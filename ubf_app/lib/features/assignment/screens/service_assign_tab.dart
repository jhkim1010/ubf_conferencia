import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/service_role_label.dart';
import '../../program/providers/program_provider.dart';
import '../providers/assignment_provider.dart';
import '../widgets/split_board.dart';

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
        final people = ((data?['volunteers'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();

        // 자원자 명단과 역할 현황은 **같이 봐야 하는 것**이다. 누구를 어디에
        // 넣을지 정하는 일이기 때문이다. 한 줄로 쌓아 두면 자원자를 보려고
        // 위로, 역할을 보려고 아래로 오가야 한다.
        //
        // 폰에서는 나눌 너비가 없으므로 예전처럼 쌓는다.
        return LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 900) {
              return RefreshIndicator(
                onRefresh: () async => refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  children: [
                    _rolesButton(context, ref, roles, l10n),
                    const SizedBox(height: 12),
                    // 등록할 때 자원한 사람. 지금까지 이 정보가 어느 화면에도
                    // 나오지 않아, 누가 무엇을 할 수 있는지 알 길이 없었다.
                    _Volunteers(
                      programId: programId,
                      roles: roles,
                      onChanged: refresh,
                      people: people,
                    ),
                    ..._roleCards(roles, refresh, l10n),
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 왼쪽: 자원한 사람. 넓은 화면에서는 접어 둘 이유가 없다.
                SizedBox(
                  width: box.maxWidth < 1200 ? 340 : 400,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 6, 24),
                    children: [
                      _Volunteers(
                        programId: programId,
                        roles: roles,
                        onChanged: refresh,
                        people: people,
                        alwaysOpen: true,
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // 오른쪽: 역할별 현황.
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => refresh(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(6, 12, 12, 24),
                      children: [
                        _rolesButton(context, ref, roles, l10n),
                        const SizedBox(height: 12),
                        // 역할 카드는 높이가 제각각이다(사람이 없는 역할은
                        // 두 줄, 여섯 명이 든 역할은 여덟 줄). 한 줄에
                        // 하나씩 쌓으면 화면 절반이 빈 채로 남는다.
                        if (roles.isEmpty)
                          ..._roleCards(roles, refresh, l10n)
                        else
                          LayoutBuilder(
                            builder: (context, inner) => MasonryColumns(
                              columns: (inner.maxWidth / 320).floor().clamp(
                                1,
                                2,
                              ),
                              weights: [
                                for (final r in roles)
                                  2 +
                                      ((r['people'] as List?)?.length ?? 0)
                                          .toDouble(),
                              ],
                              children: [
                                for (final role in roles)
                                  _RoleCard(
                                    programId: programId,
                                    role: role,
                                    onChanged: refresh,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _rolesButton(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> roles,
    AppLocalizations l10n,
  ) => OutlinedButton.icon(
    onPressed: () => _editRoles(context, ref, roles),
    icon: const Icon(Icons.tune, size: 18),
    label: Text(l10n.svcEditRoles),
  );

  /// 아무도 없는 역할도 남긴다 — 사람이 없는 역할이 목록에서 사라지면,
  /// 그것이야말로 봐야 할 상황인데 보이지 않는다.
  List<Widget> _roleCards(
    List<Map<String, dynamic>> roles,
    VoidCallback refresh,
    AppLocalizations l10n,
  ) => [
    if (roles.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text(l10n.svcNobody)),
      ),
    for (final role in roles)
      _RoleCard(programId: programId, role: role, onChanged: refresh),
  ];

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
    final call = role['call'] as Map<String, dynamic>?;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 한 사람씩 지명하는 길뿐이면, 여섯 자리가 빈 역할은 여섯 번을
                // 찍어 물어야 한다. 전체에 한 번 청하고 손을 든 사람 중에서
                // 고르는 편이 빠르다.
                if (call != null && call['closed_at'] == null)
                  TextButton.icon(
                    icon: const Icon(Icons.campaign_outlined, size: 18),
                    label: Text(l10n.svcCallSent(short)),
                    onPressed: () => _closeCall(context, '${call['id']}'),
                  )
                else if (short > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.campaign_outlined, size: 18),
                    label: Text(l10n.svcCallSend),
                    onPressed: () => _sendCall(context),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: Text(l10n.svcNominate),
                  onPressed: () => _nominate(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCall(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.sendServiceCall(programId, role['key'] as String);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.svcCallDone)));
      }
    } on ApiException catch (e) {
      // 서버가 왜 못 보내는지 말해 준다. 아무 일도 안 일어나면 담당자는
      // 버튼이 고장 났다고 여긴다.
      final msg = switch (e.message) {
        'too_soon' => l10n.svcCallTooSoon,
        'already_filled' => l10n.svcCallFilled,
        'no_target' => l10n.svcCallNoTarget,
        _ => e.message,
      };
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _closeCall(BuildContext context, String callId) async {
    try {
      await ApiClient.closeServiceCall(programId, callId);
      onChanged();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
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
  /// 서버(service_roles.js MAX_ROLES)와 같은 수. 넘겨 보내면 서버가 자른다.
  static const _maxRoles = 30;

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
    final custom = [
      for (var i = 0; i < _rows.length; i++)
        if ((_rows[i]['key'] as String).startsWith('custom:')) i,
    ];
    final builtIn = [
      for (var i = 0; i < _rows.length; i++)
        if (!(_rows[i]['key'] as String).startsWith('custom:')) i,
    ];
    final on = _rows.where((r) => r['enabled'] == true).length;

    return AlertDialog(
      title: Text(l10n.svcRolesTitle),
      content: SizedBox(
        width: 460,
        child: ListView(
          shrinkWrap: true,
          children: [
            // 만들기를 맨 위에 둔다. 기본 역할 열세 개 밑에 있으면 스크롤을
            // 내려야 보이고, 그러면 없는 기능이나 마찬가지다.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.svcRoleCount(on, _maxRoles),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
                FilledButton.icon(
                  onPressed: on >= _maxRoles ? null : _addCustom,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.svcAddRole),
                ),
              ],
            ),
            if (on >= _maxRoles)
              Text(
                l10n.svcRoleFull(_maxRoles),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            if (custom.isNotEmpty) ...[
              const SizedBox(height: 10),
              _sectionLabel(l10n.svcSectionCustom),
              for (final i in custom) _roleRow(l10n, i, deletable: true),
            ],
            const SizedBox(height: 10),
            _sectionLabel(l10n.svcSectionBuiltIn),
            for (final i in builtIn) _roleRow(l10n, i),
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

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Colors.grey[700],
      ),
    ),
  );

  Widget _roleRow(AppLocalizations l10n, int i, {bool deletable = false}) {
    return Row(
      children: [
        Checkbox(
          value: _rows[i]['enabled'] == true,
          onChanged: (v) => setState(() => _rows[i]['enabled'] = v == true),
        ),
        Expanded(
          child: Text(
            serviceRoleLabel(l10n, _rows[i]),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Text(
          l10n.svcNeedShort,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 52,
          child: TextFormField(
            initialValue: '${_rows[i]['needed']}',
            keyboardType: TextInputType.number,
            textAlign: TextAlign.end,
            decoration: const InputDecoration(isDense: true),
            onChanged: (v) => _rows[i]['needed'] = int.tryParse(v.trim()) ?? 0,
          ),
        ),
        // 직접 만든 역할만 지운다. 기본 역할은 체크를 풀면 화면에서 빠진다.
        if (deletable)
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.svcDeleteRole,
            onPressed: () => setState(() => _rows.removeAt(i)),
          )
        else
          const SizedBox(width: 40),
      ],
    );
  }
}

/// 등록할 때 "할 수 있다" 고 적어 낸 사람들.
///
/// 역할 목록과 섞지 않는다 — 운전할 수 있다고 픽업 담당이 되는 것이 아니다.
/// 담당자가 보고 고르라고 보여 주는 것이다.
class _Volunteers extends StatefulWidget {
  final List<Map<String, dynamic>> people;
  final String programId;
  final List<Map<String, dynamic>> roles;
  final VoidCallback onChanged;

  /// 왼쪽 패널로 서 있을 때는 접지 않는다. 접을 수 있게 두면 패널이 통째로
  /// 빈 채로 남는다.
  final bool alwaysOpen;

  const _Volunteers({
    required this.people,
    required this.programId,
    required this.roles,
    required this.onChanged,
    this.alwaysOpen = false,
  });

  @override
  State<_Volunteers> createState() => _VolunteersState();
}

class _VolunteersState extends State<_Volunteers> {
  late bool _open = widget.alwaysOpen;

  /// 여기서 바로 맡긴다. 지금까지는 역할 카드를 열어 사람을 찾아야 했는데,
  /// 담당자가 보고 있는 것은 이 명단이다 — 보고 있는 자리에서 누르는 것이
  /// 맞다.
  ///
  /// 맡기는 것은 **부탁**이지 확정이 아니다. 본인이 수락해야 확정된다
  /// (서버의 invite). 그래서 이미 그 역할에 있는 사람에게는 다시 묻지
  /// 않는다.
  ///
  /// [hint] 는 누른 자원(운전·요리 …)이다. 어울리는 역할을 목록 맨 위로
  /// 올리는 데만 쓰고, 나머지 역할도 그대로 고를 수 있다.
  Future<void> _assign(Map<String, dynamic> person, {String? hint}) async {
    final l10n = AppLocalizations.of(context)!;
    final name = '${person['real_name'] ?? ''}';
    final regId = person['registration_id'] as String?;
    if (regId == null) return;

    // 이미 맡고 있는 역할은 뺀다. 남는 것이 없으면 고를 것도 없다.
    bool has(Map<String, dynamic> role) =>
        ((role['people'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .any((p) => p['registration_id'] == regId);

    final open = widget.roles.where((r) => !has(r)).toList();
    final suggested = hint == null ? null : suggestedRoleFor(hint);
    final offered = ((person['resources'] as List?) ?? const [])
        .map((r) => suggestedRoleFor('$r'))
        .whereType<String>()
        .toSet();
    // 누른 자원이 먼저, 그 다음이 적어 낸 것과 맞는 역할.
    int rank(Map<String, dynamic> r) =>
        r['key'] == suggested ? 0 : (offered.contains(r['key']) ? 1 : 2);
    open.sort((a, b) => rank(a).compareTo(rank(b)));

    // 여럿을 한 번에 고른다. 운전도 하고 요리도 하는 사람에게 둘을 따로
    // 물으면 대화상자를 두 번 열어야 하고, 알림도 따로 간다.
    //
    // 누른 자원이 있으면 그것만 미리 켜 둔다 — 나머지는 담당자가 정한다.
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        final chosen = <String>{?suggested};
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(l10n.svcAssignTo(name)),
            content: SizedBox(
              width: 360,
              child: open.isEmpty
                  ? Text(l10n.tblEmpty)
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final r in open)
                          CheckboxListTile(
                            dense: true,
                            value: chosen.contains(r['key']),
                            onChanged: (v) => setLocal(() {
                              if (v == true) {
                                chosen.add(r['key'] as String);
                              } else {
                                chosen.remove(r['key']);
                              }
                            }),
                            title: Text(
                              serviceRoleLabel(l10n, r),
                              style: const TextStyle(fontSize: 14),
                            ),
                            // 적어 낸 것과 맞는 역할은 곧바로 확정된다 —
                            // 자기가 하겠다고 한 일이기 때문이다(050).
                            // 그 밖의 역할은 본인에게 물어본다. 누르기
                            // 전에 어느 쪽인지 알아야 한다.
                            subtitle: Text(
                              offered.contains(r['key'])
                                  ? l10n.svcWillConfirm
                                  : l10n.svcWillAsk,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: offered.contains(r['key'])
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                // 아무것도 안 고른 채로 보내면 서버가 거절한다. 여기서 막는다.
                onPressed: chosen.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, chosen),
                child: Text(l10n.svcAskThem(chosen.length)),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null || picked.isEmpty || !mounted) return;

    try {
      await ApiClient.inviteToService(
        widget.programId,
        registrationId: regId,
        serviceKeys: picked.toList(),
      );
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.svcAsked(name))));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 패널로 서 있을 때는 아무도 자원하지 않았다는 것도 말해 줘야 한다.
    // 통째로 사라지면 왼쪽이 빈 칸으로 남아 무엇이 없는 것인지 알 수 없다.
    if (widget.people.isEmpty && !widget.alwaysOpen) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.emoji_people_outlined, size: 20),
            title: Text(
              l10n.svcOffered(widget.people.length),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text(
              l10n.svcOfferedNote,
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: widget.alwaysOpen
                ? null
                : Icon(_open ? Icons.expand_less : Icons.expand_more),
            onTap: widget.alwaysOpen
                ? null
                : () => setState(() => _open = !_open),
          ),
          if (widget.people.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                l10n.svcNobody,
                style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
              ),
            ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final p in widget.people)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 이름을 누르면 이 사람에게 맡길 일을 고른다.
                          InkWell(
                            onTap: () => _assign(p),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${p['real_name'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  [
                                    WorldCountries.display(
                                          p['country'] as String?,
                                        ) ??
                                        '',
                                    '${p['branch'] ?? ''}',
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.add_task,
                                  size: 15,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              // 자원 하나를 누르면 그것에 어울리는 역할이
                              // 목록 맨 위로 온다 — 운전을 눌렀으면 픽업.
                              for (final r
                                  in ((p['resources'] as List?) ?? const []))
                                ActionChip(
                                  label: Text(
                                    volunteerResourceLabel(l10n, '$r'),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () => _assign(p, hint: '$r'),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          if ('${p['note'] ?? ''}'.isNotEmpty)
                            Text(
                              '${p['note']}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
