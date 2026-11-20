// 담당자가 등록을 고치면 본인에게 메일로 알린다 (2026-11)
//
// **바로 보내지 않고 모았다가 한 통으로 보낸다.** 담당자 편집 창의 동반자
// 표는 적는 대로 저장되므로(0.7초마다) 한 사람을 고치는 동안 저장이 수십
// 번 일어난다. 그때마다 보내면 받는 사람은 메일 폭탄을 맞는다. 마지막
// 저장 뒤 [QUIET_MS] 동안 더 고치지 않으면 그동안 고친 부분을 모아 보낸다.
//
// 모아 두는 곳은 메모리다. 그 사이 서버가 다시 뜨면 그 한 통은 안 나간다 —
// 메일은 덧붙는 알림이고, 그것 때문에 표를 하나 더 두지는 않는다.
//
// 담당자가 **자기 등록**을 고친 것이면 보내지 않는다.

import { sql } from '../db.js';
import { sendMail } from './mailer.js';
import { composeEditMail, mailLanguage, EDIT_PARTS } from './edit_mail_text.js';

const QUIET_MS = Number(process.env.EDIT_MAIL_QUIET_MS ?? 3 * 60 * 1000);
const APP_URL = process.env.PUBLIC_APP_URL || 'https://ubf.coolsistema.com';

const pending = new Map(); // registrationId → { parts:Set, timer }

/// 담당자가 등록 [registrationId] 의 [part] 를 고쳤다. editorUserId 는
/// 고친 사람 — 본인이 고친 것이면 알리지 않는다.
export function noteAdminEdit(registrationId, part, editorUserId) {
  if (!registrationId || !EDIT_PARTS.includes(part)) return;
  (async () => {
    const [r] = await sql`SELECT user_id FROM registrations WHERE id = ${registrationId}`;
    if (!r || (editorUserId && r.user_id === editorUserId)) return;
    const cur = pending.get(registrationId) ?? { parts: new Set(), timer: null };
    cur.parts.add(part);
    if (cur.timer) clearTimeout(cur.timer);
    cur.timer = setTimeout(() => {
      pending.delete(registrationId);
      sendEditMail(registrationId, [...cur.parts]).catch((err) =>
        console.error('수정 알림 메일 오류:', err.message),
      );
    }, QUIET_MS);
    // 이 타이머 때문에 서버가 꺼지지 못하는 일은 없게 한다.
    cur.timer.unref?.();
    pending.set(registrationId, cur);
  })().catch((err) => console.error('수정 알림 예약 오류:', err.message));
}

/// 지금 등록 상태를 읽어 한 통 보낸다.
export async function sendEditMail(registrationId, parts) {
  const [reg] = await sql`
    SELECT r.id, r.real_name, r.bible_name, r.country, r.total_cost,
           r.cancelled_at, r.selected_options, r.arrival_flight, r.departure_flight,
           u.email, u.ui_language,
           p.name AS program_name, p.currency,
           pay.status AS payment_status
      FROM registrations r
      JOIN programs p ON p.id = r.program_id
      LEFT JOIN users u ON u.id = r.user_id
      LEFT JOIN payments pay ON pay.registration_id = r.id
     WHERE r.id = ${registrationId}
  `;
  if (!reg?.email) return false;
  const [companions, tours] = await Promise.all([
    sql`SELECT real_name AS name, age FROM companions
         WHERE registration_id = ${registrationId} AND registers_separately = false
         ORDER BY created_at`,
    (reg.selected_options ?? []).length
      ? sql`SELECT name FROM program_options
             WHERE id = ANY(${reg.selected_options}) AND is_active ORDER BY name`
      : [],
  ]);
  const lang = mailLanguage(reg.ui_language, reg.country);
  const { subject, text } = composeEditMail({
    lang,
    url: APP_URL,
    parts,
    reg: {
      name: reg.real_name || reg.bible_name || '',
      program: reg.program_name,
      currency: reg.currency,
      total: reg.total_cost,
      cancelled: !!reg.cancelled_at,
      companions,
      tours: tours.map((t) => t.name),
      arrival: reg.arrival_flight?.flight_no ?? '',
      departure: reg.departure_flight?.flight_no ?? '',
      payment: reg.payment_status ?? null,
    },
  });
  return sendMail({ to: reg.email, subject, text });
}
