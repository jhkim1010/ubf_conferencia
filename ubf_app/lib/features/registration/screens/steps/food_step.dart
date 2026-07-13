import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

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

  List<String> _commonRestrictions(AppLocalizations l10n) => [
        l10n.foodVegetarian,
        l10n.foodVegan,
        l10n.foodHalal,
        l10n.foodKosher,
        l10n.foodGluten,
        l10n.foodPeanut,
        l10n.foodDairy,
        l10n.foodSeafood,
        l10n.foodNone,
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
    final l10n = AppLocalizations.of(context)!;
    if (!widget.enabled) {
      return Center(child: Text(l10n.sectionDisabled));
    }

    final theme = Theme.of(context);
    final none = l10n.foodNone;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── 질병 유무 ───────────────────────────────────────
        Text(l10n.foodMedicalTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        TextField(
          controller: _medicalController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: l10n.foodMedicalHint,
            alignLabelWithHint: true,
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 20),

        // ── 섭취 불가능한 음식 ─────────────────────────────
        Text(l10n.foodRestrictionTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          l10n.foodRestrictionHelp,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _commonRestrictions(l10n).map((restriction) {
            return ActionChip(
              label: Text(restriction, style: const TextStyle(fontSize: 13)),
              onPressed: () {
                if (restriction == none) {
                  _cannotEatController.text = none;
                } else {
                  final current = _cannotEatController.text;
                  if (current.isEmpty || current == none) {
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
          decoration: InputDecoration(
            hintText: l10n.foodRestrictionInputHint,
            alignLabelWithHint: true,
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 20),

        // ── 아침 식사 여부 ──────────────────────────────────
        Text(l10n.foodBreakfastTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        CheckboxListTile(
          value: _skipsBreakfast,
          title: Text(l10n.foodSkipBreakfast),
          subtitle: Text(l10n.foodSkipBreakfastSub),
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
