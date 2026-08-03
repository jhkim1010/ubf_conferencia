import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';

// 수양회 전후 숙박 수준 편집기(028).
//
// 참가비 편집기(FeeSection)와 같은 구조다 — 값은 부모가 소유하고 이 위젯은
// 목록을 고칠 뿐이다. 저장 시점에 값이 필요한 쪽은 부모다.
//
// 이 목록은 **외국에서 오는 참가자에게만** 보인다. 개최국 참가자는 수양회
// 전후에 집으로 가므로 물어볼 것이 없다.
class HotelSection extends StatefulWidget {
  /// 원소: { 'key': String, 'label': String, 'labels': {...}, 'pricePerNight': num? }
  final List<Map<String, dynamic>> hotelOptions;

  /// 목록을 바꾼 뒤 부모가 setState 하도록 알린다.
  final VoidCallback onChanged;

  /// 이 수양회의 통화. 참가비와 같은 단위로 보여야 비교가 된다.
  final Currency currency;

  const HotelSection({
    super.key,
    required this.hotelOptions,
    required this.onChanged,
    required this.currency,
  });

  @override
  State<HotelSection> createState() => _HotelSectionState();
}

class _HotelSectionState extends State<HotelSection> {
  final _ko = TextEditingController();
  final _en = TextEditingController();
  final _es = TextEditingController();
  final _pt = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _ko.dispose();
    _en.dispose();
    _es.dispose();
    _pt.dispose();
    _price.dispose();
    super.dispose();
  }

  void _add() {
    final labels = <String, String>{
      for (final e in {'ko': _ko, 'en': _en, 'es': _es, 'pt': _pt}.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    // 한 칸만 채워도 만들 수 있다. 네 칸을 모두 강제하면 한 언어만 쓰는
    // 지부가 항목을 아예 못 만든다.
    if (labels.isEmpty) return;
    final label = labels['en'] ?? labels['ko'] ?? labels['es']!;
    final price = num.tryParse(_price.text.trim());

    // key 는 등록 레코드가 참조한다. 위치가 아니라 "지금까지 쓴 적 없는 번호"로
    // 만든다 — 중간 항목을 지운 뒤 새로 추가할 때 옛 key 가 되살아나면
    // 이전 선택이 엉뚱한 수준에 붙는다.
    final used = widget.hotelOptions
        .map((o) => o['key'] as String? ?? '')
        .toSet();
    var n = widget.hotelOptions.length + 1;
    while (used.contains('h$n')) {
      n++;
    }

    widget.hotelOptions.add({
      'key': 'h$n',
      'label': label,
      'labels': labels,
      // 단가를 아직 못 정했으면 비워 둔다. 0 으로 넣으면 참가자가 공짜인 줄 안다.
      'pricePerNight': price != null && price >= 0 ? price : null,
    });
    _ko.clear();
    _en.clear();
    _es.clear();
    _pt.clear();
    _price.clear();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.hotelSectionTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.hotelSectionHelp,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        if (widget.hotelOptions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.hotelNoLevelsYet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          )
        else
          for (final o in List<Map<String, dynamic>>.from(widget.hotelOptions))
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(optionLabelFor(o, lang)),
                subtitle: Text(
                  Money.parse(o['pricePerNight']) == null
                      ? l10n.hotelPriceTbd
                      : l10n.hotelPerNight(
                          widget.currency.format(
                            Money.parse(o['pricePerNight'])!,
                          ),
                        ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.actionDelete,
                  onPressed: () {
                    widget.hotelOptions.remove(o);
                    widget.onChanged();
                    setState(() {});
                  },
                ),
              ),
            ),

        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _field(_ko, l10n.hotelLevelKo)),
            const SizedBox(width: 8),
            Expanded(child: _field(_en, l10n.hotelLevelEn)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _field(_es, l10n.hotelLevelEs)),
            const SizedBox(width: 8),
            Expanded(child: _field(_pt, l10n.hotelLevelPt)),
          ],
        ),
        const SizedBox(height: 8),
        _field(
          _price,
          '${l10n.hotelPricePerNightLabel} (${widget.currency.code})',
          numeric: true,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: Text(l10n.hotelAddLevel),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool numeric = false,
  }) => TextFormField(
    controller: c,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    inputFormatters: numeric
        ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
        : null,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
  );
}
