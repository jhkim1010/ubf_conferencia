import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin, requireScope } from '../middleware/auth.js';
import { isValidRoleKey } from '../services/service_roles.js';

/// 일정에 이을 봉사 역할(045). 모르는 값이면 잇지 않는다 — 알림에
/// "custom:9f2c…" 같은 것이 붙느니 안 붙는 편이 낫다.
function serviceKeyOf(v) {
  if (v === null || v === '') return null;
  return isValidRoleKey(v) ? v : null;
}

const router = Router();

// GET /schedules/:programId - 프로그램 일정 목록
router.get('/:programId', requireAuth, async (req, res) => {
  try {
    const schedules = await sql`
      SELECT id, title, description, scheduled_at, timezone, service_key,
             notification_sent, created_at
      FROM program_schedules
      WHERE program_id = ${req.params.programId}
      ORDER BY scheduled_at ASC
    `;
    res.json(schedules);
  } catch (err) {
    console.error('일정 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /schedules/:programId - 일정 추가 (admin 이상)
router.post('/:programId', requireAuth, requireProgramAdmin,
  requireScope('schedule'), async (req, res) => {
  const { title, description, scheduledAt, timezone } = req.body;
  const serviceKey = serviceKeyOf(req.body?.serviceKey);
  if (!title || !scheduledAt) {
    return res.status(400).json({ error: 'title과 scheduledAt이 필요합니다' });
  }

  try {
    const [schedule] = await sql`
      INSERT INTO program_schedules (program_id, title, description, scheduled_at, timezone, created_by, service_key)
      VALUES (
        ${req.params.programId},
        ${title},
        ${description ?? null},
        ${scheduledAt},
        ${timezone ?? 'UTC'},
        ${req.user.userId},
        ${serviceKey}
      )
      RETURNING id, title, description, scheduled_at, timezone, service_key, created_at
    `;
    res.status(201).json(schedule);
  } catch (err) {
    console.error('일정 추가 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /schedules/:programId/:scheduleId - 일정 수정 (admin 이상)
router.patch('/:programId/:scheduleId', requireAuth, requireProgramAdmin,
  requireScope('schedule'), async (req, res) => {
  const { title, description, scheduledAt, timezone } = req.body;
  // 본문에 없으면 그대로 둔다. 제목만 고치는 저장이 이어 둔 역할을 지우면
  // 안 된다. 빈 문자열은 "끊겠다" 는 뜻이다.
  const hasService = Object.prototype.hasOwnProperty.call(req.body, 'serviceKey');
  const serviceKey = hasService ? serviceKeyOf(req.body.serviceKey) : null;

  try {
    const [updated] = await sql`
      UPDATE program_schedules
      SET
        title        = COALESCE(${title ?? null}, title),
        description  = COALESCE(${description ?? null}, description),
        scheduled_at = COALESCE(${scheduledAt ?? null}::TIMESTAMPTZ, scheduled_at),
        timezone     = COALESCE(${timezone ?? null}, timezone),
        -- ::text 가 없으면 끊을 때(NULL) Postgres 가 형을 못 정해 저장이
        -- 통째로 실패한다. 값이 있을 때는 통과하므로 눈에 안 띈다.
        service_key  = CASE
          WHEN ${hasService} THEN ${serviceKey}::text
          ELSE service_key
        END,
        -- 시간 또는 타임존이 바뀌면 알림 재발송 허용
        -- ::형 없이 NULL 을 비교하면 Postgres 가 형을 못 정해 저장이 통째로
        -- 실패한다. 시각·타임존을 안 보내는 저장(제목만 고치기 등)이 전부
        -- 그랬는데, 값이 안 바뀌는 것이 정상처럼 보여 드러나지 않았다.
        notification_sent = CASE
          WHEN ${scheduledAt ?? null}::timestamptz IS NOT NULL
            OR ${timezone ?? null}::text IS NOT NULL THEN FALSE
          ELSE notification_sent
        END
      WHERE id = ${req.params.scheduleId}
        AND program_id = ${req.params.programId}
      RETURNING id, title, description, scheduled_at, timezone, service_key,
                notification_sent
    `;
    if (!updated) return res.status(404).json({ error: '일정을 찾을 수 없습니다' });
    res.json(updated);
  } catch (err) {
    console.error('일정 수정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /schedules/:programId/:scheduleId - 일정 삭제 (admin 이상)
router.delete('/:programId/:scheduleId', requireAuth, requireProgramAdmin,
  requireScope('schedule'), async (req, res) => {
  try {
    await sql`
      DELETE FROM program_schedules
      WHERE id = ${req.params.scheduleId}
        AND program_id = ${req.params.programId}
    `;
    res.json({ success: true });
  } catch (err) {
    console.error('일정 삭제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
