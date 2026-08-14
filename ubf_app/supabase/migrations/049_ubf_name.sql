-- 049: 명단에 UBF 이름(세례명)을 본명과 함께 보인다
--
-- 화면에 나오는 이름이 여권에 적힌 본명(real_name) 하나뿐이었다. 그런데 이
-- 공동체 안에서 서로 부르는 이름은 대개 그것이 아니다 — "Kim jung ho" 가
-- 아니라 "Marcos", "Yong Su Han" 이 아니라 "Timoteo". 명단만 보고는 누가
-- 누구인지 알아보지 못한다.
--
-- **칸을 새로 만들지 않는다.** bible_name 이 001 부터 있었고 이미 적어 둔
-- 사람들이 있다. 없던 것은 그 값을 화면에 쓰는 일뿐이었다.
--
-- **본명을 감추지도 않는다.** 항공권·여권·입국 안내는 본명이라야 하고,
-- 담당자가 공항에서 사람을 맞출 때도 그것을 본다. 그래서 둘을 함께 적는다:
--
--   Marcos (Kim jung ho)

-- ── 어떻게 보일지 ────────────────────────────────────────────
-- 판단을 한 곳에 둔다. 질의마다 손으로 이어 붙이면, 한 화면만 빠뜨렸을 때
-- 그 화면만 다르게 나오고 아무도 이유를 모른다 — 식사 제한 인원이 카드와
-- 표에서 달랐던 것이 바로 그런 일이었다.
--
-- 빈칸뿐이거나 `-` 처럼 기호만 적어 둔 것은 "없음" 으로 본다. 적을 것이
-- 없어서 줄표를 넣은 사람이 실제로 있고, 그대로 두면 명단에
-- "- (Shirley Coronel Cáceres)" 라고 나온다.
--
-- 매개변수를 `real` 이라고 부르지 않는다 — REAL 은 자료형 이름이라 함수
-- 정의가 통째로 문법 오류가 된다.
--
-- 본문은 이름 없는 달러 인용부호로 감싼다. migrate.js 는 그것만 함수
-- 본문으로 알아보고, 이름표를 붙이면 본문 가운데의 세미콜론에서 구문을
-- 잘라 버린다. (같은 이유로 이 주석에는 그 기호를 적지 않는다 — 주석에
-- 있어도 여는 표시로 세어 버린다.)
-- 지웠다 다시 만든다. CREATE OR REPLACE 로는 매개변수 **이름**을 못 바꾸고
-- ("cannot change name of input parameter"), 이 파일은 매 실행마다 다시
-- 돌기 때문에 한 번 다른 이름으로 만들어진 DB 에서는 영영 실패한다.
-- 함수를 지우는 것은 데이터를 지우는 것이 아니며, 바로 아래에서 다시 만든다.
DROP FUNCTION IF EXISTS display_name(TEXT, TEXT);

CREATE OR REPLACE FUNCTION display_name(bible TEXT, legal TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN regexp_replace(COALESCE(bible, ''), '[^[:alnum:]]', '', 'g') = ''
      THEN legal
    WHEN btrim(COALESCE(legal, '')) = ''
      THEN btrim(bible)
    -- 같은 이름을 두 번 적어 두는 사람이 있다("Joseph", "Joseph").
    -- 그대로 두면 명단에 "Joseph (Joseph)" 이라고 나온다.
    WHEN lower(btrim(bible)) = lower(btrim(legal))
      THEN btrim(legal)
    ELSE btrim(bible) || ' (' || btrim(legal) || ')'
  END;
$$;

COMMENT ON FUNCTION display_name(TEXT, TEXT) IS
  '명단에 보일 이름. 세례명이 있으면 "세례명 (본명)", 없으면 본명.';
