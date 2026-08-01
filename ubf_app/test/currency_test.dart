import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/money.dart';

// 통화는 수양회마다 정하고, 그 수양회의 등록자는 전원 같은 단위로 본다.
// 환율 변환은 하지 않는다 — 입력한 숫자가 곧 청구 금액이다.
void main() {
  test('기본은 USD 이고 표기는 U\$', () {
    expect(Currency.usd.code, 'USD');
    expect(Currency.usd.format(150), 'U\$ 150');
    // 통화를 넘기지 않은 옛 호출부는 USD 로 남는다.
    expect(Money.format(150), 'U\$ 150');
  });

  test('수양회가 정한 통화로 표시된다', () {
    expect(Currency.of('KRW').format(150000), '₩ 150000');
    expect(Currency.of('EUR').format(120), '€ 120');
    expect(Currency.of('BRL').format(90), 'R\$ 90');
    expect(Money.format(150, Currency.of('PEN')), 'S/ 150');
  });

  test('소수점을 쓰지 않는 통화는 정수로', () {
    // ₩ 1500.50 같은 값은 뜻이 없다.
    expect(Currency.of('KRW').format(1500.5), '₩ 1501');
    expect(Currency.of('JPY').format(999.4), '¥ 999');
    // 반대로 소수를 쓰는 통화는 두 자리를 유지한다.
    expect(Currency.of('USD').format(150.5), 'U\$ 150.50');
  });

  test('코드는 대소문자를 가리지 않는다', () {
    expect(Currency.of('krw').code, 'KRW');
    expect(Currency.of('  eur  ').code, 'EUR');
  });

  test('모르는 코드는 코드 자체를 기호로 쓴다', () {
    // 빈칸을 보여주거나 엉뚱한 통화로 대체하면 금액을 잘못 읽는다.
    final x = Currency.of('XYZ');
    expect(x.code, 'XYZ');
    expect(x.format(10), 'XYZ 10');
    expect(Currency.isKnown('XYZ'), isFalse);
    expect(Currency.isKnown('USD'), isTrue);
  });

  test('값이 없으면 USD', () {
    expect(Currency.of(null).code, 'USD');
    expect(Currency.of('').code, 'USD');
    expect(Currency.of('   ').code, 'USD');
  });

  test('통화 코드가 중복되지 않는다', () {
    final seen = <String>{};
    for (final c in Currency.all) {
      expect(seen.add(c.code), isTrue, reason: '중복: ${c.code}');
      expect(RegExp(r'^[A-Z]{3}$').hasMatch(c.code), isTrue, reason: c.code);
    }
  });

  test('환율 변환을 하지 않는다 — 숫자는 그대로다', () {
    // 같은 숫자를 어떤 통화로 보든 값은 바뀌지 않는다. 기호만 바뀐다.
    for (final c in Currency.all) {
      expect(c.format(100).contains('100'), isTrue, reason: c.code);
    }
  });
}
