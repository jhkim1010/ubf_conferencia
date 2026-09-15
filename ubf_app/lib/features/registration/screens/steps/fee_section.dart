import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../providers/registration_provider.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/constants/world_countries.dart';

// 참가비 + 할인 신청 (064)
//
// 예전에는 이것이 등록의 **마지막** 화면이었다. 그래서 참가자는 비행기 날짜를
// 적고 투어까지 고른 뒤에야 수양회 자체가 얼마인지 알았다. 이제 첫 화면
// (OverviewStep) 안으로 들어간다 — 기간과 값을 보고 결정한 다음에 나머지를
// 채우게 하려는 것이다.
//
// 그래서 화면 하나가 아니라 **끼워 넣는 조각**이다. 스스로 스크롤하지 않는다.
//
// 등급을 나란한 카드 둘로 보여주던 것도 바꿨다. 대부분은 기본으로 오므로
// **기본을 크게 펴서 무엇이 들어 있는지 읽히게** 하고, 프리미엄은 그 아래
// 옵션으로 둔다. 둘을 나란히 두면 고르는 일처럼 보여서, 기본에 무엇이
// 들어 있는지는 아무도 안 읽는다.
//
// 할인은 **신청**까지만 여기서 한다. 승인 여부와 확정 금액은 담당자가 정하며
// (서버에서 강제한다), 이 조각은 그 결과를 읽어서 보여주기만 한다.
class FeeSection extends ConsumerStatefulWidget {
  final String programId;
  final num? feeBasic;
  final num? feePremium;
  final String? feeBasicDesc;
  final String? feePremiumDesc;
  final List<Map<String, dynamic>> discountOptions;

  /// 이 수양회의 통화.
  final Currency currency;

  /// 개최 국가(ISO). 지역 수양회는 null 이다.
  ///
  /// 할인은 개최국에서 오는 사람만 신청할 수 있다 — 항목이 "1일만 참석"처럼
  /// 현지에서 오가는 사람을 전제로 만들어지기 때문이다. 서버도 같은 판단으로
  /// 신청을 떨어뜨리지만, 고를 수 있게 두면 신청한 줄 알고 기다리게 된다.
  final String? hostCountry;

  const FeeSection({
    super.key,
    required this.programId,
    required this.feeBasic,
    required this.feePremium,
    required this.feeBasicDesc,
    required this.feePremiumDesc,
    required this.discountOptions,
    required this.currency,
    required this.hostCountry,
  });

  @override
  ConsumerState<FeeSection> createState() => _FeeSectionState();
}

