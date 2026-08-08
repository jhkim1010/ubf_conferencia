// 표 내보내기 — PDF 에 한글이 글자로 찍히는가.
//
// pdf 패키지의 기본 글꼴에는 한글이 없어서, 폰트를 빠뜨려도 **예외 하나 없이**
// 두부(□)만 가득한 문서가 나온다. 받아 본 사람이 알려 주기 전에는 모른다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/table_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const headers = ['번호', '본명', '국가', '지부', '성별 / 나이', '못 먹는 것 · 비고'];
  final rows = [
    ['1', '김정호 (베드로)', 'South Korea', '서울', '남 / 34', '땅콩 알레르기'],
    ['2', 'María Fernández', 'Brazil', 'São Paulo', '여 / 41', 'Vegetariana'],
  ];

  test('한글·스페인어가 글리프로 들어간다', () async {
    final bytes = await TableExport.buildPdf(
      title: '식사 제한',
      subtitle: '2027 UBF 국제 수양회 · 2건',
      headers: headers,
      rows: rows,
    );

    final out = Platform.environment['TABLE_PDF_OUT'];
    if (out != null && out.isNotEmpty) await File(out).writeAsBytes(bytes);

    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    final raw = latin1.decode(bytes, allowInvalid: true);
    expect(
      raw.contains('FontFile2'),
      isTrue,
      reason: '번들 폰트가 임베드되지 않았습니다 — 한글이 두부로 나옵니다',
    );
    // 한글 글자체는 무겁다. 기본 글꼴만 쓰였다면 2KB 안팎에 머문다.
    expect(bytes.length, greaterThan(8000));
  });

  test('줄이 없어도 만들어진다', () async {
    final bytes = await TableExport.buildPdf(
      title: '입금 대기',
      subtitle: '',
      headers: headers,
      rows: const [],
    );
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('파일명에 쓸 수 없는 글자를 걷어낸다', () {
    // 수양회 이름에 '/' 나 ':' 가 들어가면 저장이 통째로 실패한다.
    expect(TableExport.safeName('2027/07 수양회: 명단'), '2027_07 수양회_ 명단');
  });
}
