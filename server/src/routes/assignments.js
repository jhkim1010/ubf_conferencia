import { Router } from 'express';
import { sql } from '../db.js';
import {
  requireAuth,
  requireProgramAdmin,
  requireScope,
} from '../middleware/auth.js';
import {
  assignRooms,
  assignGroups,
  connectedComponents,
} from '../services/assignment_engine.js';
import {
  companionOccupantId,
  parseOccupant,
  companionLabel,
  companionGroupPeople,
  separateFamilyEdges,
} from '../services/room_occupant.js';
import { loadCoverMap } from '../services/companion_cover.js';

const router = Router();

// ── 데이터 로더 ───────────────────────────────────────────────
async function loadPeople(programId) {
  return sql`
    SELECT r.id, r.gender, r.age, r.study_language AS "studyLanguage",
           r.country, r.branch,
           -- 이 사람이 방에서 차지하는 자리 수(069). 본인 한 자리에, 등록할
           -- 수 없는 동반자 중 **침대를 쓰는** 사람을 더한다.
           --
           -- 아기처럼 보호자와 같이 자는 동반자는 안 센다. 세어 버리면
           -- 4인실에 부부와 아기가 못 들어간다.
           1 + (SELECT COUNT(*) FROM companions c
                 WHERE c.registration_id = r.id
                   AND c.registers_separately = false
                   -- 다른 방을 쓰는 동반자는 따로 한 사람이다(077).
                   AND c.shares_room = true
                   AND c.occupies_bed = true) AS beds
      FROM registrations r
     WHERE r.program_id = ${programId}
       AND counts_as_participant(r.real_name, r.submitted, r.cancelled_at)
  `;
}
/// 대표자와 **다른 방을 쓰는** 동반자들(077). 등록이 없으므로 방 배정에서
/// 'c:<id>' 로 가리킨다(services/room_occupant.js). 말씀조에는 안 넣는다 —
/// 동반자는 원래 조에 안 들어간다(069).
async function loadSeparateCompanions(programId) {
  return sql`
    SELECT c.id, c.real_name, c.gender, c.age, r.country, r.branch,
           display_name(r.bible_name, r.real_name) AS primary_name
      FROM companions c
      JOIN registrations r ON r.id = c.registration_id
     WHERE r.program_id = ${programId}
       AND counts_as_participant(r.real_name, r.submitted, r.cancelled_at)
       AND c.registers_separately = false
       AND c.shares_room = false
  `;
}

