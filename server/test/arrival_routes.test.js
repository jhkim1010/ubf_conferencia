import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  MAX_ROUTES,
  normalizeRoutes,
  routesOf,
} from '../src/services/arrival_routes.js';

// 화면은 빈 줄을 하나 더 보여 주려고 늘 마지막에 빈 칸을 둔다. 그것이
// 그대로 저장되면 참가자 화면에 빈 줄이 생긴다 — 연락처에서 겪은 일이다.

test('빈 줄은 버린다', () => {
  assert.deepEqual(
    normalizeRoutes([
      { airport: 'EZE', note: '버스 4시간' },
      { airport: '', note: '' },
      { airport: '   ', note: '  ' },
    ]),
    [{ airport: 'EZE', note: '버스 4시간' }],
  );
});

test('둘 중 하나만 있어도 남긴다', () => {
  // 공항만 아는 경우도, 공항 없이 "육로로 국경을 넘어옵니다" 만 적는
  // 경우도 실제로 있다.
  assert.deepEqual(normalizeRoutes([{ airport: 'IGR' }]), [
    { airport: 'IGR', note: '' },
  ]);
  assert.deepEqual(normalizeRoutes([{ note: '육로로 국경을 넘습니다' }]), [
    { airport: '', note: '육로로 국경을 넘습니다' },
  ]);
});

test('공백을 정리한다', () => {
  assert.deepEqual(
    normalizeRoutes([{ airport: '  EZE  ', note: '버스   4시간 ' }]),
    [{ airport: 'EZE', note: '버스 4시간' }],
  );
});

test('같은 줄은 한 번만', () => {
  // 두 번 적어 두면 참가자 화면에 같은 길이 두 번 나온다.
  assert.deepEqual(
    normalizeRoutes([
      { airport: 'EZE', note: '버스' },
      { airport: 'EZE', note: '버스' },
    ]),
    [{ airport: 'EZE', note: '버스' }],
  );
});

test('개수를 자른다', () => {
  const many = Array.from({ length: MAX_ROUTES + 5 }, (_, i) => ({
    airport: `A${i}`,
  }));
  assert.equal(normalizeRoutes(many).length, MAX_ROUTES);
});

test('길이를 자른다', () => {
  const long = 'x'.repeat(500);
  const [r] = normalizeRoutes([{ airport: long, note: long }]);
  assert.equal(r.airport.length, 80);
  assert.equal(r.note.length, 200);
});

test('목록이 아니면 빈 목록', () => {
  // null 을 그대로 내보내면 화면마다 따로 막아야 한다.
  assert.deepEqual(normalizeRoutes(null), []);
  assert.deepEqual(normalizeRoutes('EZE'), []);
  assert.deepEqual(normalizeRoutes([null, 'EZE', 3]), []);
});

test('routesOf 는 행에서 읽는다', () => {
  assert.deepEqual(routesOf({ arrival_routes: [{ airport: 'EZE' }] }), [
    { airport: 'EZE', note: '' },
  ]);
  assert.deepEqual(routesOf({}), []);
  assert.deepEqual(routesOf(null), []);
});
