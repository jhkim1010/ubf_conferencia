import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mana/l10n/app_localizations.dart';

import '../../../core/utils/flight_api_service.dart';
import '../../../core/utils/i18n_text.dart';

/// 투어 때 타는 비행기(081) — 참가자 화면과 담당자 편집 창이 함께 쓰는 조각.
///
/// 한 구간의 꼴은 서버의 services/tour_flights.js 와 같다:
/// `{ kind, tour_id, date, time, flight_no, airline, from, to, estimated,
///    note, with_companions }`. 정리(빈 칸 버리기, 예매 전이면 편명 비우기)는
/// 서버가 다시 한다 — 여기서는 사람이 적은 것을 그대로 담아 보낸다.

/// 투어 구간의 색. 수양회 구간(파랑)과 한눈에 갈려야 한다.
const tourLegColor = Color(0xFF6A3FB5);

const tourLegKinds = ['tour_out', 'tour_return', 'other'];

String tourLegKindLabel(AppLocalizations l10n, Object? kind) => switch (kind) {
  'tour_out' => l10n.tfKindOut,
  'tour_return' => l10n.tfKindReturn,
  _ => l10n.tfKindOther,
};

/// 투어 이름을 보는 사람의 언어로(071).
String tourNameOf(Map tour, String lang) =>
    pickI18n(tour['name_i18n'], lang, tour['name']) ?? '';

