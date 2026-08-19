import 'package:flutter/material.dart';
import '../../program/providers/program_provider.dart';
import '../../../core/constants/admin_scopes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';
import '../providers/assignment_provider.dart';
import 'service_assign_tab.dart';
import '../widgets/split_board.dart';
import 'package:mana/l10n/app_localizations.dart';

// PRD F4 — 관리자 배정 화면 (숙소 · 말씀조)
class AssignmentScreen extends ConsumerWidget {
  final String programId;

  /// 처음 열 탭. 대시보드의 봉사 카드가 곧바로 봉사 탭으로 보낸다 —
  /// 숙소 탭을 지나 손으로 찾아가게 하면 카드를 누른 뜻이 없다.
  final int initialTab;

  const AssignmentScreen({
    super.key,
    required this.programId,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // 안 맡은 분야는 탭 자체가 없다(059). 탭을 남겨 두면 눌러 들어갔다가
    // 403 을 만나고, 담당자는 앱이 고장 났다고 여긴다.
    final mine = scopesOf(
      ref.watch(programStatsProvider(programId)).valueOrNull?['myScopes'],
    );
    final tabs = <({IconData icon, String text, Widget body})>[
      if (canSee(mine, 'rooms'))
        (
          icon: Icons.meeting_room_outlined,
          text: l10n.setupTabRooms,
          body: _RoomsAssignTab(programId: programId),
        ),
      if (canSee(mine, 'groups'))
        (
          icon: Icons.groups_outlined,
          text: l10n.setupTabGroups,
          body: _GroupsAssignTab(programId: programId),
        ),
      if (canSee(mine, 'service'))
        (
          icon: Icons.volunteer_activism_outlined,
          text: l10n.asnTabService,
          body: ServiceAssignTab(programId: programId),
        ),
    ];
    if (tabs.isEmpty) {
      // 여기까지 올 길이 없어야 하지만, 깊은 링크로 들어올 수는 있다.
      return Scaffold(
        appBar: AppBar(title: Text(l10n.asnTitle)),
        body: _emptyHint(Icons.lock_outline, l10n.scopeNotYours),
      );
    }
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialTab.clamp(0, tabs.length - 1),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.asnTitle),
          bottom: TabBar(
            tabs: [for (final t in tabs) Tab(icon: Icon(t.icon), text: t.text)],
          ),
        ),
        body: TabBarView(children: [for (final t in tabs) t.body]),
      ),
    );
  }
}

Color _genderColor(String? g) => g == 'M'
    ? const Color(0xFF3B6FB0)
    : (g == 'F' ? const Color(0xFFB0547E) : Colors.grey);

/// 말씀공부 언어(025·034)의 이름.
///
/// 언어 이름은 그 언어로 적는다 — 등록 화면과 같다. "Korean" 이라고 옮기면
/// 정작 그 조에 들어갈 사람이 못 알아본다.
String _languageLabel(String? code) => switch (code) {
  'ko' => '한국어',
  'en' => 'English',
  'es' => 'Español',
  'pt' => 'Português',
  _ => '',
};

/// 여럿 고른 경우. 첫 번째가 주 언어이므로 순서를 지킨다.
String _languagesLabel(dynamic codes) => ((codes as List?) ?? const [])
    .map((c) => _languageLabel('$c'))
    .where((s) => s.isNotEmpty)
    .join(' · ');

/// 배정된 사람 한 명.
///
/// X 는 자리에서 빼는 것이고, 이름을 누르는 것은 [onTap] 이다 — 두 동작을
/// 한 곳에 두면 빼려다 방장을 세우게 된다. 그래서 지우기는 X 에만 둔다.
Widget _personChip(
  String name,
  String? gender,
  VoidCallback? onRemove, {
  bool isLeader = false,
  VoidCallback? onTap,
}) {
  final chip = Chip(
    avatar: CircleAvatar(
      backgroundColor: _genderColor(gender),
      child: Text(
        name.isNotEmpty ? name.characters.first : '?',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    ),
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLeader) ...[
          const Icon(Icons.star, size: 12, color: Color(0xFFC98A16)),
          const SizedBox(width: 3),
        ],
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isLeader ? FontWeight.w700 : null,
          ),
        ),
      ],
    ),
    onDeleted: onRemove,
    deleteIcon: onRemove == null ? null : const Icon(Icons.close, size: 16),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
  if (onTap == null) return chip;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: chip,
  );
}

