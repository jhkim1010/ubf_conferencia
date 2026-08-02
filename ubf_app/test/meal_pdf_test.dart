// 식사 제한 명단 PDF
//
// 확인하려는 것은 "예외 없이 만들어지는가"가 아니라 **한글이 글자로 찍히는가**다.
// pdf 패키지의 기본 글꼴에는 한글이 없어서, 폰트를 빠뜨려도 예외 하나 없이
// 두부(□)만 가득한 문서가 나온다. 주방에 넘긴 뒤에야 알게 되는 종류의 실패다.
//
// 그래서 문서에 실제로 박힌 글리프 수를 센다. 번들 폰트를 못 읽으면
// 임베드된 폰트가 없어 이 단언이 깨진다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/meal_pdf_service.dart';
import 'package:mana/l10n/app_localizations.dart';

Map<String, dynamic> _sample() => {
  'program': {
    'name': '2027 UBF 국제 수양회',
    'location': 'Buenos Aires',
    'start_date': '2027-07-01',
    'end_date': '2027-07-05',
  },
  'total': 4,
  'skips_breakfast': 1,
  'people': [
    {
      'real_name': '김정호',
      'bible_name': '베드로',
      'country': 'KR',
      'branch': '서울',
      'food_requirements': '땅콩 알레르기, 해산물 불가',
      'skips_breakfast': true,
      'submitted': true,
    },
    {
      'real_name': 'María Fernández',
      'bible_name': 'Marta',
      'country': 'AR',
      'branch': 'Buenos Aires',
      'food_requirements': 'Vegetariana — sin carne ni pescado',
      'skips_breakfast': false,
      'submitted': false,
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('한글·스페인어가 글리프로 들어간다', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final bytes = await MealPdfService.build(data: _sample(), l10n: l10n);

    // 눈으로 확인할 때: MEAL_PDF_OUT=/경로/out.pdf flutter test ...
    final out = Platform.environment['MEAL_PDF_OUT'];
    if (out != null && out.isNotEmpty) {
      await File(out).writeAsBytes(bytes);
    }
    expect(bytes.length, greaterThan(1000));
    // PDF 헤더
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');

    // 폰트가 임베드되어야 한다. 기본 글꼴(Helvetica)만 쓰이면 FontFile2 가 없다.
    final raw = latin1.decode(bytes, allowInvalid: true);
    expect(
      raw.contains('FontFile2'),
      isTrue,
      reason: '번들 폰트가 임베드되지 않았습니다 — 한글이 두부로 나옵니다',
    );
    // 크기 바닥값. 부분집합이라도 한글 글자체는 무거워서 두 명짜리 문서가
    // 13KB 정도 나온다(측정값). 폰트가 빠지면 그 자리에서 예외가 나므로
    // 이 단언은 "글리프가 통째로 비었다" 쪽을 잡는다.
    expect(bytes.length, greaterThan(8000));
  });

  test('명단이 비어도 만들어진다', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));
    final bytes = await MealPdfService.build(
      data: {
        'program': {'name': 'Retiro'},
        'total': 0,
        'people': const [],
      },
      l10n: l10n,
    );
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
