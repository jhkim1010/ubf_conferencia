-- 020: 수양회별 통화 단위
--
-- 지금까지 금액을 전부 U$ 로 표시했다. 남미 수양회에는 맞지만 한국·유럽에서
-- 열리는 수양회에는 맞지 않는다. 주최 측이 통화를 고르고, 그 수양회의 등록자는
-- 전원 같은 단위로 본다.
--
-- **환율 변환은 하지 않는다.** 표시 단위만 바꾼다. 변환을 하면 "언제 시점의
-- 환율인지"와 "누가 갱신하는지"가 따라오고, 결국 같은 금액이 사람마다 다르게
-- 보이는 문제가 된다. 입력한 숫자가 곧 청구 금액이다.
--
-- 저장값은 ISO 4217 코드('USD','KRW','ARS'…)다. 표시 기호는 앱이 만든다 —
-- 기호를 저장하면 국가 표시명을 저장했다가 겪은 문제(019)를 반복하게 된다.
--
-- 기존 수양회는 전부 USD 로 둔다. 지금까지 U$ 로 보여 왔으므로 그대로가 맞다.
--
-- 주의: migrate.js 는 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.
-- 모든 구문이 멱등이어야 한다.

ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';

-- ISO 4217 은 대문자 세 글자다. 형식만 강제하고 목록은 앱이 관리한다 —
-- 통화를 하나 추가할 때마다 마이그레이션을 쓰게 만들 이유가 없다.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'programs_currency_format_check'
  ) THEN
    ALTER TABLE programs
      ADD CONSTRAINT programs_currency_format_check
      CHECK (currency ~ '^[A-Z]{3}$');
  END IF;
END $$;
