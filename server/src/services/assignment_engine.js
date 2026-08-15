// 배정 엔진 (순수 함수 — DB 비의존, 테스트 용이)
// PRD F4: 수락된 지목 → 연결요소 묶음 → 방침(혼숙/정원) 준수 + 연령·성비 균형

// ── 연결요소(union-find): 수락 요청을 간선으로 묶음 계산 ──────────
// nodeIds: string[], edges: [fromId, toId][]  →  묶음(배열의 배열)
export function connectedComponents(nodeIds, edges) {
  const parent = new Map(nodeIds.map((id) => [id, id]));
  const find = (x) => {
    while (parent.get(x) !== x) {
      parent.set(x, parent.get(parent.get(x))); // path halving
      x = parent.get(x);
    }
    return x;
  };
  const union = (a, b) => {
    if (!parent.has(a) || !parent.has(b)) return;
    parent.set(find(a), find(b));
  };
  for (const [a, b] of edges) union(a, b);

  const groups = new Map();
  for (const id of nodeIds) {
    const root = find(id);
    if (!groups.has(root)) groups.set(root, []);
    groups.get(root).push(id);
  }
  return [...groups.values()];
}

// ── 숙소 자동 배정 ────────────────────────────────────────────
//
// 같은 성별끼리 단체실(dorm)에 넣는 것이 기본이다. 다만 **동행 관계로 수락된
// 짝은 성별이 달라도 함께 둔다** — 부부나 부모·자녀가 같은 방을 쓸 수 없으면
// 안 되기 때문이다(022). 성별이 섞인 묶음은 mixed 방(couple·family)에만
// 들어간다.
//
// 예전에는 성별을 넘는 간선을 조용히 버렸고, couple·family 방은 아무리 만들어
// 둬도 한 번도 쓰이지 않았다.
//
// 묶음은 쪼개지 않고, 큰 묶음부터 채운다(FFD). 자리가 없으면 억지로 넣지 않고
// 사유와 함께 남긴다 — 담당자가 보고 방을 늘리는 편이 낫다.
//
// **여유 자리(extraCapacity)는 마지막에 쓴다.** 2인실에 간이침대를 하나 더
// 놓을 수 있다 해도, 다른 방에 정상 자리가 남아 있는 동안에는 깔지 않는다.
// 그래서 배치를 두 번 돈다 — 먼저 정원까지만, 그래도 남는 사람이 있으면
// 그때 여유를 연다.
//
// rooms: [{id, capacity, extraCapacity?, gender('M'|'F'|'mixed'), roomType(...)}]
// people: [{id, gender('M'|'F'|null)}]
// roommateEdges: [fromId, toId][] (수락된 것만)
// familyEdges:   [fromId, toId][] (수락 + 동행 관계. roommateEdges 의 부분집합)
// 반환: { assignments: [{roomId, registrationId}], unplaced: [{registrationId, reason}] }
export function assignRooms({ rooms, people, roommateEdges, familyEdges = [] }) {
  const assignments = [];
  const unplaced = [];
  const genderOf = new Map(people.map((p) => [p.id, p.gender]));

  // 성별이 있는 사람만 자동 배정 대상이다.
  const placeable = people.filter((p) => p.gender === 'M' || p.gender === 'F');
  const placeableIds = placeable.map((p) => p.id);
  const idSet = new Set(placeableIds);

  const key = (a, b) => (a < b ? `${a}|${b}` : `${b}|${a}`);
  const familySet = new Set(familyEdges.map(([a, b]) => key(a, b)));

  // 쓸 수 있는 간선만 남긴다.
  //   · 같은 성별            → 그대로
  //   · 성별이 다르면        → 동행으로 수락된 짝만
  // 동행이 아닌 이성 간선은 여기서 버린다. 버리는 것이 맞다 — 요청 단계에서
  // 이미 막고 있고(buddy_requests), 옛 데이터가 남아 있을 수 있다.
  const edges = roommateEdges.filter(([a, b]) => {
    if (!idSet.has(a) || !idSet.has(b)) return false;
    if (genderOf.get(a) === genderOf.get(b)) return true;
    return familySet.has(key(a, b));
  });

  let units = connectedComponents(placeableIds, edges);
  units.sort((a, b) => b.length - a.length); // 큰 묶음 먼저

  // 남은 정원을 추적한다. 성별이 섞인 묶음은 mixed 방만 쓸 수 있다.
  const pool = rooms.map((r) => ({
    id: r.id,
    remaining: r.capacity,
    // 간이침대. 정원이 다 찼을 때에만 연다.
    extra: Math.max(0, Number(r.extraCapacity ?? 0) || 0),
    gender: r.gender,
    roomType: r.roomType,
  }));

  const fits = (d, unit, mixed, genders, useExtra) => {
    const room = d.remaining + (useExtra ? d.extra : 0);
    if (room < unit.length) return false;
    if (mixed) return d.gender === 'mixed';
    // 단일 성별 묶음은 그 성별의 단체실에 넣는다. mixed 방은 동행용으로
    // 남겨 둔다 — 부부용 2인실을 혼자 온 사람으로 채우면 정작 필요한 짝이
    // 들어갈 자리가 없어진다.
    return d.roomType === 'dorm' && d.gender === [...genders][0];
  };

  const take = (d, n) => {
    const fromNormal = Math.min(d.remaining, n);
    d.remaining -= fromNormal;
    d.extra -= n - fromNormal;
  };

  const leftover = [];
  for (const unit of units) {
    const genders = new Set(unit.map((id) => genderOf.get(id)));
    const mixed = genders.size > 1;

    // 1차: 정원 안에서만 찾는다.
    const room = pool.find((d) => fits(d, unit, mixed, genders, false));
    if (!room) {
      leftover.push({ unit, mixed, genders });
      continue;
    }
    take(room, unit.length);
    for (const id of unit) assignments.push({ roomId: room.id, registrationId: id });
  }

  // 2차: 남은 사람에게만 여유 자리를 연다.
  for (const { unit, mixed, genders } of leftover) {
    const room = pool.find((d) => fits(d, unit, mixed, genders, true));
    if (!room) {
      for (const id of unit) {
        unplaced.push({
          registrationId: id,
          reason: mixed
            ? 'no_mixed_room'
            : unit.length > 1
              ? 'unit_too_large_or_full'
              : 'no_space',
        });
      }
      continue;
    }
    take(room, unit.length);
    for (const id of unit) assignments.push({ roomId: room.id, registrationId: id });
  }

  // 성별 미기입자는 자동 배정 대상 제외
  for (const p of people) {
    if (p.gender !== 'M' && p.gender !== 'F') {
      unplaced.push({ registrationId: p.id, reason: 'no_gender' });
    }
  }
  return { assignments, unplaced };
}

