/// 숙박 수준의 1박 값 (066)
///
/// 방값은 날짜와 인원에 따라 갈리는 곳이 많다. 한 숫자로 적으면 둘 중 하나는
/// 틀리므로 **범위로 적을 수 있게** 한다.
///
///   `pricePerNight`     낮은 쪽. 예전 자료에는 이 칸 하나뿐이라 그대로 읽힌다.
///   `pricePerNightMax`  높은 쪽. 없으면 한 값이다.
///
/// **받는 돈은 언제나 낮은 쪽으로 센다.** 060·061 과 같은 이유다 — 잘못
/// 잡았을 때 덜 받는 쪽이 더 받는 쪽보다 낫다. 높은 쪽은 화면에서 "얼마까지
/// 들 수 있는지" 를 알려 주는 데만 쓴다.
///
/// DB 도 HTTP 도 쓰지 않는다. test/hotel_price_test.dart 로 그대로 확인한다.
library;

import 'money.dart';

class HotelPrice {
  const HotelPrice({required this.low, required this.high});

  /// 낮은 쪽. 아직 안 정했으면 null — 0 과 다르다. 0 은 공짜라는 뜻이다.
  final num? low;

  /// 높은 쪽. 범위가 아니면 null.
  final num? high;

  bool get isRange => low != null && high != null;

  /// 금액을 아예 모르는가.
  bool get isUnknown => low == null;

  /// [nights] 밤에 들 돈의 낮은 쪽. 셀 수 없으면 null.
  num? lowFor(int nights) => low == null || nights <= 0 ? null : low! * nights;

  /// [nights] 밤에 들 돈의 높은 쪽. 범위가 아니면 null.
  num? highFor(int nights) =>
      high == null || nights <= 0 ? null : high! * nights;

  /// 수양회 자료의 숙박 수준 한 줄에서 읽는다.
  ///
  /// 높은 쪽이 낮은 쪽보다 크지 않으면 범위가 아니다 — 뒤집힌 채로 두면
  /// 화면이 "U$ 80 ~ 40" 을 적는다.
  static HotelPrice of(Map<String, dynamic>? level) {
    final low = Money.parse(level?['pricePerNight']);
    final high = Money.parse(level?['pricePerNightMax']);
    return HotelPrice(
      low: low,
      high: low != null && high != null && high > low ? high : null,
    );
  }
}
