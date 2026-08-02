import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// 네이티브(안드로이드·iOS·데스크톱): 임시 파일로 쓴 뒤 공유 시트를 연다.
// CSV·엑셀 내보내기가 이미 쓰는 경로와 같다.
Future<void> saveBytes(
  Uint8List bytes,
  String filename, {
  String? subject,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], subject: subject ?? filename);
}
