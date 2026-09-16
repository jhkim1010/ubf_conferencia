import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/hotel_price.dart';
import 'package:mana/core/utils/registration_cost.dart';

// 숙박 단가 범위 (066)
//
// 방값이 날짜와 인원에 따라 갈리는 곳이 많아 범위로 적을 수 있게 했다.
// **받는 돈은 언제나 낮은 쪽으로 센다** — 060·061 과 같은 이유로, 잘못
// 잡았을 때 덜 받는 쪽이 더 받는 쪽보다 낫다. 높은 쪽은 참가자에게 얼마까지
// 들 수 있는지 알려 주는 데만 쓴다.

Map<String, dynamic> _program(List<Map<String, dynamic>> hotels) => {
  'fee_basic': 200,
  'fee_premium': 300,
  'program_options': const [],
  'hotel_options': hotels,
};

void main() {
  group('한 값으로 적은 경우', () {
    test('예전 자료는 그대로 읽힌다 — 칸이 하나뿐이었다', () {
      final p = HotelPrice.of({'key': 'std', 'pricePerNight': 40});
      expect(p.low, 40);
      expect(p.high, isNull);
      expect(p.isRange, isFalse);
      expect(p.lowFor(3), 120);
      expect(p.highFor(3), isNull);
    });

    test('금액을 안 적었으면 모르는 것이다 — 0 이 아니다', () {
      final p = HotelPrice.of({'key': 'std'});
      expect(p.isUnknown, isTrue);
      expect(p.lowFor(3), isNull);
    });
  });

  group('범위로 적은 경우', () {
    test('낮은 쪽과 높은 쪽을 따로 센다', () {
      final p = HotelPrice.of({
        'key': 'std',
        'pricePerNight': 35,
        'pricePerNightMax': 45,
      });
      expect(p.isRange, isTrue);
      expect(p.lowFor(2), 70);
      expect(p.highFor(2), 90);
    });

    test('높은 쪽이 낮은 쪽보다 크지 않으면 범위가 아니다', () {
      // 뒤집힌 채로 두면 화면이 "U$ 80 ~ 40" 을 적는다.
      final flipped = HotelPrice.of({
        'pricePerNight': 80,
        'pricePerNightMax': 40,
      });
      expect(flipped.isRange, isFalse);

      final same = HotelPrice.of({'pricePerNight': 40, 'pricePerNightMax': 40});
      expect(same.isRange, isFalse);
    });

    test('낮은 쪽이 없으면 높은 쪽만으로는 범위가 아니다', () {
      final p = HotelPrice.of({'pricePerNightMax': 45});
      expect(p.isUnknown, isTrue);
      expect(p.isRange, isFalse);
    });

    test('묵을 밤이 없으면 셀 것이 없다', () {
      final p = HotelPrice.of({'pricePerNight': 35, 'pricePerNightMax': 45});
      expect(p.lowFor(0), isNull);
      expect(p.highFor(0), isNull);
    });
  });

  group('낼 돈에 미치는 영향', () {
    test('낼 돈은 낮은 쪽, dueMax 는 높은 쪽', () {
      final c = RegistrationCost.of(
        program: _program([
          {'key': 'std', 'pricePerNight': 35, 'pricePerNightMax': 45},
        ]),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: 'std',
        hotelNightsBefore: 1,
        hotelNightsAfter: 1,
      );
      // 200 + 70 / 200 + 90
      expect(c.due, 270);
      expect(c.dueMax, 290);
      expect(c.dueIsRange, isTrue);
    });

    test('범위가 아니면 둘이 같다 — 화면도 한 값으로 적는다', () {
      final c = RegistrationCost.of(
        program: _program([
          {'key': 'std', 'pricePerNight': 40},
        ]),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: 'std',
        hotelNightsBefore: 0,
        hotelNightsAfter: 2,
      );
      expect(c.due, 280);
      expect(c.dueMax, 280);
      expect(c.dueIsRange, isFalse);
    });

    test('숙박을 안 고르면 범위가 생기지 않는다', () {
      final c = RegistrationCost.of(
        program: _program([
          {'key': 'std', 'pricePerNight': 35, 'pricePerNightMax': 45},
        ]),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      expect(c.due, 200);
      expect(c.dueIsRange, isFalse);
      expect(c.dueUnsure, isFalse);
    });
  });
}
