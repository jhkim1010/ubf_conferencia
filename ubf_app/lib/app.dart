import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/profile_setup_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/program/screens/become_leader_screen.dart';
import 'features/program/screens/create_program_screen.dart';
import 'features/program/screens/program_created_screen.dart';
import 'features/registration/screens/registration_flow_screen.dart';
import 'features/registration/screens/summary_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/schedule/screens/schedule_screen.dart';
import 'features/sos/screens/sos_screen.dart';
import 'features/program/screens/immigration_card_screen.dart';
import 'features/program/screens/edit_program_screen.dart';

class UbfApp extends ConsumerStatefulWidget {
  const UbfApp({super.key});

  @override
  ConsumerState<UbfApp> createState() => _UbfAppState();
}

class _UbfAppState extends ConsumerState<UbfApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/home',
      redirect: (_, state) {
        final auth = ref.read(authProvider);
        if (auth.isLoading) return '/loading';

        final loc = state.matchedLocation;

        // 비로그인 → 로그인 화면
        if (!auth.isLoggedIn) {
          return loc == '/login' ? null : '/login';
        }

        // 로그인 + 프로필 미완성 → 프로필 입력 화면
        if (!auth.profileCompleted) {
          return loc == '/profile-setup' ? null : '/profile-setup';
        }

        // 로그인 + 프로필 완료 → 불필요한 화면에서 홈으로
        if (loc == '/login' || loc == '/profile-setup' || loc == '/loading') {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/loading',
          builder: (_, _) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/profile-setup', builder: (_, _) => const ProfileSetupScreen()),
        GoRoute(path: '/become-leader', builder: (_, _) => const BecomeLeaderScreen()),
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/leader/create-program',
          builder: (_, _) => const CreateProgramScreen(),
        ),
        GoRoute(
          path: '/leader/program/:id/created',
          builder: (_, s) => ProgramCreatedScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/dashboard',
          builder: (_, s) => DashboardScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/edit',
          builder: (_, s) => EditProgramScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/registration/:id',
          builder: (_, s) => RegistrationFlowScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/registration/:id/summary',
          builder: (_, s) => SummaryScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/program/:id/schedule',
          builder: (_, s) => ScheduleScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/sos/:programId',
          builder: (_, s) => SosScreen(programId: s.pathParameters['programId']!),
        ),
        GoRoute(
          path: '/program/:id/immigration',
          builder: (_, s) => ImmigrationCardScreen(programId: s.pathParameters['id']!),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 인증 상태 변화 시 라우터 리다이렉트 재평가
    ref.listen<AuthState>(authProvider, (_, _) => _router.refresh());

    return MaterialApp.router(
      title: 'Mana',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('es'),
      ],
      locale: const Locale('ko'),
      debugShowCheckedModeBanner: false,
    );
  }
}
