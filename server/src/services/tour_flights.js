// 투어 때 타는 비행기 (081) — 순수 부분
//
// 투어를 하는 사람은 수양회 뒤에 비행기를 더 탄다. 투어지로 가는 편,
// 돌아오는 편, 그리고 집에 가는 편. 집에 가는 편은 예전 그대로
// departure_flight 이고, 가운데 구간들이 registrations.tour_flights 다.
//
// 여기서 하는 일은 둘이다.
//   normalizeTourFlights — 화면이 보낸 구간을 저장할 꼴로 다듬는다.
//   tourMovements        — 담당자 화면(공항 이동 일정)에 쓸 묶음과 빈 곳.
//
// DB 도 HTTP 도 쓰지 않는다. test/tour_flights.test.js 로 그대로 확인한다.

export const TOUR_LEG_KINDS = ['tour_out', 'tour_return', 'other'];

// 한 사람이 적는 구간이 이보다 많을 일은 없다. 화면이 잘못 보내도 여기서 끊는다.
const MAX_LEGS = 12;

const text = (v, n) => (typeof v === 'string' ? v.trim().slice(0, n) : '');

/// 'YYYY-MM-DD' 만 받는다. 시간대는 붙이지 않는다 — 그 지역 날짜다.
export function cleanDay(v) {
  const s = typeof v === 'string' ? v.trim() : '';
  return /^\d{4}-\d{2}-\d{2}/.test(s) ? s.slice(0, 10) : null;
}

/// 'H:MM' · 'HH:MM' 을 'HH:MM' 으로. 못 읽으면 null.
export function cleanTime(v) {
  const m = /^(\d{1,2}):(\d{2})/.exec(typeof v === 'string' ? v.trim() : '');
  if (!m) return null;
  const h = Number(m[1]);
  const mi = Number(m[2]);
  if (h > 23 || mi > 59) return null;
  return `${String(h).padStart(2, '0')}:${m[2]}`;
}

const KIND_ORDER = { tour_out: 0, tour_return: 1, other: 2 };

/**
 * 화면이 보낸 구간들을 저장할 꼴로.
 *
 * tourIds:      이 사람이 고른 투어. 고르지 않은 투어에 붙은 구간은 투어를
 *               떼어 낸다 — 투어를 뺐는데 "이과수 가는 편" 이 남으면
 *               배차가 그 사람을 태우러 간다.
 * homeFromTour: 투어지에서 바로 집에 가면 돌아오는 편은 없다.
 */
export function normalizeTourFlights(raw, { tourIds = [], homeFromTour = false } = {}) {
  if (!Array.isArray(raw)) return [];
  const ids = tourIds.filter((v) => typeof v === 'string');
  const out = [];
  for (const leg of raw.slice(0, MAX_LEGS)) {
    if (!leg || typeof leg !== 'object' || Array.isArray(leg)) continue;
    const kind = TOUR_LEG_KINDS.includes(leg.kind) ? leg.kind : 'other';
    if (kind === 'tour_return' && homeFromTour) continue;

    let tourId = typeof leg.tour_id === 'string' && ids.includes(leg.tour_id)
      ? leg.tour_id
      : null;
    // 투어가 하나뿐이면 어느 투어인지 물을 것이 없다.
    if (!tourId && kind !== 'other' && ids.length === 1) tourId = ids[0];
    // 투어를 하나도 안 고른 사람에게 "투어 가는 편" 은 뜻이 없다.
    if (kind !== 'other' && ids.length === 0) continue;

    const estimated = leg.estimated === true;
    const cleaned = {
      kind,
      tour_id: tourId,
      date: cleanDay(leg.date),
      // 예매 전이면 편명·시각을 두지 않는다. 남기면 "예정" 이라면서 편명이
      // 붙어 있어, 담당자는 확정된 줄로 안다(021 과 같은 이유).
      time: estimated ? null : cleanTime(leg.time),
      flight_no: estimated ? '' : text(leg.flight_no, 20).toUpperCase(),
      airline: estimated ? '' : text(leg.airline, 80),
      from: text(leg.from, 60),
      to: text(leg.to, 60),
      estimated,
      note: text(leg.note, 200),
      with_companions: leg.with_companions === true,
    };
    // 아무것도 안 적힌 구간은 버린다 — 빈 줄이 명단에 남는다.
    if (!cleaned.date && !cleaned.flight_no && !cleaned.from && !cleaned.to) continue;
    out.push(cleaned);
  }
  // 날짜순. 같은 날이면 가는 편 → 돌아오는 편 → 기타.
  return out
    .map((l, i) => ({ l, i }))
    .sort((a, b) => {
      const da = a.l.date ?? '9999';
      const db = b.l.date ?? '9999';
      if (da !== db) return da < db ? -1 : 1;
      const ta = a.l.time ?? '99';
      const tb = b.l.time ?? '99';
      if (ta !== tb) return ta < tb ? -1 : 1;
      const k = KIND_ORDER[a.l.kind] - KIND_ORDER[b.l.kind];
      return k !== 0 ? k : a.i - b.i;
    })
    .map(({ l }) => l);
}

