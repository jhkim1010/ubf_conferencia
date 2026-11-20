-- 079: 함께 등록한 동반자가 투어에 함께 가는가
--
-- 동반자 표(078 다음)에 "투어" 칸이 생긴다. 함께 가면 **대표자가 고른 투어에
-- 같이 간다** — 투어를 사람마다 따로 고르게 하면 표가 다시 복잡해진다.
--
-- 값이 바뀐다: 고른 투어 값 × (본인 + 함께 가는 동반자). 정원도 그만큼 찬다.
--
-- 기본은 FALSE 다. 지금까지 동반자에게는 투어 값이 붙지 않았다 — 이 칸이
-- 생겼다고 이미 등록한 집의 낼 돈이 저절로 늘면 안 된다.
ALTER TABLE companions
  ADD COLUMN IF NOT EXISTS joins_tours BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN companions.joins_tours IS
  '대표자가 고른 투어에 함께 가는가. 투어 값·정원에 한 사람으로 센다(079)';
