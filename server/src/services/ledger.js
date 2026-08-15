// 장부 합계 (053) — 들어온 돈과 나간 돈에서 남은 돈을 낸다.
//
// DB 도 HTTP 도 쓰지 않는다. test/ledger.test.js 로 그대로 확인한다.

export const LEDGER_KINDS = ['income', 'expense'];
export const MAX_TITLE = 80;
export const MAX_NOTE = 300;

function clean(v, max) {
  const s = typeof v === 'string' ? v.trim().replace(/\s+/g, ' ') : '';
  return s.length > max ? s.slice(0, max) : s;
}

/// 저장 전에 다듬는다. 못 쓸 줄은 null 을 돌려주고 라우트가 400 을 낸다.
///
/// 금액은 늘 양수다 — 음수 지출을 허용하면 "마이너스 지출" 로 수입을 적는
/// 사람이 생기고, 그러면 합계가 무엇을 뜻하는지 아무도 모른다.
export function normalizeEntry(raw) {
  if (!raw || typeof raw !== 'object') return null;
  if (!LEDGER_KINDS.includes(raw.kind)) return null;

  const amount = Number(raw.amount);
  if (!Number.isFinite(amount) || amount <= 0) return null;

  const title = clean(raw.title, MAX_TITLE);
  if (title === '') return null;

  const note = clean(raw.note, MAX_NOTE);
  // 날짜는 YYYY-MM-DD 만 받는다. 없으면 라우트가 오늘로 둔다.
  const on = typeof raw.occurredOn === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(raw.occurredOn)
    ? raw.occurredOn
    : null;

  // 현지 통화로 적은 경우(054). 셋이 함께 와야 한다 — 금액만 있고 환율이
  // 없으면 나중에 무엇으로 환산했는지 알 수 없다.
  const localAmount = Number(raw.localAmount);
  const rate = Number(raw.rate);
  const localCurrency =
    typeof raw.localCurrency === 'string' && /^[A-Za-z]{3}$/.test(raw.localCurrency)
      ? raw.localCurrency.toUpperCase()
      : null;
  const hasLocal =
    Number.isFinite(localAmount) && localAmount > 0 &&
    Number.isFinite(rate) && rate > 0 &&
    localCurrency !== null;

  return {
    kind: raw.kind,
    amount: Math.round(amount * 100) / 100,
    title,
    note: note === '' ? null : note,
    occurredOn: on,
    localAmount: hasLocal ? Math.round(localAmount * 100) / 100 : null,
    localCurrency: hasLocal ? localCurrency : null,
    rate: hasLocal ? Math.round(rate * 1e6) / 1e6 : null,
  };
}

/// 장부와 참가비를 합쳐 지금 형편을 낸다.
///
///   support   장부에 적은 들어온 돈 (지원·후원)
///   spent     장부에 적은 나간 돈
///   collected 참가비 중 **확인된** 것
///   owed      아직 못 받은 참가비
///
/// balance 는 **지금 손에 있는 돈** 이다: 받은 것 − 쓴 것.
/// expected 는 받을 것까지 다 받았을 때다 — 둘을 함께 보여 줘야 "지금은
/// 모자라지만 다 걷히면 남는다" 를 알 수 있다.
export function ledgerSummary({ entries = [], collected = 0, owed = 0 } = {}) {
  let support = 0;
  let spent = 0;
  for (const e of entries) {
    const amount = Number(e?.amount);
    if (!Number.isFinite(amount) || amount <= 0) continue;
    if (e.kind === 'income') support += amount;
    else if (e.kind === 'expense') spent += amount;
  }
  const got = Number.isFinite(Number(collected)) ? Number(collected) : 0;
  const left = Number.isFinite(Number(owed)) ? Number(owed) : 0;

  const round = (n) => Math.round(n * 100) / 100;
  return {
    support: round(support),
    spent: round(spent),
    collected: round(got),
    owed: round(left),
    balance: round(support + got - spent),
    expected: round(support + got + left - spent),
  };
}
