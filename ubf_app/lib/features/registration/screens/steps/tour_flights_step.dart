import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';

import '../../providers/registration_provider.dart';
import '../../widgets/tour_legs.dart';

/// 투어 때 타는 비행기(081) — 여정을 위에서 아래로 한 줄로 보여 준다.
///
///   수양회에 오는 편 → 수양회 → 투어 가는 편 → 투어 → 돌아오는 편 → 집에 가는 편
///
/// 투어를 하는 사람은 수양회 뒤에 비행기를 한두 번 더 탄다. 도착·출발 두
/// 칸으로는 가운데를 적을 데가 없어서, 담당자가 투어 날 아침 공항 배차와
/// 돌아오는 날 밤 픽업을 메신저로 일일이 물어 짰다.
///
/// 오는 편과 집에 가는 편은 앞뒤 단계에서 적는다. 여기서는 보여 주기만 해서
/// 여정 전체를 한눈에 보게 한다 — 같은 값을 두 곳에서 고치게 하면 어느
/// 쪽이 맞는지 모르게 된다.
class TourFlightsStep extends ConsumerWidget {
  const TourFlightsStep({
    super.key,
    required this.programId,
    required this.program,
    required this.options,
    required this.flightStepsShown,
  });

  final String programId;
  final Map<String, dynamic> program;
  final List<Map<String, dynamic>> options;

  /// 도착·출발 단계가 있는가. 개최국 참가자는 없다(035) — 그때는 집에
  /// 가는 편 자리를 안 보인다.
  final bool flightStepsShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final form = ref.watch(registrationFormProvider(programId));
    final notifier = ref.read(registrationFormProvider(programId).notifier);
    final tours = pickedTours(options, form.selectedOptions);
    final hasCompanions =
        (ref.watch(myCompanionsProvider(programId)).valueOrNull ?? const [])
            .any((c) => c['registers_separately'] != true);
    final window = tourLegWindow(program, tours);
    final legs = form.tourFlights;
    final tourIds = tours.map((t) => '${t['id']}').toSet();

    String? nameOfTour(Object? id) {
      final t = tours.where((t) => '${t['id']}' == '$id').firstOrNull;
      return t == null ? null : tourNameOf(t, lang);
    }

    Future<void> edit({
      int? index,
      String kind = 'tour_out',
      String? tourId,
    }) async {
      final r = await showTourLegSheet(
        context,
        leg: index == null ? null : legs[index],
        initialKind: kind,
        initialTourId: tourId,
        tours: tours,
        hasCompanions: hasCompanions,
        first: window.first,
        last: window.last,
      );
      if (r == null) return;
      if (r.delete && index != null) {
        notifier.removeTourLeg(index);
      } else if (r.leg != null) {
        notifier.saveTourLeg(index, r.leg!);
      }
    }

    // 투어 하나에 딸린 구간. 투어가 하나뿐이면 tour_id 가 비어 있어도 그 투어다.
    bool belongs(Map<String, dynamic> l, String tourId) =>
        '${l['tour_id']}' == tourId ||
        (l['tour_id'] == null && tours.length == 1);
    Iterable<int> legsOf(String kind, String tourId) => [
      for (var i = 0; i < legs.length; i++)
        if (legs[i]['kind'] == kind && belongs(legs[i], tourId)) i,
    ];
    // 어느 투어에도 안 붙은 구간 — 기타, 또는 투어를 뺀 뒤 남은 것.
    final loose = [
      for (var i = 0; i < legs.length; i++)
        if (legs[i]['kind'] == 'other' ||
            (!(tours.length == 1 && legs[i]['tour_id'] == null) &&
                !tourIds.contains('${legs[i]['tour_id']}')))
          i,
    ];

    final rows = <Widget>[];

    // ── 수양회에 오는 편 ──
    if (flightStepsShown || form.arrivalFlight != null) {
      rows.add(
        _Row(
          dot: _Dot.plane(theme.colorScheme.primary),
          child: _FixedLeg(
            title: l10n.tfArrivalLeg,
            color: theme.colorScheme.primary,
            flight: form.arrivalFlight,
            timeKey: 'scheduled_arrival',
            airportKey: 'arrival_airport',
          ),
        ),
      );
    }
    // ── 수양회 ──
    rows.add(
      _Row(
        dot: _Dot.ring(theme.colorScheme.primary),
        child: _Node(
          name: '${program['name'] ?? ''}',
          period: tourPeriod(context, program),
        ),
      ),
    );

