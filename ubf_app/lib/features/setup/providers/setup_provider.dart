import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// 편성 준비: 숙소 목록 + 정원 대조 요약
// 반환: { rooms: [...], summary: {...} }
final roomsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (_, programId) => ApiClient.getRooms(programId),
);

// 편성 준비: 말씀조 목록 + 편성 요약
// 반환: { groups: [...], summary: {...} }
final groupsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (_, programId) => ApiClient.getGroups(programId),
);
