// 배정 엔진 테스트 — DB 비의존 순수 함수
// 실행: cd server && npm test
//
// 핵심 불변식: 지목으로 묶인 사람은 절대 쪼개지지 않는다, 성별 방침을 넘지 않는다,
// 정원을 넘지 않는다. 이 셋이 깨지면 현장에서 사람이 다시 배정해야 한다.

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  connectedComponents,
  assignRooms,
  assignGroups,
  ageBandOf,
} from '../src/services/assignment_engine.js';

// 묶음 배열을 비교 가능한 정규형으로 (내부 정렬 + 사전순 정렬)
const norm = (groups) =>
  groups.map((g) => [...g].sort()).sort((a, b) => a[0].localeCompare(b[0]));

// registrationId → roomId / groupId
const byPerson = (assignments, key) =>
  Object.fromEntries(assignments.map((a) => [a.registrationId, a[key]]));

describe('connectedComponents', () => {
  test('간선이 없으면 각자 하나의 묶음', () => {
    assert.deepEqual(norm(connectedComponents(['a', 'b', 'c'], [])), [['a'], ['b'], ['c']]);
  });

  test('사슬로 이어지면 하나의 묶음이 된다', () => {
    assert.deepEqual(norm(connectedComponents(['a', 'b', 'c'], [['a', 'b'], ['b', 'c']])), [
      ['a', 'b', 'c'],
    ]);
  });

  test('분리된 묶음을 각각 인식한다', () => {
    const r = connectedComponents(['a', 'b', 'c', 'd'], [['a', 'b'], ['c', 'd']]);
    assert.deepEqual(norm(r), [['a', 'b'], ['c', 'd']]);
  });

  test('양방향 중복 간선을 견딘다', () => {
    const r = connectedComponents(['a', 'b'], [['a', 'b'], ['b', 'a'], ['a', 'b']]);
    assert.deepEqual(norm(r), [['a', 'b']]);
  });

  test('자기 자신을 향한 간선을 견딘다', () => {
    assert.deepEqual(norm(connectedComponents(['a'], [['a', 'a']])), [['a']]);
  });

  test('알 수 없는 노드가 포함된 간선은 무시된다', () => {
    const r = connectedComponents(['a', 'b'], [['a', 'ghost'], ['a', 'b']]);
    assert.deepEqual(norm(r), [['a', 'b']]);
  });

  test('빈 입력에서 빈 결과', () => {
    assert.deepEqual(connectedComponents([], []), []);
  });

  test('모든 노드가 정확히 한 번씩 나타난다', () => {
    const ids = ['a', 'b', 'c', 'd', 'e'];
    const r = connectedComponents(ids, [['a', 'b'], ['d', 'e']]);
    assert.deepEqual(r.flat().sort(), [...ids].sort());
  });
});

