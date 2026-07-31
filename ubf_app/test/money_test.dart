import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/money.dart';

// 통화 표시는 화면마다 흩어지기 쉬워 한 곳으로 모았다. 그 계약을 고정한다.
void main() {
  test('정수는 소수점 없이', () {
    expect(Money.format(150), 'U\$ 150');
    expect(Money.format(0), 'U\$ 0');
  });

  test('소수가 있으면 두 자리', () {
    expect(Money.format(150.5), 'U\$ 150.50');
    expect(Money.format(1200.25), 'U\$ 1200.25');
  });

  test('null 은 0 으로', () {
    expect(Money.format(null), 'U\$ 0');
  });

  test('원화 기호가 남아 있지 않다', () {
    expect(Money.format(100).contains('₩'), isFalse);
  });
}
