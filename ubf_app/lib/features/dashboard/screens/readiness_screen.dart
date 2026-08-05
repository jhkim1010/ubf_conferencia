import 'package:flutter/material.dart';
import '../../../core/utils/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../program/providers/program_provider.dart';
import '../../../core/constants/world_countries.dart';

// 준비 현황 화면 (A003)
//
// 기존 대시보드는 숫자를 보여준다. 이 화면은 "지금 무엇이 막혀 있고 누구에게
// 연락해야 하는가"를 보여준다.
//
// 상태는 색과 형태를 함께 쓴다 — 색만으로 구분하지 않는다.

class ReadinessScreen extends ConsumerWidget {
  final String programId;

  const ReadinessScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(programReadinessProvider(programId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rdyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer_outlined),
            tooltip: l10n.adDiscountTitle,
            onPressed: () =>
                context.push('/leader/program/$programId/discounts'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (data) {
          if (data == null) return Center(child: Text(l10n.commonError));
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(programReadinessProvider(programId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(program: data['program'] as Map<String, dynamic>?),
                const SizedBox(height: 20),
                _SectionTitle(l10n.rdySectionItems),
                const SizedBox(height: 10),
                _ReadinessGrid(
                  readiness: data['readiness'] as Map<String, dynamic>? ?? {},
                  programId: programId,
                ),
                const SizedBox(height: 24),
                _SectionTitle(l10n.rdySectionCohorts),
                const SizedBox(height: 10),
                _Cohorts(cohorts: data['cohorts'] as List<dynamic>? ?? []),
                const SizedBox(height: 24),
                _SectionTitle(l10n.rdySectionBlocked),
                const SizedBox(height: 10),
                _Blocked(rows: data['blocked'] as List<dynamic>? ?? []),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── 상태 표현 ────────────────────────────────────────────────
// 색만으로 구분하지 않도록 라벨을 함께 반환한다.

Color _statusColor(String? status) => switch (status) {
  'stop' => const Color(0xFFC62828),
  'warn' => const Color(0xFFB26A00),
  'ok' => const Color(0xFF2E7D32),
  _ => const Color(0xFF7A8697),
};

String _statusLabel(AppLocalizations l10n, String? status) => switch (status) {
  'stop' => l10n.rdyStatusStop,
  'warn' => l10n.rdyStatusWarn,
  'ok' => l10n.rdyStatusOk,
  _ => l10n.rdyStatusIdle,
};

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

// ─── 상단 ─────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Map<String, dynamic>? program;
  const _Header({this.program});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = program ?? {};
    final theme = Theme.of(context);
    final dday = p['d_day'] as int?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (p['name'] as String?) ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      p['location'],
                      p['start_date']?.toString().split('T').first,
                      WorldCountries.display(p['host_country'] as String?),
                    ].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.rdySubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (dday != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  dday >= 0 ? 'D-$dday' : 'D+${-dday}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 참가비를 못 고른 사람을 한 등급으로 맞춘다.
//
// 각자 다시 들어와 고르게 하는 것이 원칙이지만, 등급이 하나뿐이거나
// 대부분이 같은 등급이면 담당자가 한 번에 맞추는 편이 낫다.
// **이미 고른 사람은 건드리지 않는다** — 고급을 고른 사람을 기본으로
// 내리면 그 사람은 자기가 왜 싸졌는지 모른다.
Future<void> _showFeeBackfill(
  BuildContext context,
  String programId,
  Map<String, dynamic> fees,
) async {
  final l10n = AppLocalizations.of(context)!;
  final count = (fees['missing'] as int?) ?? 0;

  final tier = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.feeBackfillTitle(count),
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(l10n.feeBackfillWhy, style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text(
              l10n.feeBackfillAction,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'basic'),
                    child: Text(l10n.feeTierBasic),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'premium'),
                    child: Text(l10n.feeTierPremium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.actionCancel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (tier == null || !context.mounted) return;

  final label = tier == 'premium' ? l10n.feeTierPremium : l10n.feeTierBasic;
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(l10n.feeBackfillConfirm(count, label)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.actionConfirm),
        ),
      ],
    ),
  );
  if (yes != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    final n = await ApiClient.backfillFeeTier(programId, tier);
    messenger.showSnackBar(SnackBar(content: Text(l10n.feeBackfillDone(n))));
  } on ApiException catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.statusCode == 422 ? l10n.feeBackfillNotSet : e.message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ─── 준비 항목 ────────────────────────────────────────────────
class _ReadinessGrid extends StatelessWidget {
  final Map<String, dynamic> readiness;
  final String programId;
  const _ReadinessGrid({required this.readiness, required this.programId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Map<String, dynamic> at(String k) =>
        (readiness[k] as Map<String, dynamic>?) ?? const {};

    final lodging = at('lodging');
    final transport = at('transport');
    final flights = at('flights');
    final meals = at('meals');
    final payment = at('payment');
    final fees = at('fees');
    final roles = at('roles');

    final cards = <Widget>[
      _ItemCard(
        name: l10n.rdyLodging,
        status: lodging['status'] as String?,
        figure: '${lodging['needed'] ?? 0} / ${lodging['available'] ?? 0}',
        caption: l10n.unitPeople((lodging['needed'] as int?) ?? 0),
      ),
      _ItemCard(
        name: l10n.rdyTransport,
        status: transport['status'] as String?,
        figure: '${transport['needed'] ?? 0} / ${transport['available'] ?? 0}',
        caption: l10n.unitPeople((transport['needed'] as int?) ?? 0),
      ),
      _ItemCard(
        name: l10n.rdyFlights,
        status: flights['status'] as String?,
        figure: '${flights['missing'] ?? 0}',
        caption: l10n.unitPeople((flights['overseas_total'] as int?) ?? 0),
      ),
      // 식사 카드만 두 번 누르면 명단이 열린다. 숫자만으로는 장을 볼 수 없다 —
      // 누가 무엇을 못 먹는지 봐야 하고, 그것을 주방에 넘겨야 한다.
      _ItemCard(
        name: l10n.rdyMeals,
        status: meals['status'] as String?,
        figure: '${meals['restricted'] ?? 0}',
        caption: l10n.unitPeople((meals['total'] as int?) ?? 0),
        hint: l10n.mealsHint,
        onOpen: () => context.push('/leader/program/$programId/meals'),
      ),
      // 참가비 등급을 못 고른 사람. 참가비를 나중에 정하는 수양회가 많고,
      // 그 사이에 등록한 사람은 참가비 화면을 아예 못 본다.
      _ItemCard(
        name: l10n.rdyFeeTier,
        status: fees['status'] as String?,
        figure: '${fees['missing'] ?? 0}',
        caption: l10n.unitPeople((fees['total'] as int?) ?? 0),
        hint: ((fees['missing'] as int?) ?? 0) > 0 ? l10n.mealsHint : null,
        onOpen: ((fees['missing'] as int?) ?? 0) > 0
            ? () => _showFeeBackfill(context, programId, fees)
            : null,
      ),
      _ItemCard(
        name: l10n.rdyPayment,
        status: payment['status'] as String?,
        figure: '${payment['confirmed'] ?? 0} / ${payment['total'] ?? 0}',
        caption: l10n.unitCases((payment['pending'] as int?) ?? 0),
      ),
      _RolesCard(roles: roles),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth > 900
            ? 3
            : c.maxWidth > 560
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: cards,
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String name;
  final String? status;
  final String figure;
  final String caption;
  // 열 수 있는 카드만 준다. 없으면 예전 그대로 눌리지 않는 카드다.
  final VoidCallback? onOpen;
  final String? hint;

  const _ItemCard({
    required this.name,
    required this.status,
    required this.figure,
    required this.caption,
    this.onOpen,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _statusColor(status);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 3, color: color),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(
                      status: status,
                      label: _statusLabel(l10n, status),
                    ),
                  ],
                ),
                Text(
                  figure,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  hint ?? caption,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (onOpen == null) return Card(clipBehavior: Clip.antiAlias, child: body);

    // 두 번 누르면 열린다. 다만 그것만 두면 화면 낭독기 사용자와 마우스에
    // 익숙하지 않은 사람이 들어갈 길이 없다 — 길게 누르기도 같은 곳으로
    // 보내고, 카드 아래 문구로 그 사실을 적어 둔다.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '$name. ${hint ?? ''}',
        child: InkWell(onDoubleTap: onOpen, onLongPress: onOpen, child: body),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  final String label;
  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _RolesCard extends StatelessWidget {
  final Map<String, dynamic> roles;
  const _RolesCard({required this.roles});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = roles['status'] as String?;
    final breakdown = (roles['breakdown'] as Map<String, dynamic>?) ?? const {};
    final color = _statusColor(status);

    final parts = breakdown.entries
        .where((e) => e.key != 'unspecified')
        .map((e) => '${e.key} ${e.value}')
        .join(' · ');
    final unspecified = breakdown['unspecified'] as int? ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 3, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.rdyRoles,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _StatusBadge(
                        status: status,
                        label: _statusLabel(l10n, status),
                      ),
                    ],
                  ),
                  Text(
                    '${roles['total'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    // 미입력이 많으면 집계를 믿기 어렵다는 점을 알린다
                    status == 'warn'
                        ? l10n.rdyRolesUnreliable
                        : parts.isEmpty
                        ? '${l10n.rdyUnspecified} $unspecified'
                        : parts,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 국내 · 해외 코호트 ───────────────────────────────────────
class _Cohorts extends StatelessWidget {
  final List<dynamic> cohorts;
  const _Cohorts({required this.cohorts});

  @override
  Widget build(BuildContext context) {
    if (cohorts.isEmpty) {
      return const _Empty();
    }
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 640;
        final items = cohorts
            .map((e) => _CohortCard(data: e as Map<String, dynamic>))
            .toList();
        if (!wide) {
          return Column(
            children: [
              for (final w in items) ...[w, const SizedBox(height: 10)],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(child: items[i]),
              if (i != items.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _CohortCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CohortCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final domestic = data['kind'] == 'domestic';
    final steps = (data['steps'] as Map<String, dynamic>?) ?? const {};
    final total = (data['total'] as int?) ?? 0;
    final color = domestic ? const Color(0xFF00695C) : const Color(0xFF4527A0);

    final rows = <(String, int?)>[
      (l10n.rdyStuckPersonal, steps['personal'] as int?),
      (l10n.rdyStuckMeals, steps['meals'] as int?),
      (l10n.rdyStuckFlight, steps['flight'] as int?),
      (l10n.rdyStuckLodging, steps['lodging'] as int?),
      (l10n.summarySubmit, steps['submitted'] as int?),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    domestic
                        ? '${l10n.rdyDomestic} · ${WorldCountries.display(data['country'] as String?) ?? ''}'
                        : '${l10n.rdyOverseas} · ${data['countries'] ?? 0}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.unitPeople(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final (label, value) in rows) ...[
              _StepRow(label: label, value: value, total: total, color: color),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final int? value;
  final int total;
  final Color color;

  const _StepRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // null 은 0 이 아니라 "해당 없음"이다 — 개최국 참석자의 항공편이 그렇다.
    final skipped = value == null;
    final ratio = (!skipped && total > 0)
        ? (value! / total).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: Text(
            skipped ? l10n.rdySkipped : '$value/$total',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              color: skipped ? Colors.grey[500] : null,
              fontStyle: skipped ? FontStyle.italic : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 연락이 필요한 사람 ───────────────────────────────────────
class _Blocked extends StatelessWidget {
  final List<dynamic> rows;
  const _Blocked({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (rows.isEmpty) return _Empty(message: l10n.rdyNoBlocked);

    String stuckLabel(String? key) => switch (key) {
      'personal' => l10n.rdyStuckPersonal,
      'meals' => l10n.rdyStuckMeals,
      'flight' => l10n.rdyStuckFlight,
      'lodging' => l10n.rdyStuckLodging,
      _ => l10n.rdyStuckPayment,
    };

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Builder(
              builder: (context) {
                final r = rows[i] as Map<String, dynamic>;
                final domestic = r['kind'] == 'domestic';
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: (domestic
                        ? const Color(0xFF00695C)
                        : const Color(0xFF4527A0)),
                    child: Text(
                      ((r['name'] as String?) ?? '?').characters.first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    (r['name'] as String?) ?? l10n.commonNoName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      WorldCountries.display(r['country'] as String?),
                      r['branch'],
                    ].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(
                        status: 'warn',
                        label: stuckLabel(r['stuck_at'] as String?),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r['stalled_days'] ?? 0}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String? message;
  const _Empty({this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message ?? l10n.dashNoStats,
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
