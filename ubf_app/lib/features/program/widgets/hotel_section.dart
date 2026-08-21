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

/// 수준 한 줄 만들기 — 추가할 때도 고칠 때도 이 한 곳을 쓴다.
///
/// [key] 를 **밖에서 받는다.** 고칠 때 새 key 를 붙이면 그 수준을 고른
/// 참가자의 등록(`hotel_option_key`)이 없는 것을 가리키게 되고, 숙박비가
/// 조용히 0 이 된다. 두 곳에서 각각 만들면 언젠가 한쪽만 그렇게 된다.
@visibleForTesting
Map<String, dynamic> buildHotelLevel({
  required Map<String, String> labels,
  required num? price,
  required String key,
}) => {
  'key': key,
  // 화면 언어가 없을 때 쓰는 대표 이름. 한 칸만 채워도 만들 수 있으므로
  // 있는 것 중에서 고른다.
  'label': labels['en'] ?? labels['ko'] ?? labels.values.first,
  'labels': labels,
  // 단가를 아직 못 정했으면 비워 둔다. 0 으로 넣으면 참가자가 공짜인 줄 안다.
  'pricePerNight': price != null && price >= 0 ? price : null,
};

/// 아직 쓴 적 없는 key.
///
/// 위치가 아니라 **번호**로 만든다 — 중간 항목을 지운 뒤 새로 추가할 때 옛
/// key 가 되살아나면 이전 선택이 엉뚱한 수준에 붙는다.
@visibleForTesting
String nextHotelKey(Iterable<Map<String, dynamic>> existing) {
  final used = existing.map((o) => o['key'] as String? ?? '').toSet();
  var n = used.length + 1;
  while (used.contains('h$n')) {
    n++;
  }
  return 'h$n';
}

class _HotelSectionState extends State<HotelSection> {
  final _ko = TextEditingController();
  final _en = TextEditingController();
  final _es = TextEditingController();
  final _pt = TextEditingController();
  final _price = TextEditingController();

  /// 지금 고치고 있는 수준의 key. null 이면 새로 만드는 중이다.
  String? _editingKey;

  @override
  void dispose() {
    _ko.dispose();
    _en.dispose();
    _es.dispose();
    _pt.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final labels = <String, String>{
      for (final e in {'ko': _ko, 'en': _en, 'es': _es, 'pt': _pt}.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    // 한 칸만 채워도 만들 수 있다. 네 칸을 모두 강제하면 한 언어만 쓰는
    // 지부가 항목을 아예 못 만든다.
    if (labels.isEmpty) return;
    final price = num.tryParse(_price.text.trim());

    final editing = _editingKey;
    if (editing == null) {
      widget.hotelOptions.add(
        buildHotelLevel(
          labels: labels,
          price: price,
          key: nextHotelKey(widget.hotelOptions),
        ),
      );
    } else {
      // 제자리에 갈아 끼운다. 지우고 다시 넣으면 순서가 바뀌어, 고치기만
      // 했는데 목록이 재배열된 것처럼 보인다.
      final at = widget.hotelOptions.indexWhere((o) => o['key'] == editing);
      if (at < 0) return;
      widget.hotelOptions[at] = buildHotelLevel(
        labels: labels,
        price: price,
        key: editing,
      );
    }
    _clear();
    widget.onChanged();
    setState(() {});
  }

  /// 이 수준을 아래 칸으로 불러와 고칠 수 있게 한다.
  void _edit(Map<String, dynamic> o) {
    final labels = (o['labels'] as Map?)?.cast<String, dynamic>() ?? const {};
    _ko.text = '${labels['ko'] ?? ''}';
    _en.text = '${labels['en'] ?? ''}';
    _es.text = '${labels['es'] ?? ''}';
    _pt.text = '${labels['pt'] ?? ''}';
    // 라벨이 하나도 없는 옛 줄이면 대표 이름이라도 넣어 준다 — 빈 칸으로
    // 열리면 저장이 막히고(labels.isEmpty) 왜 안 되는지 알 수 없다.
    if (_ko.text.isEmpty &&
        _en.text.isEmpty &&
        _es.text.isEmpty &&
        _pt.text.isEmpty) {
      _en.text = '${o['label'] ?? ''}';
    }
    final p = Money.parse(o['pricePerNight']);
    _price.text = p == null ? '' : '${p == p.roundToDouble() ? p.toInt() : p}';
    setState(() => _editingKey = o['key'] as String?);
  }

  void _clear() {
    _ko.clear();
    _en.clear();
    _es.clear();
    _pt.clear();
    _price.clear();
    _editingKey = null;
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
              // 지금 고치고 있는 줄을 표시한다. 아래 칸에 글자가 차 있는데
              // 어느 줄 것인지 모르면, 새로 만드는 중인 줄 알고 또 만든다.
              color: _editingKey == o['key']
                  ? theme.colorScheme.primaryContainer
                  : null,
              child: ListTile(
                dense: true,
                onTap: () => _edit(o),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.actionEdit,
                      onPressed: () => _edit(o),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.actionDelete,
                      onPressed: () {
                        // 고치던 줄을 지우면 아래 칸에 남은 글자가 갈 곳을
                        // 잃는다. 그때는 칸도 비운다.
                        if (_editingKey == o['key']) _clear();
                        widget.hotelOptions.remove(o);
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                  ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_editingKey != null) ...[
              TextButton(
                onPressed: () => setState(_clear),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: 8),
            ],
            OutlinedButton.icon(
              onPressed: _save,
              icon: Icon(_editingKey == null ? Icons.add : Icons.check),
              label: Text(
                _editingKey == null ? l10n.hotelAddLevel : l10n.actionSave,
              ),
            ),
          ],
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
