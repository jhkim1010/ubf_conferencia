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
// 단체실(dorm)만 대상. 같은 성별끼리, 묶음은 쪼개지 않고, 정원 준수(FFD).
// rooms: [{id, capacity, gender('M'|'F'|'mixed'), roomType}]
// people: [{id, gender('M'|'F'|null)}]
// roommateEdges: [fromId, toId][] (수락된 것만)
// 반환: { assignments: [{roomId, registrationId}], unplaced: [{registrationId, reason}] }
export function assignRooms({ rooms, people, roommateEdges }) {
  const assignments = [];
  const unplaced = [];
  const genderOf = new Map(people.map((p) => [p.id, p.gender]));

  for (const G of ['M', 'F']) {
    const ids = people.filter((p) => p.gender === G).map((p) => p.id);
    // 이 성별 내부의 간선만으로 묶음 계산
    const idSet = new Set(ids);
    const edges = roommateEdges.filter(([a, b]) => idSet.has(a) && idSet.has(b));
    let units = connectedComponents(ids, edges);
    // 큰 묶음 먼저 (first-fit decreasing)
    units.sort((a, b) => b.length - a.length);

    // 이 성별의 단체실 (남은 정원 추적)
    const dorms = rooms
      .filter((r) => r.roomType === 'dorm' && r.gender === G)
      .map((r) => ({ id: r.id, remaining: r.capacity }));

    for (const unit of units) {
      const room = dorms.find((d) => d.remaining >= unit.length);
      if (!room) {
        for (const id of unit) {
          unplaced.push({
            registrationId: id,
            reason: unit.length > 1 ? 'unit_too_large_or_full' : 'no_space',
          });
        }
        continue;
      }
      room.remaining -= unit.length;
      for (const id of unit) assignments.push({ roomId: room.id, registrationId: id });
    }
  }

  // 성별 미기입자는 자동 배정 대상 제외
  for (const p of people) {
    if (p.gender !== 'M' && p.gender !== 'F') {
      unplaced.push({ registrationId: p.id, reason: 'no_gender' });
    }
  }
  void genderOf;
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
