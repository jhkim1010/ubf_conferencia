import 'package:flutter/material.dart';
import '../../../core/constants/admin_scopes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/api_client.dart';
import '../providers/program_provider.dart';

// 이 수양회를 관리할 사람.
//
// 예전에는 director 만 부를 수 있는 API 뿐이었고 화면이 아예 없었다. 그래서
// 수양회를 만든 사람은 명단을 함께 볼 사람을 세울 방법이 없었다.
//
// 만든 사람도 목록에 함께 보여 준다. 이 화면은 "누가 이 수양회를 볼 수
// 있는가" 를 보여 주는 것이지 program_admins 표를 보여 주는 것이 아니다.
class ProgramAdminsScreen extends ConsumerStatefulWidget {
  final String programId;

  const ProgramAdminsScreen({super.key, required this.programId});

  @override
  ConsumerState<ProgramAdminsScreen> createState() =>
      _ProgramAdminsScreenState();
}

class _ProgramAdminsScreenState extends ConsumerState<ProgramAdminsScreen> {
  bool _busy = false;

  void _refresh() => ref.invalidate(programAdminsProvider(widget.programId));

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _add(Map<String, dynamic> body, String name) async {
    // await 뒤에서 context 를 다시 찾지 않는다. 그 사이 화면이 닫혔을 수 있다.
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final r = await ApiClient.addProgramAdmin(widget.programId, body);
      _refresh();
      _snack(l10n.admAdded('${r['name'] ?? name}'));
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 참가자 명단에서 고른다. 이메일을 몰라도 되고, 오타로 엉뚱한 사람을
  /// 세울 일이 없다.
  Future<void> _addFromRoster(List<dynamic> current) async {
    final l10n = AppLocalizations.of(context)!;
    final regs = await ref.read(
      programRegistrationsProvider(widget.programId).future,
    );
    if (!mounted) return;

    final taken = current
        .cast<Map<String, dynamic>>()
        .map((a) => a['id'])
        .toSet();
    final candidates = regs
        .cast<Map<String, dynamic>>()
        .where((r) => !taken.contains(r['user_id']))
        .toList();

    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.admPickPerson),
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
    if (picked == null || !mounted) return;
    await _add({
      'registrationId': picked['id'],
    }, '${picked['real_name'] ?? ''}');
  }

  /// 아직 등록하지 않은 사람은 이메일로. 구글 로그인에 쓰는 주소여야 한다 —
  /// 한 번도 로그인한 적이 없으면 계정 자체가 없다.
  Future<void> _addByEmail() async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.admByEmail),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.admEmailLabel,
            hintText: 'nombre@gmail.com',
          ),
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
    if (ok != true || !mounted) return;
    final email = ctrl.text.trim();
    if (email.isEmpty) return;
    await _add({'email': email}, email);
  }

  /// 맡은 분야를 한 줄로. 전부면 그렇게 적는다.
  String _scopeLine(AppLocalizations l10n, Map<String, dynamic> a) {
    final mine = scopesOf(a['scopes']);
    if (mine == null) return l10n.scopeAll;
    return adminScopes
        .where((s) => mine.contains(s.key))
        .map((s) => s.label(l10n))
        .join(' · ');
  }

  /// 분야 고르기. 저장하면 그 사람에게 텔레그램으로 알린다(서버가 보낸다).
  Future<void> _editScopes(Map<String, dynamic> a) async {
    final l10n = AppLocalizations.of(context)!;
    final start = scopesOf(a['scopes']);
    final picked = <String>{...(start ?? const <String>{})};
    var all = start == null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text(l10n.scopeTitle),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: all,
                    onChanged: (v) => setInner(() {
                      all = v ?? false;
                      if (all) picked.clear();
                    }),
                    title: Text(l10n.scopeAll),
                    subtitle: Text(
                      l10n.scopeAllHint,
                      style: const TextStyle(fontSize: 12),
                    ),
                    dense: true,
                  ),
                  const Divider(),
                  for (final sc in adminScopes)
                    CheckboxListTile(
                      // "모든 결정" 을 고르면 낱개는 고를 것이 없다.
                      value: all || picked.contains(sc.key),
                      onChanged: all
                          ? null
                          : (v) => setInner(() {
                              if (v == true) {
                                picked.add(sc.key);
                              } else {
                                picked.remove(sc.key);
                              }
                            }),
                      secondary: Icon(sc.icon, size: 20),
                      title: Text(sc.label(l10n)),
                      subtitle: Text(
                        sc.hint(l10n),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      dense: true,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              // 하나도 안 고르고 저장하면 아무 화면도 못 보는 사람이 된다.
              onPressed: all || picked.isNotEmpty
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ApiClient.setAdminScopes(
        widget.programId,
        a['id'] as String,
        all ? const [] : picked.toList(),
      );
      ref.invalidate(programAdminsProvider(widget.programId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.scopeSaved)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> admin) async {
    final l10n = AppLocalizations.of(context)!;
    final name = '${admin['name'] ?? admin['email'] ?? ''}';
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.admRemoveAsk(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.admRemove),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    try {
      await ApiClient.removeProgramAdmin(
        widget.programId,
        admin['id'] as String,
      );
      _refresh();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(programAdminsProvider(widget.programId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.admTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (admins) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              l10n.admSubtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            for (final a in admins.cast<Map<String, dynamic>>())
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    a['is_owner'] == true
                        ? Icons.workspace_premium
                        : Icons.person_outline,
                    color: a['is_owner'] == true ? Colors.amber[800] : null,
                  ),
                  title: Text('${a['name'] ?? a['email'] ?? ''}'),
                  subtitle: Text(
                    a['is_owner'] == true
                        ? '${a['email'] ?? ''} · ${l10n.admOwner}'
                        // 맡은 분야를 여기 적는다(059). 안 적으면 세워 놓고도
                        // 누가 무엇을 맡았는지 알 수 없다.
                        : '${a['email'] ?? ''}\n${_scopeLine(l10n, a)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: a['is_owner'] != true,
                  onTap: a['is_owner'] == true || _busy
                      ? null
                      : () => _editScopes(a),
                  // 만든 사람은 뺄 수 없다. 빼고 나면 아무도 관리자를 세울
                  // 수 없어 수양회가 잠긴다.
                  trailing: a['is_owner'] == true
                      ? Tooltip(
                          message: l10n.admOwnerLocked,
                          child: const Icon(Icons.lock_outline, size: 18),
                        )
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: l10n.admRemove,
                          onPressed: _busy ? null : () => _remove(a),
                        ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : () => _addFromRoster(admins),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: Text(l10n.admAdd),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _addByEmail,
              icon: const Icon(Icons.alternate_email, size: 18),
              label: Text(l10n.admByEmail),
            ),
          ],
        ),
      ),
    );
  }
}
