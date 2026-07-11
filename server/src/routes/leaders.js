import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import jwt from 'jsonwebtoken';

const router = Router();

// POST /leaders/register - 리더 등록
router.post('/register', requireAuth, async (req, res) => {
  const { name } = req.body;

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
      INSERT INTO leaders (user_id, gmail, name)
      VALUES (${req.user.userId}, ${user.email}, ${name ?? user.name})
      RETURNING id
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
