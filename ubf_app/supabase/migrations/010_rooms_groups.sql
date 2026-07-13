-- 010: 편성 준비 — 숙소(rooms) + 말씀공부 그룹(groups)
-- PRD F2. 배정(F4)에 앞서 "그릇"을 정의한다.
-- 혼숙 방침을 DB 레벨 CHECK 제약으로 강제한다:
--   couple(2인)·family(3~4인) → 혼성(mixed) 허용
--   dorm(5인+ 단체실)        → 단일 성별(M/F)만

-- ============================================================
-- 1. 숙소(방) 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS rooms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id  UUID REFERENCES programs(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,                 -- "302호"
  floor       TEXT,                          -- "3층" (선택)
  room_type   TEXT NOT NULL DEFAULT 'dorm'
              CHECK (room_type IN ('couple', 'family', 'dorm')),
  capacity    INTEGER NOT NULL CHECK (capacity > 0 AND capacity <= 30),
  gender      TEXT NOT NULL DEFAULT 'M'
              CHECK (gender IN ('M', 'F', 'mixed')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),

  -- 혼숙 방침: 단체실은 단일 성별만, 부부/가족실만 혼성 허용
  CONSTRAINT rooms_gender_policy CHECK (
    (room_type = 'dorm'   AND gender IN ('M', 'F'))
    OR
    (room_type IN ('couple', 'family') AND gender = 'mixed')
  )
);

CREATE INDEX IF NOT EXISTS idx_rooms_program_id ON rooms(program_id);

-- ============================================================
-- 2. 말씀공부 그룹(조) 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS groups (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id             UUID REFERENCES programs(id) ON DELETE CASCADE,
  name                   TEXT NOT NULL,              -- "1조", "선한 목자"
  passage                TEXT,                       -- 본문 (예: 요한복음 10장)
  location               TEXT,                       -- 모임 장소 (예: 세미나실 3)
  -- 조장(목자): 등록된 참가자일 수도, 외부 인솔자일 수도 있어 둘 다 지원
  leader_registration_id UUID REFERENCES registrations(id) ON DELETE SET NULL,
  leader_name            TEXT,                       -- 조장 이름 (미등록 인솔자 대비)
  leader_phone           TEXT,
  sort_order             INTEGER DEFAULT 0,          -- 목록 정렬용 (1조, 2조 …)
  created_at             TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_groups_program_id ON groups(program_id);
