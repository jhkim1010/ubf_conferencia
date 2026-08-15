// 스테이지에 쌓인 검증용 수양회를 정리한다.
//
// e2e 는 돌 때마다 수양회를 하나씩 만든다. 지우지 않으므로 몇 달이면 백
// 개를 넘고, 그러면 스테이지에서 손으로 확인할 때 목록에서 진짜를 찾지
// 못한다.
//
// **행을 지우지 않는다.** is_active = false 로 내린다 — 등록·배정·배차가
// 이 행을 참조하고, 잘못 골랐을 때 되돌릴 수 있어야 한다. (앱의 삭제도
// 같은 방식이다.)
//
// 사용:
//   node scripts/clean-stage-programs.js            # 무엇이 지워질지만 본다
//   node scripts/clean-stage-programs.js --yes      # 실제로 내린다
//
// DATABASE_URL 을 주지 않으면 .env(스테이지)를 쓴다. **운영 호스트면
// 거부한다** — 이 스크립트가 운영에서 도는 일은 없어야 한다.
import { sql } from '../src/db.js';

const PROD_HINT = 'ep-small-meadow';

// 검증용 이름. e2e 가 쓰는 접미사와, 손으로 확인하며 만든 것들.
const TEST_NAME = /검증|테스트|test|e2e|미리보기|디버그|dbg|probe|이름표시|투어카드|화면검증/i;

async function main() {
  const url = process.env.DATABASE_URL ?? '';
  if (url.includes(PROD_HINT)) {
    console.error('✗ 운영 DB 입니다. 이 스크립트는 스테이지 전용입니다.');
    process.exit(1);
  }
  const host = url.replace(/.*@([^.]+).*/, '$1');
  const apply = process.argv.includes('--yes');

  const rows = await sql`
    SELECT p.id, p.name, p.created_at,
           (SELECT COUNT(*)::int FROM registrations r WHERE r.program_id = p.id) AS regs
    FROM programs p
    WHERE p.is_active = true
    ORDER BY p.created_at
  `;
  const doomed = rows.filter((r) => TEST_NAME.test(r.name));
  const keep = rows.filter((r) => !TEST_NAME.test(r.name));

  console.log(`대상 호스트: ${host}`);
  console.log(`살아 있는 수양회 ${rows.length}개 · 검증용 ${doomed.length}개 · 남길 것 ${keep.length}개`);
  if (keep.length > 0) {
    console.log('\n남길 것:');
    for (const r of keep) console.log(`   ${String(r.regs).padStart(3)}명  ${r.name}`);
  }

  if (!apply) {
    console.log('\n(미리보기입니다. 실제로 내리려면 --yes 를 주십시오.)');
    process.exit(0);
  }
  if (doomed.length === 0) {
    console.log('\n내릴 것이 없습니다.');
    process.exit(0);
  }

  const ids = doomed.map((r) => r.id);
  await sql`UPDATE programs SET is_active = false WHERE id = ANY(${ids})`;
  console.log(`\n✓ ${doomed.length}개를 내렸습니다 (행은 남아 있습니다).`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('정리 오류:', err.message);
    process.exit(1);
  });
