import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { studyGroupOf, planCompanionSave } from '../src/services/companion_role.js';
import { companionGroupPeople } from '../src/services/room_occupant.js';

// 함께 등록한 동반자의 말씀조와, id 를 지키는 저장 (078)

describe('studyGroupOf', () => {
  test('함께 등록하면 고른 대로', () => {
    for (const g of ['same', 'other', 'none']) {
      assert.equal(studyGroupOf({ studyGroup: g, registersSeparately: false }), g);
    }
  });
  test('따로 등록하면 늘 none — 자기 등록으로 조에 든다', () => {
    assert.equal(studyGroupOf({ studyGroup: 'same', registersSeparately: true }), 'none');
    assert.equal(studyGroupOf({ studyGroup: 'same' }), 'none');
  });
  test('안 보냈거나 모르는 값은 none — 예전 앱으로 저장해도 아기가 조에 안 든다', () => {
    assert.equal(studyGroupOf({ registersSeparately: false }), 'none');
    assert.equal(studyGroupOf({ studyGroup: 'SAME', registersSeparately: false }), 'none');
  });
});

describe('planCompanionSave', () => {
  test('아는 id 는 고치고, 없는 것은 더하고, 빠진 것은 지운다', () => {
    const p = planCompanionSave(['a', 'b'], [
      { id: 'a', realName: 'Ana' },
      { realName: 'New' },
    ]);
    assert.deepEqual(p.keep.map((k) => k.id), ['a']);
    assert.equal(p.add.length, 1);
    assert.deepEqual(p.drop, ['b']);
    assert.deepEqual(p.ordered.map((o) => o.id), ['a', null]);
  });
  test('남의 id 는 새 사람이다 — 다른 등록의 동반자를 고칠 수 없다', () => {
    const p = planCompanionSave(['a'], [{ id: 'zzz', realName: 'X' }]);
    assert.equal(p.keep.length, 0);
    assert.equal(p.add.length, 1);
    assert.deepEqual(p.drop, ['a']);
  });
  test('같은 id 가 두 번이면 두 번째는 새 사람, 이름 없는 항목은 건너뛴다', () => {
    const p = planCompanionSave(['a'], [
      { id: 'a', realName: 'A1' },
      { id: 'a', realName: 'A2' },
      { id: 'a', realName: '  ' },
    ]);
    assert.deepEqual(p.ordered.map((o) => o.id), ['a', null]);
    assert.deepEqual(p.drop, []);
  });
});

describe('companionGroupPeople', () => {
  const rows = [
    { id: 's', registration_id: 'r1', study_group: 'same', gender: 'F', age: 40, study_language: 'es' },
    { id: 'o', registration_id: 'r1', study_group: 'other', gender: 'M', age: 17, study_language: 'es' },
    { id: 'n', registration_id: 'r1', study_group: 'none', gender: 'M', age: 2 },
  ];
  test('none 은 빠지고, same 만 대표자와 묶인다', () => {
    const { people, edges } = companionGroupPeople(rows);
    assert.deepEqual(people.map((p) => p.id), ['c:s', 'c:o']);
    assert.deepEqual(edges, [['r1', 'c:s']]);
    assert.equal(people[0].studyLanguage, 'es');
  });
});

test('자동 배정: same 은 대표자와 같은 조, other 는 따로 센다', async () => {
  const { assignGroups } = await import('../src/services/assignment_engine.js');
  const { people, edges } = companionGroupPeople([
    { id: 's', registration_id: 'r1', study_group: 'same', gender: 'F', age: 40, study_language: 'es' },
  ]);
  const registrants = [
    { id: 'r1', gender: 'M', age: 42, studyLanguage: 'es' },
    { id: 'r2', gender: 'M', age: 30, studyLanguage: 'es' },
    { id: 'r3', gender: 'F', age: 33, studyLanguage: 'es' },
  ];
  const { assignments } = assignGroups({
    groups: [{ id: 'g1' }, { id: 'g2' }],
    people: [...registrants, ...people],
    groupEdges: edges,
  });
  const groupOf = new Map(assignments.map((a) => [a.registrationId, a.groupId]));
  assert.equal(groupOf.get('c:s'), groupOf.get('r1'));
  assert.equal(assignments.length, 4);
});

// 투어마다 함께 가는 동반자 (080)
test('tourHeadsFor: 이 투어를 고른, 함께 등록한 동반자만 더한다', async () => {
  const { tourHeadsFor } = await import('../src/services/companion_role.js');
  const cs = [
    { registers_separately: false, tour_ids: ['t1', 't2'] },
    { registers_separately: false, tour_ids: ['t2'] },
    { registers_separately: true, tour_ids: ['t1'] },
    { registers_separately: false },
  ];
  assert.equal(tourHeadsFor('t1', cs), 2);
  assert.equal(tourHeadsFor('t2', cs), 3);
  assert.equal(tourHeadsFor('t3', cs), 1);
});

test('toursCostOf: 투어마다 값 × 머릿수, 그것을 다 더한다', async () => {
  const { toursCostOf } = await import('../src/services/companion_role.js');
  const companions = [
    { registers_separately: false, tour_ids: ['iguazu'] },
    { registers_separately: false, tour_ids: ['iguazu'] },
  ];
  // 이과수 250 × 3 + 시내 40 × 1
  assert.equal(
    toursCostOf({ options: [{ id: 'iguazu', cost: 250 }, { id: 'city', cost: '40' }], companions }),
    790,
  );
  assert.equal(toursCostOf({ options: [], companions }), 0);
});
