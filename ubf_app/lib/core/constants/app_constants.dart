// 앱 전역 상수 정의
class AppConstants {
  // Node.js API 서버 주소
  // 개발: http://localhost:3000
  // 배포: https://your-api-domain.com
  static const String apiBaseUrl = 'http://localhost:3000';

  // AviationStack API
  // TODO: https://aviationstack.com 에서 무료 API 키 발급
  static const String aviationStackApiKey = 'YOUR_AVIATION_STACK_KEY';
  static const String aviationStackBaseUrl = 'http://api.aviationstack.com/v1';

  // Google OAuth Client ID (macOS/iOS 전용 — Google Cloud Console에서 발급)
  // APIs & Services → Credentials → OAuth 2.0 Client IDs → macOS/iOS 항목
  static const String googleClientId = '479734237683-vbeo3u1k79gfabok29fvmaqnka8rtohh.apps.googleusercontent.com';

  // 카카오 네이티브 앱 키 (https://developers.kakao.com → 내 애플리케이션)
  static const String kakaoAppKey = '';   // TODO: 카카오 개발자 콘솔에서 발급

  // 앱 정보
  static const String appName = 'Mana';
  static const String appVersion = '1.0.0';

  // 로컬 저장소 키
  static const String jwtTokenKey = 'ubf_jwt_token';
  static const String recentProgramsKey = 'ubf_recent_programs'; // 최근 참가 UUID 목록
}
