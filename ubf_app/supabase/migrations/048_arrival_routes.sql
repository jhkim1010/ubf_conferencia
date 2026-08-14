-- 048: 도착할 수 있는 다른 경로
--
-- 005 에는 "가까운 공항" 한 칸뿐이다. 그런데 이 수양회에 오는 길은 대개
-- 하나가 아니다 — 부에노스아이레스(EZE)로 들어와 버스로 네 시간, 또는
-- 이과수(IGR)로 직항, 또는 육로로 국경을 넘어. 참가자는 표를 끊기 전에
-- 그것을 알아야 하고, 입국 심사에서도 "어떻게 왔는가" 를 설명해야 한다.
--
-- 칸을 더 만들지 않는다(route2, route3 …). 목록 하나로 둔다:
--
--   [{"airport": "EZE", "note": "부에노스아이레스 · 버스 4시간"}, …]
--
-- **가까운 공항(nearest_airport)은 그대로 둔다.** 그것은 "기본으로 삼는
-- 길" 이고 입국 안내 카드가 크게 보여 주는 값이다. 여기 목록은 그 밖의
-- 길이며, 옛 앱이 깔린 기기는 이 칸을 몰라도 예전처럼 동작한다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS arrival_routes JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN programs.arrival_routes IS
  '가까운 공항 외에 올 수 있는 길. [{airport, note}] — nearest_airport 는 그대로 둔다.';
