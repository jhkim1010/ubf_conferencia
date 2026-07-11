import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/registration_provider.dart';

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
    if (!widget.enabled) {
      return const Center(child: Text('이 섹션은 비활성화되어 있습니다'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.hotel, size: 48, color: Colors.indigo),
        const SizedBox(height: 16),
        Text(
          '같이 머물고 싶은 분이 있으신가요?',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '룸메이트 희망자의 이름(성경이름 또는 본명)을 입력해 주세요.\n최대한 반영하도록 노력하겠습니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '룸메이트 희망 (선택)',
            hintText: '예: 베드로, 요한 (같은 방 희망)\n또는 "없음"으로 입력',
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
                  '룸메이트 배정은 리더의 재량으로 조정될 수 있습니다.',
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