describe('assignRooms', () => {
  const dorm = (id, capacity, gender) => ({ id, capacity, gender, roomType: 'dorm' });
  const mixedRoom = (id, capacity, roomType = 'couple') => ({
    id,
    capacity,
    gender: 'mixed',
    roomType,
  });

  // ── 동행자는 성별이 달라도 같은 방 (022) ───────────────────
  //
  // 예전에는 성별을 넘는 간선을 조용히 버려서, 부부가 같은 방을 신청해도
  // 각자 다른 단체실로 흩어졌다. couple·family 방을 만들어 둬도 자동 배정이
  // dorm 만 보고 있어 한 번도 쓰이지 않았다.

  test('동행으로 수락된 짝은 성별이 달라도 mixed 방에 함께 들어간다', () => {
    const { assignments, unplaced } = assignRooms({
      rooms: [dorm('m1', 4, 'M'), dorm('f1', 4, 'F'), mixedRoom('c1', 2)],
      people: [
        { id: 'husband', gender: 'M' },
        { id: 'wife', gender: 'F' },
      ],
      roommateEdges: [['husband', 'wife']],
      familyEdges: [['husband', 'wife']],
    });
    assert.equal(unplaced.length, 0);
    assert.deepEqual(byPerson(assignments, 'roomId'), {
      husband: 'c1',
      wife: 'c1',
    });
  });

  test('동행 관계가 아니면 이성 간선은 무시하고 각자 배정한다', () => {
    const { assignments } = assignRooms({
      rooms: [dorm('m1', 4, 'M'), dorm('f1', 4, 'F'), mixedRoom('c1', 2)],
      people: [
        { id: 'a', gender: 'M' },
        { id: 'b', gender: 'F' },
      ],
      roommateEdges: [['a', 'b']], // familyEdges 없음
    });
    assert.deepEqual(byPerson(assignments, 'roomId'), { a: 'm1', b: 'f1' });
  });

  test('mixed 방이 없으면 억지로 넣지 않고 사유를 남긴다', () => {
    // 억지로 단체실에 넣으면 혼숙이 된다. 담당자가 보고 방을 늘려야 한다.
    const { assignments, unplaced } = assignRooms({
      rooms: [dorm('m1', 4, 'M'), dorm('f1', 4, 'F')],
      people: [
        { id: 'husband', gender: 'M' },
        { id: 'wife', gender: 'F' },
      ],
      roommateEdges: [['husband', 'wife']],
      familyEdges: [['husband', 'wife']],
    });
    assert.equal(assignments.length, 0);
    assert.deepEqual(
      unplaced.map((u) => u.reason).sort(),
      ['no_mixed_room', 'no_mixed_room'],
    );
  });

  test('mixed 방은 동행용으로 남긴다 — 혼자 온 사람으로 채우지 않는다', () => {
    // 부부용 2인실을 먼저 채워버리면 정작 필요한 짝이 들어갈 자리가 없어진다.
    const { assignments } = assignRooms({
      rooms: [mixedRoom('c1', 2), dorm('m1', 4, 'M')],
      people: [{ id: 'solo', gender: 'M' }],
      roommateEdges: [],
    });
    assert.deepEqual(byPerson(assignments, 'roomId'), { solo: 'm1' });
  });

  test('가족 3인(부·모·자녀)도 한 방에 묶인다', () => {
    const { assignments, unplaced } = assignRooms({
      rooms: [mixedRoom('fam1', 4, 'family'), dorm('m1', 8, 'M')],
      people: [
        { id: 'dad', gender: 'M' },
        { id: 'mom', gender: 'F' },
        { id: 'son', gender: 'M' },
      ],
      roommateEdges: [
        ['dad', 'mom'],
        ['dad', 'son'],
      ],
      familyEdges: [
        ['dad', 'mom'],
        ['dad', 'son'],
      ],
    });
    assert.equal(unplaced.length, 0);
    assert.deepEqual(byPerson(assignments, 'roomId'), {
      dad: 'fam1',
      mom: 'fam1',
      son: 'fam1',
    });
  });

  test('같은 성별 요청은 지금까지처럼 단체실에 함께 들어간다', () => {
    const { assignments } = assignRooms({
      rooms: [dorm('m1', 8, 'M'), mixedRoom('c1', 2)],
      people: [
        { id: 'a', gender: 'M' },
        { id: 'b', gender: 'M' },
      ],
      roommateEdges: [['a', 'b']],
      familyEdges: [],
    });
    assert.deepEqual(byPerson(assignments, 'roomId'), { a: 'm1', b: 'm1' });
  });


  test('성별에 맞는 방에만 배정한다', () => {
    const { assignments } = assignRooms({
      rooms: [dorm('m1', 4, 'M'), dorm('f1', 4, 'F')],
      people: [
        { id: 'm', gender: 'M' },
        { id: 'f', gender: 'F' },
      ],
      roommateEdges: [],
    });
    assert.deepEqual(byPerson(assignments, 'roomId'), { m: 'm1', f: 'f1' });
  });

  test('dorm 이 아닌 방에는 배정하지 않는다', () => {
    const { assignments, unplaced } = assignRooms({
      rooms: [{ id: 'suite', capacity: 4, gender: 'M', roomType: 'private' }],
      people: [{ id: 'm', gender: 'M' }],
      roommateEdges: [],
    });
    assert.deepEqual(assignments, []);
    assert.equal(unplaced[0].registrationId, 'm');
  });

  test('단일 성별 묶음은 mixed 방에 들어가지 않는다', () => {
    // 022 로 동행 짝은 mixed 방을 쓰게 됐지만, 혼자 온 사람을 혼숙 방에 넣는
    // 것은 여전히 사람이 판단할 일이다.
    const { assignments } = assignRooms({
      rooms: [dorm('x', 4, 'mixed')],
      people: [{ id: 'm', gender: 'M' }],
      roommateEdges: [],
    });
    assert.deepEqual(assignments, [], '혼숙 방은 사람이 판단해야 한다');
  });

  test('지목으로 묶인 사람은 같은 방에 들어간다', () => {
    const { assignments } = assignRooms({
      rooms: [dorm('r1', 2, 'M'), dorm('r2', 2, 'M')],
      people: [
        { id: 'a', gender: 'M' },
        { id: 'b', gender: 'M' },
        { id: 'c', gender: 'M' },
        { id: 'd', gender: 'M' },
      ],
      roommateEdges: [['a', 'b']],
    });
    const m = byPerson(assignments, 'roomId');
    assert.equal(m.a, m.b, '묶음은 절대 쪼개지지 않아야 한다');
  });

  test('묶음이 어떤 방에도 안 들어가면 통째로 미배정된다', () => {
    const { assignments, unplaced } = assignRooms({
      rooms: [dorm('r1', 2, 'M')],
      people: [
        { id: 'a', gender: 'M' },
        { id: 'b', gender: 'M' },
        { id: 'c', gender: 'M' },
      ],
      roommateEdges: [['a', 'b'], ['b', 'c']], // 3인 묶음, 정원 2
    });
    assert.deepEqual(assignments, [], '쪼개서 밀어넣지 않아야 한다');
    assert.equal(unplaced.length, 3);
    for (const u of unplaced) assert.equal(u.reason, 'unit_too_large_or_full');
  });

  test('정원을 넘겨 배정하지 않는다', () => {
    const { assignments, unplaced } = assignRooms({
      rooms: [dorm('r1', 2, 'M')],
      people: [
        { id: 'a', gender: 'M' },
        { id: 'b', gender: 'M' },
        { id: 'c', gender: 'M' },
      ],
      roommateEdges: [],
    });
    assert.equal(assignments.length, 2);
    assert.deepEqual(unplaced.map((u) => u.reason), ['no_space']);
  });

  test('큰 묶음을 먼저 배치한다 (first-fit decreasing)', () => {
    // 3인 묶음이 먼저 r1(정원 3)을 차지하고, 단독 1인은 r2 로 간다.
    const { assignments } = assignRooms({
      rooms: [dorm('r1', 3, 'M'), dorm('r2', 3, 'M')],
      people: ['a', 'b', 'c', 'z'].map((id) => ({ id, gender: 'M' })),
      roommateEdges: [['a', 'b'], ['b', 'c']],
    });
    const m = byPerson(assignments, 'roomId');
    assert.equal(m.a, m.b);
    assert.equal(m.b, m.c);
    assert.notEqual(m.z, m.a, '큰 묶음이 방 하나를 온전히 차지해야 한다');
  });

  test('성별을 넘는 지목은 무시된다', () => {
    const { assignments } = assignRooms({
      rooms: [dorm('m1', 4, 'M'), dorm('f1', 4, 'F')],
      people: [
        { id: 'm', gender: 'M' },
        { id: 'f', gender: 'F' },
      ],
      roommateEdges: [['m', 'f']],
    });
    const map = byPerson(assignments, 'roomId');
    assert.equal(map.m, 'm1');
    assert.equal(map.f, 'f1');
  });

  test('성별 미기입자는 no_gender 로 제외된다', () => {
    const { assignments, unplaced } = assignRooms({
      rooms: [dorm('m1', 4, 'M')],
      people: [
        { id: 'ok', gender: 'M' },
        { id: 'none', gender: null },
        { id: 'other', gender: 'X' },
      ],
      roommateEdges: [],
    });
    assert.deepEqual(byPerson(assignments, 'roomId'), { ok: 'm1' });
    const r = Object.fromEntries(unplaced.map((u) => [u.registrationId, u.reason]));
    assert.deepEqual(r, { none: 'no_gender', other: 'no_gender' });
  });

  test('누구도 두 번 배정되지 않는다', () => {
    const { assignments } = assignRooms({
      rooms: [dorm('r1', 5, 'M'), dorm('r2', 5, 'M')],
      people: ['a', 'b', 'c', 'd'].map((id) => ({ id, gender: 'M' })),
      roommateEdges: [['a', 'b']],
    });
    const ids = assignments.map((a) => a.registrationId);
    assert.equal(new Set(ids).size, ids.length);
  });

  test('빈 입력에서 안전하게 동작한다', () => {
    assert.deepEqual(assignRooms({ rooms: [], people: [], roommateEdges: [] }), {
      assignments: [],
      unplaced: [],
    });
  });
});

