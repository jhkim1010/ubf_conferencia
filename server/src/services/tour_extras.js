// 투어 값에 안 들어 있는 것 (061)
//
// 참가자가 실제로 묻는 것은 "이 투어를 신청하면 결국 얼마가 드느냐" 다.
// 투어 값 옆에 밥값과 항공권이 따로 붙는 일이 흔하고, 이과수 투어에 왕복
// 항공권이 들어 있는지 아닌지로 300 달러가 갈린다.
//
// 여기서 낸 값은 **참가비에 더하지 않는다.** 우리에게 내는 돈이 아니라
// 참가자가 따로 쓸 돈이고, 무엇보다 예상일 뿐이다. 합계에 섞으면 확정된
// 청구서처럼 보인다.
//
// DB 도 HTTP 도 쓰지 않는다. test/tour_extras.test.js 로 그대로 확인한다.

/// 이 셋을 본다. 순서는 화면에 나오는 순서다.
export const EXTRA_KINDS = ['meals', 'lodging', 'airfare'];

const FIELD = {
  meals: { includes: 'includesMeals', est: 'estMealsCost' },
  lodging: { includes: 'includesLodging', est: 'estLodgingCost' },
  airfare: { includes: 'includesAirfare', est: 'estAirfareCost' },
};

/// 숫자로 읽는다. 못 읽거나 음수면 null — 0 과 다르다.
/// 0 은 "더 들 것이 없다", null 은 "얼마인지 아직 모른다" 이고,
/// 둘을 같게 보면 모르는 것을 없는 것으로 알려 주게 된다.
export function amountOf(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) && n >= 0 ? n : null;
}

/// 이 투어가 값에 포함하지 않는 것들.
///
/// 안 적힌 것은 **포함으로 본다**(061). 060 과 같은 이유로, 잘못 잡았을 때
/// 덜 받는 쪽이 더 받는 쪽보다 낫다.
export function missingFrom(tour) {
  const out = [];
  for (const kind of EXTRA_KINDS) {
    const f = FIELD[kind];
    if (tour?.[f.includes] === false) {
      out.push({ kind, amount: amountOf(tour?.[f.est]) });
    }
  }
  return out;
}

/// 신청한 투어를 통틀어 얼마가 더 들 것 같은가.
///
/// `known` 은 금액이 적힌 것들의 합, `unknown` 은 "안 들어 있는데 금액을
/// 아직 안 적은" 것들이다. **둘을 합치지 않는다** — 모르는 것을 0 으로
/// 세면 참가자가 돈을 덜 챙겨 온다. 화면은 "약 500 (그리고 항공권은 미정)"
/// 처럼 둘 다 말해야 한다.
export function tourExtras(tours = []) {
  const byKind = { meals: 0, lodging: 0, airfare: 0 };
  const items = [];
  const unknown = [];

  for (const t of tours ?? []) {
    for (const { kind, amount } of missingFrom(t)) {
      const entry = { kind, amount, tour: t?.name ?? null };
      items.push(entry);
      if (amount === null) unknown.push(entry);
      else byKind[kind] += amount;
    }
  }

  const known = Math.round((byKind.meals + byKind.lodging + byKind.airfare) * 100) / 100;
  return {
    ...byKind,
    known,
    unknown,
    items,
    // 적힌 금액도 없고 빠진 것도 없으면 할 말이 없다.
    isEmpty: items.length === 0,
  };
}
