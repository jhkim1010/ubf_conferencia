-- 062: 투어마다 더 붙는 항목
--
-- 061 은 셋을 정해 두었다 — 식사·숙박·항공권. 그런데 투어마다 사정이 달라서
-- 그 셋으로 다 담기지 않는다. 국립공원 입장료, 보트, 가이드 팁, 국내선 수하물.
-- 미리 다 셀 수 없으므로 담당자가 **이름을 붙여 더할 수 있게** 한다.
--
-- 생김새는 061 의 셋과 같다 — 이름과 예상 금액. 화면도 같은 줄로 보인다.
--
-- [{ "name": "국립공원 입장료", "cost": 35 }, { "name": "가이드 팁", "cost": null }]
--
-- cost 가 null 이면 "더 드는데 얼마인지 아직 모른다" 이고 0 과 다르다.
-- 0 으로 두면 더 들 것이 없다는 뜻이 되어, 참가자가 돈을 안 챙겨 온다.
--
-- 별도 표로 빼지 않는 이유는 이 값이 투어를 벗어나 쓰이지 않기 때문이다.
-- plan_docs 도 같은 이유로 jsonb 다.
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS extra_items JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN program_options.extra_items IS
  '투어 값에 안 든 항목들. [{name, cost}] 이며 cost 가 null 이면 금액 미정(062)';