describe('assignGroups', () => {
  const people = (n, opts = {}) =>
    Array.from({ length: n }, (_, i) => ({
      id: `p${i}`,
      gender: opts.gender ?? (i % 2 === 0 ? 'M' : 'F'),
      age: opts.age ?? 20 + i,
    }));

  test('조가 없으면 배정도 없다', () => {
    const r = assignGroups({ groups: [], people: people(4), groupEdges: [] });
    assert.deepEqual(r.assignments, []);
  });

  test('모든 사람이 정확히 한 조에 배정된다', () => {
    const ppl = people(9);
    const { assignments } = assignGroups({
      groups: [{ id: 'g1' }, { id: 'g2' }, { id: 'g3' }],
      people: ppl,
      groupEdges: [],
    });
    assert.equal(assignments.length, 9);
    const ids = assignments.map((a) => a.registrationId);
    assert.equal(new Set(ids).size, 9);
    assert.deepEqual(ids.sort(), ppl.map((p) => p.id).sort());
  });

  test('인원을 조마다 고르게 나눈다', () => {
    const { assignments } = assignGroups({
      groups: [{ id: 'g1' }, { id: 'g2' }, { id: 'g3' }],
      people: people(9),
      groupEdges: [],
    });
    const counts = {};
    for (const a of assignments) counts[a.groupId] = (counts[a.groupId] ?? 0) + 1;
    assert.deepEqual(Object.values(counts).sort(), [3, 3, 3]);
  });

  test('묶음은 같은 조를 유지한다', () => {
    const { assignments } = assignGroups({
      groups: [{ id: 'g1' }, { id: 'g2' }],
      people: people(6),
      groupEdges: [['p0', 'p1'], ['p1', 'p2']],
    });
    const m = byPerson(assignments, 'groupId');
    assert.equal(m.p0, m.p1);
    assert.equal(m.p1, m.p2);
  });

  test('조가 하나면 전원이 그 조로 간다', () => {
    const { assignments } = assignGroups({
      groups: [{ id: 'only' }],
      people: people(5),
      groupEdges: [],
    });
    assert.ok(assignments.every((a) => a.groupId === 'only'));
  });

  test('사람이 없으면 배정도 없다', () => {
    const r = assignGroups({ groups: [{ id: 'g1' }], people: [], groupEdges: [] });
    assert.deepEqual(r.assignments, []);
  });

  // typeof NaN === 'number' 이라 나이 필터를 통과해 평균 연령이 NaN 이 된다.
  // 그 결과 정렬 순서는 임의가 되지만 인원이 누락되어서는 안 된다.
  test('나이가 NaN 이어도 아무도 누락되지 않는다', () => {
    const { assignments } = assignGroups({
      groups: [{ id: 'g1' }, { id: 'g2' }],
      people: [
        { id: 'a', gender: 'M', age: NaN },
        { id: 'b', gender: 'F', age: 30 },
        { id: 'c', gender: 'M', age: 25 },
      ],
      groupEdges: [],
    });
    assert.equal(assignments.length, 3);
    assert.deepEqual(assignments.map((a) => a.registrationId).sort(), ['a', 'b', 'c']);
  });

  test('나이가 없어도 배정된다', () => {
    const { assignments } = assignGroups({
      groups: [{ id: 'g1' }, { id: 'g2' }],
      people: [
        { id: 'a', gender: 'M' },
        { id: 'b', gender: 'F' },
      ],
      groupEdges: [],
    });
    assert.equal(assignments.length, 2);
  });

  test('큰 묶음이 있어도 전원이 배정된다', () => {
    const { assignments } = assignGroups({
      groups: [{ id: 'g1' }, { id: 'g2' }],
      people: people(6),
      groupEdges: [['p0', 'p1'], ['p1', 'p2'], ['p2', 'p3'], ['p3', 'p4'], ['p4', 'p5']],
    });
    assert.equal(assignments.length, 6);
    const m = byPerson(assignments, 'groupId');
    assert.equal(new Set(Object.values(m)).size, 1, '전원이 한 묶음이면 한 조로 간다');
  });
});

