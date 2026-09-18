import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  FREE_AGE_MAX,
  defaultOccupiesBed,
  countsAsPerson,
  occupiesBed,
  chargesFee,
  peopleAmong,
  bedsNeeded,
} from '../src/services/companion_role.js';

// 동반자가 무엇으로 세어지는가 (069)
//
// 아기가 명단·방·식사에서 통째로 빠지던 것을 고치면서 생긴 규칙이다.
// 여기서 틀리면 방이 모자라거나 돈을 잘못 받는다.

const baby = { real_name: 'Lucía', age: 0, registers_separately: false, occupies_bed: false };
const child = { real_name: 'Tomás', age: 8, registers_separately: false, occupies_bed: true };
const spouse = { real_name: '김사라', age: 34, registers_separately: true };

describe('사람으로 세는가', () => {
  test('따로 등록하는 동반자는 안 센다 — 자기 등록이 있다', () => {
    // 여기서 또 세면 두 번이 된다.
    assert.equal(countsAsPerson(spouse), false);
  });

  test('등록할 수 없는 동반자는 이 줄이 곧 그 사람이다', () => {
    assert.equal(countsAsPerson(baby), true);
    assert.equal(countsAsPerson(child), true);
  });

  test('칸이 없는 옛 자료는 따로 등록하는 것으로 본다', () => {
    // 069 이전에 적어 둔 동반자는 전부 "각자 따로 등록" 이 전제였다.
    assert.equal(countsAsPerson({ real_name: '옛줄' }), false);
  });

  test('사람으로 세는 것만 골라낸다', () => {
    const people = peopleAmong([spouse, baby, child]);
    assert.deepEqual(people.map((c) => c.real_name), ['Lucía', 'Tomás']);
  });
});

describe('침대를 쓰는가', () => {
  test('만 5세 이하는 기본으로 안 쓴다', () => {
    assert.equal(defaultOccupiesBed(0), false);
    assert.equal(defaultOccupiesBed(3), false);
    // 경계를 포함한다 — "5살 이하" 에 다섯 살이 빠지면 아무도 그렇게 안 읽는다.
    assert.equal(defaultOccupiesBed(FREE_AGE_MAX), false);
  });

  test('여섯 살부터는 기본으로 쓴다', () => {
    assert.equal(defaultOccupiesBed(6), true);
    assert.equal(defaultOccupiesBed(34), true);
  });

  test('나이를 모르면 쓰는 쪽으로 둔다', () => {
    // 자리를 덜 잡는 것보다 더 잡아 두는 편이 낫다. 방이 모자라면
    // 당일에 손쓸 수가 없다.
    assert.equal(defaultOccupiesBed(null), true);
    assert.equal(defaultOccupiesBed(undefined), true);
    assert.equal(defaultOccupiesBed('몰라요'), true);
  });

  test('기본값은 기본값일 뿐 — 적어 낸 값이 이긴다', () => {
    // 다섯 살이어도 따로 재우는 집이 있다.
    const five = { age: 5, registers_separately: false, occupies_bed: true };
    assert.equal(occupiesBed(five), true);
    // 여덟 살이어도 같이 재울 수 있다.
    const eight = { age: 8, registers_separately: false, occupies_bed: false };
    assert.equal(occupiesBed(eight), false);
  });

  test('따로 등록하는 동반자는 이 셈에 안 들어간다', () => {
    // 그 사람의 자리는 자기 등록으로 잡힌다.
    assert.equal(occupiesBed({ ...spouse, occupies_bed: true }), false);
  });

  test('방에 필요한 자리 수', () => {
    // 부부(따로 등록) + 여덟 살(침대) + 아기(같이 잠) → 여덟 살 하나.
    assert.equal(bedsNeeded([spouse, child, baby]), 1);
    assert.equal(bedsNeeded([]), 0);
    assert.equal(bedsNeeded(null), 0);
  });
});

describe('참가비를 받는가', () => {
  test('만 5세 이하는 안 받는다', () => {
    assert.equal(chargesFee(baby), false);
    assert.equal(chargesFee({ age: FREE_AGE_MAX, registers_separately: false }), false);
  });

  test('여섯 살부터는 받을 대상이다', () => {
    assert.equal(chargesFee(child), true);
  });

  test('따로 등록하면 자기 등록에서 낸다', () => {
    assert.equal(chargesFee({ ...spouse, age: 34 }), false);
  });

  test('나이를 모르면 받지 않는다', () => {
    // 잘못 받는 쪽이 덜 받는 쪽보다 나쁘다 — 060·061 과 같은 판단이다.
    assert.equal(chargesFee({ registers_separately: false }), false);
  });
});
