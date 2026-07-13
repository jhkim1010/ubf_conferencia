import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// 지목 후보 (나 제외 등록자)
final buddyCandidatesProvider =
    FutureProvider.family<List<dynamic>, String>(
  (_, programId) => ApiClient.getBuddyCandidates(programId),
);

// 내가 보낸/받은 요청 { sent: [...], received: [...] }
final myBuddyRequestsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (_, programId) => ApiClient.getMyBuddyRequests(programId),
);

// 내 동반자 목록
final myCompanionsProvider =
    FutureProvider.family<List<dynamic>, String>(
  (_, programId) => ApiClient.getMyCompanions(programId),
);
