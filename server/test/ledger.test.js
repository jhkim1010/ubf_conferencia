import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  MAX_TITLE,
  ledgerSummary,
  normalizeEntry,
} from '../src/services/ledger.js';

// 담당자가 묻는 것은 하나다: "지금 얼마가 모자라나".
// 참가비는 payments 에, 지원·지출은 장부에 있으므로 둘을 더해야 답이 된다.

test('남은 돈은 받은 것에서 쓴 것을 뺀다', () => {
  const s = ledgerSummary({
    entries: [
      { kind: 'income', amount: 1000 },
      { kind: 'expense', amount: 300 },
      { kind: 'expense', amount: 200 },
    ],
    collected: 500,
    owed: 0,
  });
  assert.equal(s.support, 1000);
  assert.equal(s.spent, 500);
  assert.equal(s.collected, 500);
  assert.equal(s.balance, 1000);
});

test('아직 못 받은 참가비는 따로 센다', () => {
  // "지금은 모자라지만 다 걷히면 남는다" 를 구별할 수 있어야 한다.
  const s = ledgerSummary({
    entries: [{ kind: 'expense', amount: 1000 }],
    collected: 300,
    owed: 900,
  });
  assert.equal(s.balance, -700, '지금 손에 있는 것은 모자란다');
  assert.equal(s.expected, 200, '다 걷히면 남는다');
});

test('장부가 비어 있어도 답을 낸다', () => {
  const s = ledgerSummary({ collected: 100 });
  assert.equal(s.support, 0);
  assert.equal(s.spent, 0);
  assert.equal(s.balance, 100);
});

test('이상한 줄은 합계에서 뺀다', () => {
  // 옛 행이나 잘못된 요청이 흘러들어도 합계가 NaN 이 되면 안 된다.
  const s = ledgerSummary({
    entries: [
      { kind: 'income', amount: 100 },
      { kind: 'income', amount: 'x' },
      { kind: 'expense', amount: -50 },
      { kind: '엉뚱', amount: 999 },
      null,
    ],
    collected: 0,
  });
  assert.equal(s.support, 100);
  assert.equal(s.spent, 0);
  assert.equal(s.balance, 100);
});

test('소수점 둘째 자리까지', () => {
  const s = ledgerSummary({
    entries: [{ kind: 'income', amount: 0.1 }, { kind: 'income', amount: 0.2 }],
  });
  assert.equal(s.support, 0.3, '0.30000000000000004 가 아니다');
});

test('적을 수 없는 줄은 받지 않는다', () => {
  assert.equal(normalizeEntry(null), null);
  assert.equal(normalizeEntry({ kind: '엉뚱', amount: 1, title: 'x' }), null);
  // 금액은 늘 양수다. 방향은 kind 가 정한다.
  assert.equal(normalizeEntry({ kind: 'expense', amount: 0, title: 'x' }), null);
  assert.equal(normalizeEntry({ kind: 'expense', amount: -5, title: 'x' }), null);
  assert.equal(normalizeEntry({ kind: 'expense', amount: 'x', title: 'x' }), null);
  // 무엇에 쓴 돈인지 없으면 나중에 아무도 못 알아본다.
  assert.equal(normalizeEntry({ kind: 'expense', amount: 5, title: '   ' }), null);
});

test('제대로 온 줄은 다듬어 돌려준다', () => {
  const e = normalizeEntry({
    kind: 'expense',
    amount: '1234.567',
    title: '  버스   대절 ',
    note: ' 이과수 왕복 ',
    occurredOn: '2027-07-01',
  });
  assert.equal(e.kind, 'expense');
  assert.equal(e.amount, 1234.57, '둘째 자리에서 반올림');
  assert.equal(e.title, '버스 대절', '공백 정리');
  assert.equal(e.note, '이과수 왕복');
  assert.equal(e.occurredOn, '2027-07-01');
});

test('날짜 형식이 아니면 비운다', () => {
  // 라우트가 오늘로 채운다 — 이상한 날짜를 그대로 넣으면 저장이 터진다.
  assert.equal(normalizeEntry({ kind: 'income', amount: 1, title: 'x', occurredOn: '어제' }).occurredOn, null);
  assert.equal(normalizeEntry({ kind: 'income', amount: 1, title: 'x' }).occurredOn, null);
});

test('긴 제목은 자른다', () => {
  const e = normalizeEntry({ kind: 'income', amount: 1, title: 'ㄱ'.repeat(500) });
  assert.equal(e.title.length, MAX_TITLE);
});
