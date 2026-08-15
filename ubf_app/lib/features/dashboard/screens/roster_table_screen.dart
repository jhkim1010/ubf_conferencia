import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/payment_state.dart';
import '../../../core/utils/table_export.dart';
import '../../program/providers/program_provider.dart';

/// 대시보드 카드에서 열리는 표. 카드마다 무엇을 보여 줄지가 다르다.
enum RosterView { all, meals, payments, arrival }

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
    RosterView.meals => l10n.dashStatFoodRestriction,
    RosterView.payments => l10n.tblPayments,
    RosterView.arrival => l10n.dashStatArrival,
  };

  /// 이 줄이 "끝난" 줄인가. 크림색을 입힐지 정한다.
  bool _done(Map<String, dynamic> r) => switch (widget.view) {
    RosterView.payments => (r['payment'] as Map?)?['status'] == 'confirmed',
    _ => r['submitted'] == true,
  };

  bool _keep(Map<String, dynamic> r) => switch (widget.view) {
    RosterView.all => true,
    // 식사 제한은 여기서 거르지 않는다 — 서버가 걸러 준 명단을 그대로 쓴다.
    RosterView.meals => true,
    // 입금 현황은 전원을 보여 준다 — 아직 낸 적이 없는 사람이야말로
    // 담당자가 봐야 할 줄이다.
    RosterView.payments => true,
    RosterView.arrival => r['arrival_flight'] != null,
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
      RosterView.payments => l10n.colPayment,
      _ => l10n.colStatus,
    },
    // 전체 명단에서는 입금도 한 칸으로 본다. 돈은 담당자가 가장 자주
    // 확인하는 것인데 지금까지 다른 표로 넘어가야 보였다.
    if (widget.view == RosterView.all) l10n.colPayment,
  ];

  List<double> get _flex => switch (widget.view) {
    RosterView.meals => [0.5, 2.0, 1.3, 1.3, 0.9, 3.6],
    RosterView.all => [0.5, 2.2, 1.4, 1.5, 1.0, 1.2, 2.0],
    _ => [0.5, 2.2, 1.4, 1.5, 1.0, 2.0],
  };

  /// 아직 등록을 완료하지 않은 사람의 배경색. 어두운 화면에서도 읽혀야
  /// 하므로 밝은 노랑을 그대로 쓰지 않는다.
  static Color _unfinishedColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? const Color(0xFF3E3524)
      : const Color(0xFFFFF8E7);

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
        case RosterView.payments:
          // 낸 돈 / 낼 돈 에 상태를 붙인다. 표에는 전원이 나오므로
          // 아직 못 받은 사람이 누구인지가 한 칸에 보여야 한다.
          final amount = Money.parse((r['payment'] as Map?)?['amount']);
          final status = switch ((r['payment'] as Map?)?['status']) {
            'confirmed' => l10n.dashPayConfirmed,
            'pending' => l10n.dashPayPending,
            _ => l10n.dashPayNone,
          };
          return [
            status,
            [
              amount == null ? '' : currency.format(amount),
              currency.format(Money.parse(r['total_cost']) ?? 0),
            ].where((s) => s.isNotEmpty).join(' / '),
          ].where((s) => s.isNotEmpty).join(' · ');
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
            // 이 공동체에서 서로 부르는 이름이 먼저다(049). 본명은 괄호
            // 안에 남긴다 — 여권·항공권을 맞출 때 그것이 필요하다.
            () {
              final bible = '${data[i]['bible_name'] ?? ''}'.trim();
              final legal = '${data[i]['real_name'] ?? ''}'.trim();
              // 적을 것이 없어 '-' 만 넣어 둔 사람이 있다.
              final hasBible = bible
                  .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')
                  .isNotEmpty;
              if (!hasBible) return legal;
              if (legal.isEmpty) return bible;
              return '$bible ($legal)';
            }(),
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
          if (widget.view == RosterView.all) _payCell(l10n, data[i], currency),
        ],
    ];
  }

  /// 입금 한 칸: "부분납금 · 50 / 200".
  ///
  /// 상태만 적으면 얼마가 남았는지 모르고, 금액만 적으면 확인 전인지
  /// 아닌지를 모른다.
  String _payCell(
    AppLocalizations l10n,
    Map<String, dynamic> r,
    Currency currency,
  ) {
    final pay = (r['payment'] as Map?) ?? const {};
    final due = Money.parse(r['amount_due']) ?? 0;
    final paid = Money.parse(pay['amount']) ?? 0;
    final state = payStateOf(
      due: due,
      paid: paid,
      status: pay['status'] as String?,
    );
    return [
      payStateLabel(l10n, state),
      if (due > 0) '${currency.format(paid)} / ${currency.format(due)}',
    ].join(' · ');
  }

  /// 한 사람의 등록 완료 여부와 입금을 그 자리에서 고친다.
  ///
  /// 현금을 현장에서 받는 수양회가 대부분이고, 그때는 등록자가 올릴
  /// 영수증도 없다. 담당자가 직접 적을 수 있어야 한다 — 이것이 없어서
  /// 입금은 등록자가 올린 것을 승인/반려하는 길뿐이었다.
  Future<void> _editPerson(Map<String, dynamic> reg, Currency currency) async {
    final l10n = AppLocalizations.of(context)!;
    final pay = (reg['payment'] as Map?) ?? const {};
    var submitted = reg['submitted'] == true;
    // 상태는 셋이다: 아직 없음 · 받을 예정 · 받았음.
    var status = switch (pay['status']) {
      'confirmed' => 'confirmed',
      'pending' => 'pending',
      _ => 'none',
    };
    // 낼 돈이 아직 없으면 등록서에서 계산된 금액을 넣어 준다 — 담당자가
    // 매번 옮겨 적을 이유가 없다.
    final due = Money.parse(reg['amount_due']) ?? 0;
    // **받은 금액**이다. 예전에는 여기에 낼 돈을 넣어 두어, 부분 납부를
    // 적을 방법이 아예 없었다.
    final amountCtrl = TextEditingController(
      text: (Money.parse(pay['amount']) ?? 0).toStringAsFixed(0),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('${reg['real_name'] ?? ''}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: submitted,
                onChanged: (v) => setLocal(() => submitted = v),
                title: Text(l10n.dashStatSubmitted),
                subtitle: Text(
                  l10n.tblSubmittedHint,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
              const Divider(),
              // 낼 돈은 등록서가 정한다. 여기서 고치는 것이 아니다 —
              // 고친다면 그것은 할인이고, 할인은 따로 판단한다.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.tblAmountDue}  ${currency.format(due)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setLocal(() {}),
                decoration: InputDecoration(
                  labelText: l10n.tblAmountPaid,
                  prefixText: '${currency.symbol} ',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  for (final o in [
                    (key: 'none', label: l10n.dashPayNone),
                    (key: 'pending', label: l10n.payPending),
                    (key: 'confirmed', label: l10n.dashPayConfirmed),
                  ])
                    ChoiceChip(
                      label: Text(
                        o.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: status == o.key,
                      onSelected: (_) => setLocal(() => status = o.key),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 넷 중 어디로 가는지 누르기 전에 보인다. 상태는 따로 고르는
              // 것이 아니라 **금액에서 나온다**.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  payStateLabel(
                    l10n,
                    payStateOf(
                      due: due,
                      paid: int.tryParse(amountCtrl.text.trim()) ?? 0,
                      status: status == 'none' ? null : status,
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;

    try {
      await ApiClient.updateRegistrationAdmin(
        widget.programId,
        reg['id'] as String,
        submitted: submitted,
        // "아직 없음" 은 입금 줄을 지운다는 뜻이다.
        payment: status == 'none'
            ? null
            : {
                'amount': int.tryParse(amountCtrl.text.trim()) ?? 0,
                'status': status,
              },
      );
      ref.invalidate(programRegistrationsProvider(widget.programId));
      ref.invalidate(programStatsProvider(widget.programId));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
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
    // 식사 제한만 서버가 걸러 준 명단을 쓴다.
    //
    // 낱말 목록('없음' / 'none' / 'ninguno' / 'nenhum' …)을 앱에도 두었더니
    // 포르투갈어를 넣을 때 한쪽만 늘어나, 카드는 4명 표는 2명이 됐다.
    // 판정은 한 곳(has_food_restriction, 027)에만 있어야 한다.
    final regsAsync = widget.view == RosterView.meals
        ? ref
              .watch(programMealsProvider(widget.programId))
              .whenData((d) => (d?['people'] as List?) ?? const [])
        : ref.watch(programRegistrationsProvider(widget.programId));
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
          final table = _table(l10n, theme, data, headers, rows, currency);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tblCount(rows.length),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            l10n.tblUnfinishedNote,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
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
              else if (widget.view == RosterView.all &&
                  MediaQuery.sizeOf(context).width >= 1000)
                // 넓은 화면에서는 왼쪽에 셈, 오른쪽에 표. 담당자가 표를
                // 훑어 세던 것을 화면이 대신 센다.
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 왼쪽은 오른쪽의 절반 폭.
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                          child: _MoneySummary(
                            people: data,
                            currency: currency,
                          ),
                        ),
                      ),
                      Expanded(flex: 2, child: table),
                    ],
                  ),
                )
              else
                Expanded(child: table),
            ],
          );
        },
      ),
    );
  }

  /// 표 하나. 좌우로 나눈 배치와 위아래로 쌓은 배치가 같은 것을 쓴다.
  ///
  /// 표는 가로로 넓다. 화면 밖으로 밀리면 못 읽으므로 표만 따로 가로
  /// 스크롤한다 — 화면 전체가 옆으로 밀리면 안 된다.
  Widget _table(
    AppLocalizations l10n,
    ThemeData theme,
    List<Map<String, dynamic>> data,
    List<String> headers,
    List<List<String>> rows,
    Currency currency,
  ) {
    return SingleChildScrollView(
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
            // 고치기 칸. 내보내기에는 넣지 않는다 — 종이에
            // 인쇄된 표에 버튼 자리가 있으면 이상하다.
            const DataColumn(label: Text('')),
          ],
          rows: [
            for (var ri = 0; ri < rows.length; ri++)
              DataRow(
                // 완료하지 않은 사람은 줄 전체를 노랗게.
                // 크림색은 늘 "아직 안 끝난 사람". 입금 표에서는
                // 등록 완료가 아니라 **입금** 이 기준이다.
                color: _done(data[ri])
                    ? null
                    : WidgetStatePropertyAll(_unfinishedColor(theme)),
                cells: [
                  for (final cell in rows[ri])
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          cell,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: l10n.actionEdit,
                      onPressed: () => _editPerson(data[ri], currency),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 명단 옆의 셈.
///
/// 담당자가 표를 훑으며 손으로 세던 것들이다 — 몇 명이 오려 하고, 돈을 얼마나
/// 걷었나. 표 안에 있는 값만 쓰므로 서버에 다시 묻지 않는다.
class _MoneySummary extends StatelessWidget {
  final List<Map<String, dynamic>> people;
  final Currency currency;

  const _MoneySummary({required this.people, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    var unpaid = 0, partial = 0, paid = 0, pending = 0;
    num collected = 0;
    num due = 0;
    for (final r in people) {
      final pay = (r['payment'] as Map?) ?? const {};
      final d = Money.parse(r['amount_due']) ?? 0;
      final p = Money.parse(pay['amount']) ?? 0;
      due += d;
      // **확인된 것만 걷은 돈이다.** 확인 전 금액을 더하면 장부가 실제보다
      // 커지고, 그 숫자를 믿고 예산을 짜게 된다.
      if (pay['status'] == 'confirmed') collected += p;
      switch (payStateOf(due: d, paid: p, status: pay['status'] as String?)) {
        case PayState.unpaid:
          unpaid++;
        case PayState.partial:
          partial++;
        case PayState.paid:
          paid++;
        case PayState.pending:
          pending++;
      }
    }

    Widget line(String label, String value, {Color? color, bool big = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: big ? 17 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            line(l10n.sumWanting, l10n.unitPeople(people.length), big: true),
            const Divider(),
            line(
              l10n.payPending,
              l10n.unitPeople(pending),
              color: Colors.orange[900],
            ),
            line(l10n.payUnpaid, l10n.unitPeople(unpaid), color: Colors.red),
            line(
              l10n.payPartial,
              l10n.unitPeople(partial),
              color: Colors.orange[800],
            ),
            line(l10n.payPaid, l10n.unitPeople(paid), color: Colors.green[700]),
            const Divider(),
            line(
              l10n.sumCollected,
              currency.format(collected),
              color: Colors.green[800],
              big: true,
            ),
            // 아직 받을 돈. 걷은 돈만 보면 다 끝난 것처럼 보인다.
            line(l10n.sumRemaining, currency.format(due - collected)),
          ],
        ),
      ),
    );
  }
}
