-- 032: 동반자의 지부를 등록자에게서 물려받기
--
-- 동반자는 거의 언제나 등록자와 같은 지부다(부부·부모와 자녀). 그런데도
-- 사람마다 지부명을 다시 적게 해서, 같은 지부가 'São Paulo UBF' /
-- 'Sao Paulo' / 'SP UBF' 로 갈라져 적혔다.
--
-- 항공편이 이미 같은 방식을 쓰고 있다(same_flight_as_primary, 011).
-- 지부도 같은 모양으로 둔다 — 화면과 서버가 같은 규칙을 두 번 배우지 않는다.
--
-- **컬럼 기본값은 FALSE 이고, 새 동반자를 TRUE 로 만드는 것은 화면이 한다.**
--
-- 기본값을 TRUE 로 두고 기존 행을 UPDATE 로 손보고 싶지만, 이 저장소의
-- 마이그레이션은 **실행할 때마다 전부 다시 돈다**(적용 이력 테이블이 없다).
-- 그러면 나중에 사용자가 체크를 켜 둔 행이 다음 배포 때 조용히 꺼진다.
-- 기본값을 FALSE 로 두면 이미 있는 동반자는 적어 둔 지부를 그대로 쓰고,
-- 새로 만드는 동반자만 화면이 TRUE 로 시작한다. 재실행해도 아무것도 안 바뀐다.
ALTER TABLE companions
  ADD COLUMN IF NOT EXISTS same_branch_as_primary BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN companions.same_branch_as_primary IS
  '참이면 등록자의 branch 를 쓴다. branch 컬럼의 값은 지우지 않는다 — 체크를 풀면 예전에 적은 값이 다시 보인다.';
