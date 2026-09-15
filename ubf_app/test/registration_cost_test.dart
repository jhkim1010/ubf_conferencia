import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/registration_cost.dart';

// 등록하는 사람이 보는 금액(064).
//
// 이 셈은 두 곳에서 쓰인다 — 등록 내내 따라다니는 비용 막대와 마지막 확인
// 화면이다. 두 벌로 두면 갈라지고, 갈라지면 참가자가 화면마다 다른 숫자를
// 본다. 그래서 한 곳으로 모았고, 그 계약을 여기서 고정한다.
//
// **가장 중요한 것은 두 값을 안 합치는 것이다.** 우리에게 내는 돈(due)과
// 참가자가 따로 쓸 돈(extrasKnown)은 성격이 다르다. 합치면 확정된 청구서로
// 보이고, 빼면 돈을 덜 챙겨 온다.

Map<String, dynamic> _program({
  Object? feeBasic = 200,
  Object? feePremium = 300,
  List<Map<String, dynamic>>? options,
  List<Map<String, dynamic>>? hotels,
}) => {
  'fee_basic': feeBasic,
  'fee_premium': feePremium,
  'program_options': options ?? const [],
  'hotel_options': hotels ?? const [],
};

void main() {
  group('우리에게 내는 돈', () {
    test('등급을 안 골랐으면 참가비가 0 이다', () {
      final c = RegistrationCost.of(
        program: _program(),
        feeTier: null,
        selectedOptionIds: const [],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      expect(c.due, 0);
      expect(c.isEmpty, isTrue);
    });

    test('등급과 투어 값을 더한다', () {
      final c = RegistrationCost.of(
        program: _program(
          options: [
            {'id': 'a', 'cost': 800},
            {'id': 'b', 'cost': 95},
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const ['a', 'b'],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      expect(c.optionsTotal, 895);
      expect(c.due, 1095);
    });

    test('안 고른 투어는 안 센다', () {
      final c = RegistrationCost.of(
        program: _program(
          options: [
            {'id': 'a', 'cost': 800},
            {'id': 'b', 'cost': 95},
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const ['b'],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      expect(c.due, 295);
    });

    test('프리미엄은 프리미엄 값으로 센다', () {
      final c = RegistrationCost.of(
        program: _program(),
        feeTier: 'premium',
        selectedOptionIds: const [],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      expect(c.due, 300);
    });

    test('승인된 할인만 뺀다', () {
      final approved = RegistrationCost.of(
        program: _program(),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
        savedDiscountStatus: 'approved',
        savedDiscountAmount: 40,
      );
      expect(approved.due, 160);

      // 신청 중인 금액을 미리 빼면 아직 결정되지도 않은 감액을 확정된
      // 것처럼 보여주게 된다.
      final pending = RegistrationCost.of(
        program: _program(),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
        savedDiscountStatus: 'pending',
        savedDiscountAmount: 40,
      );
      expect(pending.due, 200);
    });

    test('할인이 참가비보다 커도 0 아래로 안 내려간다', () {
      final c = RegistrationCost.of(
        program: _program(),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
        savedDiscountStatus: 'approved',
        savedDiscountAmount: 500,
      );
      expect(c.due, 0);
    });
  });

  group('따로 쓸 돈', () {
    test('투어 값에 안 든 것을 모으되 합계에는 안 넣는다', () {
      final c = RegistrationCost.of(
        program: _program(
          options: [
            {
              'id': 'a',
              'cost': 800,
              'includesMeals': false,
              'estMealsCost': 120,
              'includesAirfare': false,
              'estAirfareCost': 400,
            },
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const ['a'],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      // 여기가 핵심이다. 1000 에 520 을 더하지 않는다. 투어 값에 안 든
      // 밥값·항공권은 참가자가 현지에서 쓰는 돈이다(숙박비와 다르다).
      expect(c.due, 1000);
      expect(c.extrasKnown, 520);
      expect(c.extrasUnsure, isFalse);
    });

    test('금액을 안 적은 항목이 있으면 그 사실을 남긴다', () {
      final c = RegistrationCost.of(
        program: _program(
          options: [
            {
              'id': 'a',
              'cost': 800,
              'includesMeals': false,
              'estMealsCost': 120,
              // 항공권은 안 들어 있는데 얼마인지 아직 모른다.
              'includesAirfare': false,
            },
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const ['a'],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      expect(c.extrasKnown, 120);
      // 아는 것만 적어 두면 그것이 전부인 줄 알고 돈을 덜 챙겨 온다.
      expect(c.extrasUnsure, isTrue);
    });

    test('담당자가 이름 붙여 더한 항목도 센다', () {
      final c = RegistrationCost.of(
        program: _program(
          options: [
            {
              'id': 'a',
              'cost': 400,
              'extraItems': [
                {'name': '국립공원 입장료', 'cost': 35},
                {'name': '가이드 팁', 'cost': null},
              ],
            },
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const ['a'],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      expect(c.extrasKnown, 35);
      expect(c.extrasUnsure, isTrue);
    });
  });

  // 064: 전후 숙박비는 우리가 받아서 호텔에 낸다. 참가자가 호텔에 직접
  // 내는 돈이 아니므로 "따로 쓸 돈" 이 아니라 "낼 돈" 이다.
  // 서버도 같은 셈을 한다(services/registration_total.js).
  group('전후 숙박', () {
    test('숙박비는 우리에게 내는 돈이다', () {
      final c = RegistrationCost.of(
        program: _program(
          hotels: [
            {'key': 'std', 'pricePerNight': 40},
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: 'std',
        hotelNightsBefore: 1,
        hotelNightsAfter: 2,
      );
      expect(c.hotelNights, 3);
      expect(c.hotelEstimate, 120);
      expect(c.due, 320);
      // 따로 쓸 돈에는 안 남는다 — 두 번 세면 안 된다.
      expect(c.extrasKnown, 0);
      expect(c.dueUnsure, isFalse);
    });

    test('묵을 밤은 있는데 등급을 안 골랐으면 아직 못 더한 것이다', () {
      final c = RegistrationCost.of(
        program: _program(
          hotels: [
            {'key': 'std', 'pricePerNight': 40},
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: null,
        hotelNightsBefore: 2,
        hotelNightsAfter: 0,
      );
      expect(c.hotelEstimate, isNull);
      expect(c.due, 200);
      // 화면은 이때 "등급을 고르면 더해집니다" 라고 말해야 한다. 안 말하면
      // 숙박이 공짜인 줄 알고, 나중에 늘어난 금액을 보고 놀란다.
      expect(c.dueUnsure, isTrue);
    });

    test('묵을 밤이 없으면 등급을 안 골라도 미정이 아니다', () {
      final c = RegistrationCost.of(
        program: _program(
          hotels: [
            {'key': 'std', 'pricePerNight': 40},
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const [],
        hotelOptionKey: null,
        hotelNightsBefore: 0,
        hotelNightsAfter: 0,
      );
      expect(c.dueUnsure, isFalse);
    });

    test('숙박과 투어 별도 비용은 서로 다른 줄이다', () {
      final c = RegistrationCost.of(
        program: _program(
          options: [
            {
              'id': 'a',
              'cost': 800,
              'includesMeals': false,
              'estMealsCost': 120,
            },
          ],
          hotels: [
            {'key': 'std', 'pricePerNight': 40},
          ],
        ),
        feeTier: 'basic',
        selectedOptionIds: const ['a'],
        hotelOptionKey: 'std',
        hotelNightsBefore: 0,
        hotelNightsAfter: 1,
      );
      // 200 + 800 + 40
      expect(c.due, 1040);
      // 투어 밥값은 참가자가 현지에서 쓴다.
      expect(c.extrasKnown, 120);
    });
  });

  test('값을 정해 두지 않은 수양회는 할 말이 없다', () {
    final c = RegistrationCost.of(
      program: _program(feeBasic: null, feePremium: null),
      feeTier: null,
      selectedOptionIds: const [],
      hotelOptionKey: null,
      hotelNightsBefore: 0,
      hotelNightsAfter: 0,
    );
    expect(c.isEmpty, isTrue);
  });
}
