import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mana/l10n/app_localizations.dart';

// 모든 화면에서 재사용 가능한 SOS 플로팅 버튼
class SosFab extends StatelessWidget {
  final String programId;

  const SosFab({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'sos_fab',
      onPressed: () => _confirmSos(context),
      backgroundColor: Colors.red[700],
      foregroundColor: Colors.white,
      icon: const Icon(Icons.emergency),
      label: const Text(
        'SOS',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  // 실수 방지 확인 다이얼로그
  void _confirmSos(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(l10n.sosTitle),
          ],
        ),
        content: Text(l10n.sosFabConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/sos/$programId');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.sosSend),
          ),
        ],
      ),
    );
  }
}
