import { test } from 'node:test';
import assert from 'node:assert/strict';
import { coverMap } from '../src/services/room_occupant.js';

const regs = [
  { id: 'p', real_name: 'Gonzalo Solis' },
  { id: 'v', real_name: 'Veronica Ramirez' },
  { id: 'k1', real_name: 'Kim' },
  { id: 'k2', real_name: 'KIM' },
];

test('함께 등록한 동반자가 따로 등록하면 그 등록은 대표자가 낸다', () => {
  const m = coverMap(
    [{ id: 'c1', registration_id: 'p', real_name: 'veronica  ramírez',
       registers_separately: false, study_group: 'same' }],
    regs,
  );
  assert.deepEqual(m.get('v'), { companionId: 'c1', primaryId: 'p', studyGroup: 'same' });
  assert.equal(m.size, 1);
});

test('따로 등록으로 적힌 동반자는 덮지 않는다 — 그분이 낸다', () => {
  const m = coverMap(
    [{ id: 'c1', registration_id: 'p', real_name: 'Veronica Ramirez',
       registers_separately: true }],
    regs,
  );
  assert.equal(m.size, 0);
});

test('이름이 같은 등록이 둘이거나 대표자 자신이면 덮지 않는다', () => {
  const m = coverMap(
    [
      { id: 'c1', registration_id: 'p', real_name: 'kim', registers_separately: false },
      { id: 'c2', registration_id: 'p', real_name: 'Gonzalo Solis', registers_separately: false },
    ],
    regs,
  );
  assert.equal(m.size, 0);
});

test('두 대표자가 같은 사람을 적으면 먼저 적은 쪽이다', () => {
  const m = coverMap(
    [
      { id: 'c1', registration_id: 'p', real_name: 'Veronica Ramirez', registers_separately: false },
      { id: 'c2', registration_id: 'k1', real_name: 'Veronica Ramirez', registers_separately: false },
    ],
    regs,
  );
  assert.equal(m.get('v').companionId, 'c1');
});
