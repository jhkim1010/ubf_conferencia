import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/api_client.dart';
import '../../../l10n/app_localizations.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _regionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 구글/카카오에서 받은 이름을 기본값으로 설정
    _nameController.text = ref.read(currentUserProvider).name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final age = int.tryParse(_ageController.text.trim());
    if (age == null) return;

    setState(() => _isLoading = true);
    try {
      await ApiClient.updateProfile(
        name: _nameController.text.trim(),
        age: age,
        region: _regionController.text.trim(),
      );
      // 상태 갱신 — profileCompleted=true로 업데이트되면 라우터가 /home으로 이동
      ref.read(authProvider.notifier).markProfileCompleted(
        name: _nameController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileSaveFailed('$e'))),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            children: [
              const SizedBox(height: 16),
              // 헤더
              Icon(Icons.person_pin, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.profileTitle,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profileSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 로그인 계정 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      user.email ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 이름
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.profileNameLabel,
                  hintText: l10n.profileNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.profileNameRequired : null,
              ),
              const SizedBox(height: 16),

              // 나이
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.profileAgeLabel,
                  hintText: l10n.profileAgeHint,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 120) return l10n.profileAgeInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 거주 지역
              TextFormField(
                controller: _regionController,
                decoration: InputDecoration(
                  labelText: l10n.profileRegionLabel,
                  hintText: l10n.profileRegionHint,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.profileRegionRequired : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.profileSaveStart, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
