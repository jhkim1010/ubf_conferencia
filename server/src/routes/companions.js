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
      SELECT c.id, c.real_name, c.bible_name, c.gender, c.age, c.language,
             -- 적어 둔 값. 편집 화면이 이것을 쓴다 — 체크를 풀면 예전에
             -- 적은 값이 다시 보여야 한다.
             c.branch,
             c.same_branch_as_primary,
             -- 실제로 쓸 지부. 체크가 켜져 있으면 등록자의 것이다.
             -- 나중에 명단·내보내기가 동반자 지부를 읽을 때 낡은 값을
             -- 보지 않도록 여기서 미리 풀어 준다.
             CASE WHEN c.same_branch_as_primary THEN r.branch ELSE c.branch END
               AS effective_branch,
             c.same_flight_as_primary, c.arrival_flight, c.departure_flight,
             c.needs_pickup
      FROM companions c
      JOIN registrations r ON r.id = c.registration_id
      WHERE c.registration_id = ${regId}
      ORDER BY c.created_at ASC
    `;
    res.json(rows);
  } catch (err) {
    console.error('동반자 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PUT /companions/:programId/me — 내 동반자 목록 전체 교체
// body: { companions: [{ realName, bibleName, gender, age, language, branch,
//                         sameBranchAsPrimary, sameFlightAsPrimary,
//                         arrivalFlight, departureFlight, needsPickup }] }
//
// sameBranchAsPrimary 가 참이면 지부는 등록자의 것을 쓴다(032).
// branch 값 자체는 지우지 않는다 — 체크를 풀면 예전에 적은 값이 다시 보인다.
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
              same_branch_as_primary,
              same_flight_as_primary, arrival_flight, departure_flight, needs_pickup)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
           RETURNING id, real_name, bible_name, gender, age, language, branch,
                     same_branch_as_primary,
                     same_flight_as_primary, arrival_flight, departure_flight, needs_pickup`,
          [
            regId,
            String(c.realName).trim(),
            c.bibleName ?? null,
            c.gender ?? null,
            c.age ?? null,
            c.language ?? null,
            c.branch ?? null,
            c.sameBranchAsPrimary === true,
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
