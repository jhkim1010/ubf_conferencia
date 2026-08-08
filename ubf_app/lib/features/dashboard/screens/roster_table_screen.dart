import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/table_export.dart';
import '../../program/providers/program_provider.dart';

/// 대시보드 카드에서 열리는 표. 카드마다 무엇을 보여 줄지가 다르다.
enum RosterView { all, submitted, meals, pendingPayment, arrival, paid }

// 카드의 숫자만으로는 아무것도 못 한다. 두 번 누르면 그 숫자가 누구인지
// 표로 보이고, 그대로 PDF·엑셀로 내보내 나눌 수 있다.
//
// 화면 하나가 여섯 카드를 모두 맡는다. 카드마다 화면을 만들면 열 개 중
// 하나만 고치는 일이 반드시 생긴다.
class RosterTableScreen extends ConsumerStatefulWidget {
  final String programId;
  final RosterView view;

  const RosterTableScreen({
    super.key,
    required this.programId,
    required this.view,
  });

  @override
  ConsumerState<RosterTableScreen> createState() => _RosterTableScreenState();
}

class _RosterTableScreenState extends ConsumerState<RosterTableScreen> {
  bool _busy = false;

  String _title(AppLocalizations l10n) => switch (widget.view) {
    RosterView.all => l10n.tblAllAttendees,
    RosterView.submitted => l10n.dashStatSubmitted,
    RosterView.meals => l10n.dashStatFoodRestriction,
    RosterView.pendingPayment => l10n.dashStatPendingPayment,
    RosterView.arrival => l10n.dashStatArrival,
    RosterView.paid => l10n.dashStatConfirmedPayment,
  };

  /// 식사 제한 판정은 서버(has_food_restriction, 027)와 같아야 한다.
  /// 다르면 카드의 숫자와 표의 줄 수가 어긋나 어느 쪽도 믿을 수 없다.
  static const _noneWords = {
    '없음',
    '없다',
    '무',
    '해당없음',
    '특이사항 없음',
    'none',
    'no',
    'nothing',
    'n/a',
    'na',
    'ninguno',
    'ninguna',
    'nada',
    'sin restricciones',
    '-',
    '--',
    '.',
    'x',
  };

  static bool _hasFood(Map<String, dynamic> r) {
    final v = (r['food_requirements'] as String?)?.trim() ?? '';
    return v.isNotEmpty && !_noneWords.contains(v.toLowerCase());
  }

  bool _keep(Map<String, dynamic> r) => switch (widget.view) {
    RosterView.all => true,
    RosterView.submitted => r['submitted'] == true,
    RosterView.meals => _hasFood(r),
    RosterView.pendingPayment => (r['payment'] as Map?)?['status'] == 'pending',
    RosterView.arrival => r['arrival_flight'] != null,
    RosterView.paid => (r['payment'] as Map?)?['status'] == 'confirmed',
  };

  List<String> _headers(AppLocalizations l10n) => [
    l10n.expColNo,
    l10n.summaryRealName,
    l10n.summaryCountry,
    l10n.summaryBranch,
    l10n.colGenderAge,
    switch (widget.view) {
      RosterView.meals => l10n.mealsRestriction,
      RosterView.arrival => l10n.colFlight,
      RosterView.pendingPayment || RosterView.paid => l10n.colPayment,
      _ => l10n.colStatus,
    },
  ];

  List<double> get _flex => switch (widget.view) {
    RosterView.meals => [0.5, 2.0, 1.3, 1.3, 0.9, 3.6],
    _ => [0.5, 2.2, 1.4, 1.5, 1.0, 2.0],
  };

