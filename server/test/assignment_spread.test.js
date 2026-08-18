import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  assignRooms,
  assignGroups,
  roomAgeBand,
} from '../src/services/assignment_engine.js';

// 자동 배정이 사람을 어떻게 흩는가 (057)
//
// 담당자가 자동 배정을 누르는 까닭은 손으로 짜기 싫어서가 아니라, 손으로
// 짜면 같은 지부끼리 뭉치고 어르신이 젊은 방에 섞이기 때문이다. 그것을
// 자동으로 막는 것이 이 규칙이다.

const roomOf = (assignments, id) =>
  assignments.find((a) => a.registrationId === id)?.roomId;

test('50대부터는 또래로 나눈다', () => {
  assert.equal(roomAgeBand(34), 'young');
  assert.equal(roomAgeBand(49), 'young');
  assert.equal(roomAgeBand(50), '50s');
  assert.equal(roomAgeBand(68), '60s');
  assert.equal(roomAgeBand(75), '70+');
  // 안 적은 사람은 나누지 않는다 — 0으로 두면 갓난아기가 된다.
  assert.equal(roomAgeBand(null), 'unknown');
  assert.equal(roomAgeBand(0), 'unknown');
});

test('어르신은 어르신끼리, 젊은 사람은 젊은 사람끼리', () => {
  const rooms = [
    { id: 'A', capacity: 2, gender: 'M', roomType: 'dorm' },
    { id: 'B', capacity: 2, gender: 'M', roomType: 'dorm' },
  ];
  const people = [
    { id: 'y1', gender: 'M', age: 25, country: 'AR', branch: 'X' },
    { id: 'o1', gender: 'M', age: 68, country: 'BR', branch: 'Y' },
    { id: 'y2', gender: 'M', age: 27, country: 'KR', branch: 'Z' },
    { id: 'o2', gender: 'M', age: 66, country: 'VE', branch: 'W' },
  ];
  const { assignments } = assignRooms({ rooms, people, roommateEdges: [] });
  assert.equal(roomOf(assignments, 'y1'), roomOf(assignments, 'y2'),
    '젊은 두 사람이 갈라졌다');
  assert.equal(roomOf(assignments, 'o1'), roomOf(assignments, 'o2'),
    '60대 두 분이 갈라졌다');
  assert.notEqual(roomOf(assignments, 'y1'), roomOf(assignments, 'o1'),
    '스물다섯과 예순여덟이 한 방에 들어갔다');
});

test('같은 지부는 방을 나눠 쓴다', () => {
  const rooms = [
    { id: 'A', capacity: 2, gender: 'F', roomType: 'dorm' },
    { id: 'B', capacity: 2, gender: 'F', roomType: 'dorm' },
  ];
  // 나이는 모두 같은 또래 — 출신만 다르다.
  const people = [
    { id: 'a1', gender: 'F', age: 30, country: 'AR', branch: 'La Plata' },
    { id: 'a2', gender: 'F', age: 31, country: 'AR', branch: 'La Plata' },
    { id: 'b1', gender: 'F', age: 32, country: 'BR', branch: 'Sao Paulo' },
    { id: 'b2', gender: 'F', age: 33, country: 'BR', branch: 'Sao Paulo' },
  ];
  const { assignments } = assignRooms({ rooms, people, roommateEdges: [] });
  assert.notEqual(roomOf(assignments, 'a1'), roomOf(assignments, 'a2'),
    '같은 지부 둘이 한 방에 몰렸다');
  assert.notEqual(roomOf(assignments, 'b1'), roomOf(assignments, 'b2'),
    '같은 지부 둘이 한 방에 몰렸다');
});

