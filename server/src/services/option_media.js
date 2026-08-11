// 투어 옵션에 붙는 자료(사진·계획서 PDF)를 저장하기 전에 다듬는다.
//
// 값은 전부 담당자의 브라우저에서 온다. 화면이 올바로 보내 주더라도 요청은
// 얼마든지 손으로 만들 수 있으므로, 여기서 한 번 더 본다.
//
// 특히 **주소**를 그대로 믿으면 안 된다. 이 주소는 나중에 참가자 화면에서
// 그대로 열리므로, `javascript:` 같은 것이 들어오면 그것이 실행 통로가 된다.
// 우리가 저장한 파일(/media/…) 이거나 http(s) 링크, 둘 중 하나만 받는다.
//
// 이 파일에는 DB 도 HTTP 도 없다 — 순수 함수라 test/option_media.test.js 로
// 그대로 확인한다.

/// 사진은 여섯 장까지. 화면(edit_program_screen)도 여섯에서 막지만,
/// 그것은 화면의 사정이고 여기서도 막아야 한다.
export const MAX_PHOTOS = 6;

/// 계획서는 열 장까지. 일정표·비용안내·신청서 정도가 보통이고, 그 이상은
/// 자료실(030)이 맡는 몫이다.
export const MAX_PLAN_DOCS = 10;

/// 이름은 목록에 한 줄로 보여 준다. 길면 화면을 밀어낸다.
export const MAX_DOC_NAME = 120;

// media_store.js 가 만드는 경로 형태. 그쪽 규칙이 바뀌면 여기도 같이 바꾼다.
const MEDIA_RE = /^\/media\/[a-z]+\/[0-9a-f-]{36}\.[a-z0-9]{3,4}$/;

/// 열어도 되는 주소인가.
///
/// `javascript:`·`data:`·`file:` 은 받지 않는다. 참가자 화면이 이 값을
/// launchUrl 에 그대로 넘기기 때문이다.
export function isSafeMediaUrl(v) {
  if (typeof v !== 'string') return false;
  const s = v.trim();
  if (s === '') return false;
  if (MEDIA_RE.test(s)) return true;
  return /^https?:\/\/[^\s]+$/i.test(s);
}

function cleanName(v, fallback) {
  const s = typeof v === 'string' ? v.trim().replace(/\s+/g, ' ') : '';
  if (s === '') return fallback;
  return s.length > MAX_DOC_NAME ? s.slice(0, MAX_DOC_NAME) : s;
}

/// 계획서 목록을 다듬는다. 못 쓸 항목은 **버린다** — 하나가 이상하다고
/// 저장 전체를 막으면, 담당자는 방금 채운 내용을 통째로 잃는다.
export function normalizePlanDocs(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  for (const d of raw) {
    if (!d || typeof d !== 'object') continue;
    if (!isSafeMediaUrl(d.url)) continue;
    const url = String(d.url).trim();
    // 같은 파일을 두 번 넣지 않는다.
    if (out.some((x) => x.url === url)) continue;
    out.push({
      url,
      name: cleanName(d.name, '자료'),
      bytes: Number.isFinite(d.bytes) && d.bytes > 0 ? Math.trunc(d.bytes) : null,
    });
    if (out.length >= MAX_PLAN_DOCS) break;
  }
  return out;
}

/// 사진 주소 목록을 다듬는다.
export function normalizePhotoUrls(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  for (const v of raw) {
    if (!isSafeMediaUrl(v)) continue;
    const url = String(v).trim();
    if (out.includes(url)) continue;
    out.push(url);
    if (out.length >= MAX_PHOTOS) break;
  }
  return out;
}

/// 옵션 하나의 자료 칸만 손본다. 나머지 칸(이름·비용·정원…)은 건드리지
/// 않는다 — 여기서 다 하려 들면 저장 경로가 둘로 갈린다.
export function normalizeOptionMedia(option) {
  if (!option || typeof option !== 'object') return option;
  return {
    ...option,
    photoUrls: normalizePhotoUrls(option.photoUrls),
    planDocs: normalizePlanDocs(option.planDocs),
    // 붙여넣은 링크 칸. 못 쓸 주소면 비운다.
    brochureUrl: isSafeMediaUrl(option.brochureUrl)
      ? String(option.brochureUrl).trim()
      : '',
    videoUrl: isSafeMediaUrl(option.videoUrl)
      ? String(option.videoUrl).trim()
      : '',
  };
}

/// 옵션 배열 전체.
export function normalizeOptions(raw) {
  return Array.isArray(raw) ? raw.map(normalizeOptionMedia) : raw;
}
