import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/api_client.dart';
import '../../../../core/utils/child_fee.dart';
import '../../../../core/utils/family_cost.dart';
import '../../../../core/utils/hotel_nights.dart';
import '../../../../core/utils/registration_cost.dart';
import '../../../../core/utils/money.dart';
import '../../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// PRD F3 — 동반 가족/참석자. **표 한 장으로 등록을 끝낸다**(078·079).
//
// 같은 비행기로 함께 오는 가족은 대표자의 등록 안에서 끝낸다. 한 줄에 한
// 사람 — 이름·나이·성별·같은 방·침대·분반·투어·같은 비행기. 줄은 마음대로
// 더하고 지운다.
//
// 예전에는 사람마다 바텀시트를 열어 열 가지를 묻고, "동반자도 각자 따로
// 등록해야 합니다" 라고 안내했다. 함께 오는 가족에게 그것은 등록을 두 번
// 하라는 말이었다.
class CompanionStep extends ConsumerStatefulWidget {
  final String programId;

  /// 서버가 준 수양회 표현. 어린이 참가비 구간(073)과 참가비 등급을 읽는다.
  final Map<String, dynamic> program;

  /// 이 수양회의 통화. 금액을 적을 때 쓴다.
  final Currency currency;

  /// 테스트에서 서버 대신 쓰는 불러오기·저장. 안 주면 ApiClient 를 쓴다.
  @visibleForTesting
  final Future<List<dynamic>> Function()? loadForTest;
  @visibleForTesting
  final Future<List<Map<String, dynamic>>> Function(
    List<Map<String, dynamic>> payload,
  )?
  saveForTest;

  const CompanionStep({
    super.key,
    required this.programId,
    required this.program,
    required this.currency,
    this.loadForTest,
    this.saveForTest,
  });

  @override
  ConsumerState<CompanionStep> createState() => _CompanionStepState();
}

/// 표의 한 줄. 입력 칸의 컨트롤러와 고른 값들을 함께 든다.
class _Row {
  _Row(this.data)
    : name = TextEditingController(text: '${data['realName'] ?? ''}'),
      age = TextEditingController(text: data['age']?.toString() ?? ''),
      flight = TextEditingController(text: '${data['arrivalFlightNo'] ?? ''}');

  /// 서버와 주고받는 값들. 표에 칸이 없는 것(성경 이름·언어·지부·픽업·
  /// 출발편)도 여기 그대로 남아 다시 저장할 때 함께 간다 — 칸이 없다고
  /// 빼면 예전에 적어 둔 것이 지워진다.
  final Map<String, dynamic> data;
  final TextEditingController name;
  final TextEditingController age;
  final TextEditingController flight;
  final FocusNode focus = FocusNode();

  /// 069 이전의 뜻대로 "본인 계정으로 따로 등록하는 분" 으로 적힌 줄.
  /// 함께 등록으로 바꾸면 그분 등록과 겹쳐 참가비가 두 번 붙는다 —
  /// 바꾸지 않고 이름만 보여 준다.
  bool get ownRegistration => data['registersSeparately'] == true;

  int? get ageValue => int.tryParse(age.text.trim());
  bool get named => name.text.trim().isNotEmpty;

  /// 침대 — 다른 방이면 늘 쓴다(077). 안 골랐으면 나이로 정한다.
  bool get bed {
    if (data['sharesRoom'] == false) return true;
    final v = data['occupiesBed'];
    if (v is bool) return v;
    final a = ageValue;
    return a == null || a > _freeAgeMax;
  }

  /// 분반(078). 안 골랐으면 나이로 정한다 — 만 5세 이하는 안 한다.
  String get study {
    final v = data['studyGroup'];
    if (v is String) return v;
    final a = ageValue;
    return a != null && a <= _freeAgeMax ? 'none' : 'same';
  }

