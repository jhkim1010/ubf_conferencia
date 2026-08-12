// e2e-chapter-programs 가 스테이지에 남긴 수양회를 지운다.
//
// 그 검사는 뒷정리로 confirmName 을 "x" 로 보내고 있었고, 서버가 정당하게
// 거절해서 실행할 때마다 수양회가 쌓였다. 뒷정리는 고쳤지만(101b2ee) 이미
// 쌓인 것은 남아 있다.
//
// 쓰는 법 — 반드시 확인부터:
//   cd server
//   node scripts/clean-chapter-test-data.js          # 무엇을 지울지 보여만 준다
//   node scripts/clean-chapter-test-data.js --yes    # 실제로 지운다
//
// DATABASE_URL 은 server/.env 를 따른다(기본 stage). 운영에 대고 돌릴 일은
// 없어야 하므로, 지우기 전에 어느 DB 인지 찍어 준다.
import { sql } from '../src/db.js';

// 이 세 가지 이름 형태만 지운다. e2e-chapter-programs 가 만드는 것이 전부다.
const PATTERNS = ['부에노스수양회-%', '코르도바수양회-%', '지난수양회-%'];

const host = (process.env.DATABASE_URL ?? '').replace(/.*@([^.]+).*/s, '$1');
const apply = process.argv.includes('--yes');

const rows = await sql`
  SELECT p.id, p.name, p.is_active,
         (SELECT COUNT(*) FROM registrations WHERE program_id = p.id)::int AS regs
  FROM programs p
  WHERE p.name LIKE ANY (${PATTERNS})
  ORDER BY p.name
`;

console.log(`DB: ${host || '(알 수 없음)'}`);
if (rows.length === 0) {
  console.log('지울 것이 없습니다.');
  process.exit(0);
}
console.log(`대상 ${rows.length}개 · 딸린 등록 ${rows.reduce((n, r) => n + r.regs, 0)}건`);
for (const r of rows) console.log(`  ${r.name}${r.is_active ? '' : ' (이미 비활성)'}`);

if (!apply) {
  console.log('\n실제로 지우려면 --yes 를 붙이십시오.');
  process.exit(0);
}

// registrations 는 ON DELETE CASCADE 로 함께 지워진다(001).
const deleted = await sql`
  DELETE FROM programs WHERE name LIKE ANY (${PATTERNS}) RETURNING id
`;
console.log(`\n${deleted.length}개 지웠습니다.`);
process.exit(0);
