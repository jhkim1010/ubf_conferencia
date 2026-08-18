import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';
import { assignRooms, assignGroups } from '../services/assignment_engine.js';

const router = Router();

// ── 데이터 로더 ───────────────────────────────────────────────
async function loadPeople(programId) {
  return sql`
    SELECT id, gender, age, study_language AS "studyLanguage" FROM registrations
    WHERE program_id = ${programId} AND counts_as_participant(real_name, submitted)
  `;
}
async function loadAcceptedEdges(programId, kind) {
  const rows = await sql`
    SELECT from_registration_id AS a, to_registration_id AS b
    FROM buddy_requests
    WHERE program_id = ${programId} AND kind = ${kind} AND status = 'accepted'
  `;
  return rows.map((r) => [r.a, r.b]);
}

// 동행(가족) 관계로 수락된 짝. 성별이 달라도 같은 방을 쓸 수 있는 근거다(022).
async function loadFamilyEdges(programId) {
  const rows = await sql`
    SELECT from_registration_id AS a, to_registration_id AS b
    FROM buddy_requests
    WHERE program_id = ${programId}
      AND kind = 'roommate' AND status = 'accepted' AND relation = 'family'
  `;
  return rows.map((r) => [r.a, r.b]);
}

// ── GET 숙소 배정 현황 ────────────────────────────────────────
router.get('/:programId/rooms', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  try {
    const rooms = await sql`
      SELECT r.id, r.name, r.floor, r.room_type, r.capacity,
             r.extra_capacity, r.gender,
             r.leader_registration_id AS "leaderRegistrationId",
        COALESCE(json_agg(
          json_build_object('registrationId', reg.id,
                            'name', display_name(reg.bible_name, reg.real_name),
                            'gender', reg.gender)
          ORDER BY reg.real_name
        ) FILTER (WHERE reg.id IS NOT NULL), '[]') AS members
      FROM rooms r
      LEFT JOIN room_assignments ra ON ra.room_id = r.id
      LEFT JOIN registrations reg ON reg.id = ra.registration_id
      WHERE r.program_id = ${programId}
      GROUP BY r.id
      ORDER BY r.floor NULLS FIRST, r.name
    `;
    const unassigned = await sql`
      SELECT id AS "registrationId",
             display_name(bible_name, real_name) AS name, gender
      FROM registrations
      WHERE program_id = ${programId} AND counts_as_participant(real_name, submitted)
        AND id NOT IN (SELECT registration_id FROM room_assignments WHERE registration_id IS NOT NULL)
      ORDER BY real_name
    `;
    res.json({ rooms, unassigned });
  } catch (err) {
    console.error('숙소 배정 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── GET 말씀조 배정 현황 ──────────────────────────────────────
router.get('/:programId/groups', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  try {
    // 조의 언어(025)를 함께 보낸다. 담당자가 사람을 조에 넣을 때 가장 먼저
    // 맞춰 보는 것이 언어인데, 화면에 없으면 조 이름만 보고 짐작해야 한다.
    const groups = await sql`
      SELECT g.id, g.name, g.passage, g.location, g.leader_name,
        g.study_language AS "studyLanguage", g.age_band AS "ageBand",
        g.capacity,
        COALESCE(json_agg(
          json_build_object('registrationId', reg.id,
                            'name', display_name(reg.bible_name, reg.real_name),
                            'gender', reg.gender, 'age', reg.age)
          ORDER BY reg.real_name
        ) FILTER (WHERE reg.id IS NOT NULL), '[]') AS members
      FROM groups g
      LEFT JOIN group_members gm ON gm.group_id = g.id
      LEFT JOIN registrations reg ON reg.id = gm.registration_id
      WHERE g.program_id = ${programId}
      GROUP BY g.id
      ORDER BY g.sort_order, g.created_at
    `;
    // 아직 조가 없는 사람에게도 희망 언어(034)를 실어 준다 — 어느 조로
    // 보낼지는 그것으로 갈린다.
    const unassigned = await sql`
      SELECT id AS "registrationId",
             display_name(bible_name, real_name) AS name, gender, age,
             study_languages AS "studyLanguages"
      FROM registrations
      WHERE program_id = ${programId} AND counts_as_participant(real_name, submitted)
        AND id NOT IN (SELECT registration_id FROM group_members)
      ORDER BY real_name
    `;
    res.json({ groups, unassigned });
  } catch (err) {
    console.error('말씀조 배정 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── POST 숙소 자동 배정 ──────────────────────────────────────
router.post('/:programId/rooms/auto', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  try {
    const [rooms, people, roommateEdges] = await Promise.all([
      sql`SELECT id, capacity, extra_capacity AS "extraCapacity", gender,
                 room_type AS "roomType"
            FROM rooms WHERE program_id = ${programId}`,
      loadPeople(programId),
      loadAcceptedEdges(programId, 'roommate'),
    ]);
    const familyEdges = await loadFamilyEdges(programId);

    const { assignments, unplaced } = assignRooms({
      rooms,
      people,
      roommateEdges,
      familyEdges,
    });

    await sql.transaction(async (client) => {
      await client.query(
        `DELETE FROM room_assignments
         WHERE room_id IN (SELECT id FROM rooms WHERE program_id = $1)`,
        [programId],
      );
      for (const a of assignments) {
        await client.query(
          `INSERT INTO room_assignments (room_id, registration_id) VALUES ($1, $2)`,
          [a.roomId, a.registrationId],
        );
      }
      // 자동 배정은 사람을 다른 방으로 옮긴다. 방장을 그대로 두면 그 방에서
      // 자지도 않는 사람이 방장으로 남는다 — 화면에는 이름이 있으니 아무도
      // 알아채지 못한다.
      await client.query(
        `UPDATE rooms SET leader_registration_id = NULL
          WHERE program_id = $1
            AND leader_registration_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM room_assignments ra
               WHERE ra.room_id = rooms.id
                 AND ra.registration_id = rooms.leader_registration_id
            )`,
        [programId],
      );
    });

    res.json({ assigned: assignments.length, unplaced });
  } catch (err) {
    console.error('숙소 자동 배정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── POST 말씀조 자동 배정 ────────────────────────────────────
router.post('/:programId/groups/auto', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  try {
    const [groups, people, groupEdges, [program]] = await Promise.all([
      sql`SELECT id, study_language AS "studyLanguage", age_band AS "ageBand",
                 capacity
            FROM groups WHERE program_id = ${programId} ORDER BY sort_order`,
      loadPeople(programId),
      loadAcceptedEdges(programId, 'group'),
      sql`SELECT small_cohort_policy, min_team_size FROM programs WHERE id = ${programId}`,
    ]);

    const { assignments, unplaced, notes } = assignGroups({
      groups,
      people,
      groupEdges,
      policy: program?.small_cohort_policy ?? 'keep',
      minTeamSize: program?.min_team_size ?? 5,
    });

    await sql.transaction(async (client) => {
      await client.query(
        `DELETE FROM group_members
         WHERE group_id IN (SELECT id FROM groups WHERE program_id = $1)`,
        [programId],
      );
      for (const a of assignments) {
        await client.query(
          `INSERT INTO group_members (group_id, registration_id) VALUES ($1, $2)`,
          [a.groupId, a.registrationId],
        );
      }
    });

    // notes 는 "왜 이렇게 됐는지"다. 조용히 옮기고 말면 관리자는 스페인어 아이가
    // 왜 한국어 조에 있는지 영영 알 수 없다.
    res.json({ assigned: assignments.length, unplaced, notes });
  } catch (err) {
    console.error('말씀조 자동 배정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── POST 숙소 수동 배정 { roomId, registrationId } (방침 검증) ──
router.post('/:programId/rooms/assign', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  const { roomId, registrationId } = req.body;
  if (!roomId || !registrationId) {
    return res.status(400).json({ error: 'roomId와 registrationId가 필요합니다' });
  }
  try {
    const [room] = await sql`
      SELECT r.capacity, r.extra_capacity, r.gender, r.room_type,
             (SELECT COUNT(*) FROM room_assignments WHERE room_id = r.id) AS occupied
      FROM rooms r WHERE r.id = ${roomId} AND r.program_id = ${programId}
    `;
    if (!room) return res.status(404).json({ error: '방을 찾을 수 없습니다' });
    const [person] = await sql`
      SELECT gender FROM registrations WHERE id = ${registrationId} AND program_id = ${programId}
    `;
    if (!person) return res.status(404).json({ error: '참가자를 찾을 수 없습니다' });

    // 혼숙 방침: 단체실은 같은 성별만
    if (room.room_type === 'dorm' && person.gender && room.gender !== person.gender) {
      return res.status(422).json({ error: '단체실은 같은 성별만 배정할 수 있습니다' });
    }
    // 여유 자리까지 허용한다(042). 담당자가 직접 넣는 것은 "간이침대를
    // 하나 더 놓겠다" 는 뜻이므로 막지 않는다.
    if (Number(room.occupied) >= room.capacity + Number(room.extra_capacity ?? 0)) {
      return res.status(422).json({ error: '방 정원이 가득 찼습니다' });
    }

    await sql.transaction(async (client) => {
      // 기존 방 배정 해제 후 새 방에 배정
      await client.query('DELETE FROM room_assignments WHERE registration_id = $1', [registrationId]);
      await client.query(
        'INSERT INTO room_assignments (room_id, registration_id) VALUES ($1, $2)',
        [roomId, registrationId],
      );
    });
    res.json({ success: true });
  } catch (err) {
    console.error('숙소 수동 배정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── DELETE 숙소 배정 해제 ────────────────────────────────────
router.delete('/:programId/rooms/:registrationId', requireAuth, requireProgramAdmin, async (req, res) => {
  try {
    await sql`DELETE FROM room_assignments WHERE registration_id = ${req.params.registrationId}`;
    // 방에서 뺐으면 방장도 아니다.
    await sql`
      UPDATE rooms SET leader_registration_id = NULL
      WHERE leader_registration_id = ${req.params.registrationId}
    `;
    res.json({ success: true });
  } catch (err) {
    console.error('숙소 배정 해제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── PUT 방장 세우기 { registrationId } ───────────────────────
//
// 방장은 **그 방에 배정된 사람** 이라야 한다. 방에서 자지 않는 사람을
// 방장으로 세우면 현장에서 아무 소용이 없다. 이 규칙은 컬럼 제약으로는
// 표현할 수 없어(배정이 다른 표에 있다) 여기서 본다.
//
// registrationId 를 비우면 방장을 내린다.
router.put('/:programId/rooms/:roomId/leader', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId, roomId } = req.params;
  const registrationId = req.body?.registrationId ?? null;
  try {
    const [room] = await sql`
      SELECT id FROM rooms WHERE id = ${roomId} AND program_id = ${programId}
    `;
    if (!room) return res.status(404).json({ error: '숙소를 찾을 수 없습니다' });

    if (registrationId) {
      const [inRoom] = await sql`
        SELECT 1 FROM room_assignments
        WHERE room_id = ${roomId} AND registration_id = ${registrationId}
      `;
      if (!inRoom) {
        return res.status(400).json({ error: '그 방에 배정된 사람만 방장이 될 수 있습니다' });
      }
    }

    await sql`
      UPDATE rooms SET leader_registration_id = ${registrationId}
      WHERE id = ${roomId}
    `;
    res.json({ success: true, leaderRegistrationId: registrationId });
  } catch (err) {
    console.error('방장 지정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── POST 말씀조 수동 배정 { groupId, registrationId } ─────────
router.post('/:programId/groups/assign', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  const { groupId, registrationId } = req.body;
  if (!groupId || !registrationId) {
    return res.status(400).json({ error: 'groupId와 registrationId가 필요합니다' });
  }
  try {
    const [group] = await sql`SELECT id FROM groups WHERE id = ${groupId} AND program_id = ${programId}`;
    if (!group) return res.status(404).json({ error: '조를 찾을 수 없습니다' });

    await sql.transaction(async (client) => {
      await client.query('DELETE FROM group_members WHERE registration_id = $1', [registrationId]);
      await client.query(
        'INSERT INTO group_members (group_id, registration_id) VALUES ($1, $2)',
        [groupId, registrationId],
      );
    });
    res.json({ success: true });
  } catch (err) {
    console.error('말씀조 수동 배정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── DELETE 말씀조 배정 해제 ──────────────────────────────────
router.delete('/:programId/groups/:registrationId', requireAuth, requireProgramAdmin, async (req, res) => {
  try {
    await sql`DELETE FROM group_members WHERE registration_id = ${req.params.registrationId}`;
    res.json({ success: true });
  } catch (err) {
    console.error('말씀조 배정 해제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
