import { test } from 'node:test';
import assert from 'node:assert/strict';
import { composeEditMail, mailLanguage } from '../src/services/edit_mail_text.js';

const reg = {
  name: 'Gonzalo Solis',
  program: 'Conferencia 2027',
  currency: 'USD',
  total: 775,
  companions: [{ name: 'Veronica Ramirez', age: 39 }],
  tours: ['City Tour'],
  arrival: 'AR1300',
  departure: '',
  payment: 'pending',
};

test('스페인어 메일 — 고친 부분과 지금 상태가 들어간다', () => {
  const m = composeEditMail({ lang: 'es', reg, parts: ['tours', 'companions'], url: 'https://x' });
  assert.equal(m.subject, '[Conferencia 2027] Un responsable actualizó su inscripción');
  // 고친 부분은 정해진 순서로 — 저장 순서와 상관없이 같은 글이 된다.
  assert.match(m.text, /Qué cambió: Acompañantes, Tours/);
  assert.match(m.text, /Monto a pagar: USD 775/);
  assert.match(m.text, /Veronica Ramirez \(39\)/);
  assert.match(m.text, /Vuelo de llegada: AR1300/);
  assert.match(m.text, /Vuelo de salida: —/);
  assert.match(m.text, /Pago: En revisión/);
  assert.match(m.text, /https:\/\/x/);
});

test('취소된 등록에는 금액 대신 취소되었다고 적는다', () => {
  const m = composeEditMail({ lang: 'ko', reg: { ...reg, cancelled: true }, parts: ['cancel'], url: 'u' });
  assert.match(m.text, /참석 취소되었습니다/);
  assert.doesNotMatch(m.text, /낼 돈/);
});

test('언어 — 앱에서 고른 것이 먼저, 없으면 나라로', () => {
  assert.equal(mailLanguage('pt', 'KR'), 'pt');
  assert.equal(mailLanguage(null, 'KR'), 'ko');
  assert.equal(mailLanguage(null, 'Brasil'), 'pt');
  assert.equal(mailLanguage(null, 'US'), 'en');
  assert.equal(mailLanguage(null, 'AR'), 'es');
  assert.equal(mailLanguage(undefined, null), 'es');
});
