import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

async function myRegistrationId(userId, programId) {
  const [reg] = await sql`
    SELECT id FROM registrations
    WHERE program_id = ${programId} AND user_id = ${userId}
  `;
  return reg?.id ?? null;
}

// GET /companions/:programId/me — 내 동반자 목록
router.get('/:programId/me', requireAuth, async (req, res) => {
  try {
    const regId = await myRegistrationId(req.user.userId, req.params.programId);
    if (!regId) return res.json([]);
    const rows = await sql`
      SELECT id, real_name, bible_name, gender, age, language, branch,
             same_flight_as_primary, arrival_flight, departure_flight, needs_pickup
      FROM companions
      WHERE registration_id = ${regId}
      ORDER BY created_at ASC
    `;
    res.json(rows);
  } catch (err) {
    console.error('동반자 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PUT /companions/:programId/me — 내 동반자 목록 전체 교체
// body: { companions: [{ realName, bibleName, gender, age, language, branch,
//                         sameFlightAsPrimary, arrivalFlight, departureFlight, needsPickup }] }
router.put('/:programId/me', requireAuth, async (req, res) => {
  const list = Array.isArray(req.body.companions) ? req.body.companions : [];
  if (list.length > 15) {
    return res.status(400).json({ error: '동반자는 최대 15명까지입니다' });
  }
  try {
    const regId = await myRegistrationId(req.user.userId, req.params.programId);
    if (!regId) return res.status(403).json({ error: '이 프로그램에 먼저 등록하세요' });

    const saved = await sql.transaction(async (client) => {
      await client.query('DELETE FROM companions WHERE registration_id = $1', [regId]);
      const rows = [];
      for (const c of list) {
        if (!c.realName || !String(c.realName).trim()) continue; // 이름 없는 항목 건너뜀
        const { rows: [row] } = await client.query(
          `INSERT INTO companions
             (registration_id, real_name, bible_name, gender, age, language, branch,
              same_flight_as_primary, arrival_flight, departure_flight, needs_pickup)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
           RETURNING id, real_name, bible_name, gender, age, language, branch,
                     same_flight_as_primary, arrival_flight, departure_flight, needs_pickup`,
          [
            regId,
            String(c.realName).trim(),
            c.bibleName ?? null,
            c.gender ?? null,
            c.age ?? null,
            c.language ?? null,
            c.branch ?? null,
            c.sameFlightAsPrimary ?? true,
            c.arrivalFlight ? JSON.stringify(c.arrivalFlight) : null,
            c.departureFlight ? JSON.stringify(c.departureFlight) : null,
            c.needsPickup ?? true,
          ],
        );
        rows.push(row);
      }
      return rows;
    });

    res.json({ count: saved.length, companions: saved });
  } catch (err) {
    console.error('동반자 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
