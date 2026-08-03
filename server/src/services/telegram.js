// Telegram Bot API 서비스
//
// 봇은 **수양회마다 다를 수 있다**(029). 수양회를 만들 때 담당자가 자기 봇을
// 적어 두면 그 수양회의 알림은 그 봇으로 나가고, 안 적으면 서버 환경변수
// (TELEGRAM_BOT_TOKEN)의 봇을 쓴다.
//
// 토큰은 비밀값이다. 로그에도 남기지 않는다 — 전송 실패 본문에 토큰이 섞여
// 나오는 일은 없지만, 우리가 먼저 찍지 않는다.
import { sql } from '../db.js';

const ENV_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;

// 토큰 형식: <숫자>:<영숫자_-> . 형식만 본다 — 실제 유효성은 텔레그램이 판단한다.
// 검사하는 이유는 담당자가 붙여넣다 잘린 값을 넣어도 아무 일도 안 일어나기
// 때문이다. 그때는 저장 시점에 알려 주는 편이 낫다.
const TOKEN_RE = /^\d{6,}:[A-Za-z0-9_-]{30,}$/;

export function isValidBotToken(v) {
  return typeof v === 'string' && TOKEN_RE.test(v.trim());
}

// ─── 기본 메시지 전송 ──────────────────────────────────────────
// token 을 주면 그 봇으로, 없으면 환경변수 봇으로 보낸다.
export async function sendMessage(chatId, text, token) {
  const botToken = token || ENV_BOT_TOKEN;
  if (!botToken) {
    console.warn('텔레그램 봇 토큰 없음 — 메시지 전송 건너뜀');
    return;
  }
  if (!chatId) return;

  try {
    const res = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
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
      // 토큰은 찍지 않는다. 어느 수양회인지는 호출부 로그로 알 수 있다.
      console.error(`Telegram 전송 실패 (chat_id=${chatId}):`, body);
    }
  } catch (err) {
    console.error('Telegram 전송 오류:', err.message);
  }
}

// ─── 수양회 알림 ─────────────────────────────────────────────
//
// 두 곳으로 보낸다.
//   1) 수양회의 단톡방(programs.telegram_chat_id) — 담당자들이 함께 본다
//   2) 관리자 개인 채팅(users.telegram_chat_id) — 개인이 따로 받아 두는 경우
//
// 1) 은 그 수양회의 봇으로, 2) 도 같은 봇으로 보낸다. 봇이 다르면 참가자가
// 받는 알림과 담당자가 받는 알림이 서로 다른 봇에서 와서 헷갈린다.
//
// 어느 쪽도 없으면 조용히 지나간다. 알림은 부가 기능이고, 여기서 던지면
// 등록 저장 자체가 실패한다.
export async function notifyProgramAdmins(programId, message) {
  try {
    const [program] = await sql`
      SELECT telegram_chat_id, telegram_bot_token
      FROM programs WHERE id = ${programId}
    `;
    const token = program?.telegram_bot_token || ENV_BOT_TOKEN;
    if (!token) return;

    const targets = new Set();
    if (program?.telegram_chat_id) targets.add(program.telegram_chat_id);

    // 프로그램 관리자(program_admins) + 프로그램 생성 리더(leader_id → users)
    const admins = await sql`
      SELECT DISTINCT u.telegram_chat_id
      FROM users u
      WHERE u.telegram_chat_id IS NOT NULL
        AND (
          EXISTS (
            SELECT 1 FROM program_admins pa
            WHERE pa.program_id = ${programId}
              AND pa.user_id = u.id
          )
          OR
          EXISTS (
            SELECT 1 FROM programs p
            JOIN leaders l ON l.id = p.leader_id
            WHERE p.id = ${programId}
              AND l.user_id = u.id
          )
        )
    `;
    for (const a of admins) targets.add(a.telegram_chat_id);

    await Promise.all([...targets].map((c) => sendMessage(c, message, token)));
  } catch (err) {
    console.error('관리자 알림 오류:', err.message);
  }
}

// ─── 일일 요약 전송 (매일 19:00) ─────────────────────────────
export async function sendDailySummary() {
  try {
    // telegram_chat_id가 설정된 활성 프로그램 전체
    const programs = await sql`
      SELECT p.id, p.name, p.telegram_chat_id, p.telegram_bot_token,
        COUNT(r.id)                                              AS total,
        COUNT(r.id) FILTER (WHERE r.submitted = true)           AS submitted,
        COUNT(pay.id) FILTER (WHERE pay.status = 'pending')     AS pending_payments,
        COUNT(pay.id) FILTER (WHERE pay.status = 'confirmed')   AS confirmed_payments
      FROM programs p
      LEFT JOIN registrations r   ON r.program_id = p.id
      LEFT JOIN payments pay      ON pay.registration_id = r.id
      WHERE p.is_active = true
        AND p.telegram_chat_id IS NOT NULL
      GROUP BY p.id, p.name, p.telegram_chat_id, p.telegram_bot_token
    `;

    for (const prog of programs) {
      const text =
        `📊 <b>[${prog.name}] 일일 등록 현황</b>\n\n` +
        `👥 총 등록: ${prog.total}명\n` +
        `✅ 등록 완료: ${prog.submitted}명\n` +
        `⏳ 진행 중: ${prog.total - prog.submitted}명\n` +
        `💰 입금 대기: ${prog.pending_payments}건\n` +
        `✔️ 입금 확인: ${prog.confirmed_payments}건`;

      await sendMessage(prog.telegram_chat_id, text, prog.telegram_bot_token);
    }

    console.log(`일일 요약 전송 완료 (${programs.length}개 프로그램)`);
  } catch (err) {
    console.error('일일 요약 전송 오류:', err.message);
  }
}
