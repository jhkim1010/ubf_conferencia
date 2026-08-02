import 'package:web/web.dart' as web;

// 화면 전환 없이 주소만 바꾼다(replaceState). 뒤로 가기 기록도 남기지 않는다 —
// 남기면 뒤로 가기가 다시 초대 링크로 돌아가 같은 자리를 맴돈다.
void clearJoinQuery() {
  final loc = web.window.location;
  if (loc.search.isEmpty) return;
  final url = Uri.parse(loc.href);
  final rest = Map<String, String>.from(url.queryParameters)
    ..removeWhere((k, _) => const {'program', 'uuid', 'id', 'p'}.contains(k));
  final cleaned = url.replace(queryParameters: rest.isEmpty ? null : rest);
  // Uri 는 빈 쿼리에 '?' 를 남기지 않지만 fragment 는 유지한다.
  web.window.history.replaceState(null, '', cleaned.toString());
}
