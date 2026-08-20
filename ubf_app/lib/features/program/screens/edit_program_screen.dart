import 'package:flutter/material.dart';
import '../../../core/utils/file_pick.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/media_url.dart';
import '../providers/program_provider.dart';
import '../widgets/fee_section.dart';
import '../widgets/cohort_policy_section.dart';
import '../widgets/hotel_section.dart';
import '../widgets/telegram_section.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';

class EditProgramScreen extends ConsumerStatefulWidget {
  final String programId;

  const EditProgramScreen({super.key, required this.programId});

  @override
  ConsumerState<EditProgramScreen> createState() => _EditProgramScreenState();
}

class _EditProgramScreenState extends ConsumerState<EditProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _airportController = TextEditingController();

  /// 현장 대표 연락처(040). 두 명 고정이었는데, 공항·숙소·차량을 나눠 맡는
  /// 사람이 그보다 많고 참가자가 급할 때 닿아야 할 번호가 둘로 끝나지 않는다.
  final List<({TextEditingController name, TextEditingController phone})>
  _contacts = [];

  /// 가까운 공항 말고 올 수 있는 다른 길(048). 한 줄이 공항 + 설명이다.
  final List<({TextEditingController airport, TextEditingController note})>
  _routes = [];
  static const _maxContacts = 10;
  // 서버의 MAX_ROUTES 와 같아야 한다(arrival_routes.js).
  static const _maxRoutes = 8;

  /// 입금 시점(041). 둘 다 현장이면 대시보드에서 입금 카드를 감춘다.
  String _feePayment = 'prepaid';
  String _tourPayment = 'prepaid';
  final _hostCountryController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _hostCountry;
  String _programType = 'international';
  bool _isLoading = false;
  bool _initialized = false;

  final Map<String, bool> _enabledSections = {
    'personal_info': true,
    'arrival_flight': true,
    'departure_flight': true,
    'food_requirements': true,
    'special_programs': true,
    'roommate': true,
    'volunteer_resources': true,
  };

  Map<String, String> _sectionLabels(AppLocalizations l10n) => {
    'personal_info': l10n.regStepPersonal,
    'arrival_flight': l10n.flightInfoTitle(l10n.flightArrival),
    'departure_flight': l10n.flightInfoTitle(l10n.flightDeparture),
    'food_requirements': l10n.summarySectionFood,
    'special_programs': l10n.cpSpecialOptions,
    'roommate': l10n.summarySectionRoommate,
    'volunteer_resources': l10n.cpSecVolunteer,
  };

  List<Map<String, dynamic>> _options = [];

  // 참가비 등급 + 할인 항목
  final _feeBasicController = TextEditingController();
  final _feePremiumController = TextEditingController();
  final _feeBasicDescController = TextEditingController();
  final _feePremiumDescController = TextEditingController();
  List<Map<String, dynamic>> _discountOptions = [];
  List<Map<String, dynamic>> _hotelOptions = [];
  final _tgTokenController = TextEditingController();
  final _tgChatIdController = TextEditingController();
  bool _tgConfigured = false;
  // 해제를 누르면 빈 문자열을 보내 서버가 지우게 한다. null 은 "안 보냄"이라
  // 기존 값이 그대로 남는다 — 그 둘을 구분해야 한다.
  bool _tgClearRequested = false;

  // 이 수양회의 통화. 등록자 전원이 이 단위로 본다.
  Currency _currency = Currency.usd;

  // 소수 인원 칸 처리 방침(025). 기본은 keep — 조용히 옮기는 것보다
  // "3명이 남았습니다"를 보여 주는 편이 낫다.
  String _cohortPolicy = 'keep';
  int _minTeamSize = 5;

  // 빈 칸은 0 이 아니라 "그 등급 없음"이다.
  num? _fee(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    final n = num.tryParse(t);
    return (n != null && n >= 0) ? n : null;
  }

  String? _text(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  @override
  void dispose() {
    _feeBasicController.dispose();
    _feePremiumController.dispose();
    _feeBasicDescController.dispose();
    _feePremiumDescController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _airportController.dispose();
    for (final c in _contacts) {
      c.name.dispose();
      c.phone.dispose();
    }
    _hostCountryController.dispose();
    super.dispose();
  }

  // 기존 프로그램 데이터로 필드 초기화
  void _initFromProgram(Map<String, dynamic> program) {
    if (_initialized) return;
    _initialized = true;

    _nameController.text = program['name'] ?? '';
    _locationController.text = program['location'] ?? '';
    _airportController.text = program['nearest_airport'] ?? '';
    // 서버는 늘 목록으로 준다 — 040 이전 수양회는 옛 두 칸에서 만들어 준다.
    for (final c in _contacts) {
      c.name.dispose();
      c.phone.dispose();
    }
    _contacts.clear();
    for (final c in (program['contacts'] as List? ?? const [])) {
      if (c is! Map) continue;
      _contacts.add((
        name: TextEditingController(text: '${c['name'] ?? ''}'),
        phone: TextEditingController(text: '${c['phone'] ?? ''}'),
      ));
    }
    if (_contacts.isEmpty) _addContactRow();

    for (final r in _routes) {
      r.airport.dispose();
      r.note.dispose();
    }
    _routes.clear();
    for (final r in (program['arrival_routes'] as List? ?? const [])) {
      if (r is! Map) continue;
      _routes.add((
        airport: TextEditingController(text: '${r['airport'] ?? ''}'),
        note: TextEditingController(text: '${r['note'] ?? ''}'),
      ));
    }
    // 빈 줄 하나는 늘 둔다 — 비어 있으면 적을 자리가 있다는 것을 모른다.
    if (_routes.isEmpty) _addRouteRow();

    _feePayment = program['fee_payment'] as String? ?? 'prepaid';
    _tourPayment = program['tour_payment'] as String? ?? 'prepaid';

    if (program['start_date'] != null) {
      _startDate = DateTime.tryParse(program['start_date'] as String);
    }
    if (program['end_date'] != null) {
      _endDate = DateTime.tryParse(program['end_date'] as String);
    }

    _programType = program['program_type'] ?? 'international';

    // 019 이전에 저장된 표시명이 남아 있을 수 있다. ISO 로 되돌린 뒤 영문명을
    // 보여준다. 코드를 그대로 칸에 넣으면 관리자에게 'AR' 만 보인다.
    _hostCountry = WorldCountries.isoForLegacy(
      program['host_country'] as String?,
    );
    _hostCountryController.text = WorldCountries.nameOf(_hostCountry) ?? '';

    final sections = Map<String, dynamic>.from(
      program['enabled_sections'] ?? {},
    );
    for (final key in _enabledSections.keys) {
      _enabledSections[key] = sections[key] as bool? ?? true;
    }

    final rawOptions = program['program_options'];
    if (rawOptions is List) {
      _options = rawOptions
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();
    }

    // NUMERIC 은 드라이버에 따라 문자열로 올 수 있다. toString 으로 통일한다.
    _feeBasicController.text = program['fee_basic']?.toString() ?? '';
    _feePremiumController.text = program['fee_premium']?.toString() ?? '';
    _feeBasicDescController.text = program['fee_basic_desc'] ?? '';
    _feePremiumDescController.text = program['fee_premium_desc'] ?? '';

    // 국제 수양회는 저장된 값이 무엇이든 USD 다. 규칙이 생기기 전에 만들어진
    // 수양회에는 다른 통화가 남아 있는데, 그 값을 그대로 보여주면 잠금 안내가
    // "국제 수양회의 금액은 ARS 로 적습니다" 처럼 스스로를 반박한다.
    // 저장하면 서버가 USD 로 돌리므로, 화면도 저장될 값을 보여준다.
    _currency = _programType == 'international'
        ? Currency.usd
        : Currency.of(program['currency'] as String?);

    _cohortPolicy = program['small_cohort_policy'] as String? ?? 'keep';
    _minTeamSize = (program['min_team_size'] as num?)?.toInt() ?? 5;

    final rawDiscounts = program['discount_options'];
    if (rawDiscounts is List) {
      _discountOptions = rawDiscounts
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();
    }

    _tgConfigured = program['telegram_bot_configured'] as bool? ?? false;
    _tgChatIdController.text = program['telegram_chat_id'] as String? ?? '';

    final rawHotels = program['hotel_options'];
    if (rawHotels is List) {
      _hotelOptions = rawHotels
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();
    }
  }

  void _onProgramTypeChanged(String type) {
    final isInternational = type == 'international';
    setState(() {
      _programType = type;
      _enabledSections['arrival_flight'] = isInternational;
      _enabledSections['departure_flight'] = isInternational;
      _enabledSections['special_programs'] = isInternational;
      // 국제로 바꾸면 통화도 USD 로 되돌린다. 서버가 어차피 USD 로 강제하므로,
      // 여기서 안 되돌리면 금액 칸 접두사만 예전 통화로 남아 거짓말을 한다.
      if (isInternational) _currency = Currency.usd;
    });
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  // 기간(시작~종료)을 달력 1개로 선택
  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: AppLocalizations.of(context)!.cpPeriod,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _showOptionDialog({
    Map<String, dynamic>? existing,
    int? index,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _OptionDetailDialog(existing: existing),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _options[index] = result;
      } else {
        _options.add(result);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      await ApiClient.updateProgram(widget.programId, {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'programType': _programType,
        'startDate': _startDate?.toIso8601String().split('T').first,
        'endDate': _endDate?.toIso8601String().split('T').first,
        'hostCountry': _programType == 'international' ? _hostCountry : null,
        'enabledSections': Map<String, bool>.from(_enabledSections),
        'options': _options,
        'nearestAirport': _airportController.text.trim(),
        // 다른 도착 경로(048). 비어 있는 줄은 서버가 버린다.
        'arrivalRoutes': [
          for (final r in _routes)
            {'airport': r.airport.text.trim(), 'note': r.note.text.trim()},
        ],
        // 빈 줄은 서버가 버린다. 여기서도 보내지 않는다.
        'contacts': [
          for (final c in _contacts)
            if (c.name.text.trim().isNotEmpty || c.phone.text.trim().isNotEmpty)
              {'name': c.name.text.trim(), 'phone': c.phone.text.trim()},
        ],
        'feePayment': _feePayment,
        'tourPayment': _tourPayment,
        'feeBasic': _fee(_feeBasicController),
        'feePremium': _fee(_feePremiumController),
        'feeBasicDesc': _text(_feeBasicDescController),
        'feePremiumDesc': _text(_feePremiumDescController),
        'discountOptions': _discountOptions,
        'currency': _currency.code,
        'smallCohortPolicy': _cohortPolicy,
        'minTeamSize': _minTeamSize,
        'hotelOptions': _hotelOptions,
        // 토큰은 화면으로 돌아오지 않으므로(서버가 안 실어 준다) 비어 있으면
        // "안 바꿈"이다. 매번 다시 적으라고 하면 참가비만 고칠 때마다 잃는다.
        if (_tgClearRequested)
          'telegramBotToken': ''
        else if (_tgTokenController.text.trim().isNotEmpty)
          'telegramBotToken': _tgTokenController.text.trim(),
        'telegramChatId': _tgChatIdController.text.trim(),
      });

      if (!mounted) return;
      // 캐시 무효화 후 대시보드로 복귀
      ref.invalidate(programByIdProvider(widget.programId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.epSaved)));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileSaveFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addRouteRow() {
    _routes.add((
      airport: TextEditingController(),
      note: TextEditingController(),
    ));
  }

  void _addContactRow() {
    _contacts.add((
      name: TextEditingController(),
      phone: TextEditingController(),
    ));
  }

  Widget _paymentRow(
    String label,
    String value,
    void Function(String) onChanged,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'prepaid', label: Text(l10n.epPrepaid)),
            ButtonSegment(value: 'onsite', label: Text(l10n.epOnsite)),
          ],
          selected: {value},
          // 체크 표시를 빼면 글자가 접히지 않는다 — "선불" 이 두 줄이 됐다.
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(programByIdProvider(widget.programId));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return programAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(l10n.commonErrorDetail('$e')))),
      data: (program) {
        if (program == null) {
          return Scaffold(body: Center(child: Text(l10n.epNotFound)));
        }

        // 한 번만 초기화 (setState 없이)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_initialized) setState(() => _initFromProgram(program));
        });
        if (!_initialized) _initFromProgram(program);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.dashEditSettings),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.actionSave,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 프로그램 유형
                Text(l10n.cpProgramType, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'local',
                      label: Text(l10n.cpTypeLocal),
                      icon: const Icon(Icons.location_city),
                    ),
                    ButtonSegment(
                      value: 'international',
                      label: Text(l10n.cpTypeInternational),
                      icon: const Icon(Icons.flight),
                    ),
                  ],
                  selected: {_programType},
                  onSelectionChanged: (s) => _onProgramTypeChanged(s.first),
                ),
                const SizedBox(height: 28),

                // 기본 정보
                Text(l10n.cpBasicInfo, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.cpNameLabel),
                  validator: (v) =>
                      v?.isEmpty == true ? l10n.cpNameRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: l10n.cpLocationLabel),
                  validator: (v) =>
                      v?.isEmpty == true ? l10n.cpLocationRequired : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    (_startDate == null || _endDate == null)
                        ? l10n.cpPeriod
                        : '${_fmtDate(_startDate!)}  ~  ${_fmtDate(_endDate!)}',
                  ),
                  onPressed: _selectDateRange,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                // 개최 국가 (국제 수양회만)
                if (_programType == 'international') ...[
                  const SizedBox(height: 12),
                  DropdownMenu<String>(
                    controller: _hostCountryController,
                    enableFilter: true,
                    requestFocusOnTap: true,
                    menuHeight: 320,
                    expandedInsets: EdgeInsets.zero,
                    label: Text(l10n.cpHostCountry),
                    hintText: l10n.cpHostCountryHint,
                    leadingIcon: const Icon(Icons.flag_outlined),
                    helperText: l10n.cpHostCountryHelp,
                    inputDecorationTheme: const InputDecorationTheme(
                      border: OutlineInputBorder(),
                    ),
                    dropdownMenuEntries: [
                      // 값은 ISO 코드, 표시는 영문명. 표시명을 저장하면 참가자의
                      // 거주 국가와 문자열 비교가 성립하지 않는다.
                      for (final c in WorldCountries.all)
                        DropdownMenuEntry<String>(value: c.iso, label: c.name),
                    ],
                    onSelected: (v) => setState(() => _hostCountry = v),
                  ),
                ],
                const SizedBox(height: 28),

                // 입국 안내 (국제만)
                if (_programType == 'international') ...[
                  Text(
                    l10n.cpImmigrationInfo,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.cpImmigrationDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _airportController,
                    decoration: InputDecoration(
                      labelText: l10n.cpNearestAirport,
                      hintText: l10n.cpAirportHint,
                      prefixIcon: const Icon(Icons.flight_land),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 오는 길이 하나가 아니다 — 큰 공항으로 들어와 버스로
                  // 갈아타거나, 육로로 국경을 넘는 사람이 있다. 표를 끊기
                  // 전에 알아야 하는 정보다.
                  Text(
                    l10n.epRoutes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.epRoutesDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _routes.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _routes[i].airport,
                              decoration: InputDecoration(
                                labelText: l10n.epRouteAirport,
                                hintText: l10n.cpAirportHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _routes[i].note,
                              decoration: InputDecoration(
                                labelText: l10n.epRouteNote,
                                hintText: l10n.epRouteNoteHint,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: l10n.epRemoveRoute,
                            onPressed: () => setState(() {
                              _routes[i].airport.dispose();
                              _routes[i].note.dispose();
                              _routes.removeAt(i);
                              if (_routes.isEmpty) _addRouteRow();
                            }),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _routes.length >= _maxRoutes
                          ? null
                          : () => setState(_addRouteRow),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(l10n.epAddRoute),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.epContacts(_contacts.length),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _contacts.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _contacts[i].name,
                              decoration: InputDecoration(
                                labelText: l10n.epContactName,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _contacts[i].phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: l10n.epContactPhone,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: l10n.epRemoveContact,
                            onPressed: () => setState(() {
                              _contacts[i].name.dispose();
                              _contacts[i].phone.dispose();
                              _contacts.removeAt(i);
                              if (_contacts.isEmpty) _addContactRow();
                            }),
                          ),
                        ],
                      ),
                    ),
                  // (+) 는 마지막 줄 아래에 둔다 — 적다가 하나 더 필요할 때
                  // 손이 가 있는 자리다.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _contacts.length >= _maxContacts
                          ? null
                          : () => setState(_addContactRow),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.epAddContact),
                    ),
                  ),
                  if (_contacts.length >= _maxContacts)
                    Text(
                      l10n.epContactsFull(_maxContacts),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),

                  const SizedBox(height: 20),
                  // 입금 시점(041)
                  Text(
                    l10n.epPaymentWhen,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _paymentRow(
                    l10n.epFeeWhen,
                    _feePayment,
                    (v) => setState(() => _feePayment = v),
                    l10n,
                  ),
                  const SizedBox(height: 8),
                  _paymentRow(
                    l10n.epTourWhen,
                    _tourPayment,
                    (v) => setState(() => _tourPayment = v),
                    l10n,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.epPaymentNote,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 28),
                ],

                // 섹션 활성화
                Text(l10n.cpSectionsTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.cpSectionsDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: _sectionLabels(l10n).entries.map((entry) {
                      return SwitchListTile(
                        title: Text(entry.value),
                        value: _enabledSections[entry.key] ?? true,
                        onChanged: entry.key == 'personal_info'
                            ? null
                            : (val) => setState(
                                () => _enabledSections[entry.key] = val,
                              ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                // 참가비 등급 + 할인 항목
                FeeSection(
                  basicController: _feeBasicController,
                  premiumController: _feePremiumController,
                  basicDescController: _feeBasicDescController,
                  premiumDescController: _feePremiumDescController,
                  discountOptions: _discountOptions,
                  onDiscountsChanged: () => setState(() {}),
                  currency: _currency,
                  onCurrencyChanged: (c) => setState(() => _currency = c),
                  canChooseCurrency: _programType == 'local',
                ),
                const SizedBox(height: 28),
                // 수양회 전후 숙박 수준(028). 외국에서 오는 참가자만 고른다.
                HotelSection(
                  hotelOptions: _hotelOptions,
                  onChanged: () => setState(() {}),
                  currency: _currency,
                ),
                const SizedBox(height: 28),
                TelegramSection(
                  tokenController: _tgTokenController,
                  chatIdController: _tgChatIdController,
                  configured: _tgConfigured && !_tgClearRequested,
                  onClear: () => setState(() {
                    _tgClearRequested = true;
                    _tgTokenController.clear();
                  }),
                ),
                const SizedBox(height: 28),
                CohortPolicySection(
                  policy: _cohortPolicy,
                  onPolicyChanged: (v) => setState(() => _cohortPolicy = v),
                  minTeamSize: _minTeamSize,
                  onMinTeamSizeChanged: (v) => setState(() => _minTeamSize = v),
                ),
                const SizedBox(height: 28),

                // 투어 옵션 (국제만)
                if (_programType == 'international') ...[
                  Row(
                    children: [
                      Text(
                        l10n.cpSpecialOptions,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (_startDate != null &&
                          !_startDate!.isAfter(DateTime.now())) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 시작일이 지났으면 잠금 안내
                  if (_startDate != null &&
                      !_startDate!.isAfter(DateTime.now()))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.epTourLocked,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      l10n.cpOptionsDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 8),
                  ..._options.asMap().entries.map((entry) {
                    final i = entry.key;
                    final option = entry.value;
                    final locked =
                        _startDate != null &&
                        !_startDate!.isAfter(DateTime.now());
                    final dates = [
                      if (option['startDate'] != null) option['startDate'],
                      if (option['endDate'] != null) option['endDate'],
                    ].join(' ~ ');
                    return Card(
                      child: ListTile(
                        title: Text(option['name'] as String? ?? ''),
                        subtitle: Text(
                          [
                            l10n.cpOptionCost(
                              // 이 수양회의 통화로. 투어 옵션은 지금 국제
                              // 전용이라 늘 USD 지만, 기본값에 기대면
                              // 나중에 조용히 틀린다.
                              _currency.format(Money.parse(option['cost'])),
                            ),
                            if (dates.isNotEmpty) dates,
                            if ((option['contactName'] as String?)
                                    ?.isNotEmpty ==
                                true)
                              l10n.epOptionContact('${option['contactName']}'),
                          ].join('  |  '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _showOptionDialog(existing: option, index: i),
                            ),
                            if (!locked)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    setState(() => _options.removeAt(i)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  if (_startDate == null || _startDate!.isAfter(DateTime.now()))
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.epAddOption),
                      onPressed: () => _showOptionDialog(),
                    ),
                  const SizedBox(height: 32),
                ],

                // 저장 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.epSaveChanges),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── 투어/특별프로그램 옵션 상세 입력 다이얼로그 ────────────────
class _OptionDetailDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _OptionDetailDialog({this.existing});

  @override
  State<_OptionDetailDialog> createState() => _OptionDetailDialogState();
}

class _OptionDetailDialogState extends State<_OptionDetailDialog> {
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  /// 이 투어 값에 무엇이 들어 있는가 (060 숙박 · 061 식사·항공권).
  ///
  /// 화면에는 **"미포함" 으로 뒤집어** 보인다 — 담당자가 손대는 것은 대개
  /// 빠진 쪽이고, 빠진 것에만 금액을 적기 때문이다. 저장은 포함 여부로
  /// 한 곳에서 한다.
  bool _includesLodging = true;
  bool _includesMeals = true;
  bool _includesAirfare = true;

  /// 안 들어 있을 때 얼마쯤 더 드는가. 비워 두면 "아직 모른다" 이고 0 과
  /// 다르다 — 0 으로 두면 더 들 것이 없다는 뜻이 되어, 참가자가 돈을 안
  /// 챙겨 온다.
  final _estMealsCtrl = TextEditingController();
  final _estLodgingCtrl = TextEditingController();
  final _estAirfareCtrl = TextEditingController();
  final _brochureCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _deadline;
  final List<String> _photoUrls = [];
  bool _photoBusy = false;
  // 계획서 PDF 여러 장. [{url, name, bytes}] — 037 의 plan_docs 와 같은 모양.
  final List<Map<String, dynamic>> _planDocs = [];
  bool _planBusy = false;

  static const _maxPlanDocs = 10;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['name'] as String? ?? '';
      _costCtrl.text = '${e['cost'] ?? ''}';
      _contactCtrl.text = e['contactName'] as String? ?? '';
      _descCtrl.text = e['description'] as String? ?? '';
      if (e['capacity'] != null) _capacityCtrl.text = '${e['capacity']}';
      _includesLodging = e['includesLodging'] != false;
      _includesMeals = e['includesMeals'] != false;
      _includesAirfare = e['includesAirfare'] != false;
      _estMealsCtrl.text = _money(e['estMealsCost']);
      _estLodgingCtrl.text = _money(e['estLodgingCost']);
      _estAirfareCtrl.text = _money(e['estAirfareCost']);
      _brochureCtrl.text = e['brochureUrl'] as String? ?? '';
      _videoCtrl.text = e['videoUrl'] as String? ?? '';
      if (e['startDate'] != null) {
        _startDate = DateTime.tryParse(e['startDate'] as String);
      }
      if (e['endDate'] != null) {
        _endDate = DateTime.tryParse(e['endDate'] as String);
      }
      if (e['signupDeadline'] != null) {
        _deadline = DateTime.tryParse(e['signupDeadline'] as String);
      }
      if (e['photoUrls'] is List) {
        _photoUrls.addAll((e['photoUrls'] as List).cast<String>());
      }
      if (e['planDocs'] is List) {
        for (final d in e['planDocs'] as List) {
          if (d is Map) _planDocs.add(Map<String, dynamic>.from(d));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    _capacityCtrl.dispose();
    _brochureCtrl.dispose();
    _videoCtrl.dispose();
    _estMealsCtrl.dispose();
    _estLodgingCtrl.dispose();
    _estAirfareCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: AppLocalizations.of(context)!.cpPeriod,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // 기기에서 사진을 골라 올린다.
  //
  // 예전에는 주소를 손으로 붙여넣게 했다(스토리지가 없었다). 이제 서버가
  // 파일을 받으므로 고르기만 하면 된다. 주소 붙여넣기도 남겨 둔다 —
  // 이미 어딘가에 올려 둔 사진을 쓰는 담당자가 있다.
  Future<void> _addPhotoFromDevice() async {
    if (_photoUrls.length >= 6) return;
    final l10n = AppLocalizations.of(context)!;
    final picked = await pickImage();
    if (picked == null || !mounted) return;
    setState(() => _photoBusy = true);
    try {
      final up = await ApiClient.uploadFile(picked.bytes, 'program');
      if (!mounted) return;
      setState(() => _photoUrls.add(up['url'] as String));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoUploadFailed('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  // 계획서 PDF 올리기.
  //
  // 한 번에 한 장씩 고른다. 여러 장을 한꺼번에 고르게 하려면 <input multiple>
  // 을 다루는 길이 플랫폼마다 갈리는데, 자료마다 이름을 따로 물어야 하므로
  // 어차피 한 장씩 지나가게 된다.
  Future<void> _addPlanDoc() async {
    final l10n = AppLocalizations.of(context)!;
    if (_planDocs.length >= _maxPlanDocs) {
      _planSnack(l10n.epPlanFull(_maxPlanDocs));
      return;
    }
    // PDF 고르기는 웹에서만 된다(file_pick.dart). 버튼을 눌러도 아무 일이
    // 없으면 고장으로 읽히므로, 왜 안 되는지 말해 준다.
    if (!canPickPdf) {
      _planSnack(l10n.libPickOnWeb);
      return;
    }

    final picked = await pickPdf();
    if (picked == null || !mounted) return;

    // 이름을 **먼저** 묻는다. 올린 뒤에 물으면, 이름을 안 적고 닫았을 때
    // 아무 데도 안 붙은 파일이 서버에 남는다 (자료실도 같은 순서다).
    final name = await _askPlanName(picked.name);
    if (name == null || !mounted) return;

    setState(() => _planBusy = true);
    try {
      final up = await ApiClient.uploadFile(picked.bytes, 'program');
      if (!mounted) return;
      setState(() {
        _planDocs.add({'url': up['url'], 'name': name, 'bytes': up['bytes']});
      });
    } catch (e) {
      if (mounted) _planSnack(l10n.libUploadFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _planBusy = false);
    }
  }

  /// 파일 크기를 사람이 읽는 단위로. 정확한 단위보다 "큰가 작은가" 가 중요하다.
  static String _fileSize(Object? bytes) {
    final n = bytes is num ? bytes.toInt() : int.tryParse('$bytes') ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} MB';
    if (n >= 1000) return '${(n / 1000).round()} KB';
    return '$n B';
  }

  void _planSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  /// 자료 이름. 파일명을 기본값으로 준다 — 대개 그대로 쓸 만하다.
  Future<String?> _askPlanName(String fileName) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(
      text: fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
    );
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.epPlanName),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.epPlanNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(ctx, t);
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }

  // 사진 주소 붙여넣기 (이미 어딘가에 올려 둔 사진을 쓸 때)
  Future<void> _addPhotoUrl() async {
    if (_photoUrls.length >= 6) return;
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.epPhotoUrlTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.epPhotoUrlLabel,
            hintText: 'https://...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text(l10n.actionAdd),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (url != null && url.isNotEmpty) {
      setState(() => _photoUrls.add(url));
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: AppLocalizations.of(context)!.epSignupDeadline,
    );
    if (picked != null) {
      // 마감일은 그날 23:59까지로 설정
      setState(
        () =>
            _deadline = DateTime(picked.year, picked.month, picked.day, 23, 59),
      );
    }
  }

  String _fmt(DateTime? d, AppLocalizations l10n) => d == null
      ? l10n.epPickDate
      : '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.existing == null ? l10n.epAddOption : l10n.epEditOption,
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.epOptionNameReq,
                hintText: l10n.cpOptionNameHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.epOptionCostNum,
                // 만드는 사람도 입력하는 순간 통화를 알아야 한다. 단위 없이
                // 숫자만 적게 하면 현지 통화로 착각해 자릿수를 틀리게 넣는다.
                prefixText: '${Money.symbol} ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactCtrl,
              decoration: InputDecoration(
                labelText: l10n.epOptionContactName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.epOptionDesc,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // 기간 선택 (시작~종료를 달력 1개로)
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range, size: 16),
              label: Text(
                (_startDate == null || _endDate == null)
                    ? l10n.epPickDate
                    : '${_fmt(_startDate, l10n)}  ~  ${_fmt(_endDate, l10n)}',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: _pickDateRange,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 4),
            // 투어 값에 안 들어 있는 것과, 그때 더 들 것 같은 돈(061).
            // 숙박은 060 의 값을 뒤집어 보인다 — 저장은 한 곳이다.
            Text(
              l10n.epTourNotIncluded,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                l10n.epTourNotIncludedHelp,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            _NotIncludedRow(
              label: l10n.epTourNoMeals,
              checked: !_includesMeals,
              amount: _estMealsCtrl,
              hint: l10n.epTourEstimate,
              unknownHint: l10n.epTourEstimateUnknown,
              includedLabel: l10n.epTourYesMeals,
              onChanged: (v) => setState(() => _includesMeals = !v),
            ),
            _NotIncludedRow(
              label: l10n.epTourNoLodging,
              checked: !_includesLodging,
              amount: _estLodgingCtrl,
              hint: l10n.epTourEstimate,
              unknownHint: l10n.epTourEstimateUnknown,
              includedLabel: l10n.epTourYesLodging,
              onChanged: (v) => setState(() => _includesLodging = !v),
            ),
            _NotIncludedRow(
              label: l10n.epTourNoAirfare,
              checked: !_includesAirfare,
              amount: _estAirfareCtrl,
              hint: l10n.epTourEstimate,
              unknownHint: l10n.epTourEstimateUnknown,
              includedLabel: l10n.epTourYesAirfare,
              onChanged: (v) => setState(() => _includesAirfare = !v),
            ),
            const SizedBox(height: 12),
            // 정원 + 신청 마감
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.epCapacity,
                      prefixIcon: const Icon(Icons.groups_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_busy, size: 16),
                    label: Text(
                      _deadline == null
                          ? l10n.epSignupDeadline
                          : _fmt(_deadline, l10n),
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: _pickDeadline,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 계획서 PDF (여러 장). 일정표·비용안내·신청서처럼 나눠 주는
            // 자료가 보통 여러 장이라, 한 칸으로는 나머지를 둘 데가 없었다.
            Row(
              children: [
                Text(
                  l10n.epPlanDocs(_planDocs.length),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_planDocs.length < _maxPlanDocs)
                  TextButton.icon(
                    icon: _planBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(
                      _planBusy ? l10n.photoUploading : l10n.epPlanUpload,
                    ),
                    onPressed: _planBusy ? null : _addPlanDoc,
                  ),
              ],
            ),
            for (var i = 0; i < _planDocs.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.picture_as_pdf, size: 20),
                title: Text(
                  '${_planDocs[i]['name'] ?? ''}',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: _planDocs[i]['bytes'] == null
                    ? null
                    : Text(
                        _fileSize(_planDocs[i]['bytes']),
                        style: const TextStyle(fontSize: 11),
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l10n.epPlanRemove,
                  // 목록에서만 뺀다. 서버의 파일은 지우지 않는다 — 옵션을
                  // 고치면 예전 행이 비활성으로 남고(programs.js), 그 행이
                  // 아직 이 주소를 가리킨다.
                  onPressed: () => setState(() => _planDocs.removeAt(i)),
                ),
              ),
            const SizedBox(height: 8),
            // 우리가 받지 않는 자료(구글 드라이브·유튜브 등)는 주소로 붙인다.
            TextField(
              controller: _brochureCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.epBrochureUrl,
                hintText: 'https://...',
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _videoCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.epVideoUrl,
                hintText: 'https://...',
                prefixIcon: const Icon(Icons.ondemand_video_outlined),
              ),
            ),
            const SizedBox(height: 12),
            // 사진 (최대 6장). 기기에서 고르는 것이 기본이고,
            // 주소 붙여넣기는 이미 올려 둔 사진을 쓸 때를 위해 남겨 둔다.
            Row(
              children: [
                Text(
                  l10n.epPhotos(_photoUrls.length),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_photoUrls.length < 6) ...[
                  TextButton.icon(
                    icon: _photoBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(
                      _photoBusy ? l10n.photoUploading : l10n.photoPick,
                    ),
                    onPressed: _photoBusy ? null : _addPhotoFromDevice,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_link, size: 18),
                    tooltip: l10n.photoOrUrl,
                    onPressed: _photoBusy ? null : _addPhotoUrl,
                  ),
                ],
              ],
            ),
            if (_photoUrls.isNotEmpty)
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          mediaUrl(_photoUrls[i]),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photoUrls.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, {
              // **id 를 그대로 들려 보낸다.** 이것이 빠지면 서버가 새 투어로
              // 알고 새 id 로 넣는다. 그러면 이미 신청한 사람의 선택이 죽은
              // id 를 가리키게 되어 명단에서 사라진다 — 가격만 고쳤는데
              // 신청자가 0명이 되는 일이 실제로 있었다.
              if (widget.existing?['id'] != null) 'id': widget.existing!['id'],
              'name': name,
              'cost': double.tryParse(_costCtrl.text.trim()) ?? 0,
              'description': _descCtrl.text.trim(),
              'contactName': _contactCtrl.text.trim(),
              'startDate': _startDate?.toIso8601String().split('T').first,
              'endDate': _endDate?.toIso8601String().split('T').first,
              'photoUrls': List<String>.from(_photoUrls),
              'planDocs': List<Map<String, dynamic>>.from(_planDocs),
              'capacity': int.tryParse(_capacityCtrl.text.trim()),
              'signupDeadline': _deadline?.toIso8601String(),
              'includesLodging': _includesLodging,
              'includesMeals': _includesMeals,
              'includesAirfare': _includesAirfare,
              // 포함이면 금액은 보내지 않는다. 껐다 켠 뒤 남은 숫자가
              // 그대로 저장되면, 담당자가 지웠다고 여긴 값이 살아난다.
              'estMealsCost': _includesMeals ? null : _estMealsCtrl.text.trim(),
              'estLodgingCost': _includesLodging
                  ? null
                  : _estLodgingCtrl.text.trim(),
              'estAirfareCost': _includesAirfare
                  ? null
                  : _estAirfareCtrl.text.trim(),
              'brochureUrl': _brochureCtrl.text.trim(),
              'videoUrl': _videoCtrl.text.trim(),
            });
          },
          child: Text(l10n.actionConfirm),
        ),
      ],
    );
  }
}

/// 저장된 금액을 칸에 넣을 글자로. null 이면 빈 칸이다 — 0 이 아니다(061).
String _money(dynamic v) {
  if (v == null) return '';
  final n = num.tryParse('$v');
  if (n == null) return '';
  // 120.00 을 120 으로 보여 준다. 소수점 두 자리가 붙어 있으면 담당자가
  // 고치려고 커서를 옮기는 품이 는다.
  return n == n.roundToDouble() ? '${n.toInt()}' : '$n';
}

/// "□ 식사 미포함 · [예상 금액]" 한 줄.
///
/// 체크를 꺼 두면 금액 칸을 잠근다. 포함인데 금액이 적혀 있으면 그 숫자가
/// 무슨 뜻인지 읽는 사람이 알 수 없다.
class _NotIncludedRow extends StatelessWidget {
  const _NotIncludedRow({
    required this.label,
    required this.checked,
    required this.amount,
    required this.hint,
    required this.unknownHint,
    required this.includedLabel,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final TextEditingController amount;
  final String hint;
  final String unknownHint;

  /// 체크가 없을 때 그 자리에 적을 말 — "식사 포함".
  ///
  /// 잠긴 빈 칸만 두면 "아직 금액을 안 정한 것" 처럼 보인다. 실제로는
  /// 정할 것이 없다는 뜻이므로, 그렇다고 말해 주어야 한다.
  final String includedLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: InkWell(
            onTap: () => onChanged(!checked),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  onChanged: (v) => onChanged(v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: checked
              ? TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: hint,
                    // 비워 두면 0 이 아니라 "미정" 이라는 것을 여기서 말한다.
                    hintText: unknownHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 14),
                )
              : Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        includedLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
