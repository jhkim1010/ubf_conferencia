-- 프로그램 유형 컬럼 추가
-- local: 지역 수양회 (항공/투어 불필요)
-- international: 국제 수양회 (모든 섹션 활성)
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS program_type TEXT NOT NULL DEFAULT 'international'
    CHECK (program_type IN ('local', 'international'));
