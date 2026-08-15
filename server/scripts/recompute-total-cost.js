// 낼 돈을 다시 계산한다 (054)
//
// 참가비 등급(fee_tier)을 안 고른 사람의 낼 돈이 0 으로 저장돼 있었다.
// 등급 화면을 지나치기만 해도 그렇게 됐고, 운영 명단 열둘 중 여섯이 그
// 상태였다 — 표에 0 원으로 보이니 아무도 받으러 가지 않는다.
//
// 라우트는 고쳤다(등급을 안 골랐으면 기본 참가비). 이미 저장된 행은 여기서
// 다시 센다.
//
// **마이그레이션에 넣지 않는다.** migrate.js 는 매 실행마다 모든 파일을 다시
// 돌리므로, UPDATE 를 넣으면 그 뒤에 사람이 고친 금액을 매번 덮어쓴다.
//
// 세는 방법은 라우트와 같다:
//   기본(또는 프리미엄) 참가비 + 고른 투어 값 − 승인된 할인
//
// 사용:
//   node scripts/recompute-total-cost.js                 # 무엇이 바뀔지만 본다
//   node scripts/recompute-total-cost.js --yes           # 실제로 고친다
//   PROGRAM_ID=... node scripts/recompute-total-cost.js  # 한 수양회만
import { sql } from '../src/db.js';

async function main() {
  const apply = process.argv.includes('--yes');
  const only = process.env.PROGRAM_ID ?? null;

  const rows = await sql`
    SELECT r.id, r.real_name, r.total_cost, r.fee_tier,
           r.discount_status, r.discount_amount, r.selected_options,
           p.id AS program_id, p.name AS program_name,
           p.fee_basic, p.fee_premium, p.currency
    FROM registrations r
    JOIN programs p ON p.id = r.program_id
    WHERE p.is_active = true
      AND has_registrant_name(r.real_name)
      AND (${only}::uuid IS NULL OR p.id = ${only}::uuid)
    ORDER BY p.name, r.real_name
  `;

  const changes = [];
  for (const r of rows) {
    const tierFee =
      r.fee_tier === 'premium'
        ? Number(r.fee_premium ?? 0)
        : Number(r.fee_basic ?? 0);

    const picked = Array.isArray(r.selected_options) ? r.selected_options : [];
    let optionsCost = 0;
    if (picked.length > 0) {
      // 죽은 옵션(고쳐 다시 만든 투어)은 세지 않는다 — 카드가 4명인데 표가
      // 2명이던 것과 같은 뿌리다.
      const [sum] = await sql`
        SELECT COALESCE(SUM(cost), 0)::numeric AS s
        FROM program_options
        WHERE program_id = ${r.program_id} AND is_active
          AND id = ANY(${picked})
      `;
      optionsCost = Number(sum?.s ?? 0);
    }

    const approvedDiscount =
      r.discount_status === 'approved' ? Number(r.discount_amount ?? 0) : 0;
    const next = Math.max(0, tierFee + optionsCost - approvedDiscount);
    const now = Number(r.total_cost ?? 0);
    if (next !== now) {
      changes.push({ ...r, now, next });
    }
  }

  console.log(`살펴본 등록 ${rows.length}건 · 바뀔 것 ${changes.length}건`);
  for (const c of changes) {
    console.log(
      `   ${c.program_name.slice(0, 18).padEnd(20)}` +
        `${(c.real_name ?? '').slice(0, 20).padEnd(22)}` +
        `${String(c.now).padStart(7)} → ${String(c.next).padStart(7)} ${c.currency ?? ''}`,
    );
  }

  if (!apply) {
    console.log('\n(미리보기입니다. 실제로 고치려면 --yes 를 주십시오.)');
    return;
  }
  for (const c of changes) {
    await sql`UPDATE registrations SET total_cost = ${c.next} WHERE id = ${c.id}`;
  }
  console.log(`\n✓ ${changes.length}건을 고쳤습니다.`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('다시 계산 오류:', err.message);
    process.exit(1);
  });
