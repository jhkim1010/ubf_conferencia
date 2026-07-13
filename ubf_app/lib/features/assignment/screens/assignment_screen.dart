import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';
import '../providers/assignment_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// PRD F4 — 관리자 배정 화면 (숙소 · 말씀조)
class AssignmentScreen extends StatelessWidget {
  final String programId;
  const AssignmentScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.asnTitle),
          bottom: TabBar(tabs: [
            Tab(icon: const Icon(Icons.meeting_room_outlined), text: l10n.setupTabRooms),
            Tab(icon: const Icon(Icons.groups_outlined), text: l10n.setupTabGroups),
          ]),
        ),
        body: TabBarView(children: [
          _RoomsAssignTab(programId: programId),
          _GroupsAssignTab(programId: programId),
        ]),
      ),
    );
  }
}

Color _genderColor(String? g) => g == 'M'
    ? const Color(0xFF3B6FB0)
    : (g == 'F' ? const Color(0xFFB0547E) : Colors.grey);

Widget _personChip(String name, String? gender, VoidCallback? onRemove) => Chip(
      avatar: CircleAvatar(
        backgroundColor: _genderColor(gender),
        child: Text(name.isNotEmpty ? name.characters.first : '?',
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ),
      label: Text(name, style: const TextStyle(fontSize: 12)),
      onDeleted: onRemove,
      deleteIcon: onRemove == null ? null : const Icon(Icons.close, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red));
        }
      }
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
      data: (data) {
        final rooms = (data['rooms'] as List).cast<Map<String, dynamic>>();
        final unassigned = (data['unassigned'] as List).cast<Map<String, dynamic>>();
        if (rooms.isEmpty) {
          return _emptyHint(Icons.meeting_room_outlined, l10n.asnNoRooms);
        }
        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              FilledButton.icon(
                onPressed: auto,
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.asnAutoAssign),
              ),
              const SizedBox(height: 12),
              _UnassignedCard(
                people: unassigned,
                onTap: (p) => _pickRoom(context, ref, rooms, p, refresh),
              ),
              const SizedBox(height: 12),
              ...rooms.map((room) => _roomCard(context, ref, room, refresh)),
            ],
          ),
        );
      },
    );
  }

  Widget _roomCard(BuildContext context, WidgetRef ref, Map<String, dynamic> room, VoidCallback refresh) {
    final members = (room['members'] as List).cast<Map<String, dynamic>>();
    final cap = (room['capacity'] as num).toInt();
    final g = room['gender'] as String;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.meeting_room, size: 18, color: _genderColor(g == 'mixed' ? null : g)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '${room['floor'] ?? ''} ${room['name']}'.trim(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              Text('${members.length}/$cap',
                  style: TextStyle(
                      fontSize: 12,
                      color: members.length >= cap ? Colors.green : Colors.grey[600])),
            ]),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: members.map((m) => _personChip(
                      m['name'] as String? ?? '',
                      m['gender'] as String?,
                      () async {
                        await ApiClient.unassignFromRoom(programId, m['registrationId'] as String);
                        refresh();
                      },
                    )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickRoom(BuildContext context, WidgetRef ref,
      List<Map<String, dynamic>> rooms, Map<String, dynamic> person, VoidCallback refresh) async {
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
            child: Row(children: [
              Icon(Icons.meeting_room, size: 18, color: _genderColor(room['gender'] == 'mixed' ? null : room['gender'] as String?)),
              const SizedBox(width: 10),
              Expanded(child: Text('${room['floor'] ?? ''} ${room['name']}'.trim())),
              Text('$members/$cap', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          );
        }).toList(),
      ),
    );
    if (roomId == null) return;
    try {
      await ApiClient.assignToRoom(programId, roomId, person['registrationId'] as String);
      refresh();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red));
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.asnAutoGroupsDone((r['assigned'] as num).toInt()))));
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red));
        }
      }
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
      data: (data) {
        final groups = (data['groups'] as List).cast<Map<String, dynamic>>();
        final unassigned = (data['unassigned'] as List).cast<Map<String, dynamic>>();
        if (groups.isEmpty) {
          return _emptyHint(Icons.groups_outlined, l10n.asnNoGroups);
        }
        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              FilledButton.icon(
                onPressed: auto,
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.asnAutoAssign),
              ),
              const SizedBox(height: 12),
              _UnassignedCard(
                people: unassigned,
                onTap: (p) => _pickGroup(context, ref, groups, p, refresh),
              ),
              const SizedBox(height: 12),
              ...groups.map((group) => _groupCard(context, ref, group, refresh)),
            ],
          ),
        );
      },
    );
  }

  Widget _groupCard(BuildContext context, WidgetRef ref, Map<String, dynamic> group, VoidCallback refresh) {
    final l10n = AppLocalizations.of(context)!;
    final members = (group['members'] as List).cast<Map<String, dynamic>>();
    final male = members.where((m) => m['gender'] == 'M').length;
    final female = members.where((m) => m['gender'] == 'F').length;
    final leader = group['leader_name'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.groups, size: 18, color: Color(0xFFC98A16)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                leader != null && leader.isNotEmpty ? '${group['name']} · $leader' : group['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              Text('${members.length} · ${l10n.genderMale}$male ${l10n.genderFemale}$female',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: members.map((m) => _personChip(
                      m['name'] as String? ?? '',
                      m['gender'] as String?,
                      () async {
                        await ApiClient.unassignFromGroup(programId, m['registrationId'] as String);
                        refresh();
                      },
                    )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickGroup(BuildContext context, WidgetRef ref,
      List<Map<String, dynamic>> groups, Map<String, dynamic> person, VoidCallback refresh) async {
    final l10n = AppLocalizations.of(context)!;
    final groupId = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(l10n.asnPickGroup),
        children: groups.map((group) {
          final n = (group['members'] as List).length;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, group['id'] as String),
            child: Row(children: [
              const Icon(Icons.groups, size: 18, color: Color(0xFFC98A16)),
              const SizedBox(width: 10),
              Expanded(child: Text(group['name'] as String)),
              Text('$n', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          );
        }).toList(),
      ),
    );
    if (groupId == null) return;
    try {
      await ApiClient.assignToGroup(programId, groupId, person['registrationId'] as String);
      refresh();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    }
  }
}

// ── 미배정 카드 ───────────────────────────────────────────────
class _UnassignedCard extends StatelessWidget {
  final List<Map<String, dynamic>> people;
  final void Function(Map<String, dynamic>) onTap;
  const _UnassignedCard({required this.people, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (people.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
          const SizedBox(width: 8),
          Text(l10n.asnAllAssigned, style: TextStyle(color: Colors.green[800])),
        ]),
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
          Text(l10n.asnUnassignedCount(people.length),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber[900])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: people.map((p) => ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: _genderColor(p['gender'] as String?),
                    child: Text('${p['name']}'.isNotEmpty ? '${p['name']}'.characters.first : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                  label: Text('${p['name']}', style: const TextStyle(fontSize: 12)),
                  onPressed: () => onTap(p),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
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
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
