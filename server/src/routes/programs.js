import { Router } from 'express';
import { sql } from '../db.js';
import { normalizeOptions } from '../services/option_media.js';
import { rolesOf, tallyRole, sortRoles } from '../services/service_roles.js';
import {
  contactsOf,
  contactsFromBody,
  legacyPair,
  normalizePaymentTiming,
  needsPaymentCard,
} from '../services/program_contacts.js';
import { normalizeRoutes, routesOf } from '../services/arrival_routes.js';

// 옵션 id 는 우리가 만든 uuid 만 받는다.
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
import {
  requireAuth,
  requireLeader,
  requireProgramAdmin,
  requireScope,
  SCOPES,
} from '../middleware/auth.js';
import { isValidBotToken } from '../services/telegram.js';

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

// 텔레그램 봇 토큰 정리(029).
//   null  → 안 보냈다(기존 값 유지)
//   ''    → 비운다(기본 봇으로 되돌린다)
//   NaN   → 형식 오류 (호출부에서 400)
function normalizeBotToken(v) {
  if (v === null || v === undefined) return null;
  const t = String(v).trim();
  if (t === '') return '';
  return isValidBotToken(t) ? t : NaN;
}

// 숙박 등급 정리(028). 관리자가 "3성급 / 4성급 …" 처럼 정의한다.
//
// 할인 항목과 모양이 같아서 붙여 쓰고 싶지만, 금액 칸의 뜻이 다르다 —
// 할인은 깎는 금액이고 이쪽은 **1박 단가**다. 한 함수로 묶으면 어느 쪽
// 규칙을 고치는지 읽는 사람이 알 수 없어 따로 둔다.
function normalizeHotelOptions(raw) {
  if (!Array.isArray(raw)) return null; // 안 보냈으면 건드리지 않는다
  const seen = new Set();
  const out = [];
  raw.forEach((o, i) => {
    const labels = {};
    for (const lang of ['ko', 'en', 'es', 'pt']) {
      const v = String(o?.labels?.[lang] ?? '').trim();
      if (v) labels[lang] = v;
    }
    const label =
      String(o?.label ?? '').trim() || labels.en || labels.ko || labels.es || '';
    if (!label) return; // 어떤 언어로도 문구가 없으면 화면에 보여줄 것이 없다

    let key = String(o?.key ?? '').trim() || `h${i + 1}`;
    while (seen.has(key)) key = `${key}_`; // key 중복은 등록 참조를 망친다
    seen.add(key);

    // 단가를 못 적을 수도 있다(아직 협상 중). 그때는 null 로 두고 화면이
    // "금액 미정"이라고 말한다. 0 으로 적어 두면 공짜인 줄 안다.
    const price = parseFee(o?.pricePerNight);
    out.push({
      key,
      label,
      labels,
      pricePerNight: Number.isNaN(price) ? null : price,
    });
  });
  return out;
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
    for (const lang of ['ko', 'en', 'es', 'pt']) {
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


// 텔레그램 봇 토큰은 **어떤 응답에도 실어 보내지 않는다.**
//
// 토큰을 아는 사람은 그 봇으로 아무 메시지나 보낼 수 있다. 그런데 프로그램
// 조회(GET /programs/:id)는 참가자 누구나 부를 수 있는 경로라, SELECT p.* 로
// 그대로 내보내면 등록한 사람 전원에게 토큰이 넘어간다.
//
// 지우기만 하면 화면이 "설정했는지"를 알 수 없으므로 불리언 하나로 바꾼다.
function stripBotToken(program) {
  if (!program) return program;
  const { telegram_bot_token: token, ...rest } = program;
  return { ...rest, telegram_bot_configured: !!token };
}

// GET /programs/for-my-chapter — 우리 지부 지부장이 만든 수양회
//
// **이 경로는 반드시 /:id 보다 위에 있어야 한다.** 아래로 내려가면
// '/for-my-chapter' 가 프로그램 id 로 잡혀 UUID 파싱에서 깨진다 —
// 실제로 그렇게 두었다가 잡았다.
//
// 한 번이라도 등록한 적이 있으면 그 등록서에 나라와 지부가 적혀 있다.
// 그 지부의 지부장이 새 수양회를 만들면 UUID 를 몰라도 여기서 보인다.
//
// **모든 판단을 서버가 한다.** 앱이 "내 지부는 이것" 이라고 보내오게 하면,
// 아무 지부나 적어 남의 수양회 UUID 를 받아 갈 수 있다 — UUID 는 참가의
// 열쇠이므로 그것은 자물쇠를 없애는 것과 같다.
//
// 처음 오는 사람에게는 아무것도 안 나온다. 나라·지부를 알 방법이 없다.
// 그때는 UUID 가 유일한 길이고, 그것이 맞다.
router.get('/for-my-chapter', requireAuth, async (req, res) => {
  try {
    // 가장 최근 등록의 나라·지부. 지부는 화면에서 고른 UBF 챕터 이름이다.
    const [me] = await sql`
      SELECT country, branch
      FROM registrations
      WHERE user_id = ${req.user.userId}
        AND country IS NOT NULL AND btrim(COALESCE(branch, '')) <> ''
      ORDER BY updated_at DESC NULLS LAST
      LIMIT 1
    `;
    if (!me) return res.json([]);

    const rows = await sql`
      SELECT p.id, p.name, p.location, p.start_date, p.end_date,
             l.name AS leader_name
      FROM programs p
      JOIN leaders l ON l.id = p.leader_id
      WHERE p.is_active = true
        AND l.nation_iso = ${me.country}
        AND lower(btrim(l.chapter)) = lower(btrim(${me.branch}))
        -- 이미 등록한 수양회는 알릴 것이 없다.
        AND NOT EXISTS (
          SELECT 1 FROM registrations r
          WHERE r.program_id = p.id AND r.user_id = ${req.user.userId}
        )
        -- 끝난 수양회는 알리지 않는다. 종료일이 없으면 시작일로 본다.
        AND COALESCE(p.end_date, p.start_date, CURRENT_DATE) >= CURRENT_DATE
      ORDER BY p.start_date NULLS LAST, p.created_at DESC
    `;
    res.json(rows);
  } catch (err) {
    console.error('지부 수양회 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

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
            'planDocs', COALESCE(po.plan_docs, '[]'::jsonb),
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

    // 연락처는 늘 목록으로 내보낸다(040). 이 기능이 생기기 전 수양회는
    // 005 의 두 컬럼에만 있으므로 읽을 때 만들어 준다.
    res.json({
      ...stripBotToken(program),
      contacts: contactsOf(program),
      // 도착 경로도 늘 목록으로 내보낸다(048). null 을 그대로 주면 화면마다
      // 따로 막아야 한다.
      arrival_routes: routesOf(program),
    });
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
      --
      -- **공동 관리자도 자기 수양회를 봐야 한다(058).** 지금까지는 만든
      -- 사람(leader_id)만 봤다. 공동 관리자로 세워 둔 네 사람은 admin 이라
      -- 관리자 화면까지는 들어왔는데 목록이 비어 있어서, 들어와도 아무것도
      -- 할 수가 없었다. requireProgramAdmin 이 지키는 나머지 화면은 모두
      -- 열어 주고 있었으므로 여기만 어긋나 있었다.
      WHERE p.is_active = true
        AND (
          p.leader_id = ${req.user.leaderId}
          OR EXISTS (
            SELECT 1 FROM program_admins pa
            WHERE pa.program_id = p.id AND pa.user_id = ${req.user.userId}
          )
        )
      GROUP BY p.id
      ORDER BY p.created_at DESC
    `;

    res.json(programs.map(stripBotToken));
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
    currency, smallCohortPolicy, minTeamSize, hotelOptions,
    telegramBotToken, telegramChatId,
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
  const hotels = normalizeHotelOptions(hotelOptions) ?? [];

  const cur = normalizeCurrency(currency);
  if (Number.isNaN(cur)) {
    return res.status(400).json({ error: '통화는 ISO 4217 코드(대문자 세 글자)여야 합니다' });
  }


  // 수양회 전용 텔레그램 봇(029). 안 적으면 서버 기본 봇을 쓴다.
  //
  // 형식만 본다. 붙여넣다 잘린 값을 그대로 저장하면 알림이 조용히 안 가고,
  // 담당자는 그 사실을 몇 주 뒤 "왜 알림이 안 와요"로 알게 된다.
  const botToken = normalizeBotToken(telegramBotToken);
  if (Number.isNaN(botToken)) {
    return res.status(400).json({
      error: '텔레그램 봇 토큰 형식이 올바르지 않습니다 (예: 123456789:AA...)',
    });
  }

  const cohortPolicy = normalizeCohortPolicy(smallCohortPolicy);
  const teamMin = normalizeMinTeamSize(minTeamSize);
  if (Number.isNaN(cohortPolicy) || Number.isNaN(teamMin)) {
    return res.status(400).json({ error: '소수 인원 방침이 올바르지 않습니다' });
  }

  try {
    // 현장 대표 연락처(040). 새 앱은 contacts 목록을, 옛 앱은 두 명분
    // 네 칸을 보낸다. 앞의 두 명은 옛 컬럼에도 함께 적는다 — 옛 앱이 깔린
    // 기기가 아직 그 컬럼을 읽는다.
    const contactList = contactsFromBody(req.body) ?? [];
    const newContacts = legacyPair(contactList);

    // 도착 경로(048). 가까운 공항 외에 올 수 있는 길.
    const routeList = normalizeRoutes(req.body?.arrivalRoutes);

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
        contacts, arrival_routes, fee_payment, tour_payment,
        program_type, host_country,
        fee_basic, fee_premium, fee_basic_desc, fee_premium_desc, discount_options,
        currency, small_cohort_policy, min_team_size, hotel_options,
        telegram_bot_token, telegram_chat_id
      )
      VALUES (
        ${name},
        ${location},
        ${req.user.leaderId},
        ${startDate ?? null},
        ${endDate ?? null},
        ${JSON.stringify(sections)},
        ${nearestAirport ?? null},
        ${newContacts.contact1Name},
        ${newContacts.contact1Phone},
        ${newContacts.contact2Name},
        ${newContacts.contact2Phone},
        ${JSON.stringify(contactList ?? [])}::jsonb,
        ${JSON.stringify(routeList)}::jsonb,
        ${normalizePaymentTiming(req.body?.feePayment)},
        ${normalizePaymentTiming(req.body?.tourPayment)},
        ${type},
        ${hostCountry ?? null},
        ${basic},
        ${premium},
        ${feeBasicDesc ?? null},
        ${feePremiumDesc ?? null},
        ${JSON.stringify(discounts)},
        ${currencyFor(type, cur, null)},
        ${cohortPolicy ?? 'keep'},
        ${teamMin ?? 5},
        ${JSON.stringify(hotels)},
        ${botToken || null},
        ${telegramChatId?.toString().trim() || null}
      )
      RETURNING id
    `;

    // 사진·계획서 주소는 담당자 브라우저에서 온 값이다. 참가자 화면이
    // 그대로 열기 때문에 저장 전에 한 번 거른다(option_media.js).
    const options2 = normalizeOptions(options);

    // 옵션 일괄 삽입
    if (Array.isArray(options2) && options2.length > 0) {
      await sql`
        INSERT INTO program_options (program_id, name, description, cost, start_date, end_date, contact_name, photo_urls, capacity, signup_deadline, brochure_url, video_url, plan_docs)
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
          NULLIF(o->>'videoUrl', ''),
          COALESCE(o->'planDocs', '[]'::json)::jsonb
        FROM json_array_elements(${JSON.stringify(options2)}::json) AS o
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
    currency, hotelOptions, telegramBotToken, telegramChatId,
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
  // 안 보냈으면 null 이 되고 아래에서 기존 값을 그대로 쓴다. 숙박 등급만
  // 고치려는 호출이 참가비를 지우지 않는 것과 같은 규칙이다.
  const hotels = normalizeHotelOptions(hotelOptions);
  const patchBotToken = normalizeBotToken(telegramBotToken);
  if (Number.isNaN(patchBotToken)) {
    return res.status(400).json({
      error: '텔레그램 봇 토큰 형식이 올바르지 않습니다 (예: 123456789:AA...)',
    });
  }

  // 현장 대표 연락처(040). 본문에 없으면 null 이고, 그러면 손대지 않는다.
  const contactList2 = contactsFromBody(req.body);
  const patchContacts = contactList2 === null
    ? null
    : { list: contactList2, pair: legacyPair(contactList2) };

  // 도착 경로(048). 연락처와 같은 규칙 — 본문에 없으면 그대로 둔다.
  // 공항 하나만 고치는 저장이 애써 적어 둔 경로 목록을 지우면 안 된다.

  // 본문에 없는 키는 건드리지 않는다. 참가비만 고치려는 호출이 할인 항목을
  // 지워버리면 안 된다. (기존 필드들은 덮어쓰기 방식이라 이 규칙이 없다.)
  const has = (k) => Object.prototype.hasOwnProperty.call(req.body, k);

  try {
    // 소유권 + 시작일 확인
    const [program] = await sql`
      SELECT id, program_type, start_date, currency,
             small_cohort_policy, min_team_size,
             fee_basic, fee_premium, fee_basic_desc, fee_premium_desc, discount_options,
             hotel_options
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
        -- 연락처를 건드리지 않는 저장(예: 참가비만 고치기)이 목록을
        -- 지워 버리면 안 된다. 본문에 없으면 그대로 둔다.
        contact1_name    = ${patchContacts ? patchContacts.pair.contact1Name : null},
        contact1_phone   = ${patchContacts ? patchContacts.pair.contact1Phone : null},
        contact2_name    = ${patchContacts ? patchContacts.pair.contact2Name : null},
        contact2_phone   = ${patchContacts ? patchContacts.pair.contact2Phone : null},
        contacts         = CASE
          WHEN ${patchContacts === null} THEN contacts
          ELSE ${JSON.stringify(patchContacts?.list ?? [])}::jsonb
        END,
        arrival_routes   = CASE
          WHEN ${!Object.prototype.hasOwnProperty.call(req.body, 'arrivalRoutes')}
            THEN arrival_routes
          ELSE ${JSON.stringify(normalizeRoutes(req.body?.arrivalRoutes))}::jsonb
        END,
        -- 참가비만 고치는 저장이 입금 시점을 되돌리면 안 된다.
        fee_payment      = CASE
          WHEN ${!has('feePayment')} THEN fee_payment
          ELSE ${normalizePaymentTiming(req.body?.feePayment)}
        END,
        tour_payment     = CASE
          WHEN ${!has('tourPayment')} THEN tour_payment
          ELSE ${normalizePaymentTiming(req.body?.tourPayment)}
        END,
        program_type     = ${type},
        host_country     = ${hostCountry ?? null},
        fee_basic        = ${has('feeBasic') ? basic : program.fee_basic},
        fee_premium      = ${has('feePremium') ? premium : program.fee_premium},
        fee_basic_desc   = ${has('feeBasicDesc') ? (feeBasicDesc ?? null) : program.fee_basic_desc},
        fee_premium_desc = ${has('feePremiumDesc') ? (feePremiumDesc ?? null) : program.fee_premium_desc},
        discount_options = ${JSON.stringify(discounts ?? program.discount_options ?? [])}::jsonb,
        currency         = ${currencyFor(type, patchCurrency, program.currency)},
        small_cohort_policy = ${patchPolicy ?? program.small_cohort_policy ?? 'keep'},
        min_team_size       = ${patchTeamMin ?? program.min_team_size ?? 5},
        hotel_options       = ${JSON.stringify(hotels ?? program.hotel_options ?? [])}::jsonb,
        -- 안 보냈으면 그대로 둔다. 화면이 토큰을 못 읽으므로(응답에 없다)
        -- 다른 항목만 고치려는 저장이 매번 토큰을 지워 버리면 안 된다.
        telegram_bot_token  = CASE
          WHEN ${patchBotToken === null} THEN telegram_bot_token
          WHEN ${patchBotToken === ''}   THEN NULL
          ELSE ${patchBotToken || null}
        END,
        telegram_chat_id    = CASE
          WHEN ${telegramChatId === undefined} THEN telegram_chat_id
          ELSE ${telegramChatId?.toString().trim() || null}
        END
      WHERE id = ${req.params.id}
    `;

    // 옵션 저장.
    //
    // 예전에는 전부 비활성화하고 새로 넣었다. 그러면 저장할 때마다 옵션의
    // id 가 바뀌고, **이미 신청한 사람의 selected_options 는 죽은 id 를
    // 가리키게 된다.** 그 선택은 투어 화면에서 사라지는데 대시보드 카드에는
    // 남아, 카드는 4명인데 안에는 2명이 됐다. 운영에서 실제로 그랬다.
    //
    // 이제 id 를 그대로 둔다 — 있는 것은 고치고, 새 것만 넣고, 빠진 것만
    // 내린다.
    const options2 = normalizeOptions(options);
    if (Array.isArray(options2)) {
      const keep = options2
        .map((o) => o?.id)
        .filter((v) => typeof v === 'string' && UUID_RE.test(v));

      await sql.transaction(async (client) => {
        // 화면에서 지운 것만 내린다.
        await client.query(
          `UPDATE program_options SET is_active = false
           WHERE program_id = $1 AND NOT (id = ANY($2::uuid[]))`,
          [req.params.id, keep],
        );

        for (const o of options2) {
          const vals = [
            req.params.id,
            o.name ?? null,
            o.description ?? null,
            o.cost ?? 0,
            o.startDate || null,
            o.endDate || null,
            o.contactName ?? null,
            o.photoUrls ?? [],
            o.capacity ?? null,
            o.signupDeadline || null,
            o.brochureUrl || null,
            o.videoUrl || null,
            JSON.stringify(o.planDocs ?? []),
          ];
          const hasId = typeof o.id === 'string' && UUID_RE.test(o.id);
          if (hasId) {
            const r = await client.query(
              `UPDATE program_options SET
                 name = $2, description = $3, cost = $4,
                 start_date = $5, end_date = $6, contact_name = $7,
                 photo_urls = $8, capacity = $9, signup_deadline = $10,
                 brochure_url = $11, video_url = $12, plan_docs = $13::jsonb,
                 is_active = true
               WHERE id = $14 AND program_id = $1`,
              [...vals, o.id],
            );
            if (r.rowCount > 0) continue;
            // 남의 수양회 id 를 보냈거나 이미 지워진 것. 새로 넣는다.
          }
          await client.query(
            `INSERT INTO program_options
               (program_id, name, description, cost, start_date, end_date,
                contact_name, photo_urls, capacity, signup_deadline,
                brochure_url, video_url, plan_docs)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13::jsonb)`,
            vals,
          );
        }
      });
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
router.get('/:id/stats', requireAuth, requireProgramAdmin, requireScope(...SCOPES), async (req, res) => {
  try {
    // 권한은 requireProgramAdmin 이 이미 봤다(만든 사람 · 공동 관리자 ·
    // director). 여기서 leader_id 로 다시 좁히면 공동 관리자가 막힌다.
    const [program] = await sql`
      SELECT id FROM programs WHERE id = ${req.params.id} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

    const [stats] = await sql`
      SELECT
        p.id AS program_id,
        p.name AS program_name,
        COUNT(r.id) AS total_registrations,
        COUNT(r.id) FILTER (WHERE r.submitted = true) AS submitted_count,
        -- 투어를 하나라도 신청한 사람. 신청 건수가 아니라 사람 수다 —
        -- 카드가 "n명" 이라고 말하기 때문이다.
        --
        -- **살아 있는 옵션만 센다.** 예전에는 저장할 때마다 옵션 id 가 바뀌어
        -- 죽은 id 를 가리키는 선택이 남았는데, 그것까지 세는 바람에 카드는
        -- 4명인데 투어 화면에는 2명이었다.
        COUNT(r.id) FILTER (WHERE EXISTS (
          SELECT 1 FROM program_options po
          WHERE po.program_id = p.id AND po.is_active
            AND po.id = ANY(r.selected_options)
        )) AS tour_signup_count,
        -- 판정은 has_food_restriction(027) 하나로 모았다. 여기만 예전 조건이
        -- 남아 있어서 대시보드 카드는 4명, 표는 2명이 됐다 — 같은 것을 두
        -- 규칙으로 세면 어느 쪽도 믿을 수 없다.
        COUNT(r.id) FILTER (WHERE has_food_restriction(r.food_requirements))
          AS food_restriction_count,
        -- 등록할 때 "제가 할 수 있는 것" 을 적어 낸 사람(009). 역할을 맡은
        -- 것이 아니라 자원한 것뿐이다 — 고르는 것은 담당자의 몫이다.
        COUNT(r.id) FILTER (
          WHERE COALESCE(array_length(r.volunteer_resources, 1), 0) > 0
        ) AS volunteer_count,
        COUNT(r.id) FILTER (WHERE flight_confirmed(r.arrival_flight)) AS arrival_flight_count,
        COUNT(r.id) FILTER (WHERE flight_confirmed(r.departure_flight)) AS departure_flight_count,
        COUNT(pay.id) FILTER (WHERE pay.status = 'pending') AS pending_payment_count,
        COUNT(pay.id) FILTER (WHERE pay.status = 'confirmed') AS confirmed_payment_count,
        -- 입금 현황 카드는 "확인 n / 전체 m" 한 줄로 말한다. 대기와 확인을
        -- 카드 둘로 나눠 두면 담당자가 둘을 머릿속에서 더해야 한다.
        p.fee_payment, p.tour_payment
      FROM programs p
      -- 이름을 적기 전의 행은 세지 않는다(038). 앱을 열면 등록 행이 먼저
      -- 생기므로, 열어만 보고 만 사람이 참가자 수에 섞인다.
      LEFT JOIN registrations r
        ON r.program_id = p.id AND counts_as_participant(r.real_name, r.submitted)
      LEFT JOIN payments pay ON pay.registration_id = r.id
      WHERE p.id = ${req.params.id}
      GROUP BY p.id, p.name, p.fee_payment, p.tour_payment
    `;

    // 카드 안에 보여 줄 최근 몇 줄.
    //
    // **숫자와 같은 요청에서 온다.** 따로 조회하면 카드는 4명인데 미리보기는
    // 둘, 같은 어긋남이 또 생긴다 — 식사 제한과 투어에서 이미 두 번 겪었다.
    const id = req.params.id;
    const LIMIT = 3;

    // 봉사 역할별 현황. 역할 구성은 프로그램에 저장돼 있고(039), 비어 있으면
    // 기본 열세 개를 쓴다.
    const [progRow] = await sql`
      SELECT service_options FROM programs WHERE id = ${id}
    `;
    const serviceSignups = await sql`
      SELECT ss.service_key, ss.status
      FROM service_signups ss
      JOIN registrations r ON r.id = ss.registration_id
      WHERE r.program_id = ${id} AND counts_as_participant(r.real_name, r.submitted)
    `;
    const serviceRoles = sortRoles(
      rolesOf(progRow?.service_options).filter((x) => x.enabled !== false),
      serviceSignups,
    )
      .map((role) => ({ ...role, ...tallyRole(role, serviceSignups) }))
      .filter((x) => x.needed > 0 || x.filled > 0)
      .slice(0, LIMIT);

    // 자원한 사람 몇 줄. 역할별 부족만 내보내다가, 필요 인원을 아직 아무
    // 역할에도 안 잡아 둔 수양회에서 카드가 "5명" 위에 "아직 없습니다" 를
    // 띄웠다 — 자원자가 없다는 뜻으로 읽힌다. 보여 줄 역할 줄이 없으면
    // 자원한 사람을 대신 보여 준다.
    //
    // 많이 적어 낸 사람이 먼저다. 담당자가 카드에서 찾는 것은 "누구에게
    // 부탁할 수 있나" 이기 때문이다.
    // `assigned` 는 **자원과 다른 것**이다. 자원은 "할 수 있다" 이고 이것은
    // 실제로 맡은 자리다. 카드가 둘을 구별해 말하지 않으면 "자원자 5명" 옆의
    // 빈 줄이 자원자가 없다는 뜻으로 읽힌다. 거절·반려는 맡은 것이 아니다.
    const volunteers = await sql`
      SELECT display_name(r.bible_name, r.real_name) AS name, r.country,
             r.volunteer_resources AS resources,
             (
               SELECT COUNT(*)::int FROM service_signups ss
               WHERE ss.registration_id = r.id
                 AND ss.status NOT IN ('declined', 'rejected')
             ) AS assigned
      FROM registrations r
      WHERE r.program_id = ${id} AND counts_as_participant(r.real_name, r.submitted)
        AND COALESCE(array_length(r.volunteer_resources, 1), 0) > 0
      ORDER BY array_length(r.volunteer_resources, 1) DESC, r.real_name
      LIMIT ${LIMIT}
    `;

    const [recent, tours, meals, arrival, payments] = await Promise.all([
      sql`
        SELECT display_name(r.bible_name, r.real_name) AS name, r.country, r.submitted
        FROM registrations r
        WHERE r.program_id = ${id} AND counts_as_participant(r.real_name, r.submitted)
        ORDER BY r.created_at DESC LIMIT ${LIMIT}
      `,
      // 투어는 사람이 아니라 투어별 줄을 보여 준다 — 담당자가 먼저 보는 것이
      // "어느 투어가 찼나" 이기 때문이다. 신청자가 없는 투어도 남긴다.
      sql`
        SELECT o.name, o.capacity,
               COUNT(r.id)::int AS signup_count
        FROM program_options o
        LEFT JOIN registrations r
          ON r.program_id = ${id} AND o.id = ANY(r.selected_options)
             AND counts_as_participant(r.real_name, r.submitted)
        WHERE o.program_id = ${id} AND o.is_active
        GROUP BY o.id, o.name, o.capacity
        ORDER BY COUNT(r.id) DESC, o.name
        LIMIT ${LIMIT}
      `,
      sql`
        SELECT display_name(r.bible_name, r.real_name) AS name, r.country, r.food_requirements AS detail,
               r.submitted
        FROM registrations r
        WHERE r.program_id = ${id} AND counts_as_participant(r.real_name, r.submitted)
          AND has_food_restriction(r.food_requirements)
        ORDER BY r.country NULLS LAST, r.real_name LIMIT ${LIMIT}
      `,
      sql`
        SELECT display_name(r.bible_name, r.real_name) AS name, r.country,
               COALESCE(r.arrival_flight->>'flight_no', '') AS detail,
               r.submitted
        FROM registrations r
        WHERE r.program_id = ${id} AND counts_as_participant(r.real_name, r.submitted)
          AND flight_confirmed(r.arrival_flight)
        ORDER BY r.arrival_flight->>'scheduled_arrival' LIMIT ${LIMIT}
      `,
      // 입금은 대기·확인을 한 목록으로 준다. 아직 낸 적이 없는 사람도
      // 넣는다 — 받을 돈이 남은 사람이야말로 담당자가 봐야 할 줄이다.
      sql`
        SELECT display_name(r.bible_name, r.real_name) AS name, r.country,
               COALESCE(pay.status, 'none') AS status,
               pay.amount::text AS detail
        FROM registrations r
        LEFT JOIN payments pay ON pay.registration_id = r.id
        WHERE r.program_id = ${id} AND counts_as_participant(r.real_name, r.submitted)
        ORDER BY (COALESCE(pay.status, 'none') = 'confirmed'), r.real_name
        LIMIT ${LIMIT}
      `,
    ]);

    res.json({
      // 이 사람이 맡은 분야(059). null 이면 전부다. 앱은 이것으로 안 맡은
      // 카드를 **감춘다** — 자물쇠로 남기면 못 여는 문을 계속 보게 된다.
      myScopes: req.adminScopes ?? null,
      ...(stats ?? {}),
      // 입금 카드를 보여 줄지 여기서 정한다. 앱이 따로 판단하면 규칙이
      // 두 곳에 생긴다.
      needs_payment_card: needsPaymentCard(stats ?? {}),
      preview: {
        recent,
        tours,
        meals,
        arrival,
        payments,
        services: serviceRoles,
        volunteers,
      },
    });
  } catch (err) {
    console.error('통계 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /programs/:id/registrations - 참가자 전체 목록 (리더 전용)
router.get('/:id/registrations', requireAuth, requireProgramAdmin,
  requireScope('registration'), async (req, res) => {
  try {
    // 권한은 requireProgramAdmin 이 봤다(공동 관리자 포함).
    const [program] = await sql`
      SELECT id FROM programs WHERE id = ${req.params.id} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

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
        -- 이름을 안 적고 제출한 사람이 빈 줄로 보이면 담당자가 누구인지
        -- 알 수 없다(055). 로그인한 계정 이름을 대신 준다 — 본인이 적은
        -- 것은 아니므로 앱이 "계정 이름" 이라고 밝혀 보여 준다.
        CASE WHEN COALESCE(btrim(r.real_name), '') = ''
                  AND COALESCE(btrim(r.bible_name), '') = ''
             THEN NULLIF(btrim(COALESCE(u.name, '')), '') END AS account_name,
        r.arrival_flight, r.departure_flight,
        -- 확정 항공편인지. 예상 날짜만 적은 사람을 담당자가 구분해야 한다.
        flight_confirmed(r.arrival_flight) AS arrival_confirmed,
        flight_confirmed(r.departure_flight) AS departure_confirmed,
        r.food_requirements, r.skips_breakfast,
        r.selected_options, r.roommate_preference,
        r.volunteer_resources, r.volunteer_note,
        r.church_since, r.church_role,
        r.needs_pickup, r.service_declined,
        -- 수양회 전후 숙박(028). 담당자가 호텔에 방을 잡으려면 등급과 박수를
        -- 함께 봐야 한다.
        r.hotel_option_key, r.hotel_nights_before, r.hotel_nights_after,
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
        ) AS payment,
        -- 낼 돈. total_cost 는 저장된 값이고, 참가비를 안 고른 옛 행은
        -- 0 이다. 그런 행에는 수양회의 기본 참가비를 대신 쓴다 — 표에서
        -- 0 원으로 보이면 받으러 가지 않는다(054).
        GREATEST(
          COALESCE(NULLIF(r.total_cost, 0), p.fee_basic, 0),
          0
        )::numeric AS amount_due
      FROM registrations r
      JOIN programs p ON p.id = r.program_id
      LEFT JOIN payments pay ON pay.registration_id = r.id
      LEFT JOIN users u ON u.id = r.user_id
      -- 아직 아무것도 안 적은 행은 참가자가 아니다(038). 카드의 숫자도 같은
      -- 판정을 쓴다 — 한쪽만 거르면 "10명인데 9명만 보인다" 가 된다.
      -- 제출한 사람은 이름이 비어도 넣는다(055).
      WHERE r.program_id = ${req.params.id}
        AND counts_as_participant(r.real_name, r.submitted)
      ORDER BY r.created_at ASC
    `;

    res.json(registrations);
  } catch (err) {
    console.error('참가자 목록 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /programs/:id/registrations/:registrationId — 한 사람의 등록·입금 손보기
//
// 담당자가 명단을 보다가 그 자리에서 고쳐야 하는 것들이 있다:
//   - 현장에서 등록서를 대신 받아 적어 준 사람의 **등록 완료**
//   - 그 사람이 **낼 돈**과 **받았는지**
//
// 지금까지 입금은 등록자가 올린 것을 담당자가 승인/반려하는 길뿐이었다.
// 그런데 현금을 그 자리에서 받는 수양회가 대부분이고, 그때는 올릴 영수증도
// 없다. 담당자가 직접 적을 수 있어야 한다.
//
// **금액과 상태는 함께 다룬다.** 금액만 적고 상태를 안 정하면 "얼마를
// 받을지는 아는데 받았는지는 모르는" 줄이 생긴다.
router.patch(
  '/:id/registrations/:registrationId',
  requireAuth,
  requireProgramAdmin,
  // 등록 완료는 등록 담당이, 낼 돈·받은 돈은 회계 담당이 손댄다.
  requireScope('registration', 'ledger'),
  async (req, res) => {
    const { id: programId, registrationId } = req.params;
    const body = req.body ?? {};

    try {
      const [reg] = await sql`
        SELECT id FROM registrations
        WHERE id = ${registrationId} AND program_id = ${programId}
      `;
      if (!reg) return res.status(404).json({ error: '참가자를 찾을 수 없습니다' });

      // 등록 완료 여부. 본문에 없으면 손대지 않는다.
      if (typeof body.submitted === 'boolean') {
        await sql`
          UPDATE registrations SET submitted = ${body.submitted}, updated_at = NOW()
          WHERE id = ${registrationId}
        `;
      }

      // 입금. payments 는 등록 하나에 한 줄이다(001 의 UNIQUE).
      if (Object.prototype.hasOwnProperty.call(body, 'payment')) {
        const pay = body.payment;
        if (pay === null) {
          // 잘못 적었을 때 되돌릴 길. 줄을 지운다.
          await sql`DELETE FROM payments WHERE registration_id = ${registrationId}`;
        } else {
          const amount = Number(pay?.amount);
          if (!Number.isFinite(amount) || amount < 0) {
            return res.status(400).json({ error: '금액이 올바르지 않습니다' });
          }
          const status = ['pending', 'confirmed', 'rejected'].includes(pay?.status)
            ? pay.status
            : 'pending';
          await sql`
            INSERT INTO payments (registration_id, amount, status, note)
            VALUES (${registrationId}, ${amount}, ${status}, ${pay?.note ?? null})
            ON CONFLICT (registration_id) DO UPDATE
              SET amount = ${amount},
                  status = ${status},
                  note = ${pay?.note ?? null},
                  confirmed_by = ${status === 'confirmed' ? (req.user.leaderId ?? null) : null},
                  confirmed_at = ${status === 'confirmed' ? new Date() : null}
          `;
        }
      }

      const [row] = await sql`
        SELECT r.id, r.submitted,
               json_build_object('status', pay.status, 'amount', pay.amount) AS payment
        FROM registrations r
        LEFT JOIN payments pay ON pay.registration_id = r.id
        WHERE r.id = ${registrationId}
      `;
      res.json(row);
    } catch (err) {
      console.error('참가자 수정 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// PATCH /programs/:id/registrations/:registrationId/discount - 할인 신청 판단 (리더 전용)
//
// 신청과 판단을 분리한다. 등록자는 PUT /registrations/:programId/me 로 신청만 남기고
// (status 는 항상 'requested' 로 서버가 정한다), 확정 금액은 여기서만 정해진다.
router.patch(
  '/:id/registrations/:registrationId/discount',
  requireAuth,
  requireProgramAdmin,
  requireScope('ledger'),
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
  // 의료 담당과 만든 사람만 본다(059). 열람 기록은 그대로 남는다.
  requireProgramAdmin,
  requireScope('medical'),
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

router.get('/:id/readiness', requireAuth, requireProgramAdmin,
  requireScope('registration'), async (req, res) => {
  const programId = req.params.id;
  try {
    const [program] = await sql`
      SELECT id, name, location, start_date, end_date, host_country, program_type,
             registration_deadline, capacity, base_fee
      FROM programs
      WHERE id = ${programId} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

    const host = program.host_country;
    const isInternational = program.program_type === 'international';

    // 국내/해외 판정은 registrations.country 를 쓴다. 등록 화면에서 직접 고른
    // 값이라 users.region 보다 정확하다.
    const [counts] = await sql`
      SELECT
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE r.country IS DISTINCT FROM ${host})::int AS overseas,
        COUNT(*) FILTER (
          WHERE r.country IS DISTINCT FROM ${host} AND NOT flight_confirmed(r.arrival_flight)
        )::int AS flights_missing,
        -- 판정은 has_food_restriction(027) 하나로 모았다. 카드의 숫자와
        -- 카드를 열었을 때 나오는 명단(GET /:id/meals)이 어긋나면 안 된다.
        COUNT(*) FILTER (WHERE has_food_restriction(r.food_requirements))::int
          AS meals_restricted,
        -- 참가비 등급을 못 고른 사람. 참가비를 나중에 정하는 수양회가 많고,
        -- 그 사이에 등록한 사람은 참가비 화면을 아예 못 본다. 그 사실이
        -- 어디에도 안 보이면 아무도 모르는 채로 수양회 날이 온다.
        COUNT(*) FILTER (WHERE r.fee_tier IS NULL)::int AS fee_tier_missing,
        -- 국제 수양회의 개최국 참가자는 픽업 대상이 아니다(dispatch_engine.js
        -- isPickupExempt 와 같은 규칙). 배차판에서 빠진 사람을 여기서 계속
        -- 세면 필요 좌석이 부풀려져 밴을 과하게 잡는다.
        COUNT(*) FILTER (
          WHERE r.needs_pickup IS NOT FALSE
            AND NOT (
              ${isInternational}
              AND ${host}::text IS NOT NULL
              AND r.country IS NOT DISTINCT FROM ${host}
              AND COALESCE(r.arrival_flight->>'arrival_airport', '') = ''
              AND COALESCE(r.arrival_flight->>'scheduled_arrival', '') = ''
            )
        )::int AS pickup_needed
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
        COUNT(*) FILTER (WHERE has_registrant_name(r.real_name))::int AS personal,
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
        r.id AS registration_id, display_name(r.bible_name, r.real_name) AS name, r.country, r.branch,
        (r.country IS NOT DISTINCT FROM ${host}) AS is_domestic,
        r.updated_at,
        CASE
          WHEN NOT has_registrant_name(r.real_name) THEN 'personal'
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
        fees: {
          status: counts.fee_tier_missing === 0 ? 'ok' : 'warn',
          missing: counts.fee_tier_missing,
          total: counts.total,
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

// POST /programs/:id/fee-tier-backfill — 참가비를 못 고른 사람 맞추기
//
// 참가비를 나중에 정하는 수양회가 많다. 그 사이에 등록한 사람은 참가비
// 화면을 아예 못 봐서 등급이 비어 있고, 총액에도 참가비가 안 들어간다.
// 담당자가 나중에 금액을 적어도 이미 등록한 사람의 총액은 그대로다.
//
// 각자 다시 들어와 고르게 하는 것이 원칙이지만, 등급이 하나뿐이거나
// 대부분이 같은 등급이면 담당자가 한 번에 맞추는 편이 낫다.
//
// **총액은 서버가 다시 계산한다**(등급 + 투어 − 승인된 할인).
// registrations.js 의 식과 같아야 한다 — 다르면 이 버튼을 누른 사람만
// 다른 금액이 된다.
router.post('/:id/fee-tier-backfill', requireAuth, requireProgramAdmin,
  requireScope('ledger'), async (req, res) => {
  const tier = req.body?.tier === 'premium' ? 'premium' : 'basic';
  try {
    const [program] = await sql`
      SELECT fee_basic, fee_premium FROM programs
      WHERE id = ${req.params.id} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

    // 금액이 없는 등급으로는 맞출 수 없다. 그대로 두면 전원이 0원이 된다.
    const fee = tier === 'basic' ? program.fee_basic : program.fee_premium;
    if (fee === null || fee === undefined) {
      return res.status(422).json({
        code: 'FEE_NOT_SET',
        error: '그 등급의 참가비가 정해져 있지 않습니다',
      });
    }

    const rows = await sql`
      UPDATE registrations r SET
        fee_tier = ${tier},
        total_cost = GREATEST(0, ${Number(fee)}
          + COALESCE((
              SELECT SUM(po.cost) FROM program_options po
              WHERE po.program_id = r.program_id AND po.id = ANY(r.selected_options)
            ), 0)
          - CASE WHEN r.discount_status = 'approved'
                 THEN COALESCE(r.discount_amount, 0) ELSE 0 END),
        updated_at = NOW()
      WHERE r.program_id = ${req.params.id}
        -- 이미 고른 사람은 건드리지 않는다. 고급을 고른 사람을 기본으로
        -- 내리면 그 사람은 자기가 왜 싸졌는지 모른다.
        AND r.fee_tier IS NULL
      RETURNING r.id
    `;
    console.log(
      `[FEE] 등급 일괄 지정 | programId=${req.params.id} tier=${tier} count=${rows.length}`,
    );
    res.json({ updated: rows.length, tier });
  } catch (err) {
    console.error('참가비 등급 일괄 지정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /programs/:id/meals — 식사 제한 명단 (준비 현황 카드를 열면 나온다)
//
// 주방에 넘길 목록이다. 준비 현황 카드의 숫자와 같은 판정
// (has_food_restriction, 027)을 쓴다 — 두 곳에 각각 적으면 반드시 어긋난다.
//
// 공동 관리자도 봐야 한다. 식단은 주방·구매 담당이 챙기는 일이지 수양회를
// 만든 사람만의 일이 아니다. 그래서 requireLeader 가 아니라
// requireProgramAdmin 이다.
router.get('/:id/meals', requireAuth, requireProgramAdmin,
  requireScope('registration'), async (req, res) => {
  const programId = req.params.id;
  try {
    const [program] = await sql`
      SELECT id, name, location, start_date, end_date
      FROM programs WHERE id = ${programId} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

    // 제출 여부로 거르지 않는다. 아직 제출하지 않았어도 못 먹는 것은 못 먹는다.
    const people = await sql`
      SELECT r.real_name, r.bible_name, r.country, r.branch, r.gender, r.age,
             r.food_requirements, r.skips_breakfast, r.submitted
      FROM registrations r
      WHERE r.program_id = ${programId}
        AND has_food_restriction(r.food_requirements)
      ORDER BY r.country NULLS LAST, r.real_name
    `;

    const [counts] = await sql`
      SELECT
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE r.skips_breakfast)::int AS skips_breakfast
      FROM registrations r
      WHERE r.program_id = ${programId}
    `;

    res.json({
      program: {
        id: program.id,
        name: program.name,
        location: program.location,
        start_date: program.start_date,
        end_date: program.end_date,
      },
      total: counts.total,
      skips_breakfast: counts.skips_breakfast,
      people: people.map((p) => ({
        real_name: p.real_name,
        bible_name: p.bible_name,
        country: p.country,
        branch: p.branch,
        gender: p.gender,
        age: p.age,
        food_requirements: p.food_requirements,
        skips_breakfast: p.skips_breakfast,
        submitted: p.submitted,
      })),
    });
  } catch (err) {
    console.error('식사 제한 명단 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /programs/:id/tour-signups - 투어별 신청 상황 (담당자 전용)
//
// 대시보드의 "등록 완료" 카드를 대신한다. 완료 여부는 참가자 표 안에서
// 한 사람씩 보이므로 카드 하나를 통째로 쓸 일이 아니었고, 담당자가 정작
// 급히 알아야 하는 것은 **어느 투어가 얼마나 찼는가** 였다.
//
// 신청자가 없는 투어도 함께 준다. 아무도 신청하지 않은 투어가 목록에서
// 사라지면, 그것이야말로 담당자가 봐야 할 상황인데 보이지 않는다.
router.get(
  '/:id/tour-signups',
  requireAuth,
  requireProgramAdmin,
  requireScope('registration'),
  async (req, res) => {
    const programId = req.params.id;
    try {
      const [program] = await sql`
        SELECT id, name, location, start_date, end_date, currency
        FROM programs WHERE id = ${programId} AND is_active = true
      `;
      if (!program) {
        return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });
      }

      const options = await sql`
        SELECT id, name, cost, start_date, end_date, capacity,
               signup_deadline, contact_name
        FROM program_options
        WHERE program_id = ${programId} AND is_active = true
        ORDER BY start_date NULLS LAST, name
      `;

      // 신청자. 제출 여부로 거르지 않는다 — 아직 제출하지 않았어도 자리는
      // 잡아 둔 것이고, 담당자는 그 사람을 챙겨야 한다. 대신 완료 여부를
      // 함께 줘서 표에서 구분한다.
      const people = await sql`
        SELECT o.id AS option_id,
               r.id AS registration_id,
               r.real_name, r.bible_name, r.country, r.branch,
               r.gender, r.age, r.submitted
        FROM program_options o
        JOIN registrations r
          ON r.program_id = ${programId} AND o.id = ANY(r.selected_options)
        WHERE o.program_id = ${programId} AND o.is_active = true
          AND counts_as_participant(r.real_name, r.submitted)
        ORDER BY r.country NULLS LAST, r.real_name
      `;

      const byOption = new Map();
      for (const p of people) {
        if (!byOption.has(p.option_id)) byOption.set(p.option_id, []);
        byOption.get(p.option_id).push({
          registration_id: p.registration_id,
          real_name: p.real_name,
          bible_name: p.bible_name,
          country: p.country,
          branch: p.branch,
          gender: p.gender,
          age: p.age,
          submitted: p.submitted,
        });
      }

      res.json({
        program: {
          id: program.id,
          name: program.name,
          location: program.location,
          start_date: program.start_date,
          end_date: program.end_date,
          currency: program.currency,
        },
        tours: options.map((o) => {
          const list = byOption.get(o.id) ?? [];
          return {
            id: o.id,
            name: o.name,
            cost: o.cost,
            start_date: o.start_date,
            end_date: o.end_date,
            capacity: o.capacity,
            signup_deadline: o.signup_deadline,
            contact_name: o.contact_name,
            signup_count: list.length,
            submitted_count: list.filter((x) => x.submitted).length,
            // 정원이 없으면 잔여도 없다. 0 으로 주면 "다 찼다"로 읽힌다.
            remaining: o.capacity == null
              ? null
              : Math.max(0, o.capacity - list.length),
            people: list,
          };
        }),
      });
    } catch (err) {
      console.error('투어 신청 상황 조회 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

export default router;
