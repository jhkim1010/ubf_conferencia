import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

class RoommateStep extends ConsumerStatefulWidget {
  final String programId;
  final bool enabled;

  const RoommateStep({super.key, required this.programId, this.enabled = true});

  @override
  ConsumerState<RoommateStep> createState() => _RoommateStepState();
}

class _RoommateStepState extends ConsumerState<RoommateStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider(widget.programId));
    _controller = TextEditingController(text: state.roommatePreference ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.enabled) {
      return Center(child: Text(l10n.sectionDisabled));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.hotel, size: 48, color: Colors.indigo),
        const SizedBox(height: 16),
        Text(
          l10n.roommateQuestion,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.roommateHelp,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.roommateFieldLabel,
            hintText: l10n.roommateFieldHint,
            alignLabelWithHint: true,
          ),
          onChanged: (val) => ref
              .read(registrationFormProvider(widget.programId).notifier)
              .updateRoommate(val),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.roommateNotice,
                  style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
