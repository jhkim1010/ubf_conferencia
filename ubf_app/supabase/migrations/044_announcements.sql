-- 044: 공지 보내기 — 전체 또는 일부에게
--
-- 지금 알림을 보낼 수 있는 길은 일정 알림(자동)과 봉사 도움 요청(043)뿐이다.
-- "302호 물이 안 나옵니다", "3조는 강당 앞에 모여 주세요" 같은 말을 전할
-- 방법이 없어 단톡방으로 나가고, 그러면 앱에 등록만 하고 단톡방에 없는
-- 사람에게는 닿지 않는다.
--
-- 보낸 것을 남기는 이유는 담당자가 "보냈던가" 를 알아야 하기 때문이다.
-- 참가자 화면에도 지난 공지를 보여 줄 수 있다.
CREATE TABLE IF NOT EXISTS announcements (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id    UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  title         TEXT,
  body          TEXT NOT NULL,
  -- 누구에게 보냈는지. all·room·group·unsubmitted·unpaid (audience.js)
  audience_kind TEXT NOT NULL DEFAULT 'all',
  -- room·group 일 때의 대상. 그 방/조가 지워져도 공지 기록은 남겨야 하므로
  -- 외래키를 걸지 않는다.
  audience_id   UUID,
  -- 보낼 당시 몇 대의 기기에 갔는지. 나중에 다시 세면 사람이 바뀌어 있다.
  recipients    INTEGER NOT NULL DEFAULT 0,
  sent_by       UUID REFERENCES leaders(id) ON DELETE SET NULL,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_announcements_program
  ON announcements(program_id, sent_at DESC);
