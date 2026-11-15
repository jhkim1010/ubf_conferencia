-- 076: 참석 취소
--
-- 지금까지는 등록을 무를 길이 없었다. 못 오게 된 사람은 명단·방·조·배차
-- 어디에나 그대로 남고, 담당자는 그 사람 몫의 침대와 좌석을 계속 잡아 둔다.
--
-- **행을 지우지 않는다.** 지우면 payments 가 CASCADE 로 함께 사라져, 이미
-- 받은 돈을 돌려줘야 하는지 알 길이 없어진다. 마음을 바꿔 다시 오는 사람도
-- 흔하다 — 그때 처음부터 다시 적게 할 이유가 없다.
--
-- 그래서 취소는 표시다. submitted 는 건드리지 않는다 — 담당자가 되살리면
-- 취소 전 상태 그대로 돌아와야 한다.
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS cancelled_by UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS cancel_reason TEXT;

COMMENT ON COLUMN registrations.cancelled_at IS
  '참석을 취소한 때. NULL 이면 살아 있는 등록이다. 본인 또는 담당자가 정한다(076)';
COMMENT ON COLUMN registrations.cancelled_by IS
  '취소한 사람. 본인이면 registrations.user_id 와 같다(076)';

-- 참가자 판정(038·055)에 취소를 더한다.
--
-- 인자가 셋인 판본을 **따로** 둔다. 두 인자 판본을 바꿔 버리면 마이그레이션과
-- 배포 사이에 돌고 있는 옛 서버가 깨진다. 서버는 모두 세 인자 판본을 쓴다.
CREATE OR REPLACE FUNCTION counts_as_participant(v text, submitted boolean, cancelled_at timestamptz)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT cancelled_at IS NULL AND counts_as_participant(v, submitted)
$$;
