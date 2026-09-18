import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  /// 이 사람에 대해 이미 아는 전화번호(068). 지난 등록이나 명함에서 온다.
  /// 등록 화면이 칸을 미리 채우는 데만 쓴다 — 본인이 고칠 수 있다.
  final String? knownPhone;
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
    this.knownPhone,
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
    String? knownPhone,
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
      knownPhone: knownPhone ?? this.knownPhone,
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

  // 플랫폼마다 구글이 요구하는 것이 다르다. 하나로 뭉뚱그리면 어딘가는 깨진다.
  //
  //   웹        clientId 를 주지 않는다 → web/index.html 의
  //             <meta name="google-signin-client_id"> 를 쓴다.
  //   iOS·macOS clientId 에 iOS/macOS 클라이언트 ID.
  //   안드로이드 clientId 를 주면 안 된다. 안드로이드는 코드가 아니라
  //             **패키지명 + 서명 SHA-1** 로 앱을 식별하며, 그 조합이 구글
  //             콘솔에 등록돼 있어야 한다. 대신 서버가 검증할 ID 토큰을 받으려면
  //             serverClientId 에 **웹** 클라이언트 ID 를 준다.
  //
  // 예전에는 웹이 아니면 무조건 iOS 클라이언트 ID 를 넘겼다. 안드로이드에서는
  // 그것이 sign_in_failed(ApiException: 10, DEVELOPER_ERROR)로 돌아온다.
  static final _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: switch (defaultTargetPlatform) {
      _ when kIsWeb => null,
      TargetPlatform.iOS || TargetPlatform.macOS =>
        AppConstants.googleClientId.isEmpty
            ? null
            : AppConstants.googleClientId,
      _ => null,
    },
    // 안드로이드에서만 의미가 있다. 이 값이 ID 토큰의 audience 가 되며,
    // 서버는 GOOGLE_CLIENT_ID(웹)로 그것을 검증한다.
    serverClientId: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? AppConstants.googleServerClientId
        : null,
  );

  // 부팅 검사가 안 끝날 때 손님으로 떨어뜨리기까지 기다리는 시간.
  //
  // ApiClient 에는 타임아웃이 없다. 그래서 이 시간을 정하는 것은 우리가 아니라
  // 밑에 깔린 것들이었다 — 응답 없는 서버를 세워 재어 보니 웹(브라우저가
  // 소켓을 끊어 줌)에서 40초와 70초 사이였다. 네이티브의 dart:io 는 응답
  // 대기에 기본 상한이 없어 더 오래 걸릴 수 있다.
  static const _bootTimeout = Duration(seconds: 10);

  // 앱 시작 시 저장된 JWT로 인증 복원
  //
  // **시간 안에 끝나야 한다.** 안 끝나는 동안 isLoading 이 true 로 남고,
  // app.dart 의 redirect 가 앱을 /loading 에 붙잡아 둔다. 그 화면에는 동그라미
  // 하나뿐이라 사용자가 할 수 있는 것이 없다.
  //
  // 시간이 지나면 TimeoutException 이 나고 아래 catch 가 손님으로 떨어뜨린다.
  // 기다리는 시간을 1분 남짓에서 10초로 줄이는 것이고, 그 끝에 나오는 것이
  // 흰 화면이 아니라 로그인 화면이 되게 하는 것이다. 토큰이 멀쩡한데 회선만
  // 느렸던 경우에는 다시 로그인하면 그대로 들어간다.
  Future<void> _init() async {
    try {
      final me = await ApiClient.getMe().timeout(_bootTimeout);
      if (me != null) {
        final role = _parseRole(me['role'] as String?);
        state = AuthState(
          userId: me['userId'] as String?,
          email: me['email'] as String?,
          name: me['name'] as String?,
          knownPhone: me['knownPhone'] as String?,
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

  // 로그아웃 — disconnect()로 계정 캐시까지 삭제해서 다른 계정으로 전환 가능
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    await ApiClient.clearToken();
    state = AuthState.guest;
  }

  // 리더 등록 완료 후 상태 갱신
  void setLeader(String leaderId) {
    final newRole = state.role == UserRole.participant
        ? UserRole.admin
        : state.role;
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
