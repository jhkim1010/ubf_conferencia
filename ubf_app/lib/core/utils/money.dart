// 금액 표시.
//
// 통화 기호를 화면마다 문자열에 박아두면 바꿀 때 빠뜨리기 쉽다. 실제로 ₩ 가
// 네 곳에 흩어져 있었고, 국제 수양회인데 한국 원화로 표시되고 있었다.
// 표시는 여기 한 곳에서만 결정한다.
//
// **통화는 수양회마다 정한다.** 개최지가 남미면 U$, 한국이면 ₩ 처럼 주최 측이
// 고르고, 그 수양회의 등록자는 전원 같은 단위로 본다. 환율 변환은 하지 않는다 —
// 변환을 하려면 "언제 시점의 환율인지"와 "누가 갱신하는지"가 따라오고, 그건
// 금액이 사람마다 달라 보이는 문제로 이어진다. 단위 표시만 바꾼다.

/// 표시용 통화. DB 에는 [code](ISO 4217)를 저장한다.
class Currency {
  /// ISO 4217 코드. DB 저장값이다.
  final String code;

  /// 화면에 붙는 기호.
  final String symbol;

  /// 소수점 이하를 쓰지 않는 통화 (원, 엔, 페소 일부 등).
  /// 이 통화들은 1.50 같은 값이 의미가 없어 반올림해 정수로 보여준다.
  final bool wholeOnly;

  const Currency(this.code, this.symbol, {this.wholeOnly = false});

  /// 기본값. 지금까지 쓰던 표기를 그대로 유지한다.
  /// 남미에서는 US$/USD 보다 U$ 가 일반적이다.
  static const usd = Currency('USD', 'U\$');

  /// 고를 수 있는 통화. UBF 지부가 있는 지역을 우선으로 담았다.
  /// 여기 없는 통화가 필요하면 이 목록에 추가한다.
  static const List<Currency> all = [
    usd,
    Currency('EUR', '€'),
    Currency('KRW', '₩', wholeOnly: true),
    Currency('ARS', r'AR$', wholeOnly: true),
    Currency('BRL', r'R$'),
    Currency('PEN', 'S/'),
    Currency('MXN', r'MX$'),
    Currency('CLP', r'CL$', wholeOnly: true),
    Currency('COP', r'CO$', wholeOnly: true),
    Currency('PYG', '₲', wholeOnly: true),
    Currency('UYU', r'UY$'),
    Currency('BOB', 'Bs'),
    Currency('GBP', '£'),
    Currency('CAD', r'CA$'),
    Currency('AUD', r'AU$'),
    Currency('JPY', '¥', wholeOnly: true),
    Currency('CNY', '¥'),
    Currency('PHP', '₱'),
    Currency('INR', '₹'),
    Currency('IDR', 'Rp', wholeOnly: true),
    Currency('NGN', '₦'),
    Currency('ZAR', 'R'),
    Currency('RUB', '₽'),
    Currency('UAH', '₴'),
    Currency('TRY', '₺'),
  ];

  /// 코드로 통화를 찾는다. 모르는 코드면 코드 자체를 기호로 쓴다 —
  /// 빈 값을 보여주거나 엉뚱한 통화로 대체하는 것보다 낫다.
  /// 값이 없으면 기본값(USD)이다.
  static Currency of(String? code) {
    if (code == null || code.trim().isEmpty) return usd;
    final c = code.trim().toUpperCase();
    for (final x in all) {
      if (x.code == c) return x;
    }
    return Currency(c, c);
  }

  static bool isKnown(String? code) {
    if (code == null) return false;
    final c = code.trim().toUpperCase();
    return all.any((x) => x.code == c);
  }

  /// 금액을 표시용 문자열로. 소수점 이하가 없으면 정수로 보여준다.
  ///
  ///   usd.format(150)   → U$ 150
  ///   usd.format(150.5) → U$ 150.50
  ///   krw.format(1500)  → ₩ 1500
  String format(num? value) {
    final v = value ?? 0;
    final hasCents = !wholeOnly && v % 1 != 0;
    final n = wholeOnly ? v.round() : v;
    return '$symbol ${n.toStringAsFixed(hasCents ? 2 : 0)}';
  }
}

class Money {
  const Money._();

  /// 통화를 지정하지 않은 곳에서 쓰는 기본 기호.
  /// 새 코드는 [Currency.format] 을 쓰고 수양회의 통화를 넘기십시오.
  static const String symbol = 'U\$';

  /// 금액을 표시용 문자열로.
  ///
  /// [currency] 를 주면 그 통화로, 주지 않으면 USD 로 표시한다.
  /// 수양회 화면에서는 **반드시** 그 수양회의 통화를 넘겨야 한다 —
  /// 넘기지 않으면 주최 측이 정한 단위와 다른 값이 보인다.
  static String format(num? value, [Currency? currency]) =>
      (currency ?? Currency.usd).format(value);

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
