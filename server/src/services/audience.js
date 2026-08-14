// 알림을 받을 사람 고르기.
//
// 전체에게만 보낼 수 있으면 쓸모가 반이다. "302호 사람들만", "3조만",
// "아직 등록을 안 끝낸 사람만" 처럼 좁혀 보내야 할 일이 실제로 더 많다.
//
// 이 파일에는 **누구를 고를지의 규칙**만 있다. 실제 조회는 라우트가 하고,
// 여기서는 그 조회를 어떻게 짤지를 정한다 — 규칙만 순수 함수로 떼어 놓으면
// 검사할 수 있다.

/// 고를 수 있는 갈래.
///
/// room·group 은 대상 id 가 있어야 한다. 없으면 "어느 방인지 모르는 채로
/// 전체에게" 보내는 사고가 난다 — 좁히려던 것이 넓어지는 쪽이 가장 나쁘다.
export const AUDIENCE_KINDS = [
  'all',          // 이름을 적은 참가자 전원
  'room',         // 특정 숙소의 배정자
  'group',        // 특정 말씀조의 배정자
  'unsubmitted',  // 아직 등록을 끝내지 않은 사람
  'unpaid',       // 입금이 확인되지 않은 사람
];

export function isValidAudience(a) {
  if (!a || typeof a !== 'object') return false;
  if (!AUDIENCE_KINDS.includes(a.kind)) return false;
  if (a.kind === 'room' || a.kind === 'group') {
    return typeof a.id === 'string' && a.id.length === 36;
  }
  return true;
}

/// 본문에서 대상을 뽑는다. 안 보냈으면 전체다 — 예전 앱이 보내는 요청도
/// 그대로 동작해야 한다.
export function audienceFromBody(body) {
  const raw = body?.audience;
  if (raw === undefined || raw === null) return { kind: 'all' };
  return isValidAudience(raw) ? { kind: raw.kind, id: raw.id ?? null } : null;
}

/// 화면에 보일 이름. 서버는 갈래만 알고 방 이름·조 이름은 화면이 붙인다.
export function audienceLabelKey(a) {
  return `audience.${a?.kind ?? 'all'}`;
}
