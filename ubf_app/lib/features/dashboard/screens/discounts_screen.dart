import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/money.dart';
import '../../program/providers/program_provider.dart';

// 할인 신청 검토 (담당자)
//
// 등록자는 신청과 사유만 남긴다. 확정 금액은 여기서만 정해진다.
// 신청이 없는 사람은 목록에 넣지 않는다 — 볼 것이 없는 행이 늘어나면
// 정작 판단해야 할 몇 건이 묻힌다.
class DiscountsScreen extends ConsumerWidget {
  final String programId;

  const DiscountsScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(programRegistrationsProvider(programId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adDiscountTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (rows) {
          final requests = rows
              .where((r) => r['discount_requested'] == true)
              .toList();

          if (requests.isEmpty) {
            return Center(child: Text(l10n.adDiscountNone));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(programRegistrationsProvider(programId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (_, i) =>
                  _RequestCard(programId: programId, registration: requests[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final String programId;
  final Map<String, dynamic> registration;

  const _RequestCard({required this.programId, required this.registration});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final r = widget.registration;
    _amountController = TextEditingController(
      text: r['discount_amount']?.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: r['discount_note'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _decide(String status) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final amount = num.tryParse(_amountController.text.trim());

    // 승인에는 금액이 필요하다. 서버도 막지만 여기서 먼저 알려주는 편이
    // 왕복 한 번을 아낀다.
    if (status == 'approved' && (amount == null || amount < 0)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.adDiscountAmountReq)));
      return;
    }

    setState(() => _busy = true);
    try {
      await ApiClient.decideDiscount(
        widget.programId,
        widget.registration['id'] as String,
        status: status,
        amount: status == 'approved' ? amount : null,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      ref.invalidate(programRegistrationsProvider(widget.programId));
      messenger.showSnackBar(SnackBar(content: Text(l10n.adDiscountSaved)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.commonErrorDetail('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final r = widget.registration;
    final status = r['discount_status'] as String?;
    final reason = r['discount_reason'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r['real_name'] as String? ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            if (r['branch'] != null || r['country'] != null)
              Text(
                [
                  r['country'],
                  r['branch'],
                ].where((v) => v != null && '$v'.isNotEmpty).join(' / '),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            const SizedBox(height: 10),

            // 등록자가 고른 항목. 등록 시점 문구를 그대로 보관한 값이므로
            // 관리자가 항목을 고친 뒤에도 그때 본 문구가 남는다.
            Text(
              r['discount_option_label'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(reason, style: TextStyle(color: Colors.grey[800])),
            ],
            if (r['fee_tier'] != null) ...[
              const SizedBox(height: 4),
              Text(
                r['fee_tier'] == 'premium'
                    ? l10n.feeTierPremium
                    : l10n.feeTierBasic,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.adDiscountAmount,
                      prefixText: '${Money.symbol} ',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: l10n.adDiscountNote,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _decide('rejected'),
                  child: Text(l10n.adDiscountReject),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : () => _decide('approved'),
                  child: Text(l10n.adDiscountApprove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (text, color) = switch (status) {
      'approved' => (l10n.adDiscountApproved, const Color(0xFF2E7D32)),
      'rejected' => (l10n.adDiscountRejected, const Color(0xFFC62828)),
      _ => (l10n.adDiscountPending, const Color(0xFFB26A00)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
