// 동반자 목록 저장 (078)
//
// 참가자 본인(PUT /companions/:programId/me)과 담당자(PUT /programs/:id/
// registrations/:registrationId/companions)가 **같은 함수**로 저장한다. 두 벌로
// 두면 한쪽만 고쳐져, 담당자가 고친 동반자의 침대·분반이 다르게 들어간다.
//
// 지우고 다시 넣지 않는다 — 받은 id 가 이 등록의 것이면 그 줄을 고친다.
// 그래야 담당자가 잡아 둔 방·차·조가 살아남는다(planCompanionSave).
//
// 낼 돈은 여기서 다시 세지 않는다. 부르는 쪽이 트랜잭션 **밖**에서
// recountRegistrationTotal 을 부른다 — 셈이 실패해도 적은 이름은 남아야 한다.

import { sql } from '../db.js';
import { nameKey } from './room_occupant.js';
import {
  defaultOccupiesBed,
  planCompanionSave,
  studyGroupOf,
} from './companion_role.js';

/// 보내온 참가비 몫을 다듬는다. 0~1 밖이거나 숫자가 아니면 NULL 이다 —
/// 못 알아들은 값을 0 으로 읽으면 안 받게 되고, 1 로 읽으면 더 받게 된다.
/// 둘 다 조용히 틀리는 것보다 "정책대로" 로 돌아가는 편이 낫다.
function feeShareOf(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0 || n > 1) return null;
  return n;
}

/// 등록 [regId] 의 동반자를 [list] 로 맞춘다. 저장된 줄들을 보낸 순서대로 돌려준다.
export async function saveCompanionList(regId, list) {
  return sql.transaction(async (client) => {
    // 지우고 다시 넣지 않는다(078). 받은 id 가 이 등록의 것이면 그 줄을
    // 고친다 — 그래야 담당자가 잡아 둔 방·차·조가 살아남는다.
    const { rows: existing } = await client.query(
      'SELECT id FROM companions WHERE registration_id = $1',
      [regId],
    );
    const plan = planCompanionSave(
      existing.map((r) => r.id),
      list,
    );
    if (plan.drop.length > 0) {
      await client.query(
        'DELETE FROM companions WHERE registration_id = $1 AND id = ANY($2::uuid[])',
        [regId, plan.drop],
      );
    }
    const rows = [];
    for (const { id, item: c } of plan.ordered) {
      const values = [
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
        //
        // 다른 방을 쓰면 침대는 반드시 쓴다(077) — 보호자 옆에서 같이 잘
        // 수가 없다. 화면도 그때는 묻지 않는다.
        c.sharesRoom === false
          ? true
          : typeof c.occupiesBed === 'boolean'
            ? c.occupiesBed
            : defaultOccupiesBed(c.age),
        // 073. 참가비 몫을 **사람별로** 달리 정한 경우에만 값이 있다.
        // 안 보내면 NULL 이고, 그때는 수양회가 정한 나이 구간을 따른다.
        // 0 은 NULL 과 다르다 — "이 아이는 안 받기로 정했다" 이다.
        feeShareOf(c.feeShare),
        // 077. 안 보내면 예전 뜻 그대로 — 같은 방이다.
        c.sharesRoom !== false,
        // 078. 안 보내면 예전 뜻 그대로 — 조에 안 든다.
        studyGroupOf(c),
      ];
      const returning = `RETURNING id, real_name, bible_name, gender, age, language, branch,
                   same_branch_as_primary,
                   same_flight_as_primary, arrival_flight, departure_flight, needs_pickup,
                   registers_separately, occupies_bed, fee_share, shares_room, study_group,
                   tour_ids`;
      const { rows: [row] } = id
        ? await client.query(
            `UPDATE companions SET
               real_name = $2, bible_name = $3, gender = $4, age = $5,
               language = $6, branch = $7, same_branch_as_primary = $8,
               same_flight_as_primary = $9, arrival_flight = $10,
               departure_flight = $11, needs_pickup = $12,
               registers_separately = $13, occupies_bed = $14,
               fee_share = $15, shares_room = $16, study_group = $17,
               -- 투어는 이 표가 아니라 투어 화면에서 정한다(080) — 그대로
               -- 둔다. 따로 등록하는 분이 되면 자기 등록에서 고르므로 비운다.
               tour_ids = CASE WHEN $13 THEN '{}'::uuid[] ELSE tour_ids END
             WHERE id = $1
             ${returning}`,
            [id, ...values],
          )
        : await client.query(
            `INSERT INTO companions
               (registration_id, real_name, bible_name, gender, age, language, branch,
                same_branch_as_primary,
                same_flight_as_primary, arrival_flight, departure_flight, needs_pickup,
                registers_separately, occupies_bed, fee_share, shares_room, study_group)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
             ${returning}`,
            [regId, ...values],
          );
      rows.push(row);
    }

    // 답이 바뀌어 더는 맞지 않는 배정을 걷어낸다(077·078).
    //   같은 방으로 바꿨거나 따로 등록한다 → 자기 방 줄이 필요 없다.
    //   조에 안 들거나 따로 등록한다     → 자기 조 줄이 필요 없다.
    await client.query(
      `DELETE FROM room_assignments
        WHERE companion_id IN (
          SELECT id FROM companions
           WHERE registration_id = $1
             AND (registers_separately OR shares_room))`,
      [regId],
    );
    await client.query(
      `DELETE FROM group_members
        WHERE companion_id IN (
          SELECT id FROM companions
           WHERE registration_id = $1
             AND (registers_separately OR study_group = 'none'))`,
      [regId],
    );
    // "같은 분반" 이면 대표자가 이미 조에 있을 때 그 조로 바로 넣는다.
    // 안 넣으면 담당자가 미배정 목록에서 이 사람을 다시 찾아 옮겨야 한다.
    await client.query(
      `INSERT INTO group_members (group_id, companion_id)
       SELECT gm.group_id, c.id
         FROM companions c
         JOIN group_members gm ON gm.registration_id = c.registration_id
        WHERE c.registration_id = $1
          AND c.registers_separately = false
          AND c.study_group = 'same'
       ON CONFLICT (companion_id) WHERE companion_id IS NOT NULL
       DO UPDATE SET group_id = EXCLUDED.group_id`,
      [regId],
    );
    return rows;
  });
}

