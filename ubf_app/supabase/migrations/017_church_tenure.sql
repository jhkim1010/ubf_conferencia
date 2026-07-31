-- 017: 교회 등록 연도 (신앙 연차)
--
-- 등록 신청 시 "교회에 몸 담은 지 얼마나 되었는가"를 받는다.
--
-- 연차(예: 12년)가 아니라 **시작 연도**(예: 2014)를 저장한다.
-- 연차를 저장하면 해가 바뀔 때마다 낡아 매년 갱신해야 한다.
-- 표시할 연차는 앱에서 (현재연도 - church_since) 로 계산한다.
-- 같은 이유로 015 의 users.shepherd_since 도 시작 연도를 저장한다.
--
-- 저장 위치는 registrations 다. 이 테이블은 이미 age / gender / real_name 처럼
-- 등록 시점의 인적 정보를 스냅샷으로 갖고 있으며, 입력도 등록 플로우의
-- 개인 정보 단계에서 이루어진다.
--
-- 주의: migrate.js 는 적용 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.
-- 모든 구문이 멱등이어야 하며 파괴적 구문을 넣지 않는다.

ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS church_since INTEGER;

-- 입력 오류를 걸러낸다. 1900 이전이나 미래 연도는 받지 않는다.
-- ADD CONSTRAINT 에는 IF NOT EXISTS 가 없으므로 존재 여부를 먼저 확인한다.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'registrations_church_since_check'
  ) THEN
    ALTER TABLE registrations
      ADD CONSTRAINT registrations_church_since_check
      CHECK (
        church_since IS NULL
        OR (church_since >= 1900 AND church_since <= EXTRACT(YEAR FROM NOW())::int)
      );
  END IF;
END $$;
