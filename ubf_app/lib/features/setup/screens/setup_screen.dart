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
              Tab(
                icon: const Icon(Icons.meeting_room_outlined),
                text: l10n.setupTabRooms,
              ),
              Tab(
                icon: const Icon(Icons.groups_outlined),
                text: l10n.setupTabGroups,
              ),
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
                Text(
                  l10n.setupRoomsMade(rooms.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (rooms.isEmpty)
                  _EmptyHint(
                    icon: Icons.meeting_room_outlined,
                    message: l10n.setupRoomsEmpty,
                  )
                else
                  // 부부·가족실과 단체실은 **다른 종류의 일**이다. 부부실은
                  // 가족 단위로 묶어 배정하고 단체실은 성별로 채운다. 한
                  // 줄로 늘어놓으면 열여섯 개 중에서 눈으로 골라내야 한다.
                  //
                  // 폰에서는 나눌 너비가 없으므로 예전처럼 이어 붙인다.
                  _RoomColumns(
                    programId: programId,
                    rooms: rooms,
                    onChanged: () => ref.invalidate(roomsProvider(programId)),
                  ),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.setupRoomsAdded(n)),
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
                Text(
                  l10n.setupReconcileTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  const Icon(
                    Icons.family_restroom,
                    size: 16,
                    color: Color(0xFF7A6BB5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.setupMixedSeats(mixedSeats),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
            Text(
              l10n.setupRegVsSeats(regs, seats),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (over) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.setupSeatShortage(shortage),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
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

/// 부부·가족실과 단체실을 좌우로 나눈다.
class _RoomColumns extends StatelessWidget {
  final String programId;
  final List<Map<String, dynamic>> rooms;
  final VoidCallback onChanged;

  const _RoomColumns({
    required this.programId,
    required this.rooms,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 부부실과 가족실은 같은 칸에 둔다 — 둘 다 가족 단위로 배정한다.
    final couples = rooms
        .where((r) => r['room_type'] == 'couple' || r['room_type'] == 'family')
        .toList();
    final dorms = rooms.where((r) => r['room_type'] == 'dorm').toList();

    List<Widget> column(String title, List<Map<String, dynamic>> list) => [
      Text(
        '$title · ${list.length}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      const SizedBox(height: 6),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            l10n.setupRoomsEmpty,
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
          ),
        )
      else
        for (final r in list)
          _RoomTile(programId: programId, room: r, onChanged: onChanged),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...column(l10n.setupCoupleRooms, couples),
              const SizedBox(height: 16),
              ...column(l10n.setupDormRooms, dorms),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: column(l10n.setupCoupleRooms, couples),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: column(l10n.setupDormRooms, dorms),
              ),
            ),
          ],
        );
      },
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
    final (typeLabel, genderLabel, genderColor) = _roomBadges(
      type,
      gender,
      l10n,
    );

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
        title: Text(
          room['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${room['floor'] ?? ''} · $typeLabel · ${l10n.setupRoomCapacity((room['capacity'] as num).toInt())}'
                  '${((room['extra_capacity'] as num?)?.toInt() ?? 0) > 0 ? ' +${(room['extra_capacity'] as num).toInt()}' : ''}'
                  ' · $genderLabel'
              .replaceFirst(RegExp(r'^ · '), ''),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 정원은 현장에서 자주 바뀐다 — 침대를 하나 더 넣거나, 방 하나가
            // 못 쓰게 되거나. 지금까지는 지우고 다시 만드는 길뿐이었고,
            // 그러면 그 방에 이미 배정된 사람이 함께 날아갔다.
            TextButton(
              onPressed: () => _edit(context),
              child: Text(l10n.actionEdit),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: l10n.actionDelete,
              onPressed: () async {
                await ApiClient.deleteRoom(programId, room['id'] as String);
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 이름·정원·여유 자리를 고친다.
  ///
  /// 유형과 성별은 여기서 바꾸지 않는다 — 단체실을 부부실로 바꾸면 이미
  /// 그 방에 든 사람들의 혼숙 방침이 깨진다. 그런 경우는 방을 새로 만드는
  /// 편이 맞다.
  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: '${room['name'] ?? ''}');
    final capCtrl = TextEditingController(
      text: '${(room['capacity'] as num?)?.toInt() ?? 0}',
    );
    final extraCtrl = TextEditingController(
      text: '${(room['extra_capacity'] as num?)?.toInt() ?? 0}',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${room['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.setupRoomsMadeName),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: capCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.setupCapacity),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: extraCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.setupExtraBed,
                helperText: l10n.setupExtraBedHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (saved != true) return;

    // 정원이 0 이면 아무도 못 들어가는 방이 된다. 서버도 막지만 여기서
    // 먼저 막아야 담당자가 "저장했는데 그대로" 를 겪지 않는다.
    final cap = int.tryParse(capCtrl.text.trim()) ?? 0;
    if (cap < 1) return;

    try {
      await ApiClient.updateRoom(programId, room['id'] as String, {
        'name': nameCtrl.text.trim(),
        'capacity': cap,
        'extraCapacity': int.tryParse(extraCtrl.text.trim()) ?? 0,
      });
      onChanged();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

(String, String, Color) _roomBadges(
  String type,
  String gender,
  AppLocalizations l10n,
) {
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

  /// 여유 자리(042). 2인실에 간이침대 하나를 더 놓는 식이다.
  /// 자동 배정은 정원이 다 찬 뒤에만 쓴다.
  bool _extraBed = false;

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
            Text(
              l10n.setupBulkAddRooms,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.setupRoomType,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
            const SizedBox(height: 4),
            // 여유 자리. 정원을 3인·5인으로 적어 버리면 자동 배정이 처음부터
            // 그 자리를 정상 자리로 보고 채운다.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _extraBed,
              onChanged: (v) => setState(() => _extraBed = v),
              title: Text(
                l10n.setupExtraBed,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                l10n.setupExtraBedHint,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.regGender,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
              width: on ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: on ? AppTheme.primary : Colors.black87,
                ),
              ),
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
              width: on ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: on ? AppTheme.primary : Colors.black87,
            ),
          ),
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
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final count = int.tryParse(_countCtrl.text) ?? 0;
    final cap = int.tryParse(_capCtrl.text) ?? 0;
    if (name.isEmpty || count < 1 || cap < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.setupBulkValidation),
        ),
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
      'extraCapacity': _extraBed ? 1 : 0,
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
                Text(
                  l10n.setupGroupsMade(groups.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (groups.isEmpty)
                  _EmptyHint(
                    icon: Icons.groups_outlined,
                    message: l10n.setupGroupsEmpty,
                  )
                else
                  // 큰 화면에서는 한 줄에 셋. 조가 열 개를 넘으면 한 줄에
                  // 하나씩 쌓았을 때 아래쪽은 스크롤해야 보인다.
                  LayoutBuilder(
                    builder: (context, box) {
                      final columns = (box.maxWidth / 300).floor().clamp(1, 3);
                      const gap = 8.0;
                      final width =
                          (box.maxWidth - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final g in groups)
                            SizedBox(
                              width: columns == 1 ? box.maxWidth : width,
                              child: _GroupTile(
                                programId: programId,
                                group: g,
                                onChanged: () =>
                                    ref.invalidate(groupsProvider(programId)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
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
              decoration: InputDecoration(
                labelText: l10n.setupGroupCount,
                suffixText: l10n.setupGroupCountSuffix,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(countCtrl.text) ?? 0),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.setupGroupsCreated(n)),
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
                Text(
                  l10n.setupGroupSummary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.setupRegAndGroups(total, groupCount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.setupBalancePreview(preview),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            if (leaderless > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.amber[800],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.setupLeaderless(leaderless),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[900],
                      ),
                    ),
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

/// 말씀공부 언어의 이름. 그 언어로 적는다 — 배정 화면과 같다.
String _languageName(String? code) => switch (code) {
  'ko' => '한국어',
  'en' => 'English',
  'es' => 'Español',
  'pt' => 'Português',
  _ => '',
};

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

    // 어느 언어로 모이는 조인지(025)와 몇 명까지 받을지(051). 사람을 조에
    // 넣을 때 맞춰 보는 것이 이 둘인데 화면에 없었다.
    final lang = _languageName(group['studyLanguage'] as String?);
    final cap = (group['capacity'] as num?)?.toInt();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: hasLeader
                      ? AppTheme.primary.withValues(alpha: 0.12)
                      : Colors.grey[200],
                  child: Icon(
                    Icons.groups,
                    color: hasLeader ? AppTheme.primary : Colors.grey,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cap != null)
                  Text(
                    l10n.setupRoomCapacity(cap),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: 13,
                  color: hasLeader ? const Color(0xFFC98A16) : Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hasLeader ? leaderName : l10n.asnNoGroupLeader,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasLeader ? null : Colors.amber[800],
                    ),
                  ),
                ),
                if (lang.isNotEmpty) ...[
                  const Icon(Icons.translate, size: 13),
                  const SizedBox(width: 4),
                  Text(lang, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
            if (sub.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _editGroup(context),
                  child: Text(l10n.actionEdit),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: l10n.actionDelete,
                  onPressed: () async {
                    await ApiClient.deleteGroup(
                      programId,
                      group['id'] as String,
                    );
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGroup(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(
      text: group['name'] as String? ?? '',
    );
    final leaderCtrl = TextEditingController(
      text: group['leader_name'] as String? ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: group['leader_phone'] as String? ?? '',
    );
    final passageCtrl = TextEditingController(
      text: group['passage'] as String? ?? '',
    );
    final locationCtrl = TextEditingController(
      text: group['location'] as String? ?? '',
    );
    // 조가 어느 언어로 모이는지(025). 칸은 처음부터 있었는데 정할 자리가
    // 없어서 늘 비어 있었고, 그래서 자동 배정이 모든 조를 "아무나 받는 조"
    // 로 봤다. 안 정해 두는 것도 그대로 뜻이 있으므로 빈 값을 남겨 둔다.
    String? lang = group['studyLanguage'] as String?;
    // 정원(051). 비워 두면 "정하지 않음" 이고, 그때는 자동 배정이 지금까지처럼
    // 고르게 나눈다.
    final groupCapCtrl = TextEditingController(
      text: group['capacity'] == null ? '' : '${group['capacity']}',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
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
                const SizedBox(height: 8),
                TextField(
                  controller: groupCapCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.setupCapacity,
                    helperText: l10n.setupGroupCapacityHint,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.setupGroupLanguage,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final o in const [
                      (code: null, label: '—'),
                      (code: 'ko', label: '한국어'),
                      (code: 'en', label: 'English'),
                      (code: 'es', label: 'Español'),
                      (code: 'pt', label: 'Português'),
                    ])
                      ChoiceChip(
                        label: Text(
                          o.code == null ? l10n.setupAnyLanguage : o.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: lang == o.code,
                        onSelected: (_) => setLocal(() => lang = o.code),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    await ApiClient.updateGroup(programId, group['id'] as String, {
      'name': nameCtrl.text.trim(),
      'leaderName': leaderCtrl.text.trim(),
      'leaderPhone': phoneCtrl.text.trim(),
      'passage': passageCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
      // 빈 문자열은 "정하지 않음" 이다 — 서버가 그렇게 읽는다.
      'studyLanguage': lang ?? '',
      'capacity': groupCapCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(groupCapCtrl.text.trim()),
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
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
