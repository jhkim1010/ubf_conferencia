import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/world_countries.dart';
import '../../../../core/utils/money.dart';
import '../../auth/providers/auth_provider.dart';
import '../../program/providers/program_provider.dart';
import '../providers/registration_provider.dart';
import '../../sos/widgets/sos_fab.dart';
import 'steps/personal_info_step.dart';
import 'steps/flight_info_step.dart';
import 'steps/food_step.dart';
import 'steps/options_step.dart';
import 'steps/fee_step.dart';
import 'steps/buddy_step.dart';
import 'steps/companion_step.dart';
import 'steps/volunteer_resources_step.dart';
import 'steps/study_language_step.dart';
import 'steps/hotel_step.dart';
import 'steps/pickup_step.dart';
import 'package:mana/l10n/app_localizations.dart';

// 등록 폼 - PageView 기반
//
// 스텝은 고정 목록이 아니라 build 시점에 조립한다. 조건부 스텝(자격이 있을 때만
// 나타나는 봉사 신청 등)을 넣기 위해서다. 제목과 위젯을 한 쌍으로 묶어 두면
// 인디케이터·진행바·페이지가 어긋날 수 없다.
//
// 조건부 스텝은 **맨 뒤에** 붙인다. 중간에 끼우면 이미 방문한 스텝의 인덱스가
// 밀려 _visitedPages 와 _currentPage 가 엉킨다.
typedef _Step = ({String title, Widget widget});

class RegistrationFlowScreen extends ConsumerStatefulWidget {
  final String programId;

  const RegistrationFlowScreen({super.key, required this.programId});

  @override
  ConsumerState<RegistrationFlowScreen> createState() =>
      _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState
    extends ConsumerState<RegistrationFlowScreen> {
  late final PageController _pageController;
  late final ScrollController _stepScrollController;
  int _currentPage = 0;
  final Set<int> _visitedPages = {0}; // 방문한 스텝 추적
  bool _savedToRecents = false; // 최근 목록 저장 중복 방지

  // 개최국 참석자는 항공편 스텝을 아예 건너뛴다. 다만 국토가 넓은 나라는
  // 국내에서도 비행기로 오는 경우가 있어 되살릴 수 있게 둔다.
  bool _domesticWantsFlight = false;

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
    final notifier = ref.read(
      registrationFormProvider(widget.programId).notifier,
    );

    // 1순위: 로컬 draft (앱 종료 전 마지막 상태)
    final draft = await RegistrationFormNotifier.loadDraft(widget.programId);
    if (draft != null && mounted) {
      notifier.loadFromDraft(draft);
      return;
    }

    // 2순위: 서버 DB (임시저장 버튼으로 저장한 데이터)
    final existing = await ref.read(
      registrationProvider(widget.programId).future,
    );
    if (existing != null && mounted) {
      notifier.loadFromDb(existing);
    }
  }

