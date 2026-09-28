import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  registrationTotal,
  hotelCostOf,
  tierFeeOf,
} from '../src/services/registration_total.js';

// 이 사람이 우리에게 낼 돈 (064)
//
// 관리자 명단과 CSV 가 이 숫자를 그대로 쓴다. 운영 자료로 센다:
// 참가비 기본 200 / 프리미엄 300, 투어 Calafate 800, 호텔 1박 40.

const FEES = { feeBasic: 200, feePremium: 300 };
const LEVELS = [
  { key: 'std', pricePerNight: 40 },
  { key: 'suite', pricePerNight: 100 },
];

test('등급을 안 골라도 기본 참가비를 낸다', () => {
  // 0 으로 두었다가 운영 명단 열둘 중 여섯의 낼 돈이 0 이 된 적이 있다.
  assert.equal(tierFeeOf({ tier: null, ...FEES }), 200);
  assert.equal(tierFeeOf({ tier: 'basic', ...FEES }), 200);
  assert.equal(tierFeeOf({ tier: 'premium', ...FEES }), 300);
});

test('참가비를 안 정해 둔 수양회는 0 이다', () => {
  assert.equal(tierFeeOf({ tier: 'basic', feeBasic: null, feePremium: null }), 0);
});

test('참가비와 투어 값을 더한다', () => {
  const { total } = registrationTotal({
    tier: 'basic',
    ...FEES,
    optionsCost: 800,
  });
  assert.equal(total, 1000);
});

test('승인된 할인만 뺀다', () => {
  const { total } = registrationTotal({
    tier: 'basic',
    ...FEES,
    approvedDiscount: 40,
  });
  assert.equal(total, 160);
});

test('할인이 참가비보다 커도 0 아래로 안 내려간다', () => {
  const { total } = registrationTotal({
    tier: 'basic',
    ...FEES,
    approvedDiscount: 500,
  });
  assert.equal(total, 0);
});

// ── 전후 숙박 (064) ────────────────────────────────────
//
// 주최가 방을 잡고 받아서 호텔에 낸다. 그러니 참가자가 우리에게 내는 돈이다.

test('숙박비가 낼 돈에 들어간다', () => {
  const { total, hotelCost } = registrationTotal({
    tier: 'basic',
    ...FEES,
    optionsCost: 800,
    hotelOptions: LEVELS,
    hotelKey: 'std',
    hotelNights: 3,
  });
  assert.equal(hotelCost, 120);
  assert.equal(total, 1120);
});

test('고른 등급의 단가로 센다', () => {
  const { hotelCost } = registrationTotal({
    tier: 'basic',
    ...FEES,
    hotelOptions: LEVELS,
    hotelKey: 'suite',
    hotelNights: 2,
  });
  assert.equal(hotelCost, 200);
});

test('등급을 안 골랐으면 0 이다 — 단가를 알 수 없다', () => {
  // 화면은 이때 "등급을 고르면 더해집니다" 라고 말해야 한다. 0 이라고만
  // 해 두면 숙박이 공짜라는 뜻이 된다.
  assert.equal(hotelCostOf({ options: LEVELS, key: null, nights: 3 }), 0);
});

test('없는 등급을 가리키면 0 이다', () => {
  // 담당자가 등급을 지운 뒤 옛 key 가 남아 있는 경우다.
  assert.equal(hotelCostOf({ options: LEVELS, key: 'gone', nights: 3 }), 0);
});

test('묵을 밤이 없으면 0 이다', () => {
  assert.equal(hotelCostOf({ options: LEVELS, key: 'std', nights: 0 }), 0);
});

test('등급 목록 자체가 없어도 깨지지 않는다', () => {
  assert.equal(hotelCostOf({ options: null, key: 'std', nights: 3 }), 0);
  assert.equal(hotelCostOf({ options: [], key: 'std', nights: 3 }), 0);
});

test('할인은 숙박까지 더한 뒤에 뺀다', () => {
  const { total } = registrationTotal({
    tier: 'premium',
    ...FEES,
    optionsCost: 95,
    hotelOptions: LEVELS,
    hotelKey: 'std',
    hotelNights: 1,
    approvedDiscount: 35,
  });
  // 300 + 95 + 40 - 35
  assert.equal(total, 400);
});

