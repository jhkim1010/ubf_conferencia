// Telegram Bot API 서비스
//
// 봇은 **수양회마다 다를 수 있다**(029). 수양회를 만들 때 담당자가 자기 봇을
// 적어 두면 그 수양회의 알림은 그 봇으로 나가고, 안 적으면 서버 환경변수
// (TELEGRAM_BOT_TOKEN)의 봇을 쓴다.
//
// 토큰은 비밀값이다. 로그에도 남기지 않는다 — 전송 실패 본문에 토큰이 섞여
// 나오는 일은 없지만, 우리가 먼저 찍지 않는다.
import { sql } from '../db.js';
import { say } from './notify_text.js';

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

/// 알림 문구를 그 사람의 언어로 짓는다(056).
///
/// 문자열이 그대로 오면 손대지 않는다 — 담당자가 적은 공지 본문이 그렇다.
/// 그 말은 그 사람의 말이므로 옮기지 않는다.
function render(message, lang) {
  if (typeof message === 'string') return message;
  if (!message || typeof message !== 'object') return '';
  return say(message.key, message.params, lang || 'ko');
}

export async function notifyProgramAdmins(programId, message) {
  try {
    const [program] = await sql`
      SELECT telegram_chat_id, telegram_bot_token
      FROM programs WHERE id = ${programId}
    `;
    const token = program?.telegram_bot_token || ENV_BOT_TOKEN;
    if (!token) return;

    // 언어별로 나눠 보낸다(056). 공동 관리자가 스페인어를 쓰는데 한 벌로
    // 지어 보내면 그 사람만 못 읽는다.
    //
    // 수양회에 적어 둔 단체 채팅방은 누가 읽을지 알 수 없다. 그 방에는
    // 수양회를 만든 사람의 언어로 보낸다 — 아무 언어나 고르는 것보다 낫다.
    const byLang = new Map();
    const put = (lang, chat) => {
      const k = lang || 'ko';
      if (!byLang.has(k)) byLang.set(k, new Set());
      byLang.get(k).add(chat);
    };

    const admins = await sql`
      SELECT DISTINCT u.telegram_chat_id, u.ui_language
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
    for (const a of admins) put(a.ui_language, a.telegram_chat_id);
    if (program?.telegram_chat_id) {
      put(admins[0]?.ui_language, program.telegram_chat_id);
    }

    await Promise.all(
      [...byLang].flatMap(([lang, chats]) => {
        const text = render(message, lang);
        return [...chats].map((c) => sendMessage(c, text, token));
      }),
    );
  } catch (err) {
    console.error('관리자 알림 오류:', err.message);
  }
}

// ─── 사용자에게 직접 (059) ───────────────────────────────────
//
// 공동 관리자에게 보낼 때 쓴다. 참가자와 달리 수양회에 매인 사람이 아니라
// 계정이므로 users.telegram_chat_id 를 본다.
//
// **연결하지 않은 사람은 조용히 건너뛴다.** 여기서 던지면 분야를 바꾸는
// 일 자체가 실패한다.
export async function notifyUsers(userIds, message) {
  try {
    if (!userIds || userIds.length === 0) return 0;
    const token = ENV_BOT_TOKEN;
    if (!token) return 0;
    const rows = await sql`
      SELECT telegram_chat_id, ui_language FROM users
      WHERE id = ANY(${userIds}) AND telegram_chat_id IS NOT NULL
    `;
    await Promise.all(
      rows.map((r) =>
        sendMessage(r.telegram_chat_id, render(message, r.ui_language), token),
      ),
    );
    return rows.length;
  } catch (err) {
    console.error('관리자 알림 오류:', err.message);
    return 0;
  }
}

// ─── 참가자 개인에게 (047) ───────────────────────────────────
//
// 앱 푸시는 앱을 지웠거나 알림을 꺼 뒀거나 웹으로만 쓰는 사람에게는 가지
// 않는다. 텔레그램을 연결해 둔 사람에게는 이쪽으로도 보낸다 — 둘 다
// 보내는 것은 낭비가 아니라 보험이다.
//
// **연결하지 않은 사람은 조용히 건너뛴다.** 여기서 던지면 봉사 지명 자체가
// 실패한다.
export async function notifyRegistrations(programId, registrationIds, message) {
  try {
    if (!registrationIds || registrationIds.length === 0) return 0;
    const [program] = await sql`
      SELECT telegram_bot_token FROM programs WHERE id = ${programId}
    `;
    const token = program?.telegram_bot_token || ENV_BOT_TOKEN;
    if (!token) return 0;

    const rows = await sql`
      SELECT r.telegram_chat_id, u.ui_language
      FROM registrations r
      LEFT JOIN users u ON u.id = r.user_id
      WHERE r.program_id = ${programId}
        AND r.id = ANY(${registrationIds})
        AND r.telegram_chat_id IS NOT NULL
    `;
    await Promise.all(
      rows.map((r) =>
        sendMessage(r.telegram_chat_id, render(message, r.ui_language), token),
      ),
    );
    return rows.length;
  } catch (err) {
    console.error('참가자 텔레그램 알림 오류:', err.message);
    return 0;
  }
}

// ─── 봇 자신 (연결 링크를 만들 때) ───────────────────────────
//
// 링크는 `https://t.me/<봇이름>?start=<코드>` 다. 봇 이름은 토큰에 들어
// 있지 않으므로 물어봐야 한다.
export async function getBotUsername(token) {
  const botToken = token || ENV_BOT_TOKEN;
  if (!botToken) return null;
  try {
    const res = await fetch(`https://api.telegram.org/bot${botToken}/getMe`);
    if (!res.ok) return null;
    const body = await res.json();
    return body?.result?.username ?? null;
  } catch (err) {
    console.error('getMe 오류:', err.message);
    return null;
  }
}

// ─── 사람이 보낸 /start 를 가져온다 ──────────────────────────
//
// 웹훅을 걸지 않는 이유는 047 에 적어 두었다. offset 을 주지 않으면 같은
// 것을 계속 돌려주므로, 읽은 자리는 호출부가 저장한다.
export async function getUpdates(token, offset) {
  const botToken = token || ENV_BOT_TOKEN;
  if (!botToken) return [];
  try {
    const url = new URL(`https://api.telegram.org/bot${botToken}/getUpdates`);
    if (offset != null) url.searchParams.set('offset', String(offset));
    url.searchParams.set('timeout', '0');
    const res = await fetch(url);
    if (!res.ok) return [];
    const body = await res.json();
    return Array.isArray(body?.result) ? body.result : [];
  } catch (err) {
    console.error('getUpdates 오류:', err.message);
    return [];
  }
}

// ─── 일일 요약 전송 (매일 19:00) ─────────────────────────────
export async function sendDailySummary() {
  try {
    // telegram_chat_id가 설정된 활성 프로그램 전체
    const programs = await sql`
      SELECT p.id, p.name, p.telegram_chat_id, p.telegram_bot_token,
        (SELECT u.ui_language FROM users u
          JOIN leaders l ON l.user_id = u.id
         WHERE l.id = p.leader_id) AS owner_language,
        COUNT(r.id)                                              AS total,
        COUNT(r.id) FILTER (WHERE r.submitted = true)           AS submitted,
        COUNT(pay.id) FILTER (WHERE pay.status = 'pending')     AS pending_payments,
        COUNT(pay.id) FILTER (WHERE pay.status = 'confirmed')   AS confirmed_payments
      FROM programs p
      LEFT JOIN registrations r   ON r.program_id = p.id
      LEFT JOIN payments pay      ON pay.registration_id = r.id
      WHERE p.is_active = true
        AND p.telegram_chat_id IS NOT NULL
      GROUP BY p.id, p.name, p.telegram_chat_id, p.telegram_bot_token, p.leader_id
    `;

    for (const prog of programs) {
      // 단체 채팅방은 누가 읽을지 알 수 없다. 수양회를 만든 사람의
      // 언어로 보낸다(056).
      const text = say('admDailySummary', {
        program: prog.name,
        total: prog.total,
        done: prog.submitted,
        doing: prog.total - prog.submitted,
        pending: prog.pending_payments,
        confirmed: prog.confirmed_payments,
      }, prog.owner_language || 'ko');

      await sendMessage(prog.telegram_chat_id, text, prog.telegram_bot_token);
    }

    console.log(`일일 요약 전송 완료 (${programs.length}개 프로그램)`);
  } catch (err) {
    console.error('일일 요약 전송 오류:', err.message);
  }
}
