import 'package:flutter_test/flutter_test.dart';
import 'package:mana/features/sos/widgets/sos_fab.dart';

// SOS 버튼은 수양회 기간에만 보인다.
//
// 등록은 몇 달 전에 하는데 그때도 버튼이 떠서 입력 화면을 가렸다.
// 날짜 비교는 시차 때문에 하루씩 어긋나기 쉬워 경계값을 고정한다.
void main() {
  const start = '2027-02-10T03:00:00.000Z';
  const end = '2027-02-14T03:00:00.000Z';
  DateTime on(int m, int d) => DateTime(2027, m, d, 12);

  test('시작 전에는 보이지 않는다', () {
    expect(SosFab.isActive(start, end, now: on(2, 9)), isFalse);
    expect(SosFab.isActive(start, end, now: DateTime(2026, 12, 1)), isFalse);
  });

  test('시작 당일부터 보인다', () {
    expect(SosFab.isActive(start, end, now: on(2, 10)), isTrue);
  });

  test('기간 중에는 보인다', () {
    expect(SosFab.isActive(start, end, now: on(2, 12)), isTrue);
    expect(SosFab.isActive(start, end, now: on(2, 14)), isTrue);
  });

  test('종료 다음 날까지 남는다 — 귀국길', () {
    expect(SosFab.isActive(start, end, now: on(2, 15)), isTrue);
    expect(SosFab.isActive(start, end, now: on(2, 16)), isFalse);
  });

  test('시작일이 없으면 보이지 않는다', () {
    // 언제인지 모르는 채로 화면을 가리는 쪽이 더 나쁘다.
    expect(SosFab.isActive(null, end, now: on(2, 12)), isFalse);
    expect(SosFab.isActive('', end, now: on(2, 12)), isFalse);
  });

  test('종료일이 없으면 시작일 기준 하루', () {
    expect(SosFab.isActive(start, null, now: on(2, 10)), isTrue);
    expect(SosFab.isActive(start, null, now: on(2, 11)), isTrue);
    expect(SosFab.isActive(start, null, now: on(2, 12)), isFalse);
  });

  test('타임스탬프를 로컬 시각으로 바꾸지 않는다', () {
    // '2027-02-10T03:00:00Z' 를 DateTime.parse 로 읽고 로컬(UTC-3)로 바꾸면
    // 2027-02-10 00:00 이 되고, 시차가 더 크면 2027-02-09 로 하루 밀린다.
    // 앞 10자만 잘라 쓰므로 어느 시간대에서도 2027-02-10 이다.
    expect(SosFab.isActive(start, end, now: on(2, 9)), isFalse);
    expect(SosFab.isActive('2027-02-10', end, now: on(2, 10)), isTrue);
  });
}