// ── 동반자가 함께 자는 경우 (069) ─────────────────────────────

test('침대를 쓰는 동반자만큼 숙박비가 는다', () => {
  const { hotelCost } = registrationTotal({
    tier: 'basic',
    ...FEES,
    hotelOptions: LEVELS,
    hotelKey: 'std',
    hotelNights: 2,
    hotelPeople: 2, // 본인 + 침대 쓰는 아이 하나
  });
  assert.equal(hotelCost, 160); // 40 × 2박 × 2명
});

test('같이 자는 아기는 방값이 안 붙는다', () => {
  // hotelPeople 이 1 이면 아기를 데려와도 그대로다.
  const { hotelCost } = registrationTotal({
    tier: 'basic',
    ...FEES,
    hotelOptions: LEVELS,
    hotelKey: 'std',
    hotelNights: 2,
    hotelPeople: 1,
  });
  assert.equal(hotelCost, 80);
});

test('인원을 안 주면 한 사람으로 센다', () => {
  // 069 이전의 호출자가 그대로 동작해야 한다.
  const { hotelCost } = registrationTotal({
    tier: 'basic',
    ...FEES,
    hotelOptions: LEVELS,
    hotelKey: 'std',
    hotelNights: 3,
  });
  assert.equal(hotelCost, 120);
});

test('못 읽는 인원은 한 사람으로 본다', () => {
  for (const bad of [0, -2, null, 'two']) {
    const { hotelCost } = registrationTotal({
      tier: 'basic',
      ...FEES,
      hotelOptions: LEVELS,
      hotelKey: 'std',
      hotelNights: 1,
      hotelPeople: bad,
    });
    assert.equal(hotelCost, 40, `인원 ${bad}`);
  }
});

// ── 동반자 참가비 (073) ──────────────────────────────────────
//
// 따로 등록할 수 없는 어린이는 자기 등록이 없어, 보호자의 낼 돈에 붙는다.

const kid = (age) => ({ registers_separately: false, age });

test('어린이 참가비가 낼 돈에 더해진다', () => {
  const { tierFee, companionFee, total } = registrationTotal({
    tier: 'basic',
    ...FEES,
    companions: [kid(6)],
  });
  // 기본 200 + 여섯 살 절반 100 = 300
  assert.equal(tierFee, 200);
  assert.equal(companionFee, 100);
  assert.equal(total, 300);
});

test('어린이는 보호자가 고른 등급을 따라간다', () => {
  const { companionFee, total } = registrationTotal({
    tier: 'premium',
    ...FEES,
    companions: [kid(6)],
  });
  // 프리미엄 300 + 절반 150 = 450
  assert.equal(companionFee, 150);
  assert.equal(total, 450);
});

test('아기는 안 붙고 아홉 살은 전액이다', () => {
  const { companionFee, total } = registrationTotal({
    tier: 'basic',
    ...FEES,
    companions: [kid(1), kid(9)],
  });
  assert.equal(companionFee, 200);
  assert.equal(total, 400);
});

test('수양회가 구간을 달리 정하면 그대로 따른다', () => {
  const { companionFee } = registrationTotal({
    tier: 'basic',
    ...FEES,
    companions: [kid(10)],
    program: { fee_child_age_min: 6, fee_child_age_max: 12, fee_child_rate: 0.25 },
  });
  assert.equal(companionFee, 50);
});

test('할인은 어린이 몫까지 더한 뒤에 뺀다', () => {
  // 먼저 빼면 할인이 어른 몫에만 걸려, 같은 할인인데 집집이 달라진다.
  const { total } = registrationTotal({
    tier: 'basic',
    ...FEES,
    companions: [kid(6)],
    approvedDiscount: 50,
  });
  assert.equal(total, 250); // 200 + 100 − 50
});

test('동반자를 안 보내면 예전과 같다', () => {
  // 073 이전 호출자가 그대로 돌아야 한다.
  const { companionFee, total } = registrationTotal({ tier: 'basic', ...FEES });
  assert.equal(companionFee, 0);
  assert.equal(total, 200);
});