/// 등록 [regId] 의 동반자들 — 참가자 화면과 담당자 화면이 같은 모양을 받는다.
export async function listCompanions(regId) {
  const rows = await sql`
    SELECT c.id, c.real_name, c.bible_name, c.gender, c.age, c.language,
           -- 069: 이 사람이 따로 등록하는가, 침대를 쓰는가.
           c.registers_separately, c.occupies_bed,
           -- 077: 대표자와 같은 방을 쓰는가.
           c.shares_room,
           -- 078: 말씀조 — same·other·none.
           c.study_group,
           -- 080: 함께 가는 투어들. 투어 화면에서 정한다.
           c.tour_ids,
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
  if (!rows.some((c) => c.registers_separately)) return rows;
  // "따로 등록" 으로 적힌 분이 **정말 등록했는가**. 화면이 "등록함" 과
  // "아직 안 함" 을 갈라 적는다 — "본인 등록" 한마디로는 했다는 것인지
  // 해야 한다는 것인지 알 수 없었다. 같은 수양회에 이름이 같은 등록이
  // 있으면 한 것으로 본다(방 배정이 잇는 규칙과 같다, separateFamilyEdges).
  // 대표자 자신은 빼고 본다 — 대표자 이름을 동반자로 또 적은 줄도 있다.
  const others = await sql`
    SELECT o.real_name FROM registrations o
      JOIN registrations me ON me.program_id = o.program_id
     WHERE me.id = ${regId} AND o.id <> me.id
       AND counts_as_participant(o.real_name, o.submitted, o.cancelled_at)
  `;
  const names = new Set(others.map((o) => nameKey(o.real_name)).filter(Boolean));
  return rows.map((c) =>
    c.registers_separately
      ? { ...c, own_registration_found: names.has(nameKey(c.real_name)) }
      : c,
  );
}
