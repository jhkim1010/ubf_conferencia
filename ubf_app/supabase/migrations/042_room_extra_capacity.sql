-- 042: 방마다 여유 자리를 둔다
--
-- 2인실에 셋, 4인실에 다섯이 들어가는 일은 수양회에서 흔하다. 간이침대를
-- 하나 넣거나 바닥에 한 자리를 더 만드는 식이다. 지금은 정원이 딱 막혀 있어
-- 그런 방을 만들려면 정원 자체를 3인·5인으로 적어야 하는데, 그러면 자동
-- 배정이 **처음부터** 그 자리를 정상 자리로 보고 채운다.
--
-- 여유는 정원과 따로 센다. 자동 배정은 먼저 정원까지만 채우고, 그래도 자리가
-- 없는 사람이 남을 때에만 여유를 쓴다. 그래야 굳이 안 써도 될 간이침대가
-- 첫 방부터 깔리는 일이 없다.
ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS extra_capacity INTEGER NOT NULL DEFAULT 0;

-- 상한을 둔다. 2인실에 다섯을 넣는 것은 여유가 아니라 정원을 잘못 적은 것이다.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'rooms_extra_capacity_check'
  ) THEN
    ALTER TABLE rooms
      ADD CONSTRAINT rooms_extra_capacity_check
      CHECK (extra_capacity >= 0 AND extra_capacity <= 3);
  END IF;
END $$;
