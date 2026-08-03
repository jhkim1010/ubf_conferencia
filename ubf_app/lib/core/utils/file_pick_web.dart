import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'file_pick.dart';

// 브라우저의 파일 선택창. 새 의존성 없이 사진과 PDF 를 모두 고를 수 있다.
Future<PickedUpload?> _pick(String accept) {
  final done = Completer<PickedUpload?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = accept
    ..style.display = 'none';
  web.document.body?.append(input);

  void finish(PickedUpload? f) {
    if (!done.isCompleted) done.complete(f);
    input.remove();
  }

  input.onchange = ((web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      finish(null);
      return;
    }
    final file = files.item(0)!;
    final reader = web.FileReader();
    reader.onload = ((web.Event _) {
      final buf = reader.result as JSArrayBuffer?;
      finish(
        buf == null ? null : PickedUpload(buf.toDart.asUint8List(), file.name),
      );
    }).toJS;
    reader.onerror = ((web.Event _) => finish(null)).toJS;
    reader.readAsArrayBuffer(file);
  }).toJS;

  // 사용자가 취소하면 change 가 오지 않는다. 이것이 없으면 화면이 영영 기다린다.
  input.oncancel = ((web.Event _) => finish(null)).toJS;

  input.click();
  return done.future;
}

/// 사진 고르기. 웹에서는 브라우저가 줄여 주지 않으므로 서버 상한을
/// 넘길 수 있다 — 넘기면 서버가 안내 문구와 함께 거절한다.
Future<PickedUpload?> pickImage() => _pick('image/jpeg,image/png,image/webp');

Future<PickedUpload?> pickPdf() => _pick('application/pdf');

bool get canPickPdf => true;
