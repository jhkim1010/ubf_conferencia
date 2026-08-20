// 수양회 전후 호텔 박수 (060)
//
// 참가자에게 "몇 박 묵느냐" 를 묻지 않는다. **비행 일정에서 나온다.**
// 물어보면 둘이 어긋나고, 어긋나면 어느 쪽이 맞는지 아무도 모른다.
//
// 수양회가 1/21~1/24 이면 21일에 와서 24일 저녁에 떠나는 사람은 추가 숙박이
// 없다. 20일에 오면 하룻밤, 25일에 떠나면 또 하룻밤이다.
//
// **투어를 신청했으면 그 끝날까지는 숙박이 이미 들어 있다.** 27일에 끝나는
// 투어를 하고 27일에 떠나면 추가가 없고, 30일에 떠나면 사흘이다.
//
// DB 도 HTTP 도 쓰지 않는다. test/hotel_nights.test.js 로 그대로 확인한다.

/// 무엇이 오든 'YYYY-MM-DD' 로. 못 읽으면 null.
///
/// 항공편은 '2027-01-20T00:00:00.000' 같은 **그 지역 시각**으로 들어온다.
/// 시간대를 계산에 넣지 않는다 — 앞 열 글자가 곧 그날이고, 공항에 몇 시에
/// 내리든 그날 밤 잘 곳이 필요한지는 날짜만으로 갈린다.
export function dayOf(v) {
  if (v instanceof Date) return v.toISOString().slice(0, 10);
  const s = String(v ?? '').trim();
  return /^\d{4}-\d{2}-\d{2}/.test(s) ? s.slice(0, 10) : null;
}

/// 두 날 사이의 밤 수. b 가 a 보다 앞서면 음수.
export function nightsBetween(a, b) {
  const x = dayOf(a);
  const y = dayOf(b);
  if (!x || !y) return null;
  const ms = Date.parse(`${y}T00:00:00Z`) - Date.parse(`${x}T00:00:00Z`);
  return Math.round(ms / 86400000);
}

/// 이 사람이 며칠 밤을 더 자야 하는가.
///
/// tours 는 신청한 투어다 — `{ end, includesLodging }`.
/// **숙박이 들어 있는 투어의 끝날까지만** 이미 잔 것으로 본다(060).
/// 당일치기 시내 투어처럼 숙박이 없는 투어는 그 기간에도 잘 곳이 필요하므로
/// 기간을 늘려 주지 않는다.
///
/// suspect 는 "숫자가 이상하다" 는 표시다. 운영 자료에 도착이 다섯 달 전인
/// 줄이 실제로 있었다 — 그대로 곱하면 한 사람 앞으로 수천 달러가 붙는다.
/// 조용히 잘라 내지는 않는다. 잘라 내면 오래 묵는 사람에게 덜 받게 된다.
export function hotelNights({
  start,
  end,
  arrival,
  departure,
  tours = [],
  suspectOver = 14,
}) {
  const s = dayOf(start);
  const e = dayOf(end) ?? s;
  const arr = dayOf(arrival);
  const dep = dayOf(departure);

  // 수양회 날짜를 모르면 셀 기준이 없다.
  if (!s) return { before: 0, after: 0, nights: 0, stayEnd: null, suspect: false };

  // 숙박이 들어 있는 투어의 끝날까지는 이미 묵는다.
  let stayEnd = e;
  for (const t of tours) {
    if (t?.includesLodging === false) continue;
    const d = dayOf(t?.end ?? t);
    if (d && (!stayEnd || d > stayEnd)) stayEnd = d;
  }

  const beforeRaw = arr ? nightsBetween(arr, s) : 0;
  const afterRaw = dep && stayEnd ? nightsBetween(stayEnd, dep) : 0;

  // 늦게 오거나 일찍 가는 것은 추가 숙박이 아니다(0 으로 둔다).
  const before = Math.max(0, beforeRaw ?? 0);
  const after = Math.max(0, afterRaw ?? 0);

  return {
    before,
    after,
    nights: before + after,
    stayEnd,
    suspect: before + after > suspectOver,
  };
}

/// 숙박비. **참가비와 더하지 않는다** — 따로 보여 준다.
export function hotelCost(nights, pricePerNight) {
  const n = Number(nights);
  const p = Number(pricePerNight);
  if (!Number.isFinite(n) || n <= 0) return 0;
  if (!Number.isFinite(p) || p <= 0) return 0;
  return Math.round(n * p * 100) / 100;
}
