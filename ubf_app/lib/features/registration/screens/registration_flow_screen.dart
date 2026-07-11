import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../program/providers/program_provider.dart';
import '../providers/registration_provider.dart';
import '../../sos/widgets/sos_fab.dart';
import 'steps/personal_info_step.dart';
import 'steps/flight_info_step.dart';
import 'steps/food_step.dart';
import 'steps/options_step.dart';
import 'steps/roommate_step.dart';
import 'steps/volunteer_resources_step.dart';

// 6단계 등록 폼 - PageView 기반
class RegistrationFlowScreen extends ConsumerStatefulWidget {
  final String programId;

  const RegistrationFlowScreen({super.key, required this.programId});

  @override
  ConsumerState<RegistrationFlowScreen> createState() =>
      _RegistrationFlowScreenState();
}

// 각 스텝의 제목 (전역 상수)
const _stepTitles = ['개인 정보', '도착 비행기', '출발 비행기', '음식', '투어/옵션', '룸메이트', '자원봉사'];

class _RegistrationFlowScreenState extends ConsumerState<RegistrationFlowScreen> {
  late final PageController _pageController;
  late final ScrollController _stepScrollController;
  int _currentPage = 0;
  final Set<int> _visitedPages = {0}; // 방문한 스텝 추적
  bool _savedToRecents = false; // 최근 목록 저장 중복 방지

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _stepScrollController = ScrollController();
    _loadExistingData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stepScrollController.dispose();
    super.dispose();
  }

  // 프로그램 UUID + 이름을 장치에 저장 (최대 5개, 최신순)
  Future<void> _saveToRecents(String name) async {
    if (_savedToRecents) return;
    _savedToRecents = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.recentProgramsKey);
    final list = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    // 중복 제거 후 맨 앞에 추가
    list.removeWhere((e) => e['uuid'] == widget.programId);
    list.insert(0, {'uuid': widget.programId, 'name': name});
    if (list.length > 5) list.removeLast();
    await prefs.setString(AppConstants.recentProgramsKey, jsonEncode(list));
  }

  Future<void> _loadExistingData() async {
    final notifier = ref.read(registrationFormProvider(widget.programId).notifier);

    // 1순위: 로컬 draft (앱 종료 전 마지막 상태)
    final draft = await RegistrationFormNotifier.loadDraft(widget.programId);
    if (draft != null && mounted) {
      notifier.loadFromDraft(draft);
      return;
    }

    // 2순위: 서버 DB (임시저장 버튼으로 저장한 데이터)
    final existing = await ref.read(registrationProvider(widget.programId).future);
    if (existing != null && mounted) {
      notifier.loadFromDb(existing);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int get _totalPages => 7;

  void _jumpToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(programByIdProvider(widget.programId));

    return programAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('오류: $e')),
      ),
      data: (program) {
        if (program == null) {
          return const Scaffold(
            body: Center(child: Text('유효하지 않은 프로그램 UUID입니다')),
          );
        }
        // 프로그램 로드 성공 시 장치에 저장
        _saveToRecents(program['name'] as String? ?? widget.programId);

        final enabledSections = Map<String, bool>.from(
          program['enabled_sections'] as Map? ?? {},
        );
        final options = List<Map<String, dynamic>>.from(
          program['program_options'] as List? ?? [],
        );

        return Scaffold(
          floatingActionButton: SosFab(programId: widget.programId),
          appBar: AppBar(
            title: Text(program['name'] ?? '등록'),
            actions: [
              IconButton(
                icon: const Icon(Icons.event_note_outlined),
                tooltip: '프로그램 일정',
                onPressed: () => context.push('/program/${widget.programId}/schedule'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(6),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                backgroundColor: Colors.grey[200],
              ),
            ),
          ),
          body: Column(
            children: [
              // 스텝 인디케이터 (가로 스크롤, 완료 스텝 탭으로 이동 가능)
              SizedBox(
                height: 52,
                child: ListView.separated(
                  controller: _stepScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _totalPages,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final isVisited = _visitedPages.contains(i);
                    final isCurrent = i == _currentPage;
                    final color = isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : isVisited
                            ? Colors.green
                            : Colors.grey[400]!;
                    return GestureDetector(
                      onTap: isVisited ? () => _jumpToPage(i) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                              : isVisited
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color, width: isCurrent ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVisited && !isCurrent ? Icons.check_circle : Icons.circle,
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${i + 1}. ${_stepTitles[i]}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 임시저장 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    Text(
                      _stepTitles[_currentPage],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text('임시저장'),
                      onPressed: () async {
                        // async 전에 미리 참조 확보
                        final messenger = ScaffoldMessenger.of(context);
                        await ref
                            .read(registrationFormProvider(widget.programId).notifier)
                            .saveProgress(options);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('저장되었습니다')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // 단계별 폼
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() {
                    _currentPage = page;
                    _visitedPages.add(page);
                  }),
                  children: [
                    PersonalInfoStep(programId: widget.programId),
                    FlightInfoStep(
                      programId: widget.programId,
                      isArrival: true,
                      enabled: enabledSections['arrival_flight'] ?? true,
                    ),
                    FlightInfoStep(
                      programId: widget.programId,
                      isArrival: false,
                      enabled: enabledSections['departure_flight'] ?? true,
                    ),
                    FoodStep(
                      programId: widget.programId,
                      enabled: enabledSections['food_requirements'] ?? true,
                    ),
                    OptionsStep(
                      programId: widget.programId,
                      options: options,
                      enabled: enabledSections['special_programs'] ?? true,
                    ),
                    RoommateStep(
                      programId: widget.programId,
                      enabled: enabledSections['roommate'] ?? true,
                    ),
                    VolunteerResourcesStep(
                      programId: widget.programId,
                      enabled: enabledSections['volunteer_resources'] ?? true,
                    ),
                  ],
                ),
              ),
              // 이전/다음 버튼
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevPage,
                          child: const Text('이전'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _currentPage < _totalPages - 1
                            ? _nextPage
                            : () => context.push(
                                '/registration/${widget.programId}/summary',
                              ),
                        child: Text(
                          _currentPage < _totalPages - 1 ? '다음' : '요약 확인',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