  /// 셈과 저장에 쓰는 모양. 입력 칸의 지금 값과 나이로 정한 기본값을
  /// 풀어 넣는다.
  Map<String, dynamic> resolved() {
    final sameFlight = data['sameFlightAsPrimary'] != false;
    final flightNo = flight.text.trim().toUpperCase();
    final departure = '${data['departureFlightNo'] ?? ''}';
    return {
      ...data,
      'realName': name.text.trim(),
      'age': ageValue,
      'registersSeparately': ownRegistration,
      'occupiesBed': bed,
      'studyGroup': ownRegistration ? 'none' : study,
      'joinsTours': !ownRegistration && data['joinsTours'] == true,
      'sameFlightAsPrimary': sameFlight,
      'arrivalFlightNo': flightNo,
      'arrivalFlight': (!sameFlight && flightNo.isNotEmpty)
          ? {'flight_no': flightNo}
          : null,
      'departureFlight': (!sameFlight && departure.isNotEmpty)
          ? {'flight_no': departure}
          : null,
    };
  }

  void dispose() {
    name.dispose();
    age.dispose();
    flight.dispose();
    focus.dispose();
  }
}

/// 만 5세 이하는 침대를 기본으로 안 쓰고 분반도 안 한다.
/// 서버의 companion_role.js FREE_AGE_MAX 와 같다.
const _freeAgeMax = 5;

const _accent = Color(0xFF5B4BA0);
const _rowH = 56.0;
const _headH = 40.0;

class _CompanionStepState extends ConsumerState<CompanionStep> {
  final List<_Row> _rows = [];
  bool _loading = true;

  // 저장은 손을 멈춘 뒤 잠시 있다가 한 번에 한다. 저장 중에 또 바뀌면
  // 끝난 뒤 한 번 더 한다 — 두 저장이 겹치면 새 줄이 두 번 들어간다.
  Timer? _debounce;
  bool _saving = false;
  bool _dirty = false;
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // 손을 멈추자마자 다음 단계로 넘어가도 적은 것은 남아야 한다.
    if (_dirty) {
      final payload = _payload();
      final container = _container;
      (widget.saveForTest?.call(payload) ??
              ApiClient.saveMyCompanions(widget.programId, payload))
          .then((_) {
            container?.invalidate(myCompanionsProvider(widget.programId));
            container?.invalidate(registrationProvider(widget.programId));
          }, onError: (_) {});
    }
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows =
          await (widget.loadForTest?.call() ??
              ApiClient.getMyCompanions(widget.programId));
      if (!mounted) return;
      setState(() {
        _rows.addAll(
          rows.map((r) => _Row(_fromServer(r as Map<String, dynamic>))),
        );
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _fromServer(Map<String, dynamic> r) => {
    // 다시 저장할 때 같은 사람으로 고쳐지도록 id 를 들고 있는다(078).
    'id': r['id'],
    'realName': r['real_name'] ?? '',
    'bibleName': r['bible_name'] ?? '',
    'gender': r['gender'],
    'age': r['age'],
    'language': r['language'] ?? '',
    'branch': r['branch'] ?? '',
    'sameBranchAsPrimary': r['same_branch_as_primary'] ?? false,
    'sameFlightAsPrimary': r['same_flight_as_primary'] ?? true,
    'arrivalFlightNo': (r['arrival_flight'] as Map?)?['flight_no'] ?? '',
    'departureFlightNo': (r['departure_flight'] as Map?)?['flight_no'] ?? '',
    'needsPickup': r['needs_pickup'] ?? true,
    'registersSeparately': r['registers_separately'] ?? true,
    'occupiesBed': r['occupies_bed'] ?? true,
    'sharesRoom': r['shares_room'] ?? true,
    'studyGroup': r['study_group'] ?? 'none',
    'joinsTours': r['joins_tours'] ?? false,
    'feeShare': r['fee_share'],
  };

  /// 새 줄. 같은 방·같은 비행기·투어 함께가 기본이다 — 같은 비행기로 오는
  /// 가족은 대부분 그렇고, 아무것도 안 해도 맞는 쪽이 기본이어야 한다.
  /// 침대와 분반은 비워 두어 나이로 정하게 한다.
  _Row _newRow() => _Row({
    'registersSeparately': false,
    'sharesRoom': true,
    'sameFlightAsPrimary': true,
    'joinsTours': true,
    'sameBranchAsPrimary': true,
    'needsPickup': true,
  });

  /// 이름이 있는 줄만 보낸다. 서버도 이름 없는 줄은 건너뛴다.
  List<_Row> get _namedRows => _rows.where((r) => r.named).toList();

  List<Map<String, dynamic>> _payload() => _namedRows.map((r) {
    final c = r.resolved();
    return {
      'id': c['id'],
      'realName': c['realName'],
      'bibleName': c['bibleName'],
      'gender': c['gender'],
      'age': c['age'],
      'language': c['language'],
      'branch': c['branch'],
      'sameBranchAsPrimary': c['sameBranchAsPrimary'] != false,
      'sameFlightAsPrimary': c['sameFlightAsPrimary'],
      'arrivalFlight': c['arrivalFlight'],
      'departureFlight': c['departureFlight'],
      'needsPickup': c['needsPickup'] ?? true,
      'registersSeparately': c['registersSeparately'],
      'occupiesBed': c['occupiesBed'],
      'sharesRoom': c['sharesRoom'] ?? true,
      'studyGroup': c['studyGroup'],
      'joinsTours': c['joinsTours'],
      // 073. 따로 정하지 않았으면 null — 서버가 수양회 구간을 쓴다.
      'feeShare': c['feeShare'],
    };
  }).toList();

  /// 셈(합계 카드)에 쓰는 목록 — 이름이 있는 줄만.
  List<Map<String, dynamic>> get _companions =>
      _namedRows.map((r) => r.resolved()).toList();

  void _changed() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _persist);
    setState(() {});
  }

