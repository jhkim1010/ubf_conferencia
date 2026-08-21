// 숙박 수준 고르기 (064)
//
// 수양회 기간 밖에서 자야 하는 밤이 있으면 **어느 방을 쓸지 반드시 골라야
// 한다.** 예전에는 "숙소 필요 없음" 으로 두고 넘어갈 수 있었는데, 그러면
// 담당자는 그 사람이 스스로 잡았다는 것인지 아직 안 정했다는 것인지 알 수
// 없고, 숙박비도 셀 수 없다. 호텔에 몇 방을 잡아야 하는지가 그것으로 갈린다.
//
// 기본은 **가장 싼 방**이다. 이름으로 "일반실" 을 찾지 않는다 — 수양회마다
// 이름이 다르고 언어도 넷이라, 이름에 기대면 어느 수양회에서는 조용히 아무
// 것도 안 골라진다. 값이 그 뜻을 그대로 담고 있다.
//
// DB 도 HTTP 도 쓰지 않는다. test/hotel_choice.test.js 로 그대로 확인한다.

/// 값이 있는 것 중 가장 싼 것. 값이 하나도 안 정해졌으면 첫 번째.
/// 고를 것이 없으면 null.
export function defaultHotelKey(options) {
  if (!Array.isArray(options) || options.length === 0) return null;
  let best = null;
  let bestPrice = Infinity;
  for (const o of options) {
    const p = Number(o?.pricePerNight);
    if (Number.isFinite(p) && p >= 0 && p < bestPrice) {
      bestPrice = p;
      best = o;
    }
  }
  const chosen = best ?? options[0];
  return chosen?.key ?? null;
}

/// 이 사람은 방을 골라야 하는가.
///
/// 묵을 밤이 없으면 고를 것도 없다. 주최 측이 등급을 아직 안 만들었으면
/// 고를 수가 없으므로 막지 않는다 — 막으면 참가자가 제출 자체를 못 한다.
export function mustPickHotel({ nights, options }) {
  return (
    Number(nights) > 0 && Array.isArray(options) && options.length > 0
  );
}

/// 고른 것이 이 수양회에 실재하는가. 등급을 지운 뒤 옛 key 가 남아 있으면
/// 없는 것을 가리키고, 그때 숙박비는 조용히 0 이 된다.
export function hotelChoiceOk({ nights, options, key }) {
  if (!mustPickHotel({ nights, options })) return true;
  if (!key) return false;
  return options.some((o) => o?.key === key);
}
