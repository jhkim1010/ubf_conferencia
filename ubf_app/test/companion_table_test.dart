import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/money.dart';
import 'package:mana/features/registration/screens/steps/companion_step.dart';
import 'package:mana/l10n/app_localizations.dart';

// 동반자 표 (078·079) — 줄을 더하고, 나이로 기본값이 골라지는가.
//
// 서버 대신 빈 목록에서 시작하고, 저장한 내용을 [saves] 에 모은다.
final saves = <List<Map<String, dynamic>>>[];

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CompanionStep(
            programId: 'p1',
            program: const {
              'fee_basic': 100,
              'fee_child_age_min': 4,
              'fee_child_age_max': 8,
              'fee_child_rate': 0.5,
            },
            currency: Currency.of('USD'),
            loadForTest: () async => const [],
            saveForTest: (payload) async {
              saves.add(payload);
              // 서버처럼 보낸 순서대로 id 를 붙여 돌려준다.
              return [
                for (var i = 0; i < payload.length; i++)
                  {...payload[i], 'id': payload[i]['id'] ?? 'id$i'},
              ];
            },
          ),
        ),
      ),
    ),
  );
  // 불러오기는 진짜 HTTP 라 가짜 시계로는 안 끝난다. 잠깐 진짜로 기다린다.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('대표자 줄이 있고, 줄 추가로 새 줄이 생긴다', (tester) async {
    await _pump(tester);
    expect(find.text('나 (대표자)'), findsOneWidget);
    await tester.tap(find.text('줄 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('줄 추가'));
    await tester.pumpAndSettle();
    // 이름 칸이 둘 — 이름 칸의 안내 글로 센다.
    expect(find.widgetWithText(TextField, '이름'), findsNWidgets(2));
    // 새 줄의 기본값: 같은 방·투어 함께·같은 비행기.
    expect(find.text('함께'), findsNWidgets(2));
    expect(find.text('나이 필요'), findsNWidgets(2));
  });

  testWidgets('두 살이면 무료·같이 잠·분반 안 함으로 골라진다', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('줄 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '이름'), 'Joy');
    final ageField = find.byType(TextField).at(1);
    await tester.enterText(ageField, '2');
    await tester.pump();
    expect(find.text('무료'), findsOneWidget);

    Color? bg(String label) {
      final m = tester.widget<Material>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Material))
            .first,
      );
      return m.color;
    }

    expect(bg('같이 잠'), isNot(Colors.white));
    expect(bg('안 함'), isNot(Colors.white));
    expect(bg('같은 분반'), Colors.white);

    // 일곱 살이면 절반, 분반은 같은 분반.
    await tester.enterText(ageField, '7');
    await tester.pump();
    expect(find.text('50%'), findsOneWidget);
    expect(bg('같은 분반'), isNot(Colors.white));

    // 손을 멈추면 한 번 저장된다. 나이로 정한 값이 풀려서 간다.
    saves.clear();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(saves, hasLength(1));
    final joy = saves.single.single;
    expect(joy['realName'], 'Joy');
    expect(joy['age'], 7);
    expect(joy['registersSeparately'], false);
    expect(joy['studyGroup'], 'same');
    expect(joy['occupiesBed'], true);
    expect(joy['joinsTours'], true);

    // 다음 저장은 받은 id 로 같은 사람을 고친다.
    await tester.enterText(ageField, '8');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(saves.last.single['id'], 'id0');
  });

  testWidgets('다른 비행기를 고르면 도착 편명 칸이 생긴다', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('줄 추가'));
    await tester.pumpAndSettle();
    expect(find.text('도착 편명'), findsNothing);
    await tester.tap(find.text('다름'));
    await tester.pumpAndSettle();
    expect(find.text('도착 편명'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
