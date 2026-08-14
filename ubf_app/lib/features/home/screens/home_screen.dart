import 'dart:convert';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/service_role_label.dart';
import '../../assignment/providers/assignment_provider.dart';
import '../../program/providers/program_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ubf_chapters.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../settings/widgets/language_picker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _uuidController = TextEditingController();
  bool _leaderCheckDone = false;

  @override
  void dispose() {
    _uuidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    // participant 역할이고 아직 지부장 확인을 안 했으면 이메일 매칭 실행
    if (user.role == UserRole.participant &&
        user.email != null &&
        !_leaderCheckDone) {
      _leaderCheckDone = true;
      // 프레임 후에 비동기 검사
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkLeaderEmail(user.email!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTagline),
        actions: [
          const LanguageButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.actionLogout,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l10n.actionLogout),
                  content: Text(l10n.homeLogoutConfirmBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.actionCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.actionLogout),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                _leaderCheckDone = false;
                await ref.read(authProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: switch (user.role) {
        UserRole.director => _DirectorHomeView(
          userEmail: user.email ?? '',
          uuidController: _uuidController,
        ),
        UserRole.admin => _LeaderHomeView(
          userEmail: user.email ?? '',
          uuidController: _uuidController,
        ),
        UserRole.participant => _AttendeeHomeView(
          uuidController: _uuidController,
        ),
      },
    );
  }

  /// 로그인한 이메일이 지부장 이메일과 일치하는지 확인
  Future<void> _checkLeaderEmail(String email) async {
    try {
      final data = await loadUbfChapters();
      final matches = findLeaderByEmail(data, email);
      if (matches.isEmpty || !mounted) return;

      final l10n = AppLocalizations.of(context)!;
      // 매칭된 챕터 정보로 다이얼로그 표시
      final match = matches.first;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(l10n.homeLeaderCheckTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeLeaderCheckBody(email)),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeLeaderContinent(match.continent),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        l10n.homeLeaderNation(match.nation),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        l10n.homeLeaderChapter(match.chapterName),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.homeLeaderCheckPrompt),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.homeLeaderDeclineParticipant),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.homeLeaderConfirmRegister),
            ),
          ],
        ),
      );

      // 이미 리더면 등록 화면으로 보낼 것이 아니라 지부만 채우면 된다.
      // 033 이전에 등록한 지부장은 이 칸이 비어 있어 알림이 안 나간다.
      final iso = isoForUbfNation(match.nation) ?? '';
      if (ref.read(currentUserProvider).isLeader && iso.isNotEmpty) {
        await ApiClient.updateLeaderChapter(
          chapter: match.chapterName,
          nationIso: iso,
        );
        return;
      }

      if (confirmed == true && mounted) {
        // 여기서 찾아낸 지부를 등록 화면까지 들고 간다. 서버가 같은
        // 대응표를 따로 들고 있으면 지부 목록이 바뀔 때 어긋난다(033).
        context.push(
          '/become-leader',
          extra: {
            'chapter': match.chapterName,
            'nationIso': isoForUbfNation(match.nation) ?? '',
          },
        );
      }
    } catch (_) {
      // JSON 로드 실패 시 무시 — 참가자로 계속 진행
    }
  }
}

// ─── Director 홈 화면 ────────────────────────────────────────
class _DirectorHomeView extends ConsumerWidget {
  final String userEmail;
  final TextEditingController uuidController;

