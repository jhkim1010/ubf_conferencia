import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/api_client.dart';
import '../providers/program_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

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

  DateTime? _startDate;
  DateTime? _endDate;
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

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _airportController.dispose();
    _contact1NameController.dispose();
    _contact1PhoneController.dispose();
    _contact2NameController.dispose();
    _contact2PhoneController.dispose();
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

    final sections = Map<String, dynamic>.from(program['enabled_sections'] ?? {});
    for (final key in _enabledSections.keys) {
      _enabledSections[key] = sections[key] as bool? ?? true;
    }

    final rawOptions = program['program_options'];
    if (rawOptions is List) {
      _options = rawOptions.map((o) => Map<String, dynamic>.from(o as Map)).toList();
    }
  }

  void _onProgramTypeChanged(String type) {
    final isInternational = type == 'international';
    setState(() {
      _programType = type;
      _enabledSections['arrival_flight'] = isInternational;
      _enabledSections['departure_flight'] = isInternational;
      _enabledSections['special_programs'] = isInternational;
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

  Future<void> _showOptionDialog({Map<String, dynamic>? existing, int? index}) async {
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
        'enabledSections': Map<String, bool>.from(_enabledSections),
        'options': _options,
        'nearestAirport': _airportController.text.trim(),
        'contact1Name': _contact1NameController.text.trim(),
        'contact1Phone': _contact1PhoneController.text.trim(),
        'contact2Name': _contact2NameController.text.trim(),
        'contact2Phone': _contact2PhoneController.text.trim(),
      });

      if (!mounted) return;
      // 캐시 무효화 후 대시보드로 복귀
      ref.invalidate(programByIdProvider(widget.programId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.epSaved)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSaveFailed('$e'))),
        );
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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(l10n.commonErrorDetail('$e')))),
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
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.actionSave, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  validator: (v) => v?.isEmpty == true ? l10n.cpNameRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: l10n.cpLocationLabel),
                  validator: (v) => v?.isEmpty == true ? l10n.cpLocationRequired : null,
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
                const SizedBox(height: 28),

                // 입국 안내 (국제만)
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
                            ? null
                            : (val) => setState(() => _enabledSections[entry.key] = val),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                // 투어 옵션 (국제만)
                if (_programType == 'international') ...[
                  Row(
                    children: [
                      Text(l10n.cpSpecialOptions, style: theme.textTheme.titleMedium),
                      if (_startDate != null && !_startDate!.isAfter(DateTime.now())) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 시작일이 지났으면 잠금 안내
                  if (_startDate != null && !_startDate!.isAfter(DateTime.now()))
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
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.epTourLocked,
                              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      l10n.cpOptionsDesc,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 8),
                  ..._options.asMap().entries.map((entry) {
                    final i = entry.key;
                    final option = entry.value;
                    final locked = _startDate != null && !_startDate!.isAfter(DateTime.now());
                    final dates = [
                      if (option['startDate'] != null) option['startDate'],
                      if (option['endDate'] != null) option['endDate'],
                    ].join(' ~ ');
                    return Card(
                      child: ListTile(
                        title: Text(option['name'] as String? ?? ''),
                        subtitle: Text([
                          l10n.cpOptionCost('${option['cost']}'),
                          if (dates.isNotEmpty) dates,
                          if ((option['contactName'] as String?)?.isNotEmpty == true)
                            l10n.epOptionContact('${option['contactName']}'),
                        ].join('  |  ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showOptionDialog(existing: option, index: i),
                            ),
                            if (!locked)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => setState(() => _options.removeAt(i)),
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
  DateTime? _startDate;
  DateTime? _endDate;
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
      if (e['startDate'] != null) _startDate = DateTime.tryParse(e['startDate'] as String);
      if (e['endDate'] != null) _endDate = DateTime.tryParse(e['endDate'] as String);
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

  Future<void> _pickPhoto() async {
    if (_photoUrls.length >= 5) return;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile == null) return;
    // TODO: 실제 서버 업로드 후 URL 저장 — 현재는 로컬 경로 임시 저장
    setState(() => _photoUrls.add(xfile.path));
  }

  String _fmt(DateTime? d, AppLocalizations l10n) => d == null
      ? l10n.epPickDate
      : '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.epAddOption : l10n.epEditOption),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.epOptionNameReq, hintText: l10n.cpOptionNameHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.epOptionCostNum),
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
            // 사진 (최대 5장)
            Row(
              children: [
                Text(l10n.epPhotos(_photoUrls.length),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_photoUrls.length < 5)
                  TextButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: Text(l10n.actionAdd),
                    onPressed: _pickPhoto,
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
                        child: Image.asset(
                          _photoUrls[i],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
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
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
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
            });
          },
          child: Text(l10n.actionConfirm),
        ),
      ],
    );
  }
}
