import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  FREE_AGE_MAX,
  defaultOccupiesBed,
  countsAsPerson,
  occupiesBed,
  chargesFee,
  feeShareOf,
  companionFeeOf,
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

// 어린이 참가비 (073)
//
// 기본 구간은 네 살부터 여덟 살까지 절반이다. 그 아래는 안 받고 그 위는
// 전액이다. 경계를 **포함**한다.

const kid = (age, extra = {}) => ({ registers_separately: false, age, ...extra });

describe('참가비를 얼마나 받는가', () => {
  test('구간보다 어리면 안 받는다', () => {
    assert.equal(feeShareOf(baby), 0);
    assert.equal(feeShareOf(kid(3)), 0);
  });

  test('구간 안이면 절반 — 경계를 포함한다', () => {
    // 네 살과 여덟 살이 빠지면 "4살부터 8살까지" 를 그렇게 읽은 것이 아니다.
    assert.equal(feeShareOf(kid(4)), 0.5);
    assert.equal(feeShareOf(kid(6)), 0.5);
    assert.equal(feeShareOf(kid(8)), 0.5);
  });

  test('구간보다 많으면 어른과 같이 전액', () => {
    assert.equal(feeShareOf(kid(9)), 1);
    assert.equal(feeShareOf(kid(15)), 1);
  });

  test('침대 기본값과 참가비는 다른 질문이다', () => {
    // FREE_AGE_MAX 는 침대에만 쓴다(069·073). 다섯 살은 침대를 기본으로
    // 안 쓰지만 참가비는 절반을 낸다 — 두 값이 엮이면 한쪽을 고칠 때
    // 다른 쪽이 조용히 따라 움직인다.
    assert.equal(defaultOccupiesBed(FREE_AGE_MAX), false);
    assert.equal(feeShareOf(kid(FREE_AGE_MAX)), 0.5);
  });

  test('수양회가 구간을 달리 정하면 그대로 따른다', () => {
    const program = { fee_child_age_min: 6, fee_child_age_max: 12, fee_child_rate: 0.3 };
    assert.equal(feeShareOf(kid(5), program), 0);
    assert.equal(feeShareOf(kid(6), program), 0.3);
    assert.equal(feeShareOf(kid(12), program), 0.3);
    assert.equal(feeShareOf(kid(13), program), 1);
  });

  test('사람별로 적어 둔 몫이 나이보다 먼저다', () => {
    // 069 가 침대에서 배운 것과 같다 — 사정이 다른 집이 고칠 수 있어야 한다.
    assert.equal(feeShareOf(kid(30, { fee_share: 0.5 })), 0.5);
    // 0 도 뜻이 있다. null 과 구별해야 한다 — "안 받기로 정했다" 이다.
    assert.equal(feeShareOf(kid(8, { fee_share: 0 })), 0);
    // 범위 밖은 무시하고 나이로 돌아간다.
    assert.equal(feeShareOf(kid(8, { fee_share: 5 })), 0.5);
  });

  test('따로 등록하면 자기 등록에서 낸다', () => {
    assert.equal(feeShareOf({ ...spouse, age: 34 }), 0);
    // 적어 둔 몫이 있어도 마찬가지다 — 두 번 받게 된다.
    assert.equal(feeShareOf({ ...spouse, age: 34, fee_share: 1 }), 0);
  });

  test('나이를 모르면 받지 않는다', () => {
    // 잘못 받는 쪽이 덜 받는 쪽보다 나쁘다 — 060·061 과 같은 판단이다.
    assert.equal(feeShareOf({ registers_separately: false }), 0);
    assert.equal(chargesFee({ registers_separately: false }), false);
  });

  test('거꾸로 적힌 구간에서도 무너지지 않는다', () => {
    // DB 의 CHECK 가 막지만, 그 칸을 안 거치고 들어온 값도 있을 수 있다.
    const broken = { fee_child_age_min: 9, fee_child_age_max: 4 };
    assert.equal(feeShareOf(kid(3), broken), 0);
    assert.equal(feeShareOf(kid(10), broken), 1);
  });
});

describe('동반자 참가비의 합', () => {
  const program = null; // 기본 구간

  test('어린이는 보호자가 고른 등급을 따라간다', () => {
    // 프리미엄 U$120 을 고른 집의 여섯 살은 60 이다. 한 집이 같은 밥을
    // 먹고 같은 방에 묵는데 어린이만 다른 등급일 수가 없다.
    assert.equal(
      companionFeeOf({ companions: [kid(6)], program, tierFee: 120 }),
      60,
    );
  });

  test('여럿을 더한다 — 아기는 0, 어린이는 절반, 열 살은 전액', () => {
    const family = [kid(1), kid(7), kid(10)];
    // 0 + 40 + 80 = 120
    assert.equal(companionFeeOf({ companions: family, program, tierFee: 80 }), 120);
  });

  test('따로 등록하는 동반자는 안 더한다', () => {
    assert.equal(
      companionFeeOf({ companions: [spouse, kid(6)], program, tierFee: 80 }),
      40,
    );
  });

  test('참가비를 모르면 0 이다', () => {
    // 등급 값이 없으면 어린이 몫도 셀 수가 없다. 0 으로 두고 화면이
    // "등급을 고르면 더해집니다" 라고 말한다.
    assert.equal(companionFeeOf({ companions: [kid(6)], program, tierFee: 0 }), 0);
    assert.equal(companionFeeOf({ companions: [kid(6)], program }), 0);
  });

  test('빈 목록과 잘못된 값에도 0 이다', () => {
    assert.equal(companionFeeOf({ companions: [], tierFee: 80 }), 0);
    assert.equal(companionFeeOf({ companions: null, tierFee: 80 }), 0);
    assert.equal(companionFeeOf(), 0);
  });

  test('반올림은 센트까지', () => {
    // 33.333... 이 그대로 남으면 명단과 장부가 소수점 아래에서 갈린다.
    assert.equal(
      companionFeeOf({ companions: [kid(6)], program: { fee_child_rate: 1 / 3 }, tierFee: 100 }),
      33.33,
    );
  });
});
