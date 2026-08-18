import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

// 누가 참가자로 세어지는가 (055)
//
// 규칙 자체는 SQL 함수라 여기서 직접 부를 수 없다. 대신 **같은 규칙이 두
// 벌로 갈라지지 않는지** 를 본다 — 이 저장소에서 이미 두 번 겪은 사고다
// (식사 제한 027·036: 카드는 4명 표는 2명).

const SRC = new URL('../src/', import.meta.url).pathname;

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = dir + e.name;
    if (e.isDirectory()) walk(p + '/', out);
    else if (e.name.endsWith('.js')) out.push([p, fs.readFileSync(p, 'utf8')]);
  }
  return out;
}

test('참가자 판정을 손으로 다시 적은 곳이 없다', () => {
  // `real_name <> ''` 를 직접 적으면 그 화면만 다른 사람 수를 말하게 된다.
  const hand = [];
  for (const [p, src] of walk(SRC)) {
    for (const [i, line] of src.split('\n').entries()) {
      if (/real_name\s*(IS NOT NULL|<>\s*'')/.test(line)) {
        hand.push(`${p.split('/src/')[1]}:${i + 1}`);
      }
    }
  }
  assert.deepEqual(hand, [], `판정을 손으로 적은 곳:\n  ${hand.join('\n  ')}`);
});

test('명단·집계는 counts_as_participant 를 쓴다', () => {
  // has_registrant_name 은 준비 현황 전용이다 — "개인정보 단계를 끝냈나"
  // 라는 다른 질문이다. 그 밖에서 쓰이면 제출한 사람이 또 사라진다.
  const stray = [];
  for (const [p, src] of walk(SRC)) {
    const rel = p.split('/src/')[1];
    for (const [i, line] of src.split('\n').entries()) {
      if (!line.includes('has_registrant_name')) continue;
      // 준비 현황(cohort) 안의 단계 집계만 예외다.
      if (rel === 'routes/programs.js' && /personal|THEN 'personal'/.test(line)) continue;
      stray.push(`${rel}:${i + 1}`);
    }
  }
  assert.deepEqual(
    stray,
    [],
    `준비 현황 밖에서 옛 판정을 쓴다:\n  ${stray.join('\n  ')}`,
  );
});

test('제출하려면 이름이 있어야 한다', () => {
  // 이름 없이 제출되면 그 사람은 명단에서 사라진다. 운영에서 실제로
  // 한 명이 그렇게 되었다.
  const src = fs.readFileSync(SRC + 'routes/registrations.js', 'utf8');
  const submit = src.slice(src.indexOf("'/:programId/me/submit'"));
  const guard = submit.slice(0, submit.indexOf('SET submitted = true'));
  assert.match(
    guard,
    /real_name[\s\S]{0,200}?이름을 적어 주세요/,
    '제출 처리가 이름을 확인하지 않는다',
  );
});
