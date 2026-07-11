// Neon PostgreSQL 마이그레이션 실행 스크립트
// 실행: node src/db/migrate.js
import 'dotenv/config';
import { readFileSync, readdirSync } from 'fs';
import { resolve, dirname } from 'path';
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

async function runFile(filePath, client) {
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
    }
  }
}

async function migrate() {
  console.log('마이그레이션 시작...\n');

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    const migrationsDir = resolve(__dirname, '../../../ubf_app/supabase/migrations');

    const files = readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    for (const file of files) {
      console.log(`\n--- ${file} ---`);
      await runFile(resolve(migrationsDir, file), client);
    }

    console.log('\n마이그레이션 완료!');
  } finally {
    client.release();
    await pool.end();
  }
}

migrate().catch(console.error);
