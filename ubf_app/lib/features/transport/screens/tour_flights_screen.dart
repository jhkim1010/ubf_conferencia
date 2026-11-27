import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';

import '../../dashboard/screens/participant_editor.dart';
import '../../program/providers/program_provider.dart';
import '../../registration/widgets/tour_legs.dart';

/// 투어 이동 일정(081) — 담당자가 투어 날 공항 배차와 돌아오는 날 픽업을
/// **편 단위로** 잡는 화면.
///
/// 사람 단위로 늘어놓으면 같은 비행기를 타는 열두 명을 담당자가 눈으로
/// 묶어야 한다. 서버(services/tour_flights.js)가 같은 날 같은 편끼리 묶어
/// 주고, 여기서는 날짜별로 보여 준다. 이름을 누르면 그 사람을 연다.
class TourFlightsScreen extends ConsumerStatefulWidget {
  const TourFlightsScreen({super.key, required this.programId});
  final String programId;

  @override
  ConsumerState<TourFlightsScreen> createState() => _TourFlightsScreenState();
}

enum _Filter { all, out, back, direct }

class _TourFlightsScreenState extends ConsumerState<TourFlightsScreen> {
  _Filter _filter = _Filter.all;

  void _open(String registrationId) => openParticipantById(
    context,
    ref,
    programId: widget.programId,
    registrationId: registrationId,
    onChanged: () =>
        ref.invalidate(programTourFlightsProvider(widget.programId)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(programTourFlightsProvider(widget.programId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tfmTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(programTourFlightsProvider(widget.programId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (data) => _body(context, l10n, data ?? const {}),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> data,
  ) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final tours = ((data['tours'] as List?) ?? const []).whereType<Map>();
    String? tourName(Object? id) => tours
        .where((t) => '${t['id']}' == '$id')
        .map((t) => tourNameOf(t, lang))
        .firstOrNull;

    List<Map<String, dynamic>> list(Object? v) => ((v as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final groups = list(data['groups']);
    final direct = list(data['direct']);
    final missing = (data['missing'] as Map?) ?? const {};
    final missReturn = list(missing['return']);
    final missHome = list(missing['home']);
    final travelers = (data['travelers'] as num?)?.toInt() ?? 0;

    // 날짜별 묶음. 필터에 맞는 것만.
    final items = <({String? date, String? time, Widget card})>[];
    if (_filter != _Filter.direct) {
      for (final g in groups) {
        final kind = g['kind'];
        if (_filter == _Filter.out && kind != 'tour_out') continue;
        if (_filter == _Filter.back && kind != 'tour_return') continue;
        items.add((
          date: g['date'] as String?,
          time: g['time'] as String?,
          card: _GroupCard(
            group: g,
            tourName: tourName(g['tour_id']),
            onOpen: _open,
          ),
        ));
      }
    }
    if (_filter == _Filter.all || _filter == _Filter.direct) {
      for (final d in direct) {
        items.add((
          date: d['date'] as String?,
          time: null,
          card: _DirectCard(group: d, onOpen: _open),
        ));
      }
    }
    items.sort(
      (a, b) => '${a.date ?? '9999'} ${a.time ?? '99'}'.compareTo(
        '${b.date ?? '9999'} ${b.time ?? '99'}',
      ),
    );

    final children = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (f, label) in [
            (_Filter.all, l10n.tfmAll),
            (_Filter.out, l10n.tfKindOut),
            (_Filter.back, l10n.tfKindReturn),
            (_Filter.direct, l10n.tfmDirect),
          ])
            ChoiceChip(
              label: Text(label),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (missReturn.isNotEmpty || missHome.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1D6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF5C3800),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tfmMissing(
                        travelers,
                        missReturn.length,
                        missHome.length,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF5C3800),
                        height: 1.5,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFF5C3800),
                      ),
                      onPressed: () => _showMissing(missReturn, missHome),
                      child: Text(l10n.tfmShowNames),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            l10n.tfmEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
    ];
    String? lastDate = '';
    for (final it in items) {
      if (it.date != lastDate) {
        lastDate = it.date;
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              it.date == null ? l10n.tfmNoDate : tourLegDay(context, it.date),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      children.add(
        Padding(padding: const EdgeInsets.only(bottom: 10), child: it.card),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(programTourFlightsProvider(widget.programId)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          ),
        ),
      ),
    );
  }

  void _showMissing(
    List<Map<String, dynamic>> back,
    List<Map<String, dynamic>> home,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
        children: [
          for (final (title, people) in [
            (l10n.tfmMissingReturn, back),
            (l10n.tfmMissingHome, home),
          ])
            if (people.isNotEmpty) ...[
              ListTile(
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final p in people)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text('${p['name'] ?? l10n.commonNoName}'),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _open('${p['registration_id']}');
                  },
                ),
            ],
        ],
      ),
    );
  }
}

/// 같은 날 같은 편을 타는 사람들.
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.tourName,
    required this.onOpen,
  });
  final Map<String, dynamic> group;
  final String? tourName;
  final void Function(String registrationId) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final out = group['kind'] == 'tour_out';
    final back = group['kind'] == 'tour_return';
    final estimated = group['estimated'] == true;
    final heads = (group['heads'] as num?)?.toInt() ?? 0;
    final people = ((group['people'] as List?) ?? const []).whereType<Map>();
    final route = [
      '${group['from'] ?? ''}',
      '${group['to'] ?? ''}',
    ].where((s) => s.isNotEmpty).join(' → ');
    final headline = estimated
        ? l10n.tfmDateOnly
        : [
            '${group['time'] ?? ''}',
            route,
            '${group['flight_no'] ?? ''}',
          ].where((s) => s.isNotEmpty).join(' · ');

    final badgeColor = out || back ? tourLegColor : theme.colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estimated ? const Color(0xFFD9A441) : theme.dividerColor,
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: out ? badgeColor : badgeColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tourLegKindLabel(l10n, group['kind']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: out ? Colors.white : badgeColor,
                    ),
                  ),
                ),
                if (tourName != null)
                  Text(
                    tourName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (estimated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1D6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.tfNoTicket,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A4A00),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              headline.isEmpty ? '—' : headline,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Text(
          l10n.unitPeople(heads),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        children: [
          for (final p in people)
            ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline),
              title: Text('${p['name'] ?? l10n.commonNoName}'),
              subtitle: ((p['heads'] as num?)?.toInt() ?? 1) > 1
                  ? Text(l10n.unitPeople((p['heads'] as num).toInt()))
                  : null,
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: () => onOpen('${p['registration_id']}'),
            ),
        ],
      ),
    );
  }
}

/// 투어지에서 바로 집에 가는 사람들 — 픽업이 필요 없다.
class _DirectCard extends StatelessWidget {
  const _DirectCard({required this.group, required this.onOpen});
  final Map<String, dynamic> group;
  final void Function(String registrationId) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final people = ((group['people'] as List?) ?? const []).whereType<Map>();
    final airport = '${group['airport'] ?? ''}';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.tfmDirect,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.tfmDirectFrom(airport.isEmpty ? '—' : airport),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Text(
          l10n.unitPeople((group['heads'] as num?)?.toInt() ?? 0),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        children: [
          for (final p in people)
            ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline),
              title: Text('${p['name'] ?? l10n.commonNoName}'),
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: () => onOpen('${p['registration_id']}'),
            ),
        ],
      ),
    );
  }
}
