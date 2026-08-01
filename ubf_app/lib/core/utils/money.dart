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

  /// API 가 준 금액을 숫자로. 숫자가 아니면 null.
  ///
  /// `as num?` 로 캐스팅하지 말 것. Postgres 의 NUMERIC/BIGINT 는 드라이버가
  /// 문자열로 돌려주는 것이 기본이라 캐스팅이 예외로 죽는다. 서버에서
  /// 파서를 설정해 두었지만(server/src/db.js), 새 컬럼이나 다른 경로로
  /// 문자열이 다시 들어와도 화면이 통째로 죽지는 않게 한다.
  ///
  ///   parse(180)      → 180
  ///   parse('180.00') → 180.0
  ///   parse(null)     → null
  ///   parse('없음')   → null
  static num? parse(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }
}
