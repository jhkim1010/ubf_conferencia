-- 003: 프로그램 일정(schedules) + SOS 긴급 알림 테이블 추가

-- ============================================================
-- 프로그램 일정 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS program_schedules (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id        UUID REFERENCES programs(id) ON DELETE CASCADE,
  title             TEXT NOT NULL,              -- "개회 예배", "팀별 성경공부"
  description       TEXT,
  scheduled_at      TIMESTAMPTZ NOT NULL,       -- 시작 시각 (알림 발송 기준)
  notification_sent BOOLEAN DEFAULT FALSE,      -- FCM 발송 여부
  created_by        UUID REFERENCES users(id),
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_schedules_program_id   ON program_schedules(program_id);
-- 알림 발송 cron 쿼리 성능용
CREATE INDEX IF NOT EXISTS idx_schedules_pending_notif
  ON program_schedules(scheduled_at)
  WHERE notification_sent = FALSE;

-- ============================================================
-- SOS 긴급 알림 테이블
-- ============================================================
CREATE TABLE IF NOT EXISTS sos_alerts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id      UUID REFERENCES programs(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  real_name       TEXT,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  situation_type  TEXT NOT NULL CHECK (situation_type IN ('health', 'safety', 'lost')),
  message         TEXT,
  status          TEXT DEFAULT 'active' CHECK (status IN ('active', 'resolved')),
  resolved_by     UUID REFERENCES users(id),
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sos_program_id ON sos_alerts(program_id);
CREATE INDEX IF NOT EXISTS idx_sos_user_id    ON sos_alerts(user_id);
-- 활성 SOS 조회 최적화
CREATE INDEX IF NOT EXISTS idx_sos_active
  ON sos_alerts(program_id, created_at DESC)
  WHERE status = 'active';
