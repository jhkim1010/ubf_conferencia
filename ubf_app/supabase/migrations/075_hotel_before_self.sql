-- 075: 수양회 앞 숙소도 스스로 해결할 수 있다
--
-- 074 는 수양회 **뒤** 숙소만 본인이 해결할 수 있게 했다. 그런데 앞쪽도
-- 에어비앤비 등으로 직접 잡아 오는 사람이 있다 — 며칠 일찍 와서 도시를
-- 둘러보는 가족이 그렇다. 그 밤들에도 우리 돈이 들지 않으므로 숙박비를
-- 받을 이유가 없다.
--
-- 074 의 칸과 짝을 이룬다. 뜻도 같다 — **박수는 그대로 두고** 값을 매길
-- 때만 앞 박수를 뺀다. 도착 날 공항 마중을 잡으려면 박수가 필요하다.
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS hotel_before_self BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN registrations.hotel_before_self IS
  'true 면 수양회 앞 박수(hotel_nights_before)의 숙소를 본인이 해결한다. '
  '그 밤들에는 숙박비를 받지 않는다. 박수 자체는 그대로 남는다(075)';
