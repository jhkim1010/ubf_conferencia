import { test } from 'node:test';
import assert from 'node:assert/strict';
import { cleanProfile, planTours } from '../src/services/profile_edit.js';

// 담당자가 고치는 기본 정보와 투어

test('보낸 칸만 바꾼다', () => {
  const { set, error } = cleanProfile({ branch: ' La Plata ', phone: '' });
  assert.equal(error, null);
  assert.deepEqual(set, { branch: 'La Plata', phone: null });
});

test('이름을 비우면 오류 — 명단에서 사라진다', () => {
  assert.equal(cleanProfile({ realName: '  ' }).error, '이름을 적어 주세요');
});

test('성별·나이·등급은 정해진 값만', () => {
  assert.deepEqual(cleanProfile({ gender: 'F', age: '33', feeTier: 'premium' }).set, {
    gender: 'F', age: 33, fee_tier: 'premium',
  });
  assert.ok(cleanProfile({ gender: 'X' }).error);
  assert.ok(cleanProfile({ age: 200 }).error);
  assert.ok(cleanProfile({ age: 3.5 }).error);
  assert.ok(cleanProfile({ feeTier: 'gold' }).error);
  assert.deepEqual(cleanProfile({ age: null, gender: null }).set, { age: null, gender: null });
});

test('planTours: 모르는 투어·남의 동반자를 버리고, 대표자가 안 가는 투어에는 동반자를 안 넣는다', () => {
  const { selected, toursOf } = planTours({
    selected: ['t1', 't2', 'dead', 't1'],
    companionTours: { t1: ['c1', 'c2', 'other'], t3: ['c1'] },
    activeIds: ['t1', 't2', 't3'],
    companionIds: ['c1', 'c2', 'c3'],
  });
  assert.deepEqual(selected, ['t1', 't2']);
  assert.deepEqual(toursOf.get('c1'), ['t1']);
  assert.deepEqual(toursOf.get('c2'), ['t1']);
  assert.deepEqual(toursOf.get('c3'), []);
  assert.equal(toursOf.has('other'), false);
});
