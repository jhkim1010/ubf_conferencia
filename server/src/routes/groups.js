import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin, requireScope } from '../middleware/auth.js';

const router = Router();

// GET /groups/:programId — 말씀조 목록 + 편성 요약
router.get('/:programId', requireAuth, async (req, res) => {
  const { programId } = req.params;
  try {
    const groups = await sql`
      SELECT id, name, passage, location,
             leader_registration_id, leader_name, leader_phone, sort_order,
             study_language AS "studyLanguage", capacity, created_at
      FROM groups
      WHERE program_id = ${programId}
      ORDER BY sort_order ASC, created_at ASC
    `;

    const [regAgg] = await sql`
      SELECT
        COUNT(*)                             AS total_regs,
        COUNT(*) FILTER (WHERE gender = 'M') AS male_regs,
        COUNT(*) FILTER (WHERE gender = 'F') AS female_regs
      FROM registrations
      WHERE program_id = ${programId} AND gender IN ('M', 'F')
    `;

    const totalRegs = Number(regAgg.total_regs);
    const groupCount = groups.length;
    const summary = {
      totalRegs,
      maleRegs: Number(regAgg.male_regs),
      femaleRegs: Number(regAgg.female_regs),
      groupCount,
      // 균형 배정 시 조당 인원 미리보기 (예: 46 ÷ 8 → 6·6·…·5)
      perGroupBase: groupCount > 0 ? Math.floor(totalRegs / groupCount) : 0,
      perGroupRemainder: groupCount > 0 ? totalRegs % groupCount : 0,
      leaderlessCount: groups.filter(
        (g) => !g.leader_registration_id && !g.leader_name,
      ).length,
    };

    res.json({ groups, summary });
  } catch (err) {
    console.error('말씀조 목록 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /groups/:programId — 조 1개 생성 (admin 이상)
// 조가 어느 언어로 모이는지(025). 배정 엔진이 이 값으로 사람을 나눠 담고,
// 배정 화면이 담당자에게 보여 준다.
//
// **025 이후 읽기만 하고 아무도 쓰지 않았다** — 칸은 있는데 저장할 길이
// 없어서 모든 조가 "아무나 받는 조" 였다. 여기서 받는다.
//
// 빈 문자열은 "정하지 않음" 이다. 화면에서 지웠을 때 되돌아가야 한다.
const STUDY_LANGUAGES = ['ko', 'en', 'es', 'pt'];
function cleanLanguage(v) {
  if (v === null || v === '') return null;
  if (typeof v !== 'string') return undefined;   // 본문에 없음 → 손대지 않는다
  const s = v.trim().toLowerCase();
  if (s === '') return null;
  return STUDY_LANGUAGES.includes(s) ? s : undefined;
}

// 조 정원(051). 0 이나 음수는 아무도 못 들어가는 조가 된다 — DB 제약이
// 막지만 400 으로 돌려주는 편이 낫다. 빈 값은 "정하지 않음" 이다.
function cleanCapacity(v) {
  if (v === null || v === '') return null;
  if (v === undefined) return undefined;          // 본문에 없음 → 손대지 않는다
  const n = Number.parseInt(v, 10);
  if (!Number.isFinite(n) || n <= 0) return undefined;
  return Math.min(999, n);
}

router.post('/:programId', requireAuth, requireProgramAdmin,
  requireScope('groups'), async (req, res) => {
  const { name, passage, location, leaderRegistrationId, leaderName, leaderPhone, sortOrder } = req.body;
  if (!name) return res.status(400).json({ error: 'name이 필요합니다' });
  const language = cleanLanguage(req.body?.studyLanguage) ?? null;
  const capacity = cleanCapacity(req.body?.capacity) ?? null;

  try {
    const [group] = await sql`
      INSERT INTO groups
        (program_id, name, passage, location, leader_registration_id, leader_name, leader_phone, sort_order, study_language, capacity)
      VALUES (
        ${req.params.programId}, ${name}, ${passage ?? null}, ${location ?? null},
        ${leaderRegistrationId ?? null}, ${leaderName ?? null}, ${leaderPhone ?? null}, ${sortOrder ?? 0},
        ${language}, ${capacity}
      )
      RETURNING id, name, passage, location, leader_registration_id, leader_name, leader_phone, sort_order, study_language AS "studyLanguage", capacity, created_at
    `;
    res.status(201).json(group);
  } catch (err) {
    console.error('말씀조 생성 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /groups/:programId/generate — 조 일괄 생성 (admin 이상)
// body: { count, namePattern }  기본 이름 "{n}조" (예: 1조 … 8조)
router.post('/:programId/generate', requireAuth, requireProgramAdmin,
  requireScope('groups'), async (req, res) => {
  const { count, namePattern } = req.body;
  if (!count || count < 1 || count > 100) {
    return res.status(400).json({ error: 'count는 1~100 사이여야 합니다' });
  }

  // 기존 조 개수를 이어 번호 매김 (재생성 시 중복 방지)
  try {
    const [{ max_order }] = await sql`
      SELECT COALESCE(MAX(sort_order), 0) AS max_order
      FROM groups WHERE program_id = ${req.params.programId}
    `;
    const base = Number(max_order);

    const created = await sql.transaction(async (client) => {
      const rows = [];
      for (let i = 1; i <= count; i++) {
        const order = base + i;
        const name = namePattern
          ? namePattern.replace(/#+/, String(order))
          : `${order}조`;
        const { rows: [group] } = await client.query(
          `INSERT INTO groups (program_id, name, sort_order)
           VALUES ($1, $2, $3)
           RETURNING id, name, passage, location, leader_registration_id, leader_name, leader_phone, sort_order, study_language AS "studyLanguage", capacity, created_at`,
          [req.params.programId, name, order],
        );
        rows.push(group);
      }
      return rows;
    });

    res.status(201).json({ created: created.length, groups: created });
  } catch (err) {
    console.error('말씀조 일괄 생성 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /groups/:programId/:groupId — 조 수정 (admin 이상)
router.patch('/:programId/:groupId', requireAuth, requireProgramAdmin,
  requireScope('groups'), async (req, res) => {
  const { name, passage, location, leaderRegistrationId, leaderName, leaderPhone, sortOrder } = req.body;
  // undefined 면 본문에 없거나 모르는 값이다 — 그때는 손대지 않는다.
  const language = cleanLanguage(req.body?.studyLanguage);
  const capacity = cleanCapacity(req.body?.capacity);
  try {
    const [updated] = await sql`
      UPDATE groups SET
        name                   = COALESCE(${name ?? null}, name),
        passage                = COALESCE(${passage ?? null}, passage),
        location               = COALESCE(${location ?? null}, location),
        leader_registration_id = COALESCE(${leaderRegistrationId ?? null}, leader_registration_id),
        leader_name            = COALESCE(${leaderName ?? null}, leader_name),
        leader_phone           = COALESCE(${leaderPhone ?? null}, leader_phone),
        sort_order             = COALESCE(${sortOrder ?? null}, sort_order),
        study_language         = CASE
          WHEN ${language === undefined} THEN study_language
          ELSE ${language ?? null}::text
        END,
        capacity               = CASE
          WHEN ${capacity === undefined} THEN capacity
          ELSE ${capacity ?? null}::int
        END
      WHERE id = ${req.params.groupId} AND program_id = ${req.params.programId}
      RETURNING id, name, passage, location, leader_registration_id, leader_name, leader_phone, sort_order, study_language AS "studyLanguage", capacity, created_at
    `;
    if (!updated) return res.status(404).json({ error: '조를 찾을 수 없습니다' });
    res.json(updated);
  } catch (err) {
    console.error('말씀조 수정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /groups/:programId/:groupId — 조 삭제 (admin 이상)
router.delete('/:programId/:groupId', requireAuth, requireProgramAdmin,
  requireScope('groups'), async (req, res) => {
  try {
    await sql`
      DELETE FROM groups
      WHERE id = ${req.params.groupId} AND program_id = ${req.params.programId}
    `;
    res.json({ success: true });
  } catch (err) {
    console.error('말씀조 삭제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
