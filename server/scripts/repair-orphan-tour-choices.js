// 죽은 투어 옵션을 가리키는 신청을 살아 있는 같은 이름의 옵션으로 옮긴다.
//
// 수양회를 저장할 때마다 옵션을 전부 비활성화하고 새로 넣던 시절이 있었다.
// 그때마다 옵션 id 가 바뀌었고, 이미 신청한 사람의 selected_options 는 죽은
// id 를 가리키게 됐다. 그 선택은 투어 화면에서 사라지는데 대시보드 카드에는
// 남아, 카드는 4명인데 안에는 2명이었다.
//
// 저장 쪽은 고쳤지만(id 를 그대로 둔다) 이미 어긋난 데이터는 남아 있다.
// 이것을 마이그레이션에 넣지 않는 이유는, migrate.js 가 매 실행마다 전체를
// 재적용하기 때문이다 — UPDATE 백필은 두 번째 실행에서 사용자가 그 뒤에
// 고친 내용을 덮어쓴다.
//
// 쓰는 법 — 반드시 확인부터:
//   cd server
//   node scripts/repair-orphan-tour-choices.js          # 무엇을 고칠지 보여만 준다
//   node scripts/repair-orphan-tour-choices.js --yes    # 실제로 고친다
//
// 운영에 대고 돌릴 때:
//   DATABASE_URL="$(grep '^DATABASE_URL=' .env.prod | cut -d= -f2-)" \
//     node scripts/repair-orphan-tour-choices.js
import { sql } from '../src/db.js';

const host = (process.env.DATABASE_URL ?? '').replace(/.*@([^.]+).*/s, '$1');
const apply = process.argv.includes('--yes');

// 죽은 id 하나마다 한 줄. 같은 수양회 안에서 **이름이 같은 살아 있는 옵션**을
// 짝으로 찾는다. 이름이 유일하지 않으면 짝을 못 짓고 그대로 둔다 —
// 어느 쪽인지 모르는 채로 옮기면 남의 투어에 넣게 된다.
const rows = await sql`
  SELECT r.id            AS registration_id,
         r.real_name,
         p.name          AS program_name,
         dead.id         AS dead_id,
         dead.name       AS option_name,
         alive.id        AS alive_id
  FROM registrations r
  JOIN programs p ON p.id = r.program_id
  CROSS JOIN LATERAL unnest(r.selected_options) AS sel(opt)
  JOIN program_options dead
    ON dead.id = sel.opt AND dead.program_id = r.program_id AND dead.is_active = false
  LEFT JOIN LATERAL (
    SELECT o.id FROM program_options o
    WHERE o.program_id = r.program_id AND o.is_active AND o.name = dead.name
    LIMIT 2
  ) alive ON true
  ORDER BY p.name, r.real_name, dead.name
`;

console.log(`DB: ${host || '(알 수 없음)'}`);
if (rows.length === 0) {
  console.log('죽은 옵션을 가리키는 신청이 없습니다.');
  process.exit(0);
}

const fixable = rows.filter((r) => r.alive_id);
const stuck = rows.filter((r) => !r.alive_id);

console.log(`죽은 id 를 가리키는 신청 ${rows.length}건`);
for (const r of rows) {
  const mark = r.alive_id ? '→ ' + String(r.alive_id).slice(0, 8) : '★ 짝을 못 찾음';
  console.log(`  ${String(r.real_name ?? '(이름 없음)').padEnd(14)} ${r.option_name}  ${String(r.dead_id).slice(0, 8)} ${mark}`);
}
if (stuck.length > 0) {
  console.log(`\n짝을 못 찾은 ${stuck.length}건은 손대지 않습니다 — 같은 이름의 살아 있는 옵션이 없습니다.`);
}

if (!apply) {
  console.log('\n실제로 고치려면 --yes 를 붙이십시오.');
  process.exit(0);
}

let moved = 0;
for (const r of fixable) {
  // 옮긴 뒤 중복이 생길 수 있다(이미 살아 있는 쪽도 골라 둔 사람). 배열에서
  // 죽은 id 를 빼고, 살아 있는 id 가 없을 때만 넣는다.
  const res = await sql`
    UPDATE registrations
    SET selected_options = (
          SELECT array_agg(DISTINCT v)
          FROM unnest(
            array_remove(selected_options, ${r.dead_id}::uuid) || ARRAY[${r.alive_id}::uuid]
          ) AS v
        ),
        updated_at = NOW()
    WHERE id = ${r.registration_id}
    RETURNING id
  `;
  moved += res.length;
}
console.log(`\n${moved}건을 살아 있는 옵션으로 옮겼습니다.`);
process.exit(0);
