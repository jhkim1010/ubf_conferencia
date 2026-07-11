-- 005: programs 테이블에 입국 안내 정보 필드 추가
-- 참가자가 공항 입국 시 감사관에게 보여줄 정보

ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS nearest_airport  TEXT,          -- 가까운 공항명 (예: ICN, NRT)
  ADD COLUMN IF NOT EXISTS contact1_name    TEXT,          -- 대표 연락자 1 이름
  ADD COLUMN IF NOT EXISTS contact1_phone   TEXT,          -- 대표 연락자 1 전화번호
  ADD COLUMN IF NOT EXISTS contact2_name    TEXT,          -- 대표 연락자 2 이름
  ADD COLUMN IF NOT EXISTS contact2_phone   TEXT;          -- 대표 연락자 2 전화번호
