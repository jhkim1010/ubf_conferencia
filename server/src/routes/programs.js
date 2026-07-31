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
            'photoUrls', po.photo_urls,
            'capacity', po.capacity,
            'signupDeadline', po.signup_deadline,
            'brochureUrl', po.brochure_url,
            'videoUrl', po.video_url,
            'signupCount', (
              SELECT COUNT(*) FROM registrations r
              WHERE r.program_id = p.id
                AND r.submitted = true
                AND po.id = ANY(r.selected_options)
            )
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
    programType, hostCountry,
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
        program_type, host_country
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
        ${type},
        ${hostCountry ?? null}
      )
      RETURNING id
    `;

    // 옵션 일괄 삽입
    if (Array.isArray(options) && options.length > 0) {
      await sql`
        INSERT INTO program_options (program_id, name, description, cost, start_date, end_date, contact_name, photo_urls, capacity, signup_deadline, brochure_url, video_url)
        SELECT
          ${program.id},
          o->>'name',
          o->>'description',
          (o->>'cost')::numeric,
          NULLIF(o->>'startDate', '')::date,
          NULLIF(o->>'endDate', '')::date,
          o->>'contactName',
          COALESCE((SELECT array_agg(v) FROM json_array_elements_text(o->'photoUrls') AS v), '{}'),
          NULLIF(o->>'capacity', '')::integer,
          NULLIF(o->>'signupDeadline', '')::timestamptz,
          NULLIF(o->>'brochureUrl', ''),
          NULLIF(o->>'videoUrl', '')
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
    programType, options, hostCountry,
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
        program_type     = ${type},
        host_country     = ${hostCountry ?? null}
      WHERE id = ${req.params.id}
    `;

    // 옵션 교체 (기존 비활성화 후 새로 삽입)
    if (Array.isArray(options)) {
      await sql`UPDATE program_options SET is_active = false WHERE program_id = ${req.params.id}`;
      if (options.length > 0) {
        await sql`
          INSERT INTO program_options (program_id, name, description, cost, start_date, end_date, contact_name, photo_urls, capacity, signup_deadline, brochure_url, video_url)
          SELECT
            ${req.params.id},
            o->>'name',
            o->>'description',
            (o->>'cost')::numeric,
            NULLIF(o->>'startDate', '')::date,
            NULLIF(o->>'endDate', '')::date,
            o->>'contactName',
            COALESCE((SELECT array_agg(v) FROM json_array_elements_text(o->'photoUrls') AS v), '{}'),
            NULLIF(o->>'capacity', '')::integer,
            NULLIF(o->>'signupDeadline', '')::timestamptz,
            NULLIF(o->>'brochureUrl', ''),
            NULLIF(o->>'videoUrl', '')
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

// ── 준비 현황 (A003) ──────────────────────────────────────────
// /stats 는 숫자만 준다. 준비하는 사람에게 필요한 것은 "지금 무엇이 막혀 있고
// 누구에게 연락해야 하는가"다. 준비 항목 + 국내/해외 진척 + 막힌 사람을
// 한 응답으로 묶는다(A003 D2 — 화면이 여러 엔드포인트를 조합하지 않게 한다).

// 준비 항목 상태. 화면은 색이 아니라 이 값으로 배지 문구를 고른다.
function readinessStatus(needed, available) {
  if (available === null || available === undefined) return 'idle';
  if (needed > available) return 'stop';
  if (available > 0 && needed > available * 0.8) return 'warn';
  return 'ok';
}

function daysBetween(from, to) {
  if (!from || !to) return null;
  return Math.floor((new Date(to) - new Date(from)) / 86400000);
}

