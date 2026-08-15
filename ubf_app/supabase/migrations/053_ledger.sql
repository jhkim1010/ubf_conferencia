-- 053: 수양회 장부 — 들어온 돈과 나간 돈
--
-- 지금까지 앱이 아는 돈은 참가비뿐이었다. 그런데 수양회를 여는 데 드는
-- 돈은 그것만이 아니다 — 지부에서 보내 주는 지원금, 후원, 그리고 숙소비·
-- 식비·버스 대절 같은 지출. 담당자는 그것을 따로 종이나 표계산기에 적고,
-- "지금 얼마가 모자라나" 를 물으면 두 곳을 더해야 했다.
--
-- 한 줄이 한 번의 들어옴 또는 나감이다.
--
-- **참가비는 여기 적지 않는다.** 그것은 payments 에 이미 있고, 두 곳에
-- 적으면 언젠가 어긋난다. 합계를 낼 때 둘을 더한다.
CREATE TABLE IF NOT EXISTS ledger_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id  UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,

  -- income  : 지원·후원처럼 들어온 돈
  -- expense : 나간 돈
  kind        TEXT NOT NULL CHECK (kind IN ('income', 'expense')),

  -- 금액은 늘 양수다. 방향은 kind 가 정한다 — 음수 지출과 양수 지출이
  -- 섞이면 합계를 아무도 믿지 못한다.
  amount      NUMERIC(12, 2) NOT NULL CHECK (amount > 0),

  -- 무엇에 쓴 돈인지. 목록으로 고르지 않고 적게 둔다 — 수양회마다 항목이
  -- 다르고, 목록을 정해 두면 "기타" 만 쌓인다.
  title       TEXT NOT NULL,
  note        TEXT,

  -- 언제 있었던 일인지. 적은 날과 다를 수 있다(지난주 영수증을 오늘 적는다).
  occurred_on DATE NOT NULL DEFAULT CURRENT_DATE,

  created_by  UUID REFERENCES leaders(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE ledger_entries IS
  '수양회 장부. 참가비는 payments 에 있고 여기 적지 않는다.';

CREATE INDEX IF NOT EXISTS idx_ledger_program
  ON ledger_entries(program_id, occurred_on DESC);
