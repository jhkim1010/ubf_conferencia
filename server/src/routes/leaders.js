import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import jwt from 'jsonwebtoken';

const router = Router();

// PATCH /leaders/me/chapter — 내 지부 적어 두기
//
// 이미 리더로 등록된 사람은 위 경로가 400 을 준다. 그런데 지부 칸은 033
// 이전에 등록한 사람에게는 비어 있다 — 다시 등록하라고 할 수는 없으므로
// 여기서 채운다. 앱이 "지부장이신가요?" 확인을 지날 때마다 보낸다.
router.patch('/me/chapter', requireAuth, async (req, res) => {
  const chapter = cleanChapter(req.body?.chapter);
  const nationIso = cleanIso(req.body?.nationIso);
  if (!chapter || !nationIso) {
    return res.status(400).json({ error: '지부 정보가 올바르지 않습니다' });
  }
  try {
    const [row] = await sql`
      UPDATE leaders SET chapter = ${chapter}, nation_iso = ${nationIso}
      WHERE user_id = ${req.user.userId}
      RETURNING id
    `;
    if (!row) return res.status(404).json({ error: '리더가 아닙니다' });
    res.json({ ok: true });
  } catch (err) {
    console.error('지부 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /leaders/register - 리더 등록
// 지부 정보(033)는 앱이 "지부장이신가요?" 확인 화면에서 찾아낸 값을 그대로
// 보낸다. 사람이 직접 확인한 값이라 서버가 표를 따로 들고 있는 것보다 낫다.
function cleanChapter(v) {
  const t = String(v ?? '').trim();
  return t.length > 0 && t.length <= 120 ? t : null;
}
function cleanIso(v) {
  const t = String(v ?? '').trim().toUpperCase();
  return /^[A-Z]{2}$/.test(t) ? t : null;
}

router.post('/register', requireAuth, async (req, res) => {
  const { name, chapter, nationIso } = req.body;

  try {
    // 이미 리더인지 확인
    const [existing] = await sql`
      SELECT id FROM leaders WHERE user_id = ${req.user.userId}
    `;

    if (existing) {
      return res.status(400).json({ error: '이미 리더로 등록되어 있습니다' });
    }

    // 이메일로 권한 확인 (선택적: 사전 등록된 이메일만 리더 가능)
    // 현재는 모든 사용자가 리더 등록 가능 (필요 시 whitelist 추가)

    const [user] = await sql`
      SELECT email FROM users WHERE id = ${req.user.userId}
    `;

    const [leader] = await sql`
      INSERT INTO leaders (user_id, gmail, name, chapter, nation_iso)
      VALUES (${req.user.userId}, ${user.email}, ${name ?? user.name},
              ${cleanChapter(chapter)}, ${cleanIso(nationIso)})
      RETURNING id
    `;

    // 역할을 DB 에도 남긴다. leaders 행만 만들고 users.role 을 그대로 두면
    // 다음 로그인 때 역할을 매번 다시 유추해야 하고, 한 경로라도 빠뜨리면
    // 리더가 참가자로 보인다. director 는 강등하지 않는다.
    await sql`
      UPDATE users SET role = 'admin', updated_at = NOW()
      WHERE id = ${req.user.userId} AND role = 'participant'
    `;

    // 리더 권한이 포함된 새 JWT 발급
    const newToken = jwt.sign(
      {
        userId: req.user.userId,
        email: req.user.email,
        name: req.user.name,
        isLeader: true,
        leaderId: leader.id,
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    console.log(`[LEADER] 등록 | userId=${req.user.userId} email=${req.user.email} leaderId=${leader.id} name=${name ?? 'default'}`);
    res.json({ token: newToken, leaderId: leader.id });
  } catch (err) {
    // leaders.gmail 은 users.email 의 복사본인데 동기화되지 않는다. 위의
    // user_id 검사는 이 제약을 잡지 못하므로(다른 열이다), 그대로 두면
    // 유니크 위반이 500 "서버 오류" 로 새어 나가 화면에는 원인이 안 보인다.
    // 실제로 에뮬레이터 점검 중 이 화면이 500 으로 막혔다.
    if (err?.code === '23505') {
      console.warn(`[LEADER] 중복 등록 | userId=${req.user.userId} constraint=${err.constraint}`);
      return res.status(409).json({ error: '이 이메일은 이미 다른 리더 계정에 등록되어 있습니다' });
    }
    console.error('리더 등록 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /leaders/me - 내 리더 정보
router.get('/me', requireAuth, async (req, res) => {
  if (!req.user.isLeader) {
    return res.status(403).json({ error: '리더가 아닙니다' });
  }

  const [leader] = await sql`
    SELECT l.*, u.email FROM leaders l
    JOIN users u ON u.id = l.user_id
    WHERE l.id = ${req.user.leaderId}
  `;

  res.json(leader ?? null);
});

export default router;
