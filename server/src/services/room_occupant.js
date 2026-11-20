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

/// 말씀조 자동 배정에 넣을 동반자들(078).
///
/// 함께 등록한 동반자 중 조에 드는 사람만 'c:<id>' 로 넣는다. 'same' 은
/// 대표자와 짝(edge)으로 묶어 엔진이 한 묶음으로 다루게 한다 — 수락된
/// 짝꿍을 묶는 것과 같은 방식이다(057).
///
/// 언어는 대표자의 것을 쓴다. 동반자 칸의 언어는 손으로 적는 글이라 조의
/// 언어 코드와 맞지 않는다.
///
/// rows: [{ id, registration_id, study_group, gender, age, study_language,
///          country, branch }]
/// 반환: { people: [...], edges: [[registrationId, 'c:<id>'], ...] }
export function companionGroupPeople(rows) {
  const people = [];
  const edges = [];
  for (const c of Array.isArray(rows) ? rows : []) {
    if (c.study_group !== 'same' && c.study_group !== 'other') continue;
    const id = companionOccupantId(c.id);
    people.push({
      id,
      gender: c.gender ?? null,
      age: typeof c.age === 'number' ? c.age : null,
      studyLanguage: c.study_language ?? null,
      country: c.country ?? null,
      branch: c.branch ?? null,
    });
    if (c.study_group === 'same' && c.registration_id) {
      edges.push([c.registration_id, id]);
    }
  }
  return { people, edges };
}

/// 이름 비교용으로 다듬는다 — 대소문자, 악센트, 띄어쓰기, 문장부호를
/// 무시한다. 'SOO YEON CHOI' 와 'Soo Yeon Choi', 'Jazmín' 과 'Jazmin',
/// 'BO HYUN BAEK' 과 'bohyun baek' 을 같은 이름으로 본다(운영에서 실제로
/// 띄어쓰기만 달라 못 찾은 부부가 있었다).
export function nameKey(name) {
  return String(name ?? '')
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]/gu, '');
}

/// **따로 등록했지만 같은 방을 원하는** 동반자를 그 사람의 등록과 잇는다.
///
/// 069 이전에는 부부가 각자 등록하고 서로를 "본인 등록" 동반자로 적었다.
/// 동반자 줄에는 그 사람의 등록 id 가 없으므로 같은 수양회에서 **이름이
/// 같은 등록이 꼭 하나일 때만** 잇는다. 둘 이상이면 누구인지 알 수 없어
/// 잇지 않는다 — 엉뚱한 사람과 한 방에 넣는 것보다 담당자가 손으로 옮기는
/// 편이 낫다.
///
/// companions:    [{ registration_id, real_name, shares_room }] (registers_separately 인 것)
/// registrations: [{ id, real_name }] (같은 수양회, 참가로 치는 것)
/// 반환: [[대표자 등록 id, 그 사람의 등록 id], ...] — 중복 없이
export function separateFamilyEdges(companions, registrations) {
  const byName = new Map();
  for (const r of Array.isArray(registrations) ? registrations : []) {
    const k = nameKey(r.real_name);
    if (!k) continue;
    byName.set(k, [...(byName.get(k) ?? []), r.id]);
  }
  const seen = new Set();
  const edges = [];
  for (const c of Array.isArray(companions) ? companions : []) {
    if (c.shares_room === false) continue;
    const ids = (byName.get(nameKey(c.real_name)) ?? []).filter(
      (id) => id !== c.registration_id,
    );
    if (ids.length !== 1) continue;
    const pair = [c.registration_id, ids[0]];
    const key = [...pair].sort().join('|');
    if (seen.has(key)) continue;
    seen.add(key);
    edges.push(pair);
  }
  return edges;
}

/// 함께 등록한 동반자가 자기 계정으로 또 등록한 경우 — 그 등록은 대표자가
/// 낸다(services/companion_cover.js 설명).
///
/// companions:    [{ id, registration_id, real_name, registers_separately, study_group }]
/// registrations: [{ id, real_name, primary_name? }] (같은 수양회, 참가로 치는 것)
/// 반환: Map<덮인 등록 id, { companionId, primaryId, studyGroup }>
export function coverMap(companions, registrations) {
  const byName = new Map();
  for (const r of Array.isArray(registrations) ? registrations : []) {
    const k = nameKey(r.real_name);
    if (!k) continue;
    byName.set(k, [...(byName.get(k) ?? []), r.id]);
  }
  const out = new Map();
  for (const c of Array.isArray(companions) ? companions : []) {
    if (c.registers_separately !== false) continue;
    const ids = (byName.get(nameKey(c.real_name)) ?? []).filter(
      (id) => id !== c.registration_id,
    );
    if (ids.length !== 1) continue;
    // 두 대표자가 같은 사람을 적었으면 먼저 적은 쪽이다.
    if (out.has(ids[0])) continue;
    out.set(ids[0], {
      companionId: c.id,
      primaryId: c.registration_id,
      studyGroup: c.study_group ?? 'none',
    });
  }
  return out;
}
