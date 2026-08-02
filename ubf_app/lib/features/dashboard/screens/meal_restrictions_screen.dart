import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/meal_pdf_service.dart';
import '../../program/providers/program_provider.dart';

// 식사 제한 명단 — 준비 현황의 식사 카드를 두 번 누르면 열린다.
//
// 카드의 숫자만으로는 장을 볼 수 없다. 누가 무엇을 못 먹는지 한 자리에서 보고,
// 그대로 주방에 넘길 수 있도록 PDF 한 장으로 합쳐 내려받는다.
class MealRestrictionsScreen extends ConsumerStatefulWidget {
  final String programId;
  const MealRestrictionsScreen({super.key, required this.programId});

  @override
  ConsumerState<MealRestrictionsScreen> createState() =>
      _MealRestrictionsScreenState();
}

class _MealRestrictionsScreenState
    extends ConsumerState<MealRestrictionsScreen> {
  bool _saving = false;

  Future<void> _download(Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await MealPdfService.export(data: data, l10n: l10n);
    } catch (e) {
      // 조용히 실패하면 담당자는 파일이 어딘가 저장된 줄 안다. 웹 공유 API
      // 미지원, 저장 공간 부족 등 실제로 실패하는 경로가 있다.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mealsDownloadFailed('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(programMealsProvider(widget.programId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mealsTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (data) {
          if (data == null) return Center(child: Text(l10n.commonError));
          final people = (data['people'] as List? ?? const [])
              .cast<Map<String, dynamic>>();
          final total = (data['total'] as int?) ?? 0;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(programMealsProvider(widget.programId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  l10n.mealsSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant_menu, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.mealsSummary(people.length, total),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (people.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text(l10n.mealsEmpty)),
                  )
                else
                  for (final p in people) _PersonTile(person: p),
              ],
            ),
          );
        },
      ),
      floatingActionButton: async.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : () => _download(async.valueOrNull!),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(l10n.mealsDownloadPdf),
            ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final Map<String, dynamic> person;
  const _PersonTile({required this.person});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bible = person['bible_name'] as String?;
    final where = [
      WorldCountries.display(person['country'] as String?) ?? '',
      (person['branch'] as String?) ?? '',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      (person['real_name'] as String?) ?? l10n.commonNoName,
                      if (bible != null && bible.isNotEmpty) '($bible)',
                    ].join(' '),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                // 아직 제출 전이면 내용이 더 바뀔 수 있다. 주방이 그대로 확정하지
                // 않도록 표시해 둔다.
                if (person['submitted'] != true)
                  _Chip(l10n.mealsNotSubmitted, theme.colorScheme.outline),
                if (person['skips_breakfast'] == true) ...[
                  const SizedBox(width: 6),
                  _Chip(l10n.mealsSkipsBreakfast, theme.colorScheme.tertiary),
                ],
              ],
            ),
            if (where.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                where,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              (person['food_requirements'] as String?) ?? '',
              style: const TextStyle(height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, color: color)),
  );
}
