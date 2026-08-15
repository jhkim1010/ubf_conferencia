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
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.ledgerAmount,
                    prefixText: '${currency.symbol} ',
                  ),
                ),
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
        await ApiClient.deleteLedgerEntry(programId, entry['id'] as String);
      } else if (action == 'save') {
        final body = {
          'kind': kind0,
          'title': titleCtrl.text.trim(),
          'amount': int.tryParse(amountCtrl.text.trim()) ?? 0,
          'note': noteCtrl.text.trim(),
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
  final Currency currency;
  final AppLocalizations l10n;

  const _Entries({
    required this.entries,
    required this.onEdit,
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
                  '${e['note'] ?? ''}',
                ].where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: Text(
                currency.format(Money.parse(e['amount']) ?? 0),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: e['kind'] == 'income'
                      ? Colors.green[800]
                      : Colors.red[800],
                ),
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
