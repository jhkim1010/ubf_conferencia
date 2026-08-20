/// 항공편 날짜를 고를 수 있는 구간.
///
/// 고르개가 오늘 날짜로 열리고 아래끝이 2020 년이면, 참가자가 아무것도
/// 고르지 않고 확인만 눌러도 **오늘**이 도착일로 들어간다. 운영 자료에서
/// 실제로 셋이 그랬고, 그중 하나는 등록한 바로 그날이 도착일이었다.
/// 숙박비를 비행 일정에서 세기 시작한 뒤로는(060) 그 한 번의 확인이
/// 154 박짜리 청구서가 된다.
///
/// 그래서 수양회 기간을 중심으로 창을 좁힌다. 일찍 오거나 늦게 가는 사람이
/// 있으니 넉넉히 두되, 엉뚱한 해로 넘어가지는 못하게 한다.
library;

class FlightDateWindow {
  /// 수양회 앞뒤로 열어 두는 날수. 한 달이면 여행을 붙여 오는 사람도
  /// 담지만, 오늘 날짜가 실수로 들어오는 것은 막는다.
  static const int slackDays = 30;

  final DateTime first;
  final DateTime last;
  final DateTime initial;

  const FlightDateWindow({
    required this.first,
    required this.last,
    required this.initial,
  });

  /// [start]·[end] 는 수양회 기간. 하나라도 없으면 [fallback] 을 그대로 쓴다
  /// — 기간을 모르는 채로 창을 좁히면 맞는 날짜까지 막게 된다.
  static FlightDateWindow of({
    DateTime? start,
    DateTime? end,
    required bool isArrival,
    DateTime? chosen,
    DateTime? notBefore,
    required DateTime fallback,
  }) {
    if (start == null || end == null) {
      return FlightDateWindow(
        first: notBefore ?? DateTime(2020),
        last: DateTime(2030),
        initial: _clamp(
          chosen ?? fallback,
          notBefore ?? DateTime(2020),
          DateTime(2030),
        ),
      );
    }
    var first = start.subtract(const Duration(days: slackDays));
    final last = end.add(const Duration(days: slackDays));
    // 돌아가는 날은 오는 날보다 뒤여야 한다.
    if (notBefore != null && notBefore.isAfter(first)) first = notBefore;
    // 아직 안 고른 사람에게는 수양회 첫날(또는 마지막 날)을 내민다.
    // 오늘을 내밀면 그대로 확정되는 일이 생긴다.
    final suggested = chosen ?? (isArrival ? start : end);
    return FlightDateWindow(
      first: first,
      last: last.isBefore(first) ? first : last,
      initial: _clamp(suggested, first, last.isBefore(first) ? first : last),
    );
  }

  static DateTime _clamp(DateTime v, DateTime lo, DateTime hi) =>
      v.isBefore(lo) ? lo : (v.isAfter(hi) ? hi : v);
}
