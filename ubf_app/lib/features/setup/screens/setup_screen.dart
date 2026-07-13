import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/setup_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// 편성 준비 (PRD F2) — 숙소 설정 + 말씀조 설정
// 배정(F4) 전에 방·조의 "그릇"을 정의한다.
class SetupScreen extends StatelessWidget {
  final String programId;
  const SetupScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.setupTitle),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.meeting_room_outlined), text: l10n.setupTabRooms),
              Tab(icon: const Icon(Icons.groups_outlined), text: l10n.setupTabGroups),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RoomsTab(programId: programId),
            _GroupsTab(programId: programId),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  숙소 탭
// ═══════════════════════════════════════════════════════════
class _RoomsTab extends ConsumerWidget {
  final String programId;
  const _RoomsTab({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider(programId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (data) {
          final rooms = (data['rooms'] as List).cast<Map<String, dynamic>>();
          final summary = data['summary'] as Map<String, dynamic>;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(roomsProvider(programId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _ReconcileCard(summary: summary),
                const SizedBox(height: 20),
                Text(l10n.setupRoomsMade(rooms.length),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (rooms.isEmpty)
                  _EmptyHint(
                    icon: Icons.meeting_room_outlined,
                    message: l10n.setupRoomsEmpty,
                  )
                else
                  ...rooms.map((r) => _RoomTile(
                        programId: programId,
                        room: r,
                        onChanged: () => ref.invalidate(roomsProvider(programId)),
                      )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBulkAdd(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.setupBulkAddRooms),
      ),
    );
  }

  Future<void> _openBulkAdd(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RoomBulkSheet(),
    );
    if (result == null) return;
    try {
      final n = await ApiClient.bulkCreateRooms(programId, result);
      ref.invalidate(roomsProvider(programId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.setupRoomsAdded(n))),
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
}

// 정원 대비 등록 대조 카드
class _ReconcileCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _ReconcileCard({required this.summary});

  int _i(String k) => (summary[k] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maleShort = _i('maleShortage');
    final femaleShort = _i('femaleShortage');
    final mixedSeats = _i('mixedSeats');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(l10n.setupReconcileTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            _GenderReconcileRow(
              label: l10n.setupMale,
              regs: _i('maleRegs'),
              seats: _i('maleSeats'),
              shortage: maleShort,
              color: const Color(0xFF3B6FB0),
            ),
            const SizedBox(height: 10),
            _GenderReconcileRow(
              label: l10n.setupFemale,
              regs: _i('femaleRegs'),
              seats: _i('femaleSeats'),
              shortage: femaleShort,
              color: const Color(0xFFB0547E),
            ),
            if (mixedSeats > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.family_restroom, size: 16, color: Color(0xFF7A6BB5)),
                  const SizedBox(width: 6),
                  Text(l10n.setupMixedSeats(mixedSeats),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GenderReconcileRow extends StatelessWidget {
  final String label;
  final int regs, seats, shortage;
  final Color color;
  const _GenderReconcileRow({
    required this.label,
    required this.regs,
    required this.seats,
    required this.shortage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = seats == 0 ? 0.0 : (regs / seats).clamp(0.0, 1.0);
    final over = shortage > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(l10n.setupRegVsSeats(regs, seats),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (over) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(l10n.setupSeatShortage(shortage),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700])),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            color: over ? Colors.red : color,
          ),
        ),
      ],
    );
  }
}

class _RoomTile extends StatelessWidget {
  final String programId;
  final Map<String, dynamic> room;
  final VoidCallback onChanged;
  const _RoomTile({
    required this.programId,
    required this.room,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = room['room_type'] as String;
    final gender = room['gender'] as String;
    final (typeLabel, genderLabel, genderColor) = _roomBadges(type, gender, l10n);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: genderColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.meeting_room, color: genderColor, size: 20),
        ),
        title: Text(room['name'] as String,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${room['floor'] ?? ''} · $typeLabel · ${l10n.setupRoomCapacity((room['capacity'] as num).toInt())} · $genderLabel'
              .replaceFirst(RegExp(r'^ · '), ''),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: l10n.actionDelete,
          onPressed: () async {
            await ApiClient.deleteRoom(programId, room['id'] as String);
            onChanged();
          },
        ),
      ),
    );
  }
}

(String, String, Color) _roomBadges(String type, String gender, AppLocalizations l10n) {
  final typeLabel = switch (type) {
    'couple' => l10n.setupCouple,
    'family' => l10n.setupFamily,
    _ => l10n.setupDorm,
  };
  final genderLabel = switch (gender) {
    'M' => l10n.genderMale,
    'F' => l10n.genderFemale,
    _ => l10n.setupMixed,
  };
  final color = switch (gender) {
    'M' => const Color(0xFF3B6FB0),
    'F' => const Color(0xFFB0547E),
    _ => const Color(0xFF7A6BB5),
  };
  return (typeLabel, genderLabel, color);
}

// 방 일괄 추가 바텀시트
class _RoomBulkSheet extends StatefulWidget {
  const _RoomBulkSheet();
  @override
  State<_RoomBulkSheet> createState() => _RoomBulkSheetState();
}

class _RoomBulkSheetState extends State<_RoomBulkSheet> {
  String _type = 'dorm';
  String _gender = 'M';
  final _nameCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _startCtrl = TextEditingController(text: '1');
  final _countCtrl = TextEditingController(text: '1');
  final _capCtrl = TextEditingController(text: '8');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _floorCtrl.dispose();
    _startCtrl.dispose();
    _countCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  void _selectType(String t) {
    setState(() {
      _type = t;
      if (t == 'couple') {
        _gender = 'mixed';
        _capCtrl.text = '2';
      } else if (t == 'family') {
        _gender = 'mixed';
        _capCtrl.text = '4';
      } else {
        if (_gender == 'mixed') _gender = 'M';
        _capCtrl.text = '8';
      }
    });
  }

  bool get _isDorm => _type == 'dorm';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.setupBulkAddRooms,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(l10n.setupRoomType, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: [
                _typeChip('couple', l10n.setupCouple, l10n.setupCoupleSub),
                const SizedBox(width: 6),
                _typeChip('family', l10n.setupFamily, l10n.setupFamilySub),
                const SizedBox(width: 6),
                _typeChip('dorm', l10n.setupDorm, l10n.setupDormSub),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.setupNameRule,
                      hintText: l10n.setupNameRuleHint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _startCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.setupStartNum),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _countCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.setupCount),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _capCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.setupCapacity),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _floorCtrl,
                    decoration: InputDecoration(labelText: l10n.setupFloor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.regGender, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            if (_isDorm)
              Row(
                children: [
                  _genderChip('M', l10n.genderMale),
                  const SizedBox(width: 6),
                  _genderChip('F', l10n.genderFemale),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Opacity(
                      opacity: 0.45,
                      child: _staticChip(l10n.setupMixedNotAllowed),
                    ),
                  ),
                ],
              )
            else
              _staticChip(l10n.setupFamilyAuto),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.actionAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label, String sub) {
    final on = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectType(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: on ? AppTheme.primary.withValues(alpha: 0.08) : null,
            border: Border.all(
                color: on ? AppTheme.primary : Colors.grey[300]!,
                width: on ? 1.5 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: on ? AppTheme.primary : Colors.black87)),
              Text(sub, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderChip(String value, String label) {
    final on = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppTheme.primary.withValues(alpha: 0.08) : null,
            border: Border.all(
                color: on ? AppTheme.primary : Colors.grey[300]!,
                width: on ? 1.5 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: on ? AppTheme.primary : Colors.black87)),
        ),
      ),
    );
  }

  Widget _staticChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700])),
    );
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final count = int.tryParse(_countCtrl.text) ?? 0;
    final cap = int.tryParse(_capCtrl.text) ?? 0;
    if (name.isEmpty || count < 1 || cap < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.setupBulkValidation)),
      );
      return;
    }
    Navigator.pop(context, {
      'namePattern': name,
      'startNumber': int.tryParse(_startCtrl.text) ?? 1,
      'count': count,
      'capacity': cap,
      'roomType': _type,
      'gender': _gender,
      if (_floorCtrl.text.trim().isNotEmpty) 'floor': _floorCtrl.text.trim(),
    });
  }
}

