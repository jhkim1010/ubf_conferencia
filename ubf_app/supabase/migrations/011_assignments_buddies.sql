-- 011: Phase 2 — 지목(buddy_requests) · 동반자(companions) · 배정(room/group)
-- PRD F3(지목→수락, 동반자) + F4(묶음 배정)

-- ============================================================
-- 1. 지목 요청 (요청 → 수락으로 확정)
--    kind: roommate(같은 방) | group(같은 말씀조)
--    status: pending | accepted | declined
-- ============================================================
CREATE TABLE IF NOT EXISTS buddy_requests (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id           UUID REFERENCES programs(id) ON DELETE CASCADE,
  from_registration_id UUID REFERENCES registrations(id) ON DELETE CASCADE,
  to_registration_id   UUID REFERENCES registrations(id) ON DELETE CASCADE,
  kind                 TEXT NOT NULL CHECK (kind IN ('roommate', 'group')),
  status               TEXT NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW(),
  -- 같은 상대에게 같은 종류의 요청은 하나만
  UNIQUE (from_registration_id, to_registration_id, kind),
  -- 자기 자신 지목 금지
  CONSTRAINT buddy_no_self CHECK (from_registration_id <> to_registration_id)
);

CREATE INDEX IF NOT EXISTS idx_buddy_program   ON buddy_requests(program_id);
CREATE INDEX IF NOT EXISTS idx_buddy_from      ON buddy_requests(from_registration_id);
CREATE INDEX IF NOT EXISTS idx_buddy_to        ON buddy_requests(to_registration_id);
-- 배정 엔진: 프로그램의 수락된 요청을 종류별로 빠르게 조회
CREATE INDEX IF NOT EXISTS idx_buddy_accepted
  ON buddy_requests(program_id, kind)
  WHERE status = 'accepted';

CREATE OR REPLACE TRIGGER buddy_requests_updated_at
  BEFORE UPDATE ON buddy_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 2. 동반자 (부부/가족 — 대표자 등록의 하위 레코드, 별도 로그인 불필요)
--    인원수·픽업에 각각 1명으로 계산됨
-- ============================================================
CREATE TABLE IF NOT EXISTS companions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id       UUID REFERENCES registrations(id) ON DELETE CASCADE,
  real_name             TEXT NOT NULL,
  bible_name            TEXT,
  gender                TEXT CHECK (gender IN ('M', 'F')),
  age                   INTEGER CHECK (age > 0 AND age < 150),
  language              TEXT,
  branch                TEXT,
  -- 대표자와 항공편이 다르면 개별 저장 (같으면 null → 대표자 것 사용)
  same_flight_as_primary BOOLEAN NOT NULL DEFAULT TRUE,
  arrival_flight        JSONB,
  departure_flight      JSONB,
  needs_pickup          BOOLEAN NOT NULL DEFAULT TRUE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_companions_registration ON companions(registration_id);

-- ============================================================
-- 3. 숙소 배정 (한 사람 = 한 방)
--    사람 = 등록자(registration) 또는 동반자(companion) 중 하나
-- ============================================================
CREATE TABLE IF NOT EXISTS room_assignments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id         UUID REFERENCES rooms(id) ON DELETE CASCADE,
  registration_id UUID REFERENCES registrations(id) ON DELETE CASCADE,
  companion_id    UUID REFERENCES companions(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  -- 등록자 또는 동반자 중 정확히 하나
  CONSTRAINT room_assign_one_person CHECK (
    (registration_id IS NOT NULL AND companion_id IS NULL) OR
    (registration_id IS NULL AND companion_id IS NOT NULL)
  )
);

-- 한 사람은 한 방에만 (부분 유니크 인덱스)
CREATE UNIQUE INDEX IF NOT EXISTS uq_room_assign_reg
  ON room_assignments(registration_id) WHERE registration_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_room_assign_comp
  ON room_assignments(companion_id) WHERE companion_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_room_assign_room ON room_assignments(room_id);

-- ============================================================
-- 4. 말씀조 배정 (한 등록자 = 한 조)
--    (동반자는 대표자와 같은 조로 처리하거나 조 배정 대상에서 제외 — 앱 정책)
-- ============================================================
CREATE TABLE IF NOT EXISTS group_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id        UUID REFERENCES groups(id) ON DELETE CASCADE,
  registration_id UUID REFERENCES registrations(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_group_member_reg
  ON group_members(registration_id);
CREATE INDEX IF NOT EXISTS idx_group_member_group ON group_members(group_id);
