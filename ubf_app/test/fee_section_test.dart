import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'package:mana/features/registration/providers/registration_provider.dart';
import 'package:mana/features/registration/screens/steps/fee_section.dart';
import 'package:mana/core/utils/money.dart';

// 참가비 등급 선택과 할인 신청은 화면과 상태가 어긋나기 쉽다.
// 특히 "신청 안 함"은 값을 **지우는** 동작이라 copyWith 의 `??` 병합으로는
// 표현되지 않는다. 여기서 그 계약을 고정한다.
//
// 서버 저장 결과(registrationProvider)는 이 테스트에서 쓰지 않으므로
// null 을 돌려주도록 덮어쓴다. 실제 HTTP 를 타면 테스트가 네트워크에 의존한다.

const _programId = 'p1';

Widget _harness(
  ProviderContainer container, {
  List<Map<String, dynamic>>? discounts,
  String? hostCountry,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        // FeeSection 은 스스로 스크롤하지 않는다 — 실제로는 첫 화면
        // (OverviewStep) 의 ListView 안에 들어간다. 하네스도 같게 둔다.
        body: SingleChildScrollView(
          child: FeeSection(
            programId: _programId,
            currency: Currency.usd,
            feeBasic: 150,
            feePremium: 250,
            feeBasicDesc: '단체실',
            feePremiumDesc: '2인실',
            discountOptions:
                discounts ??
                const [
                  {'key': 'd1', 'label': '1일만 참석', 'amount': 40},
                  {'key': 'd2', 'label': '2일 참석', 'amount': 25},
                ],
            hostCountry: hostCountry,
          ),
        ),
      ),
    ),
  );
}

ProviderContainer _container() => ProviderContainer(
  overrides: [registrationProvider(_programId).overrideWith((_) async => null)],
);

