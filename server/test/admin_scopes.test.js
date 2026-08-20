import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { SCOPES, requireScope } from '../src/services/admin_scopes.js';

// 공동 관리자가 맡은 분야 (059)
//
// **분야를 안 적은 라우트는 조용히 아무나 통과한다.** 픽업만 맡은 사람이
// 장부를 열어도 아무 일도 일어나지 않고, 아무도 그것을 신고하지 않는다.
// 그래서 적었는지를 검사가 본다.

const SRC = new URL('../src/routes/', import.meta.url).pathname;

test('분야 이름은 아홉이고 서로 다르다', () => {
  assert.equal(new Set(SCOPES).size, SCOPES.length);
  assert.deepEqual(SCOPES, [
    'transport', 'rooms', 'groups', 'ledger', 'service',
    'registration', 'comms', 'schedule', 'medical',
  ]);
});

test('requireProgramAdmin 을 쓰는 라우트는 모두 분야를 적었다', () => {
  const missing = [];
  for (const f of fs.readdirSync(SRC)) {
    if (!f.endsWith('.js')) continue;
    const src = fs.readFileSync(path.join(SRC, f), 'utf8');
    // 주석과 **import 줄**은 빼고 본다. 둘 다 라우트가 아닌데, 처음에
    // import 를 안 뺐다가 여덟 곳을 잘못 잡았다.
    const code = src
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/(^|[^:])\/\/[^\n]*/g, '$1')
      .replace(/^import[\s\S]*?from\s+'[^']*';/gm, '');
    for (const m of code.matchAll(/requireProgramAdmin\s*,/g)) {
      // 바로 뒤(줄바꿈·공백 포함)에 requireScope 가 와야 한다.
      const after = code.slice(m.index + m[0].length, m.index + m[0].length + 80);
      if (!/^\s*requireScope\s*\(/.test(after)) {
        const line = code.slice(0, m.index).split('\n').length;
        missing.push(`${f}:${line}`);
      }
    }
  }
  assert.deepEqual(
    missing,
    [],
    `분야를 안 적은 라우트:\n  ${missing.join('\n  ')}`,
  );
});

test('아는 분야 이름만 쓴다', () => {
  const bad = [];
  for (const f of fs.readdirSync(SRC)) {
    if (!f.endsWith('.js')) continue;
    const src = fs.readFileSync(path.join(SRC, f), 'utf8');
    for (const m of src.matchAll(/requireScope\(([^)]*)\)/g)) {
      const args = m[1];
      if (args.includes('...SCOPES')) continue;
      for (const q of args.matchAll(/'([^']+)'/g)) {
        if (!SCOPES.includes(q[1])) bad.push(`${f}: ${q[1]}`);
      }
    }
  }
  assert.deepEqual(bad, [], `모르는 분야 이름:\n  ${bad.join('\n  ')}`);
});

// ── 판정 자체 ────────────────────────────────────────────────
const run = (scopes, needed) => {
  let allowed = false;
  let denied = null;
  requireScope(...needed)(
    { adminScopes: scopes },
    { status: () => ({ json: (b) => { denied = b; } }) },
    () => { allowed = true; },
  );
  return { allowed, denied };
};

test('전부 맡은 사람은 무엇이든 통과', () => {
  assert.equal(run(null, ['ledger']).allowed, true);
});

test('맡은 분야만 통과', () => {
  assert.equal(run(['rooms', 'transport'], ['rooms']).allowed, true);
  assert.equal(run(['rooms', 'transport'], ['ledger']).allowed, false);
});

test('여럿 중 하나만 맡아도 통과', () => {
  // 대시보드처럼 여러 분야가 함께 보이는 화면이 있다.
  assert.equal(run(['ledger'], ['registration', 'ledger']).allowed, true);
});

test('막을 때는 무엇이 막혔는지 말한다', () => {
  const { denied } = run(['rooms'], ['ledger']);
  assert.match(denied.error, /맡지 않으셨습니다/);
});
