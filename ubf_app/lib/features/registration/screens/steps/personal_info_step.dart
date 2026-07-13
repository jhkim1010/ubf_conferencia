import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/ubf_chapters.dart';
import '../../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
          decoration: InputDecoration(labelText: l10n.regContinent),
          hint: Text(l10n.regContinentHint),
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
          decoration: InputDecoration(labelText: l10n.regNation),
          hint: Text(l10n.regNationHint),
          disabledHint: _continent == null ? Text(l10n.regNationDisabled) : null,
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
            decoration: InputDecoration(labelText: l10n.regChapter),
            hint: Text(l10n.regChapterHint),
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
                ? l10n.regChapterNoneHint
                : l10n.regChapterManualHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // ── 지부 직접 입력 (챕터 선택 시 자동 채워짐) ───
        TextField(
          controller: _branchController,
          decoration: InputDecoration(
            labelText: l10n.regBranch,
            hintText: l10n.regBranchHint,
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
          decoration: InputDecoration(labelText: l10n.regRealName),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 12),

        // ── 성경 이름 ──────────────────────────────────
        TextField(
          controller: _bibleNameController,
          decoration: InputDecoration(
            labelText: l10n.regBibleName,
            hintText: l10n.regBibleNameHint,
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),

        // ── 성별 선택 ──────────────────────────────────
        Text(l10n.regGender, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'M', label: Text(l10n.genderMale)),
            ButtonSegment(value: 'F', label: Text(l10n.genderFemale)),
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
          decoration: InputDecoration(labelText: l10n.regAge),
          onChanged: (_) => _save(),
        ),
      ],
    );
  }
}
