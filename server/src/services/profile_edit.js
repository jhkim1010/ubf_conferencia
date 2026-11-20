// 담당자가 고치는 한 사람의 기본 정보
//
// 명단에서 "이름이 틀렸어요", "지부가 바뀌었어요" 를 전화로 듣는 일이 많다.
// 지금까지는 본인에게 다시 들어가서 고치라고 하는 수밖에 없었다.
//
// **보낸 칸만 바꾼다.** 화면이 모든 칸을 보내지 않아도 안 보낸 칸은 그대로다.
// 못 알아들은 값은 바꾸지 않고 오류로 돌려준다 — 조용히 비워 버리면 담당자는
// 무엇이 지워졌는지 모른다.
//
// DB 도 HTTP 도 쓰지 않는다. test/profile_edit.test.js 로 그대로 확인한다.

const has = (o, k) => Object.prototype.hasOwnProperty.call(o ?? {}, k);

function text(v) {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  return s === '' ? null : s;
}

/// 보낸 칸을 다듬는다. 반환: { set: { column: value }, error }.
/// set 의 열쇠는 registrations 의 열 이름이다.
export function cleanProfile(body) {
  const b = body ?? {};
  const set = {};

  if (has(b, 'realName')) {
    const v = text(b.realName);
    // 이름 없는 사람은 명단에서 사라진다(055).
    if (!v) return { set: {}, error: '이름을 적어 주세요' };
    set.real_name = v;
  }
  if (has(b, 'bibleName')) set.bible_name = text(b.bibleName);
  if (has(b, 'country')) set.country = text(b.country);
  if (has(b, 'branch')) set.branch = text(b.branch);
  if (has(b, 'phone')) set.phone = text(b.phone);
  if (has(b, 'foodRequirements')) set.food_requirements = text(b.foodRequirements);

  if (has(b, 'gender')) {
    const g = text(b.gender);
    if (g !== null && g !== 'M' && g !== 'F') {
      return { set: {}, error: '값이 올바르지 않습니다' };
    }
    set.gender = g;
  }
  if (has(b, 'age')) {
    const raw = b.age;
    if (raw === null || raw === '') {
      set.age = null;
    } else {
      const n = Number(raw);
      if (!Number.isInteger(n) || n < 0 || n >= 150) {
        return { set: {}, error: '값이 올바르지 않습니다' };
      }
      set.age = n;
    }
  }
  if (has(b, 'feeTier')) {
    const t = text(b.feeTier);
    if (t !== 'basic' && t !== 'premium') {
      return { set: {}, error: '값이 올바르지 않습니다' };
    }
    set.fee_tier = t;
  }
  return { set, error: null };
}

/// 담당자가 정한 투어들 (080).
///
/// [selected] 대표자가 가는 투어 id. [companionTours] { 투어 id: [동반자 id] }.
/// [activeIds] 이 수양회의 살아 있는 투어. [companionIds] 이 등록의, 함께
/// 등록한 동반자.
///
/// 모르는 투어·남의 동반자는 버린다. 동반자는 대표자도 가는 투어에만 넣는다 —
/// 대표자 없이 아이만 투어에 보내는 줄은 값도 정원도 셀 수 없다.
/// 반환: { selected: [id], toursOf: Map<동반자 id, [투어 id]> }
export function planTours({ selected, companionTours, activeIds, companionIds }) {
  const active = new Set(activeIds ?? []);
  const picked = [...new Set((Array.isArray(selected) ? selected : []).map(String))]
    .filter((id) => active.has(id));
  const pickedSet = new Set(picked);
  const toursOf = new Map((companionIds ?? []).map((id) => [id, []]));
  for (const [opt, ids] of Object.entries(companionTours ?? {})) {
    if (!pickedSet.has(opt) || !Array.isArray(ids)) continue;
    for (const cid of ids) {
      const list = toursOf.get(String(cid));
      if (list && !list.includes(opt)) list.push(opt);
    }
  }
  return { selected: picked, toursOf };
}
