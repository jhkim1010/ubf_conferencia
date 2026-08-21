// 숙박 수준 고르기 (064)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  defaultHotelKey,
  mustPickHotel,
  hotelChoiceOk,
} from '../src/services/hotel_choice.js';

const LEVELS = [
  { key: 'h1', label: 'Deluxe', pricePerNight: 100 },
  { key: 'h2', label: 'Standard', pricePerNight: 30 },
];

test('기본은 가장 싼 방이다', () => {
  assert.equal(defaultHotelKey(LEVELS), 'h2');
});

test('차례가 뒤바뀌어도 값으로 고른다', () => {
  assert.equal(defaultHotelKey([...LEVELS].reverse()), 'h2');
});

test('이름으로 찾지 않는다', () => {
  // 수양회마다 이름이 다르고 언어도 넷이다. 이름에 기대면 어느 수양회에서는
  // 조용히 아무것도 안 골라진다.
  const es = [
    { key: 'a', label: 'Habitación superior', pricePerNight: 90 },
    { key: 'b', label: 'Habitación estándar', pricePerNight: 25 },
  ];
  assert.equal(defaultHotelKey(es), 'b');
});

test('값이 하나도 안 정해졌으면 첫 번째', () => {
  const none = [{ key: 'x' }, { key: 'y' }];
  assert.equal(defaultHotelKey(none), 'x');
});

test('값이 정해진 것이 하나뿐이면 그것', () => {
  const mixed = [{ key: 'x' }, { key: 'y', pricePerNight: 80 }];
  assert.equal(defaultHotelKey(mixed), 'y');
});

test('0 원짜리 방도 값이 정해진 것이다', () => {
  const free = [{ key: 'x', pricePerNight: 50 }, { key: 'y', pricePerNight: 0 }];
  assert.equal(defaultHotelKey(free), 'y');
});

test('고를 것이 없으면 null', () => {
  assert.equal(defaultHotelKey([]), null);
  assert.equal(defaultHotelKey(null), null);
});

test('묵을 밤이 있으면 골라야 한다', () => {
  assert.equal(mustPickHotel({ nights: 2, options: LEVELS }), true);
});

test('묵을 밤이 없으면 안 골라도 된다', () => {
  assert.equal(mustPickHotel({ nights: 0, options: LEVELS }), false);
});

test('주최 측이 등급을 안 만들었으면 막지 않는다', () => {
  // 막으면 참가자가 제출 자체를 못 한다. 우리 잘못으로 남을 막는 셈이다.
  assert.equal(mustPickHotel({ nights: 3, options: [] }), false);
  assert.equal(hotelChoiceOk({ nights: 3, options: [], key: null }), true);
});

test('골라야 하는데 안 골랐으면 막는다', () => {
  assert.equal(hotelChoiceOk({ nights: 2, options: LEVELS, key: null }), false);
  assert.equal(hotelChoiceOk({ nights: 2, options: LEVELS, key: '' }), false);
});

test('없는 등급을 가리키면 막는다', () => {
  // 등급을 지운 뒤 옛 key 가 남아 있으면 숙박비가 조용히 0 이 된다.
  assert.equal(
    hotelChoiceOk({ nights: 2, options: LEVELS, key: 'h9' }),
    false,
  );
});

test('제대로 골랐으면 통과', () => {
  assert.equal(hotelChoiceOk({ nights: 2, options: LEVELS, key: 'h2' }), true);
});
