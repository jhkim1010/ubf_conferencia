import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/world_countries.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/child_fee.dart';
import '../../../core/utils/i18n_text.dart';
import '../../../core/utils/money.dart';
import '../../program/providers/program_provider.dart';
import '../../registration/providers/registration_provider.dart'
    show sortTourLegs, tourLegsFrom;
import '../../registration/screens/steps/companion_step.dart';
import '../../registration/widgets/tour_legs.dart';
import 'travel_edit_dialog.dart';
import 'package:mana/l10n/app_localizations.dart';

/// 담당자가 명단에서 한 사람을 열어 고친다 — 기본 정보 · 동반자 · 투어 · 항공·숙박.
///
/// 전화로 "이름이 틀렸어요", "아이 하나 더 데려가요", "이과수는 빼 주세요",
/// "비행기가 바뀌었어요" 를 듣는 사람이 담당자다. 지금까지는 본인에게 앱에
/// 다시 들어가 고치라고 하는 수밖에 없었다.
///
/// 낼 돈은 어느 탭에서 고쳐도 **서버가 다시 센다.** 화면은 돌려받은 값을
/// 보여 줄 뿐이다. 하나라도 저장하면 [onChanged] 를 불러 명단을 다시 읽게 한다.
Future<void> showParticipantEditor(
  BuildContext context, {
  required String programId,
  required Map<String, dynamic> reg,
  required Map<String, dynamic>? program,
  required Currency currency,
  required VoidCallback onChanged,
  VoidCallback? onPayment,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ParticipantEditor(
      programId: programId,
      reg: Map<String, dynamic>.from(reg),
      program: program ?? const {},
      currency: currency,
      onChanged: onChanged,
      onPayment: onPayment,
    ),
  );
}

