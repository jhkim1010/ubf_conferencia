import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';
import { assignRooms, assignGroups } from '../services/assignment_engine.js';

const router = Router();

// ── 데이터 로더 ───────────────────────────────────────────────
async function loadPeople(programId) {
  return sql`
    SELECT id, gender, age FROM registrations
    WHERE program_id = ${programId} AND real_name IS NOT NULL AND real_name <> ''
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

// ── GET 숙소 배정 현황 ────────────────────────────────────────
router.get('/:programId/rooms', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  try {
    const rooms = await sql`
      SELECT r.id, r.name, r.floor, r.room_type, r.capacity, r.gender,
        COALESCE(json_agg(
          json_build_object('registrationId', reg.id, 'name', reg.real_name, 'gender', reg.gender)
        ) FILTER (WHERE reg.id IS NOT NULL), '[]') AS members
      FROM rooms r
      LEFT JOIN room_assignments ra ON ra.room_id = r.id
      LEFT JOIN registrations reg ON reg.id = ra.registration_id
      WHERE r.program_id = ${programId}
      GROUP BY r.id
      ORDER BY r.floor NULLS FIRST, r.name
    `;
    const unassigned = await sql`
      SELECT id AS "registrationId", real_name AS name, gender
      FROM registrations
      WHERE program_id = ${programId} AND real_name IS NOT NULL AND real_name <> ''
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
    const groups = await sql`
      SELECT g.id, g.name, g.passage, g.location, g.leader_name,
        COALESCE(json_agg(
          json_build_object('registrationId', reg.id, 'name', reg.real_name,
                            'gender', reg.gender, 'age', reg.age)
        ) FILTER (WHERE reg.id IS NOT NULL), '[]') AS members
      FROM groups g
      LEFT JOIN group_members gm ON gm.group_id = g.id
      LEFT JOIN registrations reg ON reg.id = gm.registration_id
      WHERE g.program_id = ${programId}
      GROUP BY g.id
      ORDER BY g.sort_order, g.created_at
    `;
    const unassigned = await sql`
      SELECT id AS "registrationId", real_name AS name, gender, age
      FROM registrations
      WHERE program_id = ${programId} AND real_name IS NOT NULL AND real_name <> ''
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
      sql`SELECT id, capacity, gender, room_type AS "roomType" FROM rooms WHERE program_id = ${programId}`,
      loadPeople(programId),
      loadAcceptedEdges(programId, 'roommate'),
    ]);

    const { assignments, unplaced } = assignRooms({ rooms, people, roommateEdges });

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
    const [groups, people, groupEdges] = await Promise.all([
      sql`SELECT id FROM groups WHERE program_id = ${programId} ORDER BY sort_order`,
      loadPeople(programId),
      loadAcceptedEdges(programId, 'group'),
    ]);

    const { assignments } = assignGroups({ groups, people, groupEdges });

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

    res.json({ assigned: assignments.length });
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
      SELECT r.capacity, r.gender, r.room_type,
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
    if (Number(room.occupied) >= room.capacity) {
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
    res.json({ success: true });
  } catch (err) {
    console.error('숙소 배정 해제 오류:', err);
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
