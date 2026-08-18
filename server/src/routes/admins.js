import { Router } from 'express';
import { sql } from '../db.js';
import {
  requireAuth,
  requireDirector,
  requireProgramOwner,
  SCOPES,
} from '../middleware/auth.js';
import { notifyUsers } from '../services/telegram.js';

const router = Router();

// ─── 프로그램 관리자 관리 ─────────────────────────────────────────
//
// 예전에는 director 만 부를 수 있었고 앱에는 화면이 아예 없었다. 그래서
// 수양회를 만든 사람은 명단을 함께 볼 사람을 세울 방법이 없었다.
//
// 이제 **만든 사람**도 세울 수 있다(requireProgramOwner). 공동 관리자로
// 들어온 사람은 명단·배정을 다 보지만 관리자를 더 세우지는 못한다.

// GET /admins/programs/:programId - 특정 프로그램의 관리자 목록
router.get('/programs/:programId', requireAuth, requireProgramOwner, async (req, res) => {
  try {
    // 만든 사람도 함께 준다. 화면은 "누가 이 수양회를 볼 수 있는가" 를
    // 보여 주는 것이지 program_admins 표를 보여 주는 것이 아니다.
    const admins = await sql`
      SELECT u.id, u.email, u.name, u.role, u.telegram_chat_id,
             pa.assigned_at, false AS is_owner, pa.scopes
      FROM program_admins pa
      JOIN users u ON u.id = pa.user_id
      WHERE pa.program_id = ${req.params.programId}
      UNION ALL
      SELECT u.id, u.email, u.name, u.role, u.telegram_chat_id,
             p.created_at AS assigned_at, true AS is_owner, NULL::text[] AS scopes
      FROM programs p
      JOIN leaders l ON l.id = p.leader_id
      JOIN users u ON u.id = l.user_id
      WHERE p.id = ${req.params.programId}
      ORDER BY is_owner DESC, assigned_at
    `;
    res.json(admins);
  } catch (err) {
    console.error('관리자 목록 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /admins/programs/:programId - 관리자 지정 (이메일로 사용자 검색 후 추가)
router.post('/programs/:programId', requireAuth, requireProgramOwner, async (req, res) => {
  const { email, registrationId } = req.body ?? {};
  // 맡길 분야(059). 안 보내면 전부다 — 예전 화면에서 부르던 그대로 둔다.
  const scopes = cleanScopes(req.body?.scopes);
  if (!email && !registrationId) {
    return res.status(400).json({ error: 'email 또는 registrationId 가 필요합니다' });
  }

  try {
    // 참가자 명단에서 고른 경우. 이메일을 몰라도 되고, 오타로 엉뚱한
    // 사람을 세울 일이 없다.
    let user;
    if (registrationId) {
      [user] = await sql`
        SELECT u.id, u.name
        FROM registrations r
        JOIN users u ON u.id = r.user_id
        WHERE r.id = ${registrationId} AND r.program_id = ${req.params.programId}
      `;
      if (!user) {
        return res.status(404).json({ error: '참가자를 찾을 수 없습니다' });
      }
    } else {
      // 목록에 없는 사람은 이메일로. 구글 로그인에 쓰는 주소여야 한다 —
      // 한 번도 로그인한 적이 없으면 계정 자체가 없다.
      [user] = await sql`
        SELECT id, name FROM users WHERE lower(email) = lower(${email})
      `;
      if (!user) {
        return res.status(404).json({ error: '해당 이메일의 사용자를 찾을 수 없습니다' });
      }
    }

    // role을 admin으로 승격 (participant → admin)
    await sql`
      UPDATE users SET role = 'admin'
      WHERE id = ${user.id} AND role = 'participant'
    `;

    // program_admins에 추가
    await sql`
      INSERT INTO program_admins (program_id, user_id, assigned_by, scopes)
      VALUES (${req.params.programId}, ${user.id}, ${req.user.userId}, ${scopes})
      ON CONFLICT (program_id, user_id)
      DO UPDATE SET scopes = EXCLUDED.scopes
    `;

    console.log(`[ADMIN] 지정 | programId=${req.params.programId} userId=${user.id} by=${req.user.userId}`);
    res.json({ success: true, userId: user.id, name: user.name });
  } catch (err) {
    console.error('관리자 지정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

/// 아는 분야 이름만 남긴다. null 이면 전부라는 뜻이다.
///
/// 모르는 이름이 들어오면 **버린다** — 오타 하나로 아무 분야도 못 맡은
/// 사람이 생기느니, 그 이름이 없었던 셈 치는 편이 낫다.
function cleanScopes(raw) {
  if (!Array.isArray(raw)) return null;
  const ok = raw.filter((x) => SCOPES.includes(x));
  // 전부를 고르면 하나하나 적어 두지 않는다. 나중에 분야가 늘면 그 사람도
  // 자동으로 함께 늘어야 한다.
  if (ok.length === 0 || raw.includes('all')) return null;
  return ok;
}

// PATCH /admins/programs/:programId/:userId — 맡은 분야 고치기 (059)
//
// 화면이 조용히 바뀌면 본인이 알 길이 없다. 그래서 바꾼 뒤 **그 사람에게**
// 알린다.
router.patch(
  '/programs/:programId/:userId',
  requireAuth,
  requireProgramOwner,
  async (req, res) => {
    const scopes = cleanScopes(req.body?.scopes);
    try {
      const rows = await sql`
        UPDATE program_admins SET scopes = ${scopes}
        WHERE program_id = ${req.params.programId} AND user_id = ${req.params.userId}
        RETURNING user_id
      `;
      if (rows.length === 0) {
        return res.status(404).json({ error: '사용자 없음' });
      }
      notifyUsers([req.params.userId], {
        key: 'admScopesChanged',
        params: { what: scopes === null ? 'all' : scopes.join(', ') },
      }).catch((e) => console.error('분야 변경 알림 실패:', e.message));
      res.json({ success: true, scopes });
    } catch (err) {
      console.error('관리자 분야 변경 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// DELETE /admins/programs/:programId/:userId - 관리자 제거
router.delete('/programs/:programId/:userId', requireAuth, requireProgramOwner, async (req, res) => {
  try {
    // 만든 사람은 뺄 수 없다. 빼고 나면 아무도 관리자를 세울 수 없어
    // 수양회가 잠긴다 — 되돌릴 방법이 화면에 없다.
    const [owner] = await sql`
      SELECT 1 FROM programs p
      JOIN leaders l ON l.id = p.leader_id
      WHERE p.id = ${req.params.programId} AND l.user_id = ${req.params.userId}
    `;
    if (owner) {
      return res
        .status(409)
        .json({ error: '수양회를 만든 사람은 뺄 수 없습니다' });
    }

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
