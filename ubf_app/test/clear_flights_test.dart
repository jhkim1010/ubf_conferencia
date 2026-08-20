// 항공편 지우기 — copyWith 로는 못 지운다.
//
// copyWith 는 `??` 로 합치므로 null 을 넘겨도 "안 넘긴 것" 과 구별되지
// 않는다. 그래서 지우는 길이 따로 필요했다. 개최국에서 오시는 분은 항공편
// 화면 자체를 못 보므로(035) 이 길이 없으면 남은 값을 영영 못 지우고,
// 그 값이 숙박비를 끌고 간다(060).
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/features/registration/providers/registration_provider.dart';

void main() {
  const filled = RegistrationFormState(
    programId: 'p1',
    arrivalFlight: {'scheduled_arrival': '2026-08-20'},
    departureFlight: {'scheduled_departure': '2026-08-25'},
    realName: '김영해',
  );

  test('copyWith 에 null 을 넘겨도 안 지워진다', () {
    // 이것이 지워졌다면 clearFlights 는 필요 없었을 것이다.
    final same = filled.copyWith(arrivalFlight: null, departureFlight: null);
    expect(same.arrivalFlight, isNotNull);
    expect(same.departureFlight, isNotNull);
  });

  test('clearFlights 로는 지워진다', () {
    final cleared = filled.copyWith(clearFlights: true);
    expect(cleared.arrivalFlight, isNull);
    expect(cleared.departureFlight, isNull);
  });

  test('지워도 나머지는 그대로다', () {
    final cleared = filled.copyWith(clearFlights: true);
    expect(cleared.realName, '김영해');
  });

  test('지우면서 동시에 넣지는 않는다', () {
    // 둘 다 오면 지우는 쪽이 이긴다. 애매하게 반만 남는 것이 가장 나쁘다.
    final cleared = filled.copyWith(
      clearFlights: true,
      arrivalFlight: const {'scheduled_arrival': '2027-01-21'},
    );
    expect(cleared.arrivalFlight, isNull);
  });
}
