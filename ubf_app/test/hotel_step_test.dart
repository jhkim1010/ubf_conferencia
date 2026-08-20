import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'package:mana/features/registration/providers/registration_provider.dart';
import 'package:mana/features/registration/screens/steps/hotel_step.dart';
import 'package:mana/core/utils/money.dart';

// 숙박 단계는 "몇 박이 필요한지 계산해서 먼저 알려 준다"가 요지다.
// 계산 자체는 hotel_nights_test.dart 가 본다. 여기서는 그 값이 실제로
// 화면에 나오고 폼에 들어가는지를 본다 — 계산이 맞아도 화면에 안 나오면
// 참가자에게는 없는 기능이다.

const _programId = 'p1';

const _tiers = [
  {'key': 'h1', 'label': '3성급', 'pricePerNight': 50},
  {'key': 'h2', 'label': '4성급', 'pricePerNight': 80},
];

ProviderContainer _container() => ProviderContainer(
  overrides: [registrationProvider(_programId).overrideWith((_) async => null)],
);

Widget _harness(ProviderContainer c) => UncontrolledProviderScope(
  container: c,
  child: MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: HotelStep(
        programId: _programId,
        options: _tiers,
        currency: Currency.usd,
        programStart: '2027-07-05',
        programEnd: '2027-07-09',
        tours: [],
      ),
    ),
  ),
);

void main() {
  testWidgets('항공편이 있으면 필요한 박수를 알려주고 폼에 채운다', (tester) async {
    final c = _container();
    c.read(registrationFormProvider(_programId).notifier).updateArrivalFlight({
      'scheduled_arrival': '2027-07-03T22:00:00.000Z',
    });
    c.read(registrationFormProvider(_programId).notifier).updateDepartureFlight(
      {'scheduled_departure': '2027-07-12T06:00:00.000Z'},
    );

    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    // 3일 도착 → 5일 시작 = 2박, 9일 종료 → 12일 출발 = 3박
    expect(find.textContaining('전 2박'), findsOneWidget);
    expect(find.textContaining('이후 3박'), findsOneWidget);

    final form = c.read(registrationFormProvider(_programId));
    expect(form.hotelNightsBefore, 2);
    expect(form.hotelNightsAfter, 3);
  });

  testWidgets('항공편이 없으면 0 박이라고 단정하지 않는다', (tester) async {
    // 0 을 보여주면 계산이 끝난 줄 알고 그대로 넘어간다.
    final c = _container();
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    expect(find.textContaining('항공편을 적어 주시면'), findsOneWidget);
    expect(c.read(registrationFormProvider(_programId)).hotelNightsBefore, 0);
  });

  testWidgets('박수는 비행 일정을 따라간다 — 손으로 고쳐도 되돌아온다', (tester) async {
    // 060 이전에는 본인이 고친 값을 그대로 두었다. 이제는 저장할 때마다
    // **서버가 비행 일정에서 다시 센다** — 화면에서만 고칠 수 있게 두면
    // 고쳐 놓고도 저장되지 않아, 어느 쪽이 맞는지 아무도 모르게 된다.
    final c = _container();
    final n = c.read(registrationFormProvider(_programId).notifier);
    n.updateArrivalFlight({'scheduled_arrival': '2027-07-03'});
    n.updateDepartureFlight({'scheduled_departure': '2027-07-12'});

    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();
    expect(c.read(registrationFormProvider(_programId)).hotelNightsBefore, 2);

    // 손으로 1박으로 줄여 본다
    n.setHotelNights(before: 1);
    await tester.pumpAndSettle();

    // 다시 그리면 비행 일정에서 나온 값으로 돌아온다
    expect(c.read(registrationFormProvider(_programId)).hotelNightsBefore, 2);
  });

  testWidgets('등급을 고르면 예상 금액이 박수와 곱해져 나온다', (tester) async {
    final c = _container();
    final n = c.read(registrationFormProvider(_programId).notifier);
    n.updateArrivalFlight({'scheduled_arrival': '2027-07-03'});
    n.updateDepartureFlight({'scheduled_departure': '2027-07-12'});

    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    await tester.tap(find.text('4성급'));
    await tester.pumpAndSettle();

    // 80 × 5박 = 400
    expect(find.textContaining('400'), findsWidgets);

    // 참가비와 섞이지 않는다는 안내가 반드시 함께 나와야 한다.
    // ListView 는 화면 밖 항목을 만들지 않으므로 스크롤해서 확인한다.
    await tester.scrollUntilVisible(
      find.textContaining('참가비에는 포함되지 않습니다'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('참가비에는 포함되지 않습니다'), findsOneWidget);
  });
}
