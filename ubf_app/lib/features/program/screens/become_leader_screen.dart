import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/api_client.dart';

class BecomeLeaderScreen extends ConsumerStatefulWidget {
  const BecomeLeaderScreen({super.key});

  @override
  ConsumerState<BecomeLeaderScreen> createState() => _BecomeLeaderScreenState();
}

class _BecomeLeaderScreenState extends ConsumerState<BecomeLeaderScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 이름 기본값으로 구글/카카오 이름 사용
    final user = ref.read(currentUserProvider);
    _nameController.text = user.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력하세요')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final leaderId = await ApiClient.registerAsLeader(name);
      ref.read(authProvider.notifier).setLeader(leaderId);

      if (!mounted) return;
      // 리더 등록 완료 → 바로 프로그램 생성 화면으로
      context.pushReplacement('/leader/create-program');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리더 등록 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('리더 등록')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '리더로 등록하면 수양회 프로그램을 생성하고 참가자를 관리할 수 있습니다.',
                        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 로그인 정보 표시
            Text('로그인 계정', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              user.email ?? '-',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            // 리더 이름 입력
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '리더 이름 *',
                hintText: '참가자들에게 보여질 이름',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _register(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _register,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_forward),
                label: const Text('리더 등록 후 이벤트 생성하기'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
