// 내보내기 칸 맞춤 — 머리글 수와 줄의 칸 수.
//
// 칸을 하나 더할 때 머리글에만 넣고 줄에 안 넣으면(또는 반대로) 예외는 나지
// 않는다. CSV 는 그냥 한 칸씩 밀린 채로 만들어지고, 받아 본 사람은 국가 칸에
// 지부가 들어 있는 표를 보게 된다. 숙박비 칸(060)을 더하며 실제로 걸린 곳이다.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/export_service.dart';
import 'package:mana/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  for (final withOptions in [true, false]) {
    test('머리글과 줄의 칸 수가 같다 (옵션 $withOptions)', () {
      final headers = ExportService.headersForTest(
        l10n,
        withOptions: withOptions,
      );
      final row = ExportService.rowForTest(l10n, {
        'real_name': '김정호',
        'country': 'KR',
      }, withOptions: withOptions);
      expect(row.length, headers.length);
    });
  }

  test('숙박비는 참가비와 다른 칸이다', () {
    final headers = ExportService.headersForTest(l10n, withOptions: true);
    expect(headers.where((h) => h == l10n.colHotel).length, 1);
    expect(
      headers.indexOf(l10n.colHotel),
      isNot(headers.indexOf(l10n.expTotalCost)),
    );
  });

  test('머물 박이 없으면 숙박비 칸은 비운다', () {
    final headers = ExportService.headersForTest(l10n, withOptions: true);
    final at = headers.indexOf(l10n.colHotel);

    final none = ExportService.rowForTest(l10n, {
      'hotel_nights_before': 0,
      'hotel_nights_after': 0,
      'hotel_cost': 0,
    }, withOptions: true);
    expect(none[at], '');

    final some = ExportService.rowForTest(l10n, {
      'hotel_nights_before': 2,
      'hotel_nights_after': 1,
      'hotel_cost': 300,
    }, withOptions: true);
    expect(some[at], 300);
  });
}
