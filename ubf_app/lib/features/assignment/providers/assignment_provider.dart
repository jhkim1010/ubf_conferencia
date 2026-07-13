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
