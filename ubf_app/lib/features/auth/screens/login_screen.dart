import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/widgets/language_picker.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  int _logoTapCount = 0;
  bool _showDevLogin = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e, st) {
      debugPrint('[AUTH] 구글 오류: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.authGoogleFailed('$e')),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInDev() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInDev();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.authDevFailed('$e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        // 화면이 낮으면 스크롤된다.
        //
        // 예전에는 Column 하나뿐이라 폰을 가로로 눕히면 내용이 화면보다
        // 길어지는데 움직일 수가 없었다 — 로그인 단추가 화면 밖으로 나가
        // 들어올 길이 막혔다. 세로에서는 지금 그대로 가운데에 놓인다:
        // 높이가 남으면 minHeight 가 화면을 채우고 Spacer 가 살아 있다.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // 로그인 전에도 언어를 바꿀 수 있어야 한다 — 읽을 수 없는 언어로
                      // 이 화면이 떠 있으면 진입 자체가 막힌다.
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageButton(),
                      ),
                      const Spacer(flex: 2),
                      // 로고 영역 (5번 탭하면 테스트 로그인 표시)
                      GestureDetector(
                        onTap: () {
                          final next = _logoTapCount + 1;
                          if (next >= 5) {
                            setState(() {
                              _logoTapCount = 0;
                              _showDevLogin = true;
                            });
                          } else {
                            setState(() => _logoTapCount = next);
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.church,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Mana',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.appTagline,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(flex: 2),
                      // 구글 로그인 버튼
                      _isLoading
                          ? const CircularProgressIndicator()
                          : OutlinedButton.icon(
                              onPressed: _signInWithGoogle,
                              icon: Image.network(
                                'https://www.google.com/favicon.ico',
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.login),
                              ),
                              label: Text(
                                l10n.authSignInGoogle,
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                      if (_showDevLogin) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInDev,
                          icon: const Icon(Icons.developer_mode, size: 18),
                          label: Text(l10n.authSignInDev),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: Colors.grey[600],
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        l10n.authTermsNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
