import '../constants/app_constants.dart';

/// 올린 파일의 전체 주소.
///
/// 서버는 상대 경로(`/media/…`)를 저장한다 — 도메인을 옮겨도 DB 를 손볼
/// 일이 없다. 화면에서는 앞을 채워 줘야 한다.
///
/// apiBaseUrl 은 `…/api` 로 끝나는데 미디어는 그 바깥이다. 웹에서는
/// apiBaseUrl 이 `/api` 하나뿐이라 잘라내면 빈 문자열이 되고, 그러면
/// `/media/…` 가 그대로 남아 같은 origin 을 가리킨다 — 그것이 맞다.
String mediaUrl(String path) {
  if (path.startsWith('http')) return path;
  final base = AppConstants.apiBaseUrl;
  final root = base.endsWith('/api')
      ? base.substring(0, base.length - 4)
      : base;
  return '$root$path';
}
