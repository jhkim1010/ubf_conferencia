-- 038: "이름을 적은 등록만 명단에 넣는다" 를 한 곳에 적는다
--
-- 앱을 열면 등록 행이 먼저 생기고, 이름은 그 다음 화면에서 받는다. 그래서
-- 앱만 열어 보고 만 사람이 이름 없는 빈 행으로 남는다. 이 행이 참가자
-- 명단과 대시보드 숫자에 섞여 "이름 없는 등록자 한 명" 으로 보였다.
--
-- 판정 자체는 한 줄이지만 함수로 두는 이유는, 같은 규칙이 이미 손으로
-- 두 번 적혀 있었기 때문이다(assignments.js 의 배정 대상 조회 두 곳:
-- `real_name IS NOT NULL AND real_name <> ''`). 식사 제한도 같은 식으로
-- 두 벌이 되었다가 카드는 4명 표는 2명이 됐다(027·036). 한 곳에 적는다.
--
-- **준비 현황(readiness)에는 쓰지 않는다.** 그 화면은 "아직 시작도 안 한
-- 사람이 누구인가" 를 보여 주는 것이 일이라, 이름 없는 행이 빠지면
-- 챙겨야 할 사람이 화면에서 사라진다.
CREATE OR REPLACE FUNCTION has_registrant_name(v text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(btrim(v), '') <> ''
$$;
