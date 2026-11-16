import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'package:mana/features/dashboard/screens/roster_table_screen.dart';
import 'package:mana/features/program/providers/program_provider.dart';

// 머리글 오른쪽 끝을 끌면 그 칸의 폭이 바뀐다. 실제로 끌어 본다.

const _programId = 'p1';

final _people = <Map<String, dynamic>>[
  {
    'id': 'r1',
    'real_name': 'Bruno',
    'country': 'AR',
    'gender': 'M',
    'age': 25,
    'submitted': true,
    'amount_due': 100,
    'payment': {'status': null, 'amount': null},
  },
  {
    'id': 'r2',
    'real_name': 'Ana',
    'country': 'AR',
    'gender': 'F',
    'age': 30,
    'submitted': true,
    'amount_due': 100,
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

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness());
  await tester.pumpAndSettle();
}

Finder _nameText(String n) =>
    find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith(n));

/// 이름 칸(두 번째 칸)의 폭. 'Ana' 글자를 감싼 칸에서 잰다.
double _nameWidth(WidgetTester tester) => tester
    .getSize(
      find
          .ancestor(of: _nameText('Ana'), matching: find.byType(SizedBox))
          .first,
    )
    .width;

/// 칸 폭 손잡이들. 번호 칸이 0번, 이름 칸이 1번이다.
final _handles = find.byWidgetPredicate(
  (w) => w is MouseRegion && w.cursor == SystemMouseCursors.resizeColumn,
);

List<String> _order(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text)))
    for (final n in ['Ana', 'Bruno'])
      if ((t.data ?? '').startsWith(n)) n,
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('손잡이를 끌면 칸이 넓어지고, 기억된다', (tester) async {
    await _open(tester);
    final before = _nameWidth(tester);
    final order = _order(tester);

    await tester.drag(_handles.at(1), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(_nameWidth(tester), closeTo(before + 80, 1));
    // 끄는 것은 정렬이 아니다.
    expect(_order(tester), order);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('roster_col_widths_all'), contains('"name"'));
  });

  testWidgets('줄이면 좁아지되 최소 폭 밑으로는 안 간다', (tester) async {
    await _open(tester);
    await tester.drag(_handles.at(1), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    expect(_nameWidth(tester), 48);
  });

  testWidgets('저장해 둔 폭으로 열린다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'roster_col_widths_all': '{"name": 400}',
    });
    await _open(tester);
    expect(_nameWidth(tester), 400);
  });
}
