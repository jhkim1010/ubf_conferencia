import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';

// 참가비 등급 + 할인 항목 편집기.
//
// 수양회 생성 화면과 수정 화면이 같은 것을 물어보므로 한 곳에 둔다.
// 값(컨트롤러·목록)은 부모가 소유한다. 저장 시점에 필요한 것은 부모이고,
// 이 위젯이 값을 들고 있으면 부모가 다시 꺼내와야 한다.
class FeeSection extends StatefulWidget {
  final TextEditingController basicController;
  final TextEditingController premiumController;
  final TextEditingController basicDescController;
  final TextEditingController premiumDescController;

  /// 원소: { 'key': String, 'label': String, 'amount': num? }
  final List<Map<String, dynamic>> discountOptions;

  /// 목록을 바꾼 뒤 부모가 setState 하도록 알린다.
  final VoidCallback onDiscountsChanged;

  const FeeSection({
    super.key,
    required this.basicController,
    required this.premiumController,
    required this.basicDescController,
    required this.premiumDescController,
    required this.discountOptions,
    required this.onDiscountsChanged,
  });

  @override
  State<FeeSection> createState() => _FeeSectionState();
}

class _FeeSectionState extends State<FeeSection> {
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _add() {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;
    final amount = num.tryParse(_amountController.text.trim());

    // key 는 등록 레코드가 참조한다. 위치가 아니라 "지금까지 쓴 적 없는 번호"로
    // 만든다. 중간 항목을 지운 뒤 새로 추가할 때 옛 key 가 되살아나면
    // 이전 신청이 엉뚱한 항목에 붙는다.
    final used = widget.discountOptions
        .map((o) => o['key'] as String? ?? '')
        .toSet();
    var n = widget.discountOptions.length + 1;
    while (used.contains('d$n')) {
      n++;
    }

    widget.discountOptions.add({
      'key': 'd$n',
      'label': label,
      'amount': amount != null && amount >= 0 ? amount : null,
    });
    _labelController.clear();
    _amountController.clear();
    widget.onDiscountsChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String? validateFee(String? v) {
      if (v == null || v.trim().isEmpty) return null; // 빈 값 = 미제공
      final n = num.tryParse(v.trim());
      if (n == null || n < 0) return l10n.cpFeeInvalid;
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.cpFeeSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          l10n.cpFeeHint,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        _FeeRow(
          amountController: widget.basicController,
          descController: widget.basicDescController,
          amountLabel: l10n.cpFeeBasic,
          descLabel: l10n.cpFeeBasicDesc,
          validator: validateFee,
        ),
        const SizedBox(height: 12),
        _FeeRow(
          amountController: widget.premiumController,
          descController: widget.premiumDescController,
          amountLabel: l10n.cpFeePremium,
          descLabel: l10n.cpFeePremiumDesc,
          validator: validateFee,
        ),

        const SizedBox(height: 24),
        Text(l10n.cpDiscountSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          l10n.cpDiscountHint,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 10),

        if (widget.discountOptions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              l10n.cpDiscountEmpty,
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ...widget.discountOptions.asMap().entries.map((e) {
            final amount = e.value['amount'];
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(e.value['label'] as String? ?? ''),
                subtitle: amount is num
                    ? Text('- ${Money.format(amount)}')
                    : Text(l10n.cpDiscountAmountHint),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.cpDiscountRemove,
                  onPressed: () {
                    widget.discountOptions.removeAt(e.key);
                    widget.onDiscountsChanged();
                    setState(() {});
                  },
                ),
              ),
            );
          }),

        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: l10n.cpDiscountLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.cpDiscountAmount,
                  prefixText: '${Money.symbol} ',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IconButton.filled(
                icon: const Icon(Icons.add),
                tooltip: l10n.cpDiscountAdd,
                onPressed: _add,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController descController;
  final String amountLabel;
  final String descLabel;
  final String? Function(String?) validator;

  const _FeeRow({
    required this.amountController,
    required this.descController,
    required this.amountLabel,
    required this.descLabel,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: amountLabel,
              prefixText: '${Money.symbol} ',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            validator: validator,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: descController,
            decoration: InputDecoration(
              labelText: descLabel,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
