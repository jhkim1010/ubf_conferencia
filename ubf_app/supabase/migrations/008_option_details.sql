-- 투어/특별프로그램 옵션 상세 정보 추가
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS start_date    DATE,
  ADD COLUMN IF NOT EXISTS end_date      DATE,
  ADD COLUMN IF NOT EXISTS contact_name TEXT,
  ADD COLUMN IF NOT EXISTS photo_urls   TEXT[] DEFAULT '{}';
