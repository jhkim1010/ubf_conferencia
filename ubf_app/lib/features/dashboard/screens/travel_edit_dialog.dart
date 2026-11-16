import 'package:flutter/material.dart';
import 'package:mana/l10n/app_localizations.dart';

import '../../../core/utils/money.dart';

/// 담당자가 한 사람의 비행 일정·전후 숙박을 고치는 창.
///
/// "비행기가 바뀌었어요" 를 전화로만 알려 오는 사람이 많다. 본인이 앱을
/// 다시 열기를 기다리면 배차와 방이 옛 일정으로 잡힌다.
///
/// **박수는 여기서 정하지 않는다.** 서버가 비행 일정에서 다시 센다(060) —
/// 담당자가 따로 적게 하면 등록 화면과 두 벌이 되고, 언젠가 갈라진다.
/// 비행 일정이 아예 없는 사람(차로 오는 사람, 066)만 박수를 직접 적는다.
///
/// 손댄 칸만 돌려준다. 손대지 않은 칸까지 보내면, 이 창이 모르는 값(예:
/// 지금은 없어진 숙박 수준)을 담당자도 모르게 지운다.
/// 저장하지 않고 닫으면 null 이다.
Future<Map<String, dynamic>?> showTravelEditDialog(
  BuildContext context, {
  required Map<String, dynamic> reg,
  required Map<String, dynamic>? program,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _TravelEditDialog(reg: reg, program: program),
  );
}

/// 항공편 하나의 고칠 거리.
class _FlightDraft {
  _FlightDraft(this.isArrival, Map? raw)
    : original = raw == null ? null : Map<String, dynamic>.from(raw),
      present = raw != null {
    final o = original ?? const {};
    flightNo = TextEditingController(text: '${o['flight_no'] ?? ''}');
    airport = TextEditingController(text: '${o[_airportKey] ?? ''}');
    note = TextEditingController(text: '${o['note'] ?? ''}');
    estimated = o['estimated'] == true;
    final when = '${o[_whenKey] ?? ''}';
    // 앞 열 글자가 그날이다. DateTime.parse 로 통째로 읽으면 시간대가
    // 바뀌며 하루가 밀린다(hotel_nights.dart 와 같은 함정).
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(when)) {
      date = DateTime(
        int.parse(when.substring(0, 4)),
        int.parse(when.substring(5, 7)),
        int.parse(when.substring(8, 10)),
      );
      final t = RegExp(r'T(\d{2}):(\d{2})').firstMatch(when);
      // 자정은 "시각을 모름" 으로 적혀 온 것이다 — 달력으로 날짜만 고른 사람.
      if (t != null && !(t.group(1) == '00' && t.group(2) == '00')) {
        time = TimeOfDay(
          hour: int.parse(t.group(1)!),
          minute: int.parse(t.group(2)!),
        );
      }
    }
  }

  final bool isArrival;
  final Map<String, dynamic>? original;
  bool present;
  bool touched = false;
  bool whenTouched = false;
  late final TextEditingController flightNo;
  late final TextEditingController airport;
  late final TextEditingController note;
  late bool estimated;
  DateTime? date;
  TimeOfDay? time;

  String get _airportKey => isArrival ? 'arrival_airport' : 'departure_airport';
  String get _whenKey =>
      isArrival ? 'scheduled_arrival' : 'scheduled_departure';

  /// 그 지역 시각 그대로, 시간대 없이 적는다 — 등록 화면이 적는 꼴과 같다.
  String? _when() {
    final d = date;
    if (d == null) return null;
    final t = time ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute).toIso8601String();
  }

  /// 보낼 값. 지웠으면 null.
  Map<String, dynamic>? toJson() {
    if (!present) return null;
    return {
      // 이 창에 없는 칸(항공사·터미널·조회 상태)은 그대로 둔다.
      ...?original,
      // 예매 전이면 편명이 없다 — 등록 화면도 그렇게 적는다(021).
      'flight_no': estimated ? '' : flightNo.text.trim(),
      _airportKey: airport.text.trim(),
      'note': note.text.trim(),
      'estimated': estimated,
      // 날짜를 안 건드렸으면 원래 문자열을 그대로 둔다. 다시 만들면 시간대
      // 표기(Z 등)가 바뀌어 같은 날이 다른 날로 읽힐 수 있다.
      _whenKey: whenTouched ? _when() : original?[_whenKey],
    };
  }

  bool get hasDate => present && date != null;

  void dispose() {
    flightNo.dispose();
    airport.dispose();
    note.dispose();
  }
}

