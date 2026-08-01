-- 021: 예매 전 참가자의 "예상 도착·출발 날짜"
--
-- 항공권을 아직 사지 않은 사람도 대략의 날짜를 남길 수 있어야 한다. 그래야
-- 주최 측이 픽업 규모와 숙박 일수를 미리 가늠한다.
--
-- 날짜만 넣는 것은 예전에도 가능했다. 문제는 **확정과 예상을 구분할 수 없었다**는
-- 점이다. readiness 는 arrival_flight 가 NULL 이 아니기만 하면 "항공편 완료"로
-- 셌다. 그래서 "아직 안 샀지만 아마 10일쯤" 이 확정 항공편과 똑같이 집계되고,
-- 담당자는 다 모였다고 믿게 된다. 오류가 나지 않아 더 위험한 종류의 오답이다.
--
-- 이제 JSON 안에 estimated:true 를 남긴다. 컬럼은 이미 jsonb 라 스키마 변경은
-- 필요 없고, 대신 "확정으로 셀 수 있는가"를 판단하는 함수를 하나 둔다.
--
-- 함수로 두는 이유: 같은 조건을 네 군데 쿼리에 손으로 복사하면 한 곳만 고치는
-- 사고가 난다. 실제로 국가 비교가 그런 식으로 어긋나 있었다(019).
--
-- 주의: migrate.js 는 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.
-- CREATE OR REPLACE 는 멱등이다.

-- 확정 항공편인가.
--
--   · 값이 없으면            → 아니다
--   · estimated 가 true 면   → 아니다 (예상 날짜만 적은 것)
--   · 항공편 번호가 비었으면 → 아니다 (날짜만으로는 마중을 나갈 수 없다)
--
-- IMMUTABLE 로 선언해 인덱스·집계에서 쓸 수 있게 한다. 입력이 같으면 결과가
-- 같고 외부 상태를 읽지 않으므로 정확한 선언이다.
CREATE OR REPLACE FUNCTION flight_confirmed(f jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT f IS NOT NULL
     AND COALESCE((f->>'estimated')::boolean, false) = false
     AND COALESCE(NULLIF(trim(f->>'flight_no'), ''), NULL) IS NOT NULL
$$;
