// 참가자 텔레그램 연결 (047)
//
// 봇은 사람에게 먼저 말을 걸 수 없다. 그 사람이 봇에게 `/start <코드>` 를
// 보내야 하고, 그때 chat_id 를 알게 된다. 그래서 두 걸음이다:
//
//   1) GET  /telegram/:programId/link   — 내 코드와 링크를 받는다
//   2) POST /telegram/:programId/link/check — 돌아온 /start 를 읽어 연결한다
//
// 확인을 사람이 누르게 하는 이유는 웹훅을 걸지 않기 때문이다(047 참고).
import express from 'express';
import crypto from 'node:crypto';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import { getBotUsername, getUpdates } from '../services/telegram.js';
import { collectLinks } from '../services/telegram_link.js';

const router = express.Router();

// 내 등록 행. 없으면 연결할 것도 없다.
async function myRegistration(programId, userId) {
  const [row] = await sql`
    SELECT id, telegram_chat_id, telegram_link_code
    FROM registrations
    WHERE program_id = ${programId} AND user_id = ${userId}
  `;
  return row ?? null;
}

// GET /telegram/:programId/link — 연결 링크
router.get('/:programId/link', requireAuth, async (req, res) => {
  const { programId } = req.params;
  try {
    const reg = await myRegistration(programId, req.user.userId);
    if (!reg) return res.status(404).json({ error: '등록을 찾을 수 없습니다' });

    const [program] = await sql`
      SELECT telegram_bot_token FROM programs
      WHERE id = ${programId} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '수양회를 찾을 수 없습니다' });

    const username = await getBotUsername(program.telegram_bot_token);
    if (!username) {
      // 봇을 안 정해 둔 수양회다. 앱은 이때 버튼을 감춘다.
      return res.json({ available: false, linked: !!reg.telegram_chat_id });
    }

    // 코드는 한 번 만들면 그대로 둔다. 누를 때마다 바꾸면 앞서 연 링크가
    // 죽어, 링크를 열어 두고 나중에 누른 사람이 연결되지 않는다.
    let code = reg.telegram_link_code;
    if (!code) {
      code = crypto.randomBytes(5).toString('hex');
      await sql`
        UPDATE registrations SET telegram_link_code = ${code}
        WHERE id = ${reg.id}
      `;
    }

    res.json({
      available: true,
      linked: !!reg.telegram_chat_id,
      url: `https://t.me/${username}?start=${code}`,
    });
  } catch (err) {
    console.error('텔레그램 링크 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /telegram/:programId/link/check — 돌아온 /start 를 읽는다
router.post('/:programId/link/check', requireAuth, async (req, res) => {
  const { programId } = req.params;
  try {
    const reg = await myRegistration(programId, req.user.userId);
    if (!reg) return res.status(404).json({ error: '등록을 찾을 수 없습니다' });

    const [program] = await sql`
      SELECT telegram_bot_token, telegram_update_offset FROM programs
      WHERE id = ${programId} AND is_active = true
    `;
    if (!program) return res.status(404).json({ error: '수양회를 찾을 수 없습니다' });

    const updates = await getUpdates(
      program.telegram_bot_token,
      program.telegram_update_offset,
    );
    const { links, nextOffset } = collectLinks(updates);

    // **코드로만 찾는다.** 코드는 수양회를 가로질러 유일하므로, 다른
    // 수양회 참가자의 /start 가 섞여 와도 엉뚱한 사람에게 붙지 않는다.
    for (const link of links) {
      await sql`
        UPDATE registrations
        SET telegram_chat_id = ${link.chatId}
        WHERE telegram_link_code = ${link.code}
      `;
    }
    if (nextOffset != null) {
      await sql`
        UPDATE programs SET telegram_update_offset = ${nextOffset}
        WHERE id = ${programId}
      `;
    }

    const after = await myRegistration(programId, req.user.userId);
    res.json({ linked: !!after?.telegram_chat_id });
  } catch (err) {
    console.error('텔레그램 연결 확인 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /telegram/:programId/link — 연결 끊기
router.delete('/:programId/link', requireAuth, async (req, res) => {
  try {
    const reg = await myRegistration(req.params.programId, req.user.userId);
    if (!reg) return res.status(404).json({ error: '등록을 찾을 수 없습니다' });
    // 코드도 함께 지운다. 남겨 두면 예전 링크로 다시 붙는다.
    await sql`
      UPDATE registrations
      SET telegram_chat_id = NULL, telegram_link_code = NULL
      WHERE id = ${reg.id}
    `;
    res.json({ linked: false });
  } catch (err) {
    console.error('텔레그램 연결 해제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