// ── 연령대 ────────────────────────────────────────────────────
// Adulto 20세 이상 / Junior 19세 이하.
//
// 나이를 모르면 adulto 로 본다. 성인을 junior 조에 넣는 것보다 그 반대가
// 덜 어색하고, 무엇보다 나이를 안 적었다고 배정에서 빠지면 안 된다.
export const ADULT_MIN_AGE = 20;

export function ageBandOf(age) {
  return typeof age === 'number' && age < ADULT_MIN_AGE ? 'junior' : 'adulto';
}

// ── 말씀조 자동 배정 ──────────────────────────────────────────
//
// 조는 **언어로 먼저 갈리고, 그 안에서 연령대로** 나뉜다. 말이 통하지 않으면
// 공부가 되지 않으므로 언어가 먼저다.
//
// 칸(cohort) 안에서는 예전 로직을 그대로 쓴다 — 묶음은 쪼개지 않고, 인원이
// 적은 조부터, 성비가 기우는 쪽을 피해서. 이미 검증된 부분이라 손대지 않는다.
//
// **인원이 적은 칸**은 관리자가 미리 정해 둔 방침대로 처리한다(025):
//   absorb — 같은 언어의 adulto 칸으로 올린다 (말이 통하는 쪽 우선)
//   merge  — 같은 연령대의 다른 언어 칸과 합친다 (또래 우선)
//   keep   — 그대로 둔다. 받을 조가 없으면 미배정으로 남긴다
//
// 조용히 옮기지 않고 무엇을 왜 옮겼는지 notes 로 돌려준다. 자동으로 처리하고
// 말면 관리자는 "왜 스페인어 아이가 한국어 조에 있지"를 영영 알 수 없다.
//
// groups: [{id, studyLanguage?, ageBand?}]  — 둘 다 없으면 아무나 받는 조
// people: [{id, gender, age, studyLanguage?}]
// groupEdges: [fromId,toId][] (수락된 것만)
// policy: 'absorb' | 'merge' | 'keep'   minTeamSize: number
// 반환: { assignments, unplaced: [{registrationId, reason}], notes: [{cohort, action, count}] }
export function assignGroups({
  groups,
  people,
  groupEdges,
  policy = 'keep',
  minTeamSize = 5,
}) {
  const assignments = [];
  const unplaced = [];
  const notes = [];
  if (groups.length === 0) return { assignments, unplaced, notes };

  const byId = new Map(people.map((p) => [p.id, p]));
  const ids = people.map((p) => p.id);
  const units = connectedComponents(ids, groupEdges);

  // 묶음 하나가 어느 칸에 속하는가.
  //
  // 언어는 최빈값. 연령대는 한 명이라도 성인이면 adulto 다 — 부모와 자녀가
  // 같이 공부하겠다고 지목했으면 junior 조가 아니라 adulto 조로 간다.
  const unitInfo = units.map((u) => {
    const members = u.map((id) => byId.get(id)).filter(Boolean);
    const ages = members.map((p) => p.age).filter((a) => typeof a === 'number');
    const avgAge = ages.length ? ages.reduce((s, a) => s + a, 0) / ages.length : 999;

    const langCount = new Map();
    for (const p of members) {
      const l = p.studyLanguage ?? null;
      langCount.set(l, (langCount.get(l) ?? 0) + 1);
    }
    let language = null;
    let top = -1;
    for (const [l, n] of langCount) {
      if (n > top) { top = n; language = l; }
    }

    const band = members.some((p) => ageBandOf(p.age) === 'adulto') ? 'adulto' : 'junior';

    return {
      members: u,
      avgAge,
      language,
      band,
      male: members.filter((p) => p.gender === 'M').length,
      female: members.filter((p) => p.gender === 'F').length,
      size: u.length,
    };
  });

  const key = (language, band) => `${language ?? '-'} ${band}`;

  // 칸별로 묶음을 모은다
  const cohorts = new Map();
  for (const unit of unitInfo) {
    const k = key(unit.language, unit.band);
    if (!cohorts.has(k)) {
      cohorts.set(k, { language: unit.language, band: unit.band, units: [], size: 0 });
    }
    const c = cohorts.get(k);
    c.units.push(unit);
    c.size += unit.size;
  }

  // 조가 어느 칸을 받는가. 025 이전에 만든 조는 둘 다 null 이라 아무나 받는다.
  const state = groups.map((g) => ({
    id: g.id,
    language: g.studyLanguage ?? null,
    band: g.ageBand ?? null,
    // 정원(051). 안 정했으면 null 이고, 그때는 예전처럼 고르게 나눈다.
    capacity:
      typeof g.capacity === 'number' && g.capacity > 0 ? g.capacity : null,
    size: 0,
    male: 0,
    female: 0,
  }));
  const openGroups = state.filter((s) => s.language === null && s.band === null);

  const groupsFor = (language, band) => {
    const exact = state.filter((s) => s.language === language && s.band === band);
    return exact.length ? exact : openGroups;
  };

  // 방침에 따라 이 칸을 어디로 보낼지 정한다. 옮겼으면 notes 에 남긴다.
  const resolve = (cohort) => {
    const own = groupsFor(cohort.language, cohort.band);
    const big = cohort.size >= minTeamSize;
    if (big && own.length) return own;

    const label = `${cohort.language ?? '?'}·${cohort.band}`;

    if (!big && policy === 'absorb' && cohort.band === 'junior') {
      const up = groupsFor(cohort.language, 'adulto');
      if (up.length && up !== own) {
        notes.push({ cohort: label, action: 'absorbed', count: cohort.size });
        return up;
      }
    }
    if (!big && policy === 'merge') {
      const peers = state.filter((s) => s.band === cohort.band && s.language !== cohort.language);
      if (peers.length) {
        notes.push({ cohort: label, action: 'merged', count: cohort.size });
        return peers;
      }
    }

    if (own.length) return own;

    // 받을 조가 없다. 억지로 아무 데나 넣지 않는다 — 담당자가 조를 만드는 편이 낫다.
    notes.push({ cohort: label, action: 'unplaced', count: cohort.size });
    return [];
  };

  for (const cohort of cohorts.values()) {
    const targets = resolve(cohort);
    if (targets.length === 0) {
      for (const unit of cohort.units) {
        for (const id of unit.members) {
          unplaced.push({ registrationId: id, reason: 'no_matching_group' });
        }
      }
      continue;
    }

    // 칸 안에서는 예전 로직 그대로 — 연령 순으로 처리해 조마다 고르게 섞는다.
    const ordered = [...cohort.units].sort((a, b) => a.avgAge - b.avgAge);
    for (const unit of ordered) {
      const dominant = unit.male >= unit.female ? 'male' : 'female';
      // 정원이 남은 조를 먼저 본다(051). **다 찼다고 사람을 빼지는
      // 않는다** — 조가 없는 참가자를 만드는 것이 정원을 한 명 넘기는
      // 것보다 나쁘다. 그런 경우는 넘겼다고 적어 둔다.
      const roomy = targets.filter(
        (s) => s.capacity === null || s.size + unit.size <= s.capacity,
      );
      const pool = roomy.length > 0 ? roomy : targets;
      let best = null;
      for (const s of pool) {
        if (
          best === null ||
          s.size < best.size ||
          (s.size === best.size && s[dominant] < best[dominant])
        ) {
          best = s;
        }
      }
      if (roomy.length === 0) {
        notes.push({
          cohort: `${cohort.language ?? '?'}·${cohort.band}`,
          action: 'over_capacity',
          count: unit.size,
        });
      }
      best.size += unit.size;
      best.male += unit.male;
      best.female += unit.female;
      for (const id of unit.members) assignments.push({ groupId: best.id, registrationId: id });
    }
  }

  return { assignments, unplaced, notes };
}
