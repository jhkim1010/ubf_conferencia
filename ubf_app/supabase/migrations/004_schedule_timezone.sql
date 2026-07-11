-- 004: program_schedules 에 timezone 컬럼 추가
-- 일정 생성자의 로컬 타임존을 저장; 관리자가 사후 수정 가능

ALTER TABLE program_schedules
  ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'UTC';