class _TravelEditDialog extends StatefulWidget {
  const _TravelEditDialog({required this.reg, required this.program});

  final Map<String, dynamic> reg;
  final Map<String, dynamic>? program;

  @override
  State<_TravelEditDialog> createState() => _TravelEditDialogState();
}

class _TravelEditDialogState extends State<_TravelEditDialog> {
  late final _FlightDraft _arr;
  late final _FlightDraft _dep;
  late String? _hotelKey;
  late bool _beforeSelf;
  late bool _afterSelf;
  late final TextEditingController _nightsBefore;
  late final TextEditingController _nightsAfter;
  final Set<String> _changed = {};

  List<Map<String, dynamic>> get _options =>
      ((widget.program?['hotel_options'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

  @override
  void initState() {
    super.initState();
    final r = widget.reg;
    _arr = _FlightDraft(true, r['arrival_flight'] as Map?);
    _dep = _FlightDraft(false, r['departure_flight'] as Map?);
    _hotelKey = r['hotel_option_key'] as String?;
    _beforeSelf = r['hotel_before_self'] == true;
    _afterSelf = r['hotel_after_self'] == true;
    _nightsBefore = TextEditingController(
      text: '${(r['hotel_nights_before'] as num?)?.toInt() ?? 0}',
    );
    _nightsAfter = TextEditingController(
      text: '${(r['hotel_nights_after'] as num?)?.toInt() ?? 0}',
    );
  }

  @override
  void dispose() {
    _arr.dispose();
    _dep.dispose();
    _nightsBefore.dispose();
    _nightsAfter.dispose();
    super.dispose();
  }

  Map<String, dynamic> _changes() => {
    if (_arr.touched) 'arrivalFlight': _arr.toJson(),
    if (_dep.touched) 'departureFlight': _dep.toJson(),
    if (_changed.contains('hotel')) 'hotelOptionKey': _hotelKey,
    if (_changed.contains('beforeSelf')) 'hotelBeforeSelf': _beforeSelf,
    if (_changed.contains('afterSelf')) 'hotelAfterSelf': _afterSelf,
    if (_changed.contains('nightsBefore'))
      'hotelNightsBefore': int.tryParse(_nightsBefore.text.trim()) ?? 0,
    if (_changed.contains('nightsAfter'))
      'hotelNightsAfter': int.tryParse(_nightsAfter.text.trim()) ?? 0,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final options = _options;
    // 지금 값이 목록에 없으면(수준을 없앴거나 이름을 바꿨으면) 고른 것이
    // 없는 것처럼 보이게 둔다. 손대지 않으면 보내지도 않는다.
    final keyInList = options.any((o) => o['key'] == _hotelKey);
    final anyDate = _arr.hasDate || _dep.hasDate;

    return AlertDialog(
      title: Text(
        '${widget.reg['real_name'] ?? ''} · ${l10n.travelEdit}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _flightSection(l10n, _arr, l10n.flightArrival),
              const Divider(height: 28),
              _flightSection(l10n, _dep, l10n.flightDeparture),
              const Divider(height: 28),
              Text(
                l10n.hotelSectionTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (options.isEmpty)
                Text(
                  l10n.hotelNoOptions,
                  style: const TextStyle(fontSize: 12.5),
                )
              else
                DropdownButtonFormField<String?>(
                  initialValue: keyInList ? _hotelKey : null,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.hotelNone)),
                    for (final o in options)
                      DropdownMenuItem(
                        value: o['key'] as String?,
                        child: Text(
                          optionLabelFor(o, lang),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _hotelKey = v;
                    _changed.add('hotel');
                  }),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                value: _beforeSelf,
                onChanged: (v) => setState(() {
                  _beforeSelf = v ?? false;
                  _changed.add('beforeSelf');
                }),
                title: Text(l10n.travelSelfBefore),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                value: _afterSelf,
                onChanged: (v) => setState(() {
                  _afterSelf = v ?? false;
                  _changed.add('afterSelf');
                }),
                title: Text(l10n.travelSelfAfter),
              ),
              // 비행 일정이 있으면 박수는 거기서 나온다. 없을 때만 적는다.
              if (!anyDate)
                Row(
                  children: [
                    Expanded(
                      child: _nightsField(
                        l10n.hotelNightsBefore,
                        _nightsBefore,
                        'nightsBefore',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _nightsField(
                        l10n.hotelNightsAfter,
                        _nightsAfter,
                        'nightsAfter',
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l10n.travelNightsFromFlights,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          // 바꾼 것이 없으면 보낼 것도 없다.
          onPressed: () {
            final c = _changes();
            Navigator.pop(context, c.isEmpty ? null : c);
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }

  Widget _nightsField(String label, TextEditingController c, String key) =>
      TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => _changed.add(key),
      );

  Widget _flightSection(AppLocalizations l10n, _FlightDraft f, String dir) {
    void touch(VoidCallback fn) => setState(() {
      fn();
      f.touched = true;
    });

    final header = Row(
      children: [
        Expanded(
          child: Text(
            f.isArrival ? l10n.regStepArrival : l10n.regStepDeparture,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (f.present)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(l10n.travelRemoveFlight),
            onPressed: () => touch(() => f.present = false),
          ),
      ],
    );

    if (!f.present) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Row(
            children: [
              Text(
                l10n.travelNoFlight,
                style: const TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.travelAddFlight),
                onPressed: () => touch(() => f.present = true),
              ),
            ],
          ),
        ],
      );
    }

    final loc = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          value: f.estimated,
          onChanged: (v) => touch(() => f.estimated = v ?? false),
          title: Text(l10n.travelEstimated),
        ),
        if (!f.estimated)
          TextField(
            controller: f.flightNo,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.flightNumber),
            onChanged: (_) => f.touched = true,
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                f.date == null
                    ? l10n.flightPickDate
                    : loc.formatMediumDate(f.date!),
              ),
              onPressed: () async {
                final start = DateTime.tryParse(
                  '${widget.program?['start_date'] ?? ''}'.padRight(10),
                );
                final base = f.date ?? start ?? DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: base,
                  firstDate: DateTime(base.year - 2),
                  lastDate: DateTime(base.year + 3),
                );
                if (picked == null) return;
                touch(() {
                  f.date = picked;
                  f.whenTouched = true;
                });
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule, size: 16),
              label: Text(
                f.time == null
                    ? l10n.travelTimeNone
                    : loc.formatTimeOfDay(f.time!),
              ),
              onPressed: f.date == null
                  ? null
                  : () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime:
                            f.time ?? const TimeOfDay(hour: 12, minute: 0),
                      );
                      if (picked == null) return;
                      touch(() {
                        f.time = picked;
                        f.whenTouched = true;
                      });
                    },
            ),
          ],
        ),
        TextField(
          controller: f.airport,
          decoration: InputDecoration(labelText: l10n.flightAirportLabel(dir)),
          onChanged: (_) => f.touched = true,
        ),
        TextField(
          controller: f.note,
          decoration: InputDecoration(labelText: l10n.flightNoteLabel),
          onChanged: (_) => f.touched = true,
        ),
      ],
    );
  }
}
