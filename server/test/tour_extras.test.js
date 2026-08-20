// 투어 값에 안 들어 있는 것 (061)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { tourExtras, missingFrom, amountOf } from '../src/services/tour_extras.js';

const iguazu = {
  name: 'Iguazú',
  includesMeals: false, estMealsCost: 120,
  includesLodging: true,
  includesAirfare: false, estAirfareCost: 300,
};

test('안 적으면 다 들어 있는 것으로 본다', () => {
  assert.deepEqual(missingFrom({ name: '시내' }), []);
  assert.equal(tourExtras([{ name: '시내' }]).isEmpty, true);
});

test('빠진 것만 골라 낸다', () => {
  assert.deepEqual(
    missingFrom(iguazu).map((m) => m.kind),
    ['meals', 'airfare'],
  );
});

test('빠진 것들의 금액을 더한다', () => {
  const e = tourExtras([iguazu]);
  assert.equal(e.meals, 120);
  assert.equal(e.airfare, 300);
  assert.equal(e.lodging, 0);
  assert.equal(e.known, 420);
});

test('투어 여럿이면 종류별로 모은다', () => {
  const e = tourExtras([
    iguazu,
    { name: 'Ushuaia', includesMeals: false, estMealsCost: 80 },
  ]);
  assert.equal(e.meals, 200);
  assert.equal(e.known, 500);
});

test('금액을 안 적은 것은 0 으로 세지 않고 따로 알린다', () => {
  // 모르는 것을 0 으로 세면 참가자가 돈을 덜 챙겨 온다.
  const e = tourExtras([{ name: 'X', includesAirfare: false }]);
  assert.equal(e.known, 0);
  assert.equal(e.unknown.length, 1);
  assert.equal(e.unknown[0].kind, 'airfare');
  assert.equal(e.isEmpty, false);
});

test('0 은 모른다는 뜻이 아니다', () => {
  const e = tourExtras([
    { name: 'X', includesMeals: false, estMealsCost: 0 },
  ]);
  assert.equal(e.unknown.length, 0);
  assert.equal(e.known, 0);
  assert.equal(e.isEmpty, false, '빠진 것이 있다는 사실은 남아야 한다');
});

test('금액을 못 읽으면 모르는 것으로 둔다', () => {
  assert.equal(amountOf('abc'), null);
  assert.equal(amountOf(-5), null);
  assert.equal(amountOf(''), null);
  assert.equal(amountOf('120.50'), 120.5);
  assert.equal(amountOf(0), 0);
});

test('어느 투어에서 나온 것인지 남긴다', () => {
  // 담당자가 고칠 곳을 찾으려면 투어 이름이 있어야 한다.
  const e = tourExtras([iguazu]);
  assert.deepEqual([...new Set(e.items.map((i) => i.tour))], ['Iguazú']);
});
