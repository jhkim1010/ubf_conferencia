import pg from 'pg';
import 'dotenv/config';

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL 환경변수가 설정되지 않았습니다');
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30000,
});

// sql 태그 함수: 기존 라우트 코드와 동일한 인터페이스 유지
// 사용 예: sql`SELECT * FROM users WHERE id = ${userId}`
export const sql = async (strings, ...values) => {
  const text = strings.reduce(
    (acc, str, i) => acc + str + (i < values.length ? `$${i + 1}` : ''),
    '',
  );
  const { rows } = await pool.query(text, values);
  return rows;
};

// 트랜잭션: BEGIN → 쿼리들 → COMMIT, 오류 시 ROLLBACK
sql.transaction = async (fn) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};