// ═══════════════════════════════════════════════════════════
//  말씀조 탭
// ═══════════════════════════════════════════════════════════
class _GroupsTab extends ConsumerWidget {
  final String programId;
  const _GroupsTab({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider(programId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (data) {
          final groups = (data['groups'] as List).cast<Map<String, dynamic>>();
          final summary = data['summary'] as Map<String, dynamic>;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(groupsProvider(programId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _GroupSummaryCard(summary: summary),
                const SizedBox(height: 20),
                Text(l10n.setupGroupsMade(groups.length),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (groups.isEmpty)
                  _EmptyHint(
                    icon: Icons.groups_outlined,
                    message: l10n.setupGroupsEmpty,
                  )
                else
                  ...groups.map((g) => _GroupTile(
                        programId: programId,
                        group: g,
                        onChanged: () => ref.invalidate(groupsProvider(programId)),
                      )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGenerate(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.setupMakeGroups),
      ),
    );
  }

  Future<void> _openGenerate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final countCtrl = TextEditingController(text: '8');
    final count = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.setupMakeGroups),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.setupMakeGroupsPrompt),
            const SizedBox(height: 12),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.setupGroupCount, suffixText: l10n.setupGroupCountSuffix),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(countCtrl.text) ?? 0),
            child: Text(l10n.setupMake),
          ),
        ],
      ),
    );
    if (count == null || count < 1) return;
    try {
      final n = await ApiClient.generateGroups(programId, count);
      ref.invalidate(groupsProvider(programId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.setupGroupsCreated(n))),
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
}

