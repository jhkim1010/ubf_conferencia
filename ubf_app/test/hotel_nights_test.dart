// 항공편으로 호텔 박수를 계산한다(028).
//
// 이 계산이 틀리면 참가자가 잘 방을 예약하지 못하거나, 도착한 날 잘 곳이 없다.
// 정상 경로보다 경계(늦게 도착·일찍 출발·시차)에 무게를 둔다.

import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/hotel_nights.dart';

void main() {
  const start = '2027-07-05';
  const end = '2027-07-09';

  test('일찍 오고 늦게 가면 앞뒤로 박수가 나온다', () {
    final r = computeHotelNights(
      arrival: '2027-07-03T22:10:00.000Z',
      departure: '2027-07-12T06:00:00.000Z',
      programStart: start,
      programEnd: end,
    );
    expect(r.before, 2); // 3일 도착 → 5일 시작
    expect(r.after, 3); // 9일 종료 → 12일 출발
  });

  test('시작일에 도착하면 앞은 0 박 — 새벽이어도 그렇다', () {
    // 그날부터 수양회 숙소를 쓰므로 호텔이 필요 없다. 시각을 함께 보면
    // 02시 도착을 "전날 밤부터 필요"로 잘못 읽는다.
    for (final t in ['T00:10:00.000Z', 'T02:00:00.000Z', 'T23:50:00.000Z']) {
      final r = computeHotelNights(
        arrival: '2027-07-05\$t',
        departure: '2027-07-09T20:00:00.000Z',
        programStart: start,
        programEnd: end,
      );
      expect(r.before, 0, reason: t);
      expect(r.after, 0, reason: t);
    }
  });

  test('전날 도착하면 밤 11시라도 1박이 필요하다', () {
    // 시각이 아니라 날짜로 센다. 늦게 도착했으니 안 자도 된다고 볼 수 없다 —
    // 그날 밤 잘 곳이 없으면 공항에서 밤을 새운다.
    for (final t in ['T23:00:00.000Z', 'T23:59:00.000Z', 'T08:00:00.000Z']) {
      final r = computeHotelNights(
        arrival: '2027-07-04\$t',
        programStart: start,
      );
      expect(r.before, 1, reason: t);
    }
  });

  test('수양회가 시작한 뒤 도착해도 음수가 되지 않는다', () {
    final r = computeHotelNights(
      arrival: '2027-07-07',
      departure: '2027-07-09',
      programStart: start,
      programEnd: end,
    );
    expect(r.before, 0);
  });

  test('투어가 수양회보다 늦게 끝나면 그 뒤부터 센다', () {
    // 투어 없이 세면 3박이 나오지만, 투어가 11일까지면 실제로는 1박이다.
    final r = computeHotelNights(
      arrival: '2027-07-05',
      departure: '2027-07-12',
      programStart: start,
      programEnd: end,
      stayEndDates: const ['2027-07-11', '2027-07-10'],
    );
    expect(r.after, 1);
  });

  test('투어가 수양회보다 일찍 끝나면 수양회 종료일을 쓴다', () {
    final r = computeHotelNights(
      arrival: '2027-07-05',
      departure: '2027-07-12',
      programStart: start,
      programEnd: end,
      stayEndDates: const ['2027-07-07'],
    );
    expect(r.after, 3);
  });

  test('항공편이 없으면 그 방향은 모른다 — 0 이 아니다', () {
    // 0 박으로 보여주면 계산이 끝난 줄 알고 그대로 넘어간다.
    final r = computeHotelNights(
      arrival: null,
      departure: '2027-07-12',
      programStart: start,
      programEnd: end,
    );
    expect(r.before, isNull);
    expect(r.after, 3);
    expect(r.hasAny, isTrue);
  });

  test('수양회 일정이 없으면 아무것도 계산하지 않는다', () {
    final r = computeHotelNights(
      arrival: '2027-07-03',
      departure: '2027-07-12',
    );
    expect(r.hasAny, isFalse);
  });

  test('UTC 시각을 그대로 잘라 쓴다 — 시차로 하루가 밀리지 않는다', () {
    // 부에노스아이레스(UTC-3)에서 로컬 변환을 하면 7월 3일이 2일이 되어
    // 앞 박수가 하나 늘어난다. 문자열 앞 10자만 보므로 그런 일이 없다.
    final r = computeHotelNights(
      arrival: '2027-07-03T01:00:00.000Z',
      programStart: start,
    );
    expect(r.before, 2);
  });

  test('말도 안 되게 이른 도착은 상한에서 잘린다', () {
    final r = computeHotelNights(arrival: '2020-01-01', programStart: start);
    expect(r.before, maxHotelNights);
  });

  test('날짜 형식이 아니면 무시한다', () {
    for (final bad in ['', '없음', '2027-13-40', '7/5/2027']) {
      final r = computeHotelNights(arrival: bad, programStart: start);
      expect(r.before, isNull, reason: bad);
    }
  });
}
