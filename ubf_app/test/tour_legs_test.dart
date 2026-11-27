import 'package:flutter_test/flutter_test.dart';
import 'package:mana/features/registration/providers/registration_provider.dart';
import 'package:mana/features/registration/widgets/tour_legs.dart';

// 투어 때 타는 비행기(081). 서버 test/tour_flights.test.js 와 같은 순서 규칙.
void main() {
  test('구간은 날짜순, 같은 날이면 가는 편이 먼저', () {
    final sorted = sortTourLegs([
      {'kind': 'tour_return', 'date': '2027-01-09'},
      {'kind': 'other', 'date': '2027-01-07'},
      {'kind': 'tour_out', 'date': '2027-01-07'},
      {'kind': 'tour_out', 'date': null},
    ]);
    expect(sorted.map((l) => '${l['kind']} ${l['date']}').toList(), [
      'tour_out 2027-01-07',
      'other 2027-01-07',
      'tour_return 2027-01-09',
      'tour_out null',
    ]);
  });

  test('같은 날이면 이른 시각이 먼저', () {
    final sorted = sortTourLegs([
      {'kind': 'tour_out', 'date': '2027-01-07', 'time': '11:45'},
      {'kind': 'tour_out', 'date': '2027-01-07', 'time': '08:10'},
    ]);
    expect(sorted.first['time'], '08:10');
  });

  test('저장된 값이 목록이 아니면 빈 목록', () {
    expect(tourLegsFrom(null), isEmpty);
    expect(tourLegsFrom('x'), isEmpty);
    expect(
      tourLegsFrom([
        1,
        {'kind': 'other'},
      ]).length,
      1,
    );
  });

  test('고른 투어만 시작일 순으로', () {
    final tours = pickedTours(
      [
        {'id': 'b', 'start_date': '2027-01-10'},
        {'id': 'a', 'start_date': '2027-01-07'},
        {'id': 'c', 'start_date': '2027-01-01'},
      ],
      ['a', 'b'],
    );
    expect(tours.map((t) => t['id']).toList(), ['a', 'b']);
  });

  test('날짜 창은 수양회 30일 전부터 가장 늦은 투어 30일 뒤까지', () {
    final w = tourLegWindow(
      {'start_date': '2027-01-02', 'end_date': '2027-01-06'},
      [
        {'end_date': '2027-01-09'},
      ],
    );
    expect(w.first, DateTime(2026, 12, 3));
    expect(w.last, DateTime(2027, 2, 8));
  });
}