  // 스텝 수는 build 시점에 정해지므로 인자로 받는다.
  // 상태 필드로 캐시하면 build 와 어긋난 값으로 이동할 수 있다.
  void _nextPage(int total) {
    if (_currentPage < total - 1) {
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
    final l10n = AppLocalizations.of(context)!;

    return programAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(l10n.commonErrorDetail('$e')))),
      data: (program) {
        if (program == null) {
          return Scaffold(body: Center(child: Text(l10n.regInvalidProgram)));
        }
        // 프로그램 로드 성공 시 장치에 저장
        _saveToRecents(program['name'] as String? ?? widget.programId);

        final enabledSections = Map<String, bool>.from(
          program['enabled_sections'] as Map? ?? {},
        );
        final options = List<Map<String, dynamic>>.from(
          program['program_options'] as List? ?? [],
        );

        // 이 수양회의 통화. 주최 측이 정하고 등록자 전원이 같은 단위로 본다.
        final currency = Currency.of(program['currency'] as String?);

        // 개최 국가 == 참가자 거주 국가면 항공편 입력을 기본 생략 (필요 시 추가 가능)
        //
        // 양쪽을 ISO 로 정규화한 뒤에 비교한다. 019 마이그레이션이 기존 값을
        // 코드로 바꿨지만, 매핑에 없어 남은 값과 예전 버전 앱이 저장한 값이
        // 섞여 있을 수 있다. 정규화 없이 문자열을 그대로 비교했던 것이
        // 이 기능이 한 번도 동작하지 않은 원인이었다.
        final hostCountry = WorldCountries.isoForLegacy(
          program['host_country'] as String?,
        );
        final userCountry = WorldCountries.isoForLegacy(
          ref.watch(currentUserProvider).country,
        );
        final sameCountryAsHost =
            hostCountry != null &&
            userCountry != null &&
            userCountry == hostCountry;

        // 개최국 참석자는 항공편 스텝을 아예 만들지 않는다.
        // 되살리면(_domesticWantsFlight) 다시 들어온다.
        final skipFlightSteps = sameCountryAsHost && !_domesticWantsFlight;

        // 스텝 조립. 조건부 스텝은 맨 뒤에 붙인다(인덱스가 밀리지 않게).
        final steps = <_Step>[
          (
            title: l10n.regStepPersonal,
            widget: PersonalInfoStep(programId: widget.programId),
          ),
          (
            title: l10n.regStepCompanion,
            widget: CompanionStep(programId: widget.programId),
          ),
          // 개최국 참석자에게는 항공편 대신 픽업만 묻는다(035).
          // 버스로·차로 오므로 항공편은 뜻이 없지만, 어디서 태울지는 알아야
          // 한다 — 예전에는 아무것도 안 물어서 그 사람들이 배차 명단에서
          // 통째로 빠졌다.
          if (skipFlightSteps)
            (
              title: l10n.regStepPickup,
              widget: PickupStep(programId: widget.programId),
            ),
          // 개최국 참석자는 항공편 스텝 자체를 넣지 않는다. 배너에서 되살릴 수 있다.
          if (!skipFlightSteps) ...[
            (
              title: l10n.regStepArrival,
              widget: FlightInfoStep(
                programId: widget.programId,
                isArrival: true,
                enabled: enabledSections['arrival_flight'] ?? true,
                sameCountryAsHost: false,
              ),
            ),
            (
              title: l10n.regStepDeparture,
              widget: FlightInfoStep(
                programId: widget.programId,
                isArrival: false,
                enabled: enabledSections['departure_flight'] ?? true,
                sameCountryAsHost: false,
              ),
            ),
          ],
          (
            title: l10n.regStepFood,
            widget: FoodStep(
              programId: widget.programId,
              enabled: enabledSections['food_requirements'] ?? true,
            ),
          ),
          (
            title: l10n.regStepOptions,
            widget: OptionsStep(
              programId: widget.programId,
              options: options,
              currency: currency,
              enabled: enabledSections['special_programs'] ?? true,
            ),
          ),
          (
            title: l10n.regStepBuddy,
            widget: BuddyStep(
              programId: widget.programId,
              enabled: enabledSections['roommate'] ?? true,
            ),
          ),
          // 말씀 공부 언어. 성경공부 팀이 이 값으로 갈리므로(025) 본인에게 묻는다.
          // 앞의 룸메이트 단계 바로 뒤에 둔다 — 둘 다 "누구와 함께하는가"다.
          (
            title: l10n.regStepStudyLang,
            widget: StudyLanguageStep(programId: widget.programId),
          ),
          // 수양회 전후 숙박(028). **외국에서 오는 사람에게만 묻는다** —
          // 개최국 참가자는 전후에 집으로 가므로 물어볼 것이 없고,
          // 서버도 그 선택을 떨어뜨린다(services/hotel.js).
          if (!sameCountryAsHost && hostCountry != null)
            (
              title: l10n.regStepHotel,
              widget: HotelStep(
                programId: widget.programId,
                options: List<Map<String, dynamic>>.from(
                  program['hotel_options'] as List? ?? const [],
                ),
                currency: currency,
                // 항공편으로 박수를 계산하려면 수양회 일정과 투어 종료일이
                // 필요하다. 투어가 수양회보다 늦게 끝나면 그 뒤부터 호텔이다.
                programStart: program['start_date'],
                programEnd: program['end_date'],
                tours: options,
              ),
            ),
          (
            title: l10n.regStepVolunteer,
            widget: VolunteerResourcesStep(
              programId: widget.programId,
              enabled: enabledSections['volunteer_resources'] ?? true,
            ),
          ),
          // 참가비는 등급을 하나라도 정해 둔 수양회에서만 묻는다.
          // 참가비가 없는 행사에 빈 화면을 하나 더 보여줄 이유는 없다.
          if (program['fee_basic'] != null || program['fee_premium'] != null)
            (
              title: l10n.regStepFee,
              widget: FeeStep(
                programId: widget.programId,
                feeBasic: Money.parse(program['fee_basic']),
                feePremium: Money.parse(program['fee_premium']),
                feeBasicDesc: program['fee_basic_desc'] as String?,
                feePremiumDesc: program['fee_premium_desc'] as String?,
                discountOptions: List<Map<String, dynamic>>.from(
                  program['discount_options'] as List? ?? const [],
                ),
                currency: currency,
                hostCountry: hostCountry,
              ),
            ),
        ];
        final total = steps.length;

        return Scaffold(
          floatingActionButton: SosFab(programId: widget.programId),
          appBar: AppBar(
            title: Text(program['name'] ?? l10n.regTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.event_note_outlined),
                tooltip: l10n.regScheduleTooltip,
                onPressed: () =>
                    context.push('/program/${widget.programId}/schedule'),
              ),
              // 자료실(030). 등록 중에도 교재를 볼 일이 있다.
              IconButton(
                icon: const Icon(Icons.folder_copy_outlined),
                tooltip: l10n.libTitle,
                onPressed: () =>
                    context.push('/program/${widget.programId}/library'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(6),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / total,
                backgroundColor: Colors.grey[200],
              ),
            ),
          ),
          body: Column(
            children: [
              // 항공편 스텝을 건너뛴 국내 참석자에게만 보이는 되살리기 배너.
              // 국토가 넓은 나라는 국내에서도 비행기로 오는 경우가 있다.
              if (skipFlightSteps)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flight_takeoff,
                        size: 18,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.flightSkipTitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _domesticWantsFlight = true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.flightSkipAdd,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              // 스텝 인디케이터 (가로 스크롤, 완료 스텝 탭으로 이동 가능)
              SizedBox(
                height: 52,
                child: ListView.separated(
                  controller: _stepScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: total,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.12)
                              : isVisited
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVisited && !isCurrent
                                  ? Icons.check_circle
                                  : Icons.circle,
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${i + 1}. ${steps[i].title}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
                      steps[_currentPage].title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: Text(l10n.regSaveDraft),
                      onPressed: () async {
                        // async 전에 미리 참조 확보
                        final messenger = ScaffoldMessenger.of(context);
                        await ref
                            .read(
                              registrationFormProvider(
                                widget.programId,
                              ).notifier,
                            )
                            .saveProgress(options);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.commonSaved)),
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
                  children: [for (final s in steps) s.widget],
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
                          child: Text(l10n.actionPrevious),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _currentPage < total - 1
                            ? () => _nextPage(total)
                            : () => context.push(
                                '/registration/${widget.programId}/summary',
                              ),
                        child: Text(
                          _currentPage < total - 1
                              ? l10n.actionNext
                              : l10n.regReviewSummary,
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
