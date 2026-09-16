// 저장된 등록의 낼 돈을 다시 센다 (064).
//
// 전후 숙박비를 참가비 합계 안으로 옮겼는데, 서버는 **등록이 저장될 때만**
// 합계를 센다. 그래서 이미 등록을 마친 사람들의 total_cost 에는 숙박비가
// 빠진 채로 남아 있다 — 명단과 내보내는 파일이 그 숫자를 그대로 쓴다.
//
// 이것을 마이그레이션에 넣지 않는 이유는, migrate.js 가 매 실행마다 전체를
// 재적용하기 때문이다. UPDATE 백필은 두 번째 실행에서 그 뒤에 바뀐 값을
// 덮어쓴다.
//
// **박수는 저장된 값을 그대로 쓴다.** 비행 일정에서 다시 내지 않는다 —
// 그 셈은 저장 시점의 항공편을 보고 한 것이고, 여기서 다시 하면 그 뒤에
// 바뀐 항공편으로 조용히 다른 값이 나온다. 여기서 고치는 것은 **금액뿐**이다.
//
// 쓰는 법 — 반드시 확인부터:
//   cd server
//   node scripts/recompute-totals.js          # 무엇이 바뀌는지 보여만 준다
//   node scripts/recompute-totals.js --yes    # 실제로 쓴다
//
// 운영에 대고 돌릴 때:
//   DATABASE_URL="$(grep '^DATABASE_URL=' .env.prod | cut -d= -f2-)" \
//     node scripts/recompute-totals.js
import { sql } from '../src/db.js';
import { registrationTotal } from '../src/services/registration_total.js';

const host = (process.env.DATABASE_URL ?? '').replace(/.*@([^.]+).*/s, '$1');
const apply = process.argv.includes('--yes');

const rows = await sql`
  SELECT r.id, r.real_name, r.total_cost, r.fee_tier,
         r.selected_options, r.hotel_option_key,
         r.hotel_nights_before, r.hotel_nights_after,
         r.discount_status, r.discount_amount,
         p.name AS program_name, p.fee_basic, p.fee_premium, p.hotel_options
    FROM registrations r
    JOIN programs p ON p.id = r.program_id
   ORDER BY p.name, r.real_name`;

console.log(`DB ${host} · 등록 ${rows.length}건\n`);

const changes = [];

for (const r of rows) {
  // 고른 투어 값의 합.
  //
  // **저장 경로(routes/registrations.js)와 같은 규칙이어야 한다.** 이 스크립트가
  // 할 일은 오늘의 서버가 낼 값을 그대로 채우는 것이다. 규칙이 갈리면 여기서
  // 채운 숫자를 앱이 다시 내지 못하고, 그 사람이 한 번만 저장해도 도로 튄다.
  //
  // 그쪽이 그만둔 투어(is_active = false)를 안 세므로 여기서도 안 센다.
  const ids = Array.isArray(r.selected_options) ? r.selected_options : [];
  const [{ sum } = { sum: 0 }] = ids.length
    ? await sql`
        SELECT COALESCE(SUM(cost), 0)::numeric AS sum
          FROM program_options
         WHERE id = ANY(${ids}) AND is_active = true`
    : [{ sum: 0 }];

  const { total, hotelCost } = registrationTotal({
    tier: r.fee_tier,
    feeBasic: r.fee_basic,
    feePremium: r.fee_premium,
    optionsCost: Number(sum ?? 0),
    hotelOptions: r.hotel_options,
    hotelKey: r.hotel_option_key,
    hotelNights: Number(r.hotel_nights_before ?? 0) + Number(r.hotel_nights_after ?? 0),
    approvedDiscount:
      r.discount_status === 'approved' ? Number(r.discount_amount ?? 0) : 0,
  });

  const before = Number(r.total_cost ?? 0);
  if (Math.abs(before - total) < 0.005) continue;

  changes.push({ id: r.id, name: r.real_name, program: r.program_name, before, total, hotelCost });
}

if (changes.length === 0) {
  console.log('바뀔 것이 없습니다.');
  process.exit(0);
}

for (const c of changes) {
  const sign = c.total > c.before ? '+' : '';
  console.log(
    `  ${(c.name ?? '(이름 없음)').padEnd(18)} ${String(c.before).padStart(8)} → ${String(c.total).padStart(8)}` +
      `  (${sign}${(c.total - c.before).toFixed(2)}${c.hotelCost ? `, 숙박 ${c.hotelCost}` : ''})`,
  );
}
console.log(`\n${changes.length}건이 바뀝니다.`);

if (!apply) {
  console.log('\n실제로 쓰려면 --yes 를 붙이십시오. 아무것도 안 바꿨습니다.');
  process.exit(0);
}

await sql.transaction(async (client) => {
  for (const c of changes) {
    await client.query('UPDATE registrations SET total_cost = $1 WHERE id = $2', [
      c.total,
      c.id,
    ]);
  }
});

console.log(`\n${changes.length}건을 고쳤습니다.`);
process.exit(0);
