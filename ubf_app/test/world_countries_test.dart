import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/constants/world_countries.dart';

// 국가 값은 ISO 코드로 저장하고 표시는 항상 영어다.
//
// 이 계약이 깨지면 아무 오류 없이 "국내 참석자 0명"이 된다 — 항공편 스텝 생략,
// 준비 현황 코호트, 봉사 신청 자격이 모두 조용히 틀린다. 실제로 그 상태로
// 한동안 돌았기 때문에 여기서 고정한다.
void main() {
  test('ISO 코드로 영문명을 얻는다', () {
    expect(WorldCountries.nameOf('AR'), 'Argentina');
    expect(WorldCountries.nameOf('KR'), 'South Korea');
    expect(WorldCountries.nameOf('BR'), 'Brazil');
  });

  test('국가명은 언어와 무관하게 영어다', () {
    // 표시명에 한글이 섞여 있으면 언어마다 다른 문자열이 되어 비교가 깨진다.
    final hangul = RegExp(r'[가-힣]');
    for (final c in WorldCountries.all) {
      expect(
        hangul.hasMatch(c.name),
        isFalse,
        reason: '${c.iso} 의 표시명에 한글이 있음: ${c.name}',
      );
    }
  });

  test('예전 한글 표시명을 ISO 로 되돌린다', () {
    expect(WorldCountries.isoForLegacy('아르헨티나'), 'AR');
    expect(WorldCountries.isoForLegacy('대한민국'), 'KR');
    expect(WorldCountries.isoForLegacy('브라질'), 'BR');
  });

  test('예전 UBF 지부 목록 표기를 ISO 로 되돌린다', () {
    expect(WorldCountries.isoForLegacy('ARGENTINA'), 'AR');
    expect(WorldCountries.isoForLegacy('BRASIL'), 'BR'); // 포르투갈어 표기
    expect(WorldCountries.isoForLegacy('U. S. A.'), 'US'); // 마침표·공백
    expect(WorldCountries.isoForLegacy('Sri-Lanka'), 'LK'); // 하이픈
    expect(WorldCountries.isoForLegacy('CAMEROUN'), 'CM'); // 프랑스어 표기
    expect(WorldCountries.isoForLegacy('KOREA'), 'KR');
  });

  test('이미 ISO 인 값은 그대로 둔다', () {
    expect(WorldCountries.isoForLegacy('AR'), 'AR');
    expect(WorldCountries.isoForLegacy('  BR  '), 'BR');
  });

  test('이것이 원래 깨져 있던 비교다', () {
    // users.region 에는 '아르헨티나', registrations.country 에는 'ARGENTINA' 가
    // 들어갔다. 정규화 없이 비교하면 같은 나라인데 절대 일치하지 않는다.
    const fromProfile = '아르헨티나';
    const fromRegistration = 'ARGENTINA';
    expect(fromProfile == fromRegistration, isFalse);
    expect(
      WorldCountries.isoForLegacy(fromProfile),
      WorldCountries.isoForLegacy(fromRegistration),
    );
  });

  test('display 는 무슨 값이 오든 화면에 쓸 문자열을 준다', () {
    expect(WorldCountries.display('AR'), 'Argentina');
    expect(WorldCountries.display('아르헨티나'), 'Argentina');
    expect(WorldCountries.display('ARGENTINA'), 'Argentina');
    expect(WorldCountries.display(null), isNull);
    expect(WorldCountries.display('   '), isNull);
    // 해석되지 않는 값은 지우지 않고 그대로 보여준다.
    expect(WorldCountries.display('ATLANTIS'), 'ATLANTIS');
  });

  test('ISO 코드가 중복되지 않는다', () {
    final seen = <String>{};
    for (final c in WorldCountries.all) {
      expect(seen.add(c.iso), isTrue, reason: 'ISO 중복: ${c.iso}');
    }
  });

  test('목록이 영문명 순으로 정렬돼 있다', () {
    final names = WorldCountries.all.map((c) => c.name).toList();
    final sorted = [...names]..sort();
    expect(names, sorted);
  });
}
