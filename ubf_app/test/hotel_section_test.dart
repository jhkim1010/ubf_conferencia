// 숙박 수준 고치기 — key 를 지키는가.
//
// **key 는 등록 자료가 가리킨다**(registrations.hotel_option_key). 수준을
// 고치면서 key 를 새로 붙이면, 그 수준을 고른 참가자의 등록이 없는 것을
// 가리키게 되고 숙박비가 조용히 0 이 된다. 아무도 오류를 보지 못한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/money.dart';
import 'package:mana/features/program/widgets/hotel_section.dart';
import 'package:mana/l10n/app_localizations.dart';

void main() {
  test('고칠 때는 받은 key 를 그대로 쓴다', () {
    final level = buildHotelLevel(
      labels: const {'ko': '일반실', 'en': 'Standard'},
      price: 30,
      key: 'h2',
    );
    expect(level['key'], 'h2');
    expect(level['pricePerNight'], 30);
    expect((level['labels'] as Map)['ko'], '일반실');
  });

  test('대표 이름은 영어, 없으면 한국어, 그것도 없으면 있는 것', () {
    expect(
      buildHotelLevel(
        labels: const {'ko': '고급', 'en': 'Deluxe'},
        price: null,
        key: 'h1',
      )['label'],
      'Deluxe',
    );
    expect(
      buildHotelLevel(
        labels: const {'ko': '고급'},
        price: null,
        key: 'h1',
      )['label'],
      '고급',
    );
    expect(
      buildHotelLevel(
        labels: const {'pt': 'Luxo'},
        price: null,
        key: 'h1',
      )['label'],
      'Luxo',
    );
  });

  test('단가를 안 정했으면 0 이 아니라 비운다', () {
    // 0 으로 넣으면 참가자가 공짜인 줄 안다.
    expect(
      buildHotelLevel(
        labels: const {'en': 'X'},
        price: null,
        key: 'h1',
      )['pricePerNight'],
      isNull,
    );
    expect(
      buildHotelLevel(
        labels: const {'en': 'X'},
        price: -5,
        key: 'h1',
      )['pricePerNight'],
      isNull,
    );
    expect(
      buildHotelLevel(
        labels: const {'en': 'X'},
        price: 0,
        key: 'h1',
      )['pricePerNight'],
      0,
      reason: '0 을 직접 적은 것은 "공짜" 라는 뜻이니 그대로 둔다',
    );
  });

  test('새 key 는 쓴 적 없는 번호다', () {
    expect(nextHotelKey(const []), 'h1');
    expect(
      nextHotelKey(const [
        {'key': 'h1'},
        {'key': 'h2'},
      ]),
      'h3',
    );
  });

  testWidgets('카드를 눌러 고치면 제자리에서 바뀌고 key 는 그대로다', (tester) async {
    final levels = <Map<String, dynamic>>[
      {
        'key': 'h1',
        'label': 'Deluxe',
        'labels': {'ko': '고급', 'en': 'Deluxe'},
        'pricePerNight': 100,
      },
      {
        'key': 'h2',
        'label': 'Standard',
        'labels': {'ko': '일반실', 'en': 'Standard'},
        'pricePerNight': 30,
      },
    ];
    await tester.pumpWidget(_harness(levels));
    await tester.pumpAndSettle();

    // 둘째 카드의 연필을 누른다
    await tester.tap(find.byIcon(Icons.edit_outlined).last);
    await tester.pumpAndSettle();

    // 그 줄의 값이 아래 칸으로 올라왔는가
    expect(find.widgetWithText(TextFormField, '일반실'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '30'), findsOneWidget);

    // 단가를 45 로 고치고 저장
    await tester.enterText(find.widgetWithText(TextFormField, '30'), '45');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(levels.length, 2, reason: '고쳤는데 하나 더 생기면 안 된다');
    expect(levels.map((o) => o['key']), ['h1', 'h2'], reason: 'key 도 순서도 그대로');
    expect(levels[1]['pricePerNight'], 45);
    expect((levels[1]['labels'] as Map)['ko'], '일반실');
  });

  testWidgets('고치기를 취소하면 아무것도 안 바뀐다', (tester) async {
    final levels = <Map<String, dynamic>>[
      {
        'key': 'h1',
        'label': 'Deluxe',
        'labels': {'en': 'Deluxe'},
        'pricePerNight': 100,
      },
    ];
    await tester.pumpWidget(_harness(levels));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '100'), '999');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(levels.single['pricePerNight'], 100);
  });

  test('가운데를 지워도 옛 key 가 되살아나지 않는다', () {
    // h1·h2·h3 에서 h2 를 지우면 남은 것은 둘. 길이로 번호를 매기면 h3 이
    // 나와 이미 쓰는 중인 key 와 부딪힌다.
    final after = [
      {'key': 'h1'},
      {'key': 'h3'},
    ];
    final k = nextHotelKey(after);
    expect(after.map((o) => o['key']), isNot(contains(k)));
    expect(k, 'h4');
  });
}

// ── 화면에서 실제로 고쳐지는가 ──────────────────────────────────────

Widget _harness(List<Map<String, dynamic>> levels) => MaterialApp(
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      child: HotelSection(
        hotelOptions: levels,
        onChanged: () {},
        currency: Currency.usd,
      ),
    ),
  ),
);
