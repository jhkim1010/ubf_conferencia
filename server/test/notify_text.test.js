import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { NOTIFY, NOTIFY_KEYS, say } from '../src/services/notify_text.js';
import { roleName } from '../src/services/service_roles.js';

// 알림이 받는 사람의 언어로 나가는가 (056)
//
// 오류 문구(055)와 달리 알림은 받는 사람이 없는 자리에서 만들어진다.
// 그래서 완성된 문장을 넘기면 그 순간 언어가 굳어 버리고, 스페인어를 쓰는
// 사람에게 한국어가 간다. 라우트는 `{key, params}` 를 넘겨야 한다.

const LANGS = ['ko', 'es', 'en', 'pt'];

test('모든 알림 문구에 네 언어가 다 있다', () => {
  const holes = [];
  for (const k of NOTIFY_KEYS) {
    for (const l of LANGS) {
      if (!NOTIFY[k][l] || String(NOTIFY[k][l]).trim() === '') holes.push(`${k}.${l}`);
    }
  }
  assert.deepEqual(holes, [], `빠진 번역:\n  ${holes.join('\n  ')}`);
});

test('빈칸이 언어마다 어긋나지 않는다', () => {
  // 한국어에만 {name} 이 있고 스페인어에 없으면 그 언어에서만 이름이 사라진다.
  const bad = [];
  for (const k of NOTIFY_KEYS) {
    const set = (l) =>
      new Set([...String(NOTIFY[k][l]).matchAll(/\{(\w+)\}/g)].map((m) => m[1]));
    const ko = set('ko');
    for (const l of LANGS.slice(1)) {
      const other = set(l);
      const missing = [...ko].filter((x) => !other.has(x));
      const extra = [...other].filter((x) => !ko.has(x));
      if (missing.length || extra.length) {
        bad.push(`${k}.${l}: 빠짐=${missing} 남음=${extra}`);
      }
    }
  }
  assert.deepEqual(bad, [], `빈칸 불일치:\n  ${bad.join('\n  ')}`);
});

test('문구 안에 또 문구를 넣을 수 있다', () => {
  const out = say('admDepartureChanged', {
    who: 'Ana',
    what: { key: 'admDepartureDelayed', params: { when: '14:30' } },
    note: '',
  }, 'es');
  assert.match(out, /Demorado → 14:30/);
  assert.ok(!/[가-힣]/.test(out), `한국어가 남았다: ${out}`);
});

test('이름이 없으면 그 언어의 "참가자" 로 채운다', () => {
  // 비워 두면 "님," 같은 조각만 남아 말이 안 된다.
  assert.match(say('admRegistrationSubmitted', { program: 'X', who: null }, 'es'),
    /Un participante/);
});

test('봉사 역할 이름도 그 언어로 나온다', () => {
  assert.equal(roleName({ key: 'pickup' }, 'es'), 'buscar en el aeropuerto');
  assert.equal(roleName({ key: 'interpreter' }, 'pt'), 'traduzir');
  // 담당자가 적어 준 이름은 그대로 — 번역할 방법이 없다.
  assert.equal(roleName({ key: 'custom:1', label: 'Parrilla' }, 'es'), 'Parrilla');
});

test('map 에 그대로 넘겨도 언어 자리가 깨지지 않는다', () => {
  // roles.map(roleName) 은 두 번째 인자로 **인덱스**를 밀어 넣는다.
  // 실제로 이 함정에 걸렸다 — 감싸서 부르는지 소스로 확인한다.
  const src = stripComments(fs.readFileSync(
    new URL('../src/routes/service_signups.js', import.meta.url).pathname, 'utf8'));
  assert.ok(!/\.map\(roleName\)/.test(src),
    'roles.map(roleName) 은 인덱스를 언어로 넘긴다 — 감싸서 부를 것');
});

test('알림에 완성된 한국어 문장을 넘기는 곳이 없다', () => {
  // **이 검사가 핵심이다.** 문장을 그대로 넘기면 그 순간 언어가 굳는다.
  //
  // 인자 **안만** 본다. 창을 글자 수로 자르면 뒤따라오는 console.error 의
  // 한국어까지 삼켜 오탐이 난다 — 실제로 그렇게 만들었다가 고쳤다.
  const NOTIF = /(sendPushNotification|notifyRegistrations|notifyAudience|notifyProgramAdmins)\s*\(/g;
  const bad = [];
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) { walk(p); continue; }
      if (!e.name.endsWith('.js')) continue;
      const src = stripComments(fs.readFileSync(p, 'utf8'));
      for (const m of src.matchAll(NOTIF)) {
        const args = argsOf(src, m.index + m[0].length - 1);
        // 로그는 알림이 아니다.
        const clean = args.replace(/console\.\w+\([^)]*\)/g, '');
        for (const q of clean.matchAll(/'([^'\n]*)'|`([^`]*)`/g)) {
          const v = q[1] ?? q[2] ?? '';
          if (/[가-힣]/.test(v)) bad.push(`${p.split('/src/')[1]}: ${v.slice(0, 50)}`);
        }
      }
    }
  };
  walk(new URL('../src', import.meta.url).pathname);
  assert.deepEqual(bad, [], `알림에 굳은 한국어:\n  ${bad.join('\n  ')}`);
});

/// 주석을 지운다. 주석 안의 예시 코드에 검사가 걸리면 안 된다.
function stripComments(src) {
  return src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/[^\n]*/g, '$1');
}

/// 여는 괄호부터 짝이 맞는 닫는 괄호까지.
function argsOf(src, openIdx) {
  let depth = 0;
  for (let i = openIdx; i < src.length; i++) {
    if (src[i] === '(') depth++;
    else if (src[i] === ')') { depth--; if (depth === 0) return src.slice(openIdx + 1, i); }
  }
  return '';
}