DateTime? _day(Object? v) {
  final s = '${v ?? ''}';
  return s.length >= 10 ? DateTime.tryParse(s.substring(0, 10)) : null;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// '1월 7일 (목)' 처럼 — 그 사람의 언어로.
String tourLegDay(BuildContext context, Object? date) {
  final d = _day(date);
  if (d == null) return '';
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.MMMEd(locale).format(d);
}

/// 투어 기간 '1월 7일 – 9일' 같은 짧은 표기.
String tourPeriod(BuildContext context, Map tour) {
  final a = tourLegDay(context, tour['start_date']);
  final b = tourLegDay(context, tour['end_date']);
  if (a.isEmpty) return b;
  if (b.isEmpty || a == b) return a;
  return '$a – $b';
}

/// 구간 하나를 보여 주는 카드. 누르면 [onTap].
class TourLegCard extends StatelessWidget {
  const TourLegCard({
    super.key,
    required this.leg,
    required this.tourName,
    this.onTap,
  });

  final Map<String, dynamic> leg;
  final String? tourName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final estimated = leg['estimated'] == true;
    final kind = leg['kind'];
    final color = kind == 'other' ? theme.colorScheme.primary : tourLegColor;
    final title = [
      tourLegKindLabel(l10n, kind),
      if (tourName != null && tourName!.isNotEmpty) tourName!,
    ].join(' · ');
    final head = [
      tourLegDay(context, leg['date']),
      if ('${leg['flight_no'] ?? ''}'.isNotEmpty) '${leg['flight_no']}',
    ].where((s) => s.isNotEmpty).join(' · ');
    final route = [
      [
        '${leg['from'] ?? ''}',
        '${leg['to'] ?? ''}',
      ].where((s) => s.isNotEmpty).join(' → '),
      '${leg['time'] ?? ''}',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estimated ? const Color(0xFFD9A441) : theme.dividerColor,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  _Badge(
                    text: estimated ? l10n.tfNoTicket : l10n.tfConfirmed,
                    warn: estimated,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (head.isNotEmpty)
                Text(
                  head,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (route.isNotEmpty)
                Text(
                  route,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if ('${leg['note'] ?? ''}'.isNotEmpty)
                Text(
                  '${leg['note']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.warn});
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: warn ? const Color(0xFFFFF1D6) : const Color(0xFFE3F4E8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: warn ? const Color(0xFF7A4A00) : const Color(0xFF1E6B30),
      ),
    ),
  );
}

/// 점선 "더하기" 단추. 비어 있는 자리를 보여 주는 데도 쓴다.
class TourLegAddButton extends StatelessWidget {
  const TourLegAddButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.add, size: 18, color: c),
      label: Text(label, style: TextStyle(color: c)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        side: BorderSide(color: c.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// 시트를 닫은 결과. [delete] 면 그 구간을 지운다.
class TourLegResult {
  const TourLegResult.save(this.leg) : delete = false;
  const TourLegResult.remove() : leg = null, delete = true;
  final Map<String, dynamic>? leg;
  final bool delete;
}

/// 구간 하나를 적거나 고친다.
///
/// [tours]: 이 사람이 고른 투어(`id`, `name`, `name_i18n`, `start_date`,
/// `end_date`). 하나뿐이면 고를 것 없이 그 투어로 정한다.
/// [first]·[last]: 날짜를 고를 수 있는 구간. 수양회 앞뒤로 좁혀 둔다 —
/// 오늘 날짜로 열리면 확인만 눌러도 오늘이 들어간다(flight_date_window.dart).
Future<TourLegResult?> showTourLegSheet(
  BuildContext context, {
  Map<String, dynamic>? leg,
  String initialKind = 'tour_out',
  String? initialTourId,
  required List<Map<String, dynamic>> tours,
  required bool hasCompanions,
  required DateTime first,
  required DateTime last,
}) {
  return showModalBottomSheet<TourLegResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TourLegSheet(
      leg: leg,
      initialKind: initialKind,
      initialTourId: initialTourId,
      tours: tours,
      hasCompanions: hasCompanions,
      first: first,
      last: last,
    ),
  );
}

class _TourLegSheet extends StatefulWidget {
  const _TourLegSheet({
    required this.leg,
    required this.initialKind,
    required this.initialTourId,
    required this.tours,
    required this.hasCompanions,
    required this.first,
    required this.last,
  });

  final Map<String, dynamic>? leg;
  final String initialKind;
  final String? initialTourId;
  final List<Map<String, dynamic>> tours;
  final bool hasCompanions;
  final DateTime first;
  final DateTime last;

  @override
  State<_TourLegSheet> createState() => _TourLegSheetState();
}

class _TourLegSheetState extends State<_TourLegSheet> {
  late String _kind;
  String? _tourId;
  DateTime? _date;
  late bool _estimated;
  late bool _withCompanions;
  late final TextEditingController _flightNo;
  late final TextEditingController _from;
  late final TextEditingController _to;
  late final TextEditingController _time;
  late final TextEditingController _note;
  String _airline = '';
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final l = widget.leg ?? const {};
    _kind = tourLegKinds.contains(l['kind'])
        ? l['kind'] as String
        : widget.initialKind;
    final ids = widget.tours.map((t) => '${t['id']}').toList();
    final wanted = (l['tour_id'] as String?) ?? widget.initialTourId;
    _tourId = ids.contains(wanted)
        ? wanted
        : (ids.length == 1 ? ids.first : null);
    _date = _day(l['date']);
    _estimated = l['estimated'] == true;
    _withCompanions = l['with_companions'] == true;
    _flightNo = TextEditingController(text: '${l['flight_no'] ?? ''}');
    _from = TextEditingController(text: '${l['from'] ?? ''}');
    _to = TextEditingController(text: '${l['to'] ?? ''}');
    _time = TextEditingController(text: '${l['time'] ?? ''}');
    _note = TextEditingController(text: '${l['note'] ?? ''}');
    _airline = '${l['airline'] ?? ''}';
  }

  @override
  void dispose() {
    _flightNo.dispose();
    _from.dispose();
    _to.dispose();
    _time.dispose();
    _note.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _tour =>
      widget.tours.where((t) => '${t['id']}' == _tourId).firstOrNull;

  /// 고르개를 어느 날에 열지. 가는 편은 투어 첫날, 돌아오는 편은 끝날.
  DateTime _suggestedDay() {
    final t = _tour;
    final d =
        _date ??
        (t == null
            ? null
            : _day(_kind == 'tour_return' ? t['end_date'] : t['start_date']));
    final pick = d ?? widget.first;
    if (pick.isBefore(widget.first)) return widget.first;
    if (pick.isAfter(widget.last)) return widget.last;
    return pick;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _suggestedDay(),
      firstDate: widget.first,
      lastDate: widget.last,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _search() async {
    final no = _flightNo.text.trim();
    if (no.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    final info = await FlightApiService.fetchFlightInfo(no);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _searching = false;
      if (info == null) {
        _error = l10n.flightNotFound;
        return;
      }
      _airline = info.airline;
      _from.text = info.departureAirport;
      _to.text = info.arrivalAirport;
      final dep = info.scheduledDeparture?.toLocal();
      if (dep != null) {
        _date = DateTime(dep.year, dep.month, dep.day);
        _time.text =
            '${dep.hour.toString().padLeft(2, '0')}:${dep.minute.toString().padLeft(2, '0')}';
      }
    });
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final no = _estimated ? '' : _flightNo.text.trim().toUpperCase();
    if (_date == null && no.isEmpty) {
      setState(() => _error = l10n.tfNeedSomething);
      return;
    }
    Navigator.of(context).pop(
      TourLegResult.save({
        'kind': _kind,
        'tour_id': _kind == 'other' ? null : _tourId,
        'date': _date == null ? null : _ymd(_date!),
        'time': _estimated ? null : _time.text.trim(),
        'flight_no': no,
        'airline': _estimated ? '' : _airline,
        'from': _from.text.trim(),
        'to': _to.text.trim(),
        'estimated': _estimated,
        'note': _note.text.trim(),
        'with_companions': widget.hasCompanions && _withCompanions,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final muted = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tfSheetTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.tfWhichKind, style: muted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in tourLegKinds)
                  ChoiceChip(
                    label: Text(tourLegKindLabel(l10n, k)),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            if (_kind != 'other' && widget.tours.length > 1) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tourId,
                decoration: InputDecoration(labelText: l10n.tfTour),
                items: [
                  for (final t in widget.tours)
                    DropdownMenuItem(
                      value: '${t['id']}',
                      child: Text(
                        '${tourNameOf(t, lang)} (${tourPeriod(context, t)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _tourId = v),
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                isEmpty: _date == null,
                decoration: InputDecoration(
                  labelText: l10n.tfDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _date == null ? '' : tourLegDay(context, _ymd(_date!)),
                ),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _estimated,
              onChanged: (v) => setState(() => _estimated = v ?? false),
              title: Text(l10n.tfNotBooked),
            ),
            if (!_estimated) ...[
              TextField(
                controller: _flightNo,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.flightNumber,
                  hintText: l10n.flightNumberHint,
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: l10n.flightAutoSearch,
                          onPressed: _search,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _time,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(labelText: l10n.tfTime),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _from,
                    decoration: InputDecoration(labelText: l10n.tfFrom),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _to,
                    decoration: InputDecoration(labelText: l10n.tfTo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.tfNote),
            ),
            if (widget.hasCompanions)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _withCompanions,
                onChanged: (v) => setState(() => _withCompanions = v ?? false),
                title: Text(l10n.tfWithCompanions),
              ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.leg != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const TourLegResult.remove()),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: Text(l10n.tfDeleteLeg),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l10n.actionSave),
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

/// 날짜를 고를 수 있는 구간: 수양회 30일 전부터, 수양회와 투어 중 늦게
/// 끝나는 날 30일 뒤까지.
({DateTime first, DateTime last}) tourLegWindow(
  Map program,
  List<Map<String, dynamic>> tours,
) {
  final start = _day(program['start_date']);
  var end = _day(program['end_date']) ?? start;
  for (final t in tours) {
    final e = _day(t['end_date']);
    if (e != null && (end == null || e.isAfter(end))) end = e;
  }
  if (start == null || end == null) {
    return (first: DateTime(2020), last: DateTime(2035));
  }
  return (
    first: start.subtract(const Duration(days: 30)),
    last: end.add(const Duration(days: 30)),
  );
}

/// 이 사람이 고른 투어만, 시작일 순으로.
List<Map<String, dynamic>> pickedTours(
  Object? allOptions,
  Iterable<Object?> selectedIds,
) {
  final ids = selectedIds.map((e) => '$e').toSet();
  final list = ((allOptions as List?) ?? const [])
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .where((t) => ids.contains('${t['id']}'))
      .toList();
  list.sort(
    (a, b) => '${a['start_date'] ?? '9999'}'.compareTo(
      '${b['start_date'] ?? '9999'}',
    ),
  );
  return list;
}
