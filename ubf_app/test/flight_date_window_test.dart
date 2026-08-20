// 항공편 날짜 창 — 오늘이 도착일로 들어오지 않는가.
//
// 고르개가 오늘로 열리면 참가자는 아무 생각 없이 확인을 누른다. 운영에서
// 실제로 셋이 그랬고, 숙박비를 비행 일정에서 세는 지금은 그게 청구서가 된다.
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/flight_date_window.dart';

void main() {
  final start = DateTime(2027, 1, 21);
  final end = DateTime(2027, 1, 24);
  final today = DateTime(2026, 8, 20);

  test('아직 안 고른 사람에게 오늘이 아니라 수양회 첫날을 내민다', () {
    final w = FlightDateWindow.of(
      start: start,
      end: end,
      isArrival: true,
      fallback: today,
    );
    expect(w.initial, start);
    expect(w.initial, isNot(today));
  });

  test('돌아가는 날은 마지막 날을 내민다', () {
    final w = FlightDateWindow.of(
      start: start,
      end: end,
      isArrival: false,
      fallback: today,
    );
    expect(w.initial, end);
  });

  test('오늘은 아예 고를 수 없는 자리에 있다', () {
    final w = FlightDateWindow.of(
      start: start,
      end: end,
      isArrival: true,
      fallback: today,
    );
    expect(today.isBefore(w.first), isTrue, reason: '오늘이 창 안에 있으면 또 들어온다');
  });

  test('일찍 오는 사람은 막지 않는다 — 한 달 앞까지', () {
    final w = FlightDateWindow.of(
      start: start,
      end: end,
      isArrival: true,
      fallback: today,
    );
    expect(w.first, DateTime(2026, 12, 22));
    expect(w.last, DateTime(2027, 2, 23));
  });

  test('이미 고른 날은 그대로 둔다', () {
    final chosen = DateTime(2027, 1, 19);
    final w = FlightDateWindow.of(
      start: start,
      end: end,
      isArrival: true,
      chosen: chosen,
      fallback: today,
    );
    expect(w.initial, chosen);
  });

  test('돌아가는 날은 오는 날보다 앞설 수 없다', () {
    final w = FlightDateWindow.of(
      start: start,
      end: end,
      isArrival: false,
      notBefore: DateTime(2027, 1, 23),
      fallback: today,
    );
    expect(w.first, DateTime(2027, 1, 23));
    expect(w.initial.isBefore(w.first), isFalse);
  });

  test('수양회 기간을 모르면 좁히지 않는다', () {
    // 기간이 없는데 창을 좁히면 맞는 날짜까지 막는다.
    final w = FlightDateWindow.of(isArrival: true, fallback: today);
    expect(w.first, DateTime(2020));
    expect(w.initial, today);
  });

  test('내미는 날은 언제나 창 안에 있다', () {
    for (final chosen in [DateTime(2020, 1, 1), DateTime(2029, 1, 1)]) {
      final w = FlightDateWindow.of(
        start: start,
        end: end,
        isArrival: true,
        chosen: chosen,
        fallback: today,
      );
      expect(w.initial.isBefore(w.first), isFalse);
      expect(w.initial.isAfter(w.last), isFalse);
    }
  });
}
