// 수양회 장부 (053) — 지원·지출을 적고 지금 형편을 본다.
//
// 담당자가 묻는 것은 하나다: "지금 얼마가 모자라나". 참가비는 payments 에,
// 지원과 지출은 여기에 있으므로 합계는 둘을 더해서 낸다.
import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';
import { ledgerSummary, normalizeEntry } from '../services/ledger.js';
import { rateFor } from '../services/fx.js';

const router = Router();

// 참가비 쪽 숫자. 확인된 것만 "받은 돈" 이다 — 확인 전 금액을 세면 장부가
// 실제보다 커지고, 그 숫자를 믿고 예산을 짜게 된다.
async function feeTotals(programId) {
  const [row] = await sql`
    SELECT
      COALESCE(SUM(
        CASE WHEN pay.status = 'confirmed' THEN pay.amount ELSE 0 END
      ), 0)::numeric AS collected,
      COALESCE(SUM(
        GREATEST(
          COALESCE(NULLIF(r.total_cost, 0), p.fee_basic, 0)
            - CASE WHEN pay.status = 'confirmed' THEN COALESCE(pay.amount, 0) ELSE 0 END,
          0
        )
      ), 0)::numeric AS owed
    FROM registrations r
    JOIN programs p ON p.id = r.program_id
    LEFT JOIN payments pay ON pay.registration_id = r.id
    WHERE r.program_id = ${programId} AND counts_as_participant(r.real_name, r.submitted)
  `;
  return {
    collected: Number(row?.collected ?? 0),
    owed: Number(row?.owed ?? 0),
  };
}

// GET /ledger/:programId — 줄 목록 + 합계
router.get('/:programId', requireAuth, requireProgramAdmin, async (req, res) => {
  try {
    const entries = await sql`
      SELECT id, kind, amount, title, note, occurred_on, created_at,
             local_amount AS "localAmount", local_currency AS "localCurrency", rate
      FROM ledger_entries
      WHERE program_id = ${req.params.programId}
      ORDER BY occurred_on DESC, created_at DESC
    `;
    const fees = await feeTotals(req.params.programId);
    res.json({ entries, summary: ledgerSummary({ entries, ...fees }) });
  } catch (err) {
    console.error('장부 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /ledger/:programId — 한 줄 적기
router.post('/:programId', requireAuth, requireProgramAdmin, async (req, res) => {
  const e = normalizeEntry(req.body);
  if (!e) {
    return res.status(400).json({ error: '항목·금액·내용을 확인해 주십시오' });
  }
  try {
    const [row] = await sql`
      INSERT INTO ledger_entries
        (program_id, kind, amount, title, note, occurred_on, created_by,
         local_amount, local_currency, rate)
      VALUES (
        ${req.params.programId}, ${e.kind}, ${e.amount}, ${e.title}, ${e.note},
        COALESCE(${e.occurredOn}::date, CURRENT_DATE),
        ${req.user.leaderId ?? null},
        ${e.localAmount}, ${e.localCurrency}, ${e.rate}
      )
      RETURNING id, kind, amount, title, note, occurred_on, created_at,
                local_amount AS "localAmount", local_currency AS "localCurrency", rate
    `;
    res.status(201).json(row);
  } catch (err) {
    console.error('장부 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /ledger/:programId/:entryId — 고치기
router.patch(
  '/:programId/:entryId',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    const e = normalizeEntry(req.body);
    if (!e) {
      return res.status(400).json({ error: '항목·금액·내용을 확인해 주십시오' });
    }
    try {
      const [row] = await sql`
        UPDATE ledger_entries SET
          kind = ${e.kind}, amount = ${e.amount}, title = ${e.title},
          note = ${e.note},
          occurred_on = COALESCE(${e.occurredOn}::date, occurred_on),
          local_amount = ${e.localAmount},
          local_currency = ${e.localCurrency},
          rate = ${e.rate},
          updated_at = NOW()
        WHERE id = ${req.params.entryId}
          AND program_id = ${req.params.programId}
        RETURNING id, kind, amount, title, note, occurred_on, created_at,
                  local_amount AS "localAmount", local_currency AS "localCurrency", rate
      `;
      if (!row) return res.status(404).json({ error: '항목을 찾을 수 없습니다' });
      res.json(row);
    } catch (err) {
      console.error('장부 수정 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// DELETE /ledger/:programId/:entryId — 지우기
//
// 장부는 실제로 지운다. 잘못 적은 줄을 남겨 두면 합계가 계속 틀리고,
// 취소선 그은 줄을 세는 사람이 생긴다.
router.delete(
  '/:programId/:entryId',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    try {
      const [row] = await sql`
        DELETE FROM ledger_entries
        WHERE id = ${req.params.entryId}
          AND program_id = ${req.params.programId}
        RETURNING id
      `;
      if (!row) return res.status(404).json({ error: '항목을 찾을 수 없습니다' });
      res.json({ ok: true });
    } catch (err) {
      console.error('장부 삭제 오류:', err);
      res.status(500).json({ error: '서버 오류' });
    }
  },
);

// GET /ledger/:programId/rate?currency=ARS — 오늘 환율
//
// **가져온 값은 고칠 수 있는 기본값이다.** 아르헨티나는 공식과 블루가 따로
// 움직이고, 그날 실제로 바꾼 환율이 이것과 다를 수 있다.
router.get(
  '/:programId/rate',
  requireAuth,
  requireProgramAdmin,
  async (req, res) => {
    const r = await rateFor(req.query.currency);
    if (!r) {
      // 못 가져와도 장부는 적을 수 있어야 한다 — 화면이 손으로 넣게 한다.
      return res.status(200).json({ available: false });
    }
    res.json({ available: true, ...r });
  },
);

export default router;
