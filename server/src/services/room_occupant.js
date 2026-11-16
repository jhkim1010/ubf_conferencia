// 방에 드는 사람 — 등록자, 또는 대표자와 **다른 방을 쓰는** 동반자(077).
//
// 방 배정 화면과 자동 배정은 지금까지 등록 id 하나로만 사람을 가리켰다.
// 다른 방을 쓰는 동반자는 등록이 없으므로 'c:<동반자 id>' 로 가리킨다.
// 이렇게 하면 화면과 배정 엔진은 손대지 않고, 저장할 때만 갈라 적으면 된다
// (room_assignments 는 처음부터 registration_id / companion_id 둘 중 하나를
// 받게 되어 있다, 011).
//
// DB 도 HTTP 도 쓰지 않는다. test/room_occupant.test.js 로 그대로 확인한다.

const PREFIX = 'c:';

/// 동반자를 가리키는 id.
export function companionOccupantId(companionId) {
  return `${PREFIX}${companionId}`;
}

/// id 를 갈라 본다. 등록이면 { registrationId }, 동반자면 { companionId }.
/// 비었으면 null.
export function parseOccupant(id) {
  const s = typeof id === 'string' ? id.trim() : '';
  if (!s) return null;
  if (s.startsWith(PREFIX)) {
    const companionId = s.slice(PREFIX.length);
    return companionId ? { companionId } : null;
  }
  return { registrationId: s };
}

/// 방 이름표에 쓸 이름 — 누구의 동반자인지 함께 적는다. 이름만 있으면
/// 담당자가 명단 어디에도 없는 사람을 보게 된다.
export function companionLabel(name, primaryName) {
  const n = String(name ?? '').trim();
  const p = String(primaryName ?? '').trim();
  return p ? `${n} (${p})` : n;
}
