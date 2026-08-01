import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/api_client.dart';
import '../providers/program_provider.dart';

// 내 프로그램 관리
//
// 홈에 "내 프로그램 목록" 메뉴가 있었지만 이동 대상 라우트(/leader/programs)가
// 등록돼 있지 않아 눌러도 아무 일이 일어나지 않았다. 목록을 보여주는 데서 끝내지
// 않고 여기서 바로 수정·대시보드·준비 현황으로 갈 수 있게 한다.
class MyProgramsScreen extends ConsumerWidget {
  const MyProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(leaderProgramsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProgramsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/leader/create-program'),
        icon: const Icon(Icons.add),
        label: Text(l10n.homeCreateProgram),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.myProgramsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(leaderProgramsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: rows.length,
              itemBuilder: (_, i) =>
                  _ProgramCard(program: rows[i] as Map<String, dynamic>),
            ),
          );
        },
      ),
    );
  }
}

class _ProgramCard extends ConsumerWidget {
  final Map<String, dynamic> program;

  const _ProgramCard({required this.program});

  // 삭제. 행을 지우지 않고 비활성화한다 — 등록·배정·배차가 이 행을 참조한다.
  //
  // 등록자가 있으면 서버가 이름 확인을 요구한다(428). 그때만 입력을 받는다.
  // 아무도 등록하지 않은 수양회까지 이름을 치게 하면 실수를 막는 대신
  // 매번 성가시기만 하다.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final id = program['id'] as String;
    final name = program['name'] as String? ?? '';
    final messenger = ScaffoldMessenger.of(context);

    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        // 창이 낮으면 내용이 버튼 위로 겹쳐 그려진다. 실제로 겹쳤다.
        scrollable: true,
        title: Text(l10n.myProgramsDeleteTitle),
        content: Text(l10n.myProgramsDeleteBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.myProgramsDelete),
          ),
        ],
      ),
    );
    if (sure != true) return;

    Future<void> run(String? confirmName) async {
      await ApiClient.deleteProgram(id, confirmName: confirmName);
      ref.invalidate(leaderProgramsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.myProgramsDeleted)));
    }

    try {
      await run(null);
    } on ConfirmNameRequiredException catch (e) {
      if (!context.mounted) return;
      final typed = await showDialog<String>(
        context: context,
        builder: (_) => _ConfirmNameDialog(
          name: name,
          registrationCount: e.registrationCount,
        ),
      );
      if (typed == null) return;
      try {
        await run(typed);
      } catch (err) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.commonErrorDetail('$err')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.commonErrorDetail('$e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final id = program['id'] as String;

    final start = (program['start_date'] as String?)?.split('T').first;
    final end = (program['end_date'] as String?)?.split('T').first;
    final count = Money.parse(program['registration_count'])?.toInt() ?? 0;
    // 금액은 그 수양회의 통화로 찍는다. 인자를 빼면 Money.format 이 USD 로
    // 떨어져, ARS 로 만든 지역 수양회가 목록에서만 U$ 로 보인다.
    final currency = Currency.of(program['currency'] as String?);
    final fees = [program['fee_basic'], program['fee_premium']]
        .whereType<Object>()
        .map((v) => currency.format(Money.parse(v)))
        .join(' / ');

    // 부제는 있는 것만 붙인다. 빈 값을 ' · ' 로 이어 붙이면 구분자만 남는다.
    final meta = [
      program['location'],
      WorldCountries.display(program['host_country'] as String?),
      if (start != null) end != null && end != start ? '$start ~ $end' : start,
    ].where((v) => v != null && '$v'.isNotEmpty).join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              program['name'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meta.isNotEmpty) Text(meta),
                const SizedBox(height: 2),
                Text(
                  [
                    l10n.myProgramsRegistered(count),
                    if (fees.isNotEmpty) fees,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            isThreeLine: meta.isNotEmpty,
            onTap: () => context.push('/leader/program/$id/dashboard'),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.checklist, size: 18),
                  label: Text(l10n.rdyTitle),
                  onPressed: () =>
                      context.push('/leader/program/$id/readiness'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.space_dashboard_outlined, size: 18),
                  label: Text(l10n.dashTitle),
                  onPressed: () =>
                      context.push('/leader/program/$id/dashboard'),
                ),
                // 수정 후 돌아오면 목록의 이름·기간·참가비가 바뀌어 있어야 한다.
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.myProgramsEdit),
                  onPressed: () async {
                    await context.push('/leader/program/$id/edit');
                    ref.invalidate(leaderProgramsProvider);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.myProgramsDelete),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => _delete(context, ref, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 등록자가 있는 수양회를 지울 때만 뜬다. 이름을 그대로 입력해야 버튼이 열린다.
class _ConfirmNameDialog extends StatefulWidget {
  final String name;
  final int registrationCount;

  const _ConfirmNameDialog({
    required this.name,
    required this.registrationCount,
  });

  @override
  State<_ConfirmNameDialog> createState() => _ConfirmNameDialogState();
}

class _ConfirmNameDialogState extends State<_ConfirmNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = _controller.text.trim() == widget.name;

    return AlertDialog(
      // 입력칸이 취소·삭제 버튼과 겹치지 않도록. 창이 낮을 때 실제로 겹쳤다.
      scrollable: true,
      title: Text(l10n.myProgramsDeleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.myProgramsDeleteHasRegistrations(widget.registrationCount)),
          const SizedBox(height: 12),
          Text(
            widget.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.myProgramsDeleteTypeName,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: matches
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          child: Text(l10n.myProgramsDelete),
        ),
      ],
    );
  }
}
