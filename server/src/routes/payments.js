import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireLeader, mayTouch } from '../middleware/auth.js';

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
router.patch('/:id/confirm', requireAuth, async (req, res) => {
  const { note } = req.body;

  try {
    // **회계 담당과 만든 사람이 승인한다(059).** 예전에는 만든 사람만
    // 했는데, 명단에서 받은 금액을 고치는 것은 공동 관리자도 되고 있어서
    // 같은 일을 두 길로 하는데 권한이 달랐다.
    const [payment] = await sql`
      SELECT pay.id, r.program_id AS "programId" FROM payments pay
      JOIN registrations r ON r.id = pay.registration_id
      WHERE pay.id = ${req.params.id}
    `;
    if (!payment) return res.status(404).json({ error: '항목을 찾을 수 없습니다' });
    if (!(await mayTouch(payment.programId, req.user, 'ledger'))) {
      return res.status(403).json({ error: '이 분야는 맡지 않으셨습니다' });
    }

    await sql`
      UPDATE payments
      SET status = 'confirmed',
          -- 만든 사람이면 leaders 행이 있고, 회계 담당이면 없다. 둘 다
          -- 남겨 둬야 누가 승인했는지 알 수 있다(059).
          confirmed_by = ${req.user.leaderId ?? null},
          confirmed_by_user = ${req.user.userId},
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
router.patch('/:id/reject', requireAuth, async (req, res) => {
  const { note } = req.body;

  try {
    // **회계 담당과 만든 사람이 승인한다(059).** 예전에는 만든 사람만
    // 했는데, 명단에서 받은 금액을 고치는 것은 공동 관리자도 되고 있어서
    // 같은 일을 두 길로 하는데 권한이 달랐다.
    const [payment] = await sql`
      SELECT pay.id, r.program_id AS "programId" FROM payments pay
      JOIN registrations r ON r.id = pay.registration_id
      WHERE pay.id = ${req.params.id}
    `;
    if (!payment) return res.status(404).json({ error: '항목을 찾을 수 없습니다' });
    if (!(await mayTouch(payment.programId, req.user, 'ledger'))) {
      return res.status(403).json({ error: '이 분야는 맡지 않으셨습니다' });
    }

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