class _FeeSectionState extends ConsumerState<FeeSection> {
  @override
  void initState() {
    super.initState();
    // 기본을 미리 골라 둔다.
    //
    // 이 조각은 이제 기본을 "고르는 것"이 아니라 **받는 값**으로 보여준다.
    // 그러면 아무것도 안 누르고 지나간 사람의 등급이 null 로 남는데, 그러면
    // 합계에서 참가비가 통째로 빠져 우리도 참가자도 덜 받은 숫자를 본다.
    //
    // build 안에서 상태를 고치면 그리는 도중에 고치는 것이라 안 된다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.feeBasic == null) return;
      final form = ref.read(registrationFormProvider(widget.programId));
      if (form.feeTier == null) {
        ref
            .read(registrationFormProvider(widget.programId).notifier)
            .selectFeeTier('basic');
      }
    });
  }

  /// 이 참가자가 할인을 신청할 수 있는가.
  ///
  /// 서버(registrations.js)와 같은 판정이다. 한쪽만 고치면 화면에는 보이는데
  /// 저장 때 조용히 사라지거나, 반대로 못 고르는 항목이 서버에서는 통과한다.
  ///
  /// 양쪽을 ISO 로 정규화한 뒤 비교한다 — 019 이전에 저장된 표시명이 남아
  /// 있을 수 있고, 정규화 없이 문자열을 비교했던 것이 항공편 생략 기능이
  /// 한 번도 동작하지 않은 원인이었다.
  bool _eligible(String? registrantCountry) {
    final host = WorldCountries.isoForLegacy(widget.hostCountry);
    if (host == null) return true; // 지역 수양회 — 모두 같은 나라다
    final mine = WorldCountries.isoForLegacy(registrantCountry);
    return mine != null && mine == host;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final form = ref.watch(registrationFormProvider(widget.programId));
    final notifier = ref.read(
      registrationFormProvider(widget.programId).notifier,
    );

    // 담당자의 판단 결과는 폼 상태가 아니라 서버 값이다.
    final saved = ref.watch(registrationProvider(widget.programId)).valueOrNull;
    final decidedStatus = saved?['discount_status'] as String?;
    final decidedAmount = saved?['discount_amount'];
    final adminNote = saved?['discount_note'] as String?;

    // 값을 하나도 정해 두지 않은 수양회. 첫 화면이 이 조각을 아예 넣지 않지만,
    // 다른 데서 쓰게 될 때를 위해 여기서도 막아 둔다.
    if (widget.feeBasic == null && widget.feePremium == null) {
      return const SizedBox.shrink();
    }

    final premiumOn = form.feeTier == 'premium';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 기본 참가비 ──────────────────────────────
        if (widget.feeBasic != null)
          _BasicFee(
            amount: widget.feeBasic!,
            description: widget.feeBasicDesc,
            currency: widget.currency,
            upgraded: premiumOn,
          ),

        // ── 프리미엄으로 올리기 ───────────────────────
        //
        // 값 자체가 아니라 **차액**을 적는다. 기본 위에 얹는 선택이므로
        // "U$ 300" 보다 "+U$ 100" 이 무엇을 정하는 일인지 바로 말해 준다.
        if (widget.feePremium != null) ...[
          const SizedBox(height: 14),
          _PremiumOption(
            total: widget.feePremium!,
            extra: widget.feeBasic == null
                ? null
                : widget.feePremium! - widget.feeBasic!,
            description: widget.feePremiumDesc,
            currency: widget.currency,
            selected: premiumOn,
            onChanged: (on) => notifier.selectFeeTier(on ? 'premium' : 'basic'),
          ),
        ],

        const SizedBox(height: 28),
        Text(l10n.discountTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),

        if (widget.discountOptions.isEmpty)
          Text(
            l10n.discountNoOptions,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          )
        // 개최국에서 오는 사람이 아니면 항목을 감추고 이유를 밝힌다.
        // 그냥 감추기만 하면 "다른 사람에게는 보이던데 왜 나는 없지" 가 된다.
        else if (!_eligible(form.country))
          _IneligibleNotice(
            hostCountry: widget.hostCountry,
            // 자격을 잃었는데 예전 신청이 남아 있으면 지운다. 화면에서 항목이
            // 사라지므로 본인은 취소할 방법이 없다. 서버도 떨어뜨리지만,
            // 폼에 남겨 두면 요약 화면이 없는 할인을 계속 보여준다.
            staleRequest: form.discountRequested,
            onClearStale: notifier.clearDiscountRequest,
          )
        else ...[
          Text(
            l10n.discountPrompt,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          // 항목을 고르는 것이 곧 신청이다. 별도의 신청 스위치를 두면
          // 항목만 고르고 스위치를 켜지 않아 신청이 사라진다.
          //
          // "신청 안 함"은 빈 문자열 key 로 표현한다. RadioGroup 은 null 을
          // "선택 없음"으로 쓰기 때문에, null 을 항목 값으로 쓰면 선택 자체가
          // 없는 상태와 구별되지 않는다.
          RadioGroup<String>(
            groupValue: form.discountRequested
                ? (form.discountOptionKey ?? '')
                : '',
            onChanged: (v) => v == null || v.isEmpty
                ? notifier.clearDiscountRequest()
                : notifier.selectDiscountOption(v),
            child: Column(
              children: [
                ...widget.discountOptions.map((o) {
                  final amount = Money.parse(o['amount']);
                  return RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: o['key'] as String? ?? '',
                    // 관리자가 언어별로 적은 문구 중 지금 언어의 것.
                    title: Text(
                      discountLabelFor(
                        o,
                        Localizations.localeOf(context).languageCode,
                      ),
                    ),
                    subtitle: amount != null
                        ? Text(
                            '- ${widget.currency.format(amount)}',
                            style: TextStyle(color: theme.colorScheme.primary),
                          )
                        : null,
                  );
                }),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: '',
                  title: Text(l10n.discountNone),
                ),
              ],
            ),
          ),

          if (form.discountRequested) ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: form.discountReason,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.discountReasonLabel,
                hintText: l10n.discountReasonHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: notifier.updateDiscountReason,
            ),
            const SizedBox(height: 12),
            _DecisionBanner(
              status: decidedStatus,
              amount: decidedAmount,
              note: adminNote,
              currency: widget.currency,
            ),
          ],
        ],
      ],
    );
  }
}

