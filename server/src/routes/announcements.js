// 공지 보내기 (044)
//
// 알림을 보낼 길이 일정 알림(자동)과 봉사 도움 요청(043)뿐이었다.
// "302호 물이 안 나옵니다", "3조는 강당 앞으로" 같은 말은 전할 데가 없어
// 단톡방으로 나가고, 앱에만 등록하고 단톡방에 없는 사람에게는 닿지 않는다.

import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';
import { notifyAudience } from '../services/fcm.js';
import { notifyProgramAdmins } from '../services/telegram.js';
import { audienceFromBody } from '../services/audience.js';

const router = Router();

const MAX_TITLE = 80;
const MAX_BODY = 1000;

function clean(v, max) {
  const s = typeof v === 'string' ? v.trim() : '';
  return s.length > max ? s.slice(0, max) : s;
}

// GET /announcements/:programId — 지난 공지 (담당자)
router.get('/:programId', requireAuth, requireProgramAdmin, async (req, res) => {
  try {
    const rows = await sql`
      SELECT id, title, body, audience_kind, audience_id, recipients, sent_at
      FROM announcements
      WHERE program_id = ${req.params.programId}
      ORDER BY sent_at DESC
      LIMIT 50
    `;
    res.json(rows);
  } catch (err) {
    console.error('공지 목록 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /announcements/:programId — 공지 보내기 (담당자)
router.post('/:programId', requireAuth, requireProgramAdmin, async (req, res) => {
  const programId = req.params.programId;
  const title = clean(req.body?.title, MAX_TITLE);
  const body = clean(req.body?.body, MAX_BODY);

  if (body === '') {
    return res.status(400).json({ error: '보낼 내용이 없습니다' });
  }

  // 이상한 대상이면 **아무에게도 보내지 않는다.** 한 방에만 보내려던 공지가
  // 전원에게 가는 쪽이 가장 나쁘다.
  const audience = audienceFromBody(req.body);
  if (audience === null) {
    return res.status(400).json({ error: '보낼 대상이 올바르지 않습니다' });
  }

  try {
    const [program] = await sql`
      SELECT id, name FROM programs
      WHERE id = ${programId} AND is_active = true
    `;
    if (!program) {
      return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });
    }

    // 방·조가 이 수양회의 것인지 본다. 남의 수양회 id 로 보내면 그쪽
    // 사람들에게 알림이 간다.
    if (audience.kind === 'room') {
      const [room] = await sql`
        SELECT id FROM rooms
        WHERE id = ${audience.id} AND program_id = ${programId}
      `;
      if (!room) return res.status(404).json({ error: '방을 찾을 수 없습니다' });
    }
    if (audience.kind === 'group') {
      const [group] = await sql`
        SELECT id FROM groups
        WHERE id = ${audience.id} AND program_id = ${programId}
      `;
      if (!group) return res.status(404).json({ error: '조를 찾을 수 없습니다' });
    }

    // 보낸 뒤에 기록하지 않는다 — 알림이 늦거나 실패해도 보낸 사실은 남아야
    // 하고, 담당자가 같은 공지를 두 번 보내지 않으려면 기록이 먼저다.
    const sent = await notifyAudience(
      sql,
      programId,
      audience,
      title || program.name,
      body,
      { type: 'announcement', programId },
    );

    const [row] = await sql`
      INSERT INTO announcements (program_id, title, body, audience_kind,
                                 audience_id, recipients, sent_by)
      VALUES (${programId}, ${title || null}, ${body}, ${audience.kind},
              ${audience.id ?? null}, ${sent}, ${req.user.leaderId ?? null})
      RETURNING id, title, body, audience_kind, audience_id, recipients, sent_at
    `;

    notifyProgramAdmins(programId, { key: 'admAnnouncement', params: { body } }).catch((e) =>
      console.error('공지 텔레그램 실패:', e),
    );

    console.log(`[ANNOUNCE] programId=${programId} kind=${audience.kind} recipients=${sent} leaderId=${req.user.leaderId}`);
    res.status(201).json(row);
  } catch (err) {
    console.error('공지 보내기 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
