import { test } from 'node:test';
import assert from 'node:assert/strict';
import { toBase } from '../src/services/fx.js';

// 환율을 가져오는 부분은 바깥 API 를 타므로 여기서 검사하지 않는다.
// 셈만 본다 — 여기서 틀리면 장부의 모든 줄이 조용히 틀린다.

test('현지 금액을 수양회 통화로 나눈다', () => {
  // 640,000 페소를 블루 1545 로 → 414.24 달러
  assert.equal(toBase(640000, 1545), 414.24);
  assert.equal(toBase(1545, 1545), 1);
});

test('둘째 자리에서 반올림', () => {
  assert.equal(toBase(100, 3), 33.33);
  assert.equal(toBase(200, 3), 66.67);
});

test('말이 안 되는 값은 null', () => {
  // 0 으로 나누면 Infinity 가 되어 합계가 통째로 망가진다.
  assert.equal(toBase(1000, 0), null);
  assert.equal(toBase(1000, -5), null);
  assert.equal(toBase(0, 1545), null);
  assert.equal(toBase(-100, 1545), null);
  assert.equal(toBase('공짜', 1545), null);
  assert.equal(toBase(1000, '없음'), null);
  assert.equal(toBase(null, null), null);
});