/// 이 사람을 옮길 때 **함께 가는 사람들**. 본인이 맨 앞이다.
///
/// 서로 지목하고 수락한 사람들이다(057). 자동 배정은 이들을 한 묶음으로
/// 다루는데 손으로 옮길 때만 한 명씩이면, 담당자가 한쪽만 옮긴 순간 짝이
/// 깨지고 아무도 그것을 알아채지 못한다.
List<String> _movesWith(Map<String, dynamic> person) => [
  person['registrationId'] as String,
  ...((person['withIds'] as List?) ?? const []).map((e) => '$e'),
];

// ═══════════════════════════════════════════════════════════
//  숙소 배정 탭
// ═══════════════════════════════════════════════════════════
class _RoomsAssignTab extends ConsumerWidget {
  final String programId;
  const _RoomsAssignTab({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(roomAssignmentsProvider(programId));
    void refresh() => ref.invalidate(roomAssignmentsProvider(programId));

    Future<void> auto() async {
      try {
        final r = await ApiClient.autoAssignRooms(programId);
        refresh();
        if (context.mounted) {
          final unplaced = (r['unplaced'] as List?)?.length ?? 0;
          final msg = unplaced > 0
              ? '${l10n.asnAutoRoomsDone((r['assigned'] as num).toInt())} · ${l10n.asnUnplaced(unplaced)}'
              : l10n.asnAutoRoomsDone((r['assigned'] as num).toInt());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      }
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
      data: (data) {
        final rooms = (data['rooms'] as List).cast<Map<String, dynamic>>();
        final unassigned = (data['unassigned'] as List)
            .cast<Map<String, dynamic>>();
        if (rooms.isEmpty) {
          return _emptyHint(Icons.meeting_room_outlined, l10n.asnNoRooms);
        }
        return SplitBoard(
          onRefresh: () async => refresh(),
          action: FilledButton.icon(
            onPressed: auto,
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.asnAutoAssign),
          ),
          left: _UnassignedCard(
            people: unassigned,
            onTap: (p) => _pickRoom(context, ref, rooms, p, refresh),
          ),
          right: [
            for (final room in rooms) _roomCard(context, ref, room, refresh),
          ],
        );
      },
    );
  }

  Widget _roomCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> room,
    VoidCallback refresh,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final members = (room['members'] as List).cast<Map<String, dynamic>>();
    final cap = (room['capacity'] as num).toInt();
    final extra = (room['extra_capacity'] as num?)?.toInt() ?? 0;
    final g = room['gender'] as String;
    final leaderId = room['leaderRegistrationId'] as String?;
    final leader = members.firstWhere(
      (m) => m['registrationId'] == leaderId,
      orElse: () => const {},
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.meeting_room,
                  size: 18,
                  color: _genderColor(g == 'mixed' ? null : g),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${room['floor'] ?? ''} ${room['name']}'.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  extra > 0
                      ? l10n.asnRoomWithExtra(members.length, cap, extra)
                      : '${members.length}/$cap',
                  style: TextStyle(
                    fontSize: 12,
                    // 여유까지 쓰고 있으면 그 사실이 눈에 띄어야 한다.
                    color: members.length > cap
                        ? Colors.orange[800]
                        : (members.length >= cap
                              ? Colors.green
                              : Colors.grey[600]),
                  ),
                ),
              ],
            ),
            // 방장. 현장에서 방에 무슨 일이 생기면 담당자가 먼저 찾는
            // 사람이다. 아직 없으면 그것도 말해 준다 — 빈 줄로 두면 세울 수
            // 있다는 것 자체를 모른다.
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: leader.isEmpty
                        ? Colors.grey[400]
                        : const Color(0xFFC98A16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    leader.isEmpty
                        ? l10n.asnNoRoomLeader
                        : l10n.asnRoomLeaderIs('${leader['name']}'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: leader.isEmpty ? Colors.grey[600] : null,
                    ),
                  ),
                ],
              ),
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: members
                    .map(
                      (m) => _personChip(
                        m['name'] as String? ?? '',
                        m['gender'] as String?,
                        () async {
                          await ApiClient.unassignFromRoom(
                            programId,
                            m['registrationId'] as String,
                          );
                          refresh();
                        },
                        // 이름을 누르면 방장이 된다. 이미 방장이면 내린다.
                        isLeader: m['registrationId'] == leaderId,
                        onTap: () => _setRoomLeader(
                          context,
                          room,
                          m,
                          isLeader: m['registrationId'] == leaderId,
                          refresh: refresh,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 방장을 세우거나 내린다. 이미 방장인 사람을 다시 누르면 내려간다 —
  /// 잘못 눌렀을 때 되돌릴 길이 그것뿐이다.
  Future<void> _setRoomLeader(
    BuildContext context,
    Map<String, dynamic> room,
    Map<String, dynamic> person, {
    required bool isLeader,
    required VoidCallback refresh,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.setRoomLeader(
        programId,
        room['id'] as String,
        isLeader ? null : person['registrationId'] as String,
      );
      refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLeader
                  ? l10n.asnNoRoomLeader
                  : l10n.asnRoomLeaderIs('${person['name']}'),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickRoom(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> rooms,
    Map<String, dynamic> person,
    VoidCallback refresh,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final roomId = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(l10n.asnPickRoom),
        children: rooms.map((room) {
          final members = (room['members'] as List).length;
          final cap = (room['capacity'] as num).toInt();
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, room['id'] as String),
            child: Row(
              children: [
                Icon(
                  Icons.meeting_room,
                  size: 18,
                  color: _genderColor(
                    room['gender'] == 'mixed'
                        ? null
                        : room['gender'] as String?,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${room['floor'] ?? ''} ${room['name']}'.trim()),
                ),
                Text(
                  '$members/$cap',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (roomId == null) return;
    try {
      // 같이 있고 싶다고 서로 수락한 사람은 함께 옮긴다(057). 한 명만
      // 옮기면 자동 배정이 지켜 준 짝이 손으로 깨진다.
      for (final id in _movesWith(person)) {
        await ApiClient.assignToRoom(programId, roomId, id);
      }
      refresh();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  말씀조 배정 탭
// ═══════════════════════════════════════════════════════════
class _GroupsAssignTab extends ConsumerWidget {
  final String programId;
  const _GroupsAssignTab({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(groupAssignmentsProvider(programId));
    void refresh() => ref.invalidate(groupAssignmentsProvider(programId));

    Future<void> auto() async {
      try {
        final r = await ApiClient.autoAssignGroups(programId);
        refresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.asnAutoGroupsDone((r['assigned'] as num).toInt()),
              ),
            ),
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      }
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
      data: (data) {
        final groups = (data['groups'] as List).cast<Map<String, dynamic>>();
        final unassigned = (data['unassigned'] as List)
            .cast<Map<String, dynamic>>();
        if (groups.isEmpty) {
          return _emptyHint(Icons.groups_outlined, l10n.asnNoGroups);
        }
        return SplitBoard(
          onRefresh: () async => refresh(),
          action: FilledButton.icon(
            onPressed: auto,
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.asnAutoAssign),
          ),
          left: _UnassignedCard(
            people: unassigned,
            onTap: (p) => _pickGroup(context, ref, groups, p, refresh),
            // 어느 조로 보낼지는 언어로 갈린다. 이름만 있으면 한 명씩
            // 열어 봐야 한다.
            languageOf: (p) => _languagesLabel(p['studyLanguages']),
          ),
          right: [
            for (final group in groups)
              _groupCard(context, ref, group, refresh),
          ],
          rightWeights: [
            for (final group in groups)
              2 + ((group['members'] as List?)?.length ?? 0) / 2,
          ],
        );
      },
    );
  }

  Widget _groupCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> group,
    VoidCallback refresh,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final members = (group['members'] as List).cast<Map<String, dynamic>>();
    final male = members.where((m) => m['gender'] == 'M').length;
    final female = members.where((m) => m['gender'] == 'F').length;
    final leader = group['leader_name'] as String?;
    final lang = _languageLabel(group['studyLanguage'] as String?);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups, size: 18, color: Color(0xFFC98A16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${members.length} · ${l10n.genderMale}$male ${l10n.genderFemale}$female',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            // 조가 어느 언어로 모이는지(025)와 조장이 누구인지. 사람을 조에
            // 넣을 때 담당자가 맞춰 보는 것이 이 둘이다.
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (lang.isNotEmpty) ...[
                    const Icon(Icons.translate, size: 14),
                    const SizedBox(width: 5),
                    Text(lang, style: const TextStyle(fontSize: 11.5)),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.star,
                    size: 14,
                    color: (leader == null || leader.isEmpty)
                        ? Colors.grey[400]
                        : const Color(0xFFC98A16),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      (leader == null || leader.isEmpty)
                          ? l10n.asnNoGroupLeader
                          : leader,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: (leader == null || leader.isEmpty)
                            ? Colors.grey[600]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: members
                    .map(
                      (m) => _personChip(
                        m['name'] as String? ?? '',
                        m['gender'] as String?,
                        () async {
                          await ApiClient.unassignFromGroup(
                            programId,
                            m['registrationId'] as String,
                          );
                          refresh();
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickGroup(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> groups,
    Map<String, dynamic> person,
    VoidCallback refresh,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final groupId = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(l10n.asnPickGroup),
        children: groups.map((group) {
          final n = (group['members'] as List).length;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, group['id'] as String),
            child: Row(
              children: [
                const Icon(Icons.groups, size: 18, color: Color(0xFFC98A16)),
                const SizedBox(width: 10),
                Expanded(child: Text(group['name'] as String)),
                Text(
                  '$n',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (groupId == null) return;
    try {
      for (final id in _movesWith(person)) {
        await ApiClient.assignToGroup(programId, groupId, id);
      }
      refresh();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── 미배정 카드 ───────────────────────────────────────────────
class _UnassignedCard extends StatelessWidget {
  final List<Map<String, dynamic>> people;
  final void Function(Map<String, dynamic>) onTap;

  /// 이름 옆에 덧붙일 한마디. 말씀조에서는 그 사람이 할 수 있는 언어다 —
  /// 어느 조로 보낼지가 그것으로 갈린다. 숙소에서는 쓰지 않는다.
  final String Function(Map<String, dynamic>)? languageOf;

  const _UnassignedCard({
    required this.people,
    required this.onTap,
    this.languageOf,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (people.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              l10n.asnAllAssigned,
              style: TextStyle(color: Colors.green[800]),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.asnUnassignedCount(people.length),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.amber[900],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: people
                .map(
                  (p) => ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: _genderColor(p['gender'] as String?),
                      child: Text(
                        '${p['name']}'.isNotEmpty
                            ? '${p['name']}'.characters.first
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    // 짝이 있으면 몇 명이 함께 가는지 적는다(057). 눌렀을
                    // 때 여럿이 한꺼번에 옮겨 가는 것을 미리 알아야 한다.
                    label: Text(() {
                      final lang = languageOf?.call(p) ?? '';
                      final mates = _movesWith(p).length;
                      final base = lang.isEmpty
                          ? '${p['name']}'
                          : '${p['name']} · $lang';
                      return mates > 1 ? '$base  +${mates - 1}' : base;
                    }(), style: const TextStyle(fontSize: 12)),
                    // 짝이 있는 사람은 테두리로 구별한다.
                    side: _movesWith(p).length > 1
                        ? BorderSide(color: Colors.indigo.shade300, width: 1.4)
                        : null,
                    onPressed: () => onTap(p),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

Widget _emptyHint(IconData icon, String message) => Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  ),
);
