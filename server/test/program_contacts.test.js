import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  MAX_CONTACTS,
  MAX_NAME,
  MAX_PHONE,
  normalizeContacts,
  contactsOf,
  legacyPair,
  contactsFromBody,
} from '../src/services/program_contacts.js';

test('이름과 번호를 다듬는다', () => {
  const out = normalizeContacts([
    { name: '  Marcos   Kim ', phone: ' +54-11-3012-3113 ' },
  ]);
  assert.deepEqual(out, [{ name: 'Marcos Kim', phone: '+54-11-3012-3113' }]);
});

test('둘 다 비면 버린다', () => {
  // 화면이 빈 칸 하나를 더 보여 주려고 남겨 두는 줄이 그대로 저장되면
  // 참가자 화면에 빈 줄이 생긴다.
  assert.deepEqual(normalizeContacts([{ name: '', phone: '' }]), []);
  assert.deepEqual(normalizeContacts([{ name: '   ', phone: '  ' }]), []);
  assert.deepEqual(normalizeContacts([{}, null, 'x', 7]), []);
});

test('하나만 있어도 남긴다', () => {
  // 번호만 아는 사람도 있고, 이름만 적어 두고 나중에 채우기도 한다.
  assert.deepEqual(normalizeContacts([{ name: '김요한' }]), [
    { name: '김요한', phone: '' },
  ]);
  assert.deepEqual(normalizeContacts([{ phone: '+54-11-1' }]), [
    { name: '', phone: '+54-11-1' },
  ]);
});

test('길이를 자른다', () => {
  const [c] = normalizeContacts([
    { name: 'ㄱ'.repeat(200), phone: '9'.repeat(200) },
  ]);
  assert.equal(c.name.length, MAX_NAME);
  assert.equal(c.phone.length, MAX_PHONE);
});

test('상한을 넘기면 앞에서부터 자른다', () => {
  const many = Array.from({ length: 30 }, (_, i) => ({
    name: `사람${i}`,
    phone: `${i}`,
  }));
  const out = normalizeContacts(many);
  assert.equal(out.length, MAX_CONTACTS);
  assert.equal(out[0].name, '사람0');
});

test('배열이 아니면 빈 목록', () => {
  for (const v of [null, undefined, 'x', 7, {}]) {
    assert.deepEqual(normalizeContacts(v), []);
  }
});

test('읽을 때 — 목록이 있으면 그것을 쓴다', () => {
  const row = {
    contacts: [{ name: '새목록', phone: '1' }],
    contact1_name: '옛컬럼',
    contact1_phone: '2',
  };
  assert.deepEqual(contactsOf(row), [{ name: '새목록', phone: '1' }]);
});

test('읽을 때 — 목록이 비면 옛 두 컬럼에서 만든다', () => {
  // 이 기능이 생기기 전에 적어 둔 연락처가 사라지면 안 된다.
  const row = {
    contacts: [],
    contact1_name: 'Marcos Kim',
    contact1_phone: '+54-11-3012-3113',
    contact2_name: 'Nicolas Mendoza',
    contact2_phone: '+54-11-2554-6976',
  };
  assert.deepEqual(contactsOf(row), [
    { name: 'Marcos Kim', phone: '+54-11-3012-3113' },
    { name: 'Nicolas Mendoza', phone: '+54-11-2554-6976' },
  ]);
});

test('읽을 때 — 옛 컬럼도 비면 빈 목록', () => {
  assert.deepEqual(contactsOf({ contacts: null }), []);
  assert.deepEqual(contactsOf(null), []);
});

test('저장할 때 — 앞의 두 명을 옛 컬럼에도 적는다', () => {
  const pair = legacyPair([
    { name: '가', phone: '1' },
    { name: '나', phone: '2' },
    { name: '다', phone: '3' },
  ]);
  assert.deepEqual(pair, {
    contact1Name: '가', contact1Phone: '1',
    contact2Name: '나', contact2Phone: '2',
  });
});

