-- 061: 투어 값에 안 들어 있는 것과, 그때 더 들 것 같은 돈
--
-- 060 은 잠자리만 물었다. 그런데 참가자가 실제로 묻는 것은 "이 투어를 신청하면
-- 결국 얼마가 드느냐" 이고, 거기에는 밥값과 그 도시까지 가는 항공권도 들어간다.
-- 이과수 투어 값에 왕복 항공권이 들어 있는지 아닌지로 300 달러가 갈린다.
--
-- 그래서 셋을 따로 세운다 — 식사 · 숙박 · 항공권. 각각 "투어 값에 들어 있는가"
-- 와 "안 들어 있다면 얼마쯤 더 드는가" 다.
--
-- **기본은 셋 다 "포함" 이다.** 060 과 같은 이유다: 잘못 잡았을 때 덜 받는 쪽이
-- 더 받는 쪽보다 낫다. 담당자는 명단에서 보고 고칠 수 있지만, 더 받으면
-- 참가자가 항의하고 그 한 번이 신뢰를 깎는다.
--
-- 숙박은 060 의 includes_lodging 을 그대로 쓴다. 같은 뜻을 가진 칸을 둘로
-- 늘리면 언젠가 둘이 어긋나고, 어긋나면 어느 쪽이 맞는지 아무도 모른다.
-- 화면에는 "미포함" 으로 뒤집어 보이되 저장은 한 곳이다.
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS includes_meals BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS includes_airfare BOOLEAN NOT NULL DEFAULT true;

-- 예상 금액. NULL 은 "안 들어 있지만 얼마인지 아직 모른다" 이고 0 과 다르다 —
-- 0 으로 두면 더 들 것이 없다는 뜻이 되어, 참가자가 돈을 안 챙겨 온다.
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS est_meals_cost NUMERIC(12,2);
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS est_lodging_cost NUMERIC(12,2);
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS est_airfare_cost NUMERIC(12,2);

COMMENT ON COLUMN program_options.includes_meals IS
  'false 면 투어 값에 밥값이 없다. 그때 est_meals_cost 가 예상 금액(061)';
COMMENT ON COLUMN program_options.includes_airfare IS
  'false 면 투어 값에 항공권이 없다. 그때 est_airfare_cost 가 예상 금액(061)';
COMMENT ON COLUMN program_options.est_lodging_cost IS
  'includes_lodging 이 false 일 때 그 기간 잠자리에 들 예상 금액. 이 값이 있으면 '
  '수양회 호텔 요금으로 그 기간을 다시 세지 않는다 — 두 번 셈이 된다(061)';
