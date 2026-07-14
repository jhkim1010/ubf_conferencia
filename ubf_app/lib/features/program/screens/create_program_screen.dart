import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/api_client.dart';
import '../providers/program_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

class CreateProgramScreen extends ConsumerStatefulWidget {
  const CreateProgramScreen({super.key});

  @override
  ConsumerState<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends ConsumerState<CreateProgramScreen> {
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
  String? _hostCountry; // 개최 국가 (거주 국가 == 개최 국가면 항공편 자동 생략)
  bool _isLoading = false;
  String _programType = 'international'; // 'local' | 'international'

  // 섹션 활성화 토글
  final Map<String, bool> _enabledSections = {
    'personal_info': true,
    'arrival_flight': true,
    'departure_flight': true,
    'food_requirements': true,
    'special_programs': true,
    'roommate': true,
    'volunteer_resources': true,
  };

  // 프로그램 유형 변경 시 관련 섹션 자동 조정
  void _onProgramTypeChanged(String type) {
    final isInternational = type == 'international';
    setState(() {
      _programType = type;
      _enabledSections['arrival_flight'] = isInternational;
      _enabledSections['departure_flight'] = isInternational;
      _enabledSections['special_programs'] = isInternational;
    });
  }

  Map<String, String> _sectionLabels(AppLocalizations l10n) => {
        'personal_info': l10n.regStepPersonal,
        'arrival_flight': l10n.flightInfoTitle(l10n.flightArrival),
        'departure_flight': l10n.flightInfoTitle(l10n.flightDeparture),
        'food_requirements': l10n.summarySectionFood,
        'special_programs': l10n.cpSpecialOptions,
        'roommate': l10n.summarySectionRoommate,
        'volunteer_resources': l10n.cpSecVolunteer,
      };

  // 특별 옵션 (투어, 특별프로그램 등)
  final List<Map<String, dynamic>> _options = [];
  final _optionNameController = TextEditingController();
  final _optionCostController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _airportController.dispose();
    _contact1NameController.dispose();
    _contact1PhoneController.dispose();
    _contact2NameController.dispose();
    _contact2PhoneController.dispose();
    _hostCountryController.dispose();
    _optionNameController.dispose();
    _optionCostController.dispose();
    super.dispose();
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  // 기간(시작~종료)을 달력 1개로 선택
  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 2)),
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

  void _addOption() {
    final name = _optionNameController.text.trim();
    final cost = double.tryParse(_optionCostController.text.trim()) ?? 0;
    if (name.isEmpty) return;

    setState(() {
      _options.add({'name': name, 'cost': cost, 'description': ''});
    });
    _optionNameController.clear();
    _optionCostController.clear();
  }

  Future<void> _createProgram() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      final programId = await ProgramService.createProgram(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        programType: _programType,
        startDate: _startDate,
        endDate: _endDate,
        hostCountry: _programType == 'international' ? _hostCountry : null,
        enabledSections: Map<String, bool>.from(_enabledSections),
        options: _options,
        nearestAirport: _airportController.text.trim(),
        contact1Name: _contact1NameController.text.trim(),
        contact1Phone: _contact1PhoneController.text.trim(),
        contact2Name: _contact2NameController.text.trim(),
        contact2Phone: _contact2PhoneController.text.trim(),
      );

      if (!mounted) return;
      context.push('/leader/program/$programId/created');
    } on DuplicateProgramException catch (e) {
      if (!mounted) return;
      // 중복 UUID: 기존 프로그램으로 이동 여부 확인
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.cpDupTitle),
          content: Text(l10n.cpDupBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.cpDupGoExisting),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        context.push('/leader/program/${e.existingId}/created');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cpCreateFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeCreateProgram)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 프로그램 유형 선택
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
            if (_programType == 'local') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.cpLocalNote,
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),

            // 프로그램 기본 정보
            Text(l10n.cpBasicInfo, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.cpNameLabel,
                hintText: l10n.cpNameHint,
              ),
              validator: (v) => v?.isEmpty == true ? l10n.cpNameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: l10n.cpLocationLabel,
                hintText: l10n.cpLocationHint,
              ),
              validator: (v) => v?.isEmpty == true ? l10n.cpLocationRequired : null,
            ),
            const SizedBox(height: 12),
            // 기간 선택 (시작~종료를 달력 1개로)
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
            // 개최 국가 (국제 수양회만) — 거주 국가 == 개최 국가면 항공편 자동 생략
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
                  for (final c in WorldCountries.sortedKorean)
                    DropdownMenuEntry<String>(value: c, label: c),
                ],
                onSelected: (v) => setState(() => _hostCountry = v),
              ),
            ],
            const SizedBox(height: 28),

            // 입국 안내 정보 (국제 수양회만)
            if (_programType == 'international') ...[
              Text(l10n.cpImmigrationInfo, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.cpImmigrationDesc,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _contact1NameController,
                      decoration: InputDecoration(labelText: l10n.cpName1, hintText: l10n.cpName1Hint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _contact1PhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.cpPhone1,
                        hintText: '+82-10-1234-5678',
                      ),
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
                      decoration: InputDecoration(labelText: l10n.cpName2, hintText: l10n.cpName2Hint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _contact2PhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.cpPhone2,
                        hintText: '+82-10-9876-5432',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],

            // 활성화 섹션 설정
            Text(l10n.cpSectionsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.cpSectionsDesc,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _sectionLabels(l10n).entries.map((entry) {
                  return SwitchListTile(
                    title: Text(entry.value),
                    value: _enabledSections[entry.key] ?? true,
                    onChanged: entry.key == 'personal_info'
                        ? null // 개인 정보는 항상 필수
                        : (val) => setState(() => _enabledSections[entry.key] = val),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // 특별 옵션 추가 (국제 수양회만)
            if (_programType == 'international') ...[
              Text(l10n.cpSpecialOptions, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.cpOptionsDesc,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ..._options.asMap().entries.map((entry) {
                final i = entry.key;
                final option = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(option['name']),
                    subtitle: Text(l10n.cpOptionCost('${option['cost']}')),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _options.removeAt(i)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _optionNameController,
                      decoration: InputDecoration(
                        labelText: l10n.cpOptionName,
                        hintText: l10n.cpOptionNameHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _optionCostController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.cpOptionCostLabel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: _addOption,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // 생성 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _createProgram,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.cpCreateButton),
            ),
          ],
        ),
      ),
    );
  }
}
