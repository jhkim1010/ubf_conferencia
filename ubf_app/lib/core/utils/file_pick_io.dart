import 'package:image_picker/image_picker.dart';
import 'file_pick.dart';

/// 사진 고르기. 고르는 자리에서 줄인다 — 서버는 1.5MB 까지만 받고,
/// 줄이지 않으면 대부분의 사진이 그 자리에서 거절된다.
Future<PickedUpload?> pickImage() async {
  final x = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 82,
  );
  if (x == null) return null;
  return PickedUpload(await x.readAsBytes(), x.name);
}

/// PDF 는 웹에서만 고른다. 여기서는 못 한다는 뜻으로 null 을 준다 —
/// 화면이 그 사실을 말해 준다.
Future<PickedUpload?> pickPdf() async => null;

/// 이 플랫폼에서 PDF 를 고를 수 있는가.
bool get canPickPdf => false;
