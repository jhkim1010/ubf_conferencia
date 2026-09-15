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
