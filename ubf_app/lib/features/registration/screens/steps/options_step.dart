import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';

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
    if (!enabled || options.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('이 프로그램에는 특별 옵션이 없습니다'),
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
          '참여할 프로그램을 선택하세요 (복수 선택 가능)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((option) {
          final optionId = option['id'] as String;
          final isSelected = selectedOptions.contains(optionId);
          final cost = (option['cost'] as num).toDouble();

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                option['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: option['description'] != null
                  ? Text(option['description'])
                  : null,
              secondary: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cost == 0
                      ? Colors.green[50]
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cost == 0 ? '무료' : '₩${cost.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cost == 0
                        ? Colors.green[700]
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              value: isSelected,
              onChanged: (_) => ref
                  .read(registrationFormProvider(programId).notifier)
                  .toggleOption(optionId),
            ),
          );
        }),
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
                const Text(
                  '선택한 옵션 합계',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₩${totalCost.toStringAsFixed(0)}',
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
