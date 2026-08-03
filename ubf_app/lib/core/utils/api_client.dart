import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

// JWT + HTTP 기반 API 클라이언트
// 모든 요청에 Authorization: Bearer {token} 헤더 자동 추가
// macOS: keychain 엔타이틀먼트 불필요한 SharedPreferences 사용
// iOS/Android: 보안 키체인인 FlutterSecureStorage 사용
class ApiClient {
  static const _storage = FlutterSecureStorage();
  static String? _cachedToken;

  // ─── 토큰 관리 ────────────────────────────────────────────

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    if (kIsWeb || Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(AppConstants.jwtTokenKey);
    } else {
      _cachedToken = await _storage.read(key: AppConstants.jwtTokenKey);
    }
    return _cachedToken;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    if (kIsWeb || Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.jwtTokenKey, token);
    } else {
      await _storage.write(key: AppConstants.jwtTokenKey, value: token);
    }
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    if (kIsWeb || Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.jwtTokenKey);
    } else {
      await _storage.delete(key: AppConstants.jwtTokenKey);
    }
  }

  // ─── HTTP 헬퍼 ───────────────────────────────────────────

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path) => Uri.parse('${AppConstants.apiBaseUrl}$path');

  static Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        (body as Map<String, dynamic>)['error'] ?? '서버 오류',
      );
    }
    return body as Map<String, dynamic>;
  }

  static List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(response.statusCode, body['error'] ?? '서버 오류');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  // ─── API 메서드 ──────────────────────────────────────────

  // 구글 ID 토큰 → JWT 교환
  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await http.post(
      _uri('/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    final data = _decode(response);
    await saveToken(data['token'] as String);
    return data;
  }

  // 웹: idToken 이 없을 때 accessToken 으로 로그인 (서버가 tokeninfo 로 검증)
  static Future<Map<String, dynamic>> loginWithGoogleAccessToken(
    String accessToken,
  ) async {
    final response = await http.post(
      _uri('/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken}),
    );
    final data = _decode(response);
    await saveToken(data['token'] as String);
    return data;
  }

  static Future<Map<String, dynamic>> loginWithKakao(String accessToken) async {
    final response = await http.post(
      _uri('/auth/kakao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken}),
    );
    final data = _decode(response);
    await saveToken(data['token'] as String);
    return data;
  }

  // 내 정보 조회
  static Future<Map<String, dynamic>?> getMe() async {
    final response = await http.get(
      _uri('/auth/me'),
      headers: await _headers(),
    );
    if (response.statusCode == 401) return null;
    return _decode(response);
  }

  // 개발용 테스트 로그인 (OAuth 생략)
  static Future<Map<String, dynamic>> devLogin({
    String email = 'dev@test.com',
    String name = '테스트 사용자',
  }) async {
    final response = await http.post(
      _uri('/auth/dev-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'name': name}),
    );
    final data = _decode(response);
    await saveToken(data['token'] as String);
    return data;
  }

  // 프로필 저장 (이름 확정, 나이, 지역)
  static Future<void> updateProfile({
    required String name,
    required int age,
    required String region,
  }) async {
    final response = await http.patch(
      _uri('/auth/profile'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'age': age, 'region': region}),
    );
    _decode(response);
  }

  // ─── 프로그램 ────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProgram(String id) async {
    final response = await http.get(
      _uri('/programs/$id'),
      headers: await _headers(),
    );
    if (response.statusCode == 404) return null;
    return _decode(response);
  }

  static Future<List<dynamic>> getMyPrograms() async {
    final response = await http.get(
      _uri('/programs'),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  static Future<String> createProgram(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri('/programs'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 409) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw DuplicateProgramException(body['existingId'] as String);
    }
    return (_decode(response)['id'] as String);
  }

  static Future<void> updateProgram(
    String programId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      _uri('/programs/$programId'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    // 423 Locked: 시작일 이후 투어 옵션 수정 시도
    if (response.statusCode == 423) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(423, body['error'] as String? ?? '수정이 잠겨 있습니다');
    }
    _decode(response);
  }

  /// 수양회 삭제 (소유 리더만). 행을 지우지 않고 비활성화한다 —
  /// 등록·배정·배차 기록이 이 행을 참조한다.
  ///
  /// 등록자가 있으면 서버가 428 과 함께 이름 확인을 요구한다.
  /// [confirmName] 에 수양회 이름을 그대로 넣어 다시 호출한다.
  static Future<void> deleteProgram(
    String programId, {
    String? confirmName,
  }) async {
    final response = await http.delete(
      _uri('/programs/$programId'),
      headers: await _headers(),
      body: jsonEncode({'confirmName': confirmName}),
    );
    if (response.statusCode == 428) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ConfirmNameRequiredException(
        (body['registrationCount'] as num?)?.toInt() ?? 0,
        body['error'] as String? ?? '확인이 필요합니다',
      );
    }
    _decode(response);
  }

  // 할인 신청 판단 (리더 전용). 승인 금액은 여기서만 정해진다 —
  // 등록자가 보내는 저장 요청에는 금액도 상태도 담기지 않는다.
  static Future<void> decideDiscount(
    String programId,
    String registrationId, {
    required String status, // approved | rejected | requested
    num? amount,
    String? note,
  }) async {
    final response = await http.patch(
      _uri('/programs/$programId/registrations/$registrationId/discount'),
      headers: await _headers(),
      body: jsonEncode({'status': status, 'amount': amount, 'note': note}),
    );
    _decode(response);
  }

  static Future<Map<String, dynamic>?> getProgramStats(String programId) async {
    final response = await http.get(
      _uri('/programs/$programId/stats'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  // 준비 현황 (A003) — 준비 항목 + 국내/해외 코호트 + 막힌 사람을 한 번에
  static Future<Map<String, dynamic>?> getProgramReadiness(
    String programId,
  ) async {
    final response = await http.get(
      _uri('/programs/$programId/readiness'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  // ─── QR 나눔 (031) ───────────────────────────────────────

  static Future<Map<String, dynamic>> getMyCard() async {
    final r = await http.get(_uri('/cards/me'), headers: await _headers());
    return _decode(r);
  }

  static Future<void> saveMyCard(Map<String, dynamic> body) async {
    final r = await http.put(
      _uri('/cards/me'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _decode(r);
  }

  /// QR 을 새로 만든다. 예전 코드는 그 자리에서 무효가 된다.
  static Future<String> rotateShareToken() async {
    final r = await http.post(
      _uri('/cards/me/token'),
      headers: await _headers(),
    );
    return _decode(r)['shareToken'] as String;
  }

  /// 읽은 QR 의 명함을 미리 본다. 저장은 따로 눌러야 한다.
  static Future<Map<String, dynamic>> openCardByToken(String token) async {
    final r = await http.get(
      _uri('/cards/by-token/$token'),
      headers: await _headers(),
    );
    return _decode(r);
  }

  static Future<void> saveConnection({
    required String friendUserId,
    String? programId,
  }) async {
    final r = await http.post(
      _uri('/cards/connections'),
      headers: await _headers(),
      body: jsonEncode({'friendUserId': friendUserId, 'programId': ?programId}),
    );
    _decode(r);
  }

  static Future<List<dynamic>> getConnections() async {
    final r = await http.get(
      _uri('/cards/connections'),
      headers: await _headers(),
    );
    return _decodeList(r);
  }

  static Future<void> updateConnectionNote(String id, String? note) async {
    final r = await http.patch(
      _uri('/cards/connections/$id'),
      headers: await _headers(),
      body: jsonEncode({'note': note}),
    );
    _decode(r);
  }

  static Future<void> deleteConnection(String id) async {
    final r = await http.delete(
      _uri('/cards/connections/$id'),
      headers: await _headers(),
    );
    _decode(r);
  }

  /// 나를 저장한 사람들. 하나씩 끊을 수 있다.
  static Future<List<dynamic>> getSavedBy() async {
    final r = await http.get(
      _uri('/cards/saved-by'),
      headers: await _headers(),
    );
    return _decodeList(r);
  }

  static Future<void> revokeSavedBy(String id) async {
    final r = await http.delete(
      _uri('/cards/saved-by/$id'),
      headers: await _headers(),
    );
    _decode(r);
  }

  // ─── 파일 업로드 · 자료실 ────────────────────────────────

  /// 파일 한 개를 올리고 서버가 준 경로를 돌려준다.
  ///
  /// 바이트를 그대로 보낸다(application/octet-stream). base64 로 감싸면
  /// 33% 가 부풀어 교재 PDF 에서 손해가 크다.
  static Future<Map<String, dynamic>> uploadFile(
    List<int> bytes,
    String kind,
  ) async {
    final response = await http.post(
      _uri('/media?kind=$kind'),
      headers: {
        ...await _headers(),
        'Content-Type': 'application/octet-stream',
      },
      body: bytes,
    );
    return _decode(response);
  }

  /// 자료실 목록. 참가자는 공개된 것만, 담당자는 all=true 로 전부.
  static Future<List<dynamic>> getLibrary(
    String programId, {
    bool all = false,
  }) async {
    final response = await http.get(
      _uri('/library/$programId${all ? '/all' : ''}'),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  static Future<Map<String, dynamic>?> addLibraryItem(
    String programId,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      _uri('/library/$programId'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<void> updateLibraryItem(
    String programId,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      _uri('/library/$programId/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _decode(response);
  }

  static Future<void> deleteLibraryItem(String programId, String id) async {
    final response = await http.delete(
      _uri('/library/$programId/$id'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // 식사 제한 명단 — 준비 현황의 식사 카드를 열면 나온다.
  // { program, total, skips_breakfast, people[] }
  static Future<Map<String, dynamic>?> getProgramMeals(String programId) async {
    final response = await http.get(
      _uri('/programs/$programId/meals'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  static Future<List<dynamic>> getProgramRegistrations(String programId) async {
    final response = await http.get(
      _uri('/programs/$programId/registrations'),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  // ─── 등록 ────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getMyRegistration(
    String programId,
  ) async {
    final response = await http.get(
      _uri('/registrations/$programId/me'),
      headers: await _headers(),
    );
    if (response.statusCode == 404) return null;
    if (response.body.isEmpty || response.body == 'null') return null;
    return _decode(response);
  }

  static Future<void> saveRegistration(
    String programId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      _uri('/registrations/$programId/me'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  static Future<void> submitRegistration(String programId) async {
    final response = await http.post(
      _uri('/registrations/$programId/me/submit'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // ─── 리더 ────────────────────────────────────────────────

  /// 리더 등록. 지부는 "지부장이신가요?" 확인 화면이 찾아낸 값을 함께 보낸다 —
  /// 서버가 같은 대응표를 따로 들고 있으면 지부 목록이 바뀔 때 어긋난다(033).
  static Future<String> registerAsLeader(
    String name, {
    String? chapter,
    String? nationIso,
  }) async {
    final response = await http.post(
      _uri('/leaders/register'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'chapter': ?chapter,
        'nationIso': ?nationIso,
      }),
    );
    final data = _decode(response);
    // 리더 권한이 포함된 새 JWT 저장
    await saveToken(data['token'] as String);
    return data['leaderId'] as String;
  }

  /// 이미 리더인 사람의 지부를 채운다(033 이전에 등록한 사람).
  /// 실패해도 조용히 넘긴다 — 알림은 부가 기능이고, 여기서 막히면
  /// 로그인 직후 화면이 서지 않는다.
  static Future<void> updateLeaderChapter({
    required String chapter,
    required String nationIso,
  }) async {
    try {
      await http.patch(
        _uri('/leaders/me/chapter'),
        headers: await _headers(),
        body: jsonEncode({'chapter': chapter, 'nationIso': nationIso}),
      );
    } catch (_) {}
  }

  /// 우리 지부 지부장이 만든 수양회. 서버가 내 등록서를 보고 판단한다 —
  /// 앱이 "내 지부는 이것" 이라고 보내오게 하면 아무 지부나 적어 남의
  /// 수양회 UUID 를 받아 갈 수 있다.
  static Future<List<dynamic>> getChapterPrograms() async {
    final response = await http.get(
      _uri('/programs/for-my-chapter'),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  // ─── 입금 ────────────────────────────────────────────────

  static Future<void> registerPayment(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri('/payments'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  static Future<void> confirmPayment(String paymentId, {String? note}) async {
    final response = await http.patch(
      _uri('/payments/$paymentId/confirm'),
      headers: await _headers(),
      body: jsonEncode({'note': note}),
    );
    _decode(response);
  }

  static Future<void> rejectPayment(String paymentId, {String? note}) async {
    final response = await http.patch(
      _uri('/payments/$paymentId/reject'),
      headers: await _headers(),
      body: jsonEncode({'note': note}),
    );
    _decode(response);
  }

  // ─── 일정 ────────────────────────────────────────────────

  static Future<List<dynamic>> getSchedules(String programId) async {
    final response = await http.get(
      _uri('/schedules/$programId'),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  static Future<Map<String, dynamic>> createSchedule(
    String programId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri('/schedules/$programId'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(response);
  }

  static Future<void> updateSchedule(
    String programId,
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      _uri('/schedules/$programId/$scheduleId'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  static Future<void> deleteSchedule(
    String programId,
    String scheduleId,
  ) async {
    final response = await http.delete(
      _uri('/schedules/$programId/$scheduleId'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // ─── SOS ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> sendSos({
    required String programId,
    required String situationType,
    double? latitude,
    double? longitude,
    String? message,
    String? realName,
  }) async {
    final response = await http.post(
      _uri('/sos'),
      headers: await _headers(),
      body: jsonEncode({
        'programId': programId,
        'situationType': situationType,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'message': ?message,
        'realName': ?realName,
      }),
    );
    return _decode(response);
  }

  static Future<List<dynamic>> getSosAlerts(String programId) async {
    final response = await http.get(
      _uri('/sos/$programId'),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  static Future<void> resolveSos(String alertId) async {
    final response = await http.patch(
      _uri('/sos/$alertId/resolve'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // ─── 편성 준비: 숙소(rooms) ───────────────────────────────

  // { rooms: [...], summary: {...} }
  static Future<Map<String, dynamic>> getRooms(String programId) async {
    final response = await http.get(
      _uri('/rooms/$programId'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  static Future<void> createRoom(
    String programId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri('/rooms/$programId'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  // 일괄 생성: { namePattern, startNumber, count, floor, roomType, capacity, gender }
  static Future<int> bulkCreateRooms(
    String programId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri('/rooms/$programId/bulk'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return (_decode(response)['created'] as num).toInt();
  }

  static Future<void> updateRoom(
    String programId,
    String roomId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      _uri('/rooms/$programId/$roomId'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  static Future<void> deleteRoom(String programId, String roomId) async {
    final response = await http.delete(
      _uri('/rooms/$programId/$roomId'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // ─── 편성 준비: 말씀조(groups) ────────────────────────────

  // { groups: [...], summary: {...} }
  static Future<Map<String, dynamic>> getGroups(String programId) async {
    final response = await http.get(
      _uri('/groups/$programId'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  static Future<void> createGroup(
    String programId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri('/groups/$programId'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  // 조 일괄 생성: { count, namePattern? }
  static Future<int> generateGroups(
    String programId,
    int count, {
    String? namePattern,
  }) async {
    final response = await http.post(
      _uri('/groups/$programId/generate'),
      headers: await _headers(),
      body: jsonEncode({'count': count, 'namePattern': ?namePattern}),
    );
    return (_decode(response)['created'] as num).toInt();
  }

  static Future<void> updateGroup(
    String programId,
    String groupId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      _uri('/groups/$programId/$groupId'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  static Future<void> deleteGroup(String programId, String groupId) async {
    final response = await http.delete(
      _uri('/groups/$programId/$groupId'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // ─── 지목(buddy requests) ─────────────────────────────────

  // 지목 후보(나 제외 등록자)
  static Future<List<dynamic>> getBuddyCandidates(String programId) async {
    final response = await http.get(
      _uri('/buddy-requests/$programId/candidates'),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  // { sent: [...], received: [...] }
  static Future<Map<String, dynamic>> getMyBuddyRequests(
    String programId,
  ) async {
    final response = await http.get(
      _uri('/buddy-requests/$programId/me'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  // kind: 'roommate' | 'group'
  // relation: 'peer' | 'family'
  //   성별이 다른 사람에게 룸메이트를 요청하려면 'family' 여야 한다(022).
  //   서버는 상대의 수락이 있어야만 실제로 같은 방에 넣는다.
  static Future<void> sendBuddyRequest(
    String programId,
    String toRegistrationId,
    String kind, {
    String relation = 'peer',
  }) async {
    final response = await http.post(
      _uri('/buddy-requests/$programId'),
      headers: await _headers(),
      body: jsonEncode({
        'toRegistrationId': toRegistrationId,
        'kind': kind,
        'relation': relation,
      }),
    );
    _decode(response);
  }

  // action: 'accept' | 'decline'
  static Future<void> respondBuddyRequest(
    String programId,
    String requestId,
    String action,
  ) async {
    final response = await http.patch(
      _uri('/buddy-requests/$programId/$requestId/$action'),
      headers: await _headers(),
    );
    _decode(response);
  }

  static Future<void> cancelBuddyRequest(
    String programId,
    String requestId,
  ) async {
    final response = await http.delete(
      _uri('/buddy-requests/$programId/$requestId'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // ─── 동반자(companions) ───────────────────────────────────

  static Future<List<dynamic>> getMyCompanions(String programId) async {
    final response = await http.get(
      _uri('/companions/$programId/me'),
      headers: await _headers(),
    );
    return _decodeList(response);
  }

  // companions: 각 항목 { realName, bibleName, gender, age, language, branch,
  //                       sameFlightAsPrimary, arrivalFlight, departureFlight, needsPickup }
  static Future<void> saveMyCompanions(
    String programId,
    List<Map<String, dynamic>> companions,
  ) async {
    final response = await http.put(
      _uri('/companions/$programId/me'),
      headers: await _headers(),
      body: jsonEncode({'companions': companions}),
    );
    _decode(response);
  }

  // ─── 배정(assignments) — 관리자 ───────────────────────────

  // { rooms: [...], unassigned: [...] }
  static Future<Map<String, dynamic>> getRoomAssignments(
    String programId,
  ) async {
    final response = await http.get(
      _uri('/assignments/$programId/rooms'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  // { groups: [...], unassigned: [...] }
  static Future<Map<String, dynamic>> getGroupAssignments(
    String programId,
  ) async {
    final response = await http.get(
      _uri('/assignments/$programId/groups'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  // { assigned, unplaced: [...] }
  static Future<Map<String, dynamic>> autoAssignRooms(String programId) async {
    final response = await http.post(
      _uri('/assignments/$programId/rooms/auto'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  // { assigned }
  static Future<Map<String, dynamic>> autoAssignGroups(String programId) async {
    final response = await http.post(
      _uri('/assignments/$programId/groups/auto'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  static Future<void> assignToRoom(
    String programId,
    String roomId,
    String registrationId,
  ) async {
    final response = await http.post(
      _uri('/assignments/$programId/rooms/assign'),
      headers: await _headers(),
      body: jsonEncode({'roomId': roomId, 'registrationId': registrationId}),
    );
    _decode(response);
  }

  static Future<void> unassignFromRoom(
    String programId,
    String registrationId,
  ) async {
    final response = await http.delete(
      _uri('/assignments/$programId/rooms/$registrationId'),
      headers: await _headers(),
    );
    _decode(response);
  }

  static Future<void> assignToGroup(
    String programId,
    String groupId,
    String registrationId,
  ) async {
    final response = await http.post(
      _uri('/assignments/$programId/groups/assign'),
      headers: await _headers(),
      body: jsonEncode({'groupId': groupId, 'registrationId': registrationId}),
    );
    _decode(response);
  }

  static Future<void> unassignFromGroup(
    String programId,
    String registrationId,
  ) async {
    final response = await http.delete(
      _uri('/assignments/$programId/groups/$registrationId'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // ─── 운행 배차(transport) — F5 ────────────────────────────

  // { direction, runs: [...], unassigned: [...] }
  static Future<Map<String, dynamic>> getTransportRuns(
    String programId,
    String direction,
  ) async {
    final response = await http.get(
      _uri('/transport/$programId/runs?direction=$direction'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  static Future<String> createRun(
    String programId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      _uri('/transport/$programId/runs'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(response)['id'] as String;
  }

  static Future<void> updateRun(
    String programId,
    String runId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      _uri('/transport/$programId/runs/$runId'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    _decode(response);
  }

  static Future<void> deleteRun(String programId, String runId) async {
    final response = await http.delete(
      _uri('/transport/$programId/runs/$runId'),
      headers: await _headers(),
    );
    _decode(response);
  }

  // { assigned, unassigned }
  static Future<Map<String, dynamic>> autoDispatch(
    String programId,
    String direction,
  ) async {
    final response = await http.post(
      _uri('/transport/$programId/runs/auto?direction=$direction'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  static Future<void> assignToRun(
    String programId,
    String runId, {
    String? registrationId,
    String? companionId,
  }) async {
    final response = await http.post(
      _uri('/transport/$programId/runs/$runId/assign'),
      headers: await _headers(),
      body: jsonEncode({
        'registrationId': ?registrationId,
        'companionId': ?companionId,
      }),
    );
    _decode(response);
  }

  static Future<void> unassignFromRun(
    String programId,
    String runId, {
    String? registrationId,
    String? companionId,
  }) async {
    final response = await http.delete(
      _uri('/transport/$programId/runs/$runId/pax'),
      headers: await _headers(),
      body: jsonEncode({
        'registrationId': ?registrationId,
        'companionId': ?companionId,
      }),
    );
    _decode(response);
  }

  // { needsPickup, arrival, departure }
  static Future<Map<String, dynamic>> getMyTransport(String programId) async {
    final response = await http.get(
      _uri('/transport/$programId/my-transport'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  static Future<void> setMyPickup(String programId, bool needsPickup) async {
    final response = await http.patch(
      _uri('/transport/$programId/my-pickup'),
      headers: await _headers(),
      body: jsonEncode({'needsPickup': needsPickup}),
    );
    _decode(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// 서버 409: 같은 이름+시작일의 프로그램이 이미 존재
/// 등록자가 있는 수양회를 지우려 할 때. 이름을 그대로 입력해야 진행된다.
class ConfirmNameRequiredException implements Exception {
  final int registrationCount;
  final String message;
  ConfirmNameRequiredException(this.registrationCount, this.message);
  @override
  String toString() => message;
}

class DuplicateProgramException implements Exception {
  final String existingId;
  const DuplicateProgramException(this.existingId);

  @override
  String toString() => 'DuplicateProgramException: existingId=$existingId';
}
