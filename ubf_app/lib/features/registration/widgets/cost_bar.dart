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
      // 돌아가는 비행기를 안 적었으면 전후 숙박비를 아직 셀 수 없다(066).
      lodgingNeedsFlight: RegistrationCost.lodgingPendingFlight(
        hostCountry: program['host_country'] as String?,
        country: form.country,
        departureFlight: form.departureFlight,
      ),
    );

    // 아직 아무것도 안 정했으면 자리만 차지한다. 첫 화면에서 U$ 0 을 띄우면
    // 참가비가 없는 수양회처럼 보인다.
    if (cost.isEmpty) return const SizedBox.shrink();

    // 따로 쓸 돈. 예전에는 아래에 문장으로 적었는데, 금액 하나만 크게
    // 떠 있고 그 밑에 긴 문장이 붙으니 "그래서 결국 얼마인가" 가 한눈에
    // 안 들어왔다. 이제 **금액 옆에 붙여 적는다** — "U$ 295 ＋ 약 U$ 30".
    //
    // 그래도 **합치지는 않는다.** 두 숫자가 따로 보여야 하나는 우리에게
    // 내는 돈이고 하나는 예상이라는 것이 읽힌다.
    final hasExtra = cost.extrasKnown > 0 || cost.extrasUnsure;
    final plusText = cost.extrasKnown > 0
        ? l10n.costBarPlus(currency.format(cost.extrasKnown))
        : null;

    // 그 돈이 무엇인지 한 낱말씩. 금액이 미정인 것도 종류에는 들어간다.
    final kindWords = [
      for (final k in cost.extraKinds)
        switch (k) {
          ExtraKind.meals => l10n.costBarExtraKindMeals,
          ExtraKind.lodging => l10n.costBarExtraKindLodging,
          ExtraKind.airfare => l10n.costBarExtraKindAirfare,
        },
    ];
    final extraNote = hasExtra
        ? (kindWords.isEmpty
              ? l10n.costBarExtraNote(l10n.costBarExtraKindOther)
              : l10n.costBarExtraNote(kindWords.join(' · ')))
        : null;

    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.30),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      l10n.costBarDue,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 이 줄을 보러 오는 것이므로 크게 적는다.
                  Text(
                    // 숙박 단가를 범위로 적어 둔 곳이면 범위로 적는다(066).
                    // 명단에 남는 것은 낮은 쪽이지만, 참가자에게는 얼마까지
                    // 들 수 있는지를 말해 주어야 한다.
                    cost.dueIsRange
                        ? l10n.costBarRange(
                            currency.format(cost.due),
                            currency.format(cost.dueMax),
                          )
                        : currency.format(cost.due),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (plusText != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      plusText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              // 낼 돈에 아직 못 넣은 것(064) — 묵을 밤은 있는데 숙박 등급을
              // 안 골랐다. 숫자만 보여주면 숙박이 공짜인 줄 알고, 나중에
              // 늘어난 금액에 놀란다.
              if (cost.lodgingNeedsFlight)
                Text(
                  l10n.costBarLodgingNeedsFlight,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else if (cost.dueUnsure)
                Text(
                  l10n.costBarLodgingPending,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (extraNote != null)
                Text(
                  // 금액을 하나도 모르면 "＋ 약 얼마" 를 못 적으므로,
                  // 이 줄이 더 든다는 사실 자체를 맡는다.
                  plusText == null
                      ? '${l10n.summaryPlusUnknownOnly} · $extraNote'
                      : extraNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
