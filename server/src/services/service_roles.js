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

/// 담당자가 지명했을 때의 첫 상태.
///
/// 승인이 필요한 역할이라도 **본인 수락이 먼저**다. 순서를 뒤집으면
/// 지부장이 승인해 둔 사람이 나중에 거절하는 일이 생긴다.
export function statusOnInvite() {
  return 'invited';
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
