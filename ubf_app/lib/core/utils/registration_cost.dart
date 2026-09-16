/// 등록하는 사람이 보는 금액 (064)
///
/// 확인 화면에만 있던 셈을 여기로 꺼냈다. 등록 내내 따라다니는 비용 막대가
/// 같은 셈을 써야 하기 때문이다. 두 벌로 두면 언젠가 갈라지고, 갈라지면
/// 참가자가 화면마다 다른 숫자를 보게 된다.
///
/// **두 값을 절대 합치지 않는다.**
///
///   [due]     우리에게 내는 돈. 참가비 + 투어 값 + 전후 숙박비 - 확정된 할인.
///   [extrasKnown] 참가자가 따로 쓸 돈. 투어 값에 안 든 것(061·062)이다.
///
/// **전후 숙박비는 우리에게 내는 돈이다(064).** 주최가 방을 잡고 받아서
/// 호텔에 내므로 참가자가 호텔에 직접 내는 것이 아니다. 서버도 같은 셈을
/// 한다(services/registration_total.js).
///
/// 따로 쓸 돈은 우리가 받는 돈이 아니고 무엇보다 예상이다. 합계에 섞으면
/// 확정된 청구서처럼 보인다. 빼 버리면 참가자가 돈을 덜 챙겨 온다.
///
/// DB 도 HTTP 도 쓰지 않는다. test/registration_cost_test.dart 로 그대로 확인한다.
library;

import '../constants/world_countries.dart';
import 'hotel_price.dart';
import 'money.dart';
import 'tour_extras.dart';

class RegistrationCost {
  const RegistrationCost({
    required this.tierFee,
    required this.optionsTotal,
    required this.discount,
    required this.due,
    required this.dueMax,
    required this.dueUnsure,
    required this.lodgingNeedsFlight,
    required this.hotelNights,
    required this.hotelEstimate,
    required this.extrasKnown,
    required this.extrasUnsure,
    required this.extraKinds,
  });

  /// 고른 참가비 등급의 값. 등급을 아직 안 골랐으면 0.
  final double tierFee;

  /// 고른 투어 값의 합.
  final double optionsTotal;

  /// **승인된** 할인만이다. 신청 중인 금액을 미리 빼면 아직 결정되지도 않은
  /// 감액을 확정된 것처럼 보여주게 된다.
  final double discount;

  /// 우리에게 내는 돈. 0 아래로는 안 내려간다.
  final double due;

  /// 숙박 단가를 범위로 적어 둔 경우(066) 높은 쪽으로 센 낼 돈.
  ///
  /// 범위가 아니면 [due] 와 같다. **[due] 는 언제나 낮은 쪽**이고 명단에
  /// 남는 것도 그쪽이다 — 잘못 잡았을 때 덜 받는 쪽이 더 받는 쪽보다 낫다.
  /// 이 값은 화면이 "U\$ 295 ~ 315" 라고 적는 데만 쓴다.
  final double dueMax;

  /// 낼 돈이 범위인가.
  bool get dueIsRange => dueMax > due;

  /// [due] 에 아직 못 넣은 것이 있는가.
  ///
  /// 묵을 밤은 있는데 숙박 등급을 아직 안 골랐을 때다. 단가를 모르니 셀 수가
  /// 없다. **이때 화면은 반드시 그 사실을 말해야 한다** — 숫자만 보여주면
  /// 숙박이 공짜인 줄 알고, 나중에 늘어난 금액을 보고 놀란다.
  final bool dueUnsure;

  /// 돌아가는 비행기를 아직 안 적어 **박수를 낼 수가 없는가**(066).
  ///
  /// 외국에서 오시는 분의 전후 숙박은 비행 일정으로 센다(060). 그 일정이
  /// 없으면 0박이 나오는데, 그것은 "안 묵는다" 가 아니라 "아직 모른다" 다.
  /// 0 으로 보여주면 합계가 다 된 줄 알고 그만큼 덜 챙겨 오신다.
  final bool lodgingNeedsFlight;

  /// 수양회 전후로 묵는 밤 수.
  final int hotelNights;

  /// 그 밤들에 들 돈. 등급을 아직 안 골랐으면 null — 0 과 다르다.
  final double? hotelEstimate;

  /// 따로 쓸 돈 중 **금액을 아는 것들**의 합.
  final double extrasKnown;

  /// 따로 쓸 돈이 **무엇으로 이루어졌는가**. 화면이 "약 30 (숙박·식사)" 처럼
  /// 짧게 적을 수 있게 종류만 준다. 금액이 미정인 것도 종류에는 들어간다 —
  /// 무엇 때문에 더 드는지는 금액을 몰라도 말해 줄 수 있다.
  final List<ExtraKind> extraKinds;

