import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';

class FoodStep extends ConsumerStatefulWidget {
  final String programId;
  final bool enabled;

  const FoodStep({super.key, required this.programId, this.enabled = true});

  @override
  ConsumerState<FoodStep> createState() => _FoodStepState();
}

class _FoodStepState extends ConsumerState<FoodStep> {
  late final TextEditingController _cannotEatController;
  late final TextEditingController _medicalController;
  bool _skipsBreakfast = false;

  static const _commonRestrictions = [
    '채식주의자 (Vegetarian)',
    '비건 (Vegan)',
    '할랄 (Halal)',
    '코셔 (Kosher)',
    '글루텐 불내증',
    '땅콩 알레르기',
    '유제품 알레르기',
    '해산물 알레르기',
    '없음',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider(widget.programId));
    _cannotEatController = TextEditingController(text: state.foodRequirements ?? '');
    _medicalController = TextEditingController(text: state.medicalConditions ?? '');
    _skipsBreakfast = state.skipsBreakfast;
  }

  @override
  void dispose() {
    _cannotEatController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(registrationFormProvider(widget.programId).notifier).updateFood(
      foodRequirements: _cannotEatController.text.trim(),
      medicalConditions: _medicalController.text.trim(),
      skipsBreakfast: _skipsBreakfast,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const Center(child: Text('이 섹션은 비활성화되어 있습니다'));
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── 질병 유무 ───────────────────────────────────────
        Text('질병 유무', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        TextField(
          controller: _medicalController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '당뇨, 고혈압, 알레르기 등 특이 질환을 입력하세요 (없으면 비워두세요)',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 20),

        // ── 섭취 불가능한 음식 ─────────────────────────────
        Text('섭취 불가능한 음식', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          '아래에서 선택하거나 직접 입력하세요',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _commonRestrictions.map((restriction) {
            return ActionChip(
              label: Text(restriction, style: const TextStyle(fontSize: 13)),
              onPressed: () {
                if (restriction == '없음') {
                  _cannotEatController.text = '없음';
                } else {
                  final current = _cannotEatController.text;
                  if (current.isEmpty || current == '없음') {
                    _cannotEatController.text = restriction;
                  } else if (!current.contains(restriction)) {
                    _cannotEatController.text = '$current, $restriction';
                  }
                }
                _save();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cannotEatController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '섭취 불가능한 음식을 입력하세요',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 20),

        // ── 아침 식사 여부 ──────────────────────────────────
        Text('아침 식사', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        CheckboxListTile(
          value: _skipsBreakfast,
          title: const Text('아침 식사를 주로 하지 않습니다'),
          subtitle: const Text('식사 준비 인원 파악에 사용됩니다'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() => _skipsBreakfast = val ?? false);
            _save();
          },
        ),
      ],
    );
  }
}
