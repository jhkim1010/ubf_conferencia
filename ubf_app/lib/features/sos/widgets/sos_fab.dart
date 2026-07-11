import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('긴급 SOS'),
          ],
        ),
        content: const Text('관리자에게 긴급 알림을 전송하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
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
            child: const Text('SOS 전송'),
          ),
        ],
      ),
    );
  }
}
