// 현장 대표 연락처 목록 — 저장 전에 다듬고, 옛 두 컬럼과 이어 준다.
//
// DB 도 HTTP 도 쓰지 않는다. test/program_contacts.test.js 로 그대로 확인한다.

/// 몇 명까지. 공항·숙소·차량·의무 정도를 나눠 맡으면 이 안에 들어온다.
export const MAX_CONTACTS = 10;
export const MAX_NAME = 60;
export const MAX_PHONE = 32;

function clean(v, max) {
  const s = typeof v === 'string' ? v.trim().replace(/\s+/g, ' ') : '';
  return s.length > max ? s.slice(0, max) : s;
}

/// 목록을 다듬는다.
///
/// 이름도 번호도 없는 줄은 버린다 — 화면이 빈 칸을 하나 더 보여 주려고
/// 남겨 두는 줄이 그대로 저장되면, 참가자 화면에 빈 줄이 생긴다.
///
/// 둘 중 하나만 있는 줄은 **남긴다.** 번호만 아는 사람도 있고, 이름만 적어
/// 두고 번호를 나중에 채우는 경우도 있다.
export function normalizeContacts(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  for (const c of raw) {
    if (!c || typeof c !== 'object') continue;
    const name = clean(c.name, MAX_NAME);
    const phone = clean(c.phone, MAX_PHONE);
    if (name === '' && phone === '') continue;
    out.push({ name, phone });
    if (out.length >= MAX_CONTACTS) break;
  }
  return out;
}

/// 읽을 때. 목록이 비어 있으면 005 의 두 컬럼에서 만들어 준다 —
/// 이 기능이 생기기 전에 적어 둔 연락처가 사라지면 안 된다.
export function contactsOf(row) {
  const list = normalizeContacts(row?.contacts);
  if (list.length > 0) return list;
  return normalizeContacts([
    { name: row?.contact1_name, phone: row?.contact1_phone },
    { name: row?.contact2_name, phone: row?.contact2_phone },
  ]);
}

/// 저장할 때. 앞의 두 명은 옛 컬럼에도 함께 적는다 — 옛 앱이 깔린 기기는
/// 아직 그 컬럼을 읽는다.
export function legacyPair(list) {
  const c = normalizeContacts(list);
  return {
    contact1Name: c[0]?.name || null,
    contact1Phone: c[0]?.phone || null,
    contact2Name: c[1]?.name || null,
    contact2Phone: c[1]?.phone || null,
  };
}

/// 본문에서 목록을 뽑는다.
///
/// 새 앱은 contacts 를 보내고, 옛 앱은 contact1Name… 네 칸을 보낸다.
/// 옛 앱이 보낸 값으로 새 목록을 덮어쓰지 않도록, contacts 가 아예 없을
/// 때만 네 칸을 본다.
export function contactsFromBody(body) {
  if (Array.isArray(body?.contacts)) return normalizeContacts(body.contacts);
  const pair = [
    { name: body?.contact1Name, phone: body?.contact1Phone },
    { name: body?.contact2Name, phone: body?.contact2Phone },
  ];
  const list = normalizeContacts(pair);
  return list.length > 0 ? list : null; // null = 손대지 않는다
}

// ── 입금 시점 (041) ──────────────────────────────────────────────

/// 참가비·투어비를 미리 받는가, 와서 받는가.
export const PAYMENT_TIMINGS = ['prepaid', 'onsite'];

/// 모르는 값이 오면 'prepaid' 로 본다.
///
/// 잘못된 값 때문에 입금 카드가 조용히 사라지면, 담당자는 받을 돈이 있다는
/// 사실 자체를 화면에서 잃는다. 사라지는 쪽보다 남는 쪽이 안전하다.
export function normalizePaymentTiming(v) {
  return PAYMENT_TIMINGS.includes(v) ? v : 'prepaid';
}

/// 입금 현황 카드가 필요한가. 둘 중 하나라도 미리 받으면 필요하다.
export function needsPaymentCard(row) {
  return normalizePaymentTiming(row?.fee_payment) === 'prepaid'
    || normalizePaymentTiming(row?.tour_payment) === 'prepaid';
}
