-- 050: 이름을 "세례명 (이름) 성" 으로
--
-- 049 는 "Marcos (Kim jung ho)" 라고 적었다. 그런데 성은 두 이름에 같다 —
-- 세례명을 쓰는 사람도 성은 그대로 Kim 이다. 성을 괄호 안에 한 번 더
-- 넣으면 같은 말을 두 번 하는 셈이고, 부를 때 쓰는 모양도 아니다:
--
--   Marcos (Jung ho) Kim
--   Timoteo (Yong Su) Han
--
-- ── 어느 토막이 성인가 ──────────────────────────────────────
-- **문자열만으로는 확실히 알 수 없다.** "Kim jung ho" 는 성이 앞이고
-- "Yong Su Han" 은 성이 뒤다. 둘 다 한국 이름인데 적는 순서가 다르다.
--
-- 그래서 이렇게 본다:
--   1. 첫 토막이 한국 성이면 → 그것이 성 (Kim jung ho)
--   2. 아니고 마지막 토막이 한국 성이면 → 그것이 성 (Yong Su Han)
--   3. 둘 다 아니면 → 마지막 토막을 성으로 (Hugo Hurtado, Shirley Coronel)
--
-- 3번은 스페인어권에서 성이 둘인 경우("Coronel Cáceres")를 하나로만 본다.
-- 세례명이 없으면 어차피 이름 전체가 그대로 나오므로 눈에 띄지 않고,
-- 있는 경우에만 앞쪽 성이 이름 자리에 남는다. 확실히 하려면 등록에서
-- 성과 이름을 따로 받아야 하는데, 그것은 이미 적어 낸 사람들에게 다시
-- 묻는 일이라 여기서는 하지 않는다.
--
-- 토막이 하나뿐이면(Josverlyn) 성이 없다 — 그대로 쓴다.

-- 첫 글자만 대문자로. 나머지는 적어 낸 그대로 둔다 — initcap 을 쓰면
-- "McDonald" 가 "Mcdonald" 가 되고, 대문자로 적어 낸 이름을 우리가 임의로
-- 바꾸게 된다.
CREATE OR REPLACE FUNCTION cap_first(v TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN btrim(COALESCE(v, '')) = '' THEN ''
    ELSE upper(left(btrim(v), 1)) || substr(btrim(v), 2)
  END;
$$;

-- 한국 성의 로마자 표기. 같은 성을 여러 가지로 적는다(Lee/Yi/Rhee).
-- 여기 없는 성은 "마지막 토막이 성" 으로 처리되므로, 성이 앞에 오는
-- 표기에서만 어긋난다.
CREATE OR REPLACE FUNCTION is_korean_surname(v TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT lower(btrim(COALESCE(v, ''))) = ANY (ARRAY[
    'kim','gim','lee','yi','rhee','ri','park','pak','bak','choi','choe','cho',
    'jo','jung','jeong','chung','jeung','kang','gang','yoon','yun','jang',
    'chang','lim','im','han','oh','o','seo','suh','shin','sin','kwon','gwon',
    'hwang','ahn','an','song','yoo','yu','ryu','you','hong','jeon','chun',
    'jun','ko','go','koh','moon','mun','son','sohn','yang','bae','pae','baek',
    'paek','nam','noh','no','roh','ha','heo','hur','huh','ju','chu','joo',
    'min','sim','shim','woo','wu','gil','kil','pyo','ban','bang','byun',
    'byeon','uhm','eom','um','ok','won','wi','yeo','yeom','yum','jin','chin'
  ]);
$$;

-- 성과 이름을 나눠 "세례명 (이름) 성" 으로 잇는다.
--
-- 지웠다 저장하면 빈 문자열이 남고, 적을 것이 없어 '-' 만 넣은 사람도
-- 있다 — 둘 다 "세례명 없음" 으로 본다.
--
-- 세례명과 이름이 같으면 괄호를 넣지 않는다("Joseph (Joseph) Kuper").
--
-- 본문은 이름 없는 달러 인용부호로 감싼다. migrate.js 는 그것만 함수
-- 본문으로 알아본다. (같은 이유로 주석에 그 기호를 적지 않는다.)
DROP FUNCTION IF EXISTS display_name(TEXT, TEXT);

CREATE FUNCTION display_name(bible TEXT, legal TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  parts   TEXT[];
  n       INT;
  surname TEXT := '';
  given   TEXT := '';
  b       TEXT;
BEGIN
  b := btrim(COALESCE(bible, ''));
  -- 글자도 숫자도 없으면 없는 것으로 본다('-', '.', 공백).
  IF regexp_replace(b, '[^[:alnum:]]', '', 'g') = '' THEN
    b := '';
  END IF;

  parts := regexp_split_to_array(btrim(COALESCE(legal, '')), '\s+');
  n := COALESCE(array_length(parts, 1), 0);

  IF n = 0 OR parts[1] = '' THEN
    RETURN NULLIF(cap_first(b), '');
  END IF;

  IF n = 1 THEN
    given := parts[1];
  ELSIF is_korean_surname(parts[1]) THEN
    surname := parts[1];
    given := array_to_string(parts[2:n], ' ');
  ELSE
    surname := parts[n];
    given := array_to_string(parts[1:n - 1], ' ');
  END IF;

  given   := cap_first(given);
  surname := cap_first(surname);

  IF b = '' OR lower(b) = lower(given) THEN
    RETURN btrim(given || ' ' || surname);
  END IF;

  RETURN btrim(cap_first(b) || ' (' || given || ') ' || surname);
END;
$$;

COMMENT ON FUNCTION display_name(TEXT, TEXT) IS
  '명단에 보일 이름. "세례명 (이름) 성" — 세례명이 없으면 "이름 성".';
