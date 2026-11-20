import { Router } from 'express';
import { listCompanions, saveCompanionList } from '../services/companion_save.js';
import { recountRegistrationTotal } from '../services/registration_recount.js';
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
    const rows = await listCompanions(regId);
    res.json(rows);
  } catch (err) {
    console.error('동반자 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PUT /companions/:programId/me — 내 동반자 목록 전체 교체
// body: { companions: [{ id?, realName, bibleName, gender, age, language, branch,
//                         sameBranchAsPrimary, sameFlightAsPrimary,
//                         arrivalFlight, departureFlight, needsPickup,
//                         registersSeparately, occupiesBed, sharesRoom,
//                         studyGroup, feeShare }] }
//
// 투어(tour_ids)는 여기서 안 바꾼다 — PUT /:programId/me/tours/:optionId.
//
// id 는 GET 이 준 것이다. 있으면 그 줄을 고치고, 없으면 새로 넣고, 목록에서
// 빠진 줄은 지운다(078).
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

    const saved = await saveCompanionList(regId, list);

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

// PUT /companions/:programId/me/tours/:optionId — 이 투어에 함께 가는 동반자
// body: { companionIds: [...] }
//
// 대표자가 투어를 고를 때 "함께 오시는 분도 가십니까?" 에 답한 것이다(080).
// 이 투어에 대해서만 바꾼다 — 목록에 있는 동반자는 넣고, 없는 동반자는 뺀다.
// 다른 투어의 선택은 건드리지 않는다.
router.put('/:programId/me/tours/:optionId', requireAuth, async (req, res) => {
  const { programId, optionId } = req.params;
  const ids = Array.isArray(req.body.companionIds)
    ? req.body.companionIds.filter((x) => typeof x === 'string')
    : [];
  try {
    const regId = await myRegistrationId(req.user.userId, programId);
    if (!regId) return res.status(403).json({ error: '이 프로그램에 먼저 등록하세요' });
    const [opt] = await sql`
      SELECT id FROM program_options WHERE id = ${optionId} AND program_id = ${programId}
    `;
    if (!opt) return res.status(404).json({ error: '투어를 찾을 수 없습니다' });

    await sql.transaction(async (client) => {
      await client.query(
        `UPDATE companions SET tour_ids = array_remove(tour_ids, $2::uuid)
          WHERE registration_id = $1`,
        [regId, optionId],
      );
      // 이 등록의, 함께 등록한 동반자만. 남의 id 나 따로 등록하는 분은 무시한다.
      await client.query(
        `UPDATE companions SET tour_ids = array_append(tour_ids, $2::uuid)
          WHERE registration_id = $1
            AND registers_separately = false
            AND id::text = ANY($3::text[])`,
        [regId, optionId, ids],
      );
    });

    let totalCost = null;
    try {
      totalCost = await recountRegistrationTotal(regId);
    } catch (err) {
      console.error('투어 동반자 저장 후 낼 돈 재계산 실패:', err);
    }
    const rows = await sql`
      SELECT id, tour_ids FROM companions WHERE registration_id = ${regId}
    `;
    res.json({ companions: rows, totalCost });
  } catch (err) {
    console.error('투어 동반자 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
