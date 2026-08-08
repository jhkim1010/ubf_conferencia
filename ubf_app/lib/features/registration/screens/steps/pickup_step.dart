import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../providers/registration_provider.dart';

// 개최국 참석자의 픽업(035)
//
// 개최국에서 오는 사람에게 항공편을 물을 이유가 없다. 버스로, 차로,
// 기차로 온다. 필요한 것은 하나다 — **태울지, 태운다면 어디서.**
//
// 예전에는 항공편 스텝만 건너뛰고 아무것도 묻지 않았다. 그래서 공항이 아닌
// 곳에서 태워야 하는 사람이 배차 명단에서 통째로 빠졌다.
class PickupStep extends ConsumerStatefulWidget {
  final String programId;
  const PickupStep({super.key, required this.programId});

  @override
  ConsumerState<PickupStep> createState() => _PickupStepState();
}

class _PickupStepState extends ConsumerState<PickupStep> {
  late final TextEditingController _from = TextEditingController(
    text: ref.read(registrationFormProvider(widget.programId)).pickupFrom ?? '',
  );

  @override
  void dispose() {
    _from.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final form = ref.watch(registrationFormProvider(widget.programId));
    final notifier = ref.read(
      registrationFormProvider(widget.programId).notifier,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(
          Icons.directions_bus_outlined,
          size: 44,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          l10n.pickupTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.pickupBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        RadioGroup<bool>(
          groupValue: form.needsPickup,
          onChanged: (v) => notifier.setNeedsPickup(v ?? true),
          child: Column(
            children: [
              RadioListTile<bool>(
                value: true,
                title: Text(l10n.pickupNeed),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<bool>(
                value: false,
                title: Text(l10n.pickupNeedNo),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),

        // 태울 곳은 태운다고 했을 때만 묻는다. 안 태우는 사람에게 빈 칸을
        // 보여 주면 적어야 하는 줄 안다.
        if (form.needsPickup) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _from,
            decoration: InputDecoration(
              labelText: l10n.pickupFromLabel,
              hintText: l10n.pickupFromHint,
              border: const OutlineInputBorder(),
              // 비워 두면 담당자가 어디로 갈지 모른다. 막지는 않는다 —
              // 아직 안 정한 사람이 여기서 갇히면 등록 자체를 못 끝낸다.
              errorText: _from.text.trim().isEmpty
                  ? l10n.pickupFromRequired
                  : null,
            ),
            onChanged: (v) {
              notifier.updatePickupFrom(v.trim());
              setState(() {});
            },
          ),
        ],
      ],
    );
  }
}
