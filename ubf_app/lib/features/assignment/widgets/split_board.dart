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

  /// 오른쪽 카드의 어림 높이(대개 그 카드에 든 사람 수). 주면 넓은 화면에서
  /// 두 칸으로 나눠 담는다 — 카드 하나가 한 줄을 통째로 쓰면 스크롤이
  /// 길어진다.
  final List<double>? rightWeights;

  final Future<void> Function() onRefresh;

  /// 좌우로 나누기 시작하는 너비.
  static const double breakpoint = 900;

  const SplitBoard({
    super.key,
    required this.left,
    required this.right,
    required this.onRefresh,
    this.action,
    this.rightWeights,
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
                    if (rightWeights == null)
                      ...right
                    else
                      LayoutBuilder(
                        builder: (context, inner) => MasonryColumns(
                          // 한 칸이 320 아래로 좁아지면 이름 칩이 줄줄이
                          // 접혀 오히려 길어진다.
                          columns: (inner.maxWidth / 320).floor().clamp(1, 2),
                          weights: rightWeights,
                          children: right,
                        ),
                      ),
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

/// 높이가 다른 카드를 여러 칸에 나눠 담는다.
///
/// 방·조·역할 카드는 안에 든 사람 수에 따라 높이가 제각각이다. 격자에
/// 줄을 맞춰 넣으면 그 줄에서 가장 큰 카드에 맞춰 나머지 칸이 비어,
/// 화면의 절반이 빈 채로 남는다. 칸마다 따로 쌓으면 그 빈자리가 없다.
///
/// 어느 칸에 넣을지는 **지금까지 담긴 높이가 가장 낮은 칸** 으로 정한다.
/// 번갈아 넣으면(0,1,0,1…) 한 칸에 큰 카드만 몰리는 일이 생긴다. 높이는
/// 그릴 때까지 알 수 없으므로 [weightOf] 로 어림한다 — 대개 그 카드에 든
/// 사람 수다.
class MasonryColumns extends StatelessWidget {
  final List<Widget> children;

  /// 카드의 어림 높이. 없으면 전부 같다고 본다.
  final List<double>? weights;

  final int columns;
  final double spacing;

  const MasonryColumns({
    super.key,
    required this.children,
    required this.columns,
    this.weights,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (columns <= 1 || children.length <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    final buckets = List.generate(columns, (_) => <Widget>[]);
    final load = List.filled(columns, 0.0);
    for (var i = 0; i < children.length; i++) {
      var pick = 0;
      for (var c = 1; c < columns; c++) {
        if (load[c] < load[pick]) pick = c;
      }
      buckets[pick].add(children[i]);
      load[pick] += (weights != null && i < weights!.length)
          ? weights![i]
          : 1.0;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < buckets[c].length; i++) ...[
                  if (i > 0) SizedBox(height: spacing),
                  buckets[c][i],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