  /// 따로 쓸 돈 중 금액을 아직 모르는 것이 있는가.
  ///
  /// 있으면 화면이 반드시 그 사실을 말해야 한다 — 아는 것만 적어 두면
  /// 그것이 전부인 줄 알고 참가자가 돈을 덜 챙겨 온다.
  final bool extrasUnsure;

  /// 할 말이 아무것도 없는가. 막대를 통째로 감출지 여기서 가른다.
  bool get isEmpty =>
      due == 0 &&
      extrasKnown == 0 &&
      !extrasUnsure &&
      !dueUnsure &&
      !lodgingNeedsFlight;

  /// 이 사람의 전후 숙박비를 아직 셀 수 없는가.
  ///
  /// 외국에서 오시는데 돌아가는 비행기를 안 적었으면 셀 수가 없다.
  /// 개최국에서 오시는 분은 비행기가 없는 것이 정상이므로 해당 없다.
  static bool lodgingPendingFlight({
    required String? hostCountry,
    required String? country,
    required Object? departureFlight,
  }) {
    final host = WorldCountries.isoForLegacy(hostCountry);
    if (host == null) return false; // 지역 수양회 — 전후 숙박 자체가 없다
    final mine = WorldCountries.isoForLegacy(country);
    if (mine == null || mine == host) return false;
    return departureFlight == null;
  }

  /// [program] 은 서버가 준 수양회 표현 그대로.
  /// [savedDiscountStatus]·[savedDiscountAmount] 는 저장된 등록의 할인 결정이다.
  static RegistrationCost of({
    required Map<String, dynamic> program,
    required String? feeTier,
    required List<String> selectedOptionIds,
    required String? hotelOptionKey,
    required int hotelNightsBefore,
    required int hotelNightsAfter,
    String? savedDiscountStatus,
    Object? savedDiscountAmount,
    bool lodgingNeedsFlight = false,
  }) {
    final options = List<Map<String, dynamic>>.from(
      program['program_options'] as List? ?? const [],
    );
    final picked = options
        .where((o) => selectedOptionIds.contains(o['id'] as String?))
        .toList();

    final optionsTotal = picked.fold<double>(
      0,
      (sum, o) => sum + (Money.parse(o['cost']) ?? 0).toDouble(),
    );

    final tierFee = switch (feeTier) {
      'basic' => Money.parse(program['fee_basic']),
      'premium' => Money.parse(program['fee_premium']),
      _ => null,
    };

    final discount = savedDiscountStatus == 'approved'
        ? (Money.parse(savedDiscountAmount) ?? 0).toDouble()
        : 0.0;

    // 수양회 전후 숙박. 단가는 저장하지 않고 그때그때 센다 — 저장해 두면
    // 담당자가 단가를 고친 뒤에도 옛 금액이 남아 둘이 다른 숫자를 본다.
    final hotelOptions = List<Map<String, dynamic>>.from(
      program['hotel_options'] as List? ?? const [],
    );
    final hotelPicked = hotelOptions.cast<Map<String, dynamic>?>().firstWhere(
      (o) => o?['key'] == hotelOptionKey,
      orElse: () => null,
    );
    final hotelNights = hotelNightsBefore + hotelNightsAfter;
    final price = HotelPrice.of(hotelPicked);
    final hotelEstimate = price.lowFor(hotelNights)?.toDouble();
    // 범위로 적어 둔 곳이면 높은 쪽으로도 한 번 센다.
    final hotelEstimateMax = price.highFor(hotelNights)?.toDouble();

    final base = (tierFee ?? 0).toDouble() + optionsTotal - discount;
    final due = base + (hotelEstimate ?? 0);
    final dueMax = base + (hotelEstimateMax ?? hotelEstimate ?? 0);

    final tour = TourExtras.of(picked);

    return RegistrationCost(
      tierFee: (tierFee ?? 0).toDouble(),
      optionsTotal: _round(optionsTotal),
      discount: _round(discount),
      due: _round(due < 0 ? 0 : due),
      dueMax: _round(dueMax < 0 ? 0 : dueMax),
      // 묵을 밤은 있는데 등급을 안 골랐으면 숙박비를 아직 못 더한 것이다.
      dueUnsure: hotelNights > 0 && hotelEstimate == null,
      lodgingNeedsFlight: lodgingNeedsFlight,
      hotelNights: hotelNights,
      hotelEstimate: hotelEstimate == null ? null : _round(hotelEstimate),
      // 투어 값에 안 든 것만이다. 숙박비는 위에서 due 로 갔다.
      extrasKnown: _round(tour.known),
      extrasUnsure: tour.unknown.isNotEmpty,
      // 나온 순서대로, 겹치지 않게. 담당자가 이름 붙여 더한 항목(062)은
      // kind 가 없으므로 여기 안 들어간다 — 이름이 제각각이라 한 낱말로
      // 묶을 수가 없다.
      extraKinds: [
        for (final k in ExtraKind.values)
          if (tour.items.any((it) => it.kind == k)) k,
      ],
    );
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}
