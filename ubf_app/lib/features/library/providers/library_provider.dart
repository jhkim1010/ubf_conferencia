import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// 자료실 목록(030).
//
// 담당자는 숨긴 자료까지 봐야 하고 참가자는 공개된 것만 본다. 두 목록은
// 서로 다른 캐시여야 한다 — 하나로 묶으면 담당자가 숨긴 자료를 본 뒤
// 참가자 화면에도 그것이 남는다.
typedef LibraryArgs = ({String programId, bool all});

final programLibraryProvider =
    FutureProvider.family<List<dynamic>, LibraryArgs>(
      (_, args) => ApiClient.getLibrary(args.programId, all: args.all),
    );
