import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/service_role_label.dart';
import '../../program/providers/program_provider.dart';
import '../providers/assignment_provider.dart';

// 봉사 담당자 배정 (039)
//
// 015 는 참가자가 신청하는 데까지만 있었고, 담당자가 그것을 보고 확정하는
// 쪽이 통째로 없었다. 신청을 받아도 아무도 볼 수 없었다.
//
// 역할을 카드로 늘어놓고 모자란 것부터 위에 둔다 — 담당자가 화면을 열자마자
// 무엇이 비었는지 봐야 한다. 아무도 없는 역할도 남긴다. 사람이 없는 역할이
// 목록에서 사라지면, 그것이야말로 봐야 할 상황인데 보이지 않는다.
class ServiceAssignTab extends ConsumerWidget {
  final String programId;

  const ServiceAssignTab({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(serviceBoardProvider(programId));
    void refresh() => ref.invalidate(serviceBoardProvider(programId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
      data: (data) {
        final roles = ((data?['roles'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              OutlinedButton.icon(
                onPressed: () => _editRoles(context, ref, roles),
                icon: const Icon(Icons.tune, size: 18),
                label: Text(l10n.svcEditRoles),
              ),
              const SizedBox(height: 12),
              if (roles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text(l10n.svcNobody)),
                ),
              for (final role in roles)
                _RoleCard(programId: programId, role: role, onChanged: refresh),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editRoles(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> roles,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _RoleConfigDialog(programId: programId, roles: roles),
    );
    if (saved == true) ref.invalidate(serviceBoardProvider(programId));
  }
}

/// 아직 답이 없는 사람의 배경색. 어두운 화면에서도 읽혀야 하므로 밝은
/// 노랑을 그대로 쓰지 않는다 — 참가자 표와 같은 색이다.
Color _waitingColor(ThemeData theme) => theme.brightness == Brightness.dark
    ? const Color(0xFF3E3524)
    : const Color(0xFFFFF8E7);

class _RoleCard extends ConsumerWidget {
  final String programId;
  final Map<String, dynamic> role;
  final VoidCallback onChanged;

  const _RoleCard({
    required this.programId,
    required this.role,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final people = ((role['people'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final needed = (role['needed'] as num?)?.toInt() ?? 0;
    final filled = (role['filled'] as num?)?.toInt() ?? 0;
    final short = (role['short'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    serviceRoleLabel(l10n, role),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  // 필요 인원을 안 정했으면 "n명 · 인원 미정". 0 으로 두면
                  // 모든 역할이 다 찬 것으로 보인다.
                  needed == 0
                      ? l10n.svcNoLimit(filled)
                      : l10n.svcNeeded(filled, needed),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: short > 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (short > 0)
              Text(
                l10n.svcShort(short),
                style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
              ),
            if (role['requires_approval'] == true)
              Text(
                l10n.svcNeedsApproval,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
              ),
            if (needed > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (filled / needed).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  color: short > 0
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            if (people.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l10n.svcNobody,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
              )
            else
              for (final p in people)
                _PersonRow(
                  programId: programId,
                  person: p,
                  onChanged: onChanged,
                ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(l10n.svcNominate),
                onPressed: () => _nominate(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _nominate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final regs = await ref.read(programRegistrationsProvider(programId).future);
    if (!context.mounted) return;

    // 이미 이 역할에 있는 사람은 다시 고를 수 없다.
    final already = ((role['people'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((p) => p['registration_id'])
        .toSet();
    final candidates = regs
        .cast<Map<String, dynamic>>()
        .where((r) => !already.contains(r['id']))
        .toList();

    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.svcPickPerson),
        children: [
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.tblEmpty),
            ),
          for (final r in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Row(
                children: [
                  Expanded(child: Text('${r['real_name'] ?? ''}')),
                  Text(
                    [
                      WorldCountries.display(r['country'] as String?) ?? '',
                      '${r['branch'] ?? ''}',
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;

    try {
      await ApiClient.inviteToService(
        programId,
        registrationId: picked['id'] as String,
        serviceKey: role['key'] as String,
      );
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.svcAsked('${picked['real_name']}'))),
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

class _PersonRow extends StatelessWidget {
  final String programId;
  final Map<String, dynamic> person;
  final VoidCallback onChanged;

  const _PersonRow({
    required this.programId,
    required this.person,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = person['status'] as String?;
    // 답을 기다리는 중인 사람만 노랗게. 확정도 거절도 배경을 쓰지 않는다 —
    // 전부 색을 입히면 무엇이 급한지 다시 안 보인다.
    final waiting = status == 'invited';
    final done = status == 'confirmed';
    final gone = status == 'rejected' || status == 'declined';

    Future<void> patch(Map<String, dynamic> body) async {
      try {
        await ApiClient.patchServiceSignup(
          programId,
          person['id'] as String,
          body,
        );
        onChanged();
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      }
    }

    return Container(
      color: waiting ? _waitingColor(theme) : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          if (person['is_lead'] == true)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.star, size: 15, color: Colors.amber[800]),
            ),
          Expanded(
            child: Text(
              '${person['real_name'] ?? ''}',
              style: TextStyle(
                fontSize: 13,
                // 빠진 사람은 흐리게. 지우지는 않는다 — 누구에게 이미
                // 부탁했다 거절당했는지가 다음에 부탁할 때 필요하다.
                color: gone ? Colors.grey : null,
                decoration: gone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            serviceStatusLabel(l10n, status),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: done
                  ? Colors.green[700]
                  : (gone ? Colors.grey : Colors.orange[900]),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (v) => switch (v) {
              'confirm' => patch({'action': 'confirm'}),
              'reject' => patch({'action': 'reject'}),
              _ => patch({'isLead': true}),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'confirm', child: Text(l10n.svcConfirm)),
              PopupMenuItem(value: 'reject', child: Text(l10n.svcReject)),
              if (person['is_lead'] != true)
                PopupMenuItem(value: 'lead', child: Text(l10n.svcSetLead)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 역할·필요 인원 구성 ─────────────────────────────────────────
class _RoleConfigDialog extends StatefulWidget {
  final String programId;
  final List<Map<String, dynamic>> roles;

  const _RoleConfigDialog({required this.programId, required this.roles});

  @override
  State<_RoleConfigDialog> createState() => _RoleConfigDialogState();
}

class _RoleConfigDialogState extends State<_RoleConfigDialog> {
  /// 기본 역할. 서버(service_roles.js)의 목록과 같은 차례로 둔다.
  static const _builtIn = [
    'special_song',
    'mc',
    'pickup',
    'cleaning',
    'tour_guide',
    'meal_prep',
    'lodging_backup',
    'registration_desk',
    'interpreter',
    'photo_video',
    'medical',
    'group_study_leader',
    'other',
  ];

  late List<Map<String, dynamic>> _rows;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 저장된 구성에 없는 기본 역할은 꺼진 상태로 함께 보여 준다 —
    // 목록에 없으면 켤 방법이 없다.
    final byKey = {for (final r in widget.roles) r['key'] as String: r};
    _rows = [
      for (final k in _builtIn)
        {
          'key': k,
          'enabled': byKey[k] != null,
          'needed': (byKey[k]?['needed'] as num?)?.toInt() ?? 0,
          'requires_approval':
              byKey[k]?['requires_approval'] ?? (k == 'group_study_leader'),
        },
      for (final r in widget.roles)
        if ((r['key'] as String).startsWith('custom:'))
          {
            'key': r['key'],
            'label': r['label'],
            'enabled': true,
            'needed': (r['needed'] as num?)?.toInt() ?? 0,
            'requires_approval': r['requires_approval'] == true,
          },
    ];
  }

  Future<void> _addCustom() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.svcAddRole),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.svcRoleName,
                hintText: l10n.svcRoleNameHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.svcNeedCount),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _rows.add({
        // 키는 앱이 만든다. 서버는 custom:<영숫자> 형태만 받는다.
        'key': 'custom:${DateTime.now().millisecondsSinceEpoch}',
        'label': name,
        'enabled': true,
        'needed': int.tryParse(countCtrl.text.trim()) ?? 0,
        'requires_approval': false,
      });
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ApiClient.saveServiceRoles(
        widget.programId,
        _rows.where((r) => r['enabled'] == true).toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.commonErrorDetail('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.svcEditRoles),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < _rows.length; i++)
              Row(
                children: [
                  Checkbox(
                    value: _rows[i]['enabled'] == true,
                    onChanged: (v) =>
                        setState(() => _rows[i]['enabled'] = v == true),
                  ),
                  Expanded(
                    child: Text(
                      serviceRoleLabel(l10n, _rows[i]),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      initialValue: '${_rows[i]['needed']}',
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (v) =>
                          _rows[i]['needed'] = int.tryParse(v.trim()) ?? 0,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addCustom,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.svcAddRole),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
