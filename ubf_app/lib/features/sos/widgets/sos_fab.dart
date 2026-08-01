import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../program/providers/program_provider.dart';

/// 수양회 기간에만 나타나는 SOS 버튼.
///
/// 등록은 보통 몇 달 전에 한다. 그때는 SOS 를 누를 일이 없는데 버튼이 계속 떠서
/// 입력 화면을 가렸다. 그래서 **수양회가 시작한 뒤에만** 보여준다.
///
/// 끝난 뒤에도 하루는 남겨 둔다 — 귀국길에 생기는 일이 있고, 종료 당일 밤에
/// 버튼이 사라지면 그때가 가장 필요한 순간일 수 있다.
///
/// 날짜를 모르면(시작일 미설정) 보여주지 않는다. 언제인지 알 수 없는 채로
/// 화면을 가리는 쪽이 더 나쁘다.
///
/// 표시 여부를 호출하는 화면마다 계산하지 않고 여기서 정한다. 새 화면에
/// 이 위젯을 붙이면 같은 규칙이 그대로 따라온다.
class SosFab extends ConsumerWidget {
  final String programId;

  const SosFab({super.key, required this.programId});

  /// 지금이 수양회 기간 안인가.
  ///
  /// 서버가 주는 값은 '2027-02-10T03:00:00.000Z' 같은 타임스탬프다. 앞 10자만
  /// 잘라 날짜로 본다 — DateTime.parse 로 UTC→로컬 변환을 하면 시차 때문에
  /// 시작일이 하루 당겨지거나 밀린다.
  static bool isActive(Object? startRaw, Object? endRaw, {DateTime? now}) {
    final start = _date(startRaw);
    if (start == null) return false;

    final today = now ?? DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    if (t.isBefore(start)) return false;

    // 종료일 다음 날까지. 종료일이 없으면 시작일을 기준으로 삼는다.
    final end = _date(endRaw) ?? start;
    return !t.isAfter(end.add(const Duration(days: 1)));
  }

  static DateTime? _date(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.length < 10) return null;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(5, 7));
    final d = int.tryParse(s.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programByIdProvider(programId)).valueOrNull;
    if (program == null) return const SizedBox.shrink();
    if (!isActive(program['start_date'], program['end_date'])) {
      return const SizedBox.shrink();
    }

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
