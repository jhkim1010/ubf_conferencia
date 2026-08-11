import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// 숙소 배정 현황 { rooms, unassigned }
final roomAssignmentsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
      (_, programId) => ApiClient.getRoomAssignments(programId),
    );

// 말씀조 배정 현황 { groups, unassigned }
final groupAssignmentsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
      (_, programId) => ApiClient.getGroupAssignments(programId),
    );

// 봉사 담당자 배정 현황 (039). 역할별로 사람과 부족 인원이 함께 온다.
final serviceBoardProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
      (_, programId) => ApiClient.getServiceBoard(programId),
    );

// 나에게 온 봉사 부탁 (참가자 쪽).
final myServiceInvitesProvider = FutureProvider.family<List<dynamic>, String>(
  (_, programId) => ApiClient.getMyServiceInvites(programId),
);