  const _DirectorHomeView({
    required this.userEmail,
    required this.uuidController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.shield, size: 40, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeDirectorMode,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.homeManageMenu, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.add_circle_outline,
            title: l10n.homeCreateProgram,
            subtitle: l10n.homeCreateProgramSub,
            color: theme.colorScheme.primary,
            onTap: () => context.push('/leader/create-program'),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.folder_open,
            title: l10n.myProgramsTitle,
            subtitle: l10n.homeProgramListDirectorSub,
            color: Colors.green,
            onTap: () => context.push('/leader/programs'),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.admin_panel_settings,
            title: l10n.homeAssignAdmins,
            subtitle: l10n.homeAssignAdminsSub,
            color: Colors.deepPurple,
            onTap: () => context.push('/director/assign-admins'),
          ),
          const SizedBox(height: 28),
          // 디렉터도 참석자다. 담당자 홈과 같은 이유다.
          Text(l10n.homeAlsoAttending, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            l10n.homeAlsoAttendingSub,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const _MyProgramPicker(),
          const SizedBox(height: 14),
          Text(
            l10n.homeOrEnterUuid,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          _AttendeeHomeView(uuidController: uuidController, embedded: true),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.homeDirectorInfo,
                    style: TextStyle(color: Colors.purple[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Admin(리더) 홈 화면 ─────────────────────────────────────
class _LeaderHomeView extends ConsumerWidget {
  final String userEmail;
  final TextEditingController uuidController;

  const _LeaderHomeView({
    required this.userEmail,
    required this.uuidController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeAdminMode,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.homeManageMenu, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.add_circle_outline,
            title: l10n.homeCreateProgram,
            subtitle: l10n.homeCreateProgramSub,
            color: theme.colorScheme.primary,
            onTap: () => context.push('/leader/create-program'),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.folder_open,
            title: l10n.myProgramsTitle,
            subtitle: l10n.homeProgramListAdminSub,
            color: Colors.green,
            onTap: () => context.push('/leader/programs'),
          ),
          const SizedBox(height: 28),
          // **담당자도 참석자다.** 예전에는 역할로 화면을 갈라서, 관리자로
          // 로그인하면 자기가 적어 둔 등록 내용을 열 길이 아예 없었다.
          Text(l10n.homeAlsoAttending, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            l10n.homeAlsoAttendingSub,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const _MyProgramPicker(),
          const SizedBox(height: 14),
          Text(
            l10n.homeOrEnterUuid,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          _AttendeeHomeView(uuidController: uuidController, embedded: true),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.homeAdminInfo,
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 참가자 홈 화면 ─────────────────────────────────────────
class _AttendeeHomeView extends StatefulWidget {
  final TextEditingController uuidController;

  /// 담당자 홈 안에 끼워 넣을 때 참이다.
  ///
  /// **담당자도 참석자다.** 예전에는 역할로 화면을 통째로 갈라서, 관리자로
  /// 로그인하면 자기가 적어 둔 등록 내용을 열 길이 아예 없었다.
  /// 끼워 넣을 때는 바깥 스크롤이 부모에게 있고, 큰 제목과 "리더로 전환"
  /// 링크는 그 자리에서 뜻이 없으므로 뺀다.
  final bool embedded;

  const _AttendeeHomeView({
    required this.uuidController,
    this.embedded = false,
  });

  @override
  State<_AttendeeHomeView> createState() => _AttendeeHomeViewState();
}

class _AttendeeHomeViewState extends State<_AttendeeHomeView> {
  List<Map<String, dynamic>> _recentPrograms = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.recentProgramsKey);
    if (raw != null && mounted) {
      setState(() {
        _recentPrograms = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _removeRecent(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    _recentPrograms.removeWhere((e) => e['uuid'] == uuid);
    await prefs.setString(
      AppConstants.recentProgramsKey,
      jsonEncode(_recentPrograms),
    );
    setState(() {});
  }

  void _join(BuildContext context, String uuid) {
    if (uuid.isEmpty) return;
    context.push('/registration/$uuid');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const _ChapterNotice(),
        // 봉사 부탁(039). 담당자가 지명하면 여기로 온다 — 수락해야 확정된다.
        //
        // 최근에 연 수양회 세 개까지만 본다. 부탁은 지금 준비 중인 수양회에서
        // 오지, 몇 해 전 것에서 오지 않는다. 전부 물으면 홈을 열 때마다
        // 요청이 그만큼 늘어난다.
        for (final prog in _recentPrograms.take(3)) ...[
          _ServiceInviteNotice(programId: prog['uuid'] as String),
          // 텔레그램 연결(047). 앱 푸시가 닿지 않는 사람에게도 부탁이
          // 가도록. 봇을 안 정해 둔 수양회에서는 아무것도 안 보인다.
          _TelegramLinkCard(programId: prog['uuid'] as String),
          // 전체에 청한 모집(043). 지명은 나에게 온 부탁이고, 이쪽은
          // 아직 아무에게도 정해지지 않은 자리다.
          _ServiceCallNotice(programId: prog['uuid'] as String),
        ],
        if (!widget.embedded) ...[
          const SizedBox(height: 20),
          Text(
            l10n.homeJoinTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeJoinSub,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 20),
        // QR 나눔(031). 수양회에 등록하지 않았어도 명함은 만들 수 있다 —
        // 지난 수양회에서 만난 사람을 다시 보는 것이 이 기능의 절반이다.
        if (!widget.embedded)
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2, color: Colors.purple),
              ),
              title: Text(
                l10n.homeQrShare,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l10n.homeQrShareSub),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/cards'),
            ),
          ),
        const SizedBox(height: 24),
        TextField(
          controller: widget.uuidController,
          decoration: InputDecoration(
            labelText: l10n.homeUuidLabel,
            hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _join(context, widget.uuidController.text.trim()),
            child: Text(l10n.homeJoinButton),
          ),
        ),

        // ── 최근 참가 프로그램 ──────────────────────────
        if (_recentPrograms.isNotEmpty) ...[
          const SizedBox(height: 36),
          Text(l10n.homeRecentPrograms, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...(_recentPrograms.map((prog) {
            final uuid = prog['uuid'] as String;
            final name = prog['name'] as String? ?? uuid;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  uuid,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l10n.homeRemoveFromList,
                  onPressed: () => _removeRecent(uuid),
                ),
                onTap: () => _join(context, uuid),
              ),
            );
          })),
        ],

        if (!widget.embedded) ...[
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => context.push('/become-leader'),
              child: Text(l10n.homeBecomeLeader),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );

    // 끼워 넣을 때는 바깥 스크롤이 부모에게 있다. 스크롤을 겹치면
    // 안쪽이 먼저 먹어 버려 목록 끝까지 내려가지 않는다.
    return widget.embedded
        ? body
        : SingleChildScrollView(padding: const EdgeInsets.all(24), child: body);
  }
}

// ─── 우리 지부 지부장의 수양회 알림 ─────────────────────────
//
// 한 번이라도 등록한 적이 있으면 그 등록서에 나라와 지부가 적혀 있다.
// 그 지부의 지부장이 새 수양회를 만들면 UUID 를 몰라도 여기서 보인다.
//
// 처음 오는 사람에게는 아무것도 안 나온다 — 나라·지부를 알 방법이 없고,
// 그때는 UUID 가 유일한 길이다.
// 봉사자를 찾는다는 요청. 담당자가 전체에 청한 것이다.
//
// 지명(_ServiceInviteNotice)과 다르다 — 저쪽은 나를 콕 집어 부탁한 것이고,
// 이쪽은 아직 아무에게도 정해지지 않은 자리다. 손을 들면 신청으로 잡히고
// 확정은 담당자가 한다.
class _ServiceCallNotice extends ConsumerWidget {
  final String programId;

  const _ServiceCallNotice({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(openServiceCallsProvider(programId));

    return async.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (rows) {
        final open = rows.cast<Map<String, dynamic>>();
        if (open.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            for (final c in open)
              Card(
                color: const Color(0xFFFFF8E7),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 18,
                            color: Colors.orange[900],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.svcOpenTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.svcOpenBody(
                          serviceRoleLabel(l10n, {
                            'key': c['service_key'],
                            'label': c['label'],
                          }),
                          ((c['short'] ?? 0) as num).toInt(),
                        ),
                        style: const TextStyle(fontSize: 13.5),
                      ),
                      if ('${c['message'] ?? ''}'.isNotEmpty)
                        Text(
                          '${c['message']}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[800],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => _apply(context, ref, c),
                          child: Text(l10n.svcIllDoIt),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> call,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.applyToService(programId, '${call['service_key']}');
      ref.invalidate(openServiceCallsProvider(programId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.svcAppliedThanks)));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// 나에게 온 봉사 부탁. 답하지 않은 것만 뜬다.
//
// 지명은 부탁이지 확정이 아니다. 본인이 여기서 답해야 담당자 화면의
// "수락 대기" 가 풀린다.
class _ServiceInviteNotice extends ConsumerWidget {
  final String programId;

  const _ServiceInviteNotice({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(myServiceInvitesProvider(programId));

    return async.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (rows) {
        final all = rows.cast<Map<String, dynamic>>();
        final pending = all.where((r) => r['status'] == 'invited').toList();
        // 수락한 뒤에 부탁 카드가 사라지면, 자기가 무엇을 맡았는지 확인할
        // 데가 없어진다. 맡은 것은 남겨 둔다 — 수양회가 시작하기 전에 다시
        // 열어 보는 것이 바로 이것이다.
        final mine = all
            .where(
              (r) =>
                  r['status'] == 'confirmed' ||
                  r['status'] == 'applied' ||
                  r['status'] == 'awaiting_approval',
            )
            .toList();
        if (pending.isEmpty && mine.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            if (mine.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volunteer_activism, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.svcMineTitle,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (final r in mine)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  serviceRoleLabel(l10n, {
                                    'key': r['service_key'],
                                    'label': r['label'],
                                  }),
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ),
                              // 확정과 "기다리는 중" 은 다른 상태다. 같이
                              // 보이면 승인 대기가 끝난 줄 안다.
                              Text(
                                serviceStatusLabel(l10n, '${r['status']}'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: r['status'] == 'confirmed'
                                      ? Colors.green[700]
                                      : Colors.orange[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            for (final inv in pending)
              Card(
                color: const Color(0xFFFFF8E7),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.volunteer_activism,
                            size: 18,
                            color: Colors.orange[900],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.svcInviteTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.svcInviteBody(
                          serviceRoleLabel(l10n, {
                            'key': inv['service_key'],
                            'label': inv['label'],
                          }),
                        ),
                        style: const TextStyle(fontSize: 13.5),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _respond(context, ref, inv, false),
                            child: Text(l10n.svcDecline),
                          ),
                          FilledButton(
                            onPressed: () => _respond(context, ref, inv, true),
                            child: Text(l10n.svcAccept),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> invite,
    bool accepted,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.respondToServiceInvite(
        programId,
        invite['id'] as String,
        accepted: accepted,
      );
      ref.invalidate(myServiceInvitesProvider(programId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.svcThanks)));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _ChapterNotice extends ConsumerWidget {
  const _ChapterNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(chapterProgramsProvider);

    return async.when(
      // 못 불러와도 조용히 지나간다. 알림은 부가 기능이고, 여기서 오류를
      // 띄우면 멀쩡히 살아 있는 UUID 경로까지 막힌 것처럼 보인다.
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (programs) {
        if (programs.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (final raw in programs.cast<Map<String, dynamic>>())
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.chapterNoticeTitle('${raw['leader_name'] ?? ''}'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          raw['name'] ?? '',
                          if (raw['location'] != null) raw['location'],
                          '${raw['start_date'] ?? ''}'.split('T').first,
                        ].where((e) => '$e'.isNotEmpty).join(' · '),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.chapterNoticeAsk,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: Text(l10n.chapterNoticeLater),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () =>
                                context.push('/registration/${raw['id']}'),
                            child: Text(l10n.chapterNoticeJoin),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── 내가 만든 수양회 고르기 ─────────────────────────────────
//
// 담당자가 자기 수양회에 참석자로 들어갈 때 UUID 를 다시 찾아 붙여넣는 것은
// 말이 안 된다. 만든 목록에서 고르면 된다.
//
// UUID 칸은 그대로 둔다 — **다른 분이 만든 수양회**에는 그것이 유일한 길이다.
class _MyProgramPicker extends ConsumerWidget {
  const _MyProgramPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(leaderProgramsProvider);

    return async.when(
      // 목록을 못 불러와도 UUID 칸은 아래에 그대로 있다. 여기서 오류를
      // 크게 띄우면 멀쩡한 경로까지 막힌 것처럼 보인다.
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (programs) {
        if (programs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.homePickMyProgram,
              prefixIcon: const Icon(Icons.event_available_outlined),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final raw in programs)
                DropdownMenuItem(
                  value: (raw as Map<String, dynamic>)['id'] as String,
                  child: Text(
                    '${raw['name'] ?? ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              if (id != null) context.push('/registration/$id');
            },
          ),
        );
      },
    );
  }
}

// ─── 메뉴 타일 위젯 ─────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// 텔레그램으로도 연락받기 (047).
///
/// 봇은 사람에게 먼저 말을 걸 수 없다 — 그 사람이 봇을 열어 /start 를
/// 보내야 한다. 그래서 두 걸음이다: 링크를 열고, 돌아와서 확인을 누른다.
///
/// 확인을 사람이 누르게 하는 것이 번거로워 보이지만, 웹훅을 걸면 수양회마다
/// 다른 봇을 텔레그램에 등록해 두어야 한다. 연결은 한 사람이 한 번 하는
/// 일이므로 이쪽이 싸다.
class _TelegramLinkCard extends ConsumerStatefulWidget {
  final String programId;

  const _TelegramLinkCard({required this.programId});

  @override
  ConsumerState<_TelegramLinkCard> createState() => _TelegramLinkCardState();
}

class _TelegramLinkCardState extends ConsumerState<_TelegramLinkCard> {
  bool _busy = false;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    // 텔레그램 앱이 없으면 브라우저가 t.me 를 연다 — 거기서도 연결된다.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _check() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final r = await ApiClient.checkTelegramLink(widget.programId);
      ref.invalidate(myTelegramLinkProvider(widget.programId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r['linked'] == true ? l10n.tgLinked : l10n.tgNotYet),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    setState(() => _busy = true);
    try {
      await ApiClient.unlinkTelegram(widget.programId);
      ref.invalidate(myTelegramLinkProvider(widget.programId));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(myTelegramLinkProvider(widget.programId));

    return async.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (data) {
        // 봇을 안 정해 둔 수양회에서는 아예 내보내지 않는다. 눌러도 아무
        // 일이 안 일어나는 버튼을 두는 것보다 없는 편이 낫다.
        if (data['available'] != true) return const SizedBox.shrink();
        final linked = data['linked'] == true;
        final url = data['url'] as String?;

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
            child: Row(
              children: [
                Icon(
                  linked ? Icons.check_circle : Icons.send_outlined,
                  size: 18,
                  color: linked ? Colors.green[700] : Colors.grey[700],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    linked ? l10n.tgLinked : l10n.tgOffer,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (linked)
                  TextButton(
                    onPressed: _busy ? null : _unlink,
                    child: Text(l10n.tgUnlink),
                  )
                else ...[
                  if (url != null)
                    TextButton(
                      onPressed: _busy ? null : () => _open(url),
                      child: Text(l10n.tgOpen),
                    ),
                  TextButton(
                    onPressed: _busy ? null : _check,
                    child: Text(l10n.tgCheck),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
