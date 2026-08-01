import { test } from 'node:test';
import assert from 'node:assert/strict';
import pg from 'pg';

// NUMERIC 과 BIGINT 는 숫자로 나와야 한다.
//
// node-postgres 기본값은 문자열이다. 그러면 JSON 에 "180.00" 이 실려 나가고
// Flutter 쪽 `as num?` 캐스팅이 터진다 — 참가비를 설정한 수양회에서 등록
// 화면 전체가 죽었던 실제 원인이다.
//
// DB 없이 파서만 확인한다. 단위 테스트에 DB 연결을 끌어들이면 CI 에서
// 조용히 SKIP 되어 아무것도 지키지 못한다.
test('db.js 를 불러오면 NUMERIC 파서가 숫자를 돌려준다', async () => {
  process.env.DATABASE_URL ??= 'postgres://u:p@localhost:5432/none';
  await import('../src/db.js');

  const numeric = pg.types.getTypeParser(pg.types.builtins.NUMERIC);
  const int8 = pg.types.getTypeParser(pg.types.builtins.INT8);

  assert.equal(numeric('180.00'), 180);
  assert.equal(typeof numeric('180.00'), 'number');
  assert.equal(numeric('0.50'), 0.5);
  assert.equal(numeric(null), null);

  assert.equal(int8('10'), 10);
  assert.equal(typeof int8('10'), 'number');
  assert.equal(int8(null), null);
});
