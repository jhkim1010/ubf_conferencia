-- 047: 참가자 개인에게 텔레그램으로 연락하기
--
-- 지금까지 텔레그램은 담당자만 받았다 — 수양회 단톡방(002)과 관리자 개인
-- 채팅. 참가자에게 닿는 길은 앱 푸시뿐인데, 푸시는 앱을 지웠거나 알림을
-- 꺼 뒀거나 웹으로만 쓰는 사람에게는 가지 않는다. 봉사를 부탁해 놓고
-- 아무도 못 받는 일이 실제로 생긴다.
--
-- 봇이 사람에게 먼저 말을 걸 수는 없다. 그 사람이 봇에게 /start 를 보내야
-- 하고, 그때 봇이 chat_id 를 알게 된다. 그래서 두 칸이 필요하다:
--
--   telegram_link_code  앱이 만들어 주는 일회용 코드. `/start <code>` 로
--                       돌아오면 누구인지 알 수 있다.
--   telegram_chat_id    연결된 뒤의 대화방. 여기로 보낸다.
--
-- 코드는 **수양회를 가로질러 유일** 해야 한다. 봇 하나가 여러 수양회를
-- 담당할 수 있고, /start 로 돌아오는 것은 코드뿐이기 때문이다.
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS telegram_chat_id   TEXT,
  ADD COLUMN IF NOT EXISTS telegram_link_code TEXT;

COMMENT ON COLUMN registrations.telegram_chat_id IS
  '참가자 개인 텔레그램 대화방. /start 로 연결되면 채워진다.';
COMMENT ON COLUMN registrations.telegram_link_code IS
  '연결용 일회용 코드. `/start <code>` 로 돌아온다.';

CREATE UNIQUE INDEX IF NOT EXISTS idx_registrations_tg_code
  ON registrations(telegram_link_code)
  WHERE telegram_link_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_registrations_tg_chat
  ON registrations(program_id, telegram_chat_id)
  WHERE telegram_chat_id IS NOT NULL;

-- ── 어디까지 읽었는지 ────────────────────────────────────────
-- 웹훅을 걸지 않고 getUpdates 로 가져온다. 웹훅은 공개 주소와 인증서를
-- 텔레그램에 등록해야 하고, 수양회마다 봇이 다르면 그만큼 등록해야 한다.
-- 연결은 사람이 앱에서 버튼을 누르는 그 순간에만 일어나므로, 그때 한 번
-- 가져오면 충분하다.
--
-- **읽은 자리를 남겨야 한다.** getUpdates 는 offset 을 주지 않으면 같은
-- 것을 계속 돌려주고, 24시간이 지나면 사라진다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS telegram_update_offset BIGINT;

COMMENT ON COLUMN programs.telegram_update_offset IS
  'getUpdates 에서 다음에 읽을 update_id. 연결 확인 때만 쓴다.';
