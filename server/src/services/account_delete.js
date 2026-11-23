// 본인이 앱에서 계정을 지운다 (2026-11)
//
// 애플 심사 지침 5.1.1(v): 앱 안에서 계정을 만들 수 있으면 앱 안에서
// 지울 수도 있어야 한다.
//
// users 행을 지우면 등록·입금·동반자·방 배정·명함 등은 ON DELETE CASCADE
// 로 함께 지워진다. 막히는 것은 "누가 했는가" 만 적어 둔 칸들(입금을 확인한
// 담당자, 일정을 만든 사람 …)인데, 그 기록은 남기고 이름만 비운다.
//
// **수양회를 만든 사람과 director 는 지우지 않는다.** leaders 행이 지워지면
// programs.leader_id 가 비어 그 수양회를 아무도 관리하지 못하게 된다.
// 먼저 다른 사람에게 넘기라고 알린다.

import { sql } from '../db.js';

export class AccountDeleteBlocked extends Error {
  constructor(reason) {
    super(reason);
    this.reason = reason; // 'director' | 'owner'
  }
}

export async function deleteAccount(userId) {
  return sql.transaction(async (c) => {
    const { rows: [user] } = await c.query(
      'SELECT id, role FROM users WHERE id = $1 FOR UPDATE', [userId]);
    if (!user) return false;
    if (user.role === 'director') throw new AccountDeleteBlocked('director');

    const { rows: owned } = await c.query(
      `SELECT 1 FROM programs p JOIN leaders l ON l.id = p.leader_id
        WHERE l.user_id = $1 LIMIT 1`, [userId]);
    if (owned.length) throw new AccountDeleteBlocked('owner');

    // "누가 했는가" 칸 비우기 — 기록 자체는 다른 사람의 것이라 남긴다.
    await c.query('UPDATE payments SET confirmed_by_user = NULL WHERE confirmed_by_user = $1', [userId]);
    await c.query('UPDATE program_admins SET assigned_by = NULL WHERE assigned_by = $1', [userId]);
    await c.query('UPDATE program_schedules SET created_by = NULL WHERE created_by = $1', [userId]);
    await c.query('UPDATE sos_alerts SET resolved_by = NULL WHERE resolved_by = $1', [userId]);
    await c.query('UPDATE program_library SET uploaded_by = NULL WHERE uploaded_by = $1', [userId]);
    await c.query(
      `UPDATE payments SET confirmed_by = NULL
        WHERE confirmed_by IN (SELECT id FROM leaders WHERE user_id = $1)`, [userId]);
    await c.query(
      `UPDATE notifications SET sent_by = NULL
        WHERE sent_by IN (SELECT id FROM leaders WHERE user_id = $1)`, [userId]);

    await c.query('DELETE FROM users WHERE id = $1', [userId]);
    return true;
  });
}
