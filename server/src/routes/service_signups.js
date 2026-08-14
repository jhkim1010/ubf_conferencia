// 봉사 참여 신청 (F8)
// 명세: .team/artifacts/A001-f8-service-signup.md
//
// 자격 판정은 **서버에서도 한다**. 클라이언트만 믿으면 우회가 된다.

import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';
import {
  DEFAULT_SERVICE_ROLES,
  canBroadcast,
  isOpenForMe,
  isValidRoleKey,
  normalizeServiceRoles,
  roleName,
  rolesOf,
  statusOnInvite,
  statusOnConfirm,
  statusOnRespond,
  sortRoles,
  tallyRole,
} from '../services/service_roles.js';
import {
  sendPushNotification,
  notifyAudience,
} from '../services/fcm.js';
import { audienceFromBody } from '../services/audience.js';
import { notifyProgramAdmins, notifyRegistrations } from '../services/telegram.js';

const router = Router();

// 기본 항목 구성은 service_roles.js 하나에 둔다(039). 예전에는 여기에도
// 같은 목록이 있었는데, 역할을 늘리면 한쪽만 늘어난다.
const DEFAULT_SERVICE_OPTIONS = DEFAULT_SERVICE_ROLES;

const SHEPHERD_MIN_YEARS = 5;

// 등록 + 사용자 + 프로그램을 한 번에 읽는다. 자격 판정에 셋 다 필요하다.
async function loadContext(programId, userId) {
  const [row] = await sql`
    SELECT
      r.id   AS registration_id,
      r.country,
      r.service_declined,
      p.host_country,
      p.service_options,
      u.church_role,
      u.shepherd_since,
      u.has_driver_license
    FROM programs p
    JOIN users u ON u.id = ${userId}
    LEFT JOIN registrations r
      ON r.program_id = p.id AND r.user_id = ${userId}
    WHERE p.id = ${programId} AND p.is_active = true
  `;
  return row ?? null;
}

// 자격 세 조건 중 하나라도 만족하면 대상이다.
function evaluateEligibility(ctx) {
  const reasons = [];

  if (
    ctx.host_country &&
    ctx.country &&
    ctx.country === ctx.host_country
  ) {
    reasons.push('domestic');
  }
  if (ctx.church_role === 'misionero') {
    reasons.push('missionary');
  }
  if (
    ctx.church_role === 'maestro_biblico' &&
    typeof ctx.shepherd_since === 'number' &&
    new Date().getFullYear() - ctx.shepherd_since >= SHEPHERD_MIN_YEARS
  ) {
    reasons.push('shepherd_5y');
  }

  return { eligible: reasons.length > 0, reasons };
}

function optionsOf(ctx) {
  const raw = Array.isArray(ctx.service_options) ? ctx.service_options : [];
  const opts = raw.length > 0 ? raw : DEFAULT_SERVICE_OPTIONS;
  return opts.filter((o) => o && o.enabled !== false);
}

