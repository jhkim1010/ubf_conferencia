// Neon PostgreSQL 마이그레이션 실행 스크립트
// 실행: node src/db/migrate.js
import 'dotenv/config';
import { readFileSync, readdirSync } from 'fs';
import { resolve, dirname, basename } from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
const { Pool } = pg;

const __dirname = dirname(fileURLToPath(import.meta.url));

// $$ 블록(함수/트리거 본문)을 고려하여 세미콜론으로 구문 분리
function splitStatements(sql) {
  const statements = [];
  let current = '';
  let inDollarBlock = false;

  for (const line of sql.split('\n')) {
    const trimmed = line.trim();
    // $$ 토글 감지
    if (trimmed.includes('$$')) {
      inDollarBlock = !inDollarBlock;
    }
    current += line + '\n';

    // $$ 블록 밖에서 세미콜론으로 끝나면 구문 완성
    if (!inDollarBlock && trimmed.endsWith(';')) {
      const stmt = current.trim().replace(/;$/, '');
      if (stmt.length > 0) statements.push(stmt);
      current = '';
    }
  }
  // 남은 내용 처리
  const remaining = current.trim().replace(/;$/, '');
  if (remaining.length > 0) statements.push(remaining);

  return statements;
}

// 파일 하나를 적용하고 실패한 구문 목록을 반환한다.
// 실패해도 중단하지 않는다 — 한 번에 모든 문제를 보기 위함이다.
// 대신 호출자가 실패 건수를 집계해 종료 코드에 반영한다.
async function runFile(filePath, client) {
  const failures = [];
  const schema = readFileSync(filePath, 'utf-8');
  const statements = splitStatements(schema).filter(s => {
    // 순수 주석만 있는 구문 제외
    const nonComment = s.split('\n')
      .filter(l => !l.trim().startsWith('--'))
      .join('\n')
      .trim();
    return nonComment.length > 0;
  });

  for (const statement of statements) {
    const preview = statement.replace(/\n/g, ' ').replace(/\s+/g, ' ').slice(0, 70);
    try {
      await client.query(statement);
      console.log('✓', preview);
    } catch (err) {
      console.error('✗ 오류:', preview);
      console.error('  ', err.message);
      failures.push({ file: basename(filePath), preview, message: err.message });
    }
  }

  return failures;
}

async function migrate() {
  console.log('마이그레이션 시작...\n');

  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL 환경변수가 설정되지 않았습니다');
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();
  const failures = [];

  try {
    const migrationsDir = resolve(__dirname, '../../../ubf_app/supabase/migrations');

    const files = readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    for (const file of files) {
      console.log(`\n--- ${file} ---`);
      failures.push(...await runFile(resolve(migrationsDir, file), client));
    }
  } finally {
    client.release();
    await pool.end();
  }

  if (failures.length > 0) {
    console.error(`\n실패한 구문 ${failures.length}건:`);
    for (const f of failures) {
      console.error(`  [${f.file}] ${f.preview}`);
      console.error(`      ${f.message}`);
    }
    // 이력 추적이 없어 매 실행마다 전체가 재적용된다. 실패를 성공으로 보고하면
    // 상위 자동화(CI / verify.sh / 에이전트)가 잘못된 판단을 하므로 반드시 비정상 종료한다.
    throw new Error(`마이그레이션 실패 — ${failures.length}건의 구문이 적용되지 않았습니다`);
  }

  console.log('\n마이그레이션 완료!');
}

migrate().catch((err) => {
  console.error('\n✗ 마이그레이션 중단:', err.message);
  process.exitCode = 1;
});
