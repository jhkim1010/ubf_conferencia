import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/features/program/providers/program_provider.dart';
import 'package:mana/features/registration/providers/registration_provider.dart';
import 'package:mana/features/registration/screens/steps/tour_flights_step.dart';
import 'package:mana/features/transport/screens/tour_flights_screen.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 투어 이동(081) 화면을 실제로 그려 본다. 로그인 없이 돌리려고 서버 조회는
// provider 를 덮어쓴다.
const pid = 'p1';
const tourId = 't1';
final program = <String, dynamic>{
  'id': pid,
  'name': 'Conf 2027',
  'start_date': '2027-01-02',
  'end_date': '2027-01-06',
};
final options = <Map<String, dynamic>>[
  {
    'id': tourId,
    'name': 'Iguazu',
    'start_date': '2027-01-07',
    'end_date': '2027-01-09',
  },
];

Widget wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        myCompanionsProvider(pid).overrideWith((_) async => []),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('참가자: 여정이 보이고, 바로 귀국을 켜면 돌아오는 편 자리가 사라진다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        Consumer(
          builder: (context, ref, _) {
            return TourFlightsStep(
              programId: pid,
              program: program,
              options: options,
              flightStepsShown: true,
            );
          },
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TourFlightsStep)),
    );
    final notifier = container.read(registrationFormProvider(pid).notifier);
    notifier.toggleOption(tourId);
    notifier.saveTourLeg(null, {
      'kind': 'tour_out',
      'tour_id': tourId,
      'date': '2027-01-07',
      'time': '08:10',
      'flight_no': 'AR1730',
      'from': 'AEP',
      'to': 'IGR',
    });
    await tester.pumpAndSettle();

    expect(find.text('수양회에 오는 편'), findsOneWidget);
    expect(find.textContaining('AR1730'), findsOneWidget);
    expect(find.text('AEP → IGR · 08:10'), findsOneWidget);
    expect(find.text('돌아오는 편 적기'), findsOneWidget);
    expect(find.text('다음 단계에서 적습니다'), findsOneWidget);

    await tester.tap(find.text('투어지에서 바로 집에 갑니다'));
    await tester.pumpAndSettle();
    expect(find.text('돌아오는 편 적기'), findsNothing);
    expect(find.text('다음 단계에서 투어지 공항에서 출발하는 편을 적어 주세요'), findsOneWidget);
    expect(container.read(registrationFormProvider(pid)).homeFromTour, isTrue);
  });

  testWidgets('참가자: 구간 시트에서 적고 저장하면 목록에 들어간다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        TourFlightsStep(
          programId: pid,
          program: program,
          options: options,
          flightStepsShown: true,
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TourFlightsStep)),
    );
    container.read(registrationFormProvider(pid).notifier).toggleOption(tourId);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('투어 가는 편 적기'));
    await tester.pumpAndSettle();
    expect(find.text('항공편 구간'), findsOneWidget);

    // 아무것도 안 적고 저장하면 막는다.
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('날짜나 항공편 번호를 적어 주세요'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '항공편 번호'), 'la4021');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final legs = container.read(registrationFormProvider(pid)).tourFlights;
    expect(legs.length, 1);
    expect(legs.first['kind'], 'tour_out');
    expect(legs.first['tour_id'], tourId);
    expect(legs.first['flight_no'], 'LA4021');
    expect(find.textContaining('LA4021'), findsOneWidget);
  });

  testWidgets('담당자: 날짜별 묶음과 빈 곳 경고가 보인다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final data = <String, dynamic>{
      'tours': [
        {'id': tourId, 'name': 'Iguazu'},
      ],
      'travelers': 14,
      'groups': [
        {
          'kind': 'tour_out',
          'tour_id': tourId,
          'date': '2027-01-07',
          'time': '08:10',
          'flight_no': 'AR1730',
          'from': 'AEP',
          'to': 'IGR',
          'estimated': false,
          'heads': 12,
          'people': [
            {'registration_id': 'r1', 'name': 'Pablo', 'heads': 3},
          ],
        },
        {
          'kind': 'tour_return',
          'tour_id': tourId,
          'date': '2027-01-09',
          'time': null,
          'flight_no': '',
          'estimated': true,
          'heads': 3,
          'people': [],
        },
      ],
      'direct': [
        {'date': '2027-01-09', 'airport': 'IGR', 'heads': 3, 'people': []},
      ],
      'missing': {
        'return': [
          {'registration_id': 'r2', 'name': 'Ana'},
        ],
        'home': [],
      },
    };

    await tester.pumpWidget(
      wrap(
        const TourFlightsScreen(programId: pid),
        overrides: [
          programTourFlightsProvider(pid).overrideWith((_) async => data),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('투어 이동 일정'), findsOneWidget);
    expect(
      find.text('투어 신청 14명 중 1명이 돌아오는 편을, 0명이 집에 가는 편을 아직 적지 않았습니다.'),
      findsOneWidget,
    );
    expect(find.text('08:10 · AEP → IGR · AR1730'), findsOneWidget);
    expect(find.text('12명'), findsOneWidget);
    expect(find.text('날짜만 적음 · 시각 모름'), findsOneWidget);
    expect(find.text('IGR 에서 출발 · 픽업 없음'), findsOneWidget);

    // "투어 가는 편" 만 보기
    await tester.tap(find.widgetWithText(ChoiceChip, '투어 가는 편'));
    await tester.pumpAndSettle();
    expect(find.text('날짜만 적음 · 시각 모름'), findsNothing);
    expect(find.text('IGR 에서 출발 · 픽업 없음'), findsNothing);
    expect(find.text('12명'), findsOneWidget);

    // 묶음을 펼치면 이름이 나온다
    await tester.tap(find.text('08:10 · AEP → IGR · AR1730'));
    await tester.pumpAndSettle();
    expect(find.text('Pablo'), findsOneWidget);
  });
}
