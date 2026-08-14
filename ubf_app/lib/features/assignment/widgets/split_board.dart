import 'package:flutter/material.dart';

/// 배정 화면의 좌우 두 판.
///
/// 배정은 **두 목록을 견주는 일**이다 — 아직 자리를 못 받은 사람과, 자리마다
/// 누가 들어가 있는지. 한 줄로 쌓아 두면 사람을 보려고 위로, 방을 보려고
/// 아래로 오가야 하고, 스무 명쯤 되면 그 왕복이 배정 그 자체보다 오래 걸린다.
///
/// 폰에는 나눌 너비가 없다. 좁은 화면에서는 예전처럼 쌓는다 — 좁은 화면에서
/// 억지로 나누면 양쪽 다 못 읽는다.
class SplitBoard extends StatelessWidget {
  /// 왼쪽에 세울 것. 대개 "아직 배정 못 받은 사람".
  final Widget left;

  /// 오른쪽 맨 위에 둘 것(자동 배정 버튼 등). 없으면 생략된다.
  final Widget? action;

  /// 오른쪽 본문. 방·조·역할 카드들.
  final List<Widget> right;

  final Future<void> Function() onRefresh;

  /// 좌우로 나누기 시작하는 너비.
  static const double breakpoint = 900;

  const SplitBoard({
    super.key,
    required this.left,
    required this.right,
    required this.onRefresh,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < breakpoint) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (action != null) ...[action!, const SizedBox(height: 12)],
                left,
                const SizedBox(height: 12),
                ...right,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 왼쪽은 고정 폭이다. 비율로 두면 넓은 화면에서 이름 몇 개 때문에
            // 절반이 비어 버린다.
            SizedBox(
              width: box.maxWidth < 1200 ? 320 : 380,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 24),
                children: [left],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 24),
                  children: [
                    if (action != null) ...[
                      action!,
                      const SizedBox(height: 12),
                    ],
                    ...right,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
