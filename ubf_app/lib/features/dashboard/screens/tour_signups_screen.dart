import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/table_export.dart';
import '../../program/providers/program_provider.dart';

// 투어별 신청 상황.
//
// 대시보드의 "등록 완료" 카드를 대신한다. 완료 여부는 참가자 표 안에서 한
// 사람씩 보이므로 카드 하나를 통째로 쓸 일이 아니었고, 담당자가 급히 알아야
// 하는 것은 어느 투어가 얼마나 찼는가였다.
//
// 신청자가 없는 투어도 보여 준다. 아무도 신청하지 않은 투어가 목록에서
// 사라지면, 그것이야말로 담당자가 봐야 할 상황인데 보이지 않는다.
class TourSignupsScreen extends ConsumerStatefulWidget {
  final String programId;

  const TourSignupsScreen({super.key, required this.programId});

  @override
  ConsumerState<TourSignupsScreen> createState() => _TourSignupsScreenState();
}

class _TourSignupsScreenState extends ConsumerState<TourSignupsScreen> {
  bool _busy = false;

  /// 내보낼 표는 **투어 하나에 한 줄**이 아니라 신청자 한 줄씩이다.
  /// 명단을 받아 나눠 주려는 것이지 요약을 보려는 것이 아니다.
  /// 신청자가 없는 투어도 한 줄로 남긴다 — 빠지면 없는 줄 안다.
  List<List<String>> _rows(AppLocalizations l10n, List<dynamic> tours) {
    final out = <List<String>>[];
    var i = 0;
    for (final t in tours.cast<Map<String, dynamic>>()) {
      final people = (t['people'] as List?) ?? const [];
      if (people.isEmpty) {
        out.add(['${++i}', '${t['name'] ?? ''}', l10n.tourNobody, '', '', '']);
        continue;
      }
      for (final p in people.cast<Map<String, dynamic>>()) {
        out.add([
          '${++i}',
          '${t['name'] ?? ''}',
          [
            p['real_name'] ?? '',
            if ((p['bible_name'] as String?)?.isNotEmpty ?? false)
              '(${p['bible_name']})',
          ].join(' '),
          WorldCountries.display(p['country'] as String?) ?? '',
          '${p['branch'] ?? ''}',
          p['submitted'] == true
              ? l10n.dashStatusDone
              : l10n.dashStatusInProgress,
        ]);
      }
    }
    return out;
  }

  Future<void> _export(
    bool pdf,
    String programName,
    List<String> headers,
    List<List<String>> rows,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final base = '${programName}_${l10n.tblTourSignups}';
      if (pdf) {
        await TableExport.sharePdf(
          fileBase: base,
          title: l10n.tblTourSignups,
          subtitle: '$programName · ${l10n.tblCount(rows.length)}',
          headers: headers,
          rows: rows,
          columnFlex: const [0.5, 2.2, 2.0, 1.3, 1.4, 1.1],
        );
      } else {
        await TableExport.shareExcel(
          fileBase: base,
          sheetName: l10n.tblTourSignups,
          headers: headers,
          rows: rows,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$programName · ${l10n.tblTourSignups}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tblExportFailed('$e')),
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
    final theme = Theme.of(context);
    final async = ref.watch(programTourSignupsProvider(widget.programId));

    final headers = [
      l10n.expColNo,
      l10n.colTour,
      l10n.summaryRealName,
      l10n.summaryCountry,
      l10n.summaryBranch,
      l10n.colStatus,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tblTourSignups)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (data) {
          final tours = (data?['tours'] as List?) ?? const [];
          final programName =
              ((data?['program'] as Map?)?['name'] as String?) ?? '';
          final currency = Currency.of(
            (data?['program'] as Map?)?['currency'] as String?,
          );
          final rows = _rows(l10n, tours);

          if (tours.isEmpty) {
            return Center(child: Text(l10n.tblEmpty));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _export(true, programName, headers, rows),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(l10n.tblExportPdf),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _export(false, programName, headers, rows),
                      icon: const Icon(Icons.table_view_outlined, size: 18),
                      label: Text(l10n.tblExportExcel),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _unfinishedColor(theme),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.tblUnfinishedNote,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: tours.length,
                  itemBuilder: (_, i) => _TourCard(
                    tour: tours[i] as Map<String, dynamic>,
                    currency: currency,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 아직 등록을 완료하지 않은 사람의 배경색. 어두운 화면에서도 읽혀야 하므로
/// 밝은 노랑을 그대로 쓰지 않는다.
Color _unfinishedColor(ThemeData theme) => theme.brightness == Brightness.dark
    ? const Color(0xFF3E3524)
    : const Color(0xFFFFF8E7);

class _TourCard extends StatelessWidget {
  final Map<String, dynamic> tour;
  final Currency currency;

  const _TourCard({required this.tour, required this.currency});

  static String _date(Object? v) {
    final s = '${v ?? ''}';
    return s.length >= 10 ? s.substring(0, 10) : '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final people = (tour['people'] as List?) ?? const [];
    final capacity = Money.parse(tour['capacity'])?.toInt();
    final signed = Money.parse(tour['signup_count'])?.toInt() ?? 0;
    final remaining = Money.parse(tour['remaining'])?.toInt();
    final isFull = capacity != null && signed >= capacity;

    final period = [
      _date(tour['start_date']),
      _date(tour['end_date']),
    ].where((s) => s.isNotEmpty).join(' ~ ');
    final deadline = _date(tour['signup_deadline']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${tour['name'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  // 정원이 없으면 "n / 제한 없음". 0 을 쓰면 다 찬 것으로 읽힌다.
                  capacity == null
                      ? '$signed · ${l10n.tourNoLimit}'
                      : '$signed / $capacity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isFull
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              [
                if (period.isNotEmpty) period,
                if (deadline.isNotEmpty) '${l10n.colDeadline} $deadline',
                if (remaining != null) '${l10n.colRemaining} $remaining',
                currency.format(Money.parse(tour['cost']) ?? 0),
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.tourSignupSummary(signed),
              style: const TextStyle(fontSize: 12),
            ),
            if (capacity != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: capacity == 0
                      ? 1
                      : (signed / capacity).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  color: isFull
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            if (people.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.tourNobody,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
              )
            else
              for (final p in people.cast<Map<String, dynamic>>())
                _PersonRow(person: p),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final Map<String, dynamic> person;

  const _PersonRow({required this.person});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final done = person['submitted'] == true;
    final where = [
      WorldCountries.display(person['country'] as String?) ?? '',
      '${person['branch'] ?? ''}',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      // 아직 완료하지 않은 사람은 배경으로 구분한다. 글자만 다르게 하면
      // 목록이 길어졌을 때 눈에 걸리지 않는다.
      color: done ? null : _unfinishedColor(theme),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              [
                person['real_name'] ?? '',
                if ((person['bible_name'] as String?)?.isNotEmpty ?? false)
                  '(${person['bible_name']})',
              ].join(' '),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (where.isNotEmpty)
            Text(
              where,
              style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
            ),
          const SizedBox(width: 8),
          Text(
            done ? l10n.dashStatusDone : l10n.dashStatusInProgress,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: done ? Colors.green[700] : Colors.orange[900],
            ),
          ),
        ],
      ),
    );
  }
}