test('같이 있고 싶다고 수락한 짝은 흩지 않는다', () => {
  // 흩는 규칙이 지목을 이기면 안 된다 — 사람이 정한 것이 먼저다.
  const rooms = [
    { id: 'A', capacity: 2, gender: 'M', roomType: 'dorm' },
    { id: 'B', capacity: 2, gender: 'M', roomType: 'dorm' },
  ];
  const people = [
    { id: 'p1', gender: 'M', age: 30, country: 'AR', branch: 'La Plata' },
    { id: 'p2', gender: 'M', age: 31, country: 'AR', branch: 'La Plata' },
    { id: 'q1', gender: 'M', age: 32, country: 'BR', branch: 'Sao Paulo' },
    { id: 'q2', gender: 'M', age: 33, country: 'BR', branch: 'Sao Paulo' },
  ];
  const { assignments } = assignRooms({
    rooms, people, roommateEdges: [['p1', 'p2']],
  });
  assert.equal(roomOf(assignments, 'p1'), roomOf(assignments, 'p2'),
    '수락한 짝이 갈라졌다');
});

test('같은 자료로 두 번 돌리면 같은 답', () => {
  // 누를 때마다 방이 바뀌면 담당자가 손으로 고쳐 둔 것을 못 믿는다.
  const rooms = [
    { id: 'A', capacity: 3, gender: 'M', roomType: 'dorm' },
    { id: 'B', capacity: 3, gender: 'M', roomType: 'dorm' },
  ];
  const people = Array.from({ length: 6 }, (_, i) => ({
    id: `p${i}`, gender: 'M', age: 30 + i, country: 'AR', branch: `B${i % 3}`,
  }));
  const one = assignRooms({ rooms, people, roommateEdges: [] });
  const two = assignRooms({ rooms, people, roommateEdges: [] });
  assert.deepEqual(one.assignments, two.assignments);
});

test('말씀조도 같은 지부가 한 조에 몰리지 않는다', () => {
  const groups = [
    { id: 'g1', studyLanguage: null, ageBand: null },
    { id: 'g2', studyLanguage: null, ageBand: null },
  ];
  // **차례가 중요하다.** 조는 나이순으로 처리되고, 크기만 맞추면 번갈아
  // 들어가 저절로 갈라진다. 같은 지부가 나란히 오지 않게 섞어 두어야
  // 출신 규칙이 실제로 일하는지 알 수 있다 — 처음에 이 차례를 잘못 짜서
  // 규칙을 지워도 검사가 통과했다.
  //   나이순: a1(30) · b1(31) · a2(32) · b2(33)
  //   크기만 보면 g1 · g2 · g1 · g2 → a1 과 a2 가 같은 조가 된다.
  const people = [
    { id: 'a1', gender: 'M', age: 30, studyLanguage: 'es', country: 'AR', branch: 'La Plata' },
    { id: 'b1', gender: 'M', age: 31, studyLanguage: 'es', country: 'BR', branch: 'Sao Paulo' },
    { id: 'a2', gender: 'F', age: 32, studyLanguage: 'es', country: 'AR', branch: 'La Plata' },
    { id: 'b2', gender: 'F', age: 33, studyLanguage: 'es', country: 'BR', branch: 'Sao Paulo' },
  ];
  const { assignments } = assignGroups({ groups, people, groupEdges: [] });
  const g = (id) => assignments.find((a) => a.registrationId === id)?.groupId;
  assert.notEqual(g('a1'), g('a2'), '같은 지부 둘이 한 조에 몰렸다');
  assert.notEqual(g('b1'), g('b2'), '같은 지부 둘이 한 조에 몰렸다');
});

test('조 크기가 출신보다 먼저다', () => {
  // 흩겠다고 한 조에 몰아 넣으면 조가 아니라 줄이 된다.
  const groups = [
    { id: 'g1', studyLanguage: null, ageBand: null },
    { id: 'g2', studyLanguage: null, ageBand: null },
  ];
  const people = Array.from({ length: 6 }, (_, i) => ({
    id: `p${i}`, gender: i % 2 ? 'M' : 'F', age: 30,
    studyLanguage: 'es', country: 'AR', branch: 'La Plata',
  }));
  const { assignments } = assignGroups({ groups, people, groupEdges: [] });
  const sizes = new Map();
  for (const a of assignments) {
    sizes.set(a.groupId, (sizes.get(a.groupId) ?? 0) + 1);
  }
  const counts = [...sizes.values()];
  assert.ok(Math.max(...counts) - Math.min(...counts) <= 1,
    `조 크기가 벌어졌다: ${counts}`);
});
