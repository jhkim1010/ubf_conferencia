import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/api_client.dart';
import '../../assignment/providers/assignment_provider.dart';
import '../../setup/providers/setup_provider.dart';
import '../../../core/utils/service_role_label.dart';

// 공지 보내기 (044)
//
// 알림을 보낼 길이 일정 알림(자동)과 봉사 도움 요청(043)뿐이었다.
// "302호 물이 안 나옵니다", "3조는 강당 앞으로" 같은 말은 전할 데가 없어
// 단톡방으로 나가고, 앱에만 등록하고 단톡방에 없는 사람에게는 닿지 않는다.
//
// 받는 사람을 좁힐 수 있어야 한다 — 전체에게만 보낼 수 있으면, 한 방에
// 할 말도 전원을 울리게 된다.
class AnnounceScreen extends ConsumerStatefulWidget {
  final String programId;

  const AnnounceScreen({super.key, required this.programId});

  @override
  ConsumerState<AnnounceScreen> createState() => _AnnounceScreenState();
}

class _AnnounceScreenState extends ConsumerState<AnnounceScreen> {
  final _bodyCtrl = TextEditingController();
  String _kind = 'all';
  String? _targetId;
  String _targetName = '';
  bool _busy = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  /// 방·조를 고르지 않은 채로는 보내지 않는다. 서버도 막지만, 화면에서
  /// 먼저 막아야 담당자가 "왜 안 가지" 를 겪지 않는다.
  bool get _ready {
    if (_bodyCtrl.text.trim().isEmpty) return false;
    if (_kind == 'room' || _kind == 'group' || _kind == 'service') {
      return _targetId != null;
    }
    return true;
  }

  Future<void> _pickTarget(String kind) async {
    final l10n = AppLocalizations.of(context)!;
    // 봉사팀은 역할이 대상이다 — 방·조와 달리 id 가 UUID 가 아니라 역할
    // 키다(pickup, custom:… ). 사람이 아무도 없는 역할도 고를 수 있게
    // 남겨 둔다: 지금 아무도 없다는 것도 보내 봐야 아는 일이다.
    final List<Map<String, dynamic>> items;
    if (kind == 'room') {
      items =
          ((await ref.read(roomsProvider(widget.programId).future))['rooms']
                      as List? ??
                  const [])
              .cast<Map<String, dynamic>>();
    } else if (kind == 'group') {
      items =
          ((await ref.read(groupsProvider(widget.programId).future))['groups']
                      as List? ??
                  const [])
              .cast<Map<String, dynamic>>();
    } else {
      final board = await ref.read(
        serviceBoardProvider(widget.programId).future,
      );
      items = ((board?['roles'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
    }
    if (!mounted) return;

    String label(Map<String, dynamic> it) => kind == 'service'
        ? serviceRoleLabel(l10n, it)
        : '${it['floor'] ?? ''} ${it['name'] ?? ''}'.trim();

    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(switch (kind) {
          'room' => l10n.annPickRoom,
          'group' => l10n.annPickGroup,
          _ => l10n.annPickService,
        }),
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.tblEmpty),
            ),
          for (final it in items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, it),
              child: Row(
                children: [
                  Expanded(child: Text(label(it))),
                  if (kind == 'service')
                    Text(
                      l10n.unitPeople(
                        ((it['people'] as List?) ?? const []).length,
                      ),
                      style: const TextStyle(fontSize: 11.5),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() {
      _kind = kind;
      // 봉사팀은 역할 키가 대상이다.
      _targetId = (kind == 'service' ? picked['key'] : picked['id']) as String;
      _targetName = label(picked);
    });
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final r = await ApiClient.sendAnnouncement(
        widget.programId,
        body: _bodyCtrl.text.trim(),
        audienceKind: _kind,
        audienceId: _targetId,
      );
      _bodyCtrl.clear();
      ref.invalidate(announcementsProvider(widget.programId));
      _snack(l10n.annSent(((r['recipients'] ?? 0) as num).toInt()));
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
    'room' => l10n.annToRoom,
    'group' => l10n.annToGroup,
    'unsubmitted' => l10n.annToUnsub,
    'unpaid' => l10n.annToUnpaid,
    'service' => l10n.annToService,
    _ => l10n.annToAll,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final past = ref.watch(announcementsProvider(widget.programId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.annTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.annSubtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.annTo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final kind in const [
                'all',
                'room',
                'group',
                'service',
                'unsubmitted',
                'unpaid',
              ])
                ChoiceChip(
                  label: Text(
                    kind == _kind && _targetName.isNotEmpty
                        ? _targetName
                        : _kindLabel(l10n, kind),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  selected: _kind == kind,
                  onSelected: (_) {
                    if (kind == 'room' ||
                        kind == 'group' ||
                        kind == 'service') {
                      _pickTarget(kind);
                    } else {
                      setState(() {
                        _kind = kind;
                        _targetId = null;
                        _targetName = '';
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.annBody,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy || !_ready ? null : _send,
              icon: const Icon(Icons.send, size: 18),
              label: Text(l10n.annSend),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.annPast,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          past.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(l10n.commonErrorDetail('$e')),
            data: (rows) {
              if (rows.isEmpty) {
                return Text(
                  l10n.annNoneYet,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                );
              }
              return Column(
                children: [
                  for (final a in rows.cast<Map<String, dynamic>>())
                    Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          '${a['body'] ?? ''}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          [
                            _kindLabel(l10n, '${a['audience_kind']}'),
                            // 보낼 당시 몇 대에 갔는지. 지금 다시 세면
                            // 사람이 바뀌어 있다.
                            l10n.annSent(
                              ((a['recipients'] ?? 0) as num).toInt(),
                            ),
                            '${a['sent_at'] ?? ''}'
                                .replaceAll('T', ' ')
                                .split('.')[0],
                          ].join(' · '),
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