test('저장할 때 — 한 명뿐이면 둘째 칸은 비운다', () => {
  const pair = legacyPair([{ name: '가', phone: '1' }]);
  assert.equal(pair.contact2Name, null);
  assert.equal(pair.contact2Phone, null);
});

test('본문 — 새 앱은 contacts 를 보낸다', () => {
  const out = contactsFromBody({ contacts: [{ name: '가', phone: '1' }] });
  assert.deepEqual(out, [{ name: '가', phone: '1' }]);
});

test('본문 — 빈 목록을 보내면 전부 지우겠다는 뜻이다', () => {
  assert.deepEqual(contactsFromBody({ contacts: [] }), []);
});

test('본문 — 옛 앱의 네 칸도 받는다', () => {
  const out = contactsFromBody({
    contact1Name: '가', contact1Phone: '1',
    contact2Name: '나', contact2Phone: '2',
  });
  assert.deepEqual(out, [
    { name: '가', phone: '1' },
    { name: '나', phone: '2' },
  ]);
});

test('본문 — 아무것도 없으면 null (손대지 않는다)', () => {
  // 연락처를 건드리지 않는 저장이 목록을 지워 버리면 안 된다.
  assert.equal(contactsFromBody({}), null);
  assert.equal(contactsFromBody({ name: '엉뚱한 키' }), null);
});

test('본문 — contacts 가 있으면 옛 네 칸은 무시한다', () => {
  // 옛 앱이 보낸 두 명이 새로 적은 다섯 명을 덮어쓰면 안 된다.
  const out = contactsFromBody({
    contacts: [{ name: '새', phone: '9' }],
    contact1Name: '옛', contact1Phone: '1',
  });
  assert.deepEqual(out, [{ name: '새', phone: '9' }]);
});

// ── 입금 시점 (041) ──────────────────────────────────────────────

test('입금 시점 — 아는 값만 받는다', async () => {
  const { normalizePaymentTiming } = await import('../src/services/program_contacts.js');
  assert.equal(normalizePaymentTiming('onsite'), 'onsite');
  assert.equal(normalizePaymentTiming('prepaid'), 'prepaid');
});

test('입금 시점 — 모르는 값은 선불로 본다', async () => {
  const { normalizePaymentTiming } = await import('../src/services/program_contacts.js');
  // 사라지는 쪽보다 남는 쪽이 안전하다. 카드가 조용히 없어지면 담당자는
  // 받을 돈이 있다는 사실 자체를 화면에서 잃는다.
  for (const v of ['현금', '', null, undefined, 7, {}]) {
    assert.equal(normalizePaymentTiming(v), 'prepaid');
  }
});

test('입금 카드 — 하나라도 선불이면 필요하다', async () => {
  const { needsPaymentCard } = await import('../src/services/program_contacts.js');
  assert.equal(needsPaymentCard({ fee_payment: 'prepaid', tour_payment: 'prepaid' }), true);
  assert.equal(needsPaymentCard({ fee_payment: 'onsite', tour_payment: 'prepaid' }), true);
  assert.equal(needsPaymentCard({ fee_payment: 'prepaid', tour_payment: 'onsite' }), true);
});

test('입금 카드 — 둘 다 현장이면 필요 없다', async () => {
  const { needsPaymentCard } = await import('../src/services/program_contacts.js');
  assert.equal(needsPaymentCard({ fee_payment: 'onsite', tour_payment: 'onsite' }), false);
});

test('입금 카드 — 값이 없는 예전 수양회는 필요하다고 본다', async () => {
  const { needsPaymentCard } = await import('../src/services/program_contacts.js');
  // 041 이전에 만든 수양회는 입금 카드를 보고 있었다.
  assert.equal(needsPaymentCard({}), true);
  assert.equal(needsPaymentCard(null), true);
});
