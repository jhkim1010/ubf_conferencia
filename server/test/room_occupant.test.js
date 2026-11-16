// 방에 드는 사람 id (077)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  companionOccupantId,
  parseOccupant,
  companionLabel,
} from '../src/services/room_occupant.js';

test('등록 id 는 그대로 등록이다', () => {
  assert.deepEqual(parseOccupant('8f0e-1'), { registrationId: '8f0e-1' });
});

test('동반자 id 는 앞에 c: 를 붙이고, 갈라 보면 돌아온다', () => {
  const id = companionOccupantId('abc');
  assert.equal(id, 'c:abc');
  assert.deepEqual(parseOccupant(id), { companionId: 'abc' });
});

test('빈 것은 아무도 아니다', () => {
  assert.equal(parseOccupant(''), null);
  assert.equal(parseOccupant('c:'), null);
  assert.equal(parseOccupant(null), null);
});

test('이름표에는 누구의 동반자인지 붙는다', () => {
  assert.equal(companionLabel('Lucía', 'Ana'), 'Lucía (Ana)');
  assert.equal(companionLabel('Lucía', ''), 'Lucía');
});
