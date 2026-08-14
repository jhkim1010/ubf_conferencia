// 봉사 역할 구성 — 저장 전에 다듬고, 상태 전이를 한 곳에서 판단한다.
//
// DB 도 HTTP 도 쓰지 않는다. test/service_roles.test.js 로 그대로 확인한다.

/// 기본 역할. 이름은 여기 두지 않는다 — ARB 가 4개 언어를 맡는다.
/// 담당자가 수양회마다 켜고 끄며, 필요 인원은 각자 정한다.
export const DEFAULT_SERVICE_ROLES = [
  { key: 'special_song', enabled: true, requires_approval: false, needed: 0 },
  { key: 'mc', enabled: true, requires_approval: false, needed: 0 },
  { key: 'pickup', enabled: true, requires_approval: false, needed: 0 },
  { key: 'cleaning', enabled: true, requires_approval: false, needed: 0 },
  { key: 'tour_guide', enabled: true, requires_approval: false, needed: 0 },
  { key: 'meal_prep', enabled: true, requires_approval: false, needed: 0 },
  { key: 'lodging_backup', enabled: true, requires_approval: false, needed: 0 },
  { key: 'registration_desk', enabled: true, requires_approval: false, needed: 0 },
  { key: 'interpreter', enabled: true, requires_approval: false, needed: 0 },
  { key: 'photo_video', enabled: true, requires_approval: false, needed: 0 },
  { key: 'medical', enabled: true, requires_approval: false, needed: 0 },
  // 지부장과 코디네이터의 동의하에 확정된다 (015 D7)
  { key: 'group_study_leader', enabled: true, requires_approval: true, needed: 0 },
  { key: 'other', enabled: true, requires_approval: false, needed: 0 },
];

/// 기본 역할의 키. 이 목록에 없으면서 custom: 도 아니면 받지 않는다.
export const BUILT_IN_KEYS = new Set(DEFAULT_SERVICE_ROLES.map((r) => r.key));

/// 담당자가 그 자리에서 만든 역할. 이름을 함께 저장한다.
const CUSTOM_RE = /^custom:[0-9a-z-]{6,40}$/;

export const MAX_ROLES = 30;
export const MAX_LABEL = 60;
export const MAX_NEEDED = 999;

export function isValidRoleKey(v) {
  if (typeof v !== 'string') return false;
  return BUILT_IN_KEYS.has(v) || CUSTOM_RE.test(v);
}

export function isCustomKey(v) {
  return typeof v === 'string' && CUSTOM_RE.test(v);
}

function cleanLabel(v) {
  const s = typeof v === 'string' ? v.trim().replace(/\s+/g, ' ') : '';
  if (s === '') return '';
  return s.length > MAX_LABEL ? s.slice(0, MAX_LABEL) : s;
}

function cleanNeeded(v) {
  const n = typeof v === 'number' ? v : Number.parseInt(v, 10);
  if (!Number.isFinite(n) || n < 0) return 0;
  return Math.min(MAX_NEEDED, Math.trunc(n));
}

/// 역할 구성을 다듬는다.
///
/// 못 쓸 항목은 버린다 — 하나가 이상하다고 저장 전체를 막으면 담당자는
/// 방금 채운 구성을 통째로 잃는다.
///
/// 이름 없는 자유 역할은 버린다. 화면에 "custom:9f2c…" 라고 뜨느니 없는
/// 편이 낫다.
// 알림에 적을 역할 이름.
//
// 화면의 이름은 앱이 네 언어로 붙인다(service_role_label.dart). 서버는 키만
// 아는데, 푸시와 텔레그램은 서버가 문장을 만들어 보내므로 여기에도 이름이
// 있어야 한다. 서버가 보내는 다른 알림과 같이 한국어로 적는다.
//
// **담당자가 그 자리에서 만든 역할(custom:)은 적어 준 이름을 그대로 쓴다** —
// 번역할 방법이 없고, 번역해서도 안 된다.
const ROLE_NAMES_KO = {
  special_song: '특송',
  mc: '사회',
  pickup: '픽업',
  cleaning: '청소',
  tour_guide: '투어 안내',
  meal_prep: '식사 준비',
  lodging_backup: '숙소 백업',
  registration_desk: '등록 데스크',
  interpreter: '통역',
  photo_video: '사진·영상',
  medical: '의료',
  group_study_leader: '말씀조 리더',
  other: '봉사',
};

