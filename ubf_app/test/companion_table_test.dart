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

Future<void> _pump(
  WidgetTester tester, {
  List<Map<String, dynamic>> rows = const [],
  Map<String, dynamic>? registration,
}) async {
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
            registration: registration,
            load: () async => rows,
            save: (payload) async {
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
    // 투어는 이 표에서 묻지 않는다 — 투어를 고를 때 묻는다(080).
    expect(find.text('투어'), findsNothing);
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

  testWidgets('본인 등록으로 적힌 줄을 함께 등록으로 바꿀 수 있다', (tester) async {
    await _pump(
      tester,
      rows: [
        {
          'id': 'm1',
          'real_name': 'Moses Chang',
          'age': 81,
          'registers_separately': true,
          'own_registration_found': false,
          'study_group': 'none',
        },
      ],
    );
    // 처음에는 잠겨 있다 — 이름 입력 칸이 없다. 등록이 없다는 것이 보인다.
    expect(find.text('아직 등록 안 함'), findsOneWidget);
    expect(find.widgetWithText(TextField, '이름'), findsNothing);

    // 취소하면 그대로다.
    await tester.tap(find.text('함께 등록으로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('아직 등록 안 함'), findsOneWidget);

    saves.clear();
    await tester.tap(find.text('함께 등록으로'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Moses Chang 님을'), findsOneWidget);
    await tester.tap(find.text('바꾸기'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('아직 등록 안 함'), findsNothing);
    expect(find.widgetWithText(TextField, 'Moses Chang'), findsOneWidget);
    final m = saves.last.single;
    expect(m['id'], 'm1');
    expect(m['registersSeparately'], false);
    // 따로 등록 때의 'none' 대신 나이로 정한 분반.
    expect(m['studyGroup'], 'same');
  });

  testWidgets('본인 등록 줄도 같은 방·다른 방을 고를 수 있다', (tester) async {
    await _pump(
      tester,
      rows: [
        {
          'id': 's1',
          'real_name': 'Soo Yeon Choi',
          'age': 52,
          'registers_separately': true,
          'own_registration_found': true,
          'shares_room': true,
        },
      ],
    );
    expect(find.text('따로 등록함'), findsOneWidget);
    saves.clear();
    await tester.tap(find.text('다른 방'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final c = saves.last.single;
    expect(c['id'], 's1');
    // 여전히 따로 등록 — 참가비는 그분 등록에서 낸다.
    expect(c['registersSeparately'], true);
    expect(c['sharesRoom'], false);
  });

  testWidgets('담당자가 연 등록에서는 대표자 줄에 그 사람 이름과 값이 보인다', (tester) async {
    await _pump(
      tester,
      registration: {
        'id': 'r1',
        'real_name': 'Gonzalo Solis',
        'gender': 'M',
        'age': 41,
        'fee_tier': 'basic',
        'arrival_flight': {'flight_no': 'ar1300'},
      },
    );
    expect(find.text('Gonzalo Solis (대표자)'), findsOneWidget);
    expect(find.text('나 (대표자)'), findsNothing);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('남'), findsOneWidget);
    expect(find.text('기준'), findsNWidgets(2)); // 같은 방 · 분반
    expect(find.text('AR1300'), findsOneWidget); // 같은 비행기 칸
  });
}
