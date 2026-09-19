// 담당자가 적은 글을 네 언어로 (070)
//
// Google Cloud Translation v2 를 쓴다. 열쇠는 GOOGLE_TRANSLATE_API_KEY 다.
//
// **열쇠가 없으면 번역하지 않는다.** 오류로 만들지 않고 빈손으로 돌아온다 —
// 공지는 나가야 하고, 번역이 안 된다고 못 보내게 하면 그게 더 나쁘다.
//
// **번역이 실패해도 공지는 나간다.** 같은 이유다. 실패한 언어만 비고,
// 화면은 그 자리에 원문을 보여 준다.
//
// 순수한 부분(어느 언어를 옮길지, 결과를 어떻게 합칠지)은 아래 pickTargets·
// mergeTranslations 에 따로 두었다. test/translate_api.test.js 가 그것을 본다.

/// 이 앱이 쓰는 언어. 화면 문구(app_*.arb)와 같은 넷이다.
export const LANGS = ['ko', 'en', 'es', 'pt'];

const ENDPOINT = 'https://translation.googleapis.com/language/translate/v2';

/// 옮겨야 할 언어들. 적은 언어는 뺀다 — 원문이 있는데 기계를 돌릴 이유가 없다.
export function pickTargets(sourceLang) {
  return LANGS.filter((l) => l !== sourceLang);
}

/// 원문과 번역 결과를 한 덩이로.
///
/// 적은 언어 자리에는 **원문**이 들어간다. 그 자리에까지 번역을 넣으면
/// 담당자가 적은 말이 기계가 다듬은 말로 바뀐다.
///
/// 실패했거나 빈 결과는 넣지 않는다 — 빈 문자열을 넣으면 화면이 "번역이
/// 있다" 고 보고 빈 칸을 띄운다.
export function mergeTranslations(sourceLang, original, byLang = {}) {
  const out = {};
  if (sourceLang && original) out[sourceLang] = original;
  for (const [lang, text] of Object.entries(byLang)) {
    const t = typeof text === 'string' ? text.trim() : '';
    if (t !== '' && lang !== sourceLang) out[lang] = t;
  }
  return out;
}

/// 이 사람에게 보여 줄 한 줄. 그 언어가 없으면 원문으로 돌아간다.
export function pickText(i18n, lang, original) {
  if (i18n && typeof i18n === 'object') {
    const t = i18n[lang];
    if (typeof t === 'string' && t.trim() !== '') return t;
  }
  return original;
}

/// 번역기를 쓸 수 있는가.
export function translationEnabled() {
  return !!process.env.GOOGLE_TRANSLATE_API_KEY;
}

/// 한 덩이의 글을 여러 언어로. 실패하면 그 언어만 빠진다.
///
/// 제목과 본문을 한 번에 보낸다 — 호출 수가 줄고, 무엇보다 둘이 같은 문맥
/// 안에서 옮겨진다.
async function translateOnce(texts, target) {
  const key = process.env.GOOGLE_TRANSLATE_API_KEY;
  const res = await fetch(`${ENDPOINT}?key=${encodeURIComponent(key)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ q: texts, target, format: 'text' }),
  });
  if (!res.ok) throw new Error(`번역 API ${res.status}`);
  const json = await res.json();
  const list = json?.data?.translations;
  if (!Array.isArray(list)) throw new Error('번역 API 응답을 읽을 수 없습니다');
  return list.map((t) => t?.translatedText ?? '');
}

/// 제목과 본문을 네 언어로.
///
/// 돌려주는 것은 { title: {...}, body: {...} } 이며, 번역기를 못 쓰면
/// 원문 자리 하나만 든 덩이가 돌아온다.
export async function translateAnnouncement({ title, body, sourceLang }) {
  const src = LANGS.includes(sourceLang) ? sourceLang : 'ko';
  const titleOut = {};
  const bodyOut = {};

  if (translationEnabled() && (title || body)) {
    for (const target of pickTargets(src)) {
      try {
        // 빈 제목을 보내면 빈 줄이 돌아오므로 자리만 맞춰 둔다.
        const [t, b] = await translateOnce([title ?? '', body ?? ''], target);
        if (title) titleOut[target] = t;
        if (body) bodyOut[target] = b;
      } catch (err) {
        // 한 언어가 실패해도 나머지는 보낸다. 공지 자체는 반드시 나가야 한다.
        console.error(`공지 번역 실패(${target}):`, err.message);
      }
    }
  }

  return {
    sourceLang: src,
    title: mergeTranslations(src, title, titleOut),
    body: mergeTranslations(src, body, bodyOut),
  };
}
