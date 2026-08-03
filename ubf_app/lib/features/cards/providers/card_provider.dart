import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// QR 나눔(031)

/// 내 명함. 처음 열면 서버가 만들어 준다.
final myCardProvider = FutureProvider<Map<String, dynamic>>(
  (_) => ApiClient.getMyCard(),
);

/// 내가 저장한 사람들.
final connectionsProvider = FutureProvider<List<dynamic>>(
  (_) => ApiClient.getConnections(),
);

/// 나를 저장한 사람들. 준 것을 돌려받을 수 있어야 마음 놓고 준다.
final savedByProvider = FutureProvider<List<dynamic>>(
  (_) => ApiClient.getSavedBy(),
);
