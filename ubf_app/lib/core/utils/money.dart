// 금액 표시.
//
// 통화 기호를 화면마다 문자열에 박아두면 바꿀 때 빠뜨리기 쉽다. 실제로 ₩ 가
// 네 곳에 흩어져 있었고, 국제 수양회인데 한국 원화로 표시되고 있었다.
// 표시는 여기 한 곳에서만 결정한다.
//
// 참가비는 미국 달러로 표기한다. 남미에서는 U$ 로 쓰는 것이 일반적이다
// (US$ / USD 도 같은 뜻이지만 현지 표기를 따른다).
class Money {
  const Money._();

  static const String symbol = 'U\$';

  /// 금액을 표시용 문자열로. 소수점 이하가 없으면 정수로 보여준다.
  ///
  ///   format(150)     → U$ 150
  ///   format(150.5)   → U$ 150.50
  ///   format(0)       → U$ 0
  static String format(num? value) {
    final v = value ?? 0;
    final hasCents = v % 1 != 0;
    return '$symbol ${v.toStringAsFixed(hasCents ? 2 : 0)}';
  }
}
