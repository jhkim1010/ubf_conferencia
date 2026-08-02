import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

// 웹: Blob 을 만들어 <a download> 로 내려받는다.
//
// 공유 시트(share_plus)를 쓰지 않는 이유 — 웹 공유 API 는 브라우저마다
// 파일 공유 지원이 갈리고, 데스크톱 크롬에서는 아예 없는 경우가 있다.
// 다운로드는 어디서나 된다.
Future<void> saveBytes(
  Uint8List bytes,
  String filename, {
  String? subject,
}) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // 바로 해제하면 브라우저가 아직 읽는 중일 수 있다. 다음 틱에 정리한다.
  await Future<void>.delayed(const Duration(milliseconds: 100));
  web.URL.revokeObjectURL(url);
}