// 기본 참가비. 고르는 것이 아니라 **받는 값**이므로 라디오 단추를 두지 않고,
// 무엇이 들어 있는지를 읽을 수 있는 크기로 편다.
class _BasicFee extends StatelessWidget {
  final num amount;
  final String? description;
  final Currency currency;

  /// 프리미엄을 켰는가. 그때는 이 값이 더 이상 낼 금액이 아니므로
  /// 금액에 줄을 긋는다 — 두 숫자가 그냥 나란히 있으면 어느 쪽을 내는지
  /// 알 수 없다.
  final bool upgraded;

  const _BasicFee({
    required this.amount,
    required this.description,
    required this.currency,
    required this.upgraded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feeTierBasic,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            currency.format(amount),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              decoration: upgraded ? TextDecoration.lineThrough : null,
            ),
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            // 이 줄이 이번 변경의 요점이다. 예전에는 13픽셀 회색이라
            // 아무도 안 읽었다.
            Text(
              description!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// 프리미엄으로 올리는 선택. 기본 위에 얹는 것이므로 차액으로 말한다.
class _PremiumOption extends StatelessWidget {
  final num total;
  final num? extra;
  final String? description;
  final Currency currency;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _PremiumOption({
    required this.total,
    required this.extra,
    required this.description,
    required this.currency,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!selected),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.grey[300]!,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (v) => onChanged(v ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      l10n.feeUpgradePremium,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // 차액을 낼 수 있으면 차액으로, 기본값이 없으면 총액으로.
                      extra != null && extra! > 0
                          ? l10n.feeUpgradeExtra(currency.format(extra))
                          : l10n.feeUpgradeTotal(currency.format(total)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 담당자 판단 결과. 아직 저장 전이라 status 가 없으면 아무것도 보여주지 않는다
// (없는 상태를 "대기 중"이라고 하면 신청하지도 않았는데 신청한 것처럼 보인다).
class _DecisionBanner extends StatelessWidget {
  final String? status;
  final Object? amount;
  final String? note;
  final Currency currency;

  const _DecisionBanner({
    required this.status,
    required this.amount,
    required this.note,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (status == null) return const SizedBox.shrink();

    late final String text;
    late final Color color;
    late final IconData icon;
    switch (status) {
      case 'approved':
        final v = Money.parse(amount) ?? 0;
        text = l10n.discountStatusApproved(currency.format(v));
        color = Colors.green[700]!;
        icon = Icons.check_circle_outline;
      case 'rejected':
        text = l10n.discountStatusRejected;
        color = theme.colorScheme.error;
        icon = Icons.cancel_outlined;
      default:
        text = l10n.discountStatusPending;
        color = Colors.orange[800]!;
        icon = Icons.hourglass_empty;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.discountAdminNote(note!),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}

// 할인 자격이 없을 때 보여줄 안내.
//
// 예전 신청이 남아 있으면 조용히 지운다 — 여기서는 항목이 보이지 않으므로
// 본인이 취소할 방법이 없고, 남겨 두면 요약 화면이 없는 할인을 계속 보여준다.
// 서버도 같은 판단으로 떨어뜨리므로(registrations.js) 저장은 막히지 않는다.
class _IneligibleNotice extends StatefulWidget {
  final String? hostCountry;
  final bool staleRequest;
  final VoidCallback onClearStale;

  const _IneligibleNotice({
    required this.hostCountry,
    required this.staleRequest,
    required this.onClearStale,
  });

  @override
  State<_IneligibleNotice> createState() => _IneligibleNoticeState();
}

class _IneligibleNoticeState extends State<_IneligibleNotice> {
  @override
  void initState() {
    super.initState();
    // build 중에 상태를 바꾸면 안 된다. 프레임 뒤로 미룬다.
    if (widget.staleRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onClearStale();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.discountDomesticOnly(
              WorldCountries.display(widget.hostCountry) ?? '',
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
