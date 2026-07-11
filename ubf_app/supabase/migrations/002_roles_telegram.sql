-- 002: 3-role 시스템 + program_admins + Telegram 알림 컬럼 추가

-- users: role 컬럼 (director / admin / participant)
ALTER TABLE users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'participant'
  CHECK (role IN ('director', 'admin', 'participant'));

-- users: Telegram 개인 chat_id (관리자 개인 알림용)
ALTER TABLE users ADD COLUMN IF NOT EXISTS telegram_chat_id TEXT;

-- programs: Telegram 그룹 chat_id (일일 요약 알림용)
ALTER TABLE programs ADD COLUMN IF NOT EXISTS telegram_chat_id TEXT;

-- program_admins: 프로그램-관리자 매핑 (director가 admin 지정)
CREATE TABLE IF NOT EXISTS program_admins (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id   UUID REFERENCES programs(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  assigned_by  UUID REFERENCES users(id),
  assigned_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(program_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_program_admins_program_id ON program_admins(program_id);
CREATE INDEX IF NOT EXISTS idx_program_admins_user_id    ON program_admins(user_id);
