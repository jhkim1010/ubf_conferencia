-- 012: 프로그램 개최 국가 (host_country)
-- 국제 수양회에서 참가자 거주 국가 == 개최 국가이면 항공편 입력을 기본 생략하기 위함.
-- 값은 앱의 거주 국가 목록(한국어 국가명)과 동일한 문자열.

ALTER TABLE programs ADD COLUMN IF NOT EXISTS host_country TEXT;
