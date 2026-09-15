import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/registration_cost.dart';
import '../../../core/utils/tour_extras.dart';
import '../providers/registration_provider.dart';

/// 등록 내내 따라다니는 비용 막대 (064)
///
/// 순서를 바꿔 참가비를 첫 화면으로 올렸지만, 그것만으로는 "1번에서 봤다" 로
/// 끝난다. 여덟 번째 화면에서 투어를 하나 더 고를 때 지금까지 얼마가 됐는지는
/// 여전히 안 보인다. 그래서 막대를 모든 화면 아래에 붙인다.
///
/// **두 줄을 절대 합치지 않는다.** 위는 우리에게 내는 돈, 아래는 참가자가
/// 따로 쓸 돈이고 그것은 예상이다. 합치면 확정된 청구서처럼 보이고,
/// 빼면 돈을 덜 챙겨 온다. 셈은 [RegistrationCost] 한 곳에서 한다 —
/// 확인 화면과 같은 숫자여야 한다.
class CostBar extends ConsumerWidget {
  final String programId;
  final Map<String, dynamic> program;
  final Currency currency;

  const CostBar({
    super.key,
    required this.programId,
    required this.program,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final form = ref.watch(registrationFormProvider(programId));
    final saved = ref.watch(registrationProvider(programId)).valueOrNull;

    final cost = RegistrationCost.of(
      program: program,
      feeTier: form.feeTier,
      selectedOptionIds: form.selectedOptions,
      hotelOptionKey: form.hotelOptionKey,
      hotelNightsBefore: form.hotelNightsBefore,
      hotelNightsAfter: form.hotelNightsAfter,
      savedDiscountStatus: saved?['discount_status'] as String?,
      savedDiscountAmount: saved?['discount_amount'],
    );

    // 아직 아무것도 안 정했으면 자리만 차지한다. 첫 화면에서 U$ 0 을 띄우면
    // 참가비가 없는 수양회처럼 보인다.
    if (cost.isEmpty) return const SizedBox.shrink();

    // 따로 쓸 돈 한 줄. 아는 것과 모르는 것이 섞이므로 네 갈래다(061).
    final extrasLine = switch (extrasLineOf(
      known: cost.extrasKnown,
      unsure: cost.extrasUnsure,
    )) {
      ExtrasLine.none => null,
      ExtrasLine.known => l10n.summaryPlusEstimated(
        currency.format(cost.extrasKnown),
      ),
      ExtrasLine.knownAndUnsure => l10n.summaryPlusEstimatedSome(
        currency.format(cost.extrasKnown),
      ),
      ExtrasLine.unsureOnly => l10n.summaryPlusUnknownOnly,
    };

    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.30),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.costBarDue,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    currency.format(cost.due),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (extrasLine != null) ...[
                const SizedBox(height: 2),
                Text(
                  extrasLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
