/// 장소 홈페이지 (065)
///
/// 담당자가 손으로 적는 칸이다. 그러니 무엇이든 들어올 수 있고, **열 수 있는
/// 것만 열어야 한다.**
///
///   - `http` · `https` 만 연다. 다른 갈래(`javascript:`, `file:`, `tel:` 등)를
///     열어 주면 링크 자리에 아무 문자열이나 넣을 수 있게 되고, 눌렀을 때
///     무슨 일이 나는지 우리가 보증할 수 없다.
///   - 비었거나 못 읽으면 **링크가 아니다.** 화면은 밑줄도 화살표도 그리지
///     않는다 — 누를 것이 없는데 누를 수 있어 보이면 안 된다.
///
/// 보여줄 때는 주소 전체가 아니라 도메인만 적는다. 누르기 전에 어디로 가는지
/// 알 수 있어야 하고, 긴 주소를 통째로 적으면 장소 이름을 가린다.
///
/// DB 도 HTTP 도 쓰지 않는다. test/venue_link_test.dart 로 그대로 확인한다.
library;

class VenueLink {
  const VenueLink._(this.uri, this.host);

  final Uri uri;

  /// 화면에 작게 적을 도메인. `www.` 는 뗀다 — 자리만 먹고 알려 주는 것이 없다.
  final String host;

  /// 열 수 있는 주소면 [VenueLink], 아니면 null.
  ///
  /// 앞뒤 공백은 담당자가 붙여넣다 흔히 남기므로 먼저 턴다. 공백만 있는 칸은
  /// 안 적은 것과 같다.
  static VenueLink? parse(Object? raw) {
    final s = '${raw ?? ''}'.trim();
    if (s.isEmpty) return null;

    final uri = Uri.tryParse(s);
    if (uri == null) return null;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;

    // 갈래만 맞고 호스트가 없는 것(`https://`)은 열어도 아무 데도 안 간다.
    final host = uri.host;
    if (host.isEmpty) return null;

    final shown = host.toLowerCase().startsWith('www.')
        ? host.substring(4)
        : host;
    return VenueLink._(uri, shown);
  }
}
