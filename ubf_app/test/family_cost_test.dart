import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/child_fee.dart';
import 'package:mana/core/utils/family_cost.dart';
import 'package:mana/core/utils/registration_cost.dart';

// 함께 오는 사람까지 합친 금액 (077)
final _program = <String, dynamic>{
  'fee_basic': 100,
  'fee_premium': 160,
  'fee_child_age_min': 4,
  'fee_child_age_max': 8,
  'fee_child_rate': 0.5,
  'hotel_options': [
    {'key': 'std', 'label': '일반실', 'pricePerNight': 30},
    {'key': 'sup', 'label': '특실', 'pricePerNight': 50},
    {'key': 'tbd', 'label': '미정'}, // 값을 못 정한 수준은 합칠 수 없다
  ],
};

Map<String, dynamic> _c({
  int? age,
  bool separately = false,
  bool bed = true,
  bool sharesRoom = true,
}) => {
  'age': age,
  'registersSeparately': separately,
  'occupiesBed': bed,
  'sharesRoom': sharesRoom,
};

void main() {
  test('부부(어른 동반자 하나): 등급마다 두 사람 몫이 합쳐진다', () {
    final f = FamilyCost.of(
      program: _program,
      companions: [_c(age: 40)],
      nights: 2,
    );
    expect(f.people, 2);
    expect(f.heads, 2);
    expect(f.fees.map((r) => r.total), [200, 320]);
    expect(f.hotels.map((h) => h.perNightAll), [60, 100]);
    expect(f.hotels.map((h) => h.total), [120, 200]);
  });

  test('다른 방을 써도 금액은 같다', () {
    final same = FamilyCost.of(
      program: _program,
      companions: [_c(age: 40)],
      nights: 2,
    );
    final other = FamilyCost.of(
      program: _program,
      companions: [_c(age: 40, sharesRoom: false)],
      nights: 2,
    );
    expect(other.fees.map((r) => r.total), same.fees.map((r) => r.total));
    expect(other.hotels.map((h) => h.total), same.hotels.map((h) => h.total));
  });

  test('같이 자는 아기는 숙박 머릿수에 안 들지만, 다른 방이면 든다', () {
    expect(lodgingHeads([_c(age: 1, bed: false)]), 1);
    expect(lodgingHeads([_c(age: 1, bed: false, sharesRoom: false)]), 2);
  });

  test('어린이는 등급 값의 정해진 몫만 더해진다', () {
    final f = FamilyCost.of(program: _program, companions: [_c(age: 6)]);
    expect(f.fees.first.others, 50);
    expect(f.fees.first.total, 150);
  });

  test('따로 등록하는 분은 여기서 세지 않고, 그 수만 알린다', () {
    final f = FamilyCost.of(
      program: _program,
      companions: [_c(age: 40, separately: true)],
    );
    expect(f.people, 1);
    expect(f.heads, 1);
    expect(f.separateCount, 1);
    expect(f.fees.first.total, 100);
  });

  test('박수를 모르면 숙박 합계는 비워 둔다 — 0 은 공짜로 읽힌다', () {
    final f = FamilyCost.of(program: _program, companions: [_c(age: 40)]);
    expect(f.hotels.first.total, isNull);
    expect(f.hotels.first.perNightAll, 60);
  });

  test('낼 돈(RegistrationCost)의 숙박비도 머릿수만큼이다 — 서버와 같다', () {
    final cost = RegistrationCost.of(
      program: _program,
      companions: [_c(age: 40)],
      feeTier: 'basic',
      selectedOptionIds: const [],
      hotelOptionKey: 'std',
      hotelNightsBefore: 2,
      hotelNightsAfter: 0,
    );
    // 참가비 100 + 어른 동반자 100 + 숙박 30 × 2박 × 2명
    expect(cost.hotelEstimate, 120);
    expect(cost.due, 320);
  });
}