/// 이 구간에 함께 타는 사람 수(본인 포함).
///
/// 동반자는 "같은 편" 이라고 한 구간에서만 센다. 투어가 정해진 구간이면
/// 그 투어에 가는 동반자만(080) — 이과수에는 아이까지 가고 시내 투어에는
/// 부모만 가는 집이 있다.
function headsFor(leg, companions) {
  if (!leg.with_companions) return 1;
  const going = companions.filter((c) =>
    leg.tour_id ? (c.tour_ids ?? []).includes(leg.tour_id) : true,
  );
  return 1 + going.length;
}

function departureDay(flight) {
  if (!flight || typeof flight !== 'object') return null;
  return cleanDay(flight.scheduled_departure);
}

/**
 * 담당자의 "공항 이동 일정" 화면에 쓸 것.
 *
 * rows: 투어를 고른 등록들 — { registration_id, name, selected_options,
 *       tour_flights, home_from_tour, departure_flight,
 *       companions: [{ tour_ids }] (따로 등록하지 않는 동반자만) }
 *
 * 돌려주는 것:
 *   groups   같은 날 같은 편(예매 전이면 같은 날)끼리 묶은 구간. 배차는
 *            사람이 아니라 편 단위로 잡는다.
 *   direct   투어지에서 바로 집에 가는 사람들 — 픽업이 필요 없다.
 *   missing  돌아오는 편 / 집에 가는 편을 아직 안 적은 사람.
 *            **비행기로 간다고 적은 사람만** 본다. 버스로 가는 투어까지
 *            빈칸으로 세면 경고가 늘 켜져 아무도 안 본다.
 */
export function tourMovements(rows) {
  const groups = new Map();
  const direct = new Map();
  const missingReturn = [];
  const missingHome = [];
  let travelers = 0;

  for (const r of rows) {
    const legs = Array.isArray(r.tour_flights) ? r.tour_flights : [];
    const comps = Array.isArray(r.companions) ? r.companions : [];
    const who = { registration_id: r.registration_id, name: r.name };
    travelers += 1;

    for (const leg of legs) {
      const flightKey = leg.estimated ? '~' : (leg.flight_no || '?');
      const key = [leg.kind, leg.tour_id ?? '', leg.date ?? '', flightKey].join('|');
      if (!groups.has(key)) {
        groups.set(key, {
          kind: leg.kind,
          tour_id: leg.tour_id ?? null,
          date: leg.date ?? null,
          time: leg.time ?? null,
          flight_no: leg.estimated ? '' : (leg.flight_no ?? ''),
          from: leg.from ?? '',
          to: leg.to ?? '',
          estimated: leg.estimated === true,
          heads: 0,
          people: [],
        });
      }
      const g = groups.get(key);
      const n = headsFor(leg, comps);
      g.heads += n;
      g.people.push({ ...who, heads: n });
      // 같은 편인데 한 사람만 시각·공항을 적었으면 그것을 쓴다.
      if (!g.time && leg.time) g.time = leg.time;
      if (!g.from && leg.from) g.from = leg.from;
      if (!g.to && leg.to) g.to = leg.to;
    }

    const flies = legs.some((l) => l.kind === 'tour_out');
    const returns = legs.some((l) => l.kind === 'tour_return');
    if (r.home_from_tour) {
      const day = departureDay(r.departure_flight);
      const airport = r.departure_flight?.departure_airport ?? '';
      const key = `${day ?? ''}|${airport}`;
      if (!direct.has(key)) {
        direct.set(key, { date: day, airport, heads: 0, people: [] });
      }
      const d = direct.get(key);
      d.heads += 1;
      d.people.push(who);
      if (!day) missingHome.push(who);
    } else if (flies && !returns) {
      missingReturn.push(who);
    }
  }

  const byWhen = (a, b) => {
    const x = `${a.date ?? '9999'} ${a.time ?? '99'}`;
    const y = `${b.date ?? '9999'} ${b.time ?? '99'}`;
    return x < y ? -1 : x > y ? 1 : 0;
  };
  return {
    travelers,
    groups: [...groups.values()].sort(byWhen),
    direct: [...direct.values()].sort(byWhen),
    missing: { return: missingReturn, home: missingHome },
  };
}
