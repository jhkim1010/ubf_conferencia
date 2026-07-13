import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mana/l10n/app_localizations.dart';

// 프로그램 생성 완료 - UUID 공유 화면
class ProgramCreatedScreen extends StatelessWidget {
  final String programId;

  const ProgramCreatedScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pcTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green[600], size: 60),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.pcHeading,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pcShareUuid,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // UUID 표시
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'UUID',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      programId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(l10n.pcCopy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: programId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.pcCopied)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.pcInfo,
                        style: TextStyle(color: Colors.blue[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // 대시보드로 이동
              ElevatedButton(
                onPressed: () => context.go('/leader/program/$programId/dashboard'),
                child: Text(l10n.pcGoDashboard),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.pcGoHome),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
