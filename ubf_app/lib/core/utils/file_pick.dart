// 파일 고르기 — 플랫폼마다 할 수 있는 것이 다르다.
//
// **사진**은 어디서나 고를 수 있다(image_picker, 이미 쓰던 의존성).
// 고르는 자리에서 줄여서 받는다 — 요즘 폰 사진은 5MB 가 넘고, 서버는
// 1.5MB 까지만 받는다.
//
// **PDF** 는 웹에서만 고른다. 브라우저의 <input type="file"> 을 쓰므로
// 새 의존성이 없다. file_picker 를 들이면 다섯 플랫폼에 네이티브 코드가
// 붙는데, 이 저장소는 그런 이유로 릴리스 빌드가 두 번 깨진 적이 있다
// (firebase_cpp_sdk 의 CMake, flutter_secure_storage 의 libsecret).
//
// 자료를 올리는 담당자는 대개 컴퓨터에서 준비한다. 웹에서만 되어도
// 실제 작업에는 지장이 없고, 폰에서는 그 사실을 화면이 말해 준다.
export 'file_pick_io.dart' if (dart.library.js_interop) 'file_pick_web.dart';

/// 고른 파일. 이름은 자료실 제목의 기본값으로만 쓴다 —
/// 서버는 무작위 이름으로 저장한다.
class PickedUpload {
  final List<int> bytes;
  final String name;
  const PickedUpload(this.bytes, this.name);
}
