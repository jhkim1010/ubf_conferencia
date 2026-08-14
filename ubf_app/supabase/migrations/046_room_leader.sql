-- 046: 숙소마다 방장 한 명
--
-- 말씀조에는 조장이 있는데(010) 숙소에는 없었다. 현장에서 방에 무슨 일이
-- 생기면 — 열쇠, 물, 늦게 도착하는 사람 — 담당자가 방마다 누구에게 연락할지
-- 매번 명단을 뒤져야 했다.
--
-- 조장과 달리 **등록한 참가자 중 한 명**이다. 방 안에서 자는 사람이라야
-- 방장 노릇을 할 수 있기 때문이다. 그래서 이름을 적는 칸(groups.leader_name)
-- 을 두지 않고 등록 행을 가리킨다.
--
-- 그 사람이 등록을 지우면 방은 남고 방장만 비워진다(SET NULL). 방을 지우면
-- 방장도 함께 사라진다 — 방이 없으면 방장도 없다.
--
-- **"그 방에 배정된 사람이어야 한다" 는 여기서 강제하지 않는다.** 방 배정은
-- room_assignments 라는 다른 표에 있어서 컬럼 제약으로는 표현할 수 없고,
-- 트리거로 막으면 자동 배정이 사람을 옮길 때마다 걸린다. 그 규칙은 방장을
-- 세우는 라우트에서 본다.
ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS leader_registration_id UUID
    REFERENCES registrations(id) ON DELETE SET NULL;

COMMENT ON COLUMN rooms.leader_registration_id IS
  '방장 (그 방에 배정된 참가자 한 명). 라우트에서 배정 여부를 확인한다.';

CREATE INDEX IF NOT EXISTS idx_rooms_leader
  ON rooms(leader_registration_id);
