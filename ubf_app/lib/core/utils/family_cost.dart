/// 함께 오는 사람까지 합친 금액 — 등급마다 (077)
///
/// 동반자를 적는 사람이 가장 먼저 묻는 것은 "그래서 우리 둘이 얼마냐" 다.
/// 어린이 몫(073)과 침대 머릿수(069)를 따로 보여 주면 더하는 것은 그 사람
/// 몫이 되고, 등급(기본·프리미엄, 숙박 수준)마다 다시 더해야 한다.
///
/// **방을 같이 쓰든 따로 쓰든 금액은 같다.** 숙박 단가가 한 사람 한 밤
/// 값이기 때문이다. 다른 방을 쓰는 동반자는 늘 침대를 쓰므로 머릿수에
/// 들어간다(lodgingHeads).
///
/// 이 등록의 낼 돈에 붙는 사람만 센다 — 따로 등록하는 동반자는 자기
/// 등록에서 낸다. 셈의 규칙은 ChildFeePolicy · lodgingHeads 를 그대로 쓴다.
/// 두 벌로 두면 이 표와 실제로 낼 돈이 갈라진다.
///
/// DB 도 HTTP 도 쓰지 않는다. test/family_cost_test.dart 로 그대로 확인한다.
library;

import 'child_fee.dart';
import 'hotel_price.dart';
import 'money.dart';

/// 참가비 등급 한 줄: 본인 + 동반자 = 합계.
class FamilyFeeRow {
  const FamilyFeeRow({
    required this.tier,
    required this.self,
    required this.others,
  });

  /// 'basic' 또는 'premium'.
  final String tier;
  final double self;
  final double others;
  double get total => ((self + others) * 100).roundToDouble() / 100;
}

/// 숙박 수준 한 줄: 한 사람 한 밤 값 × 머릿수 (× 박수).
class FamilyHotelRow {
  const FamilyHotelRow({
    required this.option,
    required this.perNight,
    required this.heads,
    required this.nights,
  });

  final Map<String, dynamic> option;
  final double perNight;
  final int heads;

  /// 값을 매길 밤 수. 0 이면 아직 모른다(비행 일정을 안 적었다).
  final int nights;

  double get perNightAll => perNight * heads;
  double? get total => nights > 0 ? perNight * heads * nights : null;
}

class FamilyCost {
  const FamilyCost({
    required this.people,
    required this.heads,
    required this.fees,
    required this.hotels,
    required this.separateCount,
  });

  /// 이 등록의 낼 돈에 붙는 사람 수 — 본인과 따로 등록하지 않는 동반자.
  final int people;

  /// 전후 숙박비를 낼 머릿수.
  final int heads;
  final List<FamilyFeeRow> fees;
  final List<FamilyHotelRow> hotels;

  /// 따로 등록하는 동반자 수. 그분들 돈은 여기 없다고 말해 줘야 한다.
  final int separateCount;

  static FamilyCost of({
    required Map<String, dynamic> program,
    required List<Map<String, dynamic>> companions,
    int nights = 0,
  }) {
    bool separate(Map<String, dynamic> c) =>
        c['registersSeparately'] != false && c['registers_separately'] != false;
    final policy = ChildFeePolicy.of(program);
    final heads = lodgingHeads(companions);

    final fees = <FamilyFeeRow>[
      for (final tier in const ['basic', 'premium'])
        if (Money.parse(program['fee_$tier']) case final fee?)
          FamilyFeeRow(
            tier: tier,
            self: fee.toDouble(),
            others: policy.totalFor(companions, fee.toDouble()),
          ),
    ];

    // 값을 못 정한 수준(범위·미정)은 합칠 수가 없다. 낮은 쪽만 있으면
    // 그것으로 센다 — 등록 화면의 예상 숙박비와 같은 규칙이다.
    final hotels = <FamilyHotelRow>[
      for (final o
          in ((program['hotel_options'] as List?) ?? const [])
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m)))
        if (HotelPrice.of(o).low case final low? when low > 0)
          FamilyHotelRow(
            option: o,
            perNight: low.toDouble(),
            heads: heads,
            nights: nights < 0 ? 0 : nights,
          ),
    ];

    return FamilyCost(
      people: 1 + companions.where((c) => !separate(c)).length,
      heads: heads,
      fees: fees,
      hotels: hotels,
      separateCount: companions.where(separate).length,
    );
  }
}
