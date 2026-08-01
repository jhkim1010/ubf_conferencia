import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireLeader } from '../middleware/auth.js';

const router = Router();

// 참가비 금액 정리. 빈 문자열/잘못된 값은 NULL(= 그 등급 없음)로 본다.
// 음수는 DB 제약이 막지만 여기서 먼저 걸러 500 대신 400 을 돌려준다.
function parseFee(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0) return NaN; // 호출부에서 400 처리
  return n;
}

// 통화 코드 정리. ISO 4217 대문자 세 글자만 받는다.
//
// 표시 기호가 아니라 코드를 저장한다. 기호를 저장하면 국가 표시명을 저장했다가
// 겪은 문제(019)를 그대로 반복하게 된다 — 같은 통화가 표기마다 달라진다.
function normalizeCurrency(v) {
  if (v === null || v === undefined || v === '') return null; // 안 보냈으면 유지
  const c = String(v).trim().toUpperCase();
  return /^[A-Z]{3}$/.test(c) ? c : NaN; // 호출부에서 400 처리
}

// 이 프로그램이 실제로 쓸 통화.
//
// **국제 수양회는 항상 USD 다.** 여러 나라에서 오는 참가자가 한 화면에서
// 서로 다른 통화를 보면 자기가 얼마를 내는지 비교할 수 없다. 지역 수양회는
// 참가자가 모두 같은 나라 사람이므로 그 나라 통화를 쓰는 편이 낫다.
//
// 클라이언트가 국제 수양회에 다른 통화를 보내와도 여기서 USD 로 돌린다 —
// 화면에서 막는 것만으로는 예전 앱이나 직접 호출을 막지 못한다.
function currencyFor(type, requested, current) {
  if (type === 'international') return 'USD';
  return requested ?? current ?? 'USD';
}


// 소수 인원 칸을 어떻게 할지(025). 관리자가 미리 정해 둔다 — 자동으로
// 처리하고 말면 왜 그렇게 배정됐는지 아무도 모른다.
function normalizeCohortPolicy(v) {
  if (v === null || v === undefined || v === '') return null; // 안 보냈으면 유지
  return ['absorb', 'merge', 'keep'].includes(v) ? v : NaN;   // 호출부에서 400
}

function normalizeMinTeamSize(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isInteger(n) && n >= 1 && n <= 50 ? n : NaN;
}

