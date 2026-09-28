-- 073: 어린이 참가비 — 나이로 정하는 몫
--
-- 069 가 "등록할 수 없는 동반자" 를 만들면서 참가비는 뒤로 미뤘다.
-- companion_role.js 의 주석이 그 자리를 이렇게 남겨 두었다:
--
--   참가비를 받는가. 만 5세 이하는 받지 않는다. 그 위는 지금 받을 방법이
--   없다 — 참가비는 등록에 매기는 것이고 이 사람에게는 등록이 없다.
--   여섯 살에게 받으시려면 수양회마다 "동반 참가비" 를 정하는 칸이 따로
--   있어야 한다.
--
-- 그 칸을 만든다. 정책은 **수양회마다** 다르므로 programs 에 둔다.
-- fee_basic·fee_payment·할인 항목이 이미 그렇게 되어 있다.
--
-- 세 구간이다. 경계는 **포함**한다 — "4살부터 8살까지" 라고 말했을 때
-- 여덟 살이 빠지면 아무도 그렇게 읽지 않는다.
--
--   나이 < min        안 받는다
--   min ≤ 나이 ≤ max  rate 만큼 받는다 (0.5 = 절반)
--   나이 > max        어른과 같이 전액
--
-- **비율로 둔다. 금액이 아니다.** 등급이 둘(basic·premium)이라 금액으로
-- 박으면 "절반" 이 어느 쪽의 절반인지 정해야 하고, 참가비를 고칠 때마다
-- 어린이 값을 따로 고쳐야 한다. 비율이면 보호자가 고른 등급을 따라간다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS fee_child_age_min INTEGER NOT NULL DEFAULT 4;
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS fee_child_age_max INTEGER NOT NULL DEFAULT 8;
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS fee_child_rate NUMERIC(4,3) NOT NULL DEFAULT 0.5;

-- 사람별로 고칠 수 있어야 한다.
--
-- 069 가 침대에서 배운 것과 같다 — "다섯 살이면 따로 재우는 집도 있고,
-- 나이로 잘라 버리면 그 집은 방이 좁아지는데 고칠 방법이 없다." 돈도
-- 같다. 생일이 수양회 도중에 있는 아이, 형편이 어려운 집, 담당자가 달리
-- 정한 경우가 있다.
--
-- NULL 이면 "정책대로" 다. 0 과 다르다 — 0 은 "이 아이는 안 받기로
-- 정했다" 이고, 그것도 적을 수 있어야 한다.
ALTER TABLE companions
  ADD COLUMN IF NOT EXISTS fee_share NUMERIC(4,3);

COMMENT ON COLUMN programs.fee_child_age_min IS
  '어린이 요금이 시작되는 나이. 이보다 어리면 안 받는다. 경계 포함(073)';
COMMENT ON COLUMN programs.fee_child_age_max IS
  '어린이 요금이 끝나는 나이. 이보다 많으면 전액. 경계 포함(073)';
COMMENT ON COLUMN programs.fee_child_rate IS
  '어린이가 내는 몫. 0.5 = 참가비의 절반. 고른 등급을 따라간다(073)';
COMMENT ON COLUMN companions.fee_share IS
  '이 사람만 달리 정한 몫. NULL 이면 수양회 정책대로. 0 도 뜻이 있다(073)';

-- 허용값. ADD CONSTRAINT 에는 IF NOT EXISTS 가 없으므로 먼저 확인한다(041).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'programs_fee_child_age_check'
  ) THEN
    ALTER TABLE programs
      ADD CONSTRAINT programs_fee_child_age_check
      CHECK (fee_child_age_min >= 0
             AND fee_child_age_max >= fee_child_age_min
             AND fee_child_age_max < 150);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'programs_fee_child_rate_check'
  ) THEN
    ALTER TABLE programs
      ADD CONSTRAINT programs_fee_child_rate_check
      CHECK (fee_child_rate >= 0 AND fee_child_rate <= 1);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'companions_fee_share_check'
  ) THEN
    ALTER TABLE companions
      ADD CONSTRAINT companions_fee_share_check
      CHECK (fee_share IS NULL OR (fee_share >= 0 AND fee_share <= 1));
  END IF;
END $$;
