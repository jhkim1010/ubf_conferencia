-- 018: 참가비 등급 (기본 / 프리미엄)
--
-- 수양회를 만들 때 기본 가격과 프리미엄 가격을 정하고, 등록자가 하나를 고른다.
-- 숙소 등급 차이(단체실 vs 개인실 등)를 가격에 반영하기 위한 것이다.
--
-- 016 에서 넣은 programs.base_fee 는 이 구조로 대체한다. 아직 어느 화면에서도
-- 쓰지 않았고 데이터도 없으므로 혼란을 남기지 않도록 여기서 정리한다.
-- (DROP 대신 남겨두면 두 개의 진실이 생긴다. 다만 파괴적 구문은 쓰지 않고
--  주석으로만 폐기를 표시한다 — migrate.js 가 매번 재실행되기 때문이다.)
--
-- 주의: migrate.js 는 적용 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.
-- 모든 구문이 멱등이어야 하며 파괴적 구문을 넣지 않는다.

ALTER TABLE programs
  -- 금액. NULL 이면 그 등급을 제공하지 않는다는 뜻이다.
  -- 프리미엄만 없는 행사가 흔하므로 둘 다 nullable 로 둔다.
  ADD COLUMN IF NOT EXISTS fee_basic          NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS fee_premium        NUMERIC(10,2),
  -- 등급이 무엇을 포함하는지 설명. "프리미엄"만으로는 참가자가 판단할 수 없다.
  ADD COLUMN IF NOT EXISTS fee_basic_desc     TEXT,
  ADD COLUMN IF NOT EXISTS fee_premium_desc   TEXT,

  -- 할인 항목. 행사마다 일정이 다르므로(3일 행사 vs 5일 행사) 관리자가 정의한다.
  -- 원소: { "key": "d1", "label": "1일만 참석", "amount": 40 }
  --   label  관리자가 쓴 문구를 그대로 보여준다. program_options.name 과 같은 방식이다
  --          (행사별 문구라 ARB 로 번역할 수 없다).
  --   amount 할인 금액. NULL 이면 담당자가 개별 판단한다.
  ADD COLUMN IF NOT EXISTS discount_options   JSONB DEFAULT '[]'::jsonb;

ALTER TABLE registrations
  -- 등록자가 고른 등급. NULL 은 아직 고르지 않음.
  ADD COLUMN IF NOT EXISTS fee_tier TEXT,

  -- ── 할인 신청 (descuento) ──────────────────────────────────
  -- 등록자는 programs.discount_options 중 하나를 고른다. 금액은 담당자가 정한다.
  -- 등록자가 금액을 직접 적게 하면 폼에서 흥정이 벌어지고 승인 기준도 사라진다.
  ADD COLUMN IF NOT EXISTS discount_requested  BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS discount_option_key TEXT,   -- discount_options[].key
  -- 고른 항목의 문구를 등록 시점 그대로 보관한다. 관리자가 나중에 항목을 고치거나
  -- 지워도 "이 사람이 무엇을 보고 신청했는지"가 남아야 한다.
  ADD COLUMN IF NOT EXISTS discount_option_label TEXT,
  ADD COLUMN IF NOT EXISTS discount_reason     TEXT,   -- 보충 설명(선택)
  -- 아래 셋은 담당자만 쓴다.
  ADD COLUMN IF NOT EXISTS discount_status     TEXT,   -- requested|approved|rejected
  ADD COLUMN IF NOT EXISTS discount_amount     NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS discount_note       TEXT;   -- 담당자 메모(승인/반려 사유)

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'registrations_discount_status_check'
  ) THEN
    ALTER TABLE registrations
      ADD CONSTRAINT registrations_discount_status_check
      CHECK (discount_status IS NULL
             OR discount_status IN ('requested', 'approved', 'rejected'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'registrations_discount_amount_check'
  ) THEN
    ALTER TABLE registrations
      ADD CONSTRAINT registrations_discount_amount_check
      CHECK (discount_amount IS NULL OR discount_amount >= 0);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'registrations_fee_tier_check'
  ) THEN
    ALTER TABLE registrations
      ADD CONSTRAINT registrations_fee_tier_check
      CHECK (fee_tier IS NULL OR fee_tier IN ('basic', 'premium'));
  END IF;
END $$;

-- 금액은 음수가 될 수 없다. 관리자 입력 실수를 DB 에서 한 번 더 막는다.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'programs_fee_nonnegative_check'
  ) THEN
    ALTER TABLE programs
      ADD CONSTRAINT programs_fee_nonnegative_check
      CHECK (
        (fee_basic   IS NULL OR fee_basic   >= 0) AND
        (fee_premium IS NULL OR fee_premium >= 0)
      );
  END IF;
END $$;
