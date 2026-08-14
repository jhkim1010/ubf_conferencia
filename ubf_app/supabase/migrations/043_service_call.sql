-- 043: 봉사자가 모자랄 때 전체에게 도움을 청한다
--
-- 지금은 담당자가 한 사람씩 지명하는 길뿐이다. 식사 준비 여섯 자리가 비어
-- 있는데 누가 할 수 있는지 모르면, 여섯 번을 찍어 물어보는 수밖에 없다.
-- 전체에게 한 번 알리고 손을 든 사람 중에서 고르는 편이 빠르다.
--
-- 보낸 기록을 남기는 이유는 둘이다. 담당자가 "언제 요청했더라" 를 알아야
-- 하고, 같은 역할로 몇 번이고 다시 울리는 일을 막아야 한다.
--
-- 응답은 따로 두지 않는다 — 손을 들면 service_signups 에 status='applied'
-- 로 들어가고, 확정은 지금처럼 담당자가 한다(039). 자원은 자원일 뿐이다.
CREATE TABLE IF NOT EXISTS service_calls (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id  UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  service_key TEXT NOT NULL,
  -- 담당자가 덧붙인 말. 없으면 앱이 역할 이름으로 문장을 만든다.
  message     TEXT,
  -- 보낼 당시 몇 자리가 비어 있었는지. 나중에 "그때는 여섯 자리였다" 를
  -- 알 수 있어야 한다 — 지금 수를 다시 세면 이미 채워진 뒤일 수 있다.
  short_at_send INTEGER NOT NULL DEFAULT 0,
  sent_by     UUID REFERENCES leaders(id) ON DELETE SET NULL,
  sent_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- 담당자가 그만 받겠다고 닫을 수 있다. 채워졌는데도 알림이 남아 있으면
  -- 참가자 화면에 쓸데없는 부탁이 계속 떠 있다.
  closed_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_service_calls_program
  ON service_calls(program_id, closed_at);
