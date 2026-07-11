import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireDirector } from '../middleware/auth.js';

const router = Router();

// ─── Director 전용: 프로그램 관리자 관리 ──────────────────────────

// GET /admins/programs/:programId - 특정 프로그램의 관리자 목록
router.get('/programs/:programId', requireAuth, requireDirector, async (req, res) => {
  try {
    const admins = await sql`
      SELECT u.id, u.email, u.name, u.role, u.telegram_chat_id, pa.assigned_at
      FROM program_admins pa
      JOIN users u ON u.id = pa.user_id
      WHERE pa.program_id = ${req.params.programId}
      ORDER BY pa.assigned_at
    `;
    res.json(admins);
  } catch (err) {
    console.error('관리자 목록 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /admins/programs/:programId - 관리자 지정 (이메일로 사용자 검색 후 추가)
router.post('/programs/:programId', requireAuth, requireDirector, async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'email이 필요합니다' });

  try {
    // 사용자 확인
    const [user] = await sql`SELECT id, name FROM users WHERE email = ${email}`;
    if (!user) return res.status(404).json({ error: '해당 이메일의 사용자를 찾을 수 없습니다' });

    // role을 admin으로 승격 (participant → admin)
    await sql`
      UPDATE users SET role = 'admin'
      WHERE id = ${user.id} AND role = 'participant'
    `;

    // program_admins에 추가
    await sql`
      INSERT INTO program_admins (program_id, user_id, assigned_by)
      VALUES (${req.params.programId}, ${user.id}, ${req.user.userId})
      ON CONFLICT (program_id, user_id) DO NOTHING
    `;

    res.json({ success: true, userId: user.id, name: user.name });
  } catch (err) {
    console.error('관리자 지정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /admins/programs/:programId/:userId - 관리자 제거
router.delete('/programs/:programId/:userId', requireAuth, requireDirector, async (req, res) => {
  try {
    await sql`
      DELETE FROM program_admins
      WHERE program_id = ${req.params.programId}
        AND user_id = ${req.params.userId}
    `;

    // 다른 프로그램에도 admin 권한이 없으면 participant로 되돌림
    const [otherProgram] = await sql`
      SELECT 1 FROM program_admins WHERE user_id = ${req.params.userId} LIMIT 1
    `;
    if (!otherProgram) {
      await sql`
        UPDATE users SET role = 'participant'
        WHERE id = ${req.params.userId} AND role = 'admin'
      `;
    }

    res.json({ success: true });
  } catch (err) {
    console.error('관리자 제거 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ─── 모든 유저 자신: Telegram chat_id 업데이트 ────────────────────

// PATCH /admins/me/telegram - 내 Telegram chat_id 설정
router.patch('/me/telegram', requireAuth, async (req, res) => {
  const { telegramChatId } = req.body;
  if (!telegramChatId) return res.status(400).json({ error: 'telegramChatId가 필요합니다' });

  try {
    await sql`
      UPDATE users SET telegram_chat_id = ${telegramChatId}
      WHERE id = ${req.user.userId}
    `;
    res.json({ success: true });
  } catch (err) {
    console.error('Telegram chat_id 업데이트 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /admins/programs/:programId/telegram - 프로그램 Telegram chat_id 설정 (director)
router.patch('/programs/:programId/telegram', requireAuth, requireDirector, async (req, res) => {
  const { telegramChatId } = req.body;
  if (!telegramChatId) return res.status(400).json({ error: 'telegramChatId가 필요합니다' });

  try {
    await sql`
      UPDATE programs SET telegram_chat_id = ${telegramChatId}
      WHERE id = ${req.params.programId}
    `;
    res.json({ success: true });
  } catch (err) {
    console.error('프로그램 Telegram chat_id 업데이트 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
