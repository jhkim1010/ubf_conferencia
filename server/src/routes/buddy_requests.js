import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

// 현재 사용자의 이 프로그램 등록 정보 (id, gender)
async function myRegistration(userId, programId) {
  const [reg] = await sql`
    SELECT id, gender FROM registrations
    WHERE program_id = ${programId} AND user_id = ${userId}
  `;
  return reg ?? null;
}

// GET /buddy-requests/:programId/candidates — 지목 후보(나 제외한 등록자)
router.get('/:programId/candidates', requireAuth, async (req, res) => {
  const { programId } = req.params;
  try {
    const me = await myRegistration(req.user.userId, programId);
    const rows = await sql`
      SELECT id, real_name, bible_name, gender, branch, country
      FROM registrations
      WHERE program_id = ${programId}
        AND real_name IS NOT NULL AND real_name <> ''
        AND id <> ${me?.id ?? '00000000-0000-0000-0000-000000000000'}
      ORDER BY real_name ASC
    `;
    res.json(rows);
  } catch (err) {
    console.error('지목 후보 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /buddy-requests/:programId/me — 내가 보낸/받은 요청
router.get('/:programId/me', requireAuth, async (req, res) => {
  const { programId } = req.params;
  try {
    const me = await myRegistration(req.user.userId, programId);
    if (!me) return res.json({ sent: [], received: [] });

    const sent = await sql`
      SELECT br.id, br.kind, br.status, br.to_registration_id AS "otherId",
             r.real_name AS "otherName", r.bible_name AS "otherBibleName",
             r.gender AS "otherGender", r.branch AS "otherBranch"
      FROM buddy_requests br
      JOIN registrations r ON r.id = br.to_registration_id
      WHERE br.from_registration_id = ${me.id}
      ORDER BY br.created_at DESC
    `;
    const received = await sql`
      SELECT br.id, br.kind, br.status, br.from_registration_id AS "otherId",
             r.real_name AS "otherName", r.bible_name AS "otherBibleName",
             r.gender AS "otherGender", r.branch AS "otherBranch"
      FROM buddy_requests br
      JOIN registrations r ON r.id = br.from_registration_id
      WHERE br.to_registration_id = ${me.id}
      ORDER BY br.created_at DESC
    `;
    res.json({ sent, received });
  } catch (err) {
    console.error('내 요청 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /buddy-requests/:programId — 요청 보내기 { toRegistrationId, kind }
router.post('/:programId', requireAuth, async (req, res) => {
  const { programId } = req.params;
  const { toRegistrationId, kind } = req.body;
  if (!toRegistrationId || !['roommate', 'group'].includes(kind)) {
    return res.status(400).json({ error: 'toRegistrationId와 유효한 kind가 필요합니다' });
  }

  try {
    const me = await myRegistration(req.user.userId, programId);
    if (!me) return res.status(403).json({ error: '이 프로그램에 먼저 등록하세요' });
    if (me.id === toRegistrationId) {
      return res.status(422).json({ error: '자기 자신은 지목할 수 없습니다' });
    }

    const [target] = await sql`
      SELECT id, gender FROM registrations
      WHERE id = ${toRegistrationId} AND program_id = ${programId}
    `;
    if (!target) return res.status(404).json({ error: '대상을 찾을 수 없습니다' });

    // 룸메이트 요청은 같은 성별만 (단체실 혼숙 방침) — 부부/가족은 동반자 기능으로 처리
    if (kind === 'roommate' && me.gender && target.gender && me.gender !== target.gender) {
      return res.status(422).json({
        error: '룸메이트는 같은 성별에게만 요청할 수 있습니다',
      });
    }

    const [created] = await sql`
      INSERT INTO buddy_requests (program_id, from_registration_id, to_registration_id, kind)
      VALUES (${programId}, ${me.id}, ${toRegistrationId}, ${kind})
      ON CONFLICT (from_registration_id, to_registration_id, kind)
      DO UPDATE SET status = 'pending', updated_at = NOW()
      RETURNING id, kind, status
    `;
    res.status(201).json(created);
  } catch (err) {
    console.error('지목 요청 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /buddy-requests/:programId/:id/:action — accept | decline (받은 사람만)
router.patch('/:programId/:id/:action', requireAuth, async (req, res) => {
  const { programId, id, action } = req.params;
  if (!['accept', 'decline'].includes(action)) {
    return res.status(400).json({ error: 'action은 accept 또는 decline' });
  }
  const status = action === 'accept' ? 'accepted' : 'declined';

  try {
    const me = await myRegistration(req.user.userId, programId);
    if (!me) return res.status(403).json({ error: '권한이 없습니다' });

    const [updated] = await sql`
      UPDATE buddy_requests
      SET status = ${status}, updated_at = NOW()
      WHERE id = ${id} AND program_id = ${programId}
        AND to_registration_id = ${me.id}
        AND status = 'pending'
      RETURNING id, kind, status
    `;
    if (!updated) {
      return res.status(404).json({ error: '처리할 요청을 찾을 수 없습니다' });
    }
    res.json(updated);
  } catch (err) {
    console.error('요청 처리 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /buddy-requests/:programId/:id — 내가 보낸 요청 취소 (보낸 사람만)
router.delete('/:programId/:id', requireAuth, async (req, res) => {
  const { programId, id } = req.params;
  try {
    const me = await myRegistration(req.user.userId, programId);
    if (!me) return res.status(403).json({ error: '권한이 없습니다' });
    await sql`
      DELETE FROM buddy_requests
      WHERE id = ${id} AND program_id = ${programId}
        AND from_registration_id = ${me.id}
    `;
    res.json({ success: true });
  } catch (err) {
    console.error('요청 취소 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
