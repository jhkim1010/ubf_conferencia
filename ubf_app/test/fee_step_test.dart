import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'package:mana/features/registration/providers/registration_provider.dart';
import 'package:mana/features/registration/screens/steps/fee_step.dart';
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
        body: FeeStep(
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
        ),
      ),
    ),
  );
}

ProviderContainer _container() => ProviderContainer(
  overrides: [registrationProvider(_programId).overrideWith((_) async => null)],
);

void main() {
  testWidgets('등급을 고르면 폼 상태에 반영된다', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();

    expect(c.read(registrationFormProvider(_programId)).feeTier, isNull);

    await tester.tap(find.text('프리미엄'));
    await tester.pump();
    expect(c.read(registrationFormProvider(_programId)).feeTier, 'premium');

    await tester.tap(find.text('기본'));
    await tester.pump();
    expect(c.read(registrationFormProvider(_programId)).feeTier, 'basic');
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
}
