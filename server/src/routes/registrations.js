import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { notifyProgramAdmins } from '../services/telegram.js';

const router = Router();

// GET /registrations/:programId/me - 내 등록 정보 조회
router.get('/:programId/me', requireAuth, async (req, res) => {
  try {
    const [registration] = await sql`
      SELECT r.*,
        json_build_object(
          'status', pay.status,
          'amount', pay.amount,
          'receipt_image_url', pay.receipt_image_url
        ) AS payment
      FROM registrations r
      LEFT JOIN payments pay ON pay.registration_id = r.id
      WHERE r.program_id = ${req.params.programId}
        AND r.user_id = ${req.user.userId}
    `;

    res.json(registration ?? null);
  } catch (err) {
    console.error('등록 정보 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PUT /registrations/:programId/me - 등록 정보 저장 (upsert)
router.put('/:programId/me', requireAuth, async (req, res) => {
  const {
    country, branch, realName, bibleName, gender, age,
    arrivalFlight, departureFlight,
    foodRequirements, medicalConditions, skipsBreakfast,
    selectedOptions, roommatePreference,
    volunteerResources, volunteerNote,
    fcmToken,
    feeTier, discountRequested, discountOptionKey, discountReason,
  } = req.body;

  try {
    const [program] = await sql`
      SELECT id, name, fee_basic, fee_premium, discount_options, host_country
      FROM programs WHERE id = ${req.params.programId} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

    // 등록자가 고른 등급은 그 수양회가 실제로 제공하는 것이어야 한다.
    // 금액이 NULL 인 등급은 제공하지 않는다는 뜻이다(018 참조).
    let tier = feeTier === 'basic' || feeTier === 'premium' ? feeTier : null;
    if (tier === 'basic' && program.fee_basic === null) tier = null;
    if (tier === 'premium' && program.fee_premium === null) tier = null;

    // 할인 신청. 담당자 전용 필드(status/amount/note)는 본문에서 받지 않는다.
    // 등록자가 스스로 승인 상태나 금액을 정할 수 있으면 신청 자체가 무의미해진다.
    // 할인은 **개최국에서 오는 사람만** 신청할 수 있다. 할인 항목은 "1일만
    // 참석" 처럼 현지에서 오가는 사람을 전제로 만들어지기 때문이다.
    //
    // 판정은 registrations.country 와 programs.host_country 를 맞춰 본다 —
    // 준비 현황·봉사 자격이 이미 쓰는 기준이라 여기서만 다르게 볼 이유가 없다.
    // 지역 수양회는 host_country 가 없다. 그때는 참가자가 모두 같은 나라
    // 사람이므로 제한하지 않는다.
    const host = program.host_country;
    const isDomestic = !host || (!!country && country === host);

    const offered = Array.isArray(program.discount_options) ? program.discount_options : [];
    const picked = discountRequested
      ? offered.find((o) => o.key === discountOptionKey) ?? null
      : null;

    // 조용히 무시하지 않고 막는다. 무시하면 등록자는 신청한 줄 알고 기다리다가
    // 아무 답도 못 받는다.
    if (picked && !isDomestic) {
      return res.status(422).json({
        error: '할인은 개최국에서 참석하는 분만 신청할 수 있습니다',
        hostCountry: host,
      });
    }

    const wantsDiscount = !!picked;

    // 기존 등록 여부 확인 (수정인지 신규인지 구분)
    const [existing] = await sql`
      SELECT id, discount_option_key, discount_status, discount_amount, discount_note
      FROM registrations
      WHERE program_id = ${req.params.programId} AND user_id = ${req.user.userId}
    `;
    const isUpdate = !!existing;

    // 이미 담당자가 판단한 건은 그대로 둔다. 단 고른 항목이 바뀌면
    // 판단의 전제가 달라진 것이므로 다시 '신청' 상태로 되돌린다.
    let discountStatus = null;
    let discountAmount = null;
    let discountNote = null;
    if (wantsDiscount) {
      const sameChoice = existing?.discount_option_key === picked.key;
      if (sameChoice && existing?.discount_status) {
        discountStatus = existing.discount_status;
        discountAmount = existing.discount_amount;
        discountNote = existing.discount_note;
      } else {
        // 판단의 전제가 바뀌었으므로 확정 금액과 메모도 함께 무효화한다.
        discountStatus = 'requested';
      }
    }

    // 합계는 **서버가 계산한다.** 클라이언트가 보낸 totalCost 는 쓰지 않는다.
    //
    // 두 가지 이유다. 첫째, 앱이 보내던 값은 투어 옵션만 더하고 참가비 등급을
    // 빼먹어서 요약 화면은 U$320 인데 DB 에는 0 이 저장됐다 — 관리자 대시보드와
    // CSV 가 0 으로 나갔다. 둘째, 낼 금액을 클라이언트가 정하게 두면 안 된다.
    //
    // 승인된 할인만 뺀다. 신청 중인 금액을 미리 빼면 아직 결정되지 않은 감액이
    // 확정된 것처럼 장부에 남는다.
    const tierFee =
      tier === 'basic' ? Number(program.fee_basic ?? 0)
      : tier === 'premium' ? Number(program.fee_premium ?? 0)
      : 0;

    const picked_ids = Array.isArray(selectedOptions) ? selectedOptions : [];
    const optionRows = picked_ids.length
      ? await sql`
          SELECT COALESCE(SUM(cost), 0)::numeric AS sum
            FROM program_options
           WHERE program_id = ${req.params.programId}
             AND id = ANY(${picked_ids})`
      : [{ sum: 0 }];
    const optionsCost = Number(optionRows[0]?.sum ?? 0);

    const approvedDiscount =
      discountStatus === 'approved' ? Number(discountAmount ?? 0) : 0;

    const computedTotal = Math.max(0, tierFee + optionsCost - approvedDiscount);

    const [registration] = await sql`
      INSERT INTO registrations (
        program_id, user_id, country, branch, real_name, bible_name,
        gender, age, arrival_flight, departure_flight,
        food_requirements, medical_conditions, skips_breakfast,
        selected_options, roommate_preference,
        volunteer_resources, volunteer_note,
        total_cost, fcm_token,
        fee_tier, discount_requested, discount_option_key,
        discount_option_label, discount_option_labels, discount_reason, discount_status,
        discount_amount, discount_note
      )
      VALUES (
        ${req.params.programId}, ${req.user.userId},
        ${country ?? null}, ${branch ?? null},
        ${realName ?? null}, ${bibleName ?? null},
        ${gender ?? null}, ${age ?? null},
        ${arrivalFlight ? JSON.stringify(arrivalFlight) : null},
        ${departureFlight ? JSON.stringify(departureFlight) : null},
        ${foodRequirements ?? null},
        ${medicalConditions ?? null},
        ${skipsBreakfast ?? false},
        ${selectedOptions ?? []},
        ${roommatePreference ?? null},
        ${volunteerResources ?? []},
        ${volunteerNote ?? null},
        ${computedTotal},
        ${fcmToken ?? null},
        ${tier},
        ${wantsDiscount},
        ${picked?.key ?? null},
        ${picked?.label ?? null},
        ${picked ? JSON.stringify(picked.labels ?? {}) : null},
        ${wantsDiscount ? (discountReason ?? null) : null},
        ${discountStatus},
        ${discountAmount},
        ${discountNote}
      )
      ON CONFLICT (program_id, user_id)
      DO UPDATE SET
        country = EXCLUDED.country,
        branch = EXCLUDED.branch,
        real_name = EXCLUDED.real_name,
        bible_name = EXCLUDED.bible_name,
        gender = EXCLUDED.gender,
        age = EXCLUDED.age,
        arrival_flight = EXCLUDED.arrival_flight,
        departure_flight = EXCLUDED.departure_flight,
        food_requirements = EXCLUDED.food_requirements,
        medical_conditions = EXCLUDED.medical_conditions,
        skips_breakfast = EXCLUDED.skips_breakfast,
        selected_options = EXCLUDED.selected_options,
        roommate_preference = EXCLUDED.roommate_preference,
        volunteer_resources = EXCLUDED.volunteer_resources,
        volunteer_note = EXCLUDED.volunteer_note,
        total_cost = EXCLUDED.total_cost,
        fcm_token = EXCLUDED.fcm_token,
        fee_tier = EXCLUDED.fee_tier,
        discount_requested = EXCLUDED.discount_requested,
        discount_option_key = EXCLUDED.discount_option_key,
        discount_option_label = EXCLUDED.discount_option_label,
        discount_option_labels = EXCLUDED.discount_option_labels,
        discount_reason = EXCLUDED.discount_reason,
        discount_status = EXCLUDED.discount_status,
        discount_amount = EXCLUDED.discount_amount,
        discount_note = EXCLUDED.discount_note,
        updated_at = NOW()
      RETURNING id
    `;

    // 수정(재저장)인 경우 프로그램 관리자에게 Telegram 알림 전송 (비동기, 응답 지연 없음)
    if (isUpdate) {
      const name = realName ?? req.user.name ?? '참가자';
      const msg =
        `✏️ <b>[${program.name}] 등록 정보 수정</b>\n\n` +
        `👤 ${name}` +
        (country ? ` (${country}${branch ? ' / ' + branch : ''})` : '') +
        '\n이 등록 내용을 수정했습니다.';

      notifyProgramAdmins(req.params.programId, msg).catch(err =>
        console.error('관리자 알림 전송 오류:', err.message)
      );
    }

    res.json({ id: registration.id });
  } catch (err) {
    console.error('등록 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /registrations/:programId/me/submit - 최종 제출
router.post('/:programId/me/submit', requireAuth, async (req, res) => {
  try {
    // 이 등록이 선택한 투어 옵션의 정원·마감 검증 (F6 선착순)
    const [me] = await sql`
      SELECT id, selected_options FROM registrations
      WHERE program_id = ${req.params.programId} AND user_id = ${req.user.userId}
    `;
    if (!me) return res.status(404).json({ error: '등록 정보가 없습니다' });

    const selected = me.selected_options ?? [];
    if (selected.length > 0) {
      // 선택한 옵션 중 마감·정원 제약이 있는 것들 조회
      const constrained = await sql`
        SELECT po.id, po.name, po.capacity, po.signup_deadline,
          (SELECT COUNT(*) FROM registrations r
           WHERE r.program_id = ${req.params.programId}
             AND r.submitted = true
             AND r.id <> ${me.id}
             AND po.id = ANY(r.selected_options)) AS signup_count
        FROM program_options po
        WHERE po.program_id = ${req.params.programId}
          AND po.id = ANY(${selected})
          AND (po.capacity IS NOT NULL OR po.signup_deadline IS NOT NULL)
      `;
      for (const o of constrained) {
        if (o.signup_deadline && new Date(o.signup_deadline) < new Date()) {
          return res.status(422).json({
            code: 'TOUR_CLOSED', optionId: o.id, optionName: o.name,
            error: `"${o.name}" 투어는 신청이 마감되었습니다`,
          });
        }
        if (o.capacity != null && Number(o.signup_count) >= o.capacity) {
          return res.status(422).json({
            code: 'TOUR_FULL', optionId: o.id, optionName: o.name,
            error: `"${o.name}" 투어는 정원이 마감되었습니다`,
          });
        }
      }
    }

    const result = await sql`
      UPDATE registrations
      SET submitted = true, updated_at = NOW()
      WHERE program_id = ${req.params.programId}
        AND user_id = ${req.user.userId}
      RETURNING id, real_name
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: '등록 정보가 없습니다' });
    }

    // 최종 제출 시에도 관리자 알림
    const [program] = await sql`SELECT name FROM programs WHERE id = ${req.params.programId}`;
    const name = result[0].real_name ?? req.user.name ?? '참가자';
    const msg =
      `🎉 <b>[${program?.name ?? ''}] 최종 등록 제출</b>\n\n` +
      `👤 ${name} 이(가) 등록을 최종 제출했습니다.`;

    notifyProgramAdmins(req.params.programId, msg).catch(err =>
      console.error('제출 알림 전송 오류:', err.message)
    );

    res.json({ success: true });
  } catch (err) {
    console.error('제출 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
