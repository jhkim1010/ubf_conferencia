// 저장된 등록 하나의 낼 돈을 다시 센다 (073)
//
// 등록 라우트는 **요청 본문**에서 낼 돈을 낸다. 그런데 동반자는 등록을
// 마친 뒤에 따로 저장된다(PUT /companions). 그래서 아이를 추가해도 낼 돈이
// 그대로였다 — 어린이 참가비(073)뿐 아니라 침대가 느는 숙박비(069)도
// 같은 구멍으로 빠져 있었다.
//
// 여기서는 **이미 저장된 값**으로만 다시 센다. 라우트가 셀 때 쓰는 것들이
// 전부 등록 행에 남아 있기 때문에 가능하다:
//
//   fee_tier · selected_options · discount_status · discount_amount
//   hotel_option_key · hotel_nights_before · hotel_nights_after
//
// 박수는 **다시 유도하지 않는다.** 라우트가 비행 일정에서 낸 결과가 이미
// before/after 로 저장돼 있다. 여기서 또 유도하면 두 벌이 되고, 두 벌은
// 언젠가 갈라진다 — 그때 참가자는 화면마다 다른 숫자를 보게 된다.
//
// 저장 시점의 권위는 그대로 등록 라우트에 있다. 이 함수는 **등록 밖에서
// 낼 돈이 달라졌을 때** 따라 맞추는 쪽이다.

import { sql } from '../db.js';
import { registrationTotal } from './registration_total.js';
import { bedsNeeded } from './companion_role.js';

/// 등록 [registrationId] 의 total_cost 를 다시 세어 저장한다.
///
/// 바뀐 금액을 돌려준다. 등록이 없으면 null 이다.
export async function recountRegistrationTotal(registrationId) {
  if (!registrationId) return null;

  const [reg] = await sql`
    SELECT r.id, r.program_id, r.fee_tier, r.selected_options,
           r.discount_status, r.discount_amount,
           r.hotel_option_key, r.hotel_nights_before, r.hotel_nights_after,
           r.total_cost,
           p.fee_basic, p.fee_premium, p.hotel_options,
           p.fee_child_age_min, p.fee_child_age_max, p.fee_child_rate
      FROM registrations r
      JOIN programs p ON p.id = r.program_id
     WHERE r.id = ${registrationId}
  `;
  if (!reg) return null;

  // 죽은 옵션(고쳐 다시 만든 투어)은 세지 않는다 — 라우트와 같은 규칙이다.
  const picked = Array.isArray(reg.selected_options) ? reg.selected_options : [];
  const [sum] = picked.length
    ? await sql`
        SELECT COALESCE(SUM(cost), 0)::numeric AS s
          FROM program_options
         WHERE program_id = ${reg.program_id}
           AND id = ANY(${picked})
           AND is_active = true`
    : [{ s: 0 }];

  const companions = await sql`
    SELECT age, registers_separately, occupies_bed, fee_share
      FROM companions WHERE registration_id = ${reg.id}
  `;

  const nights =
    Number(reg.hotel_nights_before ?? 0) + Number(reg.hotel_nights_after ?? 0);

  const { total } = registrationTotal({
    tier: reg.fee_tier,
    feeBasic: reg.fee_basic,
    feePremium: reg.fee_premium,
    optionsCost: Number(sum?.s ?? 0),
    hotelOptions: reg.hotel_options,
    hotelKey: reg.hotel_option_key,
    hotelNights: nights,
    hotelPeople: 1 + bedsNeeded(companions),
    approvedDiscount:
      reg.discount_status === 'approved' ? Number(reg.discount_amount ?? 0) : 0,
    companions,
    program: reg,
  });

  // 같으면 쓰지 않는다. updated_at 이 있는 표라면 뜻 없는 변경이 남는다.
  if (Number(reg.total_cost ?? 0) !== total) {
    await sql`UPDATE registrations SET total_cost = ${total} WHERE id = ${reg.id}`;
  }
  return total;
}
