/// 담당자가 적은 글을 보는 사람의 언어로 (071·072)
///
/// 화면 문구(app_*.arb)와 다르다. 저쪽은 우리가 지은 말이라 네 벌이 언제나
/// 있지만, 이쪽은 담당자가 적은 말이라 **한 언어밖에 없을 수 있다.**
/// 번역기를 안 붙인 수양회, 번역이 실패한 언어, 070 이전에 적어 둔 글이
/// 전부 그렇다.
///
/// 그래서 없으면 **원문으로 돌아간다.** 빈 화면보다 못 읽는 글이 낫다 —
/// 적어도 옆 사람에게 보여 주고 물어볼 수는 있다.
///
/// 서버의 services/translate_api.js pickText 와 같은 규칙이다.
/// test/i18n_text_test.dart 가 그 계약을 고정한다.
library;

String? pickI18n(Object? i18n, String lang, Object? original) {
  if (i18n is Map) {
    final v = i18n[lang];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  final o = original;
  if (o is String && o.trim().isNotEmpty) return o;
  return null;
}