  Future<void> _persist() async {
    if (_saving) return; // 끝나면 _dirty 를 보고 다시 한다
    _saving = true;
    _dirty = false;
    final sent = _namedRows;
    var failed = false;
    try {
      final payload = _payload();
      final saved =
          await (widget.saveForTest?.call(payload) ??
              ApiClient.saveMyCompanions(widget.programId, payload));
      // 새로 넣은 사람의 id 를 받아 둔다. 서버는 보낸 순서대로 돌려준다.
      if (saved.length == sent.length) {
        for (var i = 0; i < saved.length; i++) {
          sent[i].data['id'] = saved[i]['id'];
        }
      }
      // 이름을 지운 줄은 서버에서 지워졌다 — 다시 적으면 새 사람이다.
      for (final r in _rows) {
        if (!r.named) r.data.remove('id');
      }
      // 어린이·투어·침대가 바뀌면 낼 돈이 달라진다. 서버가 다시 셈해
      // 저장하므로 비용 막대와 확인 화면이 그것을 다시 읽게 한다.
      // 그새 다음 단계로 넘어갔으면 ref 를 못 쓴다 — 붙잡아 둔 컨테이너로.
      _container?.invalidate(myCompanionsProvider(widget.programId));
      _container?.invalidate(registrationProvider(widget.programId));
    } on ApiException catch (e) {
      _dirty = true;
      failed = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      _dirty = true;
      failed = true;
    } finally {
      _saving = false;
    }
    // 저장 중에 또 바뀌었으면 한 번 더. **실패했으면 되풀이하지 않는다** —
    // 서버가 안 받는 동안 같은 요청을 계속 보내게 된다. 다음에 고치거나
    // 단계를 떠날 때 다시 보낸다(_dirty 가 남아 있다).
    if (_dirty && !failed && mounted) _changed();
  }

