import 'package:flutter/material.dart';
import 'package:mana/l10n/app_localizations.dart';

// 성경공부 팀 — 소수 인원 처리 방침 (025)
//
// 팀은 **언어로 먼저 갈리고, 그 안에서 연령대로** 나뉜다.
// Adulto 20세 이상 / Junior 19세 이하.
//
// 그러다 보면 "English · Junior 3명" 같은 칸이 생긴다. 자동으로 처리하고 말면
// 관리자는 왜 그렇게 배정됐는지 영영 알 수 없으므로, 미리 정해 두게 한다.
//
// 값은 부모가 소유한다 — 저장 시점에 필요한 것은 부모다.
class CohortPolicySection extends StatelessWidget {
  /// 'absorb' | 'merge' | 'keep'
  final String policy;
  final ValueChanged<String> onPolicyChanged;

  /// 이 인원 미만이면 소수로 본다.
  final int minTeamSize;
  final ValueChanged<int> onMinTeamSizeChanged;

  const CohortPolicySection({
    super.key,
    required this.policy,
    required this.onPolicyChanged,
    required this.minTeamSize,
    required this.onMinTeamSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.cohortSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          l10n.cohortHint,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        // 최소 인원이 먼저다. "몇 명부터 적은 것인가"를 정해야 그 다음
        // "그러면 어떻게 할 것인가"가 의미를 갖는다.
        Row(
          children: [
            Expanded(child: Text(l10n.cohortMinSize)),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: minTeamSize > 1
                  ? () => onMinTeamSizeChanged(minTeamSize - 1)
                  : null,
            ),
            Text(
              '$minTeamSize',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: minTeamSize < 50
                  ? () => onMinTeamSizeChanged(minTeamSize + 1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 4),

        RadioGroup<String>(
          groupValue: policy,
          onChanged: (v) {
            if (v != null) onPolicyChanged(v);
          },
          child: Column(
            children: [
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'keep',
                title: Text(l10n.cohortKeep),
                subtitle: Text(
                  l10n.cohortKeepSub,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'absorb',
                title: Text(l10n.cohortAbsorb),
                subtitle: Text(
                  l10n.cohortAbsorbSub,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'merge',
                title: Text(l10n.cohortMerge),
                subtitle: Text(
                  l10n.cohortMergeSub,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
