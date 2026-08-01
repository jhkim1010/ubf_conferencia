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
// rooms: [{id, capacity, gender('M'|'F'|'mixed'), roomType('dorm'|'couple'|'family')}]
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
    gender: r.gender,
    roomType: r.roomType,
  }));

  for (const unit of units) {
    const genders = new Set(unit.map((id) => genderOf.get(id)));
    const mixed = genders.size > 1;

    const room = pool.find((d) => {
      if (d.remaining < unit.length) return false;
      if (mixed) return d.gender === 'mixed';
      // 단일 성별 묶음은 그 성별의 단체실에 넣는다. mixed 방은 동행용으로
      // 남겨 둔다 — 부부용 2인실을 혼자 온 사람으로 채우면 정작 필요한 짝이
      // 들어갈 자리가 없어진다.
      return d.roomType === 'dorm' && d.gender === [...genders][0];
    });

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
    room.remaining -= unit.length;
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

// ── 말씀조 자동 배정 ──────────────────────────────────────────
// 묶음은 같은 조 유지. 연령·성비를 조마다 고르게(least-loaded + 성비 tiebreak,
// 묶음을 평균연령 순으로 처리해 연령을 분산).
// groups: [{id}]  people: [{id, gender, age}]  groupEdges: [fromId,toId][]
// 반환: { assignments: [{groupId, registrationId}] }
export function assignGroups({ groups, people, groupEdges }) {
  const assignments = [];
  if (groups.length === 0) return { assignments };

  const byId = new Map(people.map((p) => [p.id, p]));
  const ids = people.map((p) => p.id);
  let units = connectedComponents(ids, groupEdges);

  // 각 묶음의 평균 연령·성별 구성
  const unitInfo = units.map((u) => {
    const ages = u.map((id) => byId.get(id)?.age).filter((a) => typeof a === 'number');
    const avgAge = ages.length ? ages.reduce((s, a) => s + a, 0) / ages.length : 999;
    const male = u.filter((id) => byId.get(id)?.gender === 'M').length;
    const female = u.filter((id) => byId.get(id)?.gender === 'F').length;
    return { members: u, avgAge, male, female, size: u.length };
  });
  // 연령 순으로 처리 → 조마다 연령대가 고르게 섞이도록
  unitInfo.sort((a, b) => a.avgAge - b.avgAge);

  // 조 상태
  const state = groups.map((g) => ({ id: g.id, size: 0, male: 0, female: 0 }));

  for (const unit of unitInfo) {
    // 1순위: 인원 적은 조 / 2순위: 이 묶음의 우세 성별이 적은 조
    const dominant = unit.male >= unit.female ? 'male' : 'female';
    let best = null;
    for (const s of state) {
      if (
        best === null ||
        s.size < best.size ||
        (s.size === best.size && s[dominant] < best[dominant])
      ) {
        best = s;
      }
    }
    best.size += unit.size;
    best.male += unit.male;
    best.female += unit.female;
    for (const id of unit.members) assignments.push({ groupId: best.id, registrationId: id });
  }

  return { assignments };
}
