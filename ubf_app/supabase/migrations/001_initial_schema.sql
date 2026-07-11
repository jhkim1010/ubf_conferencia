-- UBF 참가자 등록 앱 - Neon PostgreSQL 스키마
-- Neon 콘솔 SQL Editor에서 실행하거나
-- server/src/db/migrate.js 로 적용

-- ============================================================
-- 0. UUID 확장 활성화
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. 사용자 테이블 (Google OAuth 연동)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  google_id     TEXT UNIQUE NOT NULL,
  email         TEXT UNIQUE NOT NULL,
  name          TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. 리더 권한 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS leaders (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  gmail      TEXT UNIQUE NOT NULL,
  name       TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ============================================================
-- 3. 프로그램(수양회/성경학교 등) 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS programs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT NOT NULL,
  location         TEXT NOT NULL,
  leader_id        UUID REFERENCES leaders(id) ON DELETE SET NULL,
  start_date       DATE,
  end_date         DATE,
  is_active        BOOLEAN DEFAULT TRUE,
  enabled_sections JSONB DEFAULT '{
    "personal_info": true,
    "arrival_flight": true,
    "departure_flight": true,
    "food_requirements": true,
    "special_programs": true,
    "roommate": true
  }'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. 프로그램 옵션 (투어, 특별 프로그램)
-- ============================================================
CREATE TABLE IF NOT EXISTS program_options (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id  UUID REFERENCES programs(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  description TEXT,
  cost        NUMERIC(10, 2) DEFAULT 0,
  is_active   BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- 5. 참가자 등록 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS registrations (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id         UUID REFERENCES programs(id) ON DELETE CASCADE,
  user_id            UUID REFERENCES users(id) ON DELETE CASCADE,
  -- 1. 개인 정보
  country            TEXT,
  branch             TEXT,
  real_name          TEXT,
  bible_name         TEXT,
  gender             TEXT CHECK (gender IN ('M', 'F')),
  age                INTEGER CHECK (age > 0 AND age < 150),
  -- 2. 도착 비행기 {flight_no, airline, arrival_airport, departure_airport, scheduled_arrival, terminal}
  arrival_flight     JSONB,
  -- 3. 출발 비행기
  departure_flight   JSONB,
  -- 4. 음식 특별 사항
  food_requirements  TEXT,
  -- 5. 선택 옵션 (program_options id 배열)
  selected_options   UUID[] DEFAULT '{}',
  -- 6. 룸메이트 희망
  roommate_preference TEXT,
  -- 총 비용
  total_cost         NUMERIC(10, 2) DEFAULT 0,
  -- FCM 토큰 (푸시 알림)
  fcm_token          TEXT,
  submitted          BOOLEAN DEFAULT FALSE,
  updated_at         TIMESTAMPTZ DEFAULT NOW(),
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(program_id, user_id)
);

-- ============================================================
-- 6. 입금 확인 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS payments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id   UUID REFERENCES registrations(id) ON DELETE CASCADE,
  amount            NUMERIC(10, 2) NOT NULL,
  payment_method    TEXT CHECK (payment_method IN ('cash', 'transfer', 'other')),
  receipt_image_url TEXT,
  status            TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
  confirmed_by      UUID REFERENCES leaders(id),
  confirmed_at      TIMESTAMPTZ,
  note              TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(registration_id)
);

-- ============================================================
-- 7. Push 알림 이력 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id UUID REFERENCES programs(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  sent_by    UUID REFERENCES leaders(id),
  sent_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- updated_at 자동 갱신 트리거
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER registrations_updated_at
  BEFORE UPDATE ON registrations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 인덱스 (쿼리 성능)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_registrations_program_id ON registrations(program_id);
CREATE INDEX IF NOT EXISTS idx_registrations_user_id    ON registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_programs_leader_id       ON programs(leader_id);
CREATE INDEX IF NOT EXISTS idx_payments_registration_id ON payments(registration_id);
CREATE INDEX IF NOT EXISTS idx_program_options_program_id ON program_options(program_id);
