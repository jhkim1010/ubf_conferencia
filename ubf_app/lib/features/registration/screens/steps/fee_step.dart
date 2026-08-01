import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../providers/registration_provider.dart';
import '../../../../core/utils/money.dart';

// 참가비 등급 선택 + 할인 신청
//
// 두 가지를 한 화면에 둔다. 등록자 입장에서는 "내가 얼마를 내는가"라는
// 하나의 질문이고, 등급을 고른 직후가 할인을 떠올리는 시점이기 때문이다.
//
// 할인은 **신청**까지만 여기서 한다. 승인 여부와 확정 금액은 담당자가 정하며
// (서버에서 강제한다), 이 화면은 그 결과를 읽어서 보여주기만 한다.
class FeeStep extends ConsumerWidget {
  final String programId;
  final num? feeBasic;
  final num? feePremium;
  final String? feeBasicDesc;
  final String? feePremiumDesc;
  final List<Map<String, dynamic>> discountOptions;

  const FeeStep({
    super.key,
    required this.programId,
    required this.feeBasic,
    required this.feePremium,
    required this.feeBasicDesc,
    required this.feePremiumDesc,
    required this.discountOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final form = ref.watch(registrationFormProvider(programId));
    final notifier = ref.read(registrationFormProvider(programId).notifier);

    // 담당자의 판단 결과는 폼 상태가 아니라 서버 값이다.
    final saved = ref.watch(registrationProvider(programId)).valueOrNull;
    final decidedStatus = saved?['discount_status'] as String?;
    final decidedAmount = saved?['discount_amount'];
    final adminNote = saved?['discount_note'] as String?;

    if (feeBasic == null && feePremium == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.feeNotSet, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.feePrompt,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        if (feeBasic != null)
          _TierCard(
            title: l10n.feeTierBasic,
            amount: feeBasic!,
            description: feeBasicDesc,
            selected: form.feeTier == 'basic',
            onTap: () => notifier.selectFeeTier('basic'),
          ),
        if (feePremium != null)
          _TierCard(
            title: l10n.feeTierPremium,
            amount: feePremium!,
            description: feePremiumDesc,
            selected: form.feeTier == 'premium',
            onTap: () => notifier.selectFeeTier('premium'),
          ),

        const SizedBox(height: 28),
        Text(l10n.discountTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),

        if (discountOptions.isEmpty)
          Text(
            l10n.discountNoOptions,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          )
        else ...[
          Text(
            l10n.discountPrompt,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          // 항목을 고르는 것이 곧 신청이다. 별도의 신청 스위치를 두면
          // 항목만 고르고 스위치를 켜지 않아 신청이 사라진다.
          //
          // "신청 안 함"은 빈 문자열 key 로 표현한다. RadioGroup 은 null 을
          // "선택 없음"으로 쓰기 때문에, null 을 항목 값으로 쓰면 선택 자체가
          // 없는 상태와 구별되지 않는다.
          RadioGroup<String>(
            groupValue: form.discountRequested
                ? (form.discountOptionKey ?? '')
                : '',
            onChanged: (v) => v == null || v.isEmpty
                ? notifier.clearDiscountRequest()
                : notifier.selectDiscountOption(v),
            child: Column(
              children: [
                ...discountOptions.map((o) {
                  final amount = Money.parse(o['amount']);
                  return RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: o['key'] as String? ?? '',
                    title: Text(o['label'] as String? ?? ''),
                    subtitle: amount != null
                        ? Text(
                            '- ${Money.format(amount)}',
                            style: TextStyle(color: theme.colorScheme.primary),
                          )
                        : null,
                  );
                }),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: '',
                  title: Text(l10n.discountNone),
                ),
              ],
            ),
          ),

          if (form.discountRequested) ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: form.discountReason,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.discountReasonLabel,
                hintText: l10n.discountReasonHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: notifier.updateDiscountReason,
            ),
            const SizedBox(height: 12),
            _DecisionBanner(
              status: decidedStatus,
              amount: decidedAmount,
              note: adminNote,
            ),
          ],
        ],
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final String title;
  final num amount;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  const _TierCard({
    required this.title,
    required this.amount,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : Colors.grey[300]!,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio 위젯 대신 아이콘을 쓴다. 등급은 두 개뿐이고 카드 전체가
              // 탭 영역이라 RadioGroup 을 얹을 이유가 없다.
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 4),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  Money.format(amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 담당자 판단 결과. 아직 저장 전이라 status 가 없으면 아무것도 보여주지 않는다
// (없는 상태를 "대기 중"이라고 하면 신청하지도 않았는데 신청한 것처럼 보인다).
class _DecisionBanner extends StatelessWidget {
  final String? status;
  final Object? amount;
  final String? note;

  const _DecisionBanner({
    required this.status,
    required this.amount,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (status == null) return const SizedBox.shrink();

    late final String text;
    late final Color color;
    late final IconData icon;
    switch (status) {
      case 'approved':
        final v = Money.parse(amount) ?? 0;
        text = l10n.discountStatusApproved(Money.format(v));
        color = Colors.green[700]!;
        icon = Icons.check_circle_outline;
      case 'rejected':
        text = l10n.discountStatusRejected;
        color = theme.colorScheme.error;
        icon = Icons.cancel_outlined;
      default:
        text = l10n.discountStatusPending;
        color = Colors.orange[800]!;
        icon = Icons.hourglass_empty;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.discountAdminNote(note!),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}