/// 명단 표가 아닌 곳(준비 현황 · 투어 신청 · 투어 이동)에서 한 사람을 연다.
///
/// 담당자는 사람을 **보는 자리에서** 고치고 싶어 한다. 이름은 여러 화면에
/// 보이는데 고치는 길은 명단 표 하나뿐이라, 공동 관리자들이 "고칠 수가
/// 없다" 고 여겼다. 그 화면들의 이름을 누르면 이 창이 뜨게 한다.
///
/// 명단 줄을 다시 받아 온다 — 각 화면이 들고 있는 것은 이름 정도뿐이다.
/// 명단을 볼 권한(registration)이 없는 담당자에게는 서버가 막고, 그 말을
/// 그대로 보여 준다.
Future<void> openParticipantById(
  BuildContext context,
  WidgetRef ref, {
  required String programId,
  required String registrationId,
  VoidCallback? onChanged,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final rows = await ApiClient.getProgramRegistrations(programId);
    final reg = rows
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .where((r) => r['id'] == registrationId)
        .firstOrNull;
    final program = await ApiClient.getProgram(programId);
    if (reg == null || !context.mounted) return;
    await showParticipantEditor(
      context,
      programId: programId,
      reg: reg,
      program: program,
      currency: Currency.of(program?['currency'] as String?),
      onChanged: () {
        ref.invalidate(programRegistrationsProvider(programId));
        ref.invalidate(programStatsProvider(programId));
        onChanged?.call();
      },
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e is ApiException ? e.message : '$e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _ParticipantEditor extends StatefulWidget {
  const _ParticipantEditor({
    required this.programId,
    required this.reg,
    required this.program,
    required this.currency,
    required this.onChanged,
    this.onPayment,
  });

  final String programId;

  /// 이 창이 들고 있는 사본. 저장할 때마다 돌려받은 값으로 고친다.
  final Map<String, dynamic> reg;
  final Map<String, dynamic> program;
  final Currency currency;
  final VoidCallback onChanged;
  final VoidCallback? onPayment;

  @override
  State<_ParticipantEditor> createState() => _ParticipantEditorState();
}

class _ParticipantEditorState extends State<_ParticipantEditor> {
  /// 동반자를 저장할 때마다 오른다. 투어 탭이 동반자를 다시 읽는 신호다 —
  /// 방금 더한 아이가 투어 탭에 안 보이면 안 된다.
  int _companionsVersion = 0;

  String get _id => widget.reg['id'] as String;

  void _changed([Map<String, dynamic>? fields]) {
    if (fields != null) {
      setState(() {
        for (final e in fields.entries) {
          if (e.value != null) widget.reg[e.key] = e.value;
        }
      });
    }
    widget.onChanged();
  }

  String get _title {
    final real = '${widget.reg['real_name'] ?? ''}'.trim();
    final bible = '${widget.reg['bible_name'] ?? ''}'.trim();
    return bible.isEmpty || bible == real ? real : '$real ($bible)';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final narrow = size.width < 700;
    return Dialog(
      insetPadding: narrow ? EdgeInsets.zero : const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: narrow ? size.width : 1040,
        height: narrow ? size.height : size.height * 0.88,
        // 알림은 이 창 안에만 띄운다. 바깥 명단 화면에도 같은 알림이 겹쳐
        // 뜨면 어느 쪽 이야기인지 헷갈린다.
        child: ScaffoldMessenger(
          child: DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                title: Text(_title),
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (widget.onPayment != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onPayment!();
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(l10n.pePayment),
                    ),
                  const SizedBox(width: 8),
                ],
                bottom: TabBar(
                  isScrollable: narrow,
                  tabs: [
                    Tab(text: l10n.peTabBasic),
                    Tab(text: l10n.peTabCompanions),
                    Tab(text: l10n.peTabTours),
                    Tab(text: l10n.peTabTravel),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _ProfileTab(
                    programId: widget.programId,
                    reg: widget.reg,
                    program: widget.program,
                    currency: widget.currency,
                    onSaved: _changed,
                  ),
                  CompanionStep(
                    programId: widget.programId,
                    program: widget.program,
                    currency: widget.currency,
                    registration: widget.reg,
                    load: () =>
                        ApiClient.getCompanionsAdmin(widget.programId, _id),
                    save: (payload) => ApiClient.saveCompanionsAdmin(
                      widget.programId,
                      _id,
                      payload,
                    ),
                    onSaved: () {
                      if (mounted) setState(() => _companionsVersion++);
                      widget.onChanged();
                    },
                  ),
                  _ToursTab(
                    key: ValueKey('tours$_companionsVersion'),
                    programId: widget.programId,
                    reg: widget.reg,
                    program: widget.program,
                    currency: widget.currency,
                    onSaved: _changed,
                  ),
                  _TravelTab(
                    programId: widget.programId,
                    reg: widget.reg,
                    program: widget.program,
                    currency: widget.currency,
                    onSaved: _changed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), backgroundColor: error ? Colors.red : null),
  );
}

// ── 기본 정보 ─────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.programId,
    required this.reg,
    required this.program,
    required this.currency,
    required this.onSaved,
  });

  final String programId;
  final Map<String, dynamic> reg;
  final Map<String, dynamic> program;
  final Currency currency;
  final void Function([Map<String, dynamic>? fields]) onSaved;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab>
    with AutomaticKeepAliveClientMixin {
  late final _real = TextEditingController(text: _s('real_name'));
  late final _bible = TextEditingController(text: _s('bible_name'));
  late final _branch = TextEditingController(text: _s('branch'));
  late final _phone = TextEditingController(text: _s('phone'));
  late final _age = TextEditingController(text: _s('age'));
  late final _food = TextEditingController(text: _s('food_requirements'));
  late String? _gender = widget.reg['gender'] as String?;
  // 나라는 ISO 로 저장한다. 예전 표기도 ISO 로 읽어 고른다.
  late String? _country = WorldCountries.isoForLegacy(
    widget.reg['country'] as String?,
  );
  late String? _tier = widget.reg['fee_tier'] as String?;
  bool _saving = false;

  String _s(String k) => widget.reg[k] == null ? '' : '${widget.reg[k]}';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    for (final c in [_real, _bible, _branch, _phone, _age, _food]) {
      c.dispose();
    }
    super.dispose();
  }

  /// 바뀐 칸만 보낸다 — 안 바꾼 칸을 보내면 그사이 본인이 고친 것을 덮는다.
  Map<String, dynamic> _changes() {
    final out = <String, dynamic>{};
    void text(String key, String col, TextEditingController c) {
      final now = c.text.trim();
      if (now != _s(col).trim()) out[key] = now.isEmpty ? null : now;
    }

    text('realName', 'real_name', _real);
    text('bibleName', 'bible_name', _bible);
    text('branch', 'branch', _branch);
    text('phone', 'phone', _phone);
    text('foodRequirements', 'food_requirements', _food);
    final age = int.tryParse(_age.text.trim());
    if ('${age ?? ''}' != _s('age')) out['age'] = age;
    if (_gender != widget.reg['gender']) out['gender'] = _gender;
    final savedCountry = WorldCountries.isoForLegacy(
      widget.reg['country'] as String?,
    );
    if (_country != savedCountry) out['country'] = _country;
    if (_tier != null && _tier != widget.reg['fee_tier']) {
      out['feeTier'] = _tier;
    }
    return out;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final changes = _changes();
    if (changes.isEmpty) {
      _snack(context, l10n.peNothingChanged);
      return;
    }
    setState(() => _saving = true);
    try {
      final row = await ApiClient.updateRegistrationAdmin(
        widget.programId,
        widget.reg['id'] as String,
        profile: changes,
      );
      widget.onSaved({
        for (final k in [
          'real_name',
          'bible_name',
          'country',
          'branch',
          'gender',
          'age',
          'phone',
          'food_requirements',
          'fee_tier',
          'total_cost',
        ])
          k: row[k],
      });
      // 비운 칸은 위에서 null 이라 안 들어간다 — 여기서 비운다.
      for (final e in changes.entries) {
        if (e.value == null) {
          final col = switch (e.key) {
            'bibleName' => 'bible_name',
            'foodRequirements' => 'food_requirements',
            'age' => 'age',
            'gender' => 'gender',
            'country' => 'country',
            'branch' => 'branch',
            'phone' => 'phone',
            _ => null,
          };
          if (col != null) widget.reg[col] = null;
        }
      }
      if (mounted) _snack(context, l10n.commonSaved);
    } catch (e) {
      if (mounted) {
        _snack(context, e is ApiException ? e.message : '$e', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final fees = [
      if (Money.parse(widget.program['fee_basic']) != null)
        ('basic', l10n.feeTierBasic),
      if (Money.parse(widget.program['fee_premium']) != null)
        ('premium', l10n.feeTierPremium),
    ];
    final countries = [
      // 목록에 없는 예전 값도 고를 수 있게 남긴다 — 사라지면 저장할 때 지워진다.
      if (_country != null && !WorldCountries.isKnown(_country))
        DropdownMenuItem(value: _country, child: Text(_country!)),
      for (final c in WorldCountries.all)
        DropdownMenuItem(value: c.iso, child: Text(c.name)),
    ];
    Widget pair(Widget a, Widget b) => LayoutBuilder(
      builder: (context, box) => box.maxWidth < 520
          ? Column(children: [a, const SizedBox(height: 12), b])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: a),
                const SizedBox(width: 12),
                Expanded(child: b),
              ],
            ),
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        pair(
          TextField(
            controller: _real,
            decoration: InputDecoration(labelText: l10n.regRealName),
          ),
          TextField(
            controller: _bible,
            decoration: InputDecoration(labelText: l10n.regBibleName),
          ),
        ),
        const SizedBox(height: 12),
        pair(
          DropdownButtonFormField<String>(
            initialValue: _country,
            isExpanded: true,
            items: countries,
            onChanged: (v) => setState(() => _country = v),
            decoration: InputDecoration(labelText: l10n.summaryCountry),
          ),
          TextField(
            controller: _branch,
            decoration: InputDecoration(labelText: l10n.regBranch),
          ),
        ),
        const SizedBox(height: 12),
        pair(
          Row(
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l10n.summaryAge),
                ),
              ),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'M', label: Text(l10n.genderMale)),
                  ButtonSegment(value: 'F', label: Text(l10n.genderFemale)),
                ],
                selected: {?_gender},
                emptySelectionAllowed: true,
                onSelectionChanged: (s) =>
                    setState(() => _gender = s.isEmpty ? null : s.first),
              ),
            ],
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.regPhone),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _food,
          decoration: InputDecoration(labelText: l10n.foodRestrictionTitle),
        ),
        if (fees.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.rdyFeeTier,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: [
              for (final (key, label) in fees)
                ButtonSegment(value: key, label: Text(label)),
            ],
            selected: {?_tier},
            emptySelectionAllowed: true,
            onSelectionChanged: (s) =>
                setState(() => _tier = s.isEmpty ? _tier : s.first),
          ),
        ],
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.actionSave),
          ),
        ),
      ],
    );
  }
}

