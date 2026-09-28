import { Router } from 'express';
import { defaultOccupiesBed } from '../services/companion_role.js';
import { recountRegistrationTotal } from '../services/registration_recount.js';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

/// 보내온 참가비 몫을 다듬는다. 0~1 밖이거나 숫자가 아니면 NULL 이다 —
/// 못 알아들은 값을 0 으로 읽으면 안 받게 되고, 1 로 읽으면 더 받게 된다.
/// 둘 다 조용히 틀리는 것보다 "정책대로" 로 돌아가는 편이 낫다.
function feeShareOf(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0 || n > 1) return null;
  return n;
}

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
             -- 069: 이 사람이 따로 등록하는가, 침대를 쓰는가.
             c.registers_separately, c.occupies_bed,
             -- 073: 이 사람만 달리 정한 참가비 몫. NULL 이면 수양회 정책대로.
             c.fee_share,
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
              same_flight_as_primary, arrival_flight, departure_flight, needs_pickup,
              registers_separately, occupies_bed, fee_share)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
           RETURNING id, real_name, bible_name, gender, age, language, branch,
                     same_branch_as_primary,
                     same_flight_as_primary, arrival_flight, departure_flight, needs_pickup,
                     registers_separately, occupies_bed, fee_share`,
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
            // 069. 안 보내면 예전 뜻 그대로 — 따로 등록하는 동반자다.
            c.registersSeparately !== false,
            // 침대는 **적어 낸 값이 먼저**다. 안 보냈을 때만 나이로 정한다
            // (만 5세 이하는 안 쓰는 것으로).
            typeof c.occupiesBed === 'boolean'
              ? c.occupiesBed
              : defaultOccupiesBed(c.age),
            // 073. 참가비 몫을 **사람별로** 달리 정한 경우에만 값이 있다.
            // 안 보내면 NULL 이고, 그때는 수양회가 정한 나이 구간을 따른다.
            // 0 은 NULL 과 다르다 — "이 아이는 안 받기로 정했다" 이다.
            feeShareOf(c.feeShare),
          ],
        );
        rows.push(row);
      }
      return rows;
    });

    // 동반자가 바뀌면 낼 돈도 바뀐다(073) — 어린이 참가비가 붙고, 침대를
    // 쓰는 사람이 늘면 숙박비도 는다(069). 등록 라우트는 요청 본문으로
    // 계산하므로 여기를 안 거치면 아이를 더해도 금액이 그대로다.
    //
    // 트랜잭션 **밖**에서 한다. 낼 돈을 못 고쳐도 동반자 저장 자체는
    // 살아남아야 한다 — 이름을 적어 둔 것이 사라지는 쪽이 더 나쁘다.
    let totalCost = null;
    try {
      totalCost = await recountRegistrationTotal(regId);
    } catch (err) {
      console.error('동반자 저장 후 낼 돈 재계산 실패:', err);
    }

    res.json({ count: saved.length, companions: saved, totalCost });
  } catch (err) {
    console.error('동반자 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
