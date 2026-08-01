import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/api_client.dart';
import '../providers/program_provider.dart';
import '../widgets/fee_section.dart';
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
  final _contact1NameController = TextEditingController();
  final _contact1PhoneController = TextEditingController();
  final _contact2NameController = TextEditingController();
  final _contact2PhoneController = TextEditingController();
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

  // 이 수양회의 통화. 등록자 전원이 이 단위로 본다.
  Currency _currency = Currency.usd;

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
    _contact1NameController.dispose();
    _contact1PhoneController.dispose();
    _contact2NameController.dispose();
    _contact2PhoneController.dispose();
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
    _contact1NameController.text = program['contact1_name'] ?? '';
    _contact1PhoneController.text = program['contact1_phone'] ?? '';
    _contact2NameController.text = program['contact2_name'] ?? '';
    _contact2PhoneController.text = program['contact2_phone'] ?? '';

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

    final rawDiscounts = program['discount_options'];
    if (rawDiscounts is List) {
      _discountOptions = rawDiscounts
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
        'contact1Name': _contact1NameController.text.trim(),
        'contact1Phone': _contact1PhoneController.text.trim(),
        'contact2Name': _contact2NameController.text.trim(),
        'contact2Phone': _contact2PhoneController.text.trim(),
        'feeBasic': _fee(_feeBasicController),
        'feePremium': _fee(_feePremiumController),
        'feeBasicDesc': _text(_feeBasicDescController),
        'feePremiumDesc': _text(_feePremiumDescController),
        'discountOptions': _discountOptions,
        'currency': _currency.code,
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
                  Text(
                    l10n.cpContacts,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _contact1NameController,
                          decoration: InputDecoration(labelText: l10n.cpName1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _contact1PhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: l10n.cpPhone1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _contact2NameController,
                          decoration: InputDecoration(labelText: l10n.cpName2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _contact2PhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: l10n.cpPhone2),
                        ),
                      ),
                    ],
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
  final _brochureCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _deadline;
  final List<String> _photoUrls = [];

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

  // 사진 URL 붙여넣기 (MVP — 실제 파일 업로드는 스토리지 도입 후)
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
            // 홍보물 링크 (브로슈어 / 영상)
            TextField(
              controller: _brochureCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.epBrochureUrl,
                hintText: 'https://...',
                prefixIcon: const Icon(Icons.description_outlined),
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
            // 사진 (최대 6장 — URL 붙여넣기)
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
                if (_photoUrls.length < 6)
                  TextButton.icon(
                    icon: const Icon(Icons.add_link, size: 18),
                    label: Text(l10n.actionAdd),
                    onPressed: _addPhotoUrl,
                  ),
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
                          _photoUrls[i],
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
              'name': name,
              'cost': double.tryParse(_costCtrl.text.trim()) ?? 0,
              'description': _descCtrl.text.trim(),
              'contactName': _contactCtrl.text.trim(),
              'startDate': _startDate?.toIso8601String().split('T').first,
              'endDate': _endDate?.toIso8601String().split('T').first,
              'photoUrls': List<String>.from(_photoUrls),
              'capacity': int.tryParse(_capacityCtrl.text.trim()),
              'signupDeadline': _deadline?.toIso8601String(),
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
