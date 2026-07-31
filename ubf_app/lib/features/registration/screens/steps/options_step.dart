import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../../core/utils/money.dart';

class OptionsStep extends ConsumerWidget {
  final String programId;
  final List<Map<String, dynamic>> options;
  final bool enabled;

  const OptionsStep({
    super.key,
    required this.programId,
    required this.options,
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
        totalCost += (option['cost'] as num).toDouble();
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
                  Money.format(totalCost),
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
  final bool isSelected;

  const _TourCard({
    required this.programId,
    required this.option,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final optionId = option['id'] as String;
    final cost = (option['cost'] as num).toDouble();
    final photoUrls =
        (option['photoUrls'] as List?)?.cast<String>() ?? const <String>[];
    final description = option['description'] as String?;
    final contactName = option['contactName'] as String?;
    final brochureUrl = option['brochureUrl'] as String?;
    final videoUrl = option['videoUrl'] as String?;
    final capacity = (option['capacity'] as num?)?.toInt();
    final signupCount = (option['signupCount'] as num?)?.toInt() ?? 0;
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
                      photoUrls[i],
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
                  cost == 0 ? l10n.optionsFree : Money.format(cost),
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
                  // 홍보물 링크
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
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.linkCopied),
              duration: const Duration(seconds: 2),
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