// ── 투어 ─────────────────────────────────────────────────────

class _ToursTab extends StatefulWidget {
  const _ToursTab({
    super.key,
    required this.programId,
    required this.reg,
    required this.program,
    required this.currency,
    required this.onSaved,
  });

  final String programId;
  final Map<String, dynamic> reg;
  final Map<String, dynamic> program;
  final Currency currency;
  final void Function([Map<String, dynamic>? fields]) onSaved;

  @override
  State<_ToursTab> createState() => _ToursTabState();
}

class _ToursTabState extends State<_ToursTab> {
  late final Set<String> _picked = {
    for (final id in (widget.reg['selected_options'] as List?) ?? const [])
      '$id',
  };

  /// 함께 등록한 동반자들과, 사람마다 가는 투어.
  List<Map<String, dynamic>> _companions = [];
  final Map<String, Set<String>> _goes = {};
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> get _tours =>
      ((widget.program['program_options'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ApiClient.getCompanionsAdmin(
        widget.programId,
        widget.reg['id'] as String,
      );
      if (!mounted) return;
      setState(() {
        _companions = rows
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .where((c) => c['registers_separately'] == false)
            .toList();
        for (final c in _companions) {
          _goes['${c['id']}'] = companionTourIds(c).toSet();
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final r = await ApiClient.updateToursAdmin(
        widget.programId,
        widget.reg['id'] as String,
        selectedOptions: _picked.toList(),
        companionTours: {
          for (final t in _picked)
            t: [
              for (final e in _goes.entries)
                if (e.value.contains(t)) e.key,
            ],
        },
      );
      widget.onSaved({
        'selected_options': r['selected_options'],
        'hotel_nights_before': r['hotel_nights_before'],
        'hotel_nights_after': r['hotel_nights_after'],
        'total_cost': r['total_cost'],
      });
      if (mounted) {
        _snack(
          context,
          l10n.peSavedTotal(
            widget.currency.format(Money.parse(r['total_cost']) ?? 0),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _snack(context, e is ApiException ? e.message : '$e', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    if (_loading) return const Center(child: CircularProgressIndicator());
    final tours = _tours;
    if (tours.isEmpty) return Center(child: Text(l10n.optionsNone));

    double total = 0;
    final cards = <Widget>[];
    for (final t in tours) {
      final id = '${t['id']}';
      final on = _picked.contains(id);
      final cost = (Money.parse(t['cost']) ?? 0).toDouble();
      final heads = 1 + _goes.values.where((s) => on && s.contains(id)).length;
      if (on) total += cost * heads;
      cards.add(
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  value: on,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _picked.add(id);
                    } else {
                      _picked.remove(id);
                    }
                  }),
                  title: Text(
                    pickI18n(t['nameI18n'], lang, t['name']) ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  secondary: Text(widget.currency.format(cost)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                // 대표자가 가는 투어에만 동반자를 넣는다 — 서버도 그렇다.
                if (on && _companions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.peTourCompanions,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final c in _companions)
                              FilterChip(
                                label: Text('${c['real_name'] ?? ''}'),
                                selected:
                                    _goes['${c['id']}']?.contains(id) ?? false,
                                onSelected: (v) => setState(() {
                                  final s = _goes.putIfAbsent(
                                    '${c['id']}',
                                    () => <String>{},
                                  );
                                  v ? s.add(id) : s.remove(id);
                                }),
                              ),
                          ],
                        ),
                        if (heads > 1 && cost > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            l10n.tourCostTimes(
                              widget.currency.format(cost),
                              heads,
                              widget.currency.format(cost * heads),
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...cards,
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.optionsSelectedTotal}  ${widget.currency.format(total)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.actionSave),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 항공·숙박 ────────────────────────────────────────────────

class _TravelTab extends StatefulWidget {
  const _TravelTab({
    required this.programId,
    required this.reg,
    required this.program,
    required this.currency,
    required this.onSaved,
  });

  final String programId;
  final Map<String, dynamic> reg;
  final Map<String, dynamic> program;
  final Currency currency;
  final void Function([Map<String, dynamic>? fields]) onSaved;

  @override
  State<_TravelTab> createState() => _TravelTabState();
}

class _TravelTabState extends State<_TravelTab> {
  Future<void> _edit() async {
    final l10n = AppLocalizations.of(context)!;
    final changes = await showTravelEditDialog(
      context,
      reg: widget.reg,
      program: widget.program,
    );
    if (changes == null || !mounted) return;
    try {
      final r = await ApiClient.updateTravelAdmin(
        widget.programId,
        widget.reg['id'] as String,
        changes,
      );
      // 항공편을 지웠으면 null 이 온다 — 그대로 비운다.
      setState(() {
        widget.reg['arrival_flight'] = r['arrival_flight'];
        widget.reg['departure_flight'] = r['departure_flight'];
        widget.reg['hotel_option_key'] = r['hotel_option_key'];
      });
      widget.onSaved({
        'hotel_nights_before': r['hotel_nights_before'],
        'hotel_nights_after': r['hotel_nights_after'],
        'hotel_before_self': r['hotel_before_self'],
        'hotel_after_self': r['hotel_after_self'],
        'total_cost': r['total_cost'],
      });
      if (!mounted) return;
      _snack(
        context,
        r['hotel_dropped'] == true
            ? l10n.travelHotelDropped
            : l10n.travelSaved(
                (r['hotel_nights_before'] as num?)?.toInt() ?? 0,
                (r['hotel_nights_after'] as num?)?.toInt() ?? 0,
                widget.currency.format(Money.parse(r['total_cost']) ?? 0),
              ),
      );
    } catch (e) {
      if (mounted) {
        _snack(context, e is ApiException ? e.message : '$e', error: true);
      }
    }
  }

  // ── 투어 때 타는 비행기(081) ──

  List<Map<String, dynamic>> get _legs =>
      tourLegsFrom(widget.reg['tour_flights']);

  List<Map<String, dynamic>> get _tours => pickedTours(
    widget.program['program_options'],
    (widget.reg['selected_options'] as List?) ?? const [],
  );

  bool get _hasCompanions => ((widget.reg['companions'] as List?) ?? const [])
      .whereType<Map>()
      .any((c) => c['registersSeparately'] != true);

  Future<void> _saveTour(
    List<Map<String, dynamic>> legs, {
    bool? homeFromTour,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final r = await ApiClient.updateTravelAdmin(
        widget.programId,
        widget.reg['id'] as String,
        {
          'tourFlights': legs,
          'homeFromTour': homeFromTour ?? widget.reg['home_from_tour'] == true,
        },
      );
      setState(() {
        widget.reg['tour_flights'] = r['tour_flights'];
        widget.reg['home_from_tour'] = r['home_from_tour'];
      });
      widget.onSaved({'total_cost': r['total_cost']});
      if (mounted) _snack(context, l10n.tfSaved);
    } catch (e) {
      if (mounted) {
        _snack(context, e is ApiException ? e.message : '$e', error: true);
      }
    }
  }

  Future<void> _editLeg({int? index, String kind = 'tour_out'}) async {
    final legs = _legs;
    final tours = _tours;
    final window = tourLegWindow(widget.program, tours);
    final r = await showTourLegSheet(
      context,
      leg: index == null ? null : legs[index],
      initialKind: kind,
      tours: tours,
      hasCompanions: _hasCompanions,
      first: window.first,
      last: window.last,
    );
    if (r == null || !mounted) return;
    if (r.delete && index != null) {
      legs.removeAt(index);
    } else if (r.leg != null) {
      if (index == null) {
        legs.add(r.leg!);
      } else {
        legs[index] = r.leg!;
      }
    } else {
      return;
    }
    await _saveTour(sortTourLegs(legs));
  }

  List<Widget> _tourSection(AppLocalizations l10n) {
    final tours = _tours;
    if (tours.isEmpty && _legs.isEmpty) return const [];
    final lang = Localizations.localeOf(context).languageCode;
    final legs = _legs;
    String? tourName(Object? id) => tours
        .where((t) => '${t['id']}' == '$id')
        .map((t) => tourNameOf(t, lang))
        .firstOrNull;
    return [
      const Divider(height: 32),
      Text(
        l10n.regStepTourFlights,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (legs.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l10n.tfNoLegs, style: TextStyle(color: Colors.grey[700])),
        ),
      for (var i = 0; i < legs.length; i++) ...[
        TourLegCard(
          leg: legs[i],
          tourName: tourName(legs[i]['tour_id']),
          onTap: () => _editLeg(index: i),
        ),
        const SizedBox(height: 8),
      ],
      if (tours.isNotEmpty)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: widget.reg['home_from_tour'] == true,
          onChanged: (v) => _saveTour(
            v ? legs.where((l) => l['kind'] != 'tour_return').toList() : legs,
            homeFromTour: v,
          ),
          title: Text(l10n.tfDirectHome),
          subtitle: Text(l10n.tfDirectHomeSub),
        ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (tours.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _editLeg(kind: 'tour_out'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.tfAddOut),
            ),
          if (tours.isNotEmpty && widget.reg['home_from_tour'] != true)
            OutlinedButton.icon(
              onPressed: () => _editLeg(kind: 'tour_return'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.tfAddReturn),
            ),
          OutlinedButton.icon(
            onPressed: () => _editLeg(kind: 'other'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.tfKindOther),
          ),
        ],
      ),
    ];
  }

  String _flight(Object? f, String timeKey) {
    if (f is! Map) return '—';
    final when = '${f[timeKey] ?? ''}';
    final date = when.length >= 16
        ? '${when.substring(0, 10)} ${when.substring(11, 16)}'
        : when;
    return [
      f['flight_no'],
      f['arrival_airport'] ?? f['departure_airport'],
      date,
    ].where((x) => x != null && '$x'.trim().isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.reg;
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    final levels = ((widget.program['hotel_options'] as List?) ?? const [])
        .whereType<Map>();
    final lang = Localizations.localeOf(context).languageCode;
    final level = levels
        .where((o) => o['key'] == r['hotel_option_key'])
        .map((o) => optionLabelFor(Map<String, dynamic>.from(o), lang))
        .firstOrNull;
    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        line(l10n.peArrival, _flight(r['arrival_flight'], 'scheduled_arrival')),
        line(
          l10n.peDeparture,
          _flight(r['departure_flight'], 'scheduled_departure'),
        ),
        line(l10n.peLodging, level ?? '—'),
        line(
          l10n.peNights,
          l10n.peNightsValue(
            n(r['hotel_nights_before']),
            n(r['hotel_nights_after']),
          ),
        ),
        line(
          l10n.peTotal,
          widget.currency.format(Money.parse(r['total_cost']) ?? 0),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _edit,
            icon: const Icon(Icons.flight_outlined),
            label: Text(l10n.travelEdit),
          ),
        ),
        ..._tourSection(l10n),
      ],
    );
  }
}
