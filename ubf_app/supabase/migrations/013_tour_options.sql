-- 013: F6 투어 프로그램 — program_options에 정원·마감·홍보물 컬럼 추가
-- 기존(001·008): name·description·cost·start_date·end_date·contact_name·photo_urls
-- 여기에 선착순 마감·홍보물 링크만 얹음 (테이블 신설 없음)
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS capacity        INTEGER,        -- NULL = 무제한
  ADD COLUMN IF NOT EXISTS signup_deadline TIMESTAMPTZ,    -- NULL = 마감 없음
  ADD COLUMN IF NOT EXISTS brochure_url    TEXT,           -- 브로슈어(PDF 등) 링크
  ADD COLUMN IF NOT EXISTS video_url       TEXT;           -- 소개 영상 링크

-- 잔여 정원은 파생 계산(별도 테이블 불필요):
--   SELECT COUNT(*) FROM registrations
--   WHERE program_id = $1 AND submitted = TRUE AND <option_id> = ANY(selected_options)
