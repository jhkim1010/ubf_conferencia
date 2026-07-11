import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ubf_chapters.dart';
import '../../auth/providers/auth_provider.dart';

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
        title: const Text('수양회 참가자 등록 시스템'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('로그아웃하시겠습니까?\n다른 계정으로 로그인할 수 있습니다.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('로그아웃')),
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
        UserRole.director => _DirectorHomeView(userEmail: user.email ?? ''),
        UserRole.admin    => _LeaderHomeView(userEmail: user.email ?? ''),
        UserRole.participant => _AttendeeHomeView(uuidController: _uuidController),
      },
    );
  }

  /// 로그인한 이메일이 지부장 이메일과 일치하는지 확인
  Future<void> _checkLeaderEmail(String email) async {
    try {
      final data = await loadUbfChapters();
      final matches = findLeaderByEmail(data, email);
      if (matches.isEmpty || !mounted) return;

      // 매칭된 챕터 정보로 다이얼로그 표시
      final match = matches.first;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('지부장 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '로그인하신 이메일($email)이 다음 챕터의 지부장으로 등록되어 있습니다:',
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('대륙: ${match.continent}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('국가: ${match.nation}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('챕터: ${match.chapterName}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('지부장(리더)으로 등록하시겠습니까?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('아니오, 참가자로 계속'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('예, 리더로 등록'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        // 리더 등록 화면으로 이동
        context.push('/become-leader');
      }
    } catch (_) {
      // JSON 로드 실패 시 무시 — 참가자로 계속 진행
    }
  }
}

// ─── Director 홈 화면 ────────────────────────────────────────
class _DirectorHomeView extends ConsumerWidget {
  final String userEmail;

  const _DirectorHomeView({required this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
                          'Director 모드',
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
          Text('관리 메뉴', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.add_circle_outline,
            title: '새 프로그램 생성',
            subtitle: 'UUID를 생성하고 프로그램을 설정합니다',
            color: theme.colorScheme.primary,
            onTap: () => context.push('/leader/create-program'),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.list_alt,
            title: '내 프로그램 목록',
            subtitle: '생성한 프로그램을 관리합니다',
            color: Colors.green,
            onTap: () => context.push('/leader/programs'),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.admin_panel_settings,
            title: '관리자 배정',
            subtitle: '프로그램별 admin을 지정합니다',
            color: Colors.deepPurple,
            onTap: () => context.push('/director/assign-admins'),
          ),
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
                    'Director는 모든 프로그램을 관리하고 admin을 지정할 수 있습니다.',
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

  const _LeaderHomeView({required this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
                          '관리자(Admin) 모드',
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
          Text('관리 메뉴', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.add_circle_outline,
            title: '새 프로그램 생성',
            subtitle: 'UUID를 생성하고 프로그램을 설정합니다',
            color: theme.colorScheme.primary,
            onTap: () => context.push('/leader/create-program'),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.list_alt,
            title: '내 프로그램 목록',
            subtitle: '담당 프로그램을 관리합니다',
            color: Colors.green,
            onTap: () => context.push('/leader/programs'),
          ),
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
                    '프로그램 생성 후 UUID를 참가자들에게 공유하세요.',
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

  const _AttendeeHomeView({required this.uuidController});

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
        _recentPrograms = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _removeRecent(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    _recentPrograms.removeWhere((e) => e['uuid'] == uuid);
    await prefs.setString(AppConstants.recentProgramsKey, jsonEncode(_recentPrograms));
    setState(() {});
  }

  void _join(BuildContext context, String uuid) {
    if (uuid.isEmpty) return;
    context.push('/registration/$uuid');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            '프로그램 참가',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '리더에게 받은 UUID를 입력하여 프로그램에 참가하세요.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: widget.uuidController,
            decoration: const InputDecoration(
              labelText: '프로그램 UUID',
              hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _join(context, widget.uuidController.text.trim()),
              child: const Text('참가하기'),
            ),
          ),

          // ── 최근 참가 프로그램 ──────────────────────────
          if (_recentPrograms.isNotEmpty) ...[
            const SizedBox(height: 36),
            Text('최근 참가한 프로그램', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...(_recentPrograms.map((prog) {
              final uuid = prog['uuid'] as String;
              final name = prog['name'] as String? ?? uuid;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    uuid,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: '목록에서 제거',
                    onPressed: () => _removeRecent(uuid),
                  ),
                  onTap: () => _join(context, uuid),
                ),
              );
            })),
          ],

          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () => context.push('/become-leader'),
              child: const Text('리더이신가요? 리더로 전환하기'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
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
