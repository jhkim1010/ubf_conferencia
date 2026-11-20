import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/money.dart';
import 'package:mana/features/dashboard/screens/participant_editor.dart';
import 'package:mana/l10n/app_localizations.dart';

// 담당자가 명단에서 한 사람을 여는 창 — 탭과 채워진 칸.
final _reg = <String, dynamic>{
  'id': 'r1',
  'real_name': 'Camila Hernández',
  'bible_name': 'Ruth',
  'country': 'Argentina', // 예전 표기 — ISO 로 읽어 골라져야 한다
  'branch': 'La Plata',
  'gender': 'F',
  'age': 29,
  'phone': '',
  'fee_tier': 'basic',
  'total_cost': 200,
};

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () => showParticipantEditor(
              ctx,
              programId: 'p1',
              reg: _reg,
              program: const {'fee_basic': 200, 'fee_premium': 300},
              currency: Currency.of('USD'),
              onChanged: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('네 탭과, 저장된 값으로 채워진 기본 정보', (tester) async {
    await _open(tester);
    expect(find.text('Camila Hernández (Ruth)'), findsOneWidget);
    for (final t in ['기본 정보', '동반자', '투어', '항공·숙박']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.widgetWithText(TextField, 'La Plata'), findsOneWidget);
    expect(find.widgetWithText(TextField, '29'), findsOneWidget);
    // 'Argentina' 는 ISO(AR)로 읽혀 목록에서 골라져 있다.
    expect(find.text('Argentina'), findsOneWidget);
  });

  testWidgets('아무것도 안 고치고 저장하면 보내지 않는다', (tester) async {
    await _open(tester);
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(find.text('바뀐 것이 없습니다'), findsOneWidget);
  });
}
