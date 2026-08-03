// 시간대로 국가를 짐작한다.
//
// 틀리면 조용하다 — 참가자가 안 보고 넘기면 엉뚱한 나라로 등록되고, 그 값으로
// 개최국 판정·항공편 생략·픽업 제외가 줄줄이 어긋난다. 표가 제대로 생겼는지와
// 모를 때 억지로 채우지 않는지를 본다.

import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/constants/timezone_country.dart';
import 'package:mana/core/constants/world_countries.dart';
import 'package:mana/core/utils/country_guess.dart';

void main() {
  group('timezoneToCountry 표', () {
    test('이 수양회에 실제로 오는 나라들이 들어 있다', () {
      const expected = {
        'America/Argentina/Buenos_Aires': 'AR',
        'America/Sao_Paulo': 'BR',
        'Asia/Seoul': 'KR',
        'America/New_York': 'US',
        'Europe/Madrid': 'ES',
        'America/Mexico_City': 'MX',
        'Asia/Manila': 'PH',
        'Europe/Berlin': 'DE',
      };
      expected.forEach((zone, iso) {
        expect(timezoneToCountry[zone], iso, reason: zone);
      });
    });

    test('짐작한 값은 반드시 국가 목록에 있는 것만 쓴다', () {
      // 표에는 국가 목록에 없는 속령이 섞여 있다(괌·푸에르토리코·프랑스령
      // 기아나 등 57개). 그것을 그대로 고르면 드롭다운이 빈칸을 선택한 상태가
      // 된다. CountryGuess 가 isKnown 으로 거르므로, 여기서는 "거르고 나면
      // 쓸 수 있는 나라가 충분히 남는가"를 본다.
      final usable = timezoneToCountry.values
          .toSet()
          .where(WorldCountries.isKnown)
          .toSet();
      expect(usable.length, greaterThan(180));
      // 실제로 오는 나라들은 모두 남아야 한다.
      for (final iso in ['AR', 'BR', 'KR', 'US', 'ES', 'MX', 'PH', 'DE']) {
        expect(usable.contains(iso), isTrue, reason: iso);
      }
    });

    test('표가 통째로 비어 있지 않다', () {
      // 생성 스크립트가 빈 파일을 뱉어도 컴파일은 된다.
      expect(timezoneToCountry.length, greaterThan(300));
    });
  });

  group('CountryGuess', () {
    // 테스트 환경에는 시간대 플러그인이 없다 — 그 자리에서 실패하고
    // 기기 언어의 국가로 내려온다. 그 경로를 여기서 본다.
    test('시간대를 못 얻으면 기기 언어의 국가로 내려온다', () async {
      expect(await CountryGuess.guess(localeCountryCode: 'BR'), 'BR');
      expect(await CountryGuess.guess(localeCountryCode: 'br'), 'BR');
    });

    test('모르는 값이면 아무것도 짐작하지 않는다', () async {
      // 억지로 채우면 틀린 나라가 조용히 등록된다. 비워 두는 편이 낫다.
      for (final bad in [null, '', 'XX', 'BRA', '123']) {
        expect(
          await CountryGuess.guess(localeCountryCode: bad),
          isNull,
          reason: '$bad',
        );
      }
    });
  });
}
