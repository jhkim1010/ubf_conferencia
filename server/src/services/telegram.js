// Telegram Bot API 서비스
// 환경변수: TELEGRAM_BOT_TOKEN
import { sql } from '../db.js';

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const API_BASE = `https://api.telegram.org/bot${BOT_TOKEN}`;

// ─── 기본 메시지 전송 ──────────────────────────────────────────
export async function sendMessage(chatId, text) {
  if (!BOT_TOKEN) {
    console.warn('TELEGRAM_BOT_TOKEN 미설정 — 메시지 전송 건너뜀');
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text,
        parse_mode: 'HTML',
      }),
    });

    if (!res.ok) {
      const body = await res.text();
      console.error(`Telegram 전송 실패 (chat_id=${chatId}):`, body);
    }
  } catch (err) {
    console.error('Telegram 전송 오류:', err.message);
  }
}

// ─── 프로그램 관리자 전체에게 알림 ──────────────────────────────
// program_admins 테이블 + 프로그램 소유 leader 포함
export async function notifyProgramAdmins(programId, message) {
  if (!BOT_TOKEN) return;

  try {
    // 프로그램 관리자(program_admins) + 프로그램 생성 리더(leader_id → users)
    const admins = await sql`
      SELECT DISTINCT u.telegram_chat_id
      FROM users u
      WHERE u.telegram_chat_id IS NOT NULL
        AND (
          -- program_admins에 등록된 관리자
          EXISTS (
            SELECT 1 FROM program_admins pa
            WHERE pa.program_id = ${programId}
              AND pa.user_id = u.id
          )
          OR
          -- 프로그램 생성 리더
          EXISTS (
            SELECT 1 FROM programs p
            JOIN leaders l ON l.id = p.leader_id
            WHERE p.id = ${programId}
              AND l.user_id = u.id
          )
        )
    `;

    await Promise.all(admins.map(a => sendMessage(a.telegram_chat_id, message)));
  } catch (err) {
    console.error('관리자 알림 오류:', err.message);
  }
}

// ─── 일일 요약 전송 (매일 19:00) ─────────────────────────────
export async function sendDailySummary() {
  if (!BOT_TOKEN) {
    console.warn('TELEGRAM_BOT_TOKEN 미설정 — 일일 요약 건너뜀');
    return;
  }

  try {
    // telegram_chat_id가 설정된 활성 프로그램 전체
    const programs = await sql`
      SELECT p.id, p.name, p.telegram_chat_id,
        COUNT(r.id)                                              AS total,
        COUNT(r.id) FILTER (WHERE r.submitted = true)           AS submitted,
        COUNT(pay.id) FILTER (WHERE pay.status = 'pending')     AS pending_payments,
        COUNT(pay.id) FILTER (WHERE pay.status = 'confirmed')   AS confirmed_payments
      FROM programs p
      LEFT JOIN registrations r   ON r.program_id = p.id
      LEFT JOIN payments pay      ON pay.registration_id = r.id
      WHERE p.is_active = true
        AND p.telegram_chat_id IS NOT NULL
      GROUP BY p.id, p.name, p.telegram_chat_id
    `;

    for (const prog of programs) {
      const text =
        `📊 <b>[${prog.name}] 일일 등록 현황</b>\n\n` +
        `👥 총 등록: ${prog.total}명\n` +
        `✅ 등록 완료: ${prog.submitted}명\n` +
        `⏳ 진행 중: ${prog.total - prog.submitted}명\n` +
        `💰 입금 대기: ${prog.pending_payments}건\n` +
        `✔️ 입금 확인: ${prog.confirmed_payments}건`;

      await sendMessage(prog.telegram_chat_id, text);
    }

    console.log(`일일 요약 전송 완료 (${programs.length}개 프로그램)`);
  } catch (err) {
    console.error('일일 요약 전송 오류:', err.message);
  }
}
