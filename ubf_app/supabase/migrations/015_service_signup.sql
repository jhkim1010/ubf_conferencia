-- 015: F8 봉사 참여 신청 (Service Signup)
-- 명세: .team/artifacts/A001-f8-service-signup.md
--
-- 주의: migrate.js 는 적용 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.
-- 모든 구문이 멱등이어야 하며 파괴적 구문을 넣지 않는다.

-- ── 자격 판정용 사용자 속성 ────────────────────────────────────
-- D1: 자기 신고 + 관리자 확인 플래그. 확인 전에도 신청은 받는다.
-- D2: 목자 연차는 저장하지 않는다. 시작 연도를 두고 앱에서 계산한다
--     (연차를 저장하면 매년 낡는다).
-- D5: 운전면허는 프로필 속성으로 한 번만 받는다. 재능 칩의 driving 과는 별개다.
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_missionary          BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_missionary_verified BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS shepherd_since         INTEGER,
  ADD COLUMN IF NOT EXISTS shepherd_verified      BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS has_driver_license     BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS driver_license_country TEXT;

-- ── 프로그램별 봉사 항목 구성 ──────────────────────────────────
-- D3: 수양회 성격에 따라 필요한 섬김이 다르므로 코드에 고정하지 않는다.
-- 원소 형태: { "key": "special_song", "enabled": true, "requires_approval": false }
-- D7: group_study_leader 는 requires_approval 기본 true —
--     지부장 동의가 필요하고 배정까지 대기가 생길 수 있음을 신청 시점에 알린다.
-- 라벨은 DB 에 넣지 않는다. ARB 로 3개 언어를 관리한다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS service_options JSONB DEFAULT '[]'::jsonb;

-- ── 참여 거절 기록 ─────────────────────────────────────────────
-- D6: 거절도 기록하되 스텝은 계속 접근 가능하게 둔다. 마음이 바뀌는 경우가 많다.
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS service_declined BOOLEAN NOT NULL DEFAULT FALSE;

-- ── 봉사 신청 ──────────────────────────────────────────────────
-- D4/D7: status 로 신청·승인대기·확정·반려를 구분한다.
--        참가자가 고른 것이 곧 확정이면 중복·공백이 생기므로 담당자 확정 단계를 둔다.
CREATE TABLE IF NOT EXISTS service_signups (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id UUID NOT NULL REFERENCES registrations(id) ON DELETE CASCADE,
  service_key     TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'applied',
  note            TEXT,
  -- 픽업 상세 (service_key = 'pickup' 일 때만 의미가 있다)
  can_provide_vehicle BOOLEAN,
  vehicle_seats       INTEGER,
  contact_window      TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (registration_id, service_key)
);

-- status 허용값 제약. 재실행 시 중복 추가되지 않도록 존재 여부를 확인한다
-- (ADD CONSTRAINT 에는 IF NOT EXISTS 가 없다).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'service_signups_status_check'
  ) THEN
    ALTER TABLE service_signups
      ADD CONSTRAINT service_signups_status_check
      CHECK (status IN ('applied', 'awaiting_approval', 'confirmed', 'rejected'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_service_signups_reg
  ON service_signups(registration_id);

CREATE INDEX IF NOT EXISTS idx_service_signups_status
  ON service_signups(status);
