import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// 배차판 현황 { direction, runs, unassigned } — (programId, direction) 별
final transportRunsProvider =
    FutureProvider.family<Map<String, dynamic>, (String, String)>(
  (_, arg) => ApiClient.getTransportRuns(arg.$1, arg.$2),
);

// 참가자 내 이동 정보 { needsPickup, arrival, departure }
final myTransportProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (_, programId) => ApiClient.getMyTransport(programId),
);
