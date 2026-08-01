-- 026: 출발 3시간 전 자가 확인
--
-- 운항 API 를 쓰지 않는다. 무료 등급은 호출 수가 적고 지연 반영이 늦으며,
-- 참가자가 수백 명이면 한도를 넘긴다. 대신 **출발 예정 3시간 전에 본인에게
-- 묻고 본인이 답한다.** 공항에 있는 사람보다 정확한 소식통은 없다.
--
-- 이 값은 배차와 직결된다. 누가 언제 도착하는지가 바뀌면 픽업이 바뀐다.

-- 답변 자체. 한 항목에 모아 둔다 — 상태만 있고 언제 답했는지 없으면
-- "3일 전 답이 아직 유효한가"를 판단할 수 없다.
--
--   { "leg": "departure"|"arrival",
--     "status": "on_time"|"delayed"|"cancelled",
--     "new_time": "2026-09-20T15:40",   -- 지연일 때만
--     "note": "…",
--     "answered_at": "…" }
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS departure_check JSONB;

-- 물어본 적이 있는지. 없으면 cron 이 매 분 다시 묻는다.
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS departure_check_asked_at TIMESTAMPTZ;

-- 3시간 전 대상을 찾는 cron 쿼리용. 아직 안 물어본 행만 본다.
CREATE INDEX IF NOT EXISTS idx_registrations_departure_check_pending
  ON registrations(program_id)
  WHERE departure_check_asked_at IS NULL;
