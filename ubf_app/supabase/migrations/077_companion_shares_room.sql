-- 077: 동반자가 대표자와 같은 방을 쓰는가
--
-- 지금까지 동반자는 **늘 대표자의 방으로** 들어갔다(069). 부부·가족이면
-- 맞지만, 함께 오되 방은 따로 쓰는 사람(성인 자녀, 친구, 다른 성별의 친척)은
-- 적을 길이 없었다.
--
-- 값은 이 칸 하나다. 돈은 바뀌지 않는다 — 숙박 단가가 한 사람 한 밤 값이라
-- 같은 방이든 다른 방이든 머릿수만큼 낸다. 바뀌는 것은 방 배정뿐이다:
-- 다른 방을 쓰는 동반자는 방 배정 화면에 **따로 한 사람으로** 나온다
-- (room_assignments.companion_id, 011 이 처음부터 둔 칸).
--
-- 기본은 같은 방이다. 지금까지의 모든 동반자가 그렇게 배정돼 왔다.
ALTER TABLE companions
  ADD COLUMN IF NOT EXISTS shares_room BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN companions.shares_room IS
  '대표자와 같은 방을 쓰는가. false 면 방 배정에서 따로 한 사람으로 다룬다(077)';
