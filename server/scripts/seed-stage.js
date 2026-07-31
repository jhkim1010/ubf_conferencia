// stage 환경 시드 — 브라우저 검증용 가상 데이터
//
// 실행:
//   cd server
//   DATABASE_URL="$(grep '^DATABASE_URL_DIRECT=' .env.stage | cut -d= -f2-)" node scripts/seed-stage.js
//   ... --region PE    (해외 참석자 시나리오로 전환)
//
// 안전장치: DATABASE_URL 이 .env(운영)와 같으면 실행을 거부한다.

import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __dirname = dirname(fileURLToPath(import.meta.url));
const { Pool } = pg;

const url = process.env.DATABASE_URL;
if (!url) {
  console.error('DATABASE_URL 이 필요합니다.');
  process.exit(1);
}

// 운영 DB 보호: server/.env 의 호스트와 같으면 중단
try {
  const prodEnv = readFileSync(resolve(__dirname, '../.env'), 'utf-8');
  const prodUrl = prodEnv.match(/^DATABASE_URL=(.+)$/m)?.[1] ?? '';
  const host = (u) => (u.match(/@([^/]+)\//) ?? [])[1] ?? '';
  if (host(prodUrl) && host(prodUrl) === host(url)) {
    console.error('✗ 운영 DB 로 보입니다. stage 연결 문자열을 쓰십시오.');
    console.error(`  host=${host(url)}`);
    process.exit(1);
  }
} catch {
  // .env 가 없으면 비교를 건너뛴다
}

// --region <코드> 로 참석자 거주 국가를 바꾼다 (국내/해외 시나리오 전환)
const regionArg = process.argv.indexOf('--region');
const REGION = regionArg > -1 ? process.argv[regionArg + 1] : 'BR';

const HOST_COUNTRY = 'BR';
const DEV_EMAIL = 'dev@test.com';

const pool = new Pool({ connectionString: url });

async function main() {
  console.log(`시드 시작 — host_country=${HOST_COUNTRY}, 참석자 region=${REGION}`);

  // 1. 지부장(리더) 사용자 + leaders 등록
  const [leaderUser] = (
    await pool.query(
      `INSERT INTO users (google_id, email, name, role, region, profile_completed)
       VALUES ('dev:leader@test.com', 'leader@test.com', '박지부장', 'director', $1, TRUE)
       ON CONFLICT (google_id) DO UPDATE
         SET role = 'director', region = EXCLUDED.region, updated_at = NOW()
       RETURNING id`,
      [HOST_COUNTRY],
    )
  ).rows;

  const [leader] = (
    await pool.query(
      `INSERT INTO leaders (user_id, gmail, name)
       VALUES ($1, 'leader@test.com', '박지부장')
       ON CONFLICT (user_id) DO UPDATE SET name = EXCLUDED.name
       RETURNING id`,
      [leaderUser.id],
    )
  ).rows;

  // 2. 참가자(dev 로그인 대상). region 으로 국내/해외가 갈린다.
  await pool.query(
    `INSERT INTO users (google_id, email, name, role, region, age, profile_completed)
     VALUES ($1, $2, '테스트 참가자', 'participant', $3, 28, TRUE)
     ON CONFLICT (google_id) DO UPDATE
       SET region = EXCLUDED.region, profile_completed = TRUE, updated_at = NOW()`,
    ['dev:' + DEV_EMAIL, DEV_EMAIL, REGION],
  );

  // 3. 수양회 프로그램 — 개최국 BR
  const existing = await pool.query(
    `SELECT id FROM programs WHERE name = $1`,
    ['2026 UBF 국제 수양회'],
  );

  let programId;
  if (existing.rows.length > 0) {
    programId = existing.rows[0].id;
    await pool.query(`UPDATE programs SET host_country = $1 WHERE id = $2`, [
      HOST_COUNTRY,
      programId,
    ]);
  } else {
    const [p] = (
      await pool.query(
        `INSERT INTO programs
           (name, location, leader_id, start_date, end_date, is_active,
            program_type, host_country, nearest_airport, enabled_sections)
         VALUES ($1, $2, $3, $4, $5, TRUE, 'international', $6, 'GRU', $7)
         RETURNING id`,
        [
          '2026 UBF 국제 수양회',
          '브라질 상파울루',
          leader.id,
          '2026-08-14',
          '2026-08-18',
          HOST_COUNTRY,
          JSON.stringify({
            arrival_flight: true,
            departure_flight: true,
            food_requirements: true,
            program_options: true,
            roommate: true,
            volunteer_resources: true,
          }),
        ],
      )
    ).rows;
    programId = p.id;
  }

  console.log('');
  console.log('완료');
  console.log(`  프로그램 ID : ${programId}`);
  console.log(`  개최국      : ${HOST_COUNTRY}`);
  console.log(`  참석자 region: ${REGION}  → ${REGION === HOST_COUNTRY ? '국내(항공편 생략 예상)' : '해외(항공편 입력 예상)'}`);
  console.log(`  등록 URL    : /registration/${programId}`);
  console.log(`  대시보드 URL: /leader/program/${programId}/dashboard`);
}

main()
  .catch((e) => {
    console.error('✗ 시드 실패:', e.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
