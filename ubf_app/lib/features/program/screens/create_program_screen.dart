import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/api_client.dart';
import '../providers/program_provider.dart';

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
  DateTime? _startDate;
  DateTime? _endDate;
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

  final Map<String, String> _sectionLabels = {
    'personal_info': '개인 정보',
    'arrival_flight': '도착 비행기 정보',
    'departure_flight': '출발 비행기 정보',
    'food_requirements': '음식 특별 사항',
    'special_programs': '특별 프로그램/투어 옵션',
    'roommate': '룸메이트 희망',
    'volunteer_resources': '프로그램 진행 도움 자원 (악기, 번역 etc)',
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
    _optionNameController.dispose();
    _optionCostController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
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

    setState(() => _isLoading = true);

    try {
      final programId = await ProgramService.createProgram(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        programType: _programType,
        startDate: _startDate,
        endDate: _endDate,
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
          title: const Text('이미 존재하는 프로그램'),
          content: const Text(
            '같은 이름과 시작일의 프로그램이 이미 있습니다.\n기존 프로그램의 UUID 화면으로 이동할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('기존 프로그램으로'),
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
          SnackBar(content: Text('프로그램 생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('새 프로그램 생성')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 프로그램 유형 선택
            Text('프로그램 유형', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'local',
                  label: Text('지역 수양회'),
                  icon: Icon(Icons.location_city),
                ),
                ButtonSegment(
                  value: 'international',
                  label: Text('국제 수양회'),
                  icon: Icon(Icons.flight),
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
                        '지역 수양회: 항공편·투어 섹션은 자동으로 비활성화됩니다',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),

            // 프로그램 기본 정보
            Text('기본 정보', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '프로그램 이름 *',
                hintText: '예: 2025 여름 수양회',
              ),
              validator: (v) => v?.isEmpty == true ? '프로그램 이름을 입력하세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '장소 *',
                hintText: '예: 제주도 국제 컨벤션 센터',
              ),
              validator: (v) => v?.isEmpty == true ? '장소를 입력하세요' : null,
            ),
            const SizedBox(height: 12),
            // 날짜 선택
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _startDate == null
                          ? '시작일 선택'
                          : '${_startDate!.year}.${_startDate!.month.toString().padLeft(2, '0')}.${_startDate!.day.toString().padLeft(2, '0')}',
                    ),
                    onPressed: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _endDate == null
                          ? '종료일 선택'
                          : '${_endDate!.year}.${_endDate!.month.toString().padLeft(2, '0')}.${_endDate!.day.toString().padLeft(2, '0')}',
                    ),
                    onPressed: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 입국 안내 정보 (국제 수양회만)
            if (_programType == 'international') ...[
              Text('입국 안내 정보', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '참가자가 공항 입국 시 감사관에게 보여줄 정보입니다 (선택)',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _airportController,
                decoration: const InputDecoration(
                  labelText: '가까운 공항',
                  hintText: '예: 인천국제공항 (ICN)',
                  prefixIcon: Icon(Icons.flight_land),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '현장 대표 연락처 (2명)',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _contact1NameController,
                      decoration: const InputDecoration(labelText: '이름 1', hintText: '홍길동'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _contact1PhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '전화번호 1',
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
                      decoration: const InputDecoration(labelText: '이름 2', hintText: '김철수'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _contact2PhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '전화번호 2',
                        hintText: '+82-10-9876-5432',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],

            // 활성화 섹션 설정
            Text('등록 섹션 활성화', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '참가자에게 보여줄 항목을 선택하세요',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _sectionLabels.entries.map((entry) {
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
              Text('특별 프로그램/투어 옵션', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '옵션별 비용을 설정하면 참가자가 선택할 수 있습니다',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ..._options.asMap().entries.map((entry) {
                final i = entry.key;
                final option = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(option['name']),
                    subtitle: Text('비용: ${option['cost']}'),
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
                      decoration: const InputDecoration(
                        labelText: '옵션명',
                        hintText: '제주 투어 A코스',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _optionCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '비용'),
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
                  : const Text('프로그램 생성 (UUID 발급)'),
            ),
          ],
        ),
      ),
    );
  }
}