void main() {
  // 064: 기본은 고르는 것이 아니라 받는 값이다. 아무것도 안 누르고 지나간
  // 사람의 등급이 null 로 남으면 합계에서 참가비가 통째로 빠진다.
  testWidgets('첫 그림 뒤에 기본이 골라져 있다', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    expect(c.read(registrationFormProvider(_programId)).feeTier, 'basic');
  });

  testWidgets('프리미엄은 켜고 끄는 선택이다', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    await tester.tap(find.text('프리미엄으로 올리기'));
    await tester.pump();
    expect(c.read(registrationFormProvider(_programId)).feeTier, 'premium');

    // 끄면 기본으로 돌아간다. null 로 두면 참가비가 사라진다.
    await tester.tap(find.text('프리미엄으로 올리기'));
    await tester.pump();
    expect(c.read(registrationFormProvider(_programId)).feeTier, 'basic');
  });

  // 기본에 무엇이 들어 있는지는 이제 크게 펴서 보여준다. 예전에는 13픽셀
  // 회색이라 아무도 안 읽었고, 그래서 값이 무엇을 포함하는지 물어 왔다.
  testWidgets('기본에 든 것을 본문 크기로 보여준다', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    final desc = tester.widget<Text>(find.text('단체실'));
    expect(desc.style?.fontSize, greaterThanOrEqualTo(15.0));
  });

  // 프리미엄은 기본 위에 얹는 선택이므로 총액이 아니라 차액으로 말한다.
  testWidgets('프리미엄은 차액으로 적는다', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    expect(find.text('+U\$ 100'), findsOneWidget);
    expect(find.text('U\$ 250'), findsNothing);
  });

  testWidgets('할인 항목을 고르는 것이 곧 신청이다', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    final before = c.read(registrationFormProvider(_programId));
    expect(before.discountRequested, isFalse);
    expect(before.discountOptionKey, isNull);

    await tester.tap(find.text('1일만 참석'));
    await tester.pump();

    final after = c.read(registrationFormProvider(_programId));
    expect(after.discountRequested, isTrue);
    expect(after.discountOptionKey, 'd1');
  });

  testWidgets('"할인 신청 안 함"은 고른 항목을 지운다', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2일 참석'));
    await tester.pump();
    expect(
      c.read(registrationFormProvider(_programId)).discountOptionKey,
      'd2',
    );

    await tester.tap(find.text('할인 신청 안 함'));
    await tester.pump();

    final s = c.read(registrationFormProvider(_programId));
    expect(s.discountRequested, isFalse);
    // 여기가 핵심이다. copyWith 의 `??` 병합만 있으면 key 가 남아
    // "신청 안 함"인데 항목이 붙어 있는 상태가 된다.
    expect(s.discountOptionKey, isNull);
    expect(s.discountReason, isNull);
  });

  testWidgets('할인 항목이 없으면 신청 UI 를 보여주지 않는다', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c, discounts: const []));
    await tester.pumpAndSettle();

    expect(find.text('할인 신청 안 함'), findsNothing);
    expect(find.text('이 수양회는 할인 신청을 받지 않습니다.'), findsOneWidget);
  });

  // 할인은 개최국에서 오는 사람만 신청할 수 있다. 서버도 같은 판정을 하므로
  // (registrations.js, 422), 한쪽만 바뀌면 화면과 저장이 어긋난다.
  group('개최국 참석자만 할인을 신청할 수 있다', () {
    testWidgets('개최국에서 오면 항목이 보인다', (tester) async {
      final c = _container();
      addTearDown(c.dispose);
      c
          .read(registrationFormProvider(_programId).notifier)
          .updatePersonalInfo(country: 'AR');
      await tester.pumpWidget(_harness(c, hostCountry: 'AR'));
      await tester.pumpAndSettle();

      expect(find.text('1일만 참석'), findsOneWidget);
      expect(find.text('할인 신청 안 함'), findsOneWidget);
    });

    testWidgets('다른 나라에서 오면 항목 대신 이유를 보여준다', (tester) async {
      final c = _container();
      addTearDown(c.dispose);
      c
          .read(registrationFormProvider(_programId).notifier)
          .updatePersonalInfo(country: 'KR');
      await tester.pumpWidget(_harness(c, hostCountry: 'AR'));
      await tester.pumpAndSettle();

      expect(find.text('1일만 참석'), findsNothing);
      expect(find.text('할인 신청 안 함'), findsNothing);
      // 그냥 감추기만 하면 "왜 나는 안 보이지" 가 된다. 국가명을 밝힌다.
      expect(find.textContaining('Argentina 에서 참석하는 분만'), findsOneWidget);
    });

    testWidgets('국가를 아직 안 고른 사람에게는 보이지 않는다', (tester) async {
      // 신청하게 뒀다가 저장 시점에 422 로 막으면, 자기가 무엇을 잘못했는지
      // 알 수 없다.
      final c = _container();
      addTearDown(c.dispose);
      await tester.pumpWidget(_harness(c, hostCountry: 'AR'));
      await tester.pumpAndSettle();

      expect(find.text('1일만 참석'), findsNothing);
    });

    testWidgets('지역 수양회(개최국 없음)는 제한하지 않는다', (tester) async {
      // 참가자가 모두 같은 나라 사람이므로 막을 이유가 없다.
      final c = _container();
      addTearDown(c.dispose);
      c
          .read(registrationFormProvider(_programId).notifier)
          .updatePersonalInfo(country: 'KR');
      await tester.pumpWidget(_harness(c, hostCountry: null));
      await tester.pumpAndSettle();

      expect(find.text('1일만 참석'), findsOneWidget);
    });

    testWidgets('019 이전 표시명이 남아 있어도 같은 나라로 본다', (tester) async {
      // 정규화 없이 문자열을 비교했던 것이 항공편 생략 기능이 한 번도
      // 동작하지 않은 원인이었다. 같은 실수를 반복하지 않는다.
      final c = _container();
      addTearDown(c.dispose);
      c
          .read(registrationFormProvider(_programId).notifier)
          .updatePersonalInfo(country: 'ARGENTINA');
      await tester.pumpWidget(_harness(c, hostCountry: 'AR'));
      await tester.pumpAndSettle();

      expect(find.text('1일만 참석'), findsOneWidget);
    });
  });
}
