-- 022: 동행자끼리는 성별이 달라도 같은 방
--
-- 지금까지 룸메이트 요청은 성별이 다르면 **보내는 순간 거절**됐다. 부부나
-- 부모·자녀처럼 함께 온 사람이 같은 방을 쓸 방법이 없었다. 실제로 couple·
-- family 방을 만들어 둬도 자동 배정이 dorm 만 보고 있어 한 번도 쓰이지
-- 않았다.
--
-- 규칙을 이렇게 정한다:
--   · 같은 성별      → 지금까지처럼 허용
--   · 성별이 다르면  → 동행 관계(relation='family')를 밝혀야 허용
--
-- 어느 쪽이든 **상대의 수락이 있어야** 성립한다(status='accepted'). 한쪽이
-- 일방적으로 지정할 수 있으면 안 된다 — 이 상호 동의가 성별이 다른 방 배정을
-- 안전하게 만드는 유일한 근거다.
--
-- 성별이 다른 묶음은 mixed 방(couple·family)에만 들어간다. 자리가 없으면
-- 배정하지 않고 사유와 함께 남긴다 — 억지로 넣는 것보다 담당자가 보고 방을
-- 늘리는 편이 낫다.
--
-- 주의: migrate.js 는 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.
-- 모든 구문이 멱등이어야 한다.

ALTER TABLE buddy_requests
  -- peer   : 같은 성별끼리의 보통 요청 (기존 데이터는 모두 이것이다)
  -- family : 부부·가족 등 함께 여행하는 사이. 성별이 달라도 된다.
  ADD COLUMN IF NOT EXISTS relation TEXT NOT NULL DEFAULT 'peer';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'buddy_requests_relation_check'
  ) THEN
    ALTER TABLE buddy_requests
      ADD CONSTRAINT buddy_requests_relation_check
      CHECK (relation IN ('peer', 'family'));
  END IF;
END $$;
