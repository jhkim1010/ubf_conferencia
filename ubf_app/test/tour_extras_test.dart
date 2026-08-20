// 투어 값에 안 들어 있는 것 (061) — 앱 쪽.
//
// 서버의 server/test/tour_extras.test.js 와 **같은 예**를 본다. 두 벌로
// 두면 언젠가 한쪽만 고쳐지고, 그때 참가자가 보는 금액과 담당자가 보는
// 금액이 갈린다. 같은 예가 양쪽에 있으면 그 순간 한쪽이 빨개진다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/tour_extras.dart';

void main() {
  final iguazu = <String, dynamic>{
    'name': 'Iguazú',
    'includesMeals': false,
    'estMealsCost': 120,
    'includesLodging': true,
    'includesAirfare': false,
    'estAirfareCost': 300,
  };

  test('안 적으면 다 들어 있는 것으로 본다', () {
    final e = TourExtras.of([
      {'name': '시내'},
    ]);
    expect(e.isEmpty, isTrue);
    expect(e.known, 0);
  });

  test('빠진 것만 골라 낸다', () {
    final e = TourExtras.of([iguazu]);
    expect(e.items.map((i) => i.kind), [ExtraKind.meals, ExtraKind.airfare]);
  });

  test('빠진 것들의 금액을 더한다', () {
    final e = TourExtras.of([iguazu]);
    expect(e.meals, 120);
    expect(e.airfare, 300);
    expect(e.lodging, 0);
    expect(e.known, 420);
  });

  test('투어 여럿이면 종류별로 모은다', () {
    final e = TourExtras.of([
      iguazu,
      {'name': 'Ushuaia', 'includesMeals': false, 'estMealsCost': 80},
    ]);
    expect(e.meals, 200);
    expect(e.known, 500);
  });

  test('금액을 안 적은 것은 0 으로 세지 않고 따로 알린다', () {
    final e = TourExtras.of([
      {'name': 'X', 'includesAirfare': false},
    ]);
    expect(e.known, 0);
    expect(e.unknown.length, 1);
    expect(e.unknown.first.kind, ExtraKind.airfare);
    expect(e.isEmpty, isFalse);
  });

  test('0 은 모른다는 뜻이 아니다', () {
    final e = TourExtras.of([
      {'name': 'X', 'includesMeals': false, 'estMealsCost': 0},
    ]);
    expect(e.unknown, isEmpty);
    expect(e.known, 0);
    expect(e.isEmpty, isFalse, reason: '빠진 것이 있다는 사실은 남아야 한다');
  });

  test('금액을 못 읽으면 모르는 것으로 둔다', () {
    expect(TourExtras.amountOf('abc'), isNull);
    expect(TourExtras.amountOf(-5), isNull);
    expect(TourExtras.amountOf(''), isNull);
    expect(TourExtras.amountOf('120.50'), 120.5);
    expect(TourExtras.amountOf(0), 0);
  });

  test('어느 투어에서 나온 것인지 남긴다', () {
    final e = TourExtras.of([iguazu]);
    expect(e.items.map((i) => i.tour).toSet(), {'Iguazú'});
  });

  _lineTests();
}

// ── 최종 비용 옆에 뭐라고 적을 것인가 (061) ─────────────────────────

void _lineTests() {
  test('따로 나갈 돈이 없으면 아무 말도 하지 않는다', () {
    expect(extrasLineOf(known: 0, unsure: false), ExtrasLine.none);
  });

  test('다 알면 금액만 말한다', () {
    expect(extrasLineOf(known: 500, unsure: false), ExtrasLine.known);
  });

  test('섞이면 금액과 미정을 함께 말한다', () {
    expect(extrasLineOf(known: 500, unsure: true), ExtrasLine.knownAndUnsure);
  });

  test('금액을 모르면 0 이라 하지 않고 미정이라 한다', () {
    // 여기서 none 을 돌려주면 "더 들 것 없음" 이 되어, 참가자가 돈을
    // 안 챙겨 온다. 이 한 줄이 이 파일에서 가장 중요한 갈래다.
    expect(extrasLineOf(known: 0, unsure: true), ExtrasLine.unsureOnly);
  });
}
