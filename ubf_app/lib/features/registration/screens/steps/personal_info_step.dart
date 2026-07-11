import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/ubf_chapters.dart';
import '../../providers/registration_provider.dart';

class PersonalInfoStep extends ConsumerStatefulWidget {
  final String programId;

  const PersonalInfoStep({super.key, required this.programId});

  @override
  ConsumerState<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends ConsumerState<PersonalInfoStep> {
  String? _continent; // 대륙
  String? _nation;    // 국가
  String? _chapter;   // 챕터 이름 → branch 필드로 저장
  late final TextEditingController _branchController;
  late final TextEditingController _realNameController;
  late final TextEditingController _bibleNameController;
  late final TextEditingController _ageController;
  String? _gender;

  // JSON에서 로드된 챕터 데이터
  List<UbfNationData> _chaptersData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider(widget.programId));
    _nation = state.country;
    _branchController = TextEditingController(text: state.branch ?? '');
    _realNameController = TextEditingController(text: state.realName ?? '');
    _bibleNameController = TextEditingController(text: state.bibleName ?? '');
    _ageController = TextEditingController(text: state.age?.toString() ?? '');
    _gender = state.gender;

    _loadChaptersData();
  }

  Future<void> _loadChaptersData() async {
    final data = await loadUbfChapters();
    setState(() {
      _chaptersData = data;
      _isLoading = false;

      // 저장된 국가로 대륙 복원
      if (_nation != null) {
        final match = data.where((e) => e.nation == _nation);
        if (match.isNotEmpty) {
          _continent = match.first.continent;
        }
        // 저장된 지부명으로 챕터 복원
        if (_branchController.text.isNotEmpty) {
          final chapters = getChaptersForNation(data, _nation!);
          final branch = _branchController.text;
          final chapterMatch = chapters.where((c) => c.name == branch);
          if (chapterMatch.isNotEmpty) {
            _chapter = branch;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _branchController.dispose();
    _realNameController.dispose();
    _bibleNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(registrationFormProvider(widget.programId).notifier).updatePersonalInfo(
      country: _nation,
      branch: _branchController.text.trim(),
      realName: _realNameController.text.trim(),
      bibleName: _bibleNameController.text.trim(),
      gender: _gender,
      age: int.tryParse(_ageController.text.trim()),
    );
  }

  // 대륙 변경 시 국가/챕터 초기화
  void _onContinentChanged(String? continent) {
    setState(() {
      _continent = continent;
      _nation = null;
      _chapter = null;
      _branchController.text = '';
    });
    _save();
  }

  // 국가 변경 시 챕터 초기화
  void _onNationChanged(String? nation) {
    setState(() {
      _nation = nation;
      _chapter = null;
      _branchController.text = '';
    });
    _save();
  }

  // 챕터 선택 시 지부 필드 자동 채우기
  void _onChapterChanged(String? chapterName) {
    setState(() => _chapter = chapterName);
    if (chapterName != null) {
      _branchController.text = chapterName;
    }
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 대륙 목록
    final continents = getContinents(_chaptersData);
    // 선택한 대륙의 국가 목록
    final nations = _continent != null
        ? getNationsForContinent(_chaptersData, _continent!)
        : <String>[];
    // 선택한 국가의 챕터 목록
    final chapters = _nation != null
        ? getChaptersForNation(_chaptersData, _nation!)
        : <UbfChapter>[];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── 대륙 드롭다운 ──────────────────────────────
        DropdownButtonFormField<String>(
          initialValue: _continent,
          decoration: const InputDecoration(labelText: '대륙 *'),
          hint: const Text('대륙 선택'),
          items: continents.map((c) {
            return DropdownMenuItem<String>(value: c, child: Text(c));
          }).toList(),
          onChanged: _onContinentChanged,
        ),
        const SizedBox(height: 12),

        // ── 국가 드롭다운 (대륙 선택 후 활성화) ─────────
        DropdownButtonFormField<String>(
          key: ValueKey('nation_$_continent'),
          initialValue: _nation,
          decoration: const InputDecoration(labelText: '국가 *'),
          hint: const Text('국가 선택'),
          disabledHint: _continent == null ? const Text('대륙을 먼저 선택하세요') : null,
          items: nations.map((n) {
            return DropdownMenuItem<String>(value: n, child: Text(n));
          }).toList(),
          onChanged: _continent != null ? _onNationChanged : null,
        ),
        const SizedBox(height: 12),

        // ── 챕터 드롭다운 (국가 선택 후, 챕터가 있을 때만) ──
        if (_nation != null && chapters.isNotEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey('chapter_$_nation'),
            initialValue: _chapter,
            decoration: const InputDecoration(labelText: '챕터 *'),
            hint: const Text('챕터 선택'),
            items: chapters.map((ch) {
              return DropdownMenuItem<String>(
                value: ch.name,
                child: Text(ch.name),
              );
            }).toList(),
            onChanged: _onChapterChanged,
          ),

        // 챕터 목록에 없는 경우 직접 입력 안내
        if (_nation != null) ...[
          const SizedBox(height: 4),
          Text(
            chapters.isEmpty
                ? '해당 국가에 등록된 챕터가 없습니다. 아래에 직접 입력하세요.'
                : '목록에 없으면 아래에 직접 입력하세요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // ── 지부 직접 입력 (챕터 선택 시 자동 채워짐) ───
        TextField(
          controller: _branchController,
          decoration: const InputDecoration(
            labelText: '지부명 *',
            hintText: '예: Tokyo, Chicago',
          ),
          onChanged: (_) {
            setState(() => _chapter = null); // 직접 입력 시 챕터 선택 해제
            _save();
          },
        ),
        const SizedBox(height: 12),

        // ── 본명 ───────────────────────────────────────
        TextField(
          controller: _realNameController,
          decoration: const InputDecoration(labelText: '본명 *'),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 12),

        // ── 성경 이름 ──────────────────────────────────
        TextField(
          controller: _bibleNameController,
          decoration: const InputDecoration(
            labelText: '성경 이름',
            hintText: '예: 베드로, 마리아',
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),

        // ── 성별 선택 ──────────────────────────────────
        Text('성별', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'M', label: Text('남')),
            ButtonSegment(value: 'F', label: Text('여')),
          ],
          selected: _gender != null ? {_gender!} : {},
          emptySelectionAllowed: true,
          onSelectionChanged: (val) {
            setState(() => _gender = val.isEmpty ? null : val.first);
            _save();
          },
        ),
        const SizedBox(height: 12),

        // ── 나이 ───────────────────────────────────────
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '나이 *'),
          onChanged: (_) => _save(),
        ),
      ],
    );
  }
}
