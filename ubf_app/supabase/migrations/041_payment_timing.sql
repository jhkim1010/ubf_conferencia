-- 041: 참가비·투어비를 미리 받는지, 와서 받는지
--
-- 전액을 현장에서 현금으로 받는 수양회에는 "입금 대기 / 입금 확인" 카드가
-- 아무 뜻이 없다. 늘 0 인 칸 두 개가 대시보드 자리를 차지한다.
-- 반대로 투어비만 미리 받는 경우처럼 일부만 선불인 수양회도 있다.
--
-- 그래서 참가비와 투어비를 따로 정한다. 둘 중 하나라도 선불이면 입금 카드가
-- 필요하고, 둘 다 현장이면 필요 없다.
--
-- 기본값은 'prepaid' 다. 지금 있는 수양회들은 입금 카드를 보고 있었고,
-- 마이그레이션이 그 화면을 말없이 없애 버리면 안 된다. 바꾸는 것은 담당자의
-- 몫으로 둔다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS fee_payment  TEXT NOT NULL DEFAULT 'prepaid',
  ADD COLUMN IF NOT EXISTS tour_payment TEXT NOT NULL DEFAULT 'prepaid';

-- 허용값. ADD CONSTRAINT 에는 IF NOT EXISTS 가 없으므로 먼저 확인한다.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'programs_fee_payment_check'
  ) THEN
    ALTER TABLE programs
      ADD CONSTRAINT programs_fee_payment_check
      CHECK (fee_payment IN ('prepaid', 'onsite'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'programs_tour_payment_check'
  ) THEN
    ALTER TABLE programs
      ADD CONSTRAINT programs_tour_payment_check
      CHECK (tour_payment IN ('prepaid', 'onsite'));
  END IF;
END $$;
