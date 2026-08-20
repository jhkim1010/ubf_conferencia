import 'package:flutter/material.dart';
import '../../../../core/utils/tour_extras.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/money.dart';

class OptionsStep extends ConsumerWidget {
  final String programId;
  final List<Map<String, dynamic>> options;
  final bool enabled;

  /// 이 수양회의 통화. 등록자 전원이 같은 단위로 본다.
  final Currency currency;

  const OptionsStep({
    super.key,
    required this.programId,
    required this.options,
    required this.currency,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (!enabled || options.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.optionsNone),
        ),
      );
    }

    final formState = ref.watch(registrationFormProvider(programId));
    final selectedOptions = formState.selectedOptions;

    // 선택된 옵션의 총 비용 계산
    double totalCost = 0;
    for (final option in options) {
      if (selectedOptions.contains(option['id'] as String)) {
        totalCost += (Money.parse(option['cost']) ?? 0).toDouble();
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.optionsSelectPrompt,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ...options.map(
          (option) => _TourCard(
            programId: programId,
            option: option,
            currency: currency,
            isSelected: selectedOptions.contains(option['id'] as String),
          ),
        ),
        if (selectedOptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.optionsSelectedTotal,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currency.format(totalCost),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TourCard extends ConsumerWidget {
  final String programId;
  final Map<String, dynamic> option;
  final Currency currency;
  final bool isSelected;

  const _TourCard({
    required this.programId,
    required this.option,
    required this.currency,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final optionId = option['id'] as String;
    final cost = (Money.parse(option['cost']) ?? 0).toDouble();
    final photoUrls =
        (option['photoUrls'] as List?)?.cast<String>() ?? const <String>[];
    final description = option['description'] as String?;
    final contactName = option['contactName'] as String?;
    final brochureUrl = option['brochureUrl'] as String?;
    final planDocs = (option['planDocs'] as List?) ?? const [];
    final videoUrl = option['videoUrl'] as String?;
    final capacity = Money.parse(option['capacity'])?.toInt();
    final signupCount = Money.parse(option['signupCount'])?.toInt() ?? 0;
    final deadline = option['signupDeadline'] != null
        ? DateTime.tryParse(option['signupDeadline'] as String)
        : null;

    final isFull = capacity != null && signupCount >= capacity;
    final isClosed = deadline != null && deadline.isBefore(DateTime.now());
    // 이미 선택한 항목은 언제나 해제 가능. 새로 선택하는 것만 마감/정원으로 차단.
    final locked = (isFull || isClosed) && !isSelected;

    void toggle() {
      if (locked) return;
      ref
          .read(registrationFormProvider(programId).notifier)
          .toggleOption(optionId);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 사진 갤러리
            if (photoUrls.isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: photoUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      mediaUrl(photoUrls[i]),
                      width: photoUrls.length == 1 ? double.infinity : 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 200,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // 제목 + 비용 + 선택 체크박스
            CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(
                option['name'] as String? ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: (contactName != null && contactName.isNotEmpty)
                  ? Text(l10n.epOptionContact(contactName))
                  : null,
              secondary: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cost == 0
                      ? Colors.green[50]
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cost == 0 ? l10n.optionsFree : currency.format(cost),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cost == 0
                        ? Colors.green[700]
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              value: isSelected,
              onChanged: locked ? null : (_) => toggle(),
            ),
            // 이 투어 값에 무엇이 들었고 무엇이 안 들었는지(061).
            // **고르기 전에** 보여야 한다 — 값만 보고 고른 뒤에 항공권이
            // 따로라는 것을 알면 늦다.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _Coverage(option: option, currency: currency),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description != null && description.isNotEmpty) ...[
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // 계획서·안내 자료 (037). 담당자가 올린 PDF 를 그대로 연다.
                  for (final d in planDocs)
                    if (d is Map && d['url'] is String)
                      _LinkRow(
                        icon: Icons.picture_as_pdf_outlined,
                        label: '${d['name'] ?? ''}'.isEmpty
                            ? l10n.tourPlanOpen
                            : '${d['name']}',
                        url: d['url'] as String,
                      ),
                  // 붙여넣은 홍보물 링크
                  if (brochureUrl != null && brochureUrl.isNotEmpty)
                    _LinkRow(
                      icon: Icons.description_outlined,
                      label: l10n.epBrochureUrl,
                      url: brochureUrl,
                    ),
                  if (videoUrl != null && videoUrl.isNotEmpty)
                    _LinkRow(
                      icon: Icons.ondemand_video_outlined,
                      label: l10n.epVideoUrl,
                      url: videoUrl,
                    ),
                  // 잔여 정원 바
                  if (capacity != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.tourCapacityLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.tourRemaining(
                            (capacity - signupCount).clamp(0, capacity),
                            capacity,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isFull
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: capacity == 0
                            ? 1
                            : (signupCount / capacity).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        color: isFull
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  // 마감일 / 상태 배지
                  if (deadline != null || isFull) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isFull)
                          _StatusChip(
                            text: l10n.tourFull,
                            color: theme.colorScheme.error,
                          )
                        else if (isClosed)
                          _StatusChip(
                            text: l10n.tourClosed,
                            color: theme.colorScheme.error,
                          )
                        else if (deadline != null)
                          Text(
                            l10n.tourDeadline(_fmtDeadline(deadline)),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDeadline(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkRow({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      // 연다. 예전에는 주소를 복사만 했는데, 우리가 저장한 계획서는
      // `/media/…` 라 복사해 봐야 붙여넣을 데가 없다.
      //
      // 앱 안에 PDF 뷰어는 넣지 않는다 — 기기의 기본 뷰어가 낫고, 뷰어를
      // 넣으면 다섯 플랫폼 빌드가 그만큼 무거워진다 (자료실도 같은 판단).
      onTap: () async {
        final full = mediaUrl(url);
        var opened = false;
        try {
          opened = await launchUrl(
            Uri.parse(full),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          opened = false;
        }
        if (opened || !context.mounted) return;
        // 못 열면 최소한 주소는 손에 쥐여 준다.
        await Clipboard.setData(ClipboardData(text: full));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.tourOpenFailed),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(Icons.copy, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// 투어 값에 든 것과 안 든 것을 셋 다 적는다.
///
/// 안 든 것만 적으면 나머지가 어떤지 읽는 사람이 알 수 없다 — 담당자가
/// 아직 안 정한 것인지, 값에 들어 있는 것인지 구별이 안 간다. 그래서
/// **포함인 것도 포함이라고 말한다.**
///
/// 금액을 모르는 것은 빼지 않고 "미정" 으로 적는다. 빼 버리면 참가자는
/// 그것이 값에 들어 있는 줄 안다.
class _Coverage extends StatelessWidget {
  const _Coverage({required this.option, required this.currency});

  final Map<String, dynamic> option;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final missing = {
      for (final i in TourExtras.of([option]).items) i.kind: i,
    };

    String out(ExtraKind k) => switch (k) {
      ExtraKind.meals => l10n.epTourNoMeals,
      ExtraKind.lodging => l10n.epTourNoLodging,
      ExtraKind.airfare => l10n.epTourNoAirfare,
    };
    String inc(ExtraKind k) => switch (k) {
      ExtraKind.meals => l10n.epTourYesMeals,
      ExtraKind.lodging => l10n.epTourYesLodging,
      ExtraKind.airfare => l10n.epTourYesAirfare,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.regExtrasCoverage,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          for (final kind in ExtraKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(
                    missing.containsKey(kind)
                        ? Icons.remove_circle_outline
                        : Icons.check_circle_outline,
                    size: 14,
                    color: missing.containsKey(kind)
                        ? Colors.orange[800]
                        : Colors.green[700],
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      missing.containsKey(kind) ? out(kind) : inc(kind),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (missing.containsKey(kind))
                    Text(
                      missing[kind]!.amount == null
                          ? l10n.regExtrasTbd
                          : currency.format(missing[kind]!.amount!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[900],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
