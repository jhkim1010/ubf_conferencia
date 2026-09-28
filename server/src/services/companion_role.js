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

/// 이 나이까지는 **침대를 기본으로 안 쓰는** 것으로 본다.
///
/// 만 5세 이하다. 경계를 **포함**한다 — "5살 이하" 라고 말했을 때 다섯 살이
/// 빠지면 아무도 그렇게 읽지 않는다.
///
/// **참가비와는 상관이 없다(073).** 069 가 이미 말해 둔 것이다 — "등록을 못
/// 한다 와 침대를 쓴다 는 다른 질문이다." 돈도 마찬가지로 또 다른 질문이라,
/// 어린이 참가비 구간은 수양회마다 따로 정한다(CHILD_FEE 아래).
export const FREE_AGE_MAX = 5;

/// 어린이 참가비 구간의 기본값 (073).
///
/// 수양회마다 programs.fee_child_* 로 고칠 수 있고, 이것은 그 칸이 비어
/// 있을 때 쓰는 값이다. 네 살부터 여덟 살까지 절반.
export const DEFAULT_CHILD_FEE = { minAge: 4, maxAge: 8, rate: 0.5 };

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

/// 수양회가 정한 구간을 읽는다. 빠진 칸은 기본값으로 채운다.
///
/// 거꾸로 적힌 구간(min > max)은 **구간이 없는 것으로** 본다. DB 의 CHECK 가
/// 막지만, 그 칸을 안 거치고 들어온 값도 여기서 조용히 무너지면 안 된다.
export function childFeePolicy(program) {
  const num = (v, fallback) => {
    const n = Number(v);
    return Number.isFinite(n) ? n : fallback;
  };
  const minAge = Math.trunc(num(program?.fee_child_age_min, DEFAULT_CHILD_FEE.minAge));
  const maxAge = Math.trunc(num(program?.fee_child_age_max, DEFAULT_CHILD_FEE.maxAge));
  let rate = num(program?.fee_child_rate, DEFAULT_CHILD_FEE.rate);
  if (rate < 0) rate = 0;
  if (rate > 1) rate = 1;
  return { minAge, maxAge, rate, valid: minAge <= maxAge };
}

/// 이 사람이 참가비의 **몇 몫**을 내는가. 0 이면 안 받고 1 이면 전액이다.
///
/// 세 구간이다(073). 경계는 포함한다:
///
///   나이 < minAge         0    — 아직 안 받는다
///   minAge ≤ 나이 ≤ maxAge rate — 어린이 몫 (0.5 = 절반)
///   나이 > maxAge          1    — 어른과 같다
///
/// **사람별로 적어 둔 값이 먼저다.** 069 가 침대에서 배운 것과 같다 —
/// 나이로만 자르면 사정이 다른 집이 고칠 방법이 없다. 0 도 뜻이 있으므로
/// null 과 구별한다.
export function feeShareOf(companion, program) {
  if (!countsAsPerson(companion)) return 0; // 자기 등록에서 낸다

  const own = companion?.fee_share;
  if (own !== null && own !== undefined && own !== '') {
    const n = Number(own);
    if (Number.isFinite(n) && n >= 0 && n <= 1) return n;
  }

  const a = ageOf(companion?.age);
  // 나이를 모르면 받지 않는다 — 잘못 받는 쪽이 덜 받는 쪽보다 나쁘다.
  if (a === null) return 0;

  const { minAge, maxAge, rate, valid } = childFeePolicy(program);
  if (!valid) return a < minAge ? 0 : 1;
  if (a < minAge) return 0;
  if (a <= maxAge) return rate;
  return 1;
}

/// 참가비를 받는가. 몫이 0 보다 크면 받는다.
export function chargesFee(companion, program) {
  return feeShareOf(companion, program) > 0;
}

/// 이 등록에 딸린 동반자들이 내는 참가비의 합.
///
/// [tierFee] 는 **보호자가 고른 등급의 값**이다. 어린이는 자기 등급을 고를
/// 수 없으므로 같은 등급을 따라간다 — 한 집이 같은 밥을 먹고 같은 방에
/// 묵는데 어린이만 다른 등급일 수가 없다.
export function companionFeeOf({ companions = [], program, tierFee = 0 } = {}) {
  const fee = Number(tierFee);
  if (!Number.isFinite(fee) || fee <= 0) return 0;
  const list = Array.isArray(companions) ? companions : [];
  const sum = list.reduce((acc, c) => acc + fee * feeShareOf(c, program), 0);
  return Math.round(sum * 100) / 100;
}

/// 이 등록에 딸린 동반자 중 사람으로 세는 것들.
export function peopleAmong(companions = []) {
  return (Array.isArray(companions) ? companions : []).filter(countsAsPerson);
}

/// 방에서 자리를 먹는 머릿수.
export function bedsNeeded(companions = []) {
  return (Array.isArray(companions) ? companions : []).filter(occupiesBed).length;
}
