-- 사용자 프로필 정보 (나이, 거주 지역, 프로필 완료 여부)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS age      INTEGER,
  ADD COLUMN IF NOT EXISTS region   TEXT,
  ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN NOT NULL DEFAULT FALSE;
