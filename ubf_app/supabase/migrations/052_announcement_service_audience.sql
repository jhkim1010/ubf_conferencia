-- 052: 공지를 봉사팀에도 보낸다
--
-- 044 는 받는 사람을 방·조로 좁힐 수 있게 했다. 그런데 현장에서 가장 자주
-- 하는 말이 "픽업 담당들 9시에 모입니다" 같은 것이다 — 팀 하나에게.
--
-- 방과 조는 대상이 UUID 지만 **봉사 역할은 키다**('pickup',
-- 'custom:iguazu-bus-01'). 그래서 audience_id 를 UUID 로 두면 담을 수 없다.
-- 넓힌다.
--
-- UUID → TEXT 는 값을 잃지 않는다(UUID 는 그대로 문자열이 된다). 반대
-- 방향이었다면 하지 않았을 것이다.
ALTER TABLE announcements
  ALTER COLUMN audience_id TYPE TEXT USING audience_id::text;

COMMENT ON COLUMN announcements.audience_id IS
  '대상. 방·조는 UUID, 봉사팀은 역할 키(pickup, custom:…). 전체면 NULL.';
