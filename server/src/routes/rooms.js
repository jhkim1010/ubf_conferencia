import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';

const router = Router();

// 방 유형별 혼성 허용 여부 검증 (DB CHECK와 이중 방어 + 친절한 메시지)
function validateRoomPolicy(roomType, gender) {
  if (roomType === 'dorm' && gender === 'mixed') {
    return '단체실(5인 이상)은 남녀 혼숙이 허용되지 않습니다. 성별을 남 또는 여로 지정하세요.';
  }
  if ((roomType === 'couple' || roomType === 'family') && gender !== 'mixed') {
    return '부부실·가족실은 가족 단위(혼성)로 배정됩니다. 성별은 mixed로 지정하세요.';
  }
  return null;
}

// "3층 3##호" + startNumber=1, count=10  →  ["3층 301호", … "3층 310호"]
// '#' 연속 구간을 startNumber부터 count개, '#' 개수만큼 0-padding으로 치환.
// '#'가 없으면 이름 뒤에 번호를 붙인다.
function generateNames(pattern, startNumber, count) {
  const start = Number.isInteger(startNumber) ? startNumber : 1;
  const match = pattern.match(/#+/);
  const names = [];
  for (let i = 0; i < count; i++) {
    const num = start + i;
    if (match) {
      const width = match[0].length;
      names.push(pattern.replace(/#+/, String(num).padStart(width, '0')));
    } else {
      names.push(`${pattern} ${num}`);
    }
  }
  return names;
}

// GET /rooms/:programId — 방 목록 + 정원 대비 등록 대조
router.get('/:programId', requireAuth, async (req, res) => {
  const { programId } = req.params;
  try {
    const rooms = await sql`
      SELECT id, name, floor, room_type, capacity, gender, created_at
      FROM rooms
      WHERE program_id = ${programId}
      ORDER BY floor NULLS FIRST, name ASC
    `;

    // 단체실 정원을 성별로 집계
    const [seatAgg] = await sql`
      SELECT
        COALESCE(SUM(capacity) FILTER (WHERE gender = 'M'), 0)     AS male_seats,
        COALESCE(SUM(capacity) FILTER (WHERE gender = 'F'), 0)     AS female_seats,
        COALESCE(SUM(capacity) FILTER (WHERE gender = 'mixed'), 0) AS mixed_seats,
        COALESCE(SUM(capacity), 0)                                 AS total_seats
      FROM rooms
      WHERE program_id = ${programId}
    `;

    // 등록 인원을 성별로 집계 (성별 미기입 제외)
    const [regAgg] = await sql`
      SELECT
        COUNT(*) FILTER (WHERE gender = 'M') AS male_regs,
        COUNT(*) FILTER (WHERE gender = 'F') AS female_regs,
        COUNT(*)                             AS total_regs
      FROM registrations
      WHERE program_id = ${programId} AND gender IN ('M', 'F')
    `;

    const summary = {
      maleSeats: Number(seatAgg.male_seats),
      femaleSeats: Number(seatAgg.female_seats),
      mixedSeats: Number(seatAgg.mixed_seats),
      totalSeats: Number(seatAgg.total_seats),
      maleRegs: Number(regAgg.male_regs),
      femaleRegs: Number(regAgg.female_regs),
      totalRegs: Number(regAgg.total_regs),
      // 부족 인원(양수면 자리 부족). 혼성 좌석은 특정 성별로 못 세므로 단일성별만 비교.
      maleShortage: Number(regAgg.male_regs) - Number(seatAgg.male_seats),
      femaleShortage: Number(regAgg.female_regs) - Number(seatAgg.female_seats),
    };

    res.json({ rooms, summary });
  } catch (err) {
    console.error('방 목록 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /rooms/:programId — 방 1개 생성 (admin 이상)
router.post('/:programId', requireAuth, requireProgramAdmin, async (req, res) => {
  const { name, floor, roomType, capacity, gender } = req.body;
  if (!name || !capacity) {
    return res.status(400).json({ error: 'name과 capacity가 필요합니다' });
  }
  const type = roomType ?? 'dorm';
  const g = gender ?? (type === 'dorm' ? 'M' : 'mixed');

  const policyError = validateRoomPolicy(type, g);
  if (policyError) return res.status(422).json({ error: policyError });

  try {
    const [room] = await sql`
      INSERT INTO rooms (program_id, name, floor, room_type, capacity, gender)
      VALUES (${req.params.programId}, ${name}, ${floor ?? null}, ${type}, ${capacity}, ${g})
      RETURNING id, name, floor, room_type, capacity, gender, created_at
    `;
    res.status(201).json(room);
  } catch (err) {
    console.error('방 생성 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /rooms/:programId/bulk — 방 일괄 생성 (admin 이상)
// body: { namePattern, startNumber, count, floor, roomType, capacity, gender }
router.post('/:programId/bulk', requireAuth, requireProgramAdmin, async (req, res) => {
  const { namePattern, startNumber, count, floor, roomType, capacity, gender } = req.body;
  if (!namePattern || !count || !capacity) {
    return res.status(400).json({ error: 'namePattern, count, capacity가 필요합니다' });
  }
  if (count < 1 || count > 200) {
    return res.status(400).json({ error: 'count는 1~200 사이여야 합니다' });
  }
  const type = roomType ?? 'dorm';
  const g = gender ?? (type === 'dorm' ? 'M' : 'mixed');

  const policyError = validateRoomPolicy(type, g);
  if (policyError) return res.status(422).json({ error: policyError });

  const names = generateNames(namePattern, startNumber ?? 1, count);

  try {
    const created = await sql.transaction(async (client) => {
      const rows = [];
      for (const name of names) {
        const { rows: [room] } = await client.query(
          `INSERT INTO rooms (program_id, name, floor, room_type, capacity, gender)
           VALUES ($1, $2, $3, $4, $5, $6)
           RETURNING id, name, floor, room_type, capacity, gender, created_at`,
          [req.params.programId, name, floor ?? null, type, capacity, g],
        );
        rows.push(room);
      }
      return rows;
    });
    res.status(201).json({ created: created.length, rooms: created });
  } catch (err) {
    console.error('방 일괄 생성 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /rooms/:programId/:roomId — 방 수정 (admin 이상)
router.patch('/:programId/:roomId', requireAuth, requireProgramAdmin, async (req, res) => {
  const { name, floor, roomType, capacity, gender } = req.body;

  // 유형·성별이 함께 바뀌는 경우 방침 검증 (부분 수정 시엔 기존 값과 합쳐 확인)
  try {
    const [existing] = await sql`
      SELECT room_type, gender FROM rooms
      WHERE id = ${req.params.roomId} AND program_id = ${req.params.programId}
    `;
    if (!existing) return res.status(404).json({ error: '방을 찾을 수 없습니다' });

    const nextType = roomType ?? existing.room_type;
    const nextGender = gender ?? existing.gender;
    const policyError = validateRoomPolicy(nextType, nextGender);
    if (policyError) return res.status(422).json({ error: policyError });

    const [updated] = await sql`
      UPDATE rooms SET
        name      = COALESCE(${name ?? null}, name),
        floor     = COALESCE(${floor ?? null}, floor),
        room_type = COALESCE(${roomType ?? null}, room_type),
        capacity  = COALESCE(${capacity ?? null}, capacity),
        gender    = COALESCE(${gender ?? null}, gender)
      WHERE id = ${req.params.roomId} AND program_id = ${req.params.programId}
      RETURNING id, name, floor, room_type, capacity, gender, created_at
    `;
    res.json(updated);
  } catch (err) {
    console.error('방 수정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /rooms/:programId/:roomId — 방 삭제 (admin 이상)
router.delete('/:programId/:roomId', requireAuth, requireProgramAdmin, async (req, res) => {
  try {
    await sql`
      DELETE FROM rooms
      WHERE id = ${req.params.roomId} AND program_id = ${req.params.programId}
    `;
    res.json({ success: true });
  } catch (err) {
    console.error('방 삭제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
