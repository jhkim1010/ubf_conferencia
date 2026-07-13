import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// 자원 유형 목록 (현재 언어의 라벨로 반환)
List<(String, IconData, String)> _resourceOptions(AppLocalizations l10n) => [
      ('piano',        Icons.piano,            l10n.volPiano),
      ('guitar',       Icons.music_note,       l10n.volGuitar),
      ('bass',         Icons.queue_music,      l10n.volBass),
      ('drums',        Icons.library_music,    l10n.volDrums),
      ('violin',       Icons.music_note,       l10n.volViolin),
      ('worship_lead', Icons.mic,              l10n.volWorshipLead),
      ('vocals',       Icons.mic_none,         l10n.volVocals),
      ('translation',  Icons.translate,        l10n.volTranslation),
      ('photography',  Icons.photo_camera,     l10n.volPhotography),
      ('sound',        Icons.speaker,          l10n.volSound),
      ('design',       Icons.brush,            l10n.volDesign),
      ('it',           Icons.computer,         l10n.volIt),
      ('childcare',    Icons.child_care,       l10n.volChildcare),
      ('cooking',      Icons.restaurant,       l10n.volCooking),
      ('driving',      Icons.directions_car,   l10n.volDriving),
      ('medical',      Icons.medical_services, l10n.volMedical),
    ];

class VolunteerResourcesStep extends ConsumerWidget {
  final String programId;
  final bool enabled;

  const VolunteerResourcesStep({
    super.key,
    required this.programId,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (!enabled) {
      return Center(child: Text(l10n.sectionDisabled));
    }

    final selected = ref.watch(
      registrationFormProvider(programId).select((s) => s.volunteerResources),
    );
    final notifier = ref.read(registrationFormProvider(programId).notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.volunteer_activism, size: 48, color: Colors.teal),
        const SizedBox(height: 16),
        Text(
          l10n.volQuestion,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.volHelp,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _resourceOptions(l10n).map((item) {
            final (key, icon, label) = item;
            final isSelected = selected.contains(key);
            return FilterChip(
              avatar: Icon(icon, size: 18,
                color: isSelected ? Colors.white : Colors.teal,
              ),
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => notifier.toggleVolunteerResource(key),
              selectedColor: Colors.teal,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // 기타 입력
        TextField(
          decoration: InputDecoration(
            labelText: l10n.volOtherLabel,
            hintText: l10n.volOtherHint,
            prefixIcon: const Icon(Icons.edit_note),
            border: const OutlineInputBorder(),
          ),
          onChanged: notifier.updateVolunteerNote,
        ),
      ],
    );
  }
}
