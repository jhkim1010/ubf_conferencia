// 입금 상태 — 낼 돈과 낸 돈에서 하나로 정한다.
//
// DB 도 HTTP 도 쓰지 않는다. test/payment_state.test.js 로 그대로 확인한다.
//
// **상태를 따로 저장하지 않는다.** 금액과 상태를 둘 다 적어 두면 언젠가
// 어긋난다 — 20만원 중 5만원을 받았는데 상태는 '완납' 인 줄이 생긴다.
// 금액에서 매번 계산한다.

export const PAYMENT_STATES = ['unpaid', 'partial', 'paid', 'pending'];

/// 얼마를 냈는지 세는 상태. 거절(rejected)은 낸 것이 아니다.
function countsAsPaid(status) {
  return status === 'confirmed';
}

/// 넷 중 하나.
///
///   pending — 냈다고 알려 왔지만 담당자가 아직 확인하지 않았다
///   unpaid  — 확인된 금액이 없다
///   partial — 일부만 확인됐다
///   paid    — 낼 돈을 다 채웠다
///
/// **확인 전에는 금액과 상관없이 '대기'** 다. 확인하지 않은 돈을 받은 것으로
/// 세면 장부가 실제보다 커진다.
///
/// 낼 돈이 0 이면(참가비를 안 정한 수양회, 전액 면제) 낼 것이 없으므로
/// 완납으로 본다 — '미납' 이라고 하면 담당자가 받으러 다닌다.
export function paymentState({ due, paid, status } = {}) {
  const d = Number(due);
  const p = Number(paid);
  const owed = Number.isFinite(d) && d > 0 ? d : 0;
  const got = Number.isFinite(p) && p > 0 && countsAsPaid(status) ? p : 0;

  if (status === 'pending') return 'pending';
  if (owed === 0) return 'paid';
  if (got <= 0) return 'unpaid';
  if (got < owed) return 'partial';
  return 'paid';
}

/// 아직 받을 돈. 화면이 "얼마 남았나" 를 묻는다.
export function remaining({ due, paid, status } = {}) {
  const d = Number(due);
  const p = Number(paid);
  const owed = Number.isFinite(d) && d > 0 ? d : 0;
  const got = Number.isFinite(p) && p > 0 && countsAsPaid(status) ? p : 0;
  return Math.max(0, owed - got);
}
