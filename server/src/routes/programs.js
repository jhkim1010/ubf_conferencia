import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireLeader } from '../middleware/auth.js';

const router = Router();

// GET /programs/:id - 단일 프로그램 + 옵션 조회 (참가자용)
router.get('/:id', requireAuth, async (req, res) => {
  try {
    const [program] = await sql`
      SELECT p.*,
        json_agg(
          json_build_object(
            'id', po.id,
            'name', po.name,
            'description', po.description,
            'cost', po.cost,
            'startDate', po.start_date,
            'endDate', po.end_date,
            'contactName', po.contact_name,
            'photoUrls', po.photo_urls
          ) ORDER BY po.name
        ) FILTER (WHERE po.id IS NOT NULL) AS program_options
      FROM programs p
      LEFT JOIN program_options po ON po.program_id = p.id AND po.is_active = true
      WHERE p.id = ${req.params.id} AND p.is_active = true
      GROUP BY p.id
    `;

    if (!program) {
      return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });
    }

    res.json(program);
  } catch (err) {
    console.error('프로그램 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /programs - 리더의 프로그램 목록
router.get('/', requireAuth, requireLeader, async (req, res) => {
  try {
    const programs = await sql`
      SELECT p.*,
        COUNT(r.id) AS registration_count
      FROM programs p
      LEFT JOIN registrations r ON r.program_id = p.id
      WHERE p.leader_id = ${req.user.leaderId}
      GROUP BY p.id
      ORDER BY p.created_at DESC
    `;

    res.json(programs);
  } catch (err) {
    console.error('프로그램 목록 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /programs - 새 프로그램 생성 (리더 전용)
router.post('/', requireAuth, requireLeader, async (req, res) => {
  const {
    name, location, startDate, endDate, enabledSections, options,
    nearestAirport, contact1Name, contact1Phone, contact2Name, contact2Phone,
    programType,
  } = req.body;

  if (!name || !location) {
    return res.status(400).json({ error: '프로그램 이름과 장소는 필수입니다' });
  }

  try {
    // 중복 체크: 같은 리더가 같은 이름+시작일 프로그램을 이미 만든 경우
    const [existing] = await sql`
      SELECT id FROM programs
      WHERE leader_id = ${req.user.leaderId}
        AND name = ${name}
        AND start_date = ${startDate ?? null}
        AND is_active = true
      LIMIT 1
    `;
    if (existing) {
      return res.status(409).json({
        error: '동일한 이름과 시작일의 프로그램이 이미 존재합니다',
        existingId: existing.id,
      });
    }

    const type = programType === 'local' ? 'local' : 'international';
    const sections = enabledSections ?? {
      personal_info: true,
      arrival_flight: type === 'international',
      departure_flight: type === 'international',
      food_requirements: true,
      special_programs: type === 'international',
      roommate: true,
    };

    // 프로그램 생성 (UUID는 DB에서 자동 생성)
    const [program] = await sql`
      INSERT INTO programs (
        name, location, leader_id, start_date, end_date, enabled_sections,
        nearest_airport, contact1_name, contact1_phone, contact2_name, contact2_phone,
        program_type
      )
      VALUES (
        ${name},
        ${location},
        ${req.user.leaderId},
        ${startDate ?? null},
        ${endDate ?? null},
        ${JSON.stringify(sections)},
        ${nearestAirport ?? null},
        ${contact1Name ?? null},
        ${contact1Phone ?? null},
        ${contact2Name ?? null},
        ${contact2Phone ?? null},
        ${type}
      )
      RETURNING id
    `;

    // 옵션 일괄 삽입
    if (Array.isArray(options) && options.length > 0) {
      await sql`
        INSERT INTO program_options (program_id, name, description, cost, start_date, end_date, contact_name, photo_urls)
        SELECT
          ${program.id},
          o->>'name',
          o->>'description',
          (o->>'cost')::numeric,
          NULLIF(o->>'startDate', '')::date,
          NULLIF(o->>'endDate', '')::date,
          o->>'contactName',
          COALESCE((SELECT array_agg(v) FROM json_array_elements_text(o->'photoUrls') AS v), '{}')
        FROM json_array_elements(${JSON.stringify(options)}::json) AS o
      `;
    }

    console.log(`[PROGRAM] 생성 | programId=${program.id} name="${name}" location="${location}" leaderId=${req.user.leaderId} email=${req.user.email}`);
    res.status(201).json({ id: program.id });
  } catch (err) {
    console.error('프로그램 생성 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /programs/:id - 프로그램 설정 수정 (소유 리더만)
router.patch('/:id', requireAuth, requireLeader, async (req, res) => {
  const {
    name, location, startDate, endDate, enabledSections,
    nearestAirport, contact1Name, contact1Phone, contact2Name, contact2Phone,
    programType, options,
  } = req.body;

  try {
    // 소유권 + 시작일 확인
    const [program] = await sql`
      SELECT id, program_type, start_date FROM programs
      WHERE id = ${req.params.id} AND leader_id = ${req.user.leaderId} AND is_active = true
    `;
    if (!program) return res.status(403).json({ error: '권한 없음' });

    // 국제 수양회는 시작일 이후 투어 옵션 수정 불가
    if (
      program.program_type === 'international' &&
      program.start_date &&
      new Date(program.start_date) <= new Date() &&
      Array.isArray(options)
    ) {
      return res.status(423).json({ error: '수양회가 시작된 후에는 투어 옵션을 수정할 수 없습니다' });
    }

    const type = programType === 'local' ? 'local' : 'international';

    await sql`
      UPDATE programs SET
        name             = COALESCE(${name ?? null}, name),
        location         = COALESCE(${location ?? null}, location),
        start_date       = ${startDate ?? null},
        end_date         = ${endDate ?? null},
        enabled_sections = COALESCE(${enabledSections ? JSON.stringify(enabledSections) : null}::jsonb, enabled_sections),
        nearest_airport  = ${nearestAirport ?? null},
        contact1_name    = ${contact1Name ?? null},
        contact1_phone   = ${contact1Phone ?? null},
        contact2_name    = ${contact2Name ?? null},
        contact2_phone   = ${contact2Phone ?? null},
        program_type     = ${type}
      WHERE id = ${req.params.id}
    `;

    // 옵션 교체 (기존 비활성화 후 새로 삽입)
    if (Array.isArray(options)) {
      await sql`UPDATE program_options SET is_active = false WHERE program_id = ${req.params.id}`;
      if (options.length > 0) {
        await sql`
          INSERT INTO program_options (program_id, name, description, cost, start_date, end_date, contact_name, photo_urls)
          SELECT
            ${req.params.id},
            o->>'name',
            o->>'description',
            (o->>'cost')::numeric,
            NULLIF(o->>'startDate', '')::date,
            NULLIF(o->>'endDate', '')::date,
            o->>'contactName',
            COALESCE((SELECT array_agg(v) FROM json_array_elements_text(o->'photoUrls') AS v), '{}')
          FROM json_array_elements(${JSON.stringify(options)}::json) AS o
        `;
      }
    }

    console.log(`[PROGRAM] 수정 | programId=${req.params.id} leaderId=${req.user.leaderId} email=${req.user.email}`);
    res.json({ ok: true });
  } catch (err) {
    console.error('프로그램 수정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /programs/:id/stats - 대시보드 통계 (리더 전용)
router.get('/:id/stats', requireAuth, requireLeader, async (req, res) => {
  try {
    // 리더 소유권 확인
    const [program] = await sql`
      SELECT id FROM programs WHERE id = ${req.params.id} AND leader_id = ${req.user.leaderId}
    `;
    if (!program) return res.status(403).json({ error: '권한 없음' });

    const [stats] = await sql`
      SELECT
        p.id AS program_id,
        p.name AS program_name,
        COUNT(r.id) AS total_registrations,
        COUNT(r.id) FILTER (WHERE r.submitted = true) AS submitted_count,
        COUNT(r.id) FILTER (WHERE r.food_requirements IS NOT NULL AND r.food_requirements != '' AND r.food_requirements != '없음') AS food_restriction_count,
        COUNT(r.id) FILTER (WHERE r.arrival_flight IS NOT NULL) AS arrival_flight_count,
        COUNT(r.id) FILTER (WHERE r.departure_flight IS NOT NULL) AS departure_flight_count,
        COUNT(pay.id) FILTER (WHERE pay.status = 'pending') AS pending_payment_count,
        COUNT(pay.id) FILTER (WHERE pay.status = 'confirmed') AS confirmed_payment_count
      FROM programs p
      LEFT JOIN registrations r ON r.program_id = p.id
      LEFT JOIN payments pay ON pay.registration_id = r.id
      WHERE p.id = ${req.params.id}
      GROUP BY p.id, p.name
    `;

    res.json(stats ?? {});
  } catch (err) {
    console.error('통계 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /programs/:id/registrations - 참가자 전체 목록 (리더 전용)
router.get('/:id/registrations', requireAuth, requireLeader, async (req, res) => {
  try {
    const [program] = await sql`
      SELECT id FROM programs WHERE id = ${req.params.id} AND leader_id = ${req.user.leaderId}
    `;
    if (!program) return res.status(403).json({ error: '권한 없음' });

    const registrations = await sql`
      SELECT r.*,
        json_build_object(
          'status', pay.status,
          'amount', pay.amount,
          'receipt_image_url', pay.receipt_image_url
        ) AS payment
      FROM registrations r
      LEFT JOIN payments pay ON pay.registration_id = r.id
      WHERE r.program_id = ${req.params.id}
      ORDER BY r.created_at ASC
    `;

    res.json(registrations);
  } catch (err) {
    console.error('참가자 목록 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