// 할인 항목 정리. 관리자가 "1일 참석 / 2일 참석 …" 처럼 정의한다.
// key 는 등록 레코드가 참조하므로 한 번 정해지면 바뀌면 안 된다.
// 클라이언트가 준 key 를 그대로 쓰고, 없을 때만 위치 기반으로 채운다.
function normalizeDiscountOptions(raw) {
  if (!Array.isArray(raw)) return null; // 안 보냈으면 건드리지 않는다
  const seen = new Set();
  const out = [];
  raw.forEach((o, i) => {
    // 문구는 언어별로 받는다. 한 줄만 적으면 다른 언어 사용자는 읽지 못한다.
    // label 은 기본값이자 번역이 없을 때의 대체값이다.
    const labels = {};
    for (const lang of ['ko', 'en', 'es']) {
      const v = String(o?.labels?.[lang] ?? '').trim();
      if (v) labels[lang] = v;
    }
    // 예전 형태({label}) 도 그대로 받는다. 이미 저장된 항목이 있다.
    const label = String(o?.label ?? '').trim() || labels.en || labels.ko || labels.es || '';
    if (!label) return; // 어떤 언어로도 문구가 없으면 화면에 보여줄 것이 없다

    let key = String(o?.key ?? '').trim() || `d${i + 1}`;
    while (seen.has(key)) key = `${key}_`; // key 중복은 등록 참조를 망친다
    seen.add(key);
    const amount = parseFee(o?.amount);
    out.push({
      key,
      label,
      labels,
      amount: Number.isNaN(amount) ? null : amount,
    });
  });
  return out;
}

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
      -- is_active 를 빠뜨리면 삭제한 수양회가 목록에 그대로 남는다.
      -- 단일 조회(GET /programs/:id)는 처음부터 이 조건을 보고 있었다.
      WHERE p.leader_id = ${req.user.leaderId} AND p.is_active = true
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
    feeBasic, feePremium, feeBasicDesc, feePremiumDesc, discountOptions,
    currency, smallCohortPolicy, minTeamSize,
  } = req.body;

  if (!name || !location) {
    return res.status(400).json({ error: '프로그램 이름과 장소는 필수입니다' });
  }

  const basic = parseFee(feeBasic);
  const premium = parseFee(feePremium);
  if (Number.isNaN(basic) || Number.isNaN(premium)) {
    return res.status(400).json({ error: '참가비는 0 이상의 숫자여야 합니다' });
  }
  const discounts = normalizeDiscountOptions(discountOptions) ?? [];

  const cur = normalizeCurrency(currency);
  if (Number.isNaN(cur)) {
    return res.status(400).json({ error: '통화는 ISO 4217 코드(대문자 세 글자)여야 합니다' });
  }

  const cohortPolicy = normalizeCohortPolicy(smallCohortPolicy);
  const teamMin = normalizeMinTeamSize(minTeamSize);
  if (Number.isNaN(cohortPolicy) || Number.isNaN(teamMin)) {
    return res.status(400).json({ error: '소수 인원 방침이 올바르지 않습니다' });
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
        program_type, host_country,
        fee_basic, fee_premium, fee_basic_desc, fee_premium_desc, discount_options,
        currency, small_cohort_policy, min_team_size
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
        ${hostCountry ?? null},
        ${basic},
        ${premium},
        ${feeBasicDesc ?? null},
        ${feePremiumDesc ?? null},
        ${JSON.stringify(discounts)},
        ${currencyFor(type, cur, null)},
        ${cohortPolicy ?? 'keep'},
        ${teamMin ?? 5}
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
    feeBasic, feePremium, feeBasicDesc, feePremiumDesc, discountOptions,
    currency,
  } = req.body;

  const patchCurrency = normalizeCurrency(currency);
  if (Number.isNaN(patchCurrency)) {
    return res.status(400).json({ error: '통화는 ISO 4217 코드(대문자 세 글자)여야 합니다' });
  }

  const patchPolicy  = normalizeCohortPolicy(req.body.smallCohortPolicy);
  const patchTeamMin = normalizeMinTeamSize(req.body.minTeamSize);
  if (Number.isNaN(patchPolicy) || Number.isNaN(patchTeamMin)) {
    return res.status(400).json({ error: '소수 인원 방침이 올바르지 않습니다' });
  }

  const basic = parseFee(feeBasic);
  const premium = parseFee(feePremium);
  if (Number.isNaN(basic) || Number.isNaN(premium)) {
    return res.status(400).json({ error: '참가비는 0 이상의 숫자여야 합니다' });
  }
  const discounts = normalizeDiscountOptions(discountOptions);

  // 본문에 없는 키는 건드리지 않는다. 참가비만 고치려는 호출이 할인 항목을
  // 지워버리면 안 된다. (기존 필드들은 덮어쓰기 방식이라 이 규칙이 없다.)
  const has = (k) => Object.prototype.hasOwnProperty.call(req.body, k);

  try {
    // 소유권 + 시작일 확인
    const [program] = await sql`
      SELECT id, program_type, start_date, currency,
             small_cohort_policy, min_team_size,
             fee_basic, fee_premium, fee_basic_desc, fee_premium_desc, discount_options
      FROM programs
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
        host_country     = ${hostCountry ?? null},
        fee_basic        = ${has('feeBasic') ? basic : program.fee_basic},
        fee_premium      = ${has('feePremium') ? premium : program.fee_premium},
        fee_basic_desc   = ${has('feeBasicDesc') ? (feeBasicDesc ?? null) : program.fee_basic_desc},
        fee_premium_desc = ${has('feePremiumDesc') ? (feePremiumDesc ?? null) : program.fee_premium_desc},
        discount_options = ${JSON.stringify(discounts ?? program.discount_options ?? [])}::jsonb,
        currency         = ${currencyFor(type, patchCurrency, program.currency)},
        small_cohort_policy = ${patchPolicy ?? program.small_cohort_policy ?? 'keep'},
        min_team_size       = ${patchTeamMin ?? program.min_team_size ?? 5}
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

// DELETE /programs/:id - 수양회 삭제 (소유 리더만)
//
// **행을 지우지 않고 is_active=false 로 둔다.** 등록·배정·배차·결제가 이 행을
// 참조하고 있어 실제로 지우면 그 기록이 통째로 사라진다. 잘못 눌렀을 때
// 되돌릴 방법도 없어진다. 조회 경로는 이미 전부 is_active 를 보고 있다.
//
// 등록자가 있으면 확인 문구(수양회 이름)를 요구한다. 확인 없이 지울 수 있으면
// 손이 미끄러진 한 번으로 수백 명의 등록이 화면에서 사라진다.
router.delete('/:id', requireAuth, requireLeader, async (req, res) => {
  try {
    const [program] = await sql`
      SELECT id, name FROM programs
      WHERE id = ${req.params.id} AND leader_id = ${req.user.leaderId} AND is_active = true
    `;
    if (!program) return res.status(403).json({ error: '권한 없음' });

    const [{ n }] = await sql`
      SELECT COUNT(*)::int AS n FROM registrations WHERE program_id = ${req.params.id}
    `;

    // 등록자가 있으면 이름을 그대로 입력해야 한다.
    if (n > 0 && String(req.body?.confirmName ?? '').trim() !== program.name) {
      return res.status(428).json({
        error: '등록자가 있는 수양회입니다. 삭제하려면 수양회 이름을 입력하십시오',
        registrationCount: n,
        requiresConfirmName: true,
      });
    }

    await sql`UPDATE programs SET is_active = false WHERE id = ${req.params.id}`;

    console.log(`[PROGRAM] 삭제 | programId=${req.params.id} name="${program.name}" registrations=${n} leaderId=${req.user.leaderId} email=${req.user.email}`);
    res.json({ ok: true, registrationCount: n });
  } catch (err) {
    console.error('수양회 삭제 오류:', err);
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
        COUNT(r.id) FILTER (WHERE flight_confirmed(r.arrival_flight)) AS arrival_flight_count,
        COUNT(r.id) FILTER (WHERE flight_confirmed(r.departure_flight)) AS departure_flight_count,
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

    // 질병 정보(medical_conditions)는 목록에 싣지 않는다.
    //
    // 화면에 표시하지 않더라도 SELECT r.* 로 보내면 브라우저까지 전달되어
    // 개발자도구·네트워크 로그에 그대로 남는다. 건강 정보는 가장 민감한 항목이므로
    // "필요한 사람이 필요할 때만" 원칙을 적용한다.
    //
    // 대신 has_medical_note 로 존재 여부만 알린다 — 담당자가 누구를 확인해야
    // 하는지는 알 수 있어야 하고, 상세는 아래 전용 엔드포인트로 따로 조회한다.
    const registrations = await sql`
      SELECT
        r.id, r.program_id, r.user_id, r.country, r.branch,
        r.real_name, r.bible_name, r.gender, r.age,
        r.arrival_flight, r.departure_flight,
        -- 확정 항공편인지. 예상 날짜만 적은 사람을 담당자가 구분해야 한다.
        flight_confirmed(r.arrival_flight) AS arrival_confirmed,
        flight_confirmed(r.departure_flight) AS departure_confirmed,
        r.food_requirements, r.skips_breakfast,
        r.selected_options, r.roommate_preference,
        r.volunteer_resources, r.volunteer_note,
        r.church_since, r.church_role,
        r.needs_pickup, r.service_declined,
        r.total_cost, r.submitted, r.created_at, r.updated_at,
        r.fee_tier,
        r.discount_requested, r.discount_option_key, r.discount_option_label,
        r.discount_option_labels,
        r.discount_reason, r.discount_status, r.discount_amount, r.discount_note,
        (r.medical_conditions IS NOT NULL AND r.medical_conditions <> '')
          AS has_medical_note,
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

// PATCH /programs/:id/registrations/:registrationId/discount - 할인 신청 판단 (리더 전용)
//
// 신청과 판단을 분리한다. 등록자는 PUT /registrations/:programId/me 로 신청만 남기고
// (status 는 항상 'requested' 로 서버가 정한다), 확정 금액은 여기서만 정해진다.
router.patch(
  '/:id/registrations/:registrationId/discount',
  requireAuth,
  requireLeader,
  async (req, res) => {
    const { status, amount, note } = req.body;

    if (!['approved', 'rejected', 'requested'].includes(status)) {
      return res.status(400).json({ error: 'status 는 approved/rejected/requested 중 하나여야 합니다' });
    }
    const value = parseFee(amount);
    if (Number.isNaN(value)) {
      return res.status(400).json({ error: '할인 금액은 0 이상의 숫자여야 합니다' });
    }
    // 승인인데 금액이 없으면 "얼마를 깎아줬는지" 아무도 모르는 상태로 남는다.
    if (status === 'approved' && value === null) {
      return res.status(400).json({ error: '승인하려면 할인 금액이 필요합니다' });
    }

    try {
      const [target] = await sql`
        SELECT r.id FROM registrations r
        JOIN programs p ON p.id = r.program_id
        WHERE r.id = ${req.params.registrationId}
          AND r.program_id = ${req.params.id}
          AND p.leader_id = ${req.user.leaderId}
      `;
      if (!target) return res.status(403).json({ error: '권한 없음' });

      await sql`
        UPDATE registrations SET
          discount_status = ${status},
          discount_amount = ${status === 'approved' ? value : null},
          discount_note   = ${note ?? null},
          updated_at      = NOW()
        WHERE id = ${req.params.registrationId}
      `;

      console.log(`[DISCOUNT] ${status} | registrationId=${req.params.registrationId} amount=${value ?? '-'} leaderId=${req.user.leaderId} email=${req.user.email}`);
      res.json({ ok: true });
    } catch (err) {
      console.error('할인 판단 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  }
);

// GET /programs/:id/registrations/:registrationId/medical
// 질병 정보 상세. 목록에서 빼둔 것을 한 사람 단위로만 조회한다.
//
// 안전상 담당자가 알아야 하는 정보이므로 막지는 않되, 목록으로 한꺼번에
// 흘러나가지 않게 한다. 누가 언제 열람했는지 로그로 남긴다.
router.get(
  '/:id/registrations/:registrationId/medical',
  requireAuth,
  requireLeader,
  async (req, res) => {
    try {
      const [program] = await sql`
        SELECT id FROM programs
        WHERE id = ${req.params.id} AND leader_id = ${req.user.leaderId}
      `;
      if (!program) return res.status(403).json({ error: '권한 없음' });

      const [row] = await sql`
        SELECT id, real_name, medical_conditions
        FROM registrations
        WHERE id = ${req.params.registrationId} AND program_id = ${req.params.id}
      `;
      if (!row) return res.status(404).json({ error: '등록을 찾을 수 없습니다' });

      console.log(
        `[MEDICAL-ACCESS] leader=${req.user.userId} program=${req.params.id} registration=${row.id}`,
      );
      res.json({
        registration_id: row.id,
        real_name: row.real_name,
        medical_conditions: row.medical_conditions,
      });
    } catch (err) {
      console.error('질병 정보 조회 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

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
          WHERE r.country IS DISTINCT FROM ${host} AND NOT flight_confirmed(r.arrival_flight)
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

    // 직분 분포. registrations.church_role(등록 시점 스냅샷)을 센다 —
    // users 를 보면 이후 직분이 바뀌었을 때 과거 명부가 흔들린다.
    // 미입력(NULL)은 선택 항목이므로 별도로 센다.
    const roleRows = await sql`
      SELECT COALESCE(r.church_role, 'unspecified') AS role, COUNT(*)::int AS count
      FROM registrations r
      WHERE r.program_id = ${programId}
      GROUP BY 1
      ORDER BY 2 DESC
    `;

    // 단계 완료는 기존 컬럼의 채움 여부로 유추한다(A003 D3). 스텝별 완료
    // 플래그를 새로 저장하면 등록 플로우가 바뀔 때마다 동기화 부담이 생긴다.
    const cohortRows = await sql`
      SELECT
        (r.country IS NOT DISTINCT FROM ${host}) AS is_domestic,
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE r.real_name IS NOT NULL AND r.real_name <> '')::int AS personal,
        COUNT(*) FILTER (WHERE r.food_requirements IS NOT NULL)::int AS meals,
        COUNT(*) FILTER (WHERE flight_confirmed(r.arrival_flight))::int AS flight,
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
          WHEN r.country IS DISTINCT FROM ${host} AND NOT flight_confirmed(r.arrival_flight) THEN 'flight'
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
        roles: {
          // 미입력이 절반을 넘으면 집계를 신뢰하기 어렵다 — 화면에서 그 점을 알린다.
          status:
            counts.total === 0
              ? 'idle'
              : (roleRows.find((r) => r.role === 'unspecified')?.count ?? 0) > counts.total / 2
                ? 'warn'
                : 'ok',
          total: counts.total,
          breakdown: Object.fromEntries(roleRows.map((r) => [r.role, r.count])),
        },
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
