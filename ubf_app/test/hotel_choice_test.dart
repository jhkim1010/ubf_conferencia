// 숙박 수준 고르기 (064) — 앱 쪽.
//
// server/test/hotel_choice.test.js 와 **같은 예**를 본다. 두 벌로 두면
// 언젠가 한쪽만 고쳐지고, 그때 화면이 내미는 방과 서버가 받아 주는 방이
// 갈린다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/hotel_nights.dart';

void main() {
  final levels = <Map<String, dynamic>>[
    {'key': 'h1', 'label': 'Deluxe', 'pricePerNight': 100},
    {'key': 'h2', 'label': 'Standard', 'pricePerNight': 30},
  ];

  test('기본은 가장 싼 방이다', () {
    expect(defaultHotelKey(levels), 'h2');
  });

  test('차례가 뒤바뀌어도 값으로 고른다', () {
    expect(defaultHotelKey(levels.reversed.toList()), 'h2');
  });

  test('이름으로 찾지 않는다', () {
    final es = <Map<String, dynamic>>[
      {'key': 'a', 'label': 'Habitación superior', 'pricePerNight': 90},
      {'key': 'b', 'label': 'Habitación estándar', 'pricePerNight': 25},
    ];
    expect(defaultHotelKey(es), 'b');
  });

  test('값이 하나도 안 정해졌으면 첫 번째', () {
    expect(
      defaultHotelKey(<Map<String, dynamic>>[
        {'key': 'x'},
        {'key': 'y'},
      ]),
      'x',
    );
  });

  test('값이 정해진 것이 하나뿐이면 그것', () {
    expect(
      defaultHotelKey(<Map<String, dynamic>>[
        {'key': 'x'},
        {'key': 'y', 'pricePerNight': 80},
      ]),
      'y',
    );
  });

  test('0 원짜리 방도 값이 정해진 것이다', () {
    expect(
      defaultHotelKey(<Map<String, dynamic>>[
        {'key': 'x', 'pricePerNight': 50},
        {'key': 'y', 'pricePerNight': 0},
      ]),
      'y',
    );
  });

  test('고를 것이 없으면 null', () {
    expect(defaultHotelKey(const []), isNull);
  });

  test('묵을 밤이 있으면 골라야 한다', () {
    expect(mustPickHotel(nights: 2, options: levels), isTrue);
  });

  test('묵을 밤이 없으면 안 골라도 된다', () {
    expect(mustPickHotel(nights: 0, options: levels), isFalse);
  });

  test('주최 측이 등급을 안 만들었으면 막지 않는다', () {
    // 막으면 참가자가 제출 자체를 못 한다.
    expect(mustPickHotel(nights: 3, options: const []), isFalse);
  });
}
