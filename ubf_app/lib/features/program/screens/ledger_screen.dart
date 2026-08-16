import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/money.dart';
import '../providers/program_provider.dart';

/// 수양회 장부 (053).
///
/// 앱이 아는 돈은 참가비뿐이었다. 지부 지원금과 숙소비·버스 대절 같은 지출은
/// 종이나 표계산기에 있었고, "지금 얼마가 모자라나" 를 물으면 두 곳을 더해야
/// 했다. 여기서 한 번에 본다.
///
/// **참가비는 여기 적지 않는다.** payments 에 이미 있고, 두 곳에 적으면
/// 언젠가 어긋난다 — 합계를 낼 때 서버가 둘을 더한다.
class LedgerScreen extends ConsumerWidget {
  final String programId;

  const LedgerScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(ledgerProvider(programId));
    final currency = Currency.of(
      ref.watch(programByIdProvider(programId)).valueOrNull?['currency']
          as String?,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ledgerTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (data) {
          final entries = ((data['entries'] as List?) ?? const [])
              .cast<Map<String, dynamic>>();
          final sum = (data['summary'] as Map?) ?? const {};

          // 무엇을 적는지가 버튼에 있어야 한다. "한 줄 적기" 하나면 누른
          // 뒤에야 갈래를 고르게 되고, 그 한 걸음에서 갈래를 잘못 두고
          // 저장하는 일이 생긴다.
          final buttons = Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _edit(context, ref, currency, null, kind: 'expense'),
                  icon: const Icon(Icons.north_east, size: 18),
                  label: Text(l10n.ledgerAddExpense),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green[700],
                  ),
                  onPressed: () =>
                      _edit(context, ref, currency, null, kind: 'income'),
                  icon: const Icon(Icons.south_west, size: 18),
                  label: Text(l10n.ledgerAddIncome),
                ),
              ),
            ],
          );

          final entryList = _Entries(
            entries: entries,
            onEdit: (e) => _edit(context, ref, currency, e),
            onDelete: (e) => _delete(context, ref, currency, e),
            currency: currency,
            l10n: l10n,
          );
          final summary = _Summary(sum: sum, currency: currency);

          return LayoutBuilder(
            builder: (context, box) {
              // 넓은 화면에서는 셈을 왼쪽에 붙박아 둔다 — 줄을 적는 동안
              // 합계가 화면 밖으로 밀려나면 왜 적는지를 잊는다.
              if (box.maxWidth < 900) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    summary,
                    const SizedBox(height: 12),
                    buttons,
                    const SizedBox(height: 12),
                    // 몇 줄이든 다 보여 준다 — 장부에서 접어 둘 줄은 없다.
                    _Count(n: entries.length),
                    entryList,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: box.maxWidth < 1200 ? 320 : 380,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 24),
                      child: summary,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 12, 16, 24),
                      children: [
                        buttons,
                        const SizedBox(height: 12),
                        _Count(n: entries.length),
                        entryList,
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 지우기 전에 한 번 묻는다.
  ///
  /// 장부 줄은 지우면 합계가 그 자리에서 바뀌고 되돌릴 길이 없다. 목록에서
  /// 손가락이 스쳐 사라지면 무엇이 없어졌는지도 모른다.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Currency currency,
    Map<String, dynamic> entry,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.actionDelete),
        // 무엇을 지우는지 금액까지 보여 준다.
        content: Text(
          '${entry['title']} · '
          '${currency.format(Money.parse(entry['amount']) ?? 0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ApiClient.deleteLedgerEntry(programId, entry['id'] as String);
      ref.invalidate(ledgerProvider(programId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Currency currency,
    Map<String, dynamic>? entry, {
    String? kind,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    var kind0 = (entry?['kind'] as String?) ?? kind ?? 'expense';
    final titleCtrl = TextEditingController(text: '${entry?['title'] ?? ''}');
    final noteCtrl = TextEditingController(text: '${entry?['note'] ?? ''}');
    final amountCtrl = TextEditingController(
      text: entry == null
          ? ''
          : (Money.parse(entry['amount']) ?? 0).toStringAsFixed(0),
    );

    // 현지 통화로 적으면 수양회 통화로 환산해 저장한다. 환율은 가져오되
    // 고칠 수 있다 — 아르헨티나는 공식과 블루가 따로 움직이고, 그날 실제로
    // 바꾼 값이 API 와 다를 수 있다.
    var local = (entry?['localCurrency'] as String?) ?? '';
    final localAmountCtrl = TextEditingController(
      text: entry?['localAmount'] == null
          ? ''
          : (Money.parse(entry!['localAmount']) ?? 0).toStringAsFixed(0),
    );
    final rateCtrl = TextEditingController(
      text: entry?['rate'] == null
          ? ''
          : (Money.parse(entry!['rate']) ?? 0).toStringAsFixed(2),
    );
    String rateNote = '';

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            entry == null
                ? (kind0 == 'income'
                      ? l10n.ledgerAddIncome
                      : l10n.ledgerAddExpense)
                : l10n.actionEdit,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 들어온 돈인지 나간 돈인지. 금액은 늘 양수이고 방향은
                // 여기서 정한다 — 음수 지출이 섞이면 합계를 못 믿는다.
                Wrap(
                  spacing: 6,
                  children: [
                    for (final o in [
                      (key: 'income', label: l10n.ledgerIncome),
                      (key: 'expense', label: l10n.ledgerExpense),
                    ])
                      ChoiceChip(
                        label: Text(o.label),
                        selected: kind0 == o.key,
                        onSelected: (_) => setLocal(() => kind0 = o.key),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: l10n.ledgerWhat),
                ),
                const SizedBox(height: 8),
                // 현지 통화. 비워 두면 수양회 통화로 그냥 적는다.
                Wrap(
                  spacing: 6,
                  children: [
                    for (final c in ['', 'ARS', 'BRL', 'PYG', 'KRW'])
                      ChoiceChip(
                        label: Text(
                          c.isEmpty ? currency.code : c,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: local == c,
                        onSelected: (_) async {
                          setLocal(() {
                            local = c;
                            rateNote = '';
                          });
                          if (c.isEmpty) return;
                          // 오늘 환율을 넣어 준다. 못 가져오면 손으로 적는다.
                          final r = await ApiClient.getFxRate(programId, c);
                          if (!ctx.mounted) return;
                          setLocal(() {
                            if (r['available'] == true) {
                              rateCtrl.text = (Money.parse(r['rate']) ?? 0)
                                  .toStringAsFixed(2);
                              rateNote = r['source'] == 'blue'
                                  ? l10n.ledgerRateBlue
                                  : l10n.ledgerRateMarket;
                            } else {
                              rateNote = l10n.ledgerRateUnavailable;
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (local.isEmpty)
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.ledgerAmount,
                      prefixText: '${currency.symbol} ',
                    ),
                  )
                else ...[
                  TextField(
                    controller: localAmountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setLocal(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.ledgerLocalAmount(local),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setLocal(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.ledgerRate(local, currency.code),
                      helperText: rateNote.isEmpty ? null : rateNote,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 환산 결과를 저장 전에 보여 준다. 나중에 장부를 보고
                  // "이게 얼마였더라" 를 겪지 않아야 한다.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      () {
                        final a =
                            double.tryParse(localAmountCtrl.text.trim()) ?? 0;
                        final r = double.tryParse(rateCtrl.text.trim()) ?? 0;
                        if (a <= 0 || r <= 0) return '—';
                        return '= ${currency.format(a / r)}';
                      }(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.ledgerNote),
                ),
              ],
            ),
          ),
          actions: [
            if (entry != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: Text(l10n.actionDelete),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    try {
      if (action == 'delete' && entry != null) {
        // 대화상자에서 눌러도 같은 확인을 거친다 — 지우는 길이 둘인데
        // 한쪽만 물으면 그쪽으로 사고가 난다.
        if (context.mounted) await _delete(context, ref, currency, entry);
        return;
      } else if (action == 'save') {
        // 현지 통화로 적었으면 환산해 저장하고, 그때 쓴 환율도 함께
        // 남긴다 — 나중에 다시 찾은 환율은 그날 값이 아니다.
        final localAmount = double.tryParse(localAmountCtrl.text.trim()) ?? 0;
        final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
        final useLocal = local.isNotEmpty && localAmount > 0 && rate > 0;
        final body = {
          'kind': kind0,
          'title': titleCtrl.text.trim(),
          'amount': useLocal
              ? (localAmount / rate)
              : (int.tryParse(amountCtrl.text.trim()) ?? 0),
          'note': noteCtrl.text.trim(),
          if (useLocal) ...{
            'localAmount': localAmount,
            'localCurrency': local,
            'rate': rate,
          },
        };
        if (entry == null) {
          await ApiClient.addLedgerEntry(programId, body);
        } else {
          await ApiClient.updateLedgerEntry(
            programId,
            entry['id'] as String,
            body,
          );
        }
      }
      ref.invalidate(ledgerProvider(programId));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// 지금 형편.
///
/// **남은 돈**은 손에 있는 것이고, **다 걷히면**은 아직 못 받은 참가비까지
/// 들어왔을 때다. 둘을 함께 보여 줘야 "지금은 모자라지만 다 걷히면 남는다"
/// 를 알 수 있다.
class _Summary extends StatelessWidget {
  final Map sum;
  final Currency currency;

  const _Summary({required this.sum, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    num v(String k) => Money.parse(sum[k]) ?? 0;

    Widget line(String label, num value, {Color? color, bool big = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
              Text(
                currency.format(value),
                style: TextStyle(
                  fontSize: big ? 18 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );

    final balance = v('balance');
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            line(l10n.ledgerCollected, v('collected')),
            line(l10n.ledgerSupport, v('support'), color: Colors.green[800]),
            line(l10n.ledgerSpent, v('spent'), color: Colors.red[800]),
            const Divider(),
            line(
              l10n.ledgerBalance,
              balance,
              big: true,
              // 모자란 것은 눈에 띄어야 한다.
              color: balance < 0 ? Colors.red : Colors.green[800],
            ),
            const SizedBox(height: 2),
            Text(
              l10n.ledgerOwedNote(currency.format(v('owed'))),
              style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
            ),
            line(l10n.ledgerExpected, v('expected')),
          ],
        ),
      ),
    );
  }
}

class _Entries extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;
  final Currency currency;
  final AppLocalizations l10n;

  const _Entries({
    required this.entries,
    required this.onEdit,
    required this.onDelete,
    required this.currency,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text(l10n.ledgerEmpty)),
      );
    }
    return Column(
      children: [
        for (final e in entries)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: Icon(
                e['kind'] == 'income' ? Icons.south_west : Icons.north_east,
                color: e['kind'] == 'income'
                    ? Colors.green[700]
                    : Colors.red[700],
                size: 20,
              ),
              title: Text(
                '${e['title'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  '${e['occurred_on'] ?? ''}'.split('T').first,
                  // 실제로 낸 돈과 그때 환율. 영수증과 맞춰 보려면 이것이
                  // 있어야 한다.
                  if (e['localAmount'] != null)
                    '${e['localCurrency']} '
                        '${groupDigits(Money.parse(e['localAmount']) ?? 0, 0)}'
                        ' @ ${groupDigits(Money.parse(e['rate']) ?? 0, 2)}',
                  '${e['note'] ?? ''}',
                ].where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(fontSize: 11.5),
              ),
              // 고치기·지우기가 겉으로 보여야 한다. 줄을 눌러야 열리는
              // 것만으로는 고칠 수 있다는 것을 모른다.
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currency.format(Money.parse(e['amount']) ?? 0),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: e['kind'] == 'income'
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: l10n.actionEdit,
                    onPressed: () => onEdit(e),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: l10n.actionDelete,
                    onPressed: () => onDelete(e),
                  ),
                ],
              ),
              onTap: () => onEdit(e),
            ),
          ),
      ],
    );
  }
}

/// 몇 줄인지. 장부는 접어 두지 않고 다 보여 주므로, 몇 개인지는 위에
/// 적어 둔다.
class _Count extends StatelessWidget {
  final int n;

  const _Count({required this.n});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        l10n.ledgerCount(n),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
