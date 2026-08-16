import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {
  MESSAGES,
  pickLanguage,
  translate,
} from '../src/services/messages.js';

// 스페인어를 쓰는 공동 관리자에게 한국어 오류가 뜨면, 무엇이 잘못됐는지
// 알 길이 없다. 라우트는 한국어로 적고 나가는 길목에서 갈아 끼운다.

test('Accept-Language 에서 언어를 고른다', () => {
  assert.equal(pickLanguage('es-AR,es;q=0.9,en;q=0.8'), 'es');
  assert.equal(pickLanguage('pt-BR'), 'pt');
  assert.equal(pickLanguage('en-US,en'), 'en');
  assert.equal(pickLanguage('ko-KR'), 'ko');
});

test('모르는 언어면 한국어 그대로', () => {
  // 잘못 번역된 말보다 원문이 낫다.
  assert.equal(pickLanguage('fr-FR'), 'ko');
  assert.equal(pickLanguage(''), 'ko');
  assert.equal(pickLanguage(undefined), 'ko');
});

test('아는 말은 바꾼다', () => {
  assert.equal(translate('서버 오류', 'es'), 'Error del servidor');
  assert.equal(translate('권한 없음', 'pt'), 'Sem permissão');
  assert.equal(translate('방 정원이 가득 찼습니다', 'en'), 'The room is full');
});

test('모르는 말은 원문 그대로', () => {
  // 번역표에 없다고 응답이 비면 화면에 아무 설명도 안 뜬다.
  assert.equal(translate('처음 보는 오류', 'es'), '처음 보는 오류');
  assert.equal(translate('서버 오류', 'ko'), '서버 오류');
});

test('번역표에 빠진 말이 없다', () => {
  // **이 검사가 이 기능의 핵심이다.** 새 라우트에 오류를 적고 번역표에
  // 넣지 않으면 그 화면만 한국어로 나오고, 스페인어 사용자는 그것을
  // 우리에게 말해 주지 않는다.
  const found = new Set();
  const pat = /error:\s*(['"])(.+?)\1/g;
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.js')) {
        const src = fs.readFileSync(p, 'utf8');
        for (const m of src.matchAll(pat)) {
          if (/[가-힣]/.test(m[2])) found.add(m[2]);
        }
      }
    }
  };
  walk(new URL('../src', import.meta.url).pathname);

  const missing = [...found].filter((t) => !MESSAGES[t]);
  assert.deepEqual(
    missing,
    [],
    `번역표에 없는 오류 문구:\n  ${missing.join('\n  ')}`,
  );
});

test('세 언어가 모두 채워져 있다', () => {
  const holes = [];
  for (const [ko, row] of Object.entries(MESSAGES)) {
    for (const lang of ['es', 'en', 'pt']) {
      if (!row[lang] || row[lang].trim() === '') holes.push(`${ko} (${lang})`);
    }
  }
  assert.deepEqual(holes, [], `빠진 번역:\n  ${holes.join('\n  ')}`);
});
