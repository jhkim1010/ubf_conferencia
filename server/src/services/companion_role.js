// 동반자가 무엇으로 세어지는가 (069)
//
// 동반자 칸에는 두 가지가 섞여 있다.
//
//   따로 등록한다     지금까지의 뜻. "같은 방으로 묶어 주십시오" 라는 쪽지이고,
//                    사람 수는 그 사람 자신의 등록에서 센다.
//   등록할 수 없다    아기·어린이. **이 줄이 곧 그 사람이다.**
//
// 아기는 구글 계정이 없어 등록을 만들 수 없다. 그래서 둘째 갈래가 필요하다.
//
// DB 도 HTTP 도 쓰지 않는다. test/companion_role.test.js 로 그대로 확인한다.

/// 이 나이까지는 참가비를 받지 않고, 침대도 기본으로 안 쓰는 것으로 본다.
///
/// 만 5세 이하다. 경계를 **포함**한다 — "5살 이하" 라고 말했을 때 다섯 살이
/// 빠지면 아무도 그렇게 읽지 않는다.
export const FREE_AGE_MAX = 5;

function ageOf(v) {
  // null·undefined·빈 문자열을 먼저 걷어낸다. Number(null) 은 0 이라서
  // 그대로 두면 **나이를 모르는 사람이 갓난아기가 된다** — 침대도 안 잡고
  // 참가비도 안 받는 쪽으로 조용히 넘어간다.
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) && n >= 0 ? Math.trunc(n) : null;
}

/// 침대를 쓰는 것으로 미리 골라 둘 것인가.
///
/// **기본값일 뿐이다.** 다섯 살이면 따로 재우는 집도 있으므로 화면에서 고칠
/// 수 있어야 한다. 나이를 모르면 쓰는 쪽으로 둔다 — 자리를 덜 잡는 것보다
/// 더 잡아 두는 편이 낫다. 방이 모자라면 당일에 손쓸 수가 없다.
export function defaultOccupiesBed(age) {
  const a = ageOf(age);
  if (a === null) return true;
  return a > FREE_AGE_MAX;
}

/// 이 동반자가 **사람으로 세어지는가**(명단·식사·방).
///
/// 따로 등록하는 동반자는 자기 등록으로 세어지므로 여기서 또 세면 두 번이
/// 된다.
export function countsAsPerson(companion) {
  return companion?.registers_separately === false;
}

/// 방 정원을 한 자리 먹는가.
///
/// 사람으로 안 세는 동반자는 애초에 방에 넣지 않으므로 자리도 안 먹는다.
export function occupiesBed(companion) {
  if (!countsAsPerson(companion)) return false;
  return companion?.occupies_bed !== false;
}

/// 참가비를 받는가.
///
/// **만 5세 이하는 받지 않는다.** 그 위는 지금 받을 방법이 없다 — 참가비는
/// 등록에 매기는 것이고 이 사람에게는 등록이 없다. 여섯 살에게 받으시려면
/// 수양회마다 "동반 참가비" 를 정하는 칸이 따로 있어야 한다.
export function chargesFee(companion) {
  if (!countsAsPerson(companion)) return false; // 자기 등록에서 낸다
  const a = ageOf(companion?.age);
  if (a === null) return false; // 나이를 모르면 받지 않는다 — 잘못 받는 쪽이 나쁘다
  return a > FREE_AGE_MAX;
}

/// 이 등록에 딸린 동반자 중 사람으로 세는 것들.
export function peopleAmong(companions = []) {
  return (Array.isArray(companions) ? companions : []).filter(countsAsPerson);
}

/// 방에서 자리를 먹는 머릿수.
export function bedsNeeded(companions = []) {
  return (Array.isArray(companions) ? companions : []).filter(occupiesBed).length;
}
