import pg from 'pg';
import 'dotenv/config';

const { Pool } = pg;

// NUMERIC 과 BIGINT 를 숫자로 파싱한다.
//
// node-postgres 는 이 두 타입을 **문자열로** 돌려준다. 임의 정밀도라서
// JS number 로 담으면 정밀도를 잃을 수 있기 때문인데, 그 결과 JSON 에
// "180.00" 같은 문자열이 실려 나가고 앱이 그대로 터진다:
//
//   type 'String' is not a subtype of type 'num?' in type cast
//
// 실제로 참가비를 넣은 수양회에서 등록 화면 전체가 이 예외로 죽었다.
// 화면마다 캐스팅을 고치면 새 화면을 만들 때마다 같은 함정을 다시 밟는다.
// 여기서 한 번 고친다.
//
// 이 저장소가 다루는 값은 참가비·할인 금액(NUMERIC(10,2))과 COUNT(*) 이고,
// 모두 double 로 정확히 표현되는 범위다. 그 범위를 넘는 값을 다루게 되면
// 이 설정을 다시 검토해야 한다.
pg.types.setTypeParser(pg.types.builtins.NUMERIC, (v) => (v === null ? null : Number(v)));
pg.types.setTypeParser(pg.types.builtins.INT8, (v) => (v === null ? null : Number(v)));

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
