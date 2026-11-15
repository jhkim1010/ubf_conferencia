import { test } from 'node:test';
import assert from 'node:assert/strict';
import { normalizeCancelReason } from '../src/services/cancel_reason.js';

test('취소 이유는 다듬어 받고, 비면 null 이다', () => {
  assert.equal(normalizeCancelReason('  비자가 안 나왔습니다 '), '비자가 안 나왔습니다');
  assert.equal(normalizeCancelReason('   '), null);
  assert.equal(normalizeCancelReason(undefined), null);
  assert.equal(normalizeCancelReason(42), null);
  assert.equal(normalizeCancelReason('x'.repeat(600)).length, 500);
});
