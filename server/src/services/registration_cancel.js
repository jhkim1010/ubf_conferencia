// 참석 취소·되살리기(076)
//
// 본인이 하든 담당자가 하든 **같은 일**이어야 한다. 둘이 따로 구현되면
// 한쪽만 방을 비우는 식으로 어긋난다.
import { sql } from '../db.js';
import { normalizeCancelReason } from './cancel_reason.js';

/**
 * 참석을 취소한다.
 *
 * 행은 남긴다 — 입금 기록과 적어 둔 내용이 그대로 있어야 환불을 판단하고,
 * 마음을 바꿨을 때 다시 적지 않아도 된다.
 *
 * **방·말씀조·배차 자리는 비운다.** 그 자리는 실제로 남는 침대와 좌석이다.
 * 남겨 두면 담당자는 오지 않을 사람 몫을 계속 잡아 둔다. 함께 오던 동반자
 * (따로 등록하지 못하는 아기 등, 069)의 자리도 같이 비운다.
 * 되살려도 자리는 돌아오지 않는다 — 그사이 다른 사람이 들어갔을 수 있다.
 *
 * 이미 취소된 등록이면 아무것도 하지 않고 null 을 준다.
 */
export async function cancelRegistration({ registrationId, byUserId, reason }) {
  return sql.transaction(async (client) => {
    const { rows } = await client.query(
      `UPDATE registrations
          SET cancelled_at = NOW(), cancelled_by = $2, cancel_reason = $3,
              updated_at = NOW()
        WHERE id = $1 AND cancelled_at IS NULL
        RETURNING id, program_id, real_name, bible_name, cancelled_at`,
      [registrationId, byUserId ?? null, normalizeCancelReason(reason)],
    );
    const row = rows[0];
    if (!row) return null;

    const companions = `SELECT id FROM companions WHERE registration_id = $1`;
    await client.query(
      `DELETE FROM room_assignments
        WHERE registration_id = $1 OR companion_id IN (${companions})`,
      [registrationId],
    );
    await client.query(
      `DELETE FROM run_assignments
        WHERE registration_id = $1 OR companion_id IN (${companions})`,
      [registrationId],
    );
    await client.query(
      `DELETE FROM group_members
        WHERE registration_id = $1 OR companion_id IN (${companions})`,
      [registrationId],
    );
    // 방장·조장이었다면 그 자리를 비운다(010·046).
    await client.query(
      `UPDATE rooms SET leader_registration_id = NULL WHERE leader_registration_id = $1`,
      [registrationId],
    );
    await client.query(
      `UPDATE groups SET leader_registration_id = NULL WHERE leader_registration_id = $1`,
      [registrationId],
    );
    return row;
  });
}

/** 취소를 되돌린다. 취소 전의 제출 여부는 그대로 남아 있다. */
export async function restoreRegistration(registrationId) {
  const [row] = await sql`
    UPDATE registrations
       SET cancelled_at = NULL, cancelled_by = NULL, cancel_reason = NULL,
           updated_at = NOW()
     WHERE id = ${registrationId} AND cancelled_at IS NOT NULL
     RETURNING id, program_id, submitted
  `;
  return row ?? null;
}
