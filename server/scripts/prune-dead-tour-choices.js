// 죽은 투어를 가리키는 선택을 지운다.
//
// repair-orphan-tour-choices.js 는 **같은 이름으로 살아 있는 옵션이 있을 때**
// 그쪽으로 옮긴다. 짝을 못 찾은 것은 그대로 둔다 — 어느 것으로 옮길지 모르는
// 채 옮기면 남의 투어에 넣게 되기 때문이다.
//
// 그렇게 남은 것을 여기서 지운다. 죽은 옵션은 참가자 화면에 안 보이므로
// 본인은 그것이 붙어 있는 줄도 모르는데, **저장 경로는 is_active 를 보지 않아
// 값은 그대로 매겨진다.** 운영에서 한 분이 이과수 투어에 두 번 값이 매겨져
// 있었다 — 담당자가 이름을 고치면서(Carata → Catarata) 새 옵션이 생겼고,
// 옛 것이 선택에 남았다.
//
// **먼저 repair-orphan-tour-choices.js 를 돌리십시오.** 이것은 지우는 일이라
// 옮길 수 있는 것까지 지워 버리면 그 사람의 신청이 사라진다.
//
// 지운 뒤에는 recompute-totals.js 로 금액을 다시 맞추십시오.
//
// 쓰는 법 — 반드시 확인부터:
//   cd server
//   node scripts/prune-dead-tour-choices.js          # 무엇을 지울지 보여만 준다
//   node scripts/prune-dead-tour-choices.js --yes    # 실제로 지운다
import { sql } from '../src/db.js';

const host = (process.env.DATABASE_URL ?? '').replace(/.*@([^.]+).*/s, '$1');
const apply = process.argv.includes('--yes');

const rows = await sql`
  SELECT r.id, r.real_name, p.name AS program,
         dead.id AS dead_id, dead.name AS dead_name, dead.cost AS dead_cost,
         (SELECT COUNT(*) FROM program_options alive
           WHERE alive.program_id = r.program_id AND alive.is_active = true
             AND alive.name = dead.name)::int AS same_name_alive
    FROM registrations r
    JOIN programs p ON p.id = r.program_id
    CROSS JOIN LATERAL unnest(r.selected_options) AS sel(opt)
    JOIN program_options dead ON dead.id = sel.opt AND dead.is_active = false
   ORDER BY r.real_name`;

console.log(`DB ${host}\n`);

if (rows.length === 0) {
  console.log('죽은 투어를 가리키는 선택이 없습니다.');
  process.exit(0);
}

// 같은 이름으로 살아 있는 것이 있으면 **지우지 않는다.** 옮기는 일이지
// 지우는 일이 아니다 — repair-orphan-tour-choices.js 가 할 몫이다.
const movable = rows.filter((r) => r.same_name_alive > 0);
const prunable = rows.filter((r) => r.same_name_alive === 0);

for (const r of movable) {
  console.log(
    `  건너뜀  ${r.real_name} · ${r.dead_name} — 같은 이름이 살아 있습니다.` +
      ' repair-orphan-tour-choices.js 로 옮기십시오.',
  );
}

for (const r of prunable) {
  console.log(`  지움    ${r.real_name} · ${r.dead_name} (${r.dead_cost}) · ${r.program}`);
}

if (prunable.length === 0) {
  console.log('\n지울 것이 없습니다.');
  process.exit(0);
}
console.log(`\n${prunable.length}건을 지웁니다.`);

if (!apply) {
  console.log('\n실제로 지우려면 --yes 를 붙이십시오. 아무것도 안 바꿨습니다.');
  process.exit(0);
}

await sql.transaction(async (client) => {
  for (const r of prunable) {
    await client.query(
      'UPDATE registrations SET selected_options = array_remove(selected_options, $1) WHERE id = $2',
      [r.dead_id, r.id],
    );
  }
});

console.log(`\n${prunable.length}건을 지웠습니다.`);
console.log('금액은 scripts/recompute-totals.js 로 다시 맞추십시오.');
process.exit(0);
