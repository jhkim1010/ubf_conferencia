// 수양회 전후로 호텔이 몇 박 필요한지 항공편에서 계산한다(028).
//
// 참가자에게 "며칠 묵으시겠습니까"를 백지로 물으면 대부분 틀리게 적는다.
// 이미 적어 낸 항공편과 수양회 일정에 답이 들어 있으므로 계산해서 보여주고,
// 다르면 고치게 한다.
//
// **시작일에 도착하면 앞 숙박은 0 박이다 — 새벽 도착이라도 그렇다.**
// 그날부터 수양회 숙소를 쓰므로 호텔이 필요하지 않다. 시각을 함께 보면
// 02시 도착을 "전날 밤부터 필요"로 읽게 되는데, 그건 틀린 계산이다.
// 그래서 시각은 아예 버리고 날짜만 센다.
//
// 날짜는 **문자열 앞 10자만** 떼어 UTC 로 만든다. DateTime.parse 로 통째로
// 읽으면 UTC → 로컬 변환이 일어나 시차에 따라 하루가 밀린다. 요약 화면에서
// 수양회 시작일이 하루 당겨져 보이던 것과 같은 함정이다.

/// 계산 결과. 근거가 없으면 그 방향은 `null` 이다 —
/// 0 박과 "알 수 없음"은 다르다. 0 을 보여주면 계산된 줄 안다.
class HotelNights {
  final int? before;
  final int? after;

  const HotelNights({this.before, this.after});

  bool get hasAny => before != null || after != null;

  /// 화면에 적용할 값. 모르는 쪽은 건드리지 않는다.
  int get beforeOrZero => before ?? 0;
  int get afterOrZero => after ?? 0;
}

/// 상한. services/hotel.js 의 MAX_NIGHTS 와 맞춘다.
const int maxHotelNights = 60;

DateTime? _day(Object? raw) {
  final s = raw?.toString().trim() ?? '';
  if (s.length < 10) return null;
  final y = int.tryParse(s.substring(0, 4));
  final m = int.tryParse(s.substring(5, 7));
  final d = int.tryParse(s.substring(8, 10));
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime.utc(y, m, d);
}

int _nights(DateTime from, DateTime to) {
  final n = to.difference(from).inDays;
  if (n <= 0) return 0; // 늦게 도착하거나 일찍 떠나면 그 방향은 0 박이다
  return n > maxHotelNights ? maxHotelNights : n;
}

/// [arrival] 도착 항공편 시각, [departure] 출발 항공편 시각.
/// [programStart] 수양회 시작일, [programEnd] 수양회 종료일.
/// [stayEndDates] 참가자가 고른 투어의 종료일들 — 투어가 수양회보다 늦게
/// 끝나면 그 뒤부터 호텔이 필요하다.
HotelNights computeHotelNights({
  Object? arrival,
  Object? departure,
  Object? programStart,
  Object? programEnd,
  Iterable<Object?> stayEndDates = const [],
}) {
  final arriveOn = _day(arrival);
  final leaveOn = _day(departure);
  final startOn = _day(programStart);

  // 언제까지 수양회 숙소에 머무는가. 투어가 더 늦게 끝나면 그날까지다.
  var stayEnd = _day(programEnd) ?? startOn;
  for (final raw in stayEndDates) {
    final d = _day(raw);
    if (d == null) continue;
    if (stayEnd == null || d.isAfter(stayEnd)) stayEnd = d;
  }

  return HotelNights(
    before: (arriveOn != null && startOn != null)
        ? _nights(arriveOn, startOn)
        : null,
    after: (leaveOn != null && stayEnd != null)
        ? _nights(stayEnd, leaveOn)
        : null,
  );
}

/// 어느 방을 기본으로 내밀 것인가 (064).
///
/// **가장 싼 방**이다. 이름으로 "일반실" 을 찾지 않는다 — 수양회마다 이름이
/// 다르고 언어도 넷이라, 이름에 기대면 어느 수양회에서는 조용히 아무것도
/// 안 골라진다. 값이 그 뜻을 그대로 담고 있다.
///
/// 서버의 `services/hotel_choice.js` 와 같은 규칙이다.
/// `test/hotel_choice_test.dart` 가 서버 쪽 테스트와 같은 예를 본다.
String? defaultHotelKey(List<Map<String, dynamic>> options) {
  if (options.isEmpty) return null;
  Map<String, dynamic>? best;
  num bestPrice = double.infinity;
  for (final o in options) {
    final p = num.tryParse('${o['pricePerNight'] ?? ''}');
    if (p != null && p >= 0 && p < bestPrice) {
      bestPrice = p;
      best = o;
    }
  }
  return (best ?? options.first)['key'] as String?;
}

/// 이 사람은 방을 골라야 하는가.
///
/// 묵을 밤이 없으면 고를 것도 없다. 주최 측이 등급을 아직 안 만들었으면
/// 고를 수가 없으므로 막지 않는다 — 막으면 제출 자체를 못 한다.
bool mustPickHotel({required int nights, required List<dynamic> options}) =>
    nights > 0 && options.isNotEmpty;