// GET /service-signups/:programId/me — 자격 여부 + 항목 구성 + 내 신청
router.get('/:programId/me', requireAuth, async (req, res) => {
  try {
    const ctx = await loadContext(req.params.programId, req.user.userId);
    if (!ctx) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

    const { eligible, reasons } = evaluateEligibility(ctx);
    const options = optionsOf(ctx);

    const signups = ctx.registration_id
      ? await sql`
          SELECT service_key, status, note,
                 can_provide_vehicle, vehicle_seats, contact_window
          FROM service_signups
          WHERE registration_id = ${ctx.registration_id}
          ORDER BY created_at
        `
      : [];

    res.json({
      eligible,
      reasons,
      declined: ctx.service_declined ?? false,
      has_driver_license: ctx.has_driver_license ?? false,
      church_role: ctx.church_role,
      options,
      signups,
    });
  } catch (err) {
    console.error('봉사 신청 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PUT /service-signups/:programId/me — 신청 저장 (전체 교체)
router.put('/:programId/me', requireAuth, async (req, res) => {
  const items = Array.isArray(req.body?.items) ? req.body.items : null;
  if (!items) return res.status(400).json({ error: 'items 배열이 필요합니다' });

  try {
    const ctx = await loadContext(req.params.programId, req.user.userId);
    if (!ctx) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });
    if (!ctx.registration_id) {
      return res.status(409).json({ error: '먼저 등록을 진행해 주세요' });
    }

    // 자격 재검증 — 클라이언트를 믿지 않는다
    const { eligible } = evaluateEligibility(ctx);
    if (!eligible) return res.status(403).json({ error: '신청 대상이 아닙니다' });

    const options = optionsOf(ctx);
    const byKey = new Map(options.map((o) => [o.key, o]));

    for (const it of items) {
      const opt = byKey.get(it?.service_key);
      if (!opt) {
        return res
          .status(400)
          .json({ error: `사용할 수 없는 항목입니다: ${it?.service_key}` });
      }
      // 픽업은 운전면허 보유자만 (D5)
      if (it.service_key === 'pickup' && !ctx.has_driver_license) {
        return res
          .status(403)
          .json({ error: '픽업은 운전면허 보유자만 신청할 수 있습니다' });
      }
    }

    await sql.transaction(async (client) => {
      // 전체 교체 — 화면이 최종 선택 목록을 보낸다
      await client.query('DELETE FROM service_signups WHERE registration_id = $1', [
        ctx.registration_id,
      ]);

      for (const it of items) {
        const opt = byKey.get(it.service_key);
        // D7: 승인이 필요한 항목은 곧바로 확정되지 않는다
        const status = opt.requires_approval ? 'awaiting_approval' : 'applied';
        await client.query(
          `INSERT INTO service_signups
             (registration_id, service_key, status, note,
              can_provide_vehicle, vehicle_seats, contact_window)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            ctx.registration_id,
            it.service_key,
            status,
            it.note ?? null,
            it.service_key === 'pickup' ? (it.can_provide_vehicle ?? null) : null,
            it.service_key === 'pickup' ? (it.vehicle_seats ?? null) : null,
            it.contact_window ?? null,
          ],
        );
      }

      // 신청했으므로 거절 기록을 해제한다(D6 — 마음이 바뀌는 경우가 많다)
      await client.query(
        'UPDATE registrations SET service_declined = FALSE WHERE id = $1',
        [ctx.registration_id],
      );
    });

    const saved = await sql`
      SELECT service_key, status, note,
             can_provide_vehicle, vehicle_seats, contact_window
      FROM service_signups
      WHERE registration_id = ${ctx.registration_id}
      ORDER BY created_at
    `;
    res.json({ signups: saved });
  } catch (err) {
    console.error('봉사 신청 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /service-signups/:programId/decline — 이번에는 참여하지 않음 (D6)
router.post('/:programId/decline', requireAuth, async (req, res) => {
  try {
    const ctx = await loadContext(req.params.programId, req.user.userId);
    if (!ctx) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });
    if (!ctx.registration_id) {
      return res.status(409).json({ error: '먼저 등록을 진행해 주세요' });
    }

    await sql.transaction(async (client) => {
      await client.query('DELETE FROM service_signups WHERE registration_id = $1', [
        ctx.registration_id,
      ]);
      await client.query(
        'UPDATE registrations SET service_declined = TRUE WHERE id = $1',
        [ctx.registration_id],
      );
    });

    // 거절해도 스텝은 계속 접근 가능하다(D6). 되돌릴 수 있음을 응답으로 알린다.
    res.json({ declined: true, reversible: true });
  } catch (err) {
    console.error('봉사 신청 거절 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ═══════════════════════════════════════════════════════════════
//  담당자 쪽 (039)
//
//  015 는 참가자가 신청하는 데까지만 만들어 뒀다. 신청을 받아도 담당자가
//  볼 화면이 없어, 쌓이기만 하고 아무 일도 일어나지 않는 상태였다.
// ═══════════════════════════════════════════════════════════════

// 이 수양회의 봉사 신청 전부. service_signups 에는 program_id 가 없어
// registrations 를 거친다.
async function loadSignups(programId) {
  return sql`
    SELECT ss.id, ss.registration_id, ss.service_key, ss.status, ss.note,
           ss.is_lead, ss.invited_at, ss.responded_at,
           ss.can_provide_vehicle, ss.vehicle_seats, ss.contact_window,
           display_name(r.bible_name, r.real_name) AS real_name,
           r.bible_name, r.country, r.branch, r.gender, r.age,
           r.submitted
    FROM service_signups ss
    JOIN registrations r ON r.id = ss.registration_id
    WHERE r.program_id = ${programId}
      AND has_registrant_name(r.real_name)
    ORDER BY r.country NULLS LAST, r.real_name
  `;
}

function personOf(s) {
  return {
    id: s.id,
    registration_id: s.registration_id,
    real_name: s.real_name,
    bible_name: s.bible_name,
    country: s.country,
    branch: s.branch,
    gender: s.gender,
    age: s.age,
    submitted: s.submitted,
    status: s.status,
    is_lead: s.is_lead,
    note: s.note,
    invited_at: s.invited_at,
    responded_at: s.responded_at,
    can_provide_vehicle: s.can_provide_vehicle,
    vehicle_seats: s.vehicle_seats,
    contact_window: s.contact_window,
  };
}

// GET /service-signups/:programId/board — 역할별 배정 현황 (담당자 전용)
router.get(
  '/:programId/board',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    const programId = req.params.programId;
    try {
      const [program] = await sql`
        SELECT id, name, service_options
        FROM programs WHERE id = ${programId} AND is_active = true
      `;
      if (!program) {
        return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });
      }

      const signups = await loadSignups(programId);
      const callMap = await lastCalls(programId);
      const roles = rolesOf(program.service_options).filter(
        (r) => r.enabled !== false,
      );

      // 등록할 때 적어 낸 자원(009). **역할이 아니다** — 할 수 있다고 적어
      // 냈을 뿐이고, 누구에게 무엇을 맡길지는 담당자가 정한다. 그래서 역할
      // 목록과 섞지 않고 따로 내보낸다.
      const volunteers = await sql`
        SELECT r.id AS registration_id,
               display_name(r.bible_name, r.real_name) AS real_name,
               r.country, r.branch,
               r.volunteer_resources AS resources, r.volunteer_note AS note
        FROM registrations r
        WHERE r.program_id = ${programId}
          AND has_registrant_name(r.real_name)
          AND COALESCE(array_length(r.volunteer_resources, 1), 0) > 0
        ORDER BY r.real_name
      `;

      res.json({
        program: { id: program.id, name: program.name },
        volunteers,
        // 모자란 역할이 위로 온다 — 담당자가 화면을 열자마자 할 일을 본다.
        roles: sortRoles(roles, signups).map((role) => ({
          ...role,
          ...tallyRole(role, signups),
          // 언제 도움을 청했는지. 없으면 아직 보낸 적이 없다는 뜻이다.
          call: callMap.get(role.key) ?? null,
          people: signups
            .filter((s) => s.service_key === role.key)
            .map(personOf),
        })),
      });
    } catch (err) {
      console.error('봉사 배정 현황 조회 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// PUT /service-signups/:programId/roles — 역할 구성 저장 (담당자 전용)
router.put(
  '/:programId/roles',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    try {
      const roles = normalizeServiceRoles(req.body?.roles);
      await sql`
        UPDATE programs SET service_options = ${JSON.stringify(roles)}::jsonb
        WHERE id = ${req.params.programId}
      `;
      res.json({ ok: true, roles });
    } catch (err) {
      console.error('봉사 역할 구성 저장 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// 지명·확정·반려에 쓸 역할 정의를 찾는다.
async function findRole(programId, serviceKey) {
  const [program] = await sql`
    SELECT service_options FROM programs
    WHERE id = ${programId} AND is_active = true
  `;
  if (!program) return null;
  return rolesOf(program.service_options).find((r) => r.key === serviceKey) ?? null;
}

// POST /service-signups/:programId/invite — 참가자를 역할에 지명 (담당자 전용)
//
// 지명은 부탁이지 확정이 아니다. 본인이 수락해야 확정된다.
router.post(
  '/:programId/invite',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    const programId = req.params.programId;
    const { registrationId, serviceKey, serviceKeys } = req.body ?? {};

    // 한 사람에게 여러 가지를 부탁하는 일이 보통이다 — 운전도 하고 요리도
    // 하는 사람에게 둘을 따로 물으면 알림도 따로 간다. 한 번에 받는다.
    //
    // serviceKey 하나만 오는 예전 형태도 그대로 받는다.
    const keys = [
      ...new Set(
        (Array.isArray(serviceKeys) ? serviceKeys : [serviceKey]).filter(
          (k) => typeof k === 'string' && k !== '',
        ),
      ),
    ];

    if (keys.length === 0 || !keys.every(isValidRoleKey)) {
      return res.status(400).json({ error: '역할이 올바르지 않습니다' });
    }
    if (!registrationId) {
      return res.status(400).json({ error: 'registrationId 가 없습니다' });
    }

    try {
      // **하나라도 이 수양회에 없으면 전부 거절한다.** 일부만 들어가면
      // 담당자는 셋을 부탁한 줄 아는데 둘만 갔다는 것을 알 길이 없다.
      const roles = [];
      for (const key of keys) {
        const found = await findRole(programId, key);
        if (!found) {
          return res.status(400).json({ error: '이 수양회에 없는 역할입니다' });
        }
        roles.push(found);
      }

      // 다른 수양회의 등록을 지명할 수 없다.
      const [reg] = await sql`
        SELECT id, real_name, fcm_token, volunteer_resources
        FROM registrations
        WHERE id = ${registrationId} AND program_id = ${programId}
          AND has_registrant_name(real_name)
      `;
      if (!reg) {
        return res.status(404).json({ error: '참가자를 찾을 수 없습니다' });
      }

      // 이미 손을 든 역할. 자기가 신청해 둔 것을 담당자가 승인하는 경우
      // 다시 물을 이유가 없다.
      const mine = await sql`
        SELECT service_key FROM service_signups
        WHERE registration_id = ${registrationId} AND status = 'applied'
      `;
      const appliedKeys = new Set(mine.map((m) => m.service_key));

      // 이미 있으면 다시 지명한다. 거절했던 사람에게 다시 부탁하는 일은
      // 실제로 흔하다.
      const invited = [];
      for (const role of roles) {
        // 스스로 하겠다고 한 일이면 곧바로 맡기고, 아니면 물어본다.
        const next = statusOnInvite(role, {
          resources: reg.volunteer_resources,
          applied: appliedKeys.has(role.key),
        });
        const [row] = await sql`
          INSERT INTO service_signups (registration_id, service_key, status,
                                       invited_by, invited_at)
          VALUES (${registrationId}, ${role.key}, ${next},
                  ${req.user.leaderId ?? null}, NOW())
          ON CONFLICT (registration_id, service_key) DO UPDATE
            SET status = ${next},
                invited_by = ${req.user.leaderId ?? null},
                invited_at = NOW(),
                responded_at = NULL,
                updated_at = NOW()
          RETURNING id, status
        `;
        invited.push({ id: row.id, status: row.status, service_key: role.key });
      }

      // 알림이 실패해도 지명은 남는다. 알림 때문에 배정이 막히면 안 된다.
      //
      // **무엇을 부탁받았는지 알림에 적는다.** "봉사를 부탁드립니다" 만
      // 오면 앱을 열기 전까지는 무슨 일인지 모른다.
      //
      // 여럿을 부탁해도 **알림은 한 통** 이다. 역할마다 따로 보내면 세 번
      // 울리고, 세 번째쯤에는 아무도 읽지 않는다.
      const what = roles.map(roleName).join(', ');
      // **답을 기다리는 것과 알리는 것은 다른 말이다.** 스스로 하겠다고
      // 적어 낸 일을 두고 "수락해 주십시오" 라고 하면 무엇을 더 해야 하는
      // 줄 알고, 반대로 묻지도 않고 "맡기셨습니다" 라고 하면 하겠다고 한
      // 적 없는 일이 통보로 온다.
      const asking = invited.some((i) => i.status === 'invited');
      const title = asking ? '봉사 부탁' : '봉사 배정';
      const line = asking
        ? `${reg.real_name} 님, ${what} 을(를) 부탁드립니다. 앱에서 수락 여부를 알려 주십시오.`
        : `${reg.real_name} 님, 적어 주신 대로 ${what} 을(를) 맡아 주시게 되었습니다.`;
      if (reg.fcm_token) {
        sendPushNotification(
          [reg.fcm_token],
          title,
          line,
          { type: 'service_invite', programId, serviceKey: roles[0].key },
        ).catch((e) => console.error('봉사 지명 알림 실패:', e));
      }
      // 앱 푸시는 앱을 지웠거나 알림을 꺼 뒀거나 웹으로만 쓰는 사람에게는
      // 가지 않는다. 텔레그램을 연결해 둔 사람에게는 이쪽으로도 보낸다(047).
      notifyRegistrations(
        programId,
        [registrationId],
        `<b>${title}</b>\n${line}`,
      ).catch((e) => console.error('봉사 지명 텔레그램 실패:', e));

      console.log(`[SERVICE] 지명 | programId=${programId} keys=${keys.join(',')} registrationId=${registrationId} leaderId=${req.user.leaderId}`);
      // id·status 는 예전 형태 그대로 둔다(첫 번째). 여럿을 부탁한 경우는
      // invited 로 전부 온다.
      res.status(201).json({
        id: invited[0].id,
        status: invited[0].status,
        invited,
      });
    } catch (err) {
      console.error('봉사 지명 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// PATCH /service-signups/:programId/:signupId — 확정 · 반려 · 책임자 (담당자 전용)
router.patch(
  '/:programId/:signupId',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    const { programId, signupId } = req.params;
    const { action, isLead } = req.body ?? {};

    try {
      const [row] = await sql`
        SELECT ss.id, ss.service_key, ss.status
        FROM service_signups ss
        JOIN registrations r ON r.id = ss.registration_id
        WHERE ss.id = ${signupId} AND r.program_id = ${programId}
      `;
      if (!row) return res.status(404).json({ error: '신청을 찾을 수 없습니다' });

      if (typeof isLead === 'boolean') {
        // 책임자는 역할마다 한 명이다. 새로 세우면 기존 책임자를 내린다.
        if (isLead) {
          await sql`
            UPDATE service_signups ss
            SET is_lead = false, updated_at = NOW()
            FROM registrations r
            WHERE r.id = ss.registration_id
              AND r.program_id = ${programId}
              AND ss.service_key = ${row.service_key}
          `;
        }
        await sql`
          UPDATE service_signups
          SET is_lead = ${isLead}, updated_at = NOW()
          WHERE id = ${signupId}
        `;
      }

      if (action) {
        if (!['confirm', 'reject'].includes(action)) {
          return res.status(400).json({ error: 'action 은 confirm 또는 reject 여야 합니다' });
        }
        const role = await findRole(programId, row.service_key);
        const next = action === 'confirm'
          ? statusOnConfirm(role)
          : 'rejected';
        await sql`
          UPDATE service_signups
          SET status = ${next}, updated_at = NOW()
          WHERE id = ${signupId}
        `;
        console.log(`[SERVICE] ${action} | programId=${programId} signupId=${signupId} → ${next} leaderId=${req.user.leaderId}`);
        return res.json({ ok: true, status: next });
      }

      const [after] = await sql`
        SELECT status, is_lead FROM service_signups WHERE id = ${signupId}
      `;
      res.json({ ok: true, status: after.status, is_lead: after.is_lead });
    } catch (err) {
      console.error('봉사 배정 변경 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// GET /service-signups/:programId/invites — 나에게 온 부탁 (참가자)
router.get('/:programId/invites', requireAuth, async (req, res) => {
  try {
    const rows = await sql`
      SELECT ss.id, ss.service_key, ss.status, ss.is_lead
      FROM service_signups ss
      JOIN registrations r ON r.id = ss.registration_id
      WHERE r.program_id = ${req.params.programId}
        AND r.user_id = ${req.user.userId}
      ORDER BY ss.invited_at DESC NULLS LAST
    `;

    // 자유 역할(custom:)의 이름을 함께 준다. 키만 주면 화면이 "기타" 라고
    // 부른다 — 무엇을 부탁받았는지 모른 채 수락하게 된다.
    const [program] = await sql`
      SELECT service_options FROM programs
      WHERE id = ${req.params.programId} AND is_active = true
    `;
    const byKey = new Map(
      rolesOf(program?.service_options).map((r) => [r.key, r]),
    );

    res.json(rows.map((r) => ({
      ...r,
      label: byKey.get(r.service_key)?.label ?? null,
      requires_approval: byKey.get(r.service_key)?.requires_approval === true,
    })));
  } catch (err) {
    console.error('봉사 부탁 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /service-signups/:programId/:signupId/respond — 수락 · 거절 (본인)
router.post('/:programId/:signupId/respond', requireAuth, async (req, res) => {
  const { programId, signupId } = req.params;
  const accepted = req.body?.accepted === true;

  try {
    // **본인 것만** 답할 수 있다. registration 을 거쳐 사용자까지 확인한다.
    const [row] = await sql`
      SELECT ss.id, ss.service_key, ss.status
      FROM service_signups ss
      JOIN registrations r ON r.id = ss.registration_id
      WHERE ss.id = ${signupId}
        AND r.program_id = ${programId}
        AND r.user_id = ${req.user.userId}
    `;
    if (!row) return res.status(404).json({ error: '부탁을 찾을 수 없습니다' });

    if (row.status !== 'invited') {
      return res.status(409).json({
        error: '이미 처리된 부탁입니다',
        status: row.status,
      });
    }

    const role = await findRole(programId, row.service_key);
    const next = statusOnRespond(role, accepted);
    await sql`
      UPDATE service_signups
      SET status = ${next}, responded_at = NOW(), updated_at = NOW()
      WHERE id = ${signupId}
    `;
    console.log(`[SERVICE] 응답 | programId=${programId} signupId=${signupId} accepted=${accepted} → ${next}`);
    res.json({ ok: true, status: next });
  } catch (err) {
    console.error('봉사 응답 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ═══════════════════════════════════════════════════════════════
//  도움 요청 (043)
//
//  한 사람씩 지명하는 길뿐이면, 여섯 자리가 빈 역할은 여섯 번을 찍어
//  물어야 한다. 전체에 한 번 알리고 손을 든 사람 중에서 고르는 편이 빠르다.
// ═══════════════════════════════════════════════════════════════

// 이 수양회의 열린 요청(닫지 않은 것) 중 역할별 마지막 것.
async function lastCalls(programId) {
  const rows = await sql`
    SELECT DISTINCT ON (service_key)
           id, service_key, message, short_at_send, sent_at, closed_at
    FROM service_calls
    WHERE program_id = ${programId}
    ORDER BY service_key, sent_at DESC
  `;
  return new Map(rows.map((r) => [r.service_key, r]));
}

// POST /service-signups/:programId/calls — 전체에게 도움을 청한다 (담당자)
router.post(
  '/:programId/calls',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    const programId = req.params.programId;
    const { serviceKey, message } = req.body ?? {};

    // 받을 사람(044). 안 보내면 전체다. 이상한 값이면 **아무에게도 보내지
    // 않는다** — 한 방에만 보내려던 것이 전원에게 가는 쪽이 가장 나쁘다.
    const audience = audienceFromBody(req.body);
    if (audience === null) {
      return res.status(400).json({ error: '보낼 대상이 올바르지 않습니다' });
    }

    try {
      const [program] = await sql`
        SELECT id, name, service_options FROM programs
        WHERE id = ${programId} AND is_active = true
      `;
      if (!program) {
        return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });
      }

      const role = rolesOf(program.service_options).find(
        (r) => r.key === serviceKey,
      );
      const signups = await loadSignups(programId);
      const tally = role ? tallyRole(role, signups) : null;
      const calls = await lastCalls(programId);

      const verdict = canBroadcast({
        role,
        tally,
        lastCall: calls.get(serviceKey),
      });
      if (!verdict.ok) {
        // 왜 못 보내는지 말해 준다. 아무 일도 안 일어나면 담당자는 버튼이
        // 고장 났다고 여긴다.
        return res.status(409).json({ error: verdict.reason, ...verdict });
      }

      const [call] = await sql`
        INSERT INTO service_calls (program_id, service_key, message,
                                   short_at_send, sent_by)
        VALUES (${programId}, ${serviceKey},
                ${(message ?? '').trim() || null}, ${tally.short},
                ${req.user.leaderId ?? null})
        RETURNING id, service_key, short_at_send, sent_at
      `;

      // 알림이 실패해도 요청 자체는 남는다. 알림 때문에 기록이 사라지면
      // 담당자는 보냈는지 안 보냈는지 알 수 없다.
      const title = program.name;
      const bodyText = (message ?? '').trim()
        || `봉사자를 찾습니다 — ${tally.short}자리`;
      notifyAudience(sql, programId, audience, title, bodyText, {
        type: 'service_call',
        programId,
        serviceKey,
      }).catch((e) => console.error('봉사 요청 알림 실패:', e));
      notifyProgramAdmins(
        programId,
        `[봉사] ${serviceKey} — ${tally.short}자리 도움 요청을 보냈습니다`,
      ).catch((e) => console.error('봉사 요청 텔레그램 실패:', e));

      console.log(`[SERVICE] 도움요청 | programId=${programId} key=${serviceKey} short=${tally.short} leaderId=${req.user.leaderId}`);
      res.status(201).json(call);
    } catch (err) {
      console.error('봉사 도움 요청 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// PATCH /service-signups/:programId/calls/:callId — 요청 닫기 (담당자)
router.patch(
  '/:programId/calls/:callId',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    try {
      // 채워졌는데도 알림이 남아 있으면 참가자 화면에 쓸데없는 부탁이
      // 계속 떠 있다.
      const [row] = await sql`
        UPDATE service_calls SET closed_at = NOW()
        WHERE id = ${req.params.callId} AND program_id = ${req.params.programId}
          AND closed_at IS NULL
        RETURNING id, closed_at
      `;
      if (!row) return res.status(404).json({ error: '요청을 찾을 수 없습니다' });
      res.json(row);
    } catch (err) {
      console.error('봉사 요청 닫기 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// GET /service-signups/:programId/open — 나에게 열려 있는 모집 (참가자)
router.get('/:programId/open', requireAuth, async (req, res) => {
  const programId = req.params.programId;
  try {
    const [program] = await sql`
      SELECT service_options FROM programs
      WHERE id = ${programId} AND is_active = true
    `;
    if (!program) return res.json([]);

    const [me] = await sql`
      SELECT id FROM registrations
      WHERE program_id = ${programId} AND user_id = ${req.user.userId}
    `;
    const mine = me
      ? await sql`
          SELECT service_key, status FROM service_signups
          WHERE registration_id = ${me.id}
        `
      : [];
    const myStatus = new Map(mine.map((r) => [r.service_key, r.status]));

    const signups = await loadSignups(programId);
    const calls = await lastCalls(programId);
    const roles = rolesOf(program.service_options).filter(
      (r) => r.enabled !== false,
    );

    const open = roles
      .map((role) => ({
        role,
        tally: tallyRole(role, signups),
        call: calls.get(role.key),
      }))
      .filter(({ role, tally, call }) =>
        isOpenForMe({ call, tally, myStatus: myStatus.get(role.key) }))
      .map(({ role, tally, call }) => ({
        service_key: role.key,
        label: role.label ?? null,
        requires_approval: role.requires_approval === true,
        short: tally.short,
        needed: tally.needed,
        message: call.message,
        sent_at: call.sent_at,
      }));

    res.json(open);
  } catch (err) {
    console.error('봉사 모집 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /service-signups/:programId/apply — 제가 하겠습니다 (참가자)
//
// 손을 든 것이지 확정이 아니다. 고르는 것은 담당자의 몫이다(039).
router.post('/:programId/apply', requireAuth, async (req, res) => {
  const programId = req.params.programId;
  const { serviceKey } = req.body ?? {};

  if (!isValidRoleKey(serviceKey)) {
    return res.status(400).json({ error: '역할이 올바르지 않습니다' });
  }
  try {
    const [me] = await sql`
      SELECT id, real_name FROM registrations
      WHERE program_id = ${programId} AND user_id = ${req.user.userId}
        AND has_registrant_name(real_name)
    `;
    if (!me) {
      return res.status(404).json({ error: '먼저 등록해 주십시오' });
    }
    const role = await findRole(programId, serviceKey);
    if (!role) {
      return res.status(400).json({ error: '이 수양회에 없는 역할입니다' });
    }

    const [row] = await sql`
      INSERT INTO service_signups (registration_id, service_key, status)
      VALUES (${me.id}, ${serviceKey}, 'applied')
      ON CONFLICT (registration_id, service_key) DO UPDATE
        SET status = 'applied', updated_at = NOW()
      RETURNING id, status
    `;

    notifyProgramAdmins(
      programId,
      `[봉사] ${me.real_name} 님이 ${serviceKey} 에 손을 들었습니다`,
    ).catch((e) => console.error('봉사 지원 알림 실패:', e));

    console.log(`[SERVICE] 지원 | programId=${programId} key=${serviceKey} registrationId=${me.id}`);
    res.status(201).json(row);
  } catch (err) {
    console.error('봉사 지원 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