  void _addRow() {
    final row = _newRow();
    setState(() => _rows.add(row));
    // 바로 이름을 칠 수 있게.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) row.focus.requestFocus();
    });
  }

  void _removeRow(_Row r) {
    setState(() => _rows.remove(r));
    r.dispose();
    _changed();
  }

  /// 마지막 줄에서 Enter 를 누르면 새 줄을 연다.
  void _submitted(_Row r) {
    if (identical(
      r,
      _rows.lastWhere((x) => !x.ownRegistration, orElse: () => r),
    )) {
      _addRow();
    }
  }

  /// 이 수양회의 어린이 참가비 구간 (073).
  ChildFeePolicy get _policy => ChildFeePolicy.of(widget.program);

  /// 보호자가 고른 등급의 값. 아직 안 골랐으면 null 이다.
  double? get _tierFee {
    final tier = ref.read(registrationFormProvider(widget.programId)).feeTier;
    final v = switch (tier) {
      'basic' => Money.parse(widget.program['fee_basic']),
      'premium' => Money.parse(widget.program['fee_premium']),
      _ => null,
    };
    return v?.toDouble();
  }

  /// 참가비 칸에 적을 말. 나이를 적은 그 자리에서 보여야 한다(073) —
  /// 나중에 합계에서 처음 보면 무엇 때문에 늘었는지 되물을 자리가 없다.
  String _feeText(AppLocalizations l10n, _Row r) {
    final age = r.ageValue;
    if (age == null) return l10n.companionFeeNeedAge;
    final share = _policy.shareForCompanion(r.resolved());
    if (share <= 0) return l10n.companionFeeFree;
    final fee = _tierFee;
    // 등급을 아직 안 골랐으면 몫만 말한다. 0 이라고 적으면 공짜로 읽힌다.
    if (fee == null || fee <= 0) return '${(share * 100).round()}%';
    return widget.currency.format((fee * share * 100).round() / 100);
  }

  /// 함께 오는 사람까지 합친 금액 (077).
  ///
  /// 등급마다(기본·프리미엄, 숙박 수준마다) 합계를 보여 준다. 같은 방이든
  /// 다른 방이든 금액은 같다 — 숙박 단가가 한 사람 한 밤 값이다.
  Widget _familyCard(AppLocalizations l10n) {
    final form = ref.watch(registrationFormProvider(widget.programId));
    final nights = chargeableHotelNights(
      before: form.hotelNightsBefore,
      after: form.hotelNightsAfter,
      beforeSelf: form.hotelBeforeSelf,
      afterSelf: form.hotelAfterSelf,
    );
    final fam = FamilyCost.of(
      program: widget.program,
      companions: _companions,
      nights: nights,
    );
    // 이 등록에 붙는 동반자가 없으면 합칠 것이 없다 — 따로 등록하는 분만
    // 있으면 그 사실만 말한다.
    final cur = widget.currency;
    final lang = Localizations.localeOf(context).languageCode;
    final now = RegistrationCost.of(
      program: widget.program,
      companions: _companions,
      feeTier: form.feeTier,
      selectedOptionIds: form.selectedOptions,
      hotelOptionKey: form.hotelOptionKey,
      hotelNightsBefore: form.hotelNightsBefore,
      hotelNightsAfter: form.hotelNightsAfter,
      hotelBeforeSelf: form.hotelBeforeSelf,
      hotelAfterSelf: form.hotelAfterSelf,
    );
    final small = TextStyle(fontSize: 12, color: Colors.grey[700]);
    const accent = Color(0xFF7A6BB5);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fam.people > 1) ...[
              Text(
                l10n.familyCostTitle(fam.people),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final f in fam.fees)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.tier == 'premium'
                                  ? l10n.feeTierPremium
                                  : l10n.feeTierBasic,
                            ),
                            Text(
                              l10n.familyFeeRow(
                                cur.format(f.self),
                                cur.format(f.others),
                              ),
                              style: small,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        cur.format(f.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              if (fam.hotels.isNotEmpty) ...[
                const Divider(height: 18),
                Text(
                  l10n.familyHotelTitle(fam.heads),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                for (final h in fam.hotels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(optionLabelFor(h.option, lang)),
                              Text(
                                l10n.familyHotelPerNight(
                                  cur.format(h.perNight),
                                  h.heads,
                                  cur.format(h.perNightAll),
                                ),
                                style: small,
                              ),
                            ],
                          ),
                        ),
                        if (h.total != null)
                          Text(
                            l10n.familyHotelNights(
                              h.nights,
                              cur.format(h.total!),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (nights == 0) Text(l10n.familyHotelNoNights, style: small),
              ],
              // 지금 고른 등급·투어·숙박으로 실제로 낼 돈. 비용 막대와 같은
              // 셈(RegistrationCost)이다.
              if (form.feeTier != null) ...[
                const Divider(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.familyNow,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      cur.format(now.due),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (fam.separateCount > 0) ...[
              if (fam.people > 1) const SizedBox(height: 8),
              Text(l10n.familySeparateNote(fam.separateCount), style: small),
            ],
          ],
        ),
      ),
    );
  }

  // ── 표 ──────────────────────────────────────────────────────

  Widget _cell(Widget child, {double? width, bool head = false}) => SizedBox(
    height: head ? _headH : _rowH,
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Align(alignment: Alignment.centerLeft, child: child),
    ),
  );

  Widget _head(String text, {double? width}) => _cell(
    Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4A4560),
      ),
      softWrap: false,
    ),
    width: width,
    head: true,
  );

  Widget _muted(String text) => Text(
    text,
    style: const TextStyle(fontSize: 13, color: Color(0xFF5F5A73)),
    softWrap: false,
  );

  Widget _seg<T>(
    List<(T, String)> options,
    T selected,
    ValueChanged<T> onChanged,
  ) => _Seg<T>(options: options, selected: selected, onChanged: onChanged);

  TableRow _line(List<Widget> cells, {Color? color}) => TableRow(
    decoration: BoxDecoration(
      color: color,
      border: const Border(top: BorderSide(color: Color(0xFFECEAF3))),
    ),
    children: cells,
  );

  /// 왼쪽에 붙어 있는 칸 — 번호와 이름. 휴대폰에서 표를 옆으로 밀어도
  /// 누구의 줄인지 보여야 한다.
  Widget _fixedTable(AppLocalizations l10n, double nameWidth) {
    final rows = <TableRow>[
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFFEFEDF7)),
        children: [_head('#', width: 34), _head(l10n.companionColName)],
      ),
      // 기준이 되는 대표자. 아래 칸의 "같은" 이 누구와 같다는 뜻인지 보인다.
      _line([
        _cell(_muted('—'), width: 34),
        _cell(
          Text(
            l10n.companionSelfRow,
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ], color: const Color(0xFFFAF9FD)),
    ];
    var n = 0;
    for (final r in _rows) {
      n++;
      rows.add(
        _line([
          _cell(_muted('$n'), width: 34),
          _cell(
            r.ownRegistration
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name.text,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      _muted(l10n.companionOwnRegistration),
                    ],
                  )
                : TextField(
                    controller: r.name,
                    focusNode: r.focus,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _changed(),
                    onSubmitted: (_) => _submitted(r),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.companionColName,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                  ),
          ),
        ]),
      );
    }
    return SizedBox(
      width: 34 + nameWidth,
      child: Table(
        columnWidths: {
          0: const FixedColumnWidth(34),
          1: FixedColumnWidth(nameWidth),
        },
        children: rows,
      ),
    );
  }

  /// 옆으로 미는 칸들. 칸 너비는 내용에 맞춘다(IntrinsicColumnWidth) —
  /// 언어마다 낱말 길이가 달라 고정 너비로는 어디선가 잘린다.
  Widget _scrollTable(AppLocalizations l10n) {
    final anyOtherFlight = _rows.any(
      (r) => !r.ownRegistration && r.data['sameFlightAsPrimary'] == false,
    );
    final selfFee = _tierFee;
    final rows = <TableRow>[
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFFEFEDF7)),
        children: [
          _head(l10n.companionColAge),
          _head(l10n.regGender),
          _head(l10n.companionColRoom),
          _head(l10n.companionColBed),
          _head(l10n.companionColStudy),
          _head(l10n.companionColTour),
          _head(l10n.companionColFlight),
          if (anyOtherFlight) _head(l10n.companionColFlightNo),
          _head(l10n.companionColFee),
          _head(''),
        ],
      ),
      _line([
        _cell(_muted('—')),
        _cell(_muted('—')),
        _cell(_muted('—')),
        _cell(_muted('—')),
        _cell(_muted('—')),
        _cell(_muted('—')),
        _cell(_muted('—')),
        if (anyOtherFlight) _cell(_muted('—')),
        _cell(_muted(selfFee == null ? '—' : widget.currency.format(selfFee))),
        _cell(const SizedBox(width: 40)),
      ], color: const Color(0xFFFAF9FD)),
    ];

    for (final r in _rows) {
      final del = _cell(
        IconButton(
          tooltip: l10n.companionRemoveRow,
          icon: const Icon(
            Icons.delete_outline,
            size: 20,
            color: Color(0xFF8A3B3B),
          ),
          onPressed: () => _removeRow(r),
        ),
      );
      if (r.ownRegistration) {
        rows.add(
          _line([
            _cell(_muted(r.age.text.isEmpty ? '—' : r.age.text)),
            _cell(_muted('—')),
            _cell(_muted('—')),
            _cell(_muted('—')),
            _cell(_muted('—')),
            _cell(_muted('—')),
            _cell(_muted('—')),
            if (anyOtherFlight) _cell(_muted('—')),
            _cell(_muted('—')),
            del,
          ]),
        );
        continue;
      }
      void set(String key, Object? value) {
        r.data[key] = value;
        _changed();
      }

      final otherFlight = r.data['sameFlightAsPrimary'] == false;
      rows.add(
        _line([
          _cell(
            SizedBox(
              width: 58,
              child: TextField(
                controller: r.age,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                // 참가비·침대·분반 기본값이 나이로 갈린다.
                onChanged: (_) => _changed(),
                onSubmitted: (_) => _submitted(r),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          _cell(
            _seg<String?>(
              [
                ('M', l10n.companionMaleShort),
                ('F', l10n.companionFemaleShort),
              ],
              r.data['gender'] as String?,
              (v) => set('gender', v),
            ),
          ),
          _cell(
            _seg<bool>(
              [
                (true, l10n.companionRoomSameShort),
                (false, l10n.companionRoomOtherShort),
              ],
              r.data['sharesRoom'] != false,
              (v) => set('sharesRoom', v),
            ),
          ),
          // 다른 방이면 침대는 늘 쓴다(077) — 묻지 않는다.
          _cell(
            r.data['sharesRoom'] == false
                ? _muted(l10n.companionBedOwnRoom)
                : _seg<bool>(
                    [
                      (true, l10n.companionBedUses),
                      (false, l10n.companionBedShares),
                    ],
                    r.bed,
                    (v) => set('occupiesBed', v),
                  ),
          ),
          _cell(
            _seg<String>(
              [
                ('same', l10n.companionStudySame),
                ('other', l10n.companionStudyOther),
                ('none', l10n.companionStudyNone),
              ],
              r.study,
              (v) => set('studyGroup', v),
            ),
          ),
          _cell(
            _seg<bool>(
              [(true, l10n.companionTourYes), (false, l10n.companionTourNo)],
              r.data['joinsTours'] == true,
              (v) => set('joinsTours', v),
            ),
          ),
          _cell(
            _seg<bool>(
              [
                (true, l10n.companionFlightSame),
                (false, l10n.companionFlightOther),
              ],
              !otherFlight,
              (v) => set('sameFlightAsPrimary', v),
            ),
          ),
          if (anyOtherFlight)
            _cell(
              otherFlight
                  ? SizedBox(
                      width: 130,
                      child: TextField(
                        controller: r.flight,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => _changed(),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'KE123',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          _cell(
            Text(
              _feeText(l10n, r),
              softWrap: false,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
          del,
        ]),
      );
    }
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final companions = _companions;
    final tourPeople = tourHeads(companions);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          l10n.companionTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.companionMustRegister,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2DFEE)),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, box) {
                  final nameWidth = box.maxWidth >= 700 ? 200.0 : 130.0;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fixedTable(l10n, nameWidth),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _scrollTable(l10n),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFECEAF3)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.companionAddRow),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                    Text(
                      l10n.companionTableHint,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (companions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _familyCard(l10n),
          if (tourPeople > 1) ...[
            const SizedBox(height: 8),
            Text(
              l10n.familyTourNote(tourPeople),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ],
      ],
    );
  }
}

/// 칸 안의 작은 고르기 단추. SegmentedButton 은 표 한 칸에 넣기에 크고,
/// 체크 표시가 붙어 너비가 흔들린다.
class _Seg<T> extends StatelessWidget {
  const _Seg({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D5E8)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in options)
            Material(
              color: value == selected ? _accent : Colors.white,
              child: InkWell(
                onTap: () => onChanged(value),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: value == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: value == selected
                          ? Colors.white
                          : const Color(0xFF4A4560),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