class _GroupSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _GroupSummaryCard({required this.summary});

  int _i(String k) => (summary[k] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = _i('totalRegs');
    final groupCount = _i('groupCount');
    final base = _i('perGroupBase');
    final rem = _i('perGroupRemainder');
    final leaderless = _i('leaderlessCount');

    final preview = groupCount == 0
        ? l10n.setupMakeGroupsFirst
        : rem == 0
            ? l10n.setupEvenPerGroup(base)
            : l10n.setupUnevenPerGroup(rem, base + 1, base);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.balance, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(l10n.setupGroupSummary,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.setupRegAndGroups(total, groupCount),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(l10n.setupBalancePreview(preview),
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            if (leaderless > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.amber[800]),
                    const SizedBox(width: 6),
                    Text(l10n.setupLeaderless(leaderless),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[900])),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final String programId;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  const _GroupTile({
    required this.programId,
    required this.group,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final leaderName = group['leader_name'] as String?;
    final hasLeader = leaderName != null && leaderName.isNotEmpty;
    final passage = group['passage'] as String?;
    final location = group['location'] as String?;
    final sub = [
      if (passage != null && passage.isNotEmpty) passage,
      if (location != null && location.isNotEmpty) location,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasLeader
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.grey[200],
          child: Icon(Icons.groups,
              color: hasLeader ? AppTheme.primary : Colors.grey, size: 20),
        ),
        title: Text(
          hasLeader ? '${group['name']} · $leaderName' : group['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          sub.isEmpty
              ? (hasLeader ? l10n.setupNoPassageLocation : l10n.setupNoLeader)
              : sub,
          style: TextStyle(
            color: hasLeader ? null : Colors.amber[800],
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              await _editGroup(context);
            } else if (v == 'delete') {
              await ApiClient.deleteGroup(programId, group['id'] as String);
              onChanged();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.setupEditGroupMenu)),
            PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
          ],
        ),
        onTap: () => _editGroup(context),
      ),
    );
  }

  Future<void> _editGroup(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl =
        TextEditingController(text: group['name'] as String? ?? '');
    final leaderCtrl =
        TextEditingController(text: group['leader_name'] as String? ?? '');
    final phoneCtrl =
        TextEditingController(text: group['leader_phone'] as String? ?? '');
    final passageCtrl =
        TextEditingController(text: group['passage'] as String? ?? '');
    final locationCtrl =
        TextEditingController(text: group['location'] as String? ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.setupEditGroupTitle('${group['name']}')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.setupGroupName),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: leaderCtrl,
                decoration: InputDecoration(labelText: l10n.setupLeaderName),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(labelText: l10n.setupLeaderPhone),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passageCtrl,
                decoration: InputDecoration(labelText: l10n.setupPassage),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(labelText: l10n.setupLocation),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.actionSave)),
        ],
      ),
    );

    if (saved != true) return;
    await ApiClient.updateGroup(programId, group['id'] as String, {
      'name': nameCtrl.text.trim(),
      'leaderName': leaderCtrl.text.trim(),
      'leaderPhone': phoneCtrl.text.trim(),
      'passage': passageCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
    });
    onChanged();
  }
}

// 공통 빈 상태
class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
