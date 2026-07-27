-- 012: F5 운행 배차 — 기사·차량 명부(transport_runs) + 탑승 배정(run_assignments)
-- PRD F5: 등록 시 수집된 항공편(공항·시각)을 공급(기사·정원)에 매칭
-- 핵심: 자동배차는 밴을 새로 만들지 않고, 관리자가 등록한 "명부"에 승객을 채운다.

-- ============================================================
-- 1. 운행 명부 (밴 1대 = 기사 1명 + 정원 + 공항)  ← 매칭의 공급 측
--    direction: arrival(도착 픽업) | departure(출발 드롭)
-- ============================================================
CREATE TABLE IF NOT EXISTS transport_runs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id    UUID REFERENCES programs(id) ON DELETE CASCADE,
  direction     TEXT NOT NULL CHECK (direction IN ('arrival', 'departure')),
  airport       TEXT NOT NULL,                 -- 'ICN','GMP' ...
  depart_at     TIMESTAMPTZ,                   -- 밴 출발 시각(관리자 조정용, 선택)
  vehicle       TEXT,                          -- 차량 라벨('1호차')
  driver_name   TEXT,                          -- 담당 기사 이름
  driver_phone  TEXT,
  capacity      INTEGER NOT NULL DEFAULT 7 CHECK (capacity > 0),  -- 태울 수 있는 인원
  meet_point    TEXT,                          -- 집결지('T1 입국장 5번 출구')
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_runs_program ON transport_runs(program_id, direction);

-- ============================================================
-- 2. 탑승 배정 (한 사람 = 등록자 또는 동반자 중 하나, room_assignments 패턴)
-- ============================================================
CREATE TABLE IF NOT EXISTS run_assignments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id          UUID REFERENCES transport_runs(id) ON DELETE CASCADE,
  registration_id UUID REFERENCES registrations(id) ON DELETE CASCADE,
  companion_id    UUID REFERENCES companions(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT run_assign_one_person CHECK (
    (registration_id IS NOT NULL AND companion_id IS NULL) OR
    (registration_id IS NULL AND companion_id IS NOT NULL)
  )
);
-- 같은 밴에 같은 사람 중복 금지 (한 방향에서 1인 1밴은 라우트가 DELETE 후 INSERT로 보장)
CREATE UNIQUE INDEX IF NOT EXISTS uq_run_assign_reg
  ON run_assignments(run_id, registration_id) WHERE registration_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_run_assign_comp
  ON run_assignments(run_id, companion_id) WHERE companion_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_run_assign_run ON run_assignments(run_id);

-- ============================================================
-- 3. 등록자 픽업 필요 여부 (자차 이동이면 false → 배차 제외)
--    동반자는 companions.needs_pickup(011)에 이미 있음
-- ============================================================
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS needs_pickup BOOLEAN NOT NULL DEFAULT TRUE;
