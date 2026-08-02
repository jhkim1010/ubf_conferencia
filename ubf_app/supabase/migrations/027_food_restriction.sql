-- 027: 식사 제한 여부 판정 함수
--
-- 준비 현황 카드의 "식사 제한 N명"과 그 카드를 열었을 때 나오는 명단이
-- 어긋나면 안 된다. 판정을 두 곳에 각각 적으면 반드시 어긋난다.
--
-- 예전 조건은 `food_requirements <> '없음'` 하나였다. 스페인어권 참가자가
-- 대부분인 수양회에서 "ninguno" / "no" 라고 적은 사람이 전부 제한자로
-- 잡혀 숫자가 부풀었다. 세 언어에서 실제로 쓰는 표현을 함께 걸러낸다.
--
-- 판정을 넓히지는 않는다 — 애매하면 제한자로 본다. 빠뜨려서 못 먹는 음식이
-- 나가는 쪽이, 한 명 더 확인하는 쪽보다 훨씬 나쁘다.
CREATE OR REPLACE FUNCTION has_food_restriction(v text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT v IS NOT NULL
     AND btrim(v) <> ''
     AND lower(btrim(v)) NOT IN (
       '없음', '없다', '무', '해당없음', '특이사항 없음',
       'none', 'no', 'nothing', 'n/a', 'na',
       'ninguno', 'ninguna', 'nada', 'sin restricciones',
       '-', '--', '.', 'x'
     )
$$;