export function roleName(role) {
  if (!role) return '봉사';
  const label = cleanLabel(role.label);
  if (label !== '') return label;
  return ROLE_NAMES_KO[role.key] ?? '봉사';
}

export function normalizeServiceRoles(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  const seen = new Set();
  for (const r of raw) {
    if (!r || typeof r !== 'object') continue;
    if (!isValidRoleKey(r.key)) continue;
    if (seen.has(r.key)) continue;

    const label = cleanLabel(r.label);
    if (isCustomKey(r.key) && label === '') continue;

    seen.add(r.key);
    out.push({
      key: r.key,
      // 기본 역할의 이름은 앱이 붙인다. 여기에 적힌 것은 무시한다 —
      // 두 곳에 이름이 있으면 언젠가 어긋난다.
      ...(isCustomKey(r.key) ? { label } : {}),
      enabled: r.enabled !== false,
      requires_approval: r.requires_approval === true,
      needed: cleanNeeded(r.needed),
    });
    if (out.length >= MAX_ROLES) break;
  }
  return out;
}

/// 저장된 구성이 비어 있으면 기본 구성을 쓴다(015 D3).
export function rolesOf(serviceOptions) {
  const cleaned = normalizeServiceRoles(serviceOptions);
  return cleaned.length > 0 ? cleaned : DEFAULT_SERVICE_ROLES;
}

// ── 상태 ────────────────────────────────────────────────────────

export const STATUSES = [
  'applied',
  'invited',
  'awaiting_approval',
  'confirmed',
  'rejected',
  'declined',
];

/// 등록할 때 적어 낸 자원(009)에 어울리는 역할.
///
/// **추천이 아니라 판정에 쓴다.** "운전할 수 있다" 고 적어 낸 사람에게
/// 픽업을 맡기는 것은 그 사람이 하겠다고 한 일이므로, 다시 물을 이유가
/// 없다. 앱의 같은 표(service_role_label.dart)와 짝을 이룬다 — 한쪽만
/// 고치면 화면의 추천과 서버의 판정이 어긋난다.
const ROLE_BY_RESOURCE = {
  piano: 'special_song',
  guitar: 'special_song',
  bass: 'special_song',
  drums: 'special_song',
  violin: 'special_song',
  vocals: 'special_song',
  worship_lead: 'special_song',
  sound: 'special_song',
  translation: 'interpreter',
  photography: 'photo_video',
  cooking: 'meal_prep',
  driving: 'pickup',
  medical: 'medical',
};

export function roleForResource(resourceKey) {
  return ROLE_BY_RESOURCE[resourceKey] ?? null;
}

/// 이 사람이 이 역할을 **스스로 하겠다고 한** 적이 있는가.
///
/// 둘 중 하나면 그렇다:
///   - 등록할 때 그 일을 할 수 있다고 적어 냈다(volunteer_resources)
///   - 이미 그 역할에 손을 들었다(applied)
export function offeredThis(role, { resources, applied } = {}) {
  if (!role?.key) return false;
  if (applied === true) return true;
  const list = Array.isArray(resources) ? resources : [];
  return list.some((r) => roleForResource(r) === role.key);
}

/// 담당자가 지명했을 때의 첫 상태.
///
/// **스스로 하겠다고 한 일이면 곧바로 맡긴다.** 자기가 적어 낸 것을 두고
/// 다시 "하시겠습니까" 를 묻는 것은 한 번 더 누르게 할 뿐이고, 그동안
/// 담당자는 자리가 찼는지 모른 채 기다린다. 알림은 그대로 간다 —
/// 맡았다는 것은 알아야 한다.
///
/// **적어 내지 않은 일이면 물어본다.** 하지 않겠다고 한 적도 없지만
/// 하겠다고 한 적도 없는 일이므로, 본인이 답해야 확정이다.
///
/// 승인이 필요한 역할(말씀조 리더)은 어느 쪽이든 지부장 동의가 남는다.
export function statusOnInvite(role, offer) {
  if (!offeredThis(role, offer)) return 'invited';
  return statusOnConfirm(role);
}

