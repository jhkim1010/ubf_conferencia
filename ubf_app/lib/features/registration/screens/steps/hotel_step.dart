import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/hotel_nights.dart';
import '../../providers/registration_provider.dart';

// 수양회 전후 숙박(028)
//
// 멀리서 오는 사람은 수양회 며칠 전에 도착하고, 투어가 끝난 뒤에도 며칠 더
// 머문다. 그 기간의 숙소는 수양회 숙소가 아니라 호텔이다.
//
// **이 단계는 외국에서 오는 사람에게만 보인다**(등록 흐름에서 판단).
// 개최국 참가자는 전후에 집으로 가므로 물어볼 것이 없다.
//
// 박수는 백지로 묻지 않는다. 이미 적어 낸 항공편과 수양회·투어 일정에 답이
// 들어 있으므로 계산해서 먼저 알려 주고, 다르면 고치게 한다. 백지로 물으면
// 대부분 틀리게 적는다 — 특히 "도착일 = 첫 숙박일" 을 헷갈린다.
class HotelStep extends ConsumerStatefulWidget {
  final String programId;
  final List<Map<String, dynamic>> options;
  final Currency currency;
  final Object? programStart;
  final Object? programEnd;

  /// 이 수양회의 투어 목록. 참가자가 고른 투어가 수양회보다 늦게 끝나면
  /// 그 뒤부터 호텔이 필요하다.
  final List<Map<String, dynamic>> tours;

  const HotelStep({
    super.key,
    required this.programId,
    required this.options,
    required this.currency,
    required this.programStart,
    required this.programEnd,
    required this.tours,
  });

  @override
  ConsumerState<HotelStep> createState() => _HotelStepState();
}

class _HotelStepState extends ConsumerState<HotelStep> {
  // 자동 계산을 화면당 한 번만 적용한다. 매 build 마다 밀어 넣으면
  // 참가자가 고친 값을 되돌려 버려 숫자를 바꿀 수 없게 된다.
  bool _applied = false;

  HotelNights _compute(RegistrationFormState form) {
    final selected = form.selectedOptions.toSet();
    return computeHotelNights(
      arrival: form.arrivalFlight?['scheduled_arrival'],
      departure: form.departureFlight?['scheduled_departure'],
      programStart: widget.programStart,
      programEnd: widget.programEnd,
      stayEndDates: widget.tours
          .where((t) => selected.contains(t['id']))
          .map((t) => t['endDate'] ?? t['end_date']),
    );
  }

  void _apply(HotelNights n) {
    ref
        .read(registrationFormProvider(widget.programId).notifier)
        .setHotelNights(before: n.beforeOrZero, after: n.afterOrZero);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final form = ref.watch(registrationFormProvider(widget.programId));
    final notifier = ref.read(
      registrationFormProvider(widget.programId).notifier,
    );

    final computed = _compute(form);

    // 아직 아무것도 안 적은 사람에게만 계산값을 넣어 준다. 이미 값이 있으면
    // 본인이 정한 것일 수 있으므로 건드리지 않고 "다시 계산" 버튼만 준다.
    if (!_applied &&
        computed.hasAny &&
        form.hotelNightsBefore == 0 &&
        form.hotelNightsAfter == 0) {
      _applied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(computed);
      });
    }

    final picked = widget.options.cast<Map<String, dynamic>?>().firstWhere(
      (o) => o?['key'] == form.hotelOptionKey,
      orElse: () => null,
    );
    final nights = form.hotelNightsBefore + form.hotelNightsAfter;
    final perNight = Money.parse(picked?['pricePerNight']);
    final estimate = perNight != null && nights > 0 ? perNight * nights : null;

    final differs =
        computed.hasAny &&
        (form.hotelNightsBefore != computed.beforeOrZero ||
            form.hotelNightsAfter != computed.afterOrZero);

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
        const SizedBox(height: 18),

        // 계산 결과를 먼저 말한다. 이것이 이 화면의 요지다.
        _ComputedCard(computed: computed),
        const SizedBox(height: 14),

        _NightsRow(
          label: l10n.hotelNightsBefore,
          value: form.hotelNightsBefore,
          onChanged: (v) => notifier.setHotelNights(before: v),
        ),
        const SizedBox(height: 4),
        _NightsRow(
          label: l10n.hotelNightsAfter,
          value: form.hotelNightsAfter,
          onChanged: (v) => notifier.setHotelNights(after: v),
        ),
        if (differs)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _apply(computed),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.hotelRecalc),
            ),
          ),

        const SizedBox(height: 18),
        Text(
          l10n.hotelPickPrompt,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        // 주최 측이 아직 등급을 안 정했을 수 있다. 빈 화면 대신 그렇게 말한다.
        if (widget.options.isEmpty)
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
          for (final o in widget.options)
            _TierCard(
              label: optionLabelFor(o, lang),
              // 단가를 아직 못 정한 등급이 있다. 0 으로 보여주면 공짜인 줄 안다.
              price: Money.parse(o['pricePerNight']) == null
                  ? l10n.hotelPriceTbd
                  : l10n.hotelPerNight(
                      widget.currency.format(Money.parse(o['pricePerNight'])!),
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

          if (form.hotelOptionKey != null) ...[
            const SizedBox(height: 10),
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
                        ? widget.currency.format(estimate)
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

// 계산 결과 안내. 근거가 없는 방향은 "0 박"이라고 말하지 않는다 —
// 계산이 끝난 줄 알고 그대로 넘어가 버린다.
class _ComputedCard extends StatelessWidget {
  final HotelNights computed;
  const _ComputedCard({required this.computed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final (String text, IconData icon) = switch ((
      computed.before,
      computed.after,
    )) {
      (null, null) => (l10n.hotelNoFlightYet, Icons.flight_outlined),
      (final b?, null) => (l10n.hotelComputedBeforeOnly(b), Icons.info_outline),
      (null, final a?) => (l10n.hotelComputedAfterOnly(a), Icons.info_outline),
      (0, 0) => (l10n.hotelComputedNone, Icons.check_circle_outline),
      (final b?, final a?) => (
        l10n.hotelComputed(b, a),
        Icons.nights_stay_outlined,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (computed.hasAny) ...[
            const SizedBox(height: 6),
            Text(
              l10n.hotelAdjustHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.75,
                ),
              ),
            ),
          ],
        ],
      ),
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
          width: 56,
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
          // 상한은 services/hotel.js MAX_NIGHTS 와 맞춘다.
          onPressed: value < maxHotelNights ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          tooltip: l10n.actionNext,
        ),
      ],
    );
  }
}