/// 말씀조에 드는 동반자들(078). 함께 등록했고 study_group 이 same·other 인
/// 사람이다. 언어는 대표자의 것을 쓴다(companionGroupPeople).
async function loadGroupCompanions(programId) {
  return sql`
    SELECT c.id, c.registration_id, c.study_group, c.real_name, c.gender, c.age,
           r.study_language, r.study_languages, r.country, r.branch,
           display_name(r.bible_name, r.real_name) AS primary_name
      FROM companions c
      JOIN registrations r ON r.id = c.registration_id
     WHERE r.program_id = ${programId}
       AND counts_as_participant(r.real_name, r.submitted, r.cancelled_at)
       AND c.registers_separately = false
       AND c.study_group IN ('same', 'other')
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

/// 미배정 목록에 **같이 움직일 사람**을 붙인다(057).
///
/// 서로 지목하고 수락한 사람들은 자동 배정이 한 묶음으로 다룬다. 그런데
/// 손으로 옮길 때는 한 명씩 눌러야 했고, 담당자가 한쪽만 옮기면 자동 배정이
/// 지켜 준 짝이 손으로 깨졌다. 목록에서부터 묶어 보여 주고 함께 옮긴다.
async function withBuddies(programId, rows, kind, extraEdges = []) {
  if (rows.length === 0) return rows;
  const edges = [...(await loadAcceptedEdges(programId, kind)), ...extraEdges];
  const ids = rows.map((r) => r.registrationId);
  const comps = connectedComponents(ids, edges);
  const mate = new Map();
  for (const c of comps) {
    if (c.length < 2) continue;
    for (const id of c) mate.set(id, c);
  }
  return rows.map((r) => ({
    ...r,
    // 자기 자신을 뺀 나머지. 없으면 빈 배열이라 앱이 그냥 한 명으로 그린다.
    withIds: (mate.get(r.registrationId) ?? []).filter(
      (id) => id !== r.registrationId,
    ),
  }));
}

/// 따로 등록했지만 같은 방을 원하는 가족. 동반자 표에 "본인
/// 등록" 으로 적힌 사람을 이름으로 그 사람의 등록과 잇는다
/// (services/room_occupant.js separateFamilyEdges). 가족 짝으로 다룬다 —
/// 부부는 성별이 달라도 한 방이다.
async function loadSeparateFamilyEdges(programId) {
  const [companions, registrations] = await Promise.all([
    sql`
      SELECT c.registration_id, c.real_name, c.shares_room
        FROM companions c
        JOIN registrations r ON r.id = c.registration_id
       WHERE r.program_id = ${programId}
         AND counts_as_participant(r.real_name, r.submitted, r.cancelled_at)
         AND c.registers_separately = true
    `,
    sql`
      SELECT id, real_name FROM registrations
       WHERE program_id = ${programId}
         AND counts_as_participant(real_name, submitted, cancelled_at)
    `,
  ]);
  return separateFamilyEdges(companions, registrations);
}

/// 대표자가 동반자로 함께 등록했는데 자기 계정으로도 등록한 사람
/// (companion_cover.js). 방에서는 **동반자 줄이 그 사람**이다 — 대표자와
/// 같은 방이면 대표자를 따라가고, 다른 방이면 'c:<id>' 로 든다. 자기 등록까지
/// 넣으면 같은 사람이 두 자리를 차지한다.
async function roomCoveredIds(programId) {
  return new Set((await loadCoverMap(programId)).keys());
}

/// 말씀조에서는 동반자 줄이 조에 들 때(same·other)만 그 사람이다.
/// 동반자 줄이 '안 함' 이면 자기 등록으로 조에 든다.
async function groupCoveredIds(programId) {
  const out = new Set();
  for (const [id, c] of await loadCoverMap(programId)) {
    if (c.studyGroup === 'same' || c.studyGroup === 'other') out.add(id);
  }
  return out;
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
router.get('/:programId/rooms', requireAuth, requireProgramAdmin, requireScope('rooms'), async (req, res) => {
  const { programId } = req.params;
  try {
    const rooms = await sql`
      SELECT r.id, r.name, r.floor, r.room_type, r.capacity,
             r.extra_capacity, r.gender,
             r.leader_registration_id AS "leaderRegistrationId",
        COALESCE(json_agg(
          json_build_object('registrationId', reg.id,
                            'name', display_name(reg.bible_name, reg.real_name),
                            'gender', reg.gender,
                            -- 이 사람과 같은 방에 있는, 등록할 수 없는
                            -- 동반자들(069). 보호자를 따라가므로 따로
                            -- 배정하지 않는다.
                            'companions', COALESCE((
                              SELECT json_agg(json_build_object(
                                       'name', c.real_name,
                                       'age', c.age,
                                       'gender', c.gender,
                                       'occupiesBed', c.occupies_bed)
                                     ORDER BY c.age NULLS LAST)
                                FROM companions c
                               WHERE c.registration_id = reg.id
                                 AND c.registers_separately = false
                                 -- 다른 방을 쓰는 동반자는 자기 줄로 나온다(077).
                                 AND c.shares_room = true
                            ), '[]'::json))
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
      SELECT reg.id AS "registrationId",
             display_name(reg.bible_name, reg.real_name) AS name, reg.gender,
             -- 이 사람과 한 방에 드는, 함께 등록한 동반자(069). 미배정
             -- 목록에서 "누구 + 누구" 로 한 줄에 보인다.
             COALESCE((
               SELECT json_agg(json_build_object('name', c.real_name, 'age', c.age)
                               ORDER BY c.age DESC NULLS LAST)
                 FROM companions c
                WHERE c.registration_id = reg.id
                  AND c.registers_separately = false
                  AND c.shares_room = true
             ), '[]'::json) AS companions
      FROM registrations reg
      WHERE reg.program_id = ${programId}
        AND counts_as_participant(reg.real_name, reg.submitted, reg.cancelled_at)
        AND reg.id NOT IN (SELECT registration_id FROM room_assignments WHERE registration_id IS NOT NULL)
      ORDER BY reg.real_name
    `;
    const roomCovered = await roomCoveredIds(programId);
    // 다른 방을 쓰는 동반자(077). 자기 줄(companion_id)로 방에 든다.
    const separate = await loadSeparateCompanions(programId);
    const placed = await sql`
      SELECT ra.room_id, ra.companion_id
        FROM room_assignments ra
        JOIN rooms rm ON rm.id = ra.room_id
       WHERE rm.program_id = ${programId} AND ra.companion_id IS NOT NULL
    `;
    const roomOf = new Map(placed.map((p) => [p.companion_id, p.room_id]));
    const asMember = (c) => ({
      registrationId: companionOccupantId(c.id),
      name: companionLabel(c.real_name, c.primary_name),
      gender: c.gender,
      companions: [],
      // 앱이 방장 버튼을 감춘다 — 방장은 등록한 사람만 될 수 있다.
      isCompanion: true,
    });
    const byRoom = new Map(rooms.map((r) => [r.id, r]));
    const loose = [];
    for (const c of separate) {
      const room = byRoom.get(roomOf.get(c.id));
      if (room) room.members.push(asMember(c));
      else loose.push(asMember(c));
    }
    res.json({
      rooms,
      unassigned: [
        ...(await withBuddies(
          programId,
          unassigned.filter((u) => !roomCovered.has(u.registrationId)),
          'roommate',
          await loadSeparateFamilyEdges(programId),
        )),
        ...loose.map((m) => ({ ...m, withIds: [] })),
      ],
    });
  } catch (err) {
    console.error('숙소 배정 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── GET 말씀조 배정 현황 ──────────────────────────────────────
router.get('/:programId/groups', requireAuth, requireProgramAdmin, requireScope('groups'), async (req, res) => {
  const { programId } = req.params;
  try {
    // 조의 언어(025)를 함께 보낸다. 담당자가 사람을 조에 넣을 때 가장 먼저
    // 맞춰 보는 것이 언어인데, 화면에 없으면 조 이름만 보고 짐작해야 한다.
    const groups = await sql`
      SELECT g.id, g.name, g.passage, g.location, g.leader_name,
        g.study_language AS "studyLanguage", g.age_band AS "ageBand",
        g.capacity
      FROM groups g
      WHERE g.program_id = ${programId}
      ORDER BY g.sort_order, g.created_at
    `;
    // 조원 — 등록자와, 함께 등록해 조에 드는 동반자(078). 동반자는
    // 'c:<id>' 로 가리키고 누구의 동반자인지 이름에 붙인다.
    const members = await sql`
      SELECT gm.group_id,
             COALESCE(reg.id::text, 'c:' || comp.id::text) AS "registrationId",
             CASE WHEN reg.id IS NOT NULL
                  THEN display_name(reg.bible_name, reg.real_name)
                  ELSE comp.real_name END AS name,
             CASE WHEN reg.id IS NULL
                  THEN display_name(owner.bible_name, owner.real_name) END
               AS primary_name,
             COALESCE(reg.gender, comp.gender) AS gender,
             COALESCE(reg.age, comp.age) AS age,
             comp.id IS NOT NULL AS "isCompanion",
             COALESCE(reg.real_name, comp.real_name) AS sort_name
        FROM group_members gm
        JOIN groups g ON g.id = gm.group_id
        LEFT JOIN registrations reg ON reg.id = gm.registration_id
        LEFT JOIN companions comp ON comp.id = gm.companion_id
        LEFT JOIN registrations owner ON owner.id = comp.registration_id
       WHERE g.program_id = ${programId}
         AND (reg.id IS NOT NULL OR comp.id IS NOT NULL)
       ORDER BY sort_name
    `;
    const byGroup = new Map(groups.map((g) => [g.id, []]));
    for (const m of members) {
      byGroup.get(m.group_id)?.push({
        registrationId: m.registrationId,
        name: m.isCompanion ? companionLabel(m.name, m.primary_name) : m.name,
        gender: m.gender,
        age: m.age,
        isCompanion: m.isCompanion,
      });
    }
    for (const g of groups) g.members = byGroup.get(g.id) ?? [];

    // 아직 조가 없는 사람에게도 희망 언어(034)를 실어 준다 — 어느 조로
    // 보낼지는 그것으로 갈린다.
    const unassignedRegs = await sql`
      SELECT id AS "registrationId",
             display_name(bible_name, real_name) AS name, gender, age,
             study_languages AS "studyLanguages"
      FROM registrations
      WHERE program_id = ${programId} AND counts_as_participant(real_name, submitted, cancelled_at)
        AND id NOT IN (SELECT registration_id FROM group_members
                        WHERE registration_id IS NOT NULL)
      ORDER BY real_name
    `;
    const groupCovered = await groupCoveredIds(programId);
    // 조에 들기로 한 동반자 중 아직 조가 없는 사람(078). 언어는 대표자의 것.
    const companions = await loadGroupCompanions(programId);
    const placed = new Set(
      members.filter((m) => m.isCompanion).map((m) => m.registrationId),
    );
    const { edges: sameEdges } = companionGroupPeople(companions);
    const unassignedComps = companions
      .map((c) => ({
        registrationId: companionOccupantId(c.id),
        name: companionLabel(c.real_name, c.primary_name),
        gender: c.gender,
        age: c.age,
        studyLanguages: c.study_languages,
        isCompanion: true,
      }))
      .filter((c) => !placed.has(c.registrationId));
    res.json({
      groups,
      // "같은 분반" 동반자는 대표자와 함께 움직인다(withIds).
      unassigned: await withBuddies(
        programId,
        [
          ...unassignedRegs.filter((u) => !groupCovered.has(u.registrationId)),
          ...unassignedComps,
        ],
        'group',
        sameEdges,
      ),
    });
  } catch (err) {
    console.error('말씀조 배정 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── POST 숙소 자동 배정 ──────────────────────────────────────
router.post('/:programId/rooms/auto', requireAuth, requireProgramAdmin, requireScope('rooms'), async (req, res) => {
  const { programId } = req.params;
  try {
    const [rooms, allRegistrants, separate, acceptedRoommates, separateFamily, roomCovered] = await Promise.all([
      sql`SELECT id, capacity, extra_capacity AS "extraCapacity", gender,
                 room_type AS "roomType"
            FROM rooms WHERE program_id = ${programId}`,
      loadPeople(programId),
      loadSeparateCompanions(programId),
      loadAcceptedEdges(programId, 'roommate'),
      loadSeparateFamilyEdges(programId),
      roomCoveredIds(programId),
    ]);
    const registrants = allRegistrants.filter((p) => !roomCovered.has(p.id));
    // 따로 등록한 가족도 짝이다. 엔진은 가족 짝이 짝 목록의 일부이기를
    // 바란다(assignRooms 의 familyEdges 설명).
    const roommateEdges = [...acceptedRoommates, ...separateFamily];
    // 다른 방을 쓰는 동반자도 한 사람으로 넣는다(077). 엔진은 id 만 본다.
    const people = [
      ...registrants,
      ...separate.map((c) => ({
        id: companionOccupantId(c.id),
        gender: c.gender,
        age: c.age,
        country: c.country,
        branch: c.branch,
        beds: 1,
      })),
    ];
    const familyEdges = [...(await loadFamilyEdges(programId)), ...separateFamily];

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
        const who = parseOccupant(a.registrationId);
        if (!who) continue;
        await client.query(
          `INSERT INTO room_assignments (room_id, registration_id, companion_id)
           VALUES ($1, $2, $3)`,
          [a.roomId, who.registrationId ?? null, who.companionId ?? null],
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
router.post('/:programId/groups/auto', requireAuth, requireProgramAdmin, requireScope('groups'), async (req, res) => {
  const { programId } = req.params;
  try {
    const [groups, allRegistrants, acceptedEdges, companions, [program], groupCovered] = await Promise.all([
      sql`SELECT id, study_language AS "studyLanguage", age_band AS "ageBand",
                 capacity
            FROM groups WHERE program_id = ${programId} ORDER BY sort_order`,
      loadPeople(programId),
      loadAcceptedEdges(programId, 'group'),
      loadGroupCompanions(programId),
      sql`SELECT small_cohort_policy, min_team_size FROM programs WHERE id = ${programId}`,
      groupCoveredIds(programId),
    ]);
    const registrants = allRegistrants.filter((p) => !groupCovered.has(p.id));
    // 함께 등록한 동반자도 한 사람으로 넣는다(078). "같은 분반" 은 대표자와
    // 짝으로 묶여 한 조로 간다.
    const fromCompanions = companionGroupPeople(companions);
    const people = [...registrants, ...fromCompanions.people];
    const groupEdges = [...acceptedEdges, ...fromCompanions.edges];

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
        const who = parseOccupant(a.registrationId);
        if (!who) continue;
        await client.query(
          `INSERT INTO group_members (group_id, registration_id, companion_id)
           VALUES ($1, $2, $3)`,
          [a.groupId, who.registrationId ?? null, who.companionId ?? null],
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
router.post('/:programId/rooms/assign', requireAuth, requireProgramAdmin, requireScope('rooms'), async (req, res) => {
  const { programId } = req.params;
  const { roomId, registrationId } = req.body;
  if (!roomId || !registrationId) {
    return res.status(400).json({ error: 'roomId와 registrationId가 필요합니다' });
  }
  try {
    const [room] = await sql`
      SELECT r.capacity, r.extra_capacity, r.gender, r.room_type,
             -- 이 방이 쓰는 침대 수(069). 배정된 등록자 + 그 사람에게 딸린
             -- **등록 못 하는 동반자 중 침대를 쓰는 사람**이다.
             --
             -- 아기는 방에 있지만 자리를 안 먹는 경우가 많고, 그때 정원을 한
             -- 칸 깎으면 4인실에 부부와 아기가 못 들어간다.
             --
             -- 동반자에게는 room_assignments 줄을 따로 만들지 않는다.
             -- **보호자를 따라간다** — 줄을 따로 두면 부모와 다른 방에
             -- 배정될 수 있고, 그것은 어떤 경우에도 옳지 않다.
             (SELECT COUNT(*) FROM room_assignments WHERE room_id = r.id)
             + (SELECT COUNT(*)
                  FROM room_assignments ra3
                  JOIN companions c3 ON c3.registration_id = ra3.registration_id
                 WHERE ra3.room_id = r.id
                   AND c3.registers_separately = false
                   AND c3.shares_room = true
                   AND c3.occupies_bed = true) AS occupied
      FROM rooms r WHERE r.id = ${roomId} AND r.program_id = ${programId}
    `;
    if (!room) return res.status(404).json({ error: '방을 찾을 수 없습니다' });
    // 다른 방을 쓰는 동반자일 수 있다(077).
    const who = parseOccupant(registrationId);
    if (!who) return res.status(400).json({ error: 'roomId와 registrationId가 필요합니다' });
    const [person] = who.companionId
      ? await sql`
          SELECT c.gender FROM companions c
            JOIN registrations r ON r.id = c.registration_id
           WHERE c.id = ${who.companionId} AND r.program_id = ${programId}
             AND c.registers_separately = false AND c.shares_room = false
        `
      : await sql`
          SELECT gender FROM registrations
           WHERE id = ${who.registrationId} AND program_id = ${programId}
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
      if (who.companionId) {
        await client.query('DELETE FROM room_assignments WHERE companion_id = $1', [who.companionId]);
        await client.query(
          'INSERT INTO room_assignments (room_id, companion_id) VALUES ($1, $2)',
          [roomId, who.companionId],
        );
      } else {
        await client.query('DELETE FROM room_assignments WHERE registration_id = $1', [who.registrationId]);
        await client.query(
          'INSERT INTO room_assignments (room_id, registration_id) VALUES ($1, $2)',
          [roomId, who.registrationId],
        );
      }
    });
    res.json({ success: true });
  } catch (err) {
    console.error('숙소 수동 배정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── DELETE 숙소 배정 해제 ────────────────────────────────────
router.delete('/:programId/rooms/:registrationId', requireAuth, requireProgramAdmin, requireScope('rooms'), async (req, res) => {
  try {
    const who = parseOccupant(req.params.registrationId);
    if (who?.companionId) {
      // 다른 방을 쓰는 동반자(077). 방장일 수 없으므로 그것만 지운다.
      await sql`DELETE FROM room_assignments WHERE companion_id = ${who.companionId}`;
      return res.json({ success: true });
    }
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
router.put('/:programId/rooms/:roomId/leader', requireAuth, requireProgramAdmin, requireScope('rooms'), async (req, res) => {
  const { programId, roomId } = req.params;
  const registrationId = req.body?.registrationId ?? null;
  try {
    const [room] = await sql`
      SELECT id FROM rooms WHERE id = ${roomId} AND program_id = ${programId}
    `;
    if (!room) return res.status(404).json({ error: '숙소를 찾을 수 없습니다' });

    // 방장은 등록한 사람이라야 한다 — 동반자(077)는 앱에 계정이 없다.
    if (parseOccupant(registrationId)?.companionId) {
      return res.status(400).json({ error: '동반자는 방장이 될 수 없습니다' });
    }
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
router.post('/:programId/groups/assign', requireAuth, requireProgramAdmin, requireScope('groups'), async (req, res) => {
  const { programId } = req.params;
  const { groupId, registrationId } = req.body;
  if (!groupId || !registrationId) {
    return res.status(400).json({ error: 'groupId와 registrationId가 필요합니다' });
  }
  try {
    const [group] = await sql`SELECT id FROM groups WHERE id = ${groupId} AND program_id = ${programId}`;
    if (!group) return res.status(404).json({ error: '조를 찾을 수 없습니다' });

    // 동반자는 'c:<id>' 로 온다(078). 이 수양회의, 조에 들기로 한 동반자인지
    // 확인한다 — 아기를 조에 넣거나 남의 수양회 사람을 넣으면 안 된다.
    const who = parseOccupant(registrationId);
    if (!who) return res.status(400).json({ error: 'groupId와 registrationId가 필요합니다' });
    if (who.companionId) {
      const [comp] = await sql`
        SELECT c.id FROM companions c
          JOIN registrations r ON r.id = c.registration_id
         WHERE c.id = ${who.companionId} AND r.program_id = ${programId}
           AND c.registers_separately = false
           AND c.study_group IN ('same', 'other')
      `;
      if (!comp) return res.status(404).json({ error: '동반자를 찾을 수 없습니다' });
    }

    await sql.transaction(async (client) => {
      if (who.companionId) {
        await client.query('DELETE FROM group_members WHERE companion_id = $1', [who.companionId]);
        await client.query(
          'INSERT INTO group_members (group_id, companion_id) VALUES ($1, $2)',
          [groupId, who.companionId],
        );
      } else {
        await client.query('DELETE FROM group_members WHERE registration_id = $1', [registrationId]);
        await client.query(
          'INSERT INTO group_members (group_id, registration_id) VALUES ($1, $2)',
          [groupId, registrationId],
        );
      }
    });
    res.json({ success: true });
  } catch (err) {
    console.error('말씀조 수동 배정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── DELETE 말씀조 배정 해제 ──────────────────────────────────
router.delete('/:programId/groups/:registrationId', requireAuth, requireProgramAdmin, requireScope('groups'), async (req, res) => {
  try {
    const who = parseOccupant(req.params.registrationId);
    if (who?.companionId) {
      await sql`DELETE FROM group_members WHERE companion_id = ${who.companionId}`;
    } else if (who?.registrationId) {
      await sql`DELETE FROM group_members WHERE registration_id = ${who.registrationId}`;
    }
    res.json({ success: true });
  } catch (err) {
    console.error('말씀조 배정 해제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
