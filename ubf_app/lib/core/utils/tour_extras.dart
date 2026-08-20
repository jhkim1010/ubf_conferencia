/// 투어 값에 안 들어 있는 것 (061)
///
/// 서버의 `services/tour_extras.js` 와 같은 규칙이다. 두 벌이지만 한쪽은
/// 명단·내보내기에, 다른 한쪽은 참가자 화면에 쓰인다.
/// **규칙이 갈리지 않게** `test/tour_extras_test.dart` 가 서버 쪽 테스트와
/// 같은 예를 본다.
///
/// 여기서 낸 값은 참가비에 더하지 않는다. 우리에게 내는 돈이 아니고,
/// 무엇보다 예상일 뿐이다. 합계에 섞으면 확정된 청구서처럼 보인다.
library;

enum ExtraKind { meals, lodging, airfare }

class ExtraItem {
  const ExtraItem({required this.kind, required this.amount, this.tour});

  final ExtraKind kind;

  /// null 이면 "안 들어 있는데 금액을 아직 모른다". 0 과 다르다 — 0 으로
  /// 세면 참가자가 돈을 덜 챙겨 온다.
  final double? amount;
  final String? tour;
}

class TourExtras {
  const TourExtras({
    required this.meals,
    required this.lodging,
    required this.airfare,
    required this.known,
    required this.items,
    required this.unknown,
  });

  final double meals;
  final double lodging;
  final double airfare;

  /// 금액이 적힌 것들의 합.
  final double known;

  final List<ExtraItem> items;

  /// 안 들어 있는데 금액을 아직 안 적은 것들.
  final List<ExtraItem> unknown;

  bool get isEmpty => items.isEmpty;

  /// 못 읽거나 음수면 null. 빈 문자열도 null 이다.
  static double? amountOf(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty) return null;
    final n = double.tryParse(s);
    if (n == null || n < 0) return null;
    return n;
  }

  /// [tours] 는 신청한 투어의 서버 표현 그대로.
  ///
  /// 안 적힌 것은 **들어 있는 것으로 본다**(061) — 060 과 같은 이유로,
  /// 잘못 잡았을 때 덜 받는 쪽이 더 받는 쪽보다 낫다.
  static TourExtras of(Iterable<Map<String, dynamic>> tours) {
    const fields = {
      ExtraKind.meals: ('includesMeals', 'estMealsCost'),
      ExtraKind.lodging: ('includesLodging', 'estLodgingCost'),
      ExtraKind.airfare: ('includesAirfare', 'estAirfareCost'),
    };
    final sums = {
      ExtraKind.meals: 0.0,
      ExtraKind.lodging: 0.0,
      ExtraKind.airfare: 0.0,
    };
    final items = <ExtraItem>[];
    final unknown = <ExtraItem>[];

    for (final t in tours) {
      for (final kind in ExtraKind.values) {
        final (includesKey, estKey) = fields[kind]!;
        if (t[includesKey] == false) {
          final amount = amountOf(t[estKey]);
          final item = ExtraItem(
            kind: kind,
            amount: amount,
            tour: t['name'] as String?,
          );
          items.add(item);
          if (amount == null) {
            unknown.add(item);
          } else {
            sums[kind] = sums[kind]! + amount;
          }
        }
      }
    }

    final known = sums.values.fold(0.0, (a, b) => a + b);
    return TourExtras(
      meals: sums[ExtraKind.meals]!,
      lodging: sums[ExtraKind.lodging]!,
      airfare: sums[ExtraKind.airfare]!,
      known: (known * 100).roundToDouble() / 100,
      items: items,
      unknown: unknown,
    );
  }
}

/// 최종 비용 옆에 뭐라고 적을 것인가(061).
///
/// 금액을 아는 것과 모르는 것이 섞이므로 네 갈래다. **모르는 것이 있으면
/// 반드시 말한다** — 아는 것만 적어 두면 그것이 전부인 줄 알고 참가자가
/// 돈을 덜 챙겨 온다.
enum ExtrasLine {
  /// 따로 나갈 돈이 없다. 아무 말도 하지 않는다.
  none,

  /// 얼마인지 다 안다. "약 500 이 더 듭니다".
  known,

  /// 아는 것도 있고 모르는 것도 있다. "약 500 이 있고, 미정인 것도 있습니다".
  knownAndUnsure,

  /// 더 들 것은 분명한데 금액을 모른다. 0 이라고 적으면 안 된다.
  unsureOnly,
}

ExtrasLine extrasLineOf({required double known, required bool unsure}) {
  if (known > 0) return unsure ? ExtrasLine.knownAndUnsure : ExtrasLine.known;
  return unsure ? ExtrasLine.unsureOnly : ExtrasLine.none;
}
