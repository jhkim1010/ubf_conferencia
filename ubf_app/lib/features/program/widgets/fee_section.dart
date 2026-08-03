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

  /// 이 수양회의 통화. 등록자 전원이 이 단위로 본다.
  final Currency currency;

  /// 통화를 바꿨을 때. 부모가 상태를 들고 저장 시점에 서버로 보낸다.
  final ValueChanged<Currency> onCurrencyChanged;

  /// 통화를 고를 수 있는지. 국제 수양회는 USD 로 고정이므로 false 다.
  ///
  /// 고를 수 없을 때는 드롭다운을 비활성으로 두지 않고 아예 안 보여준다 —
  /// 눌러도 아무 일도 없는 컨트롤은 고장난 것으로 읽힌다.
  final bool canChooseCurrency;

  const FeeSection({
    super.key,
    required this.basicController,
    required this.premiumController,
    required this.basicDescController,
    required this.premiumDescController,
    required this.discountOptions,
    required this.onDiscountsChanged,
    required this.currency,
    required this.onCurrencyChanged,
    required this.canChooseCurrency,
  });

  @override
  State<FeeSection> createState() => _FeeSectionState();
}

class _FeeSectionState extends State<FeeSection> {
  // 언어별 문구. 한 줄만 받으면 다른 언어 사용자는 읽지 못한 채 고르게 된다.
  // 돈이 걸린 선택지라 더 나쁘다.
  final _labelKo = TextEditingController();
  final _labelEn = TextEditingController();
  final _labelEs = TextEditingController();
  final _labelPt = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 아래의 "참가비가 비어 있습니다" 안내가 입력에 따라 나타났다 사라져야
    // 한다. 컨트롤러를 듣지 않으면 화면을 열 때의 상태로 굳는다.
    widget.basicController.addListener(_refresh);
    widget.premiumController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.basicController.removeListener(_refresh);
    widget.premiumController.removeListener(_refresh);
    _labelKo.dispose();
    _labelEn.dispose();
    _labelEs.dispose();
    _labelPt.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _add() {
    final labels = <String, String>{
      for (final e in {
        'ko': _labelKo,
        'en': _labelEn,
        'es': _labelEs,
        'pt': _labelPt,
      }.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    // 한 칸만 채워도 만들 수 있다. 네 칸을 모두 강제하면 한 언어만 쓰는
    // 지부가 항목을 아예 못 만든다. 비어 있는 언어는 기본 문구로 대체된다.
    if (labels.isEmpty) return;
    final label = labels['en'] ?? labels['ko'] ?? labels['es']!;
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
      'labels': labels,
      'amount': amount != null && amount >= 0 ? amount : null,
    });
    _labelKo.clear();
    _labelEn.clear();
    _labelEs.clear();
    _labelPt.clear();
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

        // 통화를 먼저 고르게 한다. 금액을 입력한 뒤에 단위를 정하면 이미 적은
        // 숫자가 어느 통화였는지 헷갈린다.
        if (widget.canChooseCurrency)
          DropdownButtonFormField<String>(
            initialValue: widget.currency.code,
            decoration: InputDecoration(
              labelText: l10n.cpCurrency,
              helperText: l10n.cpCurrencyHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final c in Currency.all)
                DropdownMenuItem(
                  value: c.code,
                  child: Text('${c.symbol}  ${c.code}'),
                ),
            ],
            onChanged: (v) {
              if (v != null) widget.onCurrencyChanged(Currency.of(v));
            },
          )
        else
          // 고를 수 없어도 무엇으로 적히는지는 보여야 한다. 금액 칸의 접두사만
          // 보고 "왜 U$ 인가"를 유추하게 두지 않는다.
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.cpCurrencyFixed(widget.currency.code),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),

        _FeeRow(
          amountController: widget.basicController,
          descController: widget.basicDescController,
          amountLabel: l10n.cpFeeBasic,
          descLabel: l10n.cpFeeBasicDesc,
          validator: validateFee,
          symbol: widget.currency.symbol,
        ),
        const SizedBox(height: 12),
        _FeeRow(
          amountController: widget.premiumController,
          descController: widget.premiumDescController,
          amountLabel: l10n.cpFeePremium,
          descLabel: l10n.cpFeePremiumDesc,
          validator: validateFee,
          symbol: widget.currency.symbol,
        ),

        // 참가비를 하나도 안 적으면 참가자에게 참가비 화면이 나오지 않는다.
        // 무료 수양회면 맞는 동작이지만, 적었다고 믿는 담당자에게는 사고다.
        if (widget.basicController.text.trim().isEmpty &&
            widget.premiumController.text.trim().isEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.cpFeeNoneWarning,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],

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
                title: Text(_labelSummary(e.value)),
                subtitle: amount is num
                    ? Text('- ${widget.currency.format(amount)}')
                    : Text(l10n.cpDiscountAmountHint),
                isThreeLine: _labelSummary(e.value).contains('\n'),
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
        // 언어별 문구. 아는 언어만 채우면 된다.
        _LangField(controller: _labelKo, lang: '한국어', hint: '1일만 참석'),
        const SizedBox(height: 6),
        _LangField(
          controller: _labelEn,
          lang: 'English',
          hint: 'Attending one day only',
        ),
        const SizedBox(height: 6),
        _LangField(
          controller: _labelEs,
          lang: 'Español',
          hint: 'Asisto solo un día',
        ),
        const SizedBox(height: 6),
        _LangField(
          controller: _labelPt,
          lang: 'Português',
          hint: 'Participo só um dia',
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  prefixText: '${widget.currency.symbol} ',
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

// 목록에 보여줄 요약. 언어별로 다르게 적었으면 모두 보여준다 —
// 관리자가 어느 언어를 빠뜨렸는지 여기서 바로 보여야 한다.
String _labelSummary(Map<String, dynamic> option) {
  final raw = option['labels'];
  final labels = raw is Map ? Map<String, dynamic>.from(raw) : const {};
  final parts = <String>[];
  for (final lang in ['ko', 'en', 'es', 'pt']) {
    final v = labels[lang];
    if (v is String && v.trim().isNotEmpty) parts.add('$lang  ${v.trim()}');
  }
  if (parts.isEmpty) return option['label'] as String? ?? '';
  return parts.join('\n');
}

class _LangField extends StatelessWidget {
  final TextEditingController controller;
  final String lang;
  final String hint;

  const _LangField({
    required this.controller,
    required this.lang,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: lang,
      hintText: hint,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
  );
}

class _FeeRow extends StatefulWidget {
  final TextEditingController amountController;
  final TextEditingController descController;
  final String amountLabel;
  final String descLabel;
  final String? Function(String?) validator;
  final String symbol;

  const _FeeRow({
    required this.amountController,
    required this.descController,
    required this.amountLabel,
    required this.descLabel,
    required this.validator,
    required this.symbol,
  });

  @override
  State<_FeeRow> createState() => _FeeRowState();
}

class _FeeRowState extends State<_FeeRow> {
  @override
  void initState() {
    super.initState();
    // 설명 칸에 숫자만 적히는 일이 실제로 있었다. 그러면 금액이 비어 있어
    // 참가자에게 참가비 화면이 아예 안 나오는데, 담당자는 적었다고 믿는다.
    widget.descController.addListener(_onDescChanged);
    widget.amountController.addListener(_onDescChanged);
  }

  @override
  void dispose() {
    widget.descController.removeListener(_onDescChanged);
    widget.amountController.removeListener(_onDescChanged);
    super.dispose();
  }

  void _onDescChanged() => setState(() {});

  /// 설명이 숫자뿐이고 금액이 비어 있으면 칸을 바꿔 적은 것이다.
  bool get _looksSwapped {
    final desc = widget.descController.text.trim();
    if (desc.isEmpty) return false;
    if (num.tryParse(desc) == null) return false;
    return widget.amountController.text.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final amount = TextFormField(
      controller: widget.amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: widget.amountLabel,
        prefixText: '${widget.symbol} ',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: widget.validator,
    );

    final desc = TextFormField(
      controller: widget.descController,
      decoration: InputDecoration(
        labelText: widget.descLabel,
        hintText: l10n.cpFeeDescHint,
        border: const OutlineInputBorder(),
        isDense: true,
        // 경고는 칸 바로 아래에 붙인다. 화면 아래쪽에 모아 두면 어느 칸
        // 이야기인지 알 수 없다.
        errorText: _looksSwapped ? l10n.cpFeeDescLooksLikeAmount : null,
        errorMaxLines: 3,
      ),
    );

    // 좁은 화면에서는 세로로 쌓는다. 나란히 두면 라벨이 잘려
    // "기본 참가비"와 "포함되는 것"을 구별할 수 없다 — 실제로 그래서
    // 금액이 설명 칸에 들어갔다.
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 420) {
          return Column(children: [amount, const SizedBox(height: 8), desc]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: amount),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: desc),
          ],
        );
      },
    );
  }
}
