-- 등록 테이블에 추가 필드 (자원봉사, 음식 세부 사항)
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS volunteer_resources TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS volunteer_note       TEXT,
  ADD COLUMN IF NOT EXISTS medical_conditions   TEXT,
  ADD COLUMN IF NOT EXISTS skips_breakfast      BOOLEAN NOT NULL DEFAULT FALSE;
