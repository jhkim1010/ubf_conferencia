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
//   hotel_before_self(075) · hotel_after_self(074)
//
// 박수는 **다시 유도하지 않는다.** 라우트가 비행 일정에서 낸 결과가 이미
// before/after 로 저장돼 있다. 여기서 또 유도하면 두 벌이 되고, 두 벌은
// 언젠가 갈라진다 — 그때 참가자는 화면마다 다른 숫자를 보게 된다.
//
// 저장 시점의 권위는 그대로 등록 라우트에 있다. 이 함수는 **등록 밖에서
// 낼 돈이 달라졌을 때** 따라 맞추는 쪽이다.

import { sql } from '../db.js';
import { registrationTotal } from './registration_total.js';
import { chargeableNights } from './hotel_nights.js';
import { bedsNeeded, toursCostOf } from './companion_role.js';
import { loadCoverMap, registrationsNamed } from './companion_cover.js';

/// 등록 [registrationId] 의 total_cost 를 다시 세어 저장한다.
///
/// 바뀐 금액을 돌려준다. 등록이 없으면 null 이다.
export async function recountRegistrationTotal(registrationId) {
  if (!registrationId) return null;

  const [reg] = await sql`
    SELECT r.id, r.program_id, r.fee_tier, r.selected_options,
           r.discount_status, r.discount_amount,
           r.hotel_option_key, r.hotel_nights_before, r.hotel_nights_after,
           r.hotel_before_self, r.hotel_after_self,
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
  const pickedTours = picked.length
    ? await sql`
        SELECT id, cost
          FROM program_options
         WHERE program_id = ${reg.program_id}
           AND id = ANY(${picked})
           AND is_active = true`
    : [];

  const companions = await sql`
    SELECT age, registers_separately, occupies_bed, fee_share, tour_ids
      FROM companions WHERE registration_id = ${reg.id}
  `;

  // 스스로 해결하는 쪽 박수는 빼고 센다(074·075).
  // 등록 라우트와 같은 함수를 쓴다 — 두 벌이면 언젠가 갈라진다.
  const nights = chargeableNights({
    before: reg.hotel_nights_before,
    after: reg.hotel_nights_after,
    beforeSelf: reg.hotel_before_self,
    afterSelf: reg.hotel_after_self,
  });

  const { total: counted } = registrationTotal({
    tier: reg.fee_tier,
    feeBasic: reg.fee_basic,
    feePremium: reg.fee_premium,
    // 투어마다 한 사람 값 × (본인 + 그 투어에 가는 동반자)(080).
    optionsCost: toursCostOf({ options: pickedTours, companions }),
    hotelOptions: reg.hotel_options,
    hotelKey: reg.hotel_option_key,
    hotelNights: nights,
    hotelPeople: 1 + bedsNeeded(companions),
    approvedDiscount:
      reg.discount_status === 'approved' ? Number(reg.discount_amount ?? 0) : 0,
    companions,
    program: reg,
  });

  // 대표자가 함께 등록한 동반자가 또 등록한 것이면 낼 돈은 0 이다 —
  // 대표자 등록에서 동반자 몫으로 이미 셌다(companion_cover.js).
  const total = (await loadCoverMap(reg.program_id)).has(reg.id) ? 0 : counted;

  // 같으면 쓰지 않는다. updated_at 이 있는 표라면 뜻 없는 변경이 남는다.
  if (Number(reg.total_cost ?? 0) !== total) {
    await sql`UPDATE registrations SET total_cost = ${total} WHERE id = ${reg.id}`;
  }
  return total;
}

/// 동반자 [names] 와 이름이 같은 **다른 등록들**의 낼 돈을 다시 센다.
///
/// 대표자가 동반자를 더하거나 지우거나 "따로 등록" 으로 바꾸면, 그 사람이
/// 자기 계정으로 한 등록이 대표자에게 덮이거나(0 원) 풀린다(제 몫을 냄).
/// 그 등록은 손대지 않았으므로 여기서 따라 맞춘다. 고친 뒤의 이름뿐 아니라
/// **고치기 전의 이름도** 넘겨야 한다 — 지운 동반자의 등록이 풀려야 한다.
export async function recountNamesakes(registrationId, names) {
  const [reg] = await sql`SELECT program_id FROM registrations WHERE id = ${registrationId}`;
  if (!reg) return;
  const ids = await registrationsNamed(reg.program_id, names, registrationId);
  for (const id of ids) await recountRegistrationTotal(id);
}

/// 등록 [registrationId] 에 지금 적혀 있는 동반자 이름들.
export async function companionNamesOf(registrationId) {
  const rows = await sql`
    SELECT real_name FROM companions WHERE registration_id = ${registrationId}
  `;
  return rows.map((r) => r.real_name);
}
