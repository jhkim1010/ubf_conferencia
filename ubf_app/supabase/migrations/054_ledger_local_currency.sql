-- 054: 장부에 현지 통화도 함께 적는다
--
-- 053 은 금액을 수양회 통화(대개 USD) 하나로만 적었다. 그런데 실제로 쓰는
-- 돈은 페소다 — 버스 대절도, 식자재도 페소로 내고 영수증도 페소로 나온다.
-- 달러로 환산해 적어 두면 나중에 영수증과 맞춰 볼 수가 없다.
--
-- 그래서 셋을 함께 남긴다:
--
--   local_amount    실제로 낸 돈 (예: 640,000)
--   local_currency  그 통화 (예: ARS)
--   rate            그때 쓴 환율, 1 달러당 현지 통화 (예: 1545)
--
-- **환율을 함께 적는 것이 핵심이다.** 환율만 나중에 다시 찾으면 그날 값이
-- 아니고, 아르헨티나는 하루에도 공식·블루가 따로 움직인다. 그때 쓴 값을
-- 그대로 박아 둬야 나중에 셈이 맞는다.
--
-- amount(수양회 통화)는 그대로 둔다 — 합계는 계속 그것으로 낸다. 현지
-- 통화로 적으면 amount 는 환율로 계산해 채운다.
ALTER TABLE ledger_entries
  ADD COLUMN IF NOT EXISTS local_amount   NUMERIC(14, 2),
  ADD COLUMN IF NOT EXISTS local_currency TEXT,
  ADD COLUMN IF NOT EXISTS rate           NUMERIC(14, 6);

COMMENT ON COLUMN ledger_entries.local_amount IS
  '실제로 낸 현지 통화 금액. 수양회 통화로 적었으면 NULL.';
COMMENT ON COLUMN ledger_entries.local_currency IS
  '현지 통화 코드(ARS·BRL·PYG …).';
COMMENT ON COLUMN ledger_entries.rate IS
  '그때 쓴 환율. 1 수양회통화당 현지 통화. 나중에 다시 찾으면 그날 값이 아니다.';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'ledger_local_positive'
  ) THEN
    ALTER TABLE ledger_entries
      ADD CONSTRAINT ledger_local_positive
      CHECK (
        (local_amount IS NULL AND rate IS NULL)
        OR (local_amount > 0 AND rate > 0)
      );
  END IF;
END $$;