  List<List<String>> _rows(
    AppLocalizations l10n,
    List<Map<String, dynamic>> data,
    Currency currency,
  ) {
    String last(Map<String, dynamic> r) {
      switch (widget.view) {
        case RosterView.meals:
          return [
            (r['food_requirements'] as String?) ?? '',
            if (r['skips_breakfast'] == true) '[${l10n.mealsSkipsBreakfast}]',
          ].where((s) => s.isNotEmpty).join('  ');
        case RosterView.arrival:
          final f = r['arrival_flight'] as Map<String, dynamic>?;
          if (f == null) return '';
          final when = '${f['scheduled_arrival'] ?? ''}';
          return [
            r['arrival_confirmed'] == true
                ? (f['flight_no'] ?? '')
                : l10n.expFlightEstimated,
            f['arrival_airport'] ?? '',
            when.length >= 16 ? when.substring(0, 16).replaceAll('T', ' ') : '',
          ].where((s) => '$s'.isNotEmpty).join(' · ');
        case RosterView.pendingPayment:
        case RosterView.paid:
          final amount = Money.parse((r['payment'] as Map?)?['amount']);
          return [
            amount == null ? '' : currency.format(amount),
            currency.format(Money.parse(r['total_cost']) ?? 0),
          ].where((s) => s.isNotEmpty).join(' / ');
        default:
          return r['submitted'] == true
              ? l10n.dashStatusDone
              : l10n.dashStatusInProgress;
      }
    }

    return [
      for (var i = 0; i < data.length; i++)
        [
          '${i + 1}',
          [
            data[i]['real_name'] ?? '',
            if ((data[i]['bible_name'] as String?)?.isNotEmpty ?? false)
              '(${data[i]['bible_name']})',
          ].join(' '),
          WorldCountries.display(data[i]['country'] as String?) ?? '',
          '${data[i]['branch'] ?? ''}',
          [
            data[i]['gender'] == 'M'
                ? l10n.genderMale
                : data[i]['gender'] == 'F'
                ? l10n.genderFemale
                : '',
            '${data[i]['age'] ?? ''}',
          ].where((s) => s.isNotEmpty).join(' / '),
          last(data[i]),
        ],
    ];
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
      final title = '$programName · ${_title(l10n)}';
      final base = '${programName}_${_title(l10n)}';
      if (pdf) {
        await TableExport.sharePdf(
          fileBase: base,
          title: _title(l10n),
          subtitle: '$programName · ${l10n.tblCount(rows.length)}',
          headers: headers,
          rows: rows,
          columnFlex: _flex,
        );
      } else {
        await TableExport.shareExcel(
          fileBase: base,
          sheetName: _title(l10n),
          headers: headers,
          rows: rows,
        );
      }
      if (mounted) {
        // 파일이 어디로 갔는지 알려 주지 않으면 안 만들어진 줄 안다.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(title)));
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
    final regsAsync = ref.watch(programRegistrationsProvider(widget.programId));
    final program = ref
        .watch(programByIdProvider(widget.programId))
        .valueOrNull;
    final programName = (program?['name'] as String?) ?? '';
    final currency = Currency.of(program?['currency'] as String?);

    return Scaffold(
      appBar: AppBar(title: Text(_title(l10n))),
      body: regsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (raw) {
          final data = raw.cast<Map<String, dynamic>>().where(_keep).toList()
            ..sort(
              (a, b) => '${a['country'] ?? ''}${a['real_name'] ?? ''}'
                  .compareTo('${b['country'] ?? ''}${b['real_name'] ?? ''}'),
            );
          final headers = _headers(l10n);
          final rows = _rows(l10n, data, currency);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tblCount(rows.length),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || rows.isEmpty
                          ? null
                          : () => _export(true, programName, headers, rows),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(l10n.tblExportPdf),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _busy || rows.isEmpty
                          ? null
                          : () => _export(false, programName, headers, rows),
                      icon: const Icon(Icons.table_view_outlined, size: 18),
                      label: Text(l10n.tblExportExcel),
                    ),
                  ],
                ),
              ),
              if (rows.isEmpty)
                Expanded(child: Center(child: Text(l10n.tblEmpty)))
              else
                // 표는 가로로 넓다. 화면 밖으로 밀리면 못 읽으므로 표만
                // 따로 가로 스크롤한다 — 화면 전체가 옆으로 밀리면 안 된다.
                Expanded(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          theme.colorScheme.surfaceContainerHighest,
                        ),
                        columns: [
                          for (final h in headers)
                            DataColumn(
                              label: Text(
                                h,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                        rows: [
                          for (final r in rows)
                            DataRow(
                              cells: [
                                for (final cell in r)
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                      ),
                                      child: Text(
                                        cell,
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
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
