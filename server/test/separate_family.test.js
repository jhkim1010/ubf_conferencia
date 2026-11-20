import { test } from 'node:test';
import assert from 'node:assert/strict';
import { nameKey, separateFamilyEdges } from '../src/services/room_occupant.js';

test('이름은 대소문자·악센트·공백을 무시하고 비교한다', () => {
  assert.equal(nameKey('  SOO  YEON Choi '), 'sooyeonchoi');
  assert.equal(nameKey('BO HYUN BAEK'), nameKey('bohyun baek'));
  assert.equal(nameKey('Jazmín Rentería'), nameKey('jazmin renteria'));
});

test('서로를 적은 부부는 한 쌍으로 이어진다', () => {
  const regs = [
    { id: 'a', real_name: 'NAM KI CHUN' },
    { id: 'b', real_name: 'Soo Yeon Choi' },
  ];
  const comps = [
    { registration_id: 'a', real_name: 'SOO YEON CHOI', shares_room: true },
    { registration_id: 'b', real_name: 'Nam Ki Chun', shares_room: true },
  ];
  assert.deepEqual(separateFamilyEdges(comps, regs), [['a', 'b']]);
});

test('다른 방을 원하면 잇지 않는다', () => {
  const regs = [{ id: 'a', real_name: 'X' }, { id: 'b', real_name: 'Y' }];
  const comps = [{ registration_id: 'a', real_name: 'Y', shares_room: false }];
  assert.deepEqual(separateFamilyEdges(comps, regs), []);
});

test('등록이 없거나 같은 이름이 둘이면 잇지 않는다', () => {
  const regs = [
    { id: 'a', real_name: 'Sarah Chang' },
    { id: 'b', real_name: 'Kim' },
    { id: 'c', real_name: 'kim' },
  ];
  const comps = [
    { registration_id: 'a', real_name: 'Moses Chang', shares_room: true },
    { registration_id: 'a', real_name: 'Kim', shares_room: true },
    // 대표자 자신과 이름이 같은 줄은 자기 자신과 잇지 않는다.
    { registration_id: 'a', real_name: 'sarah chang', shares_room: true },
  ];
  assert.deepEqual(separateFamilyEdges(comps, regs), []);
});
