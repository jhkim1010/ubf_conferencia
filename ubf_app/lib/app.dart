import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/utils/join_link.dart';
import 'core/utils/join_query_cleanup.dart';
import 'l10n/app_localizations.dart';
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
import 'features/dashboard/screens/readiness_screen.dart';
import 'features/dashboard/screens/meal_restrictions_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/dashboard/screens/discounts_screen.dart';
import 'features/schedule/screens/schedule_screen.dart';
import 'features/sos/screens/sos_screen.dart';
import 'features/program/screens/immigration_card_screen.dart';
import 'features/program/screens/edit_program_screen.dart';
import 'features/program/screens/my_programs_screen.dart';
import 'features/setup/screens/setup_screen.dart';
import 'features/assignment/screens/assignment_screen.dart';
import 'features/transport/screens/dispatch_screen.dart';
import 'features/transport/screens/my_transport_screen.dart';

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
        // 초대 링크(?program=<uuid>)로 들어왔으면 목적지를 기억해 둔다.
        //
        // **인증 검사보다 먼저 본다.** 처음 오는 사람은 반드시 로그인과
        // 프로필 입력을 지나가는데, 그 사이에 주소가 갈아치워지므로
        // 여기서 붙잡지 않으면 목적지를 잃고 결국 UUID 를 손으로 묻게 된다.
        final fromLink = programIdFromQuery(state.uri.queryParameters);
        if (fromLink != null) PendingJoin.remember(fromLink);

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

        // 준비가 끝났으면 기억해 둔 수양회로 곧장 보낸다.
        // take() 는 꺼내면서 지운다 — 남겨 두면 이후에 홈으로 가려 할 때마다
        // 등록 화면으로 끌려간다.
        if (PendingJoin.isPending) {
          final id = PendingJoin.take();
          if (id != null) {
            // 다 썼으니 주소에서도 지운다. 남겨 두면 새로고침할 때마다
            // 여기로 다시 끌려온다(웹은 해시 전략이라 쿼리가 계속 남는다).
            clearJoinQuery();
            return '/registration/$id';
          }
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
          builder: (_, _) =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/profile-setup',
          builder: (_, _) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/become-leader',
          builder: (_, _) => const BecomeLeaderScreen(),
        ),
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/leader/create-program',
          builder: (_, _) => const CreateProgramScreen(),
        ),
        GoRoute(
          path: '/leader/programs',
          builder: (_, _) => const MyProgramsScreen(),
        ),
        GoRoute(
          path: '/leader/program/:id/created',
          builder: (_, s) =>
              ProgramCreatedScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/dashboard',
          builder: (_, s) =>
              DashboardScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/readiness',
          builder: (_, s) =>
              ReadinessScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/meals',
          builder: (_, s) =>
              MealRestrictionsScreen(programId: s.pathParameters['id']!),
        ),
        // 자료실. 담당자용(관리 가능)과 참가자용(보기)을 경로로 나눈다 —
        // 화면은 하나지만 권한이 다르고, 참가자에게 관리 버튼이 보이면 안 된다.
        GoRoute(
          path: '/leader/program/:id/library',
          builder: (_, s) =>
              LibraryScreen(programId: s.pathParameters['id']!, isAdmin: true),
        ),
        GoRoute(
          path: '/program/:id/library',
          builder: (_, s) => LibraryScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/discounts',
          builder: (_, s) =>
              DiscountsScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/edit',
          builder: (_, s) =>
              EditProgramScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/setup',
          builder: (_, s) => SetupScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/assign',
          builder: (_, s) =>
              AssignmentScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/leader/program/:id/dispatch',
          builder: (_, s) => DispatchScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/program/:id/my-transport',
          builder: (_, s) =>
              MyTransportScreen(programId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/registration/:id',
          builder: (_, s) =>
              RegistrationFlowScreen(programId: s.pathParameters['id']!),
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
          builder: (_, s) =>
              SosScreen(programId: s.pathParameters['programId']!),
        ),
        GoRoute(
          path: '/program/:id/immigration',
          builder: (_, s) =>
              ImmigrationCardScreen(programId: s.pathParameters['id']!),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 인증 상태 변화 시 라우터 리다이렉트 재평가
    ref.listen<AuthState>(authProvider, (_, _) => _router.refresh());

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // 앱 안에서 고른 언어(A002). null 이면 아래 localeResolutionCallback 이
      // 기존대로 기기 언어를 따른다 — 한 번도 고르지 않은 사용자는 종전과 동일하다.
      locale: ref.watch(localeProvider),
      // locale 미지정 → 기기 언어를 따른다. 지원(ko/en/es) 언어면 그 언어,
      // 그 외에는 영어로 폴백.
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale != null) {
          for (final l in supported) {
            if (l.languageCode == deviceLocale.languageCode) return l;
          }
        }
        return const Locale('en');
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
