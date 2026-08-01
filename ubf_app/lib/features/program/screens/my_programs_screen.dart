import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/money.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final id = program['id'] as String;

    final start = (program['start_date'] as String?)?.split('T').first;
    final end = (program['end_date'] as String?)?.split('T').first;
    final count = Money.parse(program['registration_count'])?.toInt() ?? 0;
    final fees = [
      program['fee_basic'],
      program['fee_premium'],
    ].whereType<Object>().map((v) => Money.format(Money.parse(v))).join(' / ');

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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
