import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';

const router = Router();

// GET /schedules/:programId - 프로그램 일정 목록
router.get('/:programId', requireAuth, async (req, res) => {
  try {
    const schedules = await sql`
      SELECT id, title, description, scheduled_at, timezone, notification_sent, created_at
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
router.post('/:programId', requireAuth, requireProgramAdmin, async (req, res) => {
  const { title, description, scheduledAt, timezone } = req.body;
  if (!title || !scheduledAt) {
    return res.status(400).json({ error: 'title과 scheduledAt이 필요합니다' });
  }

  try {
    const [schedule] = await sql`
      INSERT INTO program_schedules (program_id, title, description, scheduled_at, timezone, created_by)
      VALUES (
        ${req.params.programId},
        ${title},
        ${description ?? null},
        ${scheduledAt},
        ${timezone ?? 'UTC'},
        ${req.user.userId}
      )
      RETURNING id, title, description, scheduled_at, timezone, created_at
    `;
    res.status(201).json(schedule);
  } catch (err) {
    console.error('일정 추가 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /schedules/:programId/:scheduleId - 일정 수정 (admin 이상)
router.patch('/:programId/:scheduleId', requireAuth, requireProgramAdmin, async (req, res) => {
  const { title, description, scheduledAt, timezone } = req.body;

  try {
    const [updated] = await sql`
      UPDATE program_schedules
      SET
        title        = COALESCE(${title ?? null}, title),
        description  = COALESCE(${description ?? null}, description),
        scheduled_at = COALESCE(${scheduledAt ?? null}::TIMESTAMPTZ, scheduled_at),
        timezone     = COALESCE(${timezone ?? null}, timezone),
        -- 시간 또는 타임존이 바뀌면 알림 재발송 허용
        notification_sent = CASE
          WHEN ${scheduledAt ?? null} IS NOT NULL OR ${timezone ?? null} IS NOT NULL THEN FALSE
          ELSE notification_sent
        END
      WHERE id = ${req.params.scheduleId}
        AND program_id = ${req.params.programId}
      RETURNING id, title, description, scheduled_at, timezone, notification_sent
    `;
    if (!updated) return res.status(404).json({ error: '일정을 찾을 수 없습니다' });
    res.json(updated);
  } catch (err) {
    console.error('일정 수정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /schedules/:programId/:scheduleId - 일정 삭제 (admin 이상)
router.delete('/:programId/:scheduleId', requireAuth, requireProgramAdmin, async (req, res) => {
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
