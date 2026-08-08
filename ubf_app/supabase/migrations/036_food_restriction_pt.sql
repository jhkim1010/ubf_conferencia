-- 036: 식사 제한 판정에 포르투갈어를 넣는다
--
-- 앱에 포르투갈어를 넣으면서(a4a0356) 화면 문구만 옮기고 **판정 낱말은
-- 그대로 두었다.** 그래서 "Nenhum"(없음)을 고른 브라질 참가자가 식사 제한자로
-- 잡혔다. 화면은 멀쩡히 포르투갈어인데 뒤에서는 그 말을 모르는 상태였다.
--
-- 앱의 foodNone 은 네 언어로 이렇게 나온다:
--   ko 없음 · en None · es Ninguno · pt Nenhum
-- 넷이 모두 여기 있어야 한다. 언어를 늘릴 때 이 목록을 같이 늘리는 것을
-- 잊으면, 그 언어 사용자만 조용히 제한자로 잡힌다.
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
       -- 한국어
       '없음', '없다', '무', '해당없음', '특이사항 없음',
       -- 영어
       'none', 'no', 'nothing', 'n/a', 'na',
       -- 스페인어
       'ninguno', 'ninguna', 'nada', 'sin restricciones',
       -- 포르투갈어
       -- 포르투갈어
       'nenhum', 'nenhuma', 'sem restrições', 'sem restricoes',
       -- 기호로 대신 적는 사람들
       '-', '--', '.', 'x'
     )
$$;
