import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin, requireScope } from '../middleware/auth.js';
import { deleteByUrl } from '../services/media_store.js';

const router = Router();

// 수양회 자료실(030) — 교재·순서지 PDF
//
// 담당자가 올리고 참가자가 언제든 다시 본다. 종이는 잃어버리고, 단톡방에
// 올린 파일은 위로 밀려 사라진다.
//
// 파일 자체는 POST /media 로 먼저 올리고, 여기에는 그 결과(url)를 등록한다.
// 두 단계로 나눈 이유는 업로드가 느리기 때문이다 — 제목을 고치려고 파일을
// 다시 올리게 하면 안 된다.

// GET /library/:programId — 참가자용 목록 (공개된 것만)
//
// 등록 여부는 따지지 않는다. UUID 를 아는 사람은 이미 그 수양회의 참가자다.
// 여기서 더 조이면 등록을 끝내지 않은 사람이 교재를 못 본다.
router.get('/:programId', requireAuth, async (req, res) => {
  try {
    const rows = await sql`
      SELECT id, title, description, file_url, mime, bytes, sort_order, created_at
      FROM program_library
      WHERE program_id = ${req.params.programId} AND is_published = true
      ORDER BY sort_order, created_at
    `;
    res.json(rows);
  } catch (err) {
    console.error('자료실 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /library/:programId/all — 담당자용 (안 보이게 둔 것까지)
router.get('/:programId/all', requireAuth, requireProgramAdmin,
  requireScope('comms'), async (req, res) => {
  try {
    const rows = await sql`
      SELECT id, title, description, file_url, mime, bytes, sort_order,
             is_published, created_at
      FROM program_library
      WHERE program_id = ${req.params.programId}
      ORDER BY sort_order, created_at
    `;
    res.json(rows);
  } catch (err) {
    console.error('자료실 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /library/:programId — 자료 등록
router.post('/:programId', requireAuth, requireProgramAdmin,
  requireScope('comms'), async (req, res) => {
  const { title, description, fileUrl, mime, bytes, isPublished } = req.body ?? {};
  const t = String(title ?? '').trim();
  if (!t) return res.status(400).json({ error: '제목이 필요합니다' });

  // 우리가 만든 경로만 받는다. 임의 주소를 받으면 자료실이 아무 사이트로나
  // 사람을 보내는 통로가 된다.
  if (!/^\/media\/library\/[0-9a-f-]{36}\.[a-z0-9]{3,4}$/.test(String(fileUrl ?? ''))) {
    return res.status(400).json({ error: '파일을 먼저 올려 주십시오' });
  }

  try {
    // 새 자료는 맨 뒤에 붙인다. 담당자가 순서를 바꾸기 전까지는 올린 순서다.
    const [{ next }] = await sql`
      SELECT COALESCE(MAX(sort_order), 0) + 1 AS next
      FROM program_library WHERE program_id = ${req.params.programId}
    `;
    const [row] = await sql`
      INSERT INTO program_library
        (program_id, title, description, file_url, mime, bytes, sort_order,
         is_published, uploaded_by)
      VALUES (${req.params.programId}, ${t}, ${description ?? null},
              ${fileUrl}, ${mime ?? null}, ${bytes ?? null}, ${next},
              ${isPublished !== false}, ${req.user.userId})
      RETURNING id
    `;
    res.status(201).json({ id: row.id });
  } catch (err) {
    console.error('자료 등록 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /library/:programId/:id — 제목·설명·공개 여부·순서
router.patch('/:programId/:id', requireAuth, requireProgramAdmin,
  requireScope('comms'), async (req, res) => {
  const { title, description, isPublished, sortOrder } = req.body ?? {};
  try {
    const [row] = await sql`
      UPDATE program_library SET
        title        = COALESCE(${title?.toString().trim() || null}, title),
        description  = ${description ?? null},
        is_published = COALESCE(${isPublished ?? null}, is_published),
        sort_order   = COALESCE(${Number.isInteger(sortOrder) ? sortOrder : null}, sort_order),
        updated_at   = NOW()
      WHERE id = ${req.params.id} AND program_id = ${req.params.programId}
      RETURNING id
    `;
    if (!row) return res.status(404).json({ error: '자료를 찾을 수 없습니다' });
    res.json({ ok: true });
  } catch (err) {
    console.error('자료 수정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /library/:programId/:id — 자료 삭제 (파일까지)
router.delete('/:programId/:id', requireAuth, requireProgramAdmin,
  requireScope('comms'), async (req, res) => {
  try {
    const [row] = await sql`
      DELETE FROM program_library
      WHERE id = ${req.params.id} AND program_id = ${req.params.programId}
      RETURNING file_url
    `;
    if (!row) return res.status(404).json({ error: '자료를 찾을 수 없습니다' });
    // 파일도 지운다. 남겨 두면 아무도 볼 수 없는 파일이 디스크에 쌓인다.
    // 실패해도 목록에서는 이미 사라졌으므로 응답은 성공이다.
    await deleteByUrl(row.file_url);
    res.json({ ok: true });
  } catch (err) {
    console.error('자료 삭제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
