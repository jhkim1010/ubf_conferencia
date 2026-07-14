import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/api_client.dart';

// 사용자 역할 (서버와 일치)
enum UserRole { director, admin, participant }

UserRole _parseRole(String? raw) {
  switch (raw) {
    case 'director':
      return UserRole.director;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.participant;
  }
}

// 현재 로그인 상태 (JWT 페이로드)
class AuthState {
  final String? userId;
  final String? email;
  final String? name;
  final UserRole role;
  final bool isLeader;
  final String? leaderId;
  final bool isLoading;
  final bool profileCompleted;
  final String? country; // 거주 국가 (users.region) — 항공편 자동 생략 판단용

  const AuthState({
    this.userId,
    this.email,
    this.name,
    this.role = UserRole.participant,
    this.isLeader = false,
    this.leaderId,
    this.isLoading = true,
    this.profileCompleted = false,
    this.country,
  });

  bool get isLoggedIn => userId != null;
  bool get isDirector => role == UserRole.director;
  bool get isAdmin => role == UserRole.admin || role == UserRole.director;

  AuthState copyWith({
    String? userId,
    String? email,
    String? name,
    UserRole? role,
    bool? isLeader,
    String? leaderId,
    bool? isLoading,
    bool? profileCompleted,
    String? country,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isLeader: isLeader ?? this.isLeader,
      leaderId: leaderId ?? this.leaderId,
      isLoading: isLoading ?? this.isLoading,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      country: country ?? this.country,
    );
  }

  static const guest = AuthState(isLoading: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // 웹: null → web/index.html 의 <meta name="google-signin-client_id"> 를 사용
    //      (웹은 반드시 "웹 애플리케이션" 타입 클라이언트 ID + 승인된 JS 원본 필요)
    // 네이티브(macOS/iOS): app_constants 의 iOS/macOS 클라이언트 ID 사용
    clientId: kIsWeb || AppConstants.googleClientId.isEmpty
        ? null
        : AppConstants.googleClientId,
  );

  // 앱 시작 시 저장된 JWT로 인증 복원
  Future<void> _init() async {
    try {
      final me = await ApiClient.getMe();
      if (me != null) {
        final role = _parseRole(me['role'] as String?);
        state = AuthState(
          userId: me['userId'] as String?,
          email: me['email'] as String?,
          name: me['name'] as String?,
          role: role,
          isLeader: me['isLeader'] as bool? ?? (role != UserRole.participant),
          leaderId: me['leaderId'] as String?,
          isLoading: false,
          profileCompleted: me['profileCompleted'] as bool? ?? false,
          country: me['region'] as String?,
        );
      } else {
        state = AuthState.guest;
      }
    } catch (_) {
      state = AuthState.guest;
    }
  }

  // 구글 로그인
  Future<void> signInWithGoogle() async {
    debugPrint('[AUTH] 1. signIn() 호출 시작');
    debugPrint('[AUTH] clientId: ${AppConstants.googleClientId}');

    final googleUser = await _googleSignIn.signIn();
    debugPrint('[AUTH] 2. signIn() 결과: ${googleUser?.email ?? "null (취소됨)"}');
    if (googleUser == null) return;

    debugPrint('[AUTH] 3. authentication 요청 중...');
    final googleAuth = await googleUser.authentication;
    debugPrint('[AUTH] 4. idToken 존재: ${googleAuth.idToken != null}');
    debugPrint('[AUTH] 4. accessToken 존재: ${googleAuth.accessToken != null}');

    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    debugPrint('[AUTH] 5. 서버 API 호출: ${AppConstants.apiBaseUrl}/auth/google');
    final Map<String, dynamic> data;
    if (idToken != null) {
      // 네이티브: ID 토큰 사용
      data = await ApiClient.loginWithGoogle(idToken);
    } else if (accessToken != null) {
      // 웹: idToken 이 없으므로 accessToken 사용
      data = await ApiClient.loginWithGoogleAccessToken(accessToken);
    } else {
      throw Exception('Google 토큰을 가져올 수 없습니다');
    }
    debugPrint('[AUTH] 6. 서버 응답: $data');

    final userMap = data['user'] as Map<String, dynamic>;
    debugPrint('[AUTH] 7. 완료! userId: ${userMap['id']}');
    // DB에서 profileCompleted 등 전체 프로필 로드
    await _init();
  }

  // 개발용 테스트 로그인 (kDebugMode 전용)
  Future<void> signInDev() async {
    await ApiClient.devLogin();
    await _init();
  }

  // 카카오 로그인
  Future<void> signInWithKakao() async {
    // 카카오톡 앱이 설치된 경우 앱으로, 없으면 웹으로 로그인
    final token = await isKakaoTalkInstalled()
        ? await UserApi.instance.loginWithKakaoTalk()
        : await UserApi.instance.loginWithKakaoAccount();

    final data = await ApiClient.loginWithKakao(token.accessToken);
    final userMap = data['user'] as Map<String, dynamic>;
    final role = _parseRole(userMap['role'] as String?);

    state = AuthState(
      userId: userMap['id'] as String?,
      email: userMap['email'] as String?,
      name: userMap['name'] as String?,
      role: role,
      isLeader: data['isLeader'] as bool? ?? (role != UserRole.participant),
      leaderId: null,
      isLoading: false,
    );
  }

  // 로그아웃 — disconnect()로 계정 캐시까지 삭제해서 다른 계정으로 전환 가능
  Future<void> signOut() async {
    try { await _googleSignIn.disconnect(); } catch (_) {}
    if (AppConstants.kakaoAppKey.isNotEmpty) {
      try { await UserApi.instance.logout(); } catch (_) {}
    }
    await ApiClient.clearToken();
    state = AuthState.guest;
  }

  // 리더 등록 완료 후 상태 갱신
  void setLeader(String leaderId) {
    final newRole = state.role == UserRole.participant ? UserRole.admin : state.role;
    state = state.copyWith(isLeader: true, leaderId: leaderId, role: newRole);
  }

  // 프로필 입력 완료 후 상태 갱신
  void markProfileCompleted({required String name}) {
    state = state.copyWith(name: name, profileCompleted: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);

// 편의 프로바이더
final isLeaderProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLeader;
});

final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authProvider).role;
});

final currentUserProvider = Provider<AuthState>((ref) {
  return ref.watch(authProvider);
});
