import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/venue_link.dart';
import 'fee_section.dart';

/// 등록의 첫 화면 (064)
///
/// 참석할지 말지를 가르는 것은 **기간과 값** 두 가지다. 예전에는 그 둘이
/// 마지막에 있었다 — 참가비가 열한 번째 화면이었고, 기간은 어디에도 없었다.
/// 그래서 참가자는 비행기 날짜를 적고 투어까지 고른 뒤에야 수양회가 얼마인지
/// 알았고, "그럼 지금까지 적은 건 뭔가" 가 됐다.
///
/// 이제 정할 것을 먼저 정하고 나머지를 채운다.
///
/// **이 화면은 언제나 넣는다.** 참가비를 정해 두지 않은 수양회에서는 값 구역만
/// 빠지고 기간·장소는 남는다. 값이 없을 때 이 화면을 통째로 빼면 첫 스텝이
/// 조건부가 되는데, 스텝 목록은 "조건부는 맨 뒤에 붙인다 — 인덱스가 밀리지
/// 않게" 로 조립돼 있어서 그 규칙이 깨진다.
class OverviewStep extends ConsumerWidget {
  final String programId;
  final Map<String, dynamic> program;
  final Currency currency;

  /// 개최 국가(ISO). 할인 자격 판정에 쓴다.
  final String? hostCountry;

  const OverviewStep({
    super.key,
    required this.programId,
    required this.program,
    required this.currency,
    required this.hostCountry,
  });

  static String _ymd(Object? v) {
    final s = '${v ?? ''}';
    if (s.isEmpty) return '';
    return s.length >= 10 ? s.substring(0, 10).replaceAll('-', '.') : s;
  }

  /// 수양회가 며칠인가. 날짜를 못 읽으면 null — 0 으로 두면 당일치기로 보인다.
  static int? _nights(Object? start, Object? end) {
    final a = DateTime.tryParse('${start ?? ''}');
    final b = DateTime.tryParse('${end ?? ''}');
    if (a == null || b == null) return null;
    final n = b.difference(a).inDays;
    return n > 0 ? n : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final start = _ymd(program['start_date']);
    final end = _ymd(program['end_date']);
    final nights = _nights(program['start_date'], program['end_date']);
    final period = end.isEmpty || end == start ? start : '$start → $end';

    final feeBasic = Money.parse(program['fee_basic']);
    final feePremium = Money.parse(program['fee_premium']);
    final hasFee = feeBasic != null || feePremium != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.ovTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          l10n.ovSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 18),

        // ── 기간 · 장소 ───────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (period.isNotEmpty)
                _Fact(
                  label: l10n.summaryPeriod,
                  value: period,
                  sub: nights == null ? null : l10n.ovNights(nights),
                ),
              if (period.isNotEmpty && (program['location'] != null))
                Divider(height: 1, color: Colors.grey[200]),
              if (program['location'] != null)
                _Fact(
                  label: l10n.summaryLocation,
                  value: '${program['location']}',
                  // 장소 홈페이지(065). 못 여는 주소면 null 이고, 그때는
                  // 그냥 글자로 남는다 — 누를 것이 없는데 누를 수 있어
                  // 보이면 안 된다.
                  link: VenueLink.parse(program['venue_url']),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── 참가비 · 할인 ─────────────────────────────
        if (hasFee)
          FeeSection(
            programId: programId,
            feeBasic: feeBasic,
            feePremium: feePremium,
            feeBasicDesc: program['fee_basic_desc'] as String?,
            feePremiumDesc: program['fee_premium_desc'] as String?,
            discountOptions: List<Map<String, dynamic>>.from(
              program['discount_options'] as List? ?? const [],
            ),
            currency: currency,
            hostCountry: hostCountry,
          )
        else
          Text(
            l10n.feeNotSet,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  /// 있으면 이 줄 전체가 눌린다(065).
  final VenueLink? link;

  const _Fact({required this.label, required this.value, this.sub, this.link});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 날짜와 장소는 본문보다 두 배로 키운다. 이 화면에서 사람이
                // 실제로 읽는 것이 이 둘과 아래의 참가비 설명이고, 나머지는
                // 곁다리다. 작게 두면 읽지 않고 넘어간다.
                Text.rich(
                  TextSpan(
                    text: value,
                    children: link == null
                        ? null
                        // 누를 수 있다는 것을 화살표로 알린다. 밑줄은 글씨가
                        // 커서 오히려 읽기를 방해한다.
                        : const [TextSpan(text: '  ↗')],
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * 2,
                    height: 1.2,
                    color: link == null ? null : theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.end,
                ),
                // 누르기 전에 어디로 가는지 알 수 있어야 한다. 주소 전체를
                // 적으면 장소 이름을 가리므로 도메인만 적는다.
                if (link != null)
                  Text(
                    link!.host,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                if (sub != null)
                  Text(
                    sub!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (link == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // 기기의 브라우저로 연다. 투어 브로슈어와 같은 방식이라
        // 등록하던 자리를 잃지 않는다.
        onTap: () => launchUrl(link!.uri, mode: LaunchMode.externalApplication),
        child: row,
      ),
    );
  }
}
