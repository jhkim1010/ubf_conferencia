// 수양회 전후 숙박(호텔) — 순수 로직 (DB 비의존)
//
// 멀리서 오는 사람은 수양회 며칠 전에 도착하고, 투어가 끝난 뒤에도 며칠 더
// 머문다. 그 기간의 숙소는 주최 측이 등급을 정해 두면 참가자가 고른다.

export const MAX_NIGHTS = 60;

// 이 사람이 숙박 등급을 고를 수 있는가.
//
// **국제 수양회의 참가자면 누구나 고른다(066).**
//
// 예전에는 외국에서 오는 사람만이었다. 개최국 사람은 전후에 집으로 간다고
// 보았는데, 실제로는 먼 지방에서 오시는 분이 있고 그분들도 수양회 기간 밖에
// 잘 곳이 필요하다. 필요 없으면 화면에서 "필요 없음" 으로 두면 되고, 그때는
// 박수가 0 이라 값도 안 매겨진다 — 물어보는 것 자체는 해가 없다.
//
// 개최국이 정해지지 않았으면(지역 수양회) 아무도 고를 수 없다. 전후 숙박은
// 멀리서 오는 것을 전제한 기능이고, 지역 수양회는 그 전제가 없다.
export function isHotelEligible({ hostCountry, country }) {
  return !!hostCountry && !!country;
}

export function normalizeNights(v) {
  const n = Number(v);
  if (!Number.isFinite(n)) return 0;
  return Math.min(MAX_NIGHTS, Math.max(0, Math.trunc(n)));
}

// 참가자가 낸 선택을 저장 가능한 형태로 정리한다.
//
// 자격이 없거나 없는 등급을 고르면 **선택을 떨어뜨린다. 저장 자체는 막지
// 않는다.** 할인 신청에서 같은 자리를 422 로 막았다가, 나중에 자격을 잃은
// 사람이 이름 한 글자도 저장할 수 없는 상태에 갇힌 적이 있다 —
// 화면에는 항목이 안 보이므로 스스로 취소할 방법도 없었다.
export function resolveHotelChoice({
  options,
  hostCountry,
  country,
  optionKey,
  nightsBefore,
  nightsAfter,
}) {
  const list = Array.isArray(options) ? options : [];
  const eligible = isHotelEligible({ hostCountry, country });
  const picked = eligible
    ? (list.find((o) => o && o.key === optionKey) ?? null)
    : null;

  // 등급을 고르지 않았으면 박수도 남기지 않는다. "3박" 만 남아 있으면
  // 담당자가 어느 등급으로 잡아야 할지 알 수 없고, 화면에는 아무것도 안 보인다.
  if (!picked) {
    return { key: null, nightsBefore: 0, nightsAfter: 0, estimate: null };
  }

  const before = normalizeNights(nightsBefore);
  const after = normalizeNights(nightsAfter);
  const perNight = Number(picked.pricePerNight);
  const nights = before + after;

  return {
    key: picked.key,
    nightsBefore: before,
    nightsAfter: after,
    // 예상 금액은 저장하지 않고 그때그때 계산해 보여준다. 저장해 두면
    // 등급 단가를 고친 뒤에도 옛 금액이 남아 참가자와 담당자가 다른 숫자를 본다.
    estimate: Number.isFinite(perNight) && nights > 0 ? perNight * nights : null,
  };
}
