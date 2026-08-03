-- 030: 수양회 자료실 (PDF)
--
-- 수양회 기간에 나눠 주는 교재·순서지·소책자를 담당자가 올려 두면 참가자가
-- 언제든 다시 본다. 종이는 잃어버리고, 단톡방에 올린 파일은 위로 밀려 사라진다.
--
-- 파일 자체는 서버 디스크에 있고(services/media_store.js) 여기에는 **어디에
-- 있고 무엇인지**만 적는다. 원본 파일명은 무작위로 바꿔 저장하므로
-- 보여줄 제목은 따로 받아 둔다 — 없으면 참가자에게 uuid 만 보인다.
CREATE TABLE IF NOT EXISTS program_library (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id   UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  description  TEXT,
  file_url     TEXT NOT NULL,
  mime         TEXT,
  bytes        INTEGER,
  -- 목록에서 담당자가 순서를 정한다. 올린 순서가 읽는 순서와 같지 않다 —
  -- 1과를 나중에 올릴 수도 있다.
  sort_order   INTEGER NOT NULL DEFAULT 0,
  -- 올리자마자 보이지 않게 둘 수 있다. 수양회 전날 미리 올려 두고
  -- 당일 아침에 여는 식으로 쓴다.
  is_published BOOLEAN NOT NULL DEFAULT TRUE,
  uploaded_by  UUID REFERENCES users(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 참가자 화면은 "이 수양회의 공개된 자료를 순서대로"만 물어본다.
CREATE INDEX IF NOT EXISTS idx_program_library_program
  ON program_library (program_id, sort_order, created_at);
