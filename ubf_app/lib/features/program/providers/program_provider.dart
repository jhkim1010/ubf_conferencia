import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// 단일 프로그램 (UUID로 조회)
final programByIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
      (_, programId) => ApiClient.getProgram(programId),
    );

// 리더의 프로그램 목록
final leaderProgramsProvider = FutureProvider<List<dynamic>>(
  (_) => ApiClient.getMyPrograms(),
);

// 대시보드 통계
final programStatsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
      (_, programId) => ApiClient.getProgramStats(programId),
    );

// 준비 현황 (A003) — 준비 항목 + 국내/해외 코호트 + 막힌 사람
final programReadinessProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
      (_, programId) => ApiClient.getProgramReadiness(programId),
    );

// 식사 제한 명단 — 준비 현황의 식사 카드를 두 번 누르면 열린다
// 투어별 신청 상황. 대시보드의 "등록 완료" 카드를 대신한다.
final programTourSignupsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
      (_, programId) => ApiClient.getTourSignups(programId),
    );

final programMealsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
      (_, programId) => ApiClient.getProgramMeals(programId),
    );

// 우리 지부 지부장이 만든 수양회(033). 한 번이라도 등록한 적이 있어야
// 나라·지부를 알 수 있다 — 처음 오는 사람에게는 빈 목록이 온다.
final chapterProgramsProvider = FutureProvider<List<dynamic>>(
  (_) => ApiClient.getChapterPrograms(),
);

// 참가자 전체 목록
final programRegistrationsProvider =
    FutureProvider.family<List<dynamic>, String>(
      (_, programId) => ApiClient.getProgramRegistrations(programId),
    );

// 프로그램 서비스
class ProgramService {
  // 새 프로그램 생성
  static Future<String> createProgram({
    required String name,
    required String location,
    required String programType,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, bool>? enabledSections,
    List<Map<String, dynamic>>? options,
    String? nearestAirport,
    String? contact1Name,
    String? contact1Phone,
    String? contact2Name,
    String? contact2Phone,
    String? hostCountry,
    num? feeBasic,
    num? feePremium,
    String? feeBasicDesc,
    String? feePremiumDesc,
    List<Map<String, dynamic>>? discountOptions,
    String? currency,
    String? smallCohortPolicy,
    int? minTeamSize,
    List<Map<String, dynamic>>? hotelOptions,
    String? telegramBotToken,
    String? telegramChatId,
  }) async {
    return ApiClient.createProgram({
      'name': name,
      'location': location,
      'programType': programType,
      'startDate': startDate?.toIso8601String().split('T').first,
      'endDate': endDate?.toIso8601String().split('T').first,
      'enabledSections': enabledSections,
      'options': options,
      if (hostCountry != null && hostCountry.isNotEmpty)
        'hostCountry': hostCountry,
      if (nearestAirport != null && nearestAirport.isNotEmpty)
        'nearestAirport': nearestAirport,
      if (contact1Name != null && contact1Name.isNotEmpty)
        'contact1Name': contact1Name,
      if (contact1Phone != null && contact1Phone.isNotEmpty)
        'contact1Phone': contact1Phone,
      if (contact2Name != null && contact2Name.isNotEmpty)
        'contact2Name': contact2Name,
      if (contact2Phone != null && contact2Phone.isNotEmpty)
        'contact2Phone': contact2Phone,
      // 참가비는 null 도 의미가 있다("그 등급을 제공하지 않는다"). 다른 필드처럼
      // 비었을 때 키를 빼면 서버가 값을 지울 방법이 없어진다.
      'feeBasic': feeBasic,
      'feePremium': feePremium,
      'feeBasicDesc': feeBasicDesc,
      'feePremiumDesc': feePremiumDesc,
      'discountOptions': discountOptions ?? const [],
      'currency': currency ?? 'USD',
      'smallCohortPolicy': smallCohortPolicy ?? 'keep',
      'minTeamSize': minTeamSize ?? 5,
      'hotelOptions': hotelOptions ?? const [],
      // 빈 값은 보내지 않는다. 서버에서 '' 는 "지운다"는 뜻이라, 새로 만들 때
      // 굳이 보내면 의미 없는 지우기 요청이 된다.
      if (telegramBotToken != null && telegramBotToken.isNotEmpty)
        'telegramBotToken': telegramBotToken,
      if (telegramChatId != null && telegramChatId.isNotEmpty)
        'telegramChatId': telegramChatId,
    });
  }

  // UUID 유효성 확인
  static Future<bool> validateProgramId(String programId) async {
    final program = await ApiClient.getProgram(programId);
    return program != null;
  }
}

// 이 수양회를 관리할 사람. 만든 사람도 함께 온다(is_owner).
final programAdminsProvider = FutureProvider.family<List<dynamic>, String>(
  (_, programId) => ApiClient.getProgramAdmins(programId),
);
