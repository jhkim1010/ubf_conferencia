import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// 단일 프로그램 (UUID로 조회)
final programByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (_, programId) => ApiClient.getProgram(programId),
);

// 리더의 프로그램 목록
final leaderProgramsProvider = FutureProvider<List<dynamic>>(
  (_) => ApiClient.getMyPrograms(),
);

// 대시보드 통계
final programStatsProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (_, programId) => ApiClient.getProgramStats(programId),
);

// 참가자 전체 목록
final programRegistrationsProvider = FutureProvider.family<List<dynamic>, String>(
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
  }) async {
    return ApiClient.createProgram({
      'name': name,
      'location': location,
      'programType': programType,
      'startDate': startDate?.toIso8601String().split('T').first,
      'endDate': endDate?.toIso8601String().split('T').first,
      'enabledSections': enabledSections,
      'options': options,
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
    });
  }

  // UUID 유효성 확인
  static Future<bool> validateProgramId(String programId) async {
    final program = await ApiClient.getProgram(programId);
    return program != null;
  }
}