/// 담당자가 확정을 눌렀을 때.
///
/// 승인이 필요한 역할은 바로 확정되지 않는다.
export function statusOnConfirm(role) {
  return role?.requires_approval === true ? 'awaiting_approval' : 'confirmed';
}

/// 본인이 답했을 때. 수락은 역할에 따라 확정 또는 승인 대기로 간다.
export function statusOnRespond(role, accepted) {
  if (!accepted) return 'declined';
  return statusOnConfirm(role);
}

/// 사람 수를 셀 때 **자리를 차지한 것으로 보는** 상태.
///
/// 수락 대기와 승인 대기도 센다. 아직 답이 없다고 자리를 비워 두면 담당자가
/// 같은 자리에 또 부탁하게 된다. 거절·반려만 뺀다.
export function occupiesSeat(status) {
  return status === 'applied'
    || status === 'invited'
    || status === 'awaiting_approval'
    || status === 'confirmed';
}

/// 역할 하나의 집계.
export function tallyRole(role, signups) {
  const mine = signups.filter((s) => s.service_key === role.key);
  const filled = mine.filter((s) => occupiesSeat(s.status));
  const confirmed = mine.filter((s) => s.status === 'confirmed');
  const needed = cleanNeeded(role.needed);
  return {
    needed,
    filled: filled.length,
    confirmed: confirmed.length,
    waiting: mine.filter((s) => s.status === 'invited').length,
    applied: mine.filter((s) => s.status === 'applied').length,
    // 필요 인원을 정하지 않았으면 부족분도 없다. 0 으로 두면 모든 역할이
    // "다 찼다" 로 보인다.
    short: needed === 0 ? 0 : Math.max(0, needed - filled.length),
  };
}

/// 화면에 늘어놓는 차례. **모자란 역할이 위로** 온다 — 담당자가 화면을
/// 열자마자 할 일을 봐야 한다.
export function sortRoles(roles, signups) {
  return [...roles].sort((a, b) => {
    const ta = tallyRole(a, signups);
    const tb = tallyRole(b, signups);
    if (tb.short !== ta.short) return tb.short - ta.short;
    // 그 다음은 답을 기다리는 사람이 많은 순.
    if (tb.waiting !== ta.waiting) return tb.waiting - ta.waiting;
    return String(a.key).localeCompare(String(b.key));
  });
}

// ── 도움 요청 (043) ──────────────────────────────────────────────

/// 다시 울리기까지 두는 시간. 같은 역할로 몇 번이고 알림이 오면 사람들이
/// 알림 자체를 꺼 버린다.
export const RECALL_HOURS = 6;

/// 지금 이 역할로 요청을 보낼 수 있는가.
///
/// 이유를 함께 돌려준다 — 화면이 "왜 못 보내는지" 를 말해 줘야 담당자가
/// 버튼이 고장 났다고 여기지 않는다.
export function canBroadcast({ role, tally, lastCall, now = Date.now() }) {
  if (!role || role.enabled === false) {
    return { ok: false, reason: 'role_off' };
  }
  // 필요 인원을 안 정했으면 모자란지 알 수 없다.
  if (!tally || tally.needed <= 0) return { ok: false, reason: 'no_target' };
  if (tally.short <= 0) return { ok: false, reason: 'already_filled' };

  if (lastCall && !lastCall.closed_at) {
    const sent = new Date(lastCall.sent_at).getTime();
    if (Number.isFinite(sent) && now - sent < RECALL_HOURS * 3600 * 1000) {
      return { ok: false, reason: 'too_soon', retryAfter: sent + RECALL_HOURS * 3600 * 1000 };
    }
  }
  return { ok: true };
}

/// 참가자에게 보일 "모집 중" 역할인가.
///
/// 열린 요청이 있고, 아직 모자라고, 내가 이미 손을 들지 않았을 때만 보인다.
/// 이미 손을 든 사람에게 계속 물으면 재촉으로 읽힌다.
export function isOpenForMe({ call, tally, myStatus }) {
  if (!call || call.closed_at) return false;
  if (!tally || tally.short <= 0) return false;
  return myStatus === undefined || myStatus === null
    || myStatus === 'declined' || myStatus === 'rejected';
}
