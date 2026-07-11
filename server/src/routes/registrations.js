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
    totalCost, fcmToken,
  } = req.body;

  try {
    const [program] = await sql`
      SELECT id, name FROM programs WHERE id = ${req.params.programId} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

    // 기존 등록 여부 확인 (수정인지 신규인지 구분)
    const [existing] = await sql`
      SELECT id FROM registrations
      WHERE program_id = ${req.params.programId} AND user_id = ${req.user.userId}
    `;
    const isUpdate = !!existing;

    const [registration] = await sql`
      INSERT INTO registrations (
        program_id, user_id, country, branch, real_name, bible_name,
        gender, age, arrival_flight, departure_flight,
        food_requirements, medical_conditions, skips_breakfast,
        selected_options, roommate_preference,
        volunteer_resources, volunteer_note,
        total_cost, fcm_token
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
        ${totalCost ?? 0},
        ${fcmToken ?? null}
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