    for (var ti = 0; ti < tours.length; ti++) {
      final t = tours[ti];
      final id = '${t['id']}';
      final isLast = ti == tours.length - 1;
      // ── 투어 가는 편 ──
      final outs = legsOf('tour_out', id).toList();
      rows.add(
        _Row(
          dot: _Dot.plane(tourLegColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final i in outs) ...[
                TourLegCard(
                  leg: legs[i],
                  tourName: tourNameOf(t, lang),
                  onTap: () => edit(index: i),
                ),
                const SizedBox(height: 8),
              ],
              if (outs.isEmpty)
                TourLegAddButton(
                  label: '${l10n.tfAddOut} · ${tourNameOf(t, lang)}',
                  color: tourLegColor,
                  onPressed: () => edit(kind: 'tour_out', tourId: id),
                ),
            ],
          ),
        ),
      );
      // ── 투어 ──
      rows.add(
        _Row(
          dot: _Dot.ring(tourLegColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Node(name: tourNameOf(t, lang), period: tourPeriod(context, t)),
              if (isLast) ...[
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: SwitchListTile(
                    value: form.homeFromTour,
                    onChanged: notifier.setHomeFromTour,
                    title: Text(l10n.tfDirectHome),
                    subtitle: Text(l10n.tfDirectHomeSub),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      // ── 돌아오는 편 ──
      if (!form.homeFromTour) {
        final backs = legsOf('tour_return', id).toList();
        rows.add(
          _Row(
            dot: _Dot.plane(tourLegColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final i in backs) ...[
                  TourLegCard(
                    leg: legs[i],
                    tourName: tourNameOf(t, lang),
                    onTap: () => edit(index: i),
                  ),
                  const SizedBox(height: 8),
                ],
                if (backs.isEmpty)
                  TourLegAddButton(
                    label: l10n.tfAddReturn,
                    color: tourLegColor,
                    onPressed: () => edit(kind: 'tour_return', tourId: id),
                  ),
              ],
            ),
          ),
        );
      }
    }

    // ── 기타 구간 ──
    for (final i in loose) {
      rows.add(
        _Row(
          dot: _Dot.plane(theme.colorScheme.primary),
          child: TourLegCard(
            leg: legs[i],
            tourName: nameOfTour(legs[i]['tour_id']),
            onTap: () => edit(index: i),
          ),
        ),
      );
    }

    // ── 집에 가는 편 ──
    if (flightStepsShown || form.departureFlight != null) {
      rows.add(
        _Row(
          dot: _Dot.home(theme.colorScheme.primary),
          last: true,
          child: _FixedLeg(
            title: l10n.tfHomeLeg,
            color: theme.colorScheme.primary,
            flight: form.departureFlight,
            timeKey: 'scheduled_departure',
            airportKey: 'departure_airport',
            emptyText: form.homeFromTour
                ? l10n.tfHomeFromTourHint
                : l10n.tfHomeNextStep,
          ),
        ),
      );
    }

    final names = tours.map((t) => tourNameOf(t, lang)).join(', ');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(l10n.tfIntro(names), style: const TextStyle(height: 1.5)),
        ),
        const SizedBox(height: 16),
        ...rows,
        const SizedBox(height: 8),
        TourLegAddButton(
          label: l10n.tfAddOther,
          onPressed: () => edit(kind: 'other'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// 왼쪽 줄 + 점, 오른쪽 내용. 줄이 다음 줄과 이어져 하나의 여정이 된다.
class _Row extends StatelessWidget {
  const _Row({required this.dot, required this.child, this.last = false});
  final Widget dot;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).dividerColor;
    // IntrinsicHeight 로 줄 길이를 맞추면 안쪽의 SwitchListTile 높이를
    // 잘못 재어 넘친다(위젯 테스트에서 잡혔다). 줄은 Stack 으로 깐다 —
    // 내용 높이를 그대로 따라간다.
    return Stack(
      children: [
        if (!last)
          Positioned(
            left: 13,
            top: 14,
            bottom: 0,
            child: Container(width: 2, color: line),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 28, child: Center(child: dot)),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: child,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot._(this.color, this.icon, {this.filled = true});
  factory _Dot.plane(Color c) => _Dot._(c, Icons.flight);
  factory _Dot.home(Color c) => _Dot._(c, Icons.home_outlined, filled: false);
  factory _Dot.ring(Color c) => _Dot._(c, null);
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: color, width: 3),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Theme.of(context).colorScheme.surface,
        border: filled ? null : Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 16, color: filled ? Colors.white : color),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.name, required this.period});
  final String name;
  final String period;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (period.isNotEmpty)
            TextSpan(
              text: ' · $period',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    ),
  );
}

/// 앞뒤 단계에서 적은 편(오는 편·집에 가는 편)을 보여 주기만 한다.
class _FixedLeg extends StatelessWidget {
  const _FixedLeg({
    required this.title,
    required this.color,
    required this.flight,
    required this.timeKey,
    required this.airportKey,
    this.emptyText,
  });
  final String title;
  final Color color;
  final Map<String, dynamic>? flight;
  final String timeKey;
  final String airportKey;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = flight;
    final when = '${f?[timeKey] ?? ''}';
    final hasAny =
        f != null && (when.isNotEmpty || '${f['flight_no'] ?? ''}'.isNotEmpty);
    final line = !hasAny
        ? (emptyText ?? l10n.tfNotEntered)
        : [
            tourLegDay(context, when),
            if (when.length >= 16) when.substring(11, 16),
            '${f['flight_no'] ?? ''}',
            '${f[airportKey] ?? ''}',
          ].where((s) => s.isNotEmpty).join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              line,
              style: TextStyle(
                fontSize: hasAny ? 15 : 14,
                fontWeight: hasAny ? FontWeight.w600 : FontWeight.normal,
                color: hasAny ? null : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
