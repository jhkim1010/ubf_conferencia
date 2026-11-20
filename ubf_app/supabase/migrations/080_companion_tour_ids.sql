-- 080: 동반자가 **어느 투어에** 함께 가는가
--
-- 079 의 joins_tours 는 "대표자가 고른 투어에 다 같이 간다" 한 칸이었다.
-- 투어가 둘 이상이면 맞지 않는다 — 이과수에는 온 가족이 가고 시내 투어에는
-- 대표자만 가는 집이 있다.
--
-- 이제 대표자가 투어를 고를 때 "함께 오시는 분도 가십니까?" 를 묻고,
-- 사람마다 고른 투어 id 를 여기 적는다. 값과 정원은 투어마다
-- (본인 + 이 투어를 가진 동반자) 로 센다. 대표자가 고르지 않은 투어의 id 가
-- 남아 있어도 세지 않는다 — 대표자의 selected_options 가 먼저다.
--
-- joins_tours(079)는 더 쓰지 않는다. 운영에서 켜진 줄이 하나도 없을 때
-- 바꿨으므로 옮겨 담을 것이 없다. 칸은 지우지 않는다(파괴적 구문 금지).
ALTER TABLE companions
  ADD COLUMN IF NOT EXISTS tour_ids UUID[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN companions.tour_ids IS
  '함께 가는 투어(program_options.id). 대표자도 고른 투어만 센다(080)';
COMMENT ON COLUMN companions.joins_tours IS
  '쓰지 않음 — 080 의 tour_ids 로 바뀌었다';