// ── 언어 × 연령대 편성 (025) ─────────────────────────────────
//
// 말이 통하지 않으면 공부가 되지 않으므로 언어가 먼저다. 언어는 짐작하지 않고
// 참석자가 직접 고른 값(study_language)을 쓴다.
describe('assignGroups — 언어와 연령대', () => {
  const P = (id, lang, age, gender = 'M') => ({ id, studyLanguage: lang, age, gender });
  const G = (id, lang, band) => ({ id, studyLanguage: lang, ageBand: band });
  const where = (assignments, id) =>
    assignments.find((a) => a.registrationId === id)?.groupId;

  test('언어가 다르면 다른 조로 간다', () => {
    const { assignments } = assignGroups({
      groups: [G('es', 'es', 'adulto'), G('ko', 'ko', 'adulto')],
      people: [P('a', 'es', 30), P('b', 'es', 40), P('c', 'ko', 30), P('d', 'ko', 40)],
      groupEdges: [],
    });
    assert.equal(where(assignments, 'a'), 'es');
    assert.equal(where(assignments, 'b'), 'es');
    assert.equal(where(assignments, 'c'), 'ko');
    assert.equal(where(assignments, 'd'), 'ko');
  });

  test('20세는 adulto, 19세는 junior', () => {
    assert.equal(ageBandOf(20), 'adulto');
    assert.equal(ageBandOf(19), 'junior');
    // 나이를 안 적었다고 배정에서 빠지면 안 된다.
    assert.equal(ageBandOf(null), 'adulto');
    assert.equal(ageBandOf(undefined), 'adulto');
  });

  test('같은 언어라도 연령대가 다르면 갈린다', () => {
    const { assignments } = assignGroups({
      groups: [G('esA', 'es', 'adulto'), G('esJ', 'es', 'junior')],
      people: [P('grown', 'es', 35), P('teen', 'es', 16)],
      groupEdges: [],
    });
    assert.equal(where(assignments, 'grown'), 'esA');
    assert.equal(where(assignments, 'teen'), 'esJ');
  });

  test('부모와 자녀가 함께 지목하면 adulto 로 간다', () => {
    // 묶음에 성인이 한 명이라도 있으면 junior 조가 아니라 adulto 조다.
    const { assignments } = assignGroups({
      groups: [G('esA', 'es', 'adulto'), G('esJ', 'es', 'junior')],
      people: [P('parent', 'es', 45), P('child', 'es', 15)],
      groupEdges: [['parent', 'child']],
    });
    assert.equal(where(assignments, 'parent'), 'esA');
    assert.equal(where(assignments, 'child'), 'esA', '묶음은 쪼개지지 않는다');
  });

  test('025 이전 조(속성 없음)는 아무나 받는다', () => {
    // 기존 수양회의 배정이 깨지면 안 된다.
    const { assignments, unplaced } = assignGroups({
      groups: [{ id: 'old1' }, { id: 'old2' }],
      people: [P('a', 'es', 30), P('b', 'ko', 16)],
      groupEdges: [],
    });
    assert.equal(assignments.length, 2);
    assert.deepEqual(unplaced, []);
  });
});

