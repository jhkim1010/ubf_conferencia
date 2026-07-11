import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireLeader } from '../middleware/auth.js';

const router = Router();

// POST /payments - 입금 영수증 등록 (참가자)
router.post('/', requireAuth, async (req, res) => {
  const { programId, amount, paymentMethod, receiptImageUrl } = req.body;

  try {
    // 내 등록 ID 확인
    const [registration] = await sql`
      SELECT id FROM registrations
      WHERE program_id = ${programId} AND user_id = ${req.user.userId}
    `;
    if (!registration) {
      return res.status(404).json({ error: '등록 정보를 먼저 제출해 주세요' });
    }

    const [payment] = await sql`
      INSERT INTO payments (registration_id, amount, payment_method, receipt_image_url)
      VALUES (${registration.id}, ${amount}, ${paymentMethod}, ${receiptImageUrl ?? null})
      ON CONFLICT (registration_id)
      DO UPDATE SET
        amount = EXCLUDED.amount,
        payment_method = EXCLUDED.payment_method,
        receipt_image_url = EXCLUDED.receipt_image_url,
        status = 'pending',
        created_at = NOW()
      RETURNING id, status
    `;

    res.status(201).json(payment);
  } catch (err) {
    console.error('입금 등록 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /payments/:id/confirm - 입금 승인 (리더)
router.patch('/:id/confirm', requireAuth, requireLeader, async (req, res) => {
  const { note } = req.body;

  try {
    // 리더 소유 프로그램의 입금인지 확인
    const [payment] = await sql`
      SELECT pay.id FROM payments pay
      JOIN registrations r ON r.id = pay.registration_id
      JOIN programs p ON p.id = r.program_id
      WHERE pay.id = ${req.params.id}
        AND p.leader_id = ${req.user.leaderId}
    `;
    if (!payment) return res.status(403).json({ error: '권한 없음' });

    await sql`
      UPDATE payments
      SET status = 'confirmed',
          confirmed_by = ${req.user.leaderId},
          confirmed_at = NOW(),
          note = ${note ?? null}
      WHERE id = ${req.params.id}
    `;

    res.json({ success: true });
  } catch (err) {
    console.error('입금 승인 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /payments/:id/reject - 입금 반려 (리더)
router.patch('/:id/reject', requireAuth, requireLeader, async (req, res) => {
  const { note } = req.body;

  try {
    const [payment] = await sql`
      SELECT pay.id FROM payments pay
      JOIN registrations r ON r.id = pay.registration_id
      JOIN programs p ON p.id = r.program_id
      WHERE pay.id = ${req.params.id}
        AND p.leader_id = ${req.user.leaderId}
    `;
    if (!payment) return res.status(403).json({ error: '권한 없음' });

    await sql`
      UPDATE payments
      SET status = 'rejected',
          confirmed_by = ${req.user.leaderId},
          confirmed_at = NOW(),
          note = ${note ?? null}
      WHERE id = ${req.params.id}
    `;

    res.json({ success: true });
  } catch (err) {
    console.error('입금 반려 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
