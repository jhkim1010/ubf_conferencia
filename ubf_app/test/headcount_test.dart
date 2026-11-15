import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/headcount.dart';
import 'package:mana/l10n/app_localizations.dart';

// 국제 수양회 인원 표시 — "전체 (외국 n)".
void main() {
  late AppLocalizations ko;
  late AppLocalizations en;

  setUpAll(() async {
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('외국 인원이 오면 괄호로 붙인다', () {
    expect(withForeignCount(ko, ko.unitPeople(12), 5), '12명 (외국 5명)');
    expect(
      withForeignCount(en, en.myProgramsRegistered(12), 5),
      '12 registered (5 from abroad)',
    );
  });

  test('서버의 bigint 문자열도 읽는다', () {
    expect(withForeignCount(ko, ko.unitPeople(12), '5'), '12명 (외국 5명)');
  });

  test('외국 0명도 적는다 — 센 결과다', () {
    expect(withForeignCount(ko, ko.unitPeople(8), 0), '8명 (외국 0명)');
  });

  test('지역 수양회(null)는 괄호 없이 그대로', () {
    expect(withForeignCount(ko, ko.unitPeople(12), null), '12명');
    expect(withForeignCount(ko, ko.unitPeople(12), ''), '12명');
  });
}