describe('assignGroups — 인원이 적은 칸', () => {
  const P = (id, lang, age) => ({ id, studyLanguage: lang, age, gender: 'M' });
  const G = (id, lang, band) => ({ id, studyLanguage: lang, ageBand: band });
  const where = (assignments, id) =>
    assignments.find((a) => a.registrationId === id)?.groupId;

  // 스페인어 Junior 2명 + 스페인어 Adulto 6명. 최소 5명.
  const setup = (policy) =>
    assignGroups({
      groups: [G('esA', 'es', 'adulto'), G('esJ', 'es', 'junior'), G('koJ', 'ko', 'junior')],
      people: [
        P('j1', 'es', 15), P('j2', 'es', 16),
        P('a1', 'es', 30), P('a2', 'es', 31), P('a3', 'es', 32),
        P('a4', 'es', 33), P('a5', 'es', 34), P('a6', 'es', 35),
      ],
      groupEdges: [],
      policy,
      minTeamSize: 5,
    });

  test('absorb — 같은 언어의 adulto 조로 올라간다', () => {
    const { assignments, notes } = setup('absorb');
    assert.equal(where(assignments, 'j1'), 'esA');
    assert.equal(where(assignments, 'j2'), 'esA');
    // 왜 옮겼는지 남긴다. 조용히 옮기면 관리자가 이유를 알 수 없다.
    assert.ok(notes.some((n) => n.action === 'absorbed' && n.count === 2));
  });

  test('merge — 같은 연령대의 다른 언어 조로 간다', () => {
    const { assignments, notes } = setup('merge');
    assert.equal(where(assignments, 'j1'), 'koJ');
    assert.equal(where(assignments, 'j2'), 'koJ');
    assert.ok(notes.some((n) => n.action === 'merged' && n.count === 2));
  });

  test('keep — 그대로 자기 조에 남는다', () => {
    const { assignments, notes } = setup('keep');
    assert.equal(where(assignments, 'j1'), 'esJ');
    assert.equal(where(assignments, 'j2'), 'esJ');
    assert.equal(notes.length, 0, '옮기지 않았으므로 남길 것도 없다');
  });

  test('keep 인데 받을 조가 없으면 미배정으로 남긴다', () => {
    // 억지로 아무 조에나 넣지 않는다 — 담당자가 조를 만드는 편이 낫다.
    const { assignments, unplaced, notes } = assignGroups({
      groups: [G('esA', 'es', 'adulto')],
      people: [P('j1', 'es', 15), P('j2', 'es', 16)],
      groupEdges: [],
      policy: 'keep',
      minTeamSize: 5,
    });
    assert.equal(assignments.length, 0);
    assert.equal(unplaced.length, 2);
    assert.ok(notes.some((n) => n.action === 'unplaced'));
  });

  test('인원이 충분하면 방침과 무관하게 자기 칸에 남는다', () => {
    for (const policy of ['absorb', 'merge', 'keep']) {
      const { assignments, notes } = assignGroups({
        groups: [G('esA', 'es', 'adulto'), G('esJ', 'es', 'junior')],
        people: [
          P('j1', 'es', 15), P('j2', 'es', 16), P('j3', 'es', 17),
          P('j4', 'es', 18), P('j5', 'es', 19),
        ],
        groupEdges: [],
        policy,
        minTeamSize: 5,
      });
      assert.equal(where(assignments, 'j1'), 'esJ', `${policy}: 5명이면 그대로 둔다`);
      assert.equal(notes.length, 0, `${policy}: 옮기지 않았다`);
    }
  });
});
