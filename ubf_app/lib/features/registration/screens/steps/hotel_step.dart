import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../../core/utils/money.dart';
import '../../providers/registration_provider.dart';

// 수양회 전후 숙박(028)
//
// 멀리서 오는 사람은 수양회 며칠 전에 도착하고, 투어가 끝난 뒤에도 며칠 더
// 머문다. 그 기간의 숙소는 수양회 숙소가 아니라 호텔이다.
//
// **이 단계는 외국에서 오는 사람에게만 보인다**(등록 흐름에서 판단).
// 개최국 참가자는 전후에 집으로 가므로 물어볼 것이 없다.
//
// 박수를 등급과 함께 받는 이유: 호텔 예약은 날짜 단위다. 등급만 알고는 방을
// 잡을 수 없다. 전/후를 나눠 받는 이유도 같다 — 합계만으로는 언제 자는지
// 알 수 없다.
class HotelStep extends ConsumerWidget {
  final String programId;
  final List<Map<String, dynamic>> options;
  final Currency currency;

  const HotelStep({
    super.key,
    required this.programId,
    required this.options,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final form = ref.watch(registrationFormProvider(programId));
    final notifier = ref.read(registrationFormProvider(programId).notifier);

    final picked = options.cast<Map<String, dynamic>?>().firstWhere(
      (o) => o?['key'] == form.hotelOptionKey,
      orElse: () => null,
    );
    final nights = form.hotelNightsBefore + form.hotelNightsAfter;
    final perNight = Money.parse(picked?['pricePerNight']);
    final estimate = perNight != null && nights > 0 ? perNight * nights : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.hotel_outlined, size: 44, color: theme.colorScheme.primary),
        const SizedBox(height: 14),
        Text(
          l10n.hotelTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.hotelBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // 주최 측이 아직 등급을 안 정했을 수 있다. 빈 화면 대신 그렇게 말한다.
        if (options.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.hotelNoOptions,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          )
        else ...[
          for (final o in options)
            _TierCard(
              label: optionLabelFor(o, lang),
              // 단가를 아직 못 정한 등급이 있다. 0 으로 보여주면 공짜인 줄 안다.
              price: Money.parse(o['pricePerNight']) == null
                  ? l10n.hotelPriceTbd
                  : l10n.hotelPerNight(
                      currency.format(Money.parse(o['pricePerNight'])!),
                    ),
              selected: form.hotelOptionKey == o['key'],
              onTap: () => notifier.selectHotelOption(o['key'] as String),
            ),
          _TierCard(
            label: l10n.hotelNone,
            price: '',
            selected: form.hotelOptionKey == null,
            onTap: notifier.clearHotelChoice,
          ),

          // 등급을 고르기 전에는 박수를 묻지 않는다. 고르지 않은 채 박수만
          // 남으면 서버가 그 박수를 떨어뜨려, 적은 값이 조용히 사라진다.
          if (form.hotelOptionKey != null) ...[
            const SizedBox(height: 18),
            _NightsRow(
              label: l10n.hotelNightsBefore,
              value: form.hotelNightsBefore,
              onChanged: (v) => notifier.setHotelNights(before: v),
            ),
            const SizedBox(height: 8),
            _NightsRow(
              label: l10n.hotelNightsAfter,
              value: form.hotelNightsAfter,
              onChanged: (v) => notifier.setHotelNights(after: v),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.hotelEstimate)),
                  Text(
                    estimate != null
                        ? currency.format(estimate)
                        : l10n.hotelPriceTbd,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 참가비와 섞이지 않는다는 사실을 분명히 적는다. 총액에 포함된
            // 줄 알고 입금하면 호텔 값을 두 번 내거나 아예 안 내게 된다.
            Text(
              l10n.hotelNotInFee,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final String label;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const _TierCard({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? theme.colorScheme.primary : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? theme.colorScheme.primary : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (price.isNotEmpty)
                  Text(
                    price,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 박수 입력. 키보드 대신 +/- 로 받는다 — 손가락으로 숫자를 지웠다 쓰는 것보다
// 빠르고, 음수·오타가 아예 들어오지 않는다.
class _NightsRow extends StatelessWidget {
  static const _max = 60; // services/hotel.js MAX_NIGHTS 와 맞춘다

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _NightsRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: l10n.actionPrevious,
        ),
        SizedBox(
          width: 52,
          child: Text(
            l10n.hotelNightsCount(value),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          onPressed: value < _max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          tooltip: l10n.actionNext,
        ),
      ],
    );
  }
}
