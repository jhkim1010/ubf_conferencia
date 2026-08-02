// 생성한 파일을 사용자에게 건네는 경로. 플랫폼마다 방법이 다르다.
//
//   웹     브라우저 다운로드(Blob + <a download>). 임시 디렉터리가 없다 —
//          path_provider 의 getTemporaryDirectory 는 웹에서 예외를 던진다.
//   그 외  임시 파일로 쓴 뒤 공유 시트(share_plus).
//
// 조건부 import 로 갈라 둔다. dart:io 를 웹 번들에 넣으면 빌드가 깨진다.
export 'file_download_io.dart'
    if (dart.library.js_interop) 'file_download_web.dart';
