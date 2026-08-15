import { test } from 'node:test';
import assert from 'node:assert/strict';
import { paymentState, remaining } from '../src/services/payment_state.js';

// 담당자가 명단에서 보는 것은 넷 중 하나다: 미납·부분납금·완납·대기.
// 금액과 상태를 둘 다 저장하면 어긋나므로 금액에서 매번 정한다.

test('아무것도 안 냈으면 미납', () => {
  assert.equal(paymentState({ due: 200, paid: 0, status: null }), 'unpaid');
  assert.equal(paymentState({ due: 200 }), 'unpaid');
  assert.equal(paymentState({ due: 200, paid: null }), 'unpaid');
});

test('일부만 확인됐으면 부분납금', () => {
  assert.equal(paymentState({ due: 200, paid: 50, status: 'confirmed' }), 'partial');
  assert.equal(remaining({ due: 200, paid: 50, status: 'confirmed' }), 150);
});

test('다 채웠으면 완납', () => {
  assert.equal(paymentState({ due: 200, paid: 200, status: 'confirmed' }), 'paid');
  // 더 낸 경우도 완납이다 — 거스름은 장부 밖의 일이다.
  assert.equal(paymentState({ due: 200, paid: 250, status: 'confirmed' }), 'paid');
  assert.equal(remaining({ due: 200, paid: 250, status: 'confirmed' }), 0);
});

test('확인 전에는 금액과 상관없이 대기', () => {
  // 확인하지 않은 돈을 받은 것으로 세면 장부가 실제보다 커진다.
  assert.equal(paymentState({ due: 200, paid: 200, status: 'pending' }), 'pending');
  assert.equal(paymentState({ due: 200, paid: 10, status: 'pending' }), 'pending');
});

test('거절한 입금은 낸 것이 아니다', () => {
  assert.equal(paymentState({ due: 200, paid: 200, status: 'rejected' }), 'unpaid');
  assert.equal(remaining({ due: 200, paid: 200, status: 'rejected' }), 200);
});

test('낼 돈이 없으면 완납', () => {
  // 전액 면제거나 참가비를 안 정한 수양회. '미납' 이라고 하면 담당자가
  // 받으러 다닌다.
  assert.equal(paymentState({ due: 0, paid: 0 }), 'paid');
  assert.equal(paymentState({ due: null, paid: 0 }), 'paid');
  assert.equal(remaining({ due: 0, paid: 0 }), 0);
});

test('이상한 값에도 답을 낸다', () => {
  // 화면이 빈칸을 보내거나 옛 행에 null 이 있어도 표가 깨지면 안 된다.
  assert.ok(['unpaid', 'paid'].includes(paymentState({})));
  assert.equal(paymentState({ due: '200', paid: '200', status: 'confirmed' }), 'paid');
  assert.equal(paymentState({ due: -5, paid: 0 }), 'paid');
});
