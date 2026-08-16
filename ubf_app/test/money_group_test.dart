import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/money.dart';

// 640000 은 한눈에 읽히지 않는다. 페소처럼 자리가 긴 통화에서는 0 을 하나
// 빠뜨린 채 적어도 아무도 알아채지 못한다.

void main() {
  test('천 단위를 점으로 끊는다', () {
    expect(groupDigits(1234567, 0), '1.234.567');
    expect(groupDigits(640000, 0), '640.000');
    expect(groupDigits(1000, 0), '1.000');
  });

  test('네 자리 미만은 그대로', () {
    expect(groupDigits(999, 0), '999');
    expect(groupDigits(0, 0), '0');
    expect(groupDigits(1, 0), '1');
  });

  test('소수점은 쉼표', () {
    // 남미 표기 — 천 단위는 점, 소수점은 쉼표.
    expect(groupDigits(1234.5, 2), '1.234,50');
    expect(groupDigits(0.5, 2), '0,50');
  });

  test('음수도 자리를 끊는다', () {
    // 장부의 "지금 남은 돈" 은 모자라면 음수다.
    expect(groupDigits(-1234567, 0), '-1.234.567');
    expect(groupDigits(-1234.5, 2), '-1.234,50');
  });

  test('통화 표시가 이 규칙을 쓴다', () {
    expect(Currency.usd.format(1234567), r'U$ 1.234.567');
    expect(Currency.usd.format(150.5), r'U$ 150,50');
    // 소수점을 안 쓰는 통화는 반올림해 정수로.
    expect(Currency.of('ARS').format(640000), r'AR$ 640.000');
    expect(Currency.of('KRW').format(1500000), '₩ 1.500.000');
  });

  test('빈 값은 0', () {
    expect(Currency.usd.format(null), r'U$ 0');
  });
}
