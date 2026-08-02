// 초대 링크 — 수양회 UUID 를 주소에 실어 보낸다.
//
//   https://ubf.coolsistema.com/?program=6f0c…            (권장)
//   https://ubf.coolsistema.com/registration/6f0c…        (직접 진입)
//
// UUID 를 손으로 옮겨 적게 하면 반드시 틀린다 — 36자에 하이픈이 섞여 있고,
// 카카오톡·메일로 오면 줄바꿈이 끼어든다. 실제로 "등록이 안 된다"는 문의는
// 대개 한 글자가 빠진 UUID 다. 링크를 누르면 그 수양회로 바로 들어간다.
//
// 링크는 로그인·프로필 입력을 거치는 동안 **살아남아야 한다.** 처음 오는
// 사람은 반드시 그 두 화면을 지나가는데, 거기서 목적지를 잊어버리면 결국
// UUID 를 다시 물어보게 된다.

/// 주소에서 UUID 를 꺼낸다. 못 꺼내면 null.
///
/// 받는 이름을 하나로 고집하지 않는다 — 안내문을 쓰는 사람마다 `program`,
/// `uuid`, `id` 를 섞어 쓴다. 링크가 안 먹는 것보다 몇 개 더 받는 편이 낫다.
String? programIdFromQuery(Map<String, String> query) {
  for (final key in const ['program', 'uuid', 'id', 'p']) {
    final v = query[key]?.trim();
    if (v != null && isProgramUuid(v)) return v.toLowerCase();
  }
  return null;
}

/// UUID 모양인지. 서버에 물어보기 전에 형식만 본다.
///
/// 검사하지 않으면 `?program=<script>` 같은 값이 그대로 경로에 붙는다.
/// 존재하는 수양회인지는 등록 화면이 서버에 물어 판단한다.
final _uuidRe = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isProgramUuid(String v) => _uuidRe.hasMatch(v.trim());

/// 참가자에게 보낼 초대 링크.
///
/// 웹 주소는 앱 안에서 알 방법이 없으므로 배포 주소를 상수로 둔다.
/// 도메인을 옮기면 여기를 함께 고쳐야 한다.
const String webBaseUrl = 'https://ubf.coolsistema.com';

String joinLinkFor(String programId) => '$webBaseUrl/?program=$programId';

/// 로그인·프로필 입력을 지나는 동안 목적지를 들고 있는 자리.
///
/// Riverpod 프로바이더가 아니라 평범한 전역이다. GoRouter 의 redirect 는
/// 빌드 도중에 불리므로 그 안에서 프로바이더 상태를 쓰면 안 된다.
/// 값은 한 번 쓰이고 즉시 비워진다 — 남겨 두면 나중에 홈으로 가려 할 때마다
/// 등록 화면으로 끌려간다.
class PendingJoin {
  static String? _programId;

  static void remember(String programId) => _programId = programId;

  /// 꺼내면서 지운다.
  static String? take() {
    final v = _programId;
    _programId = null;
    return v;
  }

  static bool get isPending => _programId != null;
}
