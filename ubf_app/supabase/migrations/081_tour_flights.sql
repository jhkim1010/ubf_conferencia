-- 081: 투어 때 타는 비행기 (2026-11)
--
-- 투어를 하는 사람은 수양회가 끝난 뒤 비행기를 한 번 더 탄다. 투어지로
-- 가고, 돌아오고, 그다음에 집으로 간다. 지금까지는 도착 편과 출발 편 두
-- 칸뿐이라 가운데 둘을 적을 데가 없었고, 담당자는 투어 날 아침 공항 배차와
-- 돌아오는 날 밤 픽업을 메신저로 일일이 물어 짰다.
--
-- tour_flights: 구간 목록. 한 칸이 한 번의 비행이다.
--   { kind: 'tour_out' | 'tour_return' | 'other',
--     tour_id, date 'YYYY-MM-DD', time 'HH:MM', flight_no, airline,
--     from, to, estimated, note, with_companions }
--   집에 가는 편은 여기 넣지 않는다 — 예전처럼 departure_flight 다. 숙박
--   박수(060)와 배차가 그 칸을 보고 있어 옮기면 둘 다 틀린다.
--   정리 규칙은 server/src/services/tour_flights.js 한 곳에 있다.
--
-- home_from_tour: 투어지에서 바로 집에 간다(돌아오는 편이 없다).
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS tour_flights JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS home_from_tour BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN registrations.tour_flights IS
  '투어 때 타는 비행기 구간들(081). 집에 가는 편은 departure_flight';
COMMENT ON COLUMN registrations.home_from_tour IS
  '투어지에서 바로 집에 간다 — 투어에서 돌아오는 편이 없다(081)';
