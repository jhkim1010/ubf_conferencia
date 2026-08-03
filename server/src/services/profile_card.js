// QR 나눔 — 명함 정리·공개 판정 (순수 로직, DB 비의존)

import { randomBytes } from 'crypto';

// ─── QR 토큰 ─────────────────────────────────────────────────
// QR 에는 개인정보가 아니라 이 토큰 하나가 담긴다. 새로 만들면 예전 QR 은
// 그 자리에서 무효가 된다 — 사진에 찍혀도 취소할 방법이 있어야 마음 놓고
// 보여준다.
//
// 주소에 들어가므로 URL 안전 문자만 쓴다. 22자면 추측으로 맞힐 수 없다.
export function newShareToken() {
  return randomBytes(16).toString('base64url');
}

export const TOKEN_RE = /^[A-Za-z0-9_-]{16,64}$/;
export const isValidToken = (v) => typeof v === 'string' && TOKEN_RE.test(v);

// ─── 채널 아이디 ─────────────────────────────────────────────
// 사람마다 다르게 적는다 — `@maria.f`, `instagram.com/maria.f`, 전체 주소,
// 앞뒤 공백까지. 그대로 저장하면 눌렀을 때 열리지 않는다.
//
// **아이디만 남기고 주소는 앱이 만든다.** 그래야 화면에서 @maria.f 로
// 보이고, 눌렀을 때 정식 주소로 열린다.
export function normalizeHandle(raw, { allowSlash = false } = {}) {
  if (typeof raw !== 'string') return null;
  let v = raw.trim();
  if (!v) return null;

  // 주소로 붙여넣은 경우: 도메인까지 걷어낸다.
  v = v.replace(/^https?:\/\//i, '').replace(/^www\./i, '');
  const slash = v.indexOf('/');
  if (v.includes('.') && slash > 0) v = v.slice(slash + 1);

  // 물음표 뒤(추적 파라미터)와 남은 슬래시를 정리한다.
  v = v.split('?')[0];
  if (!allowSlash) v = v.split('/')[0];
  v = v.replace(/^@+/, '').trim();

  // 유튜브는 @핸들과 channel/UC… 두 가지가 있어 슬래시를 허용한다.
  if (!v) return null;
  return /^[A-Za-z0-9._\-/]{1,64}$/.test(v) ? v : null;
}

// 전화번호·WhatsApp. 숫자와 맨 앞 + 만 남긴다 — 괄호와 하이픈은 나라마다
// 규칙이 달라 저장해 봐야 쓸 수 없다.
export function normalizePhone(raw) {
  if (typeof raw !== 'string') return null;
  const v = raw.trim();
  if (!v) return null;
  const plus = v.startsWith('+');
  const digits = v.replace(/\D/g, '');
  if (digits.length < 6 || digits.length > 15) return null;
  return (plus ? '+' : '') + digits;
}

export function normalizeEmail(raw) {
  if (typeof raw !== 'string') return null;
  const v = raw.trim().toLowerCase();
  if (!v) return null;
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v) ? v : null;
}

// ─── 기도제목 ────────────────────────────────────────────────
// 세 개까지. 더 받으면 상대 화면에서 스크롤해야 하고, 그러면 아무도 끝까지
// 읽지 않는다.
export const MAX_PRAYER_TOPICS = 3;
export const MAX_TOPIC_LEN = 200;

export function normalizePrayerTopics(raw) {
  if (!Array.isArray(raw)) return null; // 안 보냈으면 건드리지 않는다
  return raw
    .map((t) => String(t ?? '').trim())
    .filter((t) => t.length > 0)
    .slice(0, MAX_PRAYER_TOPICS)
    .map((t) => t.slice(0, MAX_TOPIC_LEN));
}

// ─── 미성년 잠금 ─────────────────────────────────────────────
// 수양회에는 19세 이하가 온다. 어른과 같은 화면을 주면 전화번호가 처음 만난
// 사람에게 넘어간다.
//
// **연락(이메일·WhatsApp·전화)은 잠근다** — 본인이 켤 수도 없다.
// 채널(Instagram·X·YouTube)은 이미 공개된 계정이라 잠그지 않는다.
// 요절과 기도제목은 나눌 수 있다.
export const JUNIOR_MAX_AGE = 19;

export function isJunior(age) {
  return typeof age === 'number' && Number.isFinite(age) && age <= JUNIOR_MAX_AGE;
}

// 저장할 공개 스위치를 정한다. 나이를 모르면 잠그지 않는다 —
// 모른다고 잠그면 나이를 안 적은 어른이 아무것도 못 나눈다.
export function applyJuniorLock(flags, age) {
  if (!isJunior(age)) return flags;
  return {
    ...flags,
    show_email: false,
    show_whatsapp: false,
    show_phone: false,
  };
}

// ─── 공개 명함 ───────────────────────────────────────────────
// 상대에게 보낼 형태로 깎는다. **꺼 둔 항목은 응답에 아예 싣지 않는다** —
// 값을 보내고 화면에서 감추면, 화면을 거치지 않는 호출에 그대로 새어 나간다.
export function publicCard(row, { name, bibleName, country, branch }) {
  if (!row) return null;
  return {
    name,
    bibleName: bibleName || null,
    country: country || null,
    branch: branch || null,
    photoUrl: row.photo_url || null,
    lifeVerseRef: row.life_verse_ref || null,
    lifeVerseText: row.life_verse_text || null,
    prayerTopics: Array.isArray(row.prayer_topics) ? row.prayer_topics : [],
    contacts: {
      ...(row.show_email && row.email ? { email: row.email } : {}),
      ...(row.show_whatsapp && row.whatsapp ? { whatsapp: row.whatsapp } : {}),
      ...(row.show_phone && row.phone ? { phone: row.phone } : {}),
    },
    channels: {
      ...(row.show_instagram && row.instagram ? { instagram: row.instagram } : {}),
      ...(row.show_x && row.x_handle ? { x: row.x_handle } : {}),
      ...(row.show_youtube && row.youtube ? { youtube: row.youtube } : {}),
    },
  };
}
