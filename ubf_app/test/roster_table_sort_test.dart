import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'package:mana/features/dashboard/screens/roster_table_screen.dart';
import 'package:mana/features/program/providers/program_provider.dart';

// 전체 명단의 머리글을 누르면 **그 칸으로** 줄이 선다.
//
// 예전에는 줄 세우기 값을 칸 번호로 따로 골랐다. 전화번호 칸(068)이
// 끼어들면서 번호가 밀렸는데 그쪽은 그대로여서, 전화번호를 누르면 상태로,
// 상태를 누르면 입금으로 섰고 입금은 아예 안 섰다. 칸마다 실제로 눌러 본다.

const _programId = 'p1';

// 이름 순서와 전화번호 순서가 일부러 어긋나게 둔다 — 그래야 엉뚱한 칸으로
// 섰을 때 드러난다.
final _people = <Map<String, dynamic>>[
  {
    'id': 'r1',
    'real_name': 'Ana',
    'country': 'AR',
    'gender': 'F',
    'age': 30,
    'phone': '333',
    'submitted': true,
    'amount_due': 100,
    'payment': {'status': null, 'amount': null},
  },
  {
    'id': 'r2',
    'real_name': 'Bruno',
    'country': 'AR',
    'gender': 'M',
    'age': 25,
    'phone': '111',
    'submitted': false,
    'amount_due': 100,
    'payment': {'status': 'confirmed', 'amount': 100},
  },
  {
    'id': 'r3',
    'real_name': 'Carla',
    'country': 'AR',
    'gender': 'F',
    'age': 41,
    'phone': '222',
    'submitted': true,
    'amount_due': 300,
    'payment': {'status': null, 'amount': null},
  },
];

Widget _harness() => ProviderScope(
  overrides: [
    programRegistrationsProvider(_programId).overrideWith((_) async => _people),
    programByIdProvider(
      _programId,
    ).overrideWith((_) async => {'name': 'Test', 'currency': 'USD'}),
  ],
  child: const MaterialApp(
    locale: Locale('ko'),
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: RosterTableScreen(programId: _programId, view: RosterView.all),
  ),
);

/// 표에 보이는 이름 차례. 이름 칸 글자에서 첫 낱말만 본다.
List<String> _order(WidgetTester tester) {
  final names = <String>[];
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    final s = t.data ?? '';
    for (final n in ['Ana', 'Bruno', 'Carla']) {
      if (s.startsWith(n)) names.add(n);
    }
  }
  return names;
}

void main() {
  setUp(() {});

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
  }

  Future<void> tapHeader(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  testWidgets('전화번호를 누르면 전화번호로 선다', (tester) async {
    await open(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tapHeader(tester, l10n.regPhone);
    expect(_order(tester), ['Bruno', 'Carla', 'Ana']); // 111 · 222 · 333

    // 한 번 더 누르면 내림차순
    await tapHeader(tester, l10n.regPhone);
    expect(_order(tester), ['Ana', 'Carla', 'Bruno']);
  });

  testWidgets('상태를 누르면 상태로 선다 — 입금으로 서지 않는다', (tester) async {
    await open(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tapHeader(tester, l10n.colStatus);
    // 완료(Ana·Carla)가 먼저, 미완료(Bruno)가 뒤. 같은 무리 안은 기본 순서.
    expect(_order(tester).last, 'Bruno');
  });

  testWidgets('입금을 누르면 입금으로 선다', (tester) async {
    await open(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tapHeader(tester, l10n.colPayment);
    // 미납이 위로, 같은 미납이면 낼 돈이 많은 쪽이 먼저 — Carla(300) · Ana(100).
    // 입금 확인된 Bruno 는 맨 아래.
    expect(_order(tester), ['Carla', 'Ana', 'Bruno']);
  });

  testWidgets('나이는 성별로 묶고 그 안에서 수로 선다', (tester) async {
    await open(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tapHeader(tester, l10n.colGenderAge);
    expect(_order(tester), ['Ana', 'Carla', 'Bruno']); // F30 · F41 · M25
  });
}
