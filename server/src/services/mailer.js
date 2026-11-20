// 메일 보내기 — Gmail SMTP (2026-11)
//
// 환경변수:
//   SMTP_USER  보내는 Gmail 주소
//   SMTP_PASS  그 계정의 "앱 비밀번호"(16자리). 계정 비밀번호가 아니다.
//   MAIL_FROM  (선택) 보내는 사람 표시. 없으면 "UBF <SMTP_USER>"
//   MAIL_DRY_RUN=1  (확인용) 보내지 않고 로그에 찍는다
//
// 설정이 없으면 보내지 않고 로그만 남긴다. 메일이 안 나간다고 담당자의
// 저장이 실패하면 안 된다 — 메일은 덧붙는 알림일 뿐이다.

import nodemailer from 'nodemailer';

let transport = null;
let warned = false;

export function mailConfigured() {
  return !!(process.env.SMTP_USER && process.env.SMTP_PASS);
}

function getTransport() {
  if (transport) return transport;
  transport = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
  return transport;
}

/// 보냈으면 true. 설정이 없거나 실패하면 false — 던지지 않는다.
export async function sendMail({ to, subject, text }) {
  if (!to) return false;
  // 확인용 — 보내지 않고 화면에 찍는다. 받는 주소는 가린다.
  if (process.env.MAIL_DRY_RUN === '1') {
    console.log(`[메일 미리보기] to=${String(to).replace(/^(.).*@/, '$1***@')}\n${subject}\n\n${text}`);
    return true;
  }
  if (!mailConfigured()) {
    if (!warned) {
      console.warn('메일 설정(SMTP_USER/SMTP_PASS)이 없어 메일을 보내지 않습니다');
      warned = true;
    }
    return false;
  }
  try {
    await getTransport().sendMail({
      from: process.env.MAIL_FROM || `UBF <${process.env.SMTP_USER}>`,
      to,
      subject,
      text,
    });
    return true;
  } catch (err) {
    console.error('메일 보내기 실패:', err.message);
    return false;
  }
}
