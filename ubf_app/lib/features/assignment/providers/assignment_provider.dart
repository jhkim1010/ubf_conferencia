import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';

// 조회는 **autoDispose** 다. 화면을 떠나면 버리고 다시 들어올 때 새로 받는다.
//
// 예전에는 앱이 살아 있는 동안 응답을 계속 들고 있었다. 그래서 배정 화면을
// 먼저 열어 "방 없음" 을 캐시한 뒤 편성 준비에서 방을 열아홉 개 만들고
// 돌아오면, 화면은 여전히 비어 있었다 — 편성 준비는 자기 목록만 새로
// 고치고 배정 쪽은 건드리지 않는다.

// 숙소 배정 현황 { rooms, unassigned }
final roomAssignmentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (_, programId) => ApiClient.getRoomAssignments(programId),
    );

// 말씀조 배정 현황 { groups, unassigned }
final groupAssignmentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (_, programId) => ApiClient.getGroupAssignments(programId),
    );

// 봉사 담당자 배정 현황 (039). 역할별로 사람과 부족 인원이 함께 온다.
final serviceBoardProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>(
      (_, programId) => ApiClient.getServiceBoard(programId),
    );

// 나에게 온 봉사 부탁 (참가자 쪽).
final myServiceInvitesProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>(
      (_, programId) => ApiClient.getMyServiceInvites(programId),
    );

// 나에게 열려 있는 봉사 모집 (043). 담당자가 전체에 청한 것 중, 아직 내가
// 답하지 않았고 여전히 모자란 역할만 온다.
final openServiceCallsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>(
      (_, programId) => ApiClient.getOpenServiceCalls(programId),
    );

// 지난 공지 (044).
final announcementsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>(
      (_, programId) => ApiClient.getAnnouncements(programId),
    );

/// 내 텔레그램 연결 상태(047). 링크와 연결 여부를 함께 준다.
///
/// autoDispose 다 — 연결한 뒤 화면을 다시 열면 새로 물어야 한다.
final myTelegramLinkProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (_, programId) => ApiClient.getTelegramLink(programId),
    );
