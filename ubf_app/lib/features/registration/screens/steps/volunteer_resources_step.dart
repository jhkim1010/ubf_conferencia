import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';

// 자원 유형 목록
const _resourceOptions = [
  ('piano',       Icons.piano,            '피아노'),
  ('guitar',      Icons.music_note,       '기타'),
  ('bass',        Icons.queue_music,      '베이스'),
  ('drums',       Icons.library_music,    '드럼'),
  ('violin',      Icons.music_note,       '바이올린'),
  ('worship_lead',Icons.mic,              '워십 인도'),
  ('vocals',      Icons.mic_none,         '보컬'),
  ('translation', Icons.translate,        '통역/번역'),
  ('photography', Icons.photo_camera,     '사진/영상'),
  ('sound',       Icons.speaker,          '음향'),
  ('design',      Icons.brush,            '디자인'),
  ('it',          Icons.computer,         'IT/기술'),
  ('childcare',   Icons.child_care,       '어린이 돌봄'),
  ('cooking',     Icons.restaurant,       '요리/주방'),
  ('driving',     Icons.directions_car,   '차량 운전'),
  ('medical',     Icons.medical_services, '의료/구급'),
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
    if (!enabled) {
      return const Center(child: Text('이 섹션은 비활성화되어 있습니다'));
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
          '프로그램 진행에 도움을 드릴 수 있나요?',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '해당되는 항목을 모두 선택해 주세요. (선택 사항)',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _resourceOptions.map((item) {
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
          decoration: const InputDecoration(
            labelText: '기타 도움 가능한 내용 (선택)',
            hintText: '위 목록에 없는 재능이나 자원을 적어주세요',
            prefixIcon: Icon(Icons.edit_note),
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.updateVolunteerNote,
        ),
      ],
    );
  }
}
