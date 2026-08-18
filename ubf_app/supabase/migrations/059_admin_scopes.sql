-- 059: 공동 관리자에게 맡은 분야를 준다
--
-- 지금까지는 공동 관리자가 되면 전부 보거나 아무것도 못 봤다. 픽업만 맡은
-- 사람이 장부를 열고, 회계만 맡은 사람이 참가자의 항공편을 봤다.
--
-- **NULL 은 "전부" 다.** 이미 세워 둔 네 사람의 권한을 이 마이그레이션이
-- 조용히 줄이면 안 된다 — 어제까지 되던 일이 오늘 안 되는데 아무도 이유를
-- 모르는 것이 가장 나쁘다. 담당자가 화면에서 분야를 고를 때 비로소 좁아진다.
--
-- 값은 텍스트 배열이다. 분야가 늘 때마다 스키마를 고치지 않으려는 것이고,
-- 아는 값인지는 서버가 본다(SCOPES).
ALTER TABLE program_admins ADD COLUMN IF NOT EXISTS scopes TEXT[];

COMMENT ON COLUMN program_admins.scopes IS
  'NULL 이면 전부. 아니면 transport/rooms/groups/ledger/service/registration/comms/schedule/medical 중 맡은 것';

-- 입금을 **누가** 승인했는지.
--
-- confirmed_by 는 leaders(id) 를 가리킨다. 회계 담당 공동 관리자는 leaders
-- 행이 없으므로 거기에 넣을 수 없고, 그대로 두면 승인은 되는데 누가 했는지
-- 아무 데도 안 남는다. 돈을 다루는 일에서 그것은 안 된다.
ALTER TABLE payments ADD COLUMN IF NOT EXISTS confirmed_by_user UUID REFERENCES users(id);
