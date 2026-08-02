// 수양회 전후 숙박 로직 테스트 — DB 비의존 순수 함수
// 실행: cd server && npm test

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  isHotelEligible,
  normalizeNights,
  resolveHotelChoice,
  MAX_NIGHTS,
} from '../src/services/hotel.js';

const OPTIONS = [
  { key: 'h1', label: '3성급', pricePerNight: 50 },
  { key: 'h2', label: '4성급', pricePerNight: 80 },
];

describe('isHotelEligible', () => {
  test('외국에서 오는 사람만 고른다', () => {
    assert.equal(isHotelEligible({ hostCountry: 'AR', country: 'KR' }), true);
  });

  test('개최국 사람은 못 고른다 — 전후에 집으로 간다', () => {
    assert.equal(isHotelEligible({ hostCountry: 'AR', country: 'AR' }), false);
  });

  test('개최국이 없으면 아무도 못 고른다', () => {
    // 누가 외국인인지 판정할 근거가 없다. 나중에 개최국을 적는 순간
    // 이미 신청해 둔 사람의 자격이 통째로 흔들린다.
    assert.equal(isHotelEligible({ hostCountry: null, country: 'KR' }), false);
    assert.equal(isHotelEligible({ hostCountry: '', country: 'KR' }), false);
  });

  test('참가자 국가를 모르면 못 고른다', () => {
    assert.equal(isHotelEligible({ hostCountry: 'AR', country: null }), false);
  });
});

describe('normalizeNights', () => {
  test('음수는 0 으로', () => {
    assert.equal(normalizeNights(-3), 0);
  });

  test('상한을 넘으면 잘린다 — 오타 방지', () => {
    assert.equal(normalizeNights(200), MAX_NIGHTS);
  });

  test('숫자가 아니면 0', () => {
    for (const v of [null, undefined, '', 'abc', NaN]) {
      assert.equal(normalizeNights(v), 0);
    }
  });

  test('문자열 숫자도 받는다', () => {
    assert.equal(normalizeNights('3'), 3);
  });

  test('소수는 버린다', () => {
    assert.equal(normalizeNights(2.9), 2);
  });
});

describe('resolveHotelChoice', () => {
  const base = { options: OPTIONS, hostCountry: 'AR', country: 'KR' };

  test('고른 등급과 박수를 그대로 남기고 금액을 계산한다', () => {
    const r = resolveHotelChoice({
      ...base,
      optionKey: 'h2',
      nightsBefore: 2,
      nightsAfter: 3,
    });
    assert.deepEqual(r, {
      key: 'h2',
      nightsBefore: 2,
      nightsAfter: 3,
      estimate: 400, // 80 × 5박
    });
  });

  test('개최국 참가자의 선택은 떨어뜨린다', () => {
    const r = resolveHotelChoice({
      ...base,
      country: 'AR',
      optionKey: 'h2',
      nightsBefore: 2,
      nightsAfter: 3,
    });
    assert.equal(r.key, null);
    assert.equal(r.nightsBefore, 0);
  });

  test('없는 등급을 고르면 떨어뜨린다', () => {
    // 예전 앱이나 직접 호출이 지워진 등급을 보내올 수 있다.
    const r = resolveHotelChoice({ ...base, optionKey: 'h9', nightsBefore: 2 });
    assert.equal(r.key, null);
  });

  test('등급을 안 고르면 박수도 남기지 않는다', () => {
    // "3박" 만 남아 있으면 어느 등급으로 방을 잡을지 알 수 없고
    // 화면에는 아무것도 안 보인다.
    const r = resolveHotelChoice({
      ...base,
      optionKey: null,
      nightsBefore: 3,
      nightsAfter: 3,
    });
    assert.deepEqual(r, {
      key: null,
      nightsBefore: 0,
      nightsAfter: 0,
      estimate: null,
    });
  });

  test('박수가 0 이면 금액은 없다', () => {
    const r = resolveHotelChoice({
      ...base,
      optionKey: 'h1',
      nightsBefore: 0,
      nightsAfter: 0,
    });
    assert.equal(r.key, 'h1');
    assert.equal(r.estimate, null);
  });

  test('단가가 없는 등급이면 금액을 내지 않는다', () => {
    // 등급만 정하고 금액은 나중에 알리는 경우가 있다. 0 으로 보여주면
    // 공짜인 줄 안다.
    const r = resolveHotelChoice({
      options: [{ key: 'h3', label: '미정' }],
      hostCountry: 'AR',
      country: 'KR',
      optionKey: 'h3',
      nightsBefore: 2,
      nightsAfter: 0,
    });
    assert.equal(r.key, 'h3');
    assert.equal(r.estimate, null);
  });

  test('상한을 넘는 박수는 잘린 값으로 계산한다', () => {
    const r = resolveHotelChoice({
      ...base,
      optionKey: 'h1',
      nightsBefore: 999,
      nightsAfter: 0,
    });
    assert.equal(r.nightsBefore, MAX_NIGHTS);
    assert.equal(r.estimate, 50 * MAX_NIGHTS);
  });
});
