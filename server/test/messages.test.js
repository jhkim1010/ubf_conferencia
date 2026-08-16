import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {
  MESSAGES,
  PATTERNS,
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

/// 라우트가 적은 오류 문구를 모두 걷는다.
///
/// 두 꼴을 본다. 리터럴(`error: '...'`)과 **백틱**(`error: \`...\``).
/// 백틱을 빠뜨리고 있었고, 그래서 다섯 개가 번역 없이 나가는 동안 검사는
/// 통과했다. 백틱은 `${...}` 를 `{}` 로 바꿔 모양만 남긴다 — 그 모양이
/// 곧 빈칸 있는 번역표의 열쇠다.
function errorStringsInRoutes() {
  const plain = new Set();
  const shaped = new Set();
  const lit = /error:\s*(['"])(.+?)\1/g;
  // 백틱은 여러 조각을 `+` 로 이어 붙이기도 한다(media.js 가 그렇다).
  // 앞 조각만 보면 열쇠가 반쪽이 되고, 그 열쇠는 런타임 문자열과 안 맞는다.
  const tmpl = /error:\s*(`[^`]*`(?:\s*\+\s*`[^`]*`)*)/g;
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.js')) {
        const src = fs.readFileSync(p, 'utf8');
        for (const m of src.matchAll(lit)) {
          if (/[가-힣]/.test(m[2])) plain.add(m[2]);
        }
        for (const m of src.matchAll(tmpl)) {
          if (!/[가-힣]/.test(m[1])) continue;
          // 조각들의 알맹이만 이어 붙여 런타임 문자열의 모양을 만든다.
          const joined = [...m[1].matchAll(/`([^`]*)`/g)]
            .map((c) => c[1])
            .join('');
          const shape = joined.replace(/\$\{[^}]*\}/g, '{}');
          // 빈칸이 없으면 그냥 리터럴과 같다.
          if (shape.includes('{}')) shaped.add(shape);
          else plain.add(shape);
        }
      }
    }
  };
  walk(new URL('../src', import.meta.url).pathname);
  return { plain, shaped };
}

test('번역표에 빠진 말이 없다', () => {
  // **이 검사가 이 기능의 핵심이다.** 새 라우트에 오류를 적고 번역표에
  // 넣지 않으면 그 화면만 한국어로 나오고, 스페인어 사용자는 그것을
  // 우리에게 말해 주지 않는다.
  const { plain, shaped } = errorStringsInRoutes();
  const missing = [
    ...[...plain].filter((t) => !MESSAGES[t]),
    ...[...shaped].filter((t) => !PATTERNS[t]),
  ];
  assert.deepEqual(
    missing,
    [],
    `번역표에 없는 오류 문구:\n  ${missing.join('\n  ')}`,
  );
});

test('빈칸 있는 말도 실제로 갈아 끼운다', () => {
  // 열쇠에 있다고 끝이 아니다 — 라우트가 만드는 **완성된 문자열**이
  // 번역돼야 한다. 이게 원래 깨져 있던 부분이다.
  assert.equal(
    translate('"이과수 폭포" 투어는 정원이 마감되었습니다', 'es'),
    'La excursión "이과수 폭포" ya no tiene lugares',
  );
  assert.equal(
    translate('이미 배정된 7명보다 작을 수 없습니다', 'es'),
    'No puede ser menos que las 7 personas ya asignadas',
  );
  // 빈칸이 둘인 것도.
  assert.equal(
    translate('파일이 너무 큽니다 (사진 800KB · PDF 5MB 까지)', 'es'),
    'El archivo es muy grande (hasta 800 KB en fotos · 5 MB en PDF)',
  );
  // 값은 번역하지 않고 그대로 옮긴다 — 고유명사와 숫자다.
  assert.match(translate('사용할 수 없는 항목입니다: tour-x', 'pt'), /tour-x$/);
});

test('빈칸 있는 말은 라우트가 짓는 그대로 맞는다', () => {
  // 열쇠의 모양이 라우트와 어긋나면(띄어쓰기 한 칸, 따옴표 하나) 정규식이
  // 안 맞고 조용히 한국어로 나간다. 실제 소스에서 걷은 모양으로 확인한다.
  const { shaped } = errorStringsInRoutes();
  assert.ok(shaped.size > 0, '백틱 오류를 하나도 못 걷었다 — 걷는 쪽이 깨졌다');
  for (const shape of shaped) {
    // 빈칸에 그럴듯한 값을 넣어 라우트가 만들 문자열을 흉내 낸다.
    const built = shape.replace(/\{\}/g, '값1');
    const out = translate(built, 'es');
    assert.notEqual(out, built, `번역이 안 되고 한국어로 나간다: ${built}`);
    assert.ok(!/[가-힣]/.test(out.replace(/값1/g, '')), `한국어가 남았다: ${out}`);
  }
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
