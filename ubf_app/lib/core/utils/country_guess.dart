import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../constants/timezone_country.dart';
import '../constants/world_countries.dart';

// 참가자가 어느 나라에서 오는지 **짐작해서 기본으로 골라 둔다.**
//
// 국가 목록은 200개가 넘고 대륙까지 먼저 고르게 돼 있어서, 백지에서 찾는 데
// 시간이 걸리고 엉뚱한 나라를 고르기도 쉽다. 대부분은 지금 있는 나라에서
// 오므로 그것을 먼저 채워 두면 대개 그대로 맞다.
//
// **어디까지나 기본값이다.** 틀릴 수 있으므로 반드시 바꿀 수 있어야 하고,
// 이미 골라 둔 값이 있으면 절대 덮어쓰지 않는다 — 짐작이 사람이 정한 것을
// 이기면 안 된다.
//
// 신호는 **시간대**를 쓴다. 위치에서 나온 값이면서 권한을 묻지 않고,
// 웹·데스크톱에서도 얻을 수 있다. GPS 권한을 지도도 아닌 드롭다운 하나
// 채우려고 묻는 것은 과하다.
//
// 앱 언어로 짐작하지 않는다. 이 수양회 참가자 중에는 아르헨티나에 사는
// 한국인 선교사가 흔한데, 그 사람의 폰은 한국어다 — 언어로 보면 전부 한국이
// 된다. 언어는 시간대를 못 얻었을 때의 마지막 수단으로만 쓴다.
class CountryGuess {
  const CountryGuess._();

  /// 짐작한 ISO 코드. 못 짐작하면 null.
  ///
  /// [localeCountryCode] 는 마지막 수단이다 — 보통
  /// `WidgetsBinding.instance.platformDispatcher.locale.countryCode` 를 넘긴다.
  static Future<String?> guess({String? localeCountryCode}) async {
    final byZone = await _fromTimezone();
    if (byZone != null) return byZone;

    final loc = localeCountryCode?.trim().toUpperCase();
    if (loc != null && loc.length == 2 && WorldCountries.isKnown(loc)) {
      return loc;
    }
    return null;
  }

  /// 위젯에서 부르기 쉬운 형태. 기기 언어의 국가를 마지막 수단으로 쓴다.
  static Future<String?> guessFor(BuildContext context) {
    final code = Localizations.localeOf(context).countryCode;
    return guess(localeCountryCode: code);
  }

  static Future<String?> _fromTimezone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      final iso = timezoneToCountry[zone.toString()];
      // 표에 없는 시간대가 있다(새로 생기거나 별칭). 그때는 조용히 포기한다 —
      // 틀린 나라를 넣는 것보다 비워 두는 편이 낫다.
      if (iso != null && WorldCountries.isKnown(iso)) return iso;
    } catch (_) {
      // 시간대를 못 읽는 환경이 있다(테스트·일부 웹 브라우저).
      // 짐작은 편의 기능이므로 실패해도 화면은 그대로 동작해야 한다.
    }
    return null;
  }
}
