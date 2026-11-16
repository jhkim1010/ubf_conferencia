import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/features/dashboard/screens/travel_edit_dialog.dart';
import 'package:mana/l10n/app_localizations.dart';

// 담당자가 비행·숙박을 고치는 창 — 손댄 칸만 돌려주는가.
final _reg = <String, dynamic>{
  'id': 'r1',
  'real_name': 'Ana',
  'arrival_flight': {
    'flight_no': 'KE1',
    'airline': 'Korean Air',
    'arrival_airport': 'EZE',
    // 조회 결과로 들어온 UTC 표기. 안 건드렸으면 이대로 가야 한다.
    'scheduled_arrival': '2027-01-20T23:30:00.000Z',
  },
  'departure_flight': {
    'flight_no': 'KE2',
    'departure_airport': 'EZE',
    'scheduled_departure': '2027-01-25T10:00:00.000',
  },
  'hotel_option_key': 'gone', // 지금은 없어진 수준
  'hotel_nights_before': 1,
  'hotel_nights_after': 1,
  'hotel_before_self': false,
  'hotel_after_self': false,
};

final _program = <String, dynamic>{
  'start_date': '2027-01-21',
  'hotel_options': [
    {'key': 'std', 'label': 'Standard', 'pricePerNight': 30},
  ],
};

Future<Future<Map<String, dynamic>?> Function()> _open(
  WidgetTester tester,
) async {
  Map<String, dynamic>? result;
  var done = false;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await showTravelEditDialog(
                ctx,
                reg: _reg,
                program: _program,
              );
              done = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  return () async {
    expect(done, isTrue);
    return result;
  };
}

void main() {
  testWidgets('아무것도 안 고치고 저장하면 보낼 것이 없다', (tester) async {
    final get = await _open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(await get(), isNull);
  });

  testWidgets('편명만 고치면 그 항공편만, 날짜 문자열은 그대로 간다', (tester) async {
    final get = await _open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'KE1'), 'KE9');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final c = (await get())!;
    expect(c.keys, ['arrivalFlight']);
    final a = c['arrivalFlight'] as Map;
    expect(a['flight_no'], 'KE9');
    expect(a['scheduled_arrival'], '2027-01-20T23:30:00.000Z');
    // 이 창에 없는 칸도 남는다.
    expect(a['airline'], 'Korean Air');
    // 없어진 숙박 수준은 손대지 않았으니 보내지 않는다 — 보내면 지워진다.
    expect(c.containsKey('hotelOptionKey'), isFalse);
  });

  testWidgets('출발편을 지우고 앞 숙소를 본인이 구하게 한다', (tester) async {
    final get = await _open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 두 번째 "지우기" 가 출발편이다.
    await tester.tap(find.text('이 항공편 지우기').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('수양회 전 숙소는 본인이 직접 구함'));
    await tester.tap(find.text('수양회 전 숙소는 본인이 직접 구함'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final c = (await get())!;
    expect(c.containsKey('departureFlight'), isTrue);
    expect(c['departureFlight'], isNull);
    expect(c['hotelBeforeSelf'], isTrue);
    expect(c.containsKey('arrivalFlight'), isFalse);
  });
}
