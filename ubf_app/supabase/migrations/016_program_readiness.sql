-- 016: 준비 현황 화면용 프로그램 속성 (A003)
-- 명세: .team/artifacts/A003-organizer-readiness.md
--
-- 주의: migrate.js 는 적용 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.
-- 모든 구문이 멱등이어야 하며 파괴적 구문을 넣지 않는다.
--
-- 세 컬럼 모두 nullable 이다. 기존 프로그램은 값이 없어도 화면이 동작해야 하며,
-- 해당 카드는 "설정 안 됨"으로 표시한다.

ALTER TABLE programs
  -- D-day 와 "마감 임박" 판정의 기준. 지금은 수양회 시작일밖에 없어
  -- 등록을 언제까지 받는지 앱이 알지 못한다.
  ADD COLUMN IF NOT EXISTS registration_deadline DATE,

  -- 전체 수용 인원. 숙소 정원과 별개로 "몇 명까지 받을 것인가"가 있어야
  -- 초과 여부를 판단할 수 있다.
  ADD COLUMN IF NOT EXISTS capacity INTEGER,

  -- 기본 참가비. 지금은 옵션 비용만 있어 미납 집계가 부정확하다.
  ADD COLUMN IF NOT EXISTS base_fee NUMERIC(10,2);

-- 준비 현황은 등록의 마지막 변경 시각으로 "정체 일수"를 계산한다.
-- updated_at 은 이미 있으나 인덱스가 없어 정렬 비용이 커질 수 있다.
CREATE INDEX IF NOT EXISTS idx_registrations_program_updated
  ON registrations(program_id, updated_at);
