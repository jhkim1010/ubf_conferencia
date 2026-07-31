// 봉사 참여 신청 (F8)
// 명세: .team/artifacts/A001-f8-service-signup.md
//
// 자격 판정은 **서버에서도 한다**. 클라이언트만 믿으면 우회가 된다.

import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

// 기본 항목 구성. 프로그램에 service_options 가 비어 있으면 이것을 쓴다(D3).
const DEFAULT_SERVICE_OPTIONS = [
  { key: 'special_song', enabled: true, requires_approval: false },
  { key: 'mc', enabled: true, requires_approval: false },
  { key: 'pickup', enabled: true, requires_approval: false },
  { key: 'cleaning', enabled: true, requires_approval: false },
  // D7: 지부장과 코디네이터의 동의하에 확정된다
  { key: 'group_study_leader', enabled: true, requires_approval: true },
  { key: 'other', enabled: true, requires_approval: false },
];

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

export default router;
