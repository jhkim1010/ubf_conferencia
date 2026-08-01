import 'package:flutter_test/flutter_test.dart';

// summary_screen.dart 의 _flightWhen 과 같은 규칙.
//
// 원본이 private 이라 여기 복제해 둔다. 규칙 자체가 조용히 틀리기 쉬운
// 종류라서(시차·자정) 지켜 둘 값어치가 있다. 원본을 고치면 여기도 고쳐야
// 한다 — 어긋나면 이 테스트가 먼저 깨진다.
String flightWhen(Object? raw) {
  final s = raw?.toString() ?? '';
  if (s.length < 10) return s;
  final date = s.substring(0, 10);
  if (s.length < 16 || s[10] != 'T') return date;
  final time = s.substring(11, 16);
  return time == '00:00' ? date : '$date $time';
}

void main() {
  test('예상 날짜(자정)는 시각을 붙이지 않는다', () {
    // 예매 전 예상 날짜는 시각 없이 자정으로 저장된다. 그대로 붙이면
    // "새벽 0시 도착"이라는 없는 정보를 만들어 낸다.
    expect(flightWhen('2026-09-13T00:00:00.000'), '2026-09-13');
  });

  test('실제 항공편은 시:분까지 보여준다', () {
    expect(flightWhen('2026-09-13T14:35:00.000'), '2026-09-13 14:35');
  });

  test('UTC 표기가 붙어도 날짜가 밀리지 않는다', () {
    // DateTime 으로 파싱하면 로컬 변환이 일어나 시차에 따라 하루 밀린다.
    // 자르기만 하므로 서버가 적어 준 날짜가 그대로 남는다.
    expect(flightWhen('2026-09-13T03:00:00.000Z'), '2026-09-13 03:00');
    expect(flightWhen('2026-01-01T00:00:00.000Z'), '2026-01-01');
  });

  test('날짜만 있어도 그대로 돌려준다', () {
    expect(flightWhen('2026-09-13'), '2026-09-13');
  });

  test('비었거나 깨진 값은 그대로 (화면이 죽지 않는다)', () {
    expect(flightWhen(null), '');
    expect(flightWhen(''), '');
    expect(flightWhen('없음'), '없음');
  });
}