router.get('/:id/readiness', requireAuth, requireLeader, async (req, res) => {
  const programId = req.params.id;
  try {
    const [program] = await sql`
      SELECT id, name, location, start_date, end_date, host_country,
             registration_deadline, capacity, base_fee
      FROM programs
      WHERE id = ${programId} AND leader_id = ${req.user.leaderId}
    `;
    if (!program) return res.status(403).json({ error: '권한 없음' });

    const host = program.host_country;

    // 국내/해외 판정은 registrations.country 를 쓴다. 등록 화면에서 직접 고른
    // 값이라 users.region 보다 정확하다.
    const [counts] = await sql`
      SELECT
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE r.country IS DISTINCT FROM ${host})::int AS overseas,
        COUNT(*) FILTER (
          WHERE r.country IS DISTINCT FROM ${host} AND r.arrival_flight IS NULL
        )::int AS flights_missing,
        COUNT(*) FILTER (
          WHERE r.food_requirements IS NOT NULL
            AND r.food_requirements <> ''
            AND r.food_requirements <> '없음'
        )::int AS meals_restricted,
        COUNT(*) FILTER (WHERE r.needs_pickup IS NOT FALSE)::int AS pickup_needed
      FROM registrations r
      WHERE r.program_id = ${programId}
    `;

    const [lodging] = await sql`
      SELECT COALESCE(SUM(capacity), 0)::int AS seats
      FROM rooms WHERE program_id = ${programId}
    `;
    const [transport] = await sql`
      SELECT COALESCE(SUM(capacity), 0)::int AS seats
      FROM transport_runs WHERE program_id = ${programId}
    `;
    const [payment] = await sql`
      SELECT
        COUNT(*) FILTER (WHERE pay.status = 'confirmed')::int AS confirmed,
        COUNT(*) FILTER (WHERE pay.status = 'pending')::int AS pending
      FROM payments pay
      JOIN registrations r ON r.id = pay.registration_id
      WHERE r.program_id = ${programId}
    `;

    // 단계 완료는 기존 컬럼의 채움 여부로 유추한다(A003 D3). 스텝별 완료
    // 플래그를 새로 저장하면 등록 플로우가 바뀔 때마다 동기화 부담이 생긴다.
    const cohortRows = await sql`
      SELECT
        (r.country IS NOT DISTINCT FROM ${host}) AS is_domestic,
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE r.real_name IS NOT NULL AND r.real_name <> '')::int AS personal,
        COUNT(*) FILTER (WHERE r.food_requirements IS NOT NULL)::int AS meals,
        COUNT(*) FILTER (WHERE r.arrival_flight IS NOT NULL)::int AS flight,
        COUNT(*) FILTER (WHERE ra.id IS NOT NULL)::int AS lodging,
        COUNT(*) FILTER (WHERE r.submitted)::int AS submitted,
        COUNT(DISTINCT r.country)::int AS countries
      FROM registrations r
      LEFT JOIN room_assignments ra ON ra.registration_id = r.id
      WHERE r.program_id = ${programId}
      GROUP BY 1
    `;

    const cohorts = cohortRows.map((c) => ({
      kind: c.is_domestic ? 'domestic' : 'overseas',
      country: c.is_domestic ? host : null,
      countries: c.is_domestic ? null : c.countries,
      total: c.total,
      steps: {
        personal: c.personal,
        meals: c.meals,
        // 개최국 참석자는 항공편 단계를 건너뛴다 — null 은 "해당 없음"이다
        flight: c.is_domestic ? null : c.flight,
        lodging: c.lodging,
        submitted: c.submitted,
      },
    }));

    // 앞 단계부터 보고 처음 비는 곳을 stuck_at 으로 준다.
    const blocked = await sql`
      SELECT
        r.id AS registration_id, r.real_name AS name, r.country, r.branch,
        (r.country IS NOT DISTINCT FROM ${host}) AS is_domestic,
        r.updated_at,
        CASE
          WHEN r.real_name IS NULL OR r.real_name = '' THEN 'personal'
          WHEN r.food_requirements IS NULL THEN 'meals'
          WHEN r.country IS DISTINCT FROM ${host} AND r.arrival_flight IS NULL THEN 'flight'
          WHEN ra.id IS NULL THEN 'lodging'
          ELSE 'payment'
        END AS stuck_at
      FROM registrations r
      LEFT JOIN room_assignments ra ON ra.registration_id = r.id
      WHERE r.program_id = ${programId} AND r.submitted = false
      ORDER BY r.updated_at ASC
      LIMIT 100
    `;

    const now = new Date();

    res.json({
      program: {
        id: program.id,
        name: program.name,
        location: program.location,
        start_date: program.start_date,
        end_date: program.end_date,
        host_country: host,
        registration_deadline: program.registration_deadline,
        capacity: program.capacity,
        base_fee: program.base_fee,
        // 마감일이 없으면 시작일 기준. 둘 다 없으면 null.
        d_day: daysBetween(now, program.registration_deadline ?? program.start_date),
      },
      readiness: {
        lodging: {
          status: readinessStatus(counts.total, lodging.seats),
          needed: counts.total,
          available: lodging.seats,
        },
        transport: {
          status: readinessStatus(counts.pickup_needed, transport.seats),
          needed: counts.pickup_needed,
          available: transport.seats,
        },
        flights: {
          status: counts.flights_missing === 0 ? 'ok' : 'warn',
          missing: counts.flights_missing,
          overseas_total: counts.overseas,
        },
        meals: { status: 'ok', restricted: counts.meals_restricted, total: counts.total },
        payment: {
          status: payment.pending > 0 ? 'warn' : 'ok',
          confirmed: payment.confirmed,
          pending: payment.pending,
          total: counts.total,
        },
      },
      cohorts,
      blocked: blocked.map((b) => ({
        registration_id: b.registration_id,
        name: b.name,
        country: b.country,
        branch: b.branch,
        kind: b.is_domestic ? 'domestic' : 'overseas',
        stuck_at: b.stuck_at,
        stalled_days: daysBetween(b.updated_at, now),
      })),
    });
  } catch (err) {
    console.error('준비 현황 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
