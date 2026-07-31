// 앱 전역 상수 정의
class AppConstants {
  // Node.js API 서버 주소.
  //
  // 빌드 시점에 주입한다. 상수로 박아두면 배포 빌드가 localhost 를 호출해
  // 아무것도 동작하지 않는다.
  //
  //   개발  flutter run                                   (기본값 사용)
  //   배포  flutter build web --dart-define=API_BASE_URL=https://ubf.coolsistema.com/api
  //
  // 같은 도메인에 웹과 API 를 함께 올리면 상대 경로(/api)로 두는 것이 낫다 —
  // CORS 가 필요 없고 origin 이 하나라 구글 OAuth 설정도 단순해진다.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // AviationStack API
  // TODO: https://aviationstack.com 에서 무료 API 키 발급
  static const String aviationStackApiKey = 'YOUR_AVIATION_STACK_KEY';
  static const String aviationStackBaseUrl = 'http://api.aviationstack.com/v1';

  // Google OAuth Client ID (macOS/iOS 전용 — Google Cloud Console에서 발급)
  // APIs & Services → Credentials → OAuth 2.0 Client IDs → macOS/iOS 항목
  static const String googleClientId =
      '479734237683-vbeo3u1k79gfabok29fvmaqnka8rtohh.apps.googleusercontent.com';

  // 카카오 네이티브 앱 키 (https://developers.kakao.com → 내 애플리케이션)
  static const String kakaoAppKey = ''; // TODO: 카카오 개발자 콘솔에서 발급

  // 앱 정보
  static const String appName = 'Mana';
  static const String appVersion = '1.0.0';

  // 로컬 저장소 키
  static const String jwtTokenKey = 'ubf_jwt_token';
  static const String recentProgramsKey =
      'ubf_recent_programs'; // 최근 참가 UUID 목록
}
