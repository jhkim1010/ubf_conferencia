import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../program/providers/program_provider.dart';
import '../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// 등록 요약 화면 - 모든 정보 확인 + 총 비용 표시
class SummaryScreen extends ConsumerWidget {
  final String programId;

  const SummaryScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(registrationFormProvider(programId));
    final programAsync = ref.watch(programByIdProvider(programId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.summaryTitle)),
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (program) {
          if (program == null) return const SizedBox.shrink();

          final options = List<Map<String, dynamic>>.from(
            program['program_options'] as List? ?? [],
          );

          // 선택된 옵션 목록 및 비용 계산
          final selectedOptionDetails = options
              .where((o) => formState.selectedOptions.contains(o['id'] as String))
              .toList();

          double totalCost = selectedOptionDetails.fold(
            0.0,
            (sum, o) => sum + (o['cost'] as num).toDouble(),
          );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 프로그램 정보
              _SectionCard(
                title: l10n.summarySectionProgram,
                icon: Icons.event,
                children: [
                  _InfoRow(l10n.summaryName, program['name'] ?? ''),
                  _InfoRow(l10n.summaryLocation, program['location'] ?? ''),
                  if (program['start_date'] != null)
                    _InfoRow(l10n.summaryPeriod, '${program['start_date']} ~ ${program['end_date'] ?? ''}'),
                ],
              ),
              const SizedBox(height: 12),

              // 개인 정보
              _SectionCard(
                title: l10n.regStepPersonal,
                icon: Icons.person,
                onEdit: () => context.go('/registration/$programId'),
                children: [
                  _InfoRow(l10n.summaryCountry, formState.country ?? '-'),
                  _InfoRow(l10n.summaryBranch, formState.branch ?? '-'),
                  _InfoRow(l10n.summaryRealName, formState.realName ?? '-'),
                  _InfoRow(l10n.summaryBibleName, formState.bibleName ?? '-'),
                  _InfoRow(l10n.regGender, formState.gender == 'M' ? l10n.genderMale : formState.gender == 'F' ? l10n.genderFemale : '-'),
                  _InfoRow(l10n.summaryAge, formState.age?.toString() ?? '-'),
                ],
              ),
              const SizedBox(height: 12),

              // 도착 비행기
              if (formState.arrivalFlight != null)
                _SectionCard(
                  title: l10n.regStepArrival,
                  icon: Icons.flight_land,
                  onEdit: () => context.go('/registration/$programId'),
                  children: [
                    _InfoRow(l10n.summaryFlightNo, formState.arrivalFlight!['flight_no'] ?? '-'),
                    _InfoRow(l10n.summaryArrAirport, formState.arrivalFlight!['arrival_airport'] ?? '-'),
                    _InfoRow(l10n.summaryArrTime, formState.arrivalFlight!['scheduled_arrival'] ?? '-'),
                  ],
                ),
              if (formState.arrivalFlight != null) const SizedBox(height: 12),

              // 출발 비행기
              if (formState.departureFlight != null)
                _SectionCard(
                  title: l10n.regStepDeparture,
                  icon: Icons.flight_takeoff,
                  onEdit: () => context.go('/registration/$programId'),
                  children: [
                    _InfoRow(l10n.summaryFlightNo, formState.departureFlight!['flight_no'] ?? '-'),
                    _InfoRow(l10n.summaryDepAirport, formState.departureFlight!['departure_airport'] ?? '-'),
                    _InfoRow(l10n.summaryDepTime, formState.departureFlight!['scheduled_departure'] ?? '-'),
                  ],
                ),
              if (formState.departureFlight != null) const SizedBox(height: 12),

              // 음식 특별 사항
              if (formState.foodRequirements?.isNotEmpty == true)
                _SectionCard(
                  title: l10n.summarySectionFood,
                  icon: Icons.restaurant,
                  onEdit: () => context.go('/registration/$programId'),
                  children: [
                    _InfoRow('', formState.foodRequirements ?? '-'),
                  ],
                ),
              if (formState.foodRequirements?.isNotEmpty == true) const SizedBox(height: 12),

              // 선택 옵션
              if (selectedOptionDetails.isNotEmpty)
                _SectionCard(
                  title: l10n.summarySectionOptions,
                  icon: Icons.checklist,
                  onEdit: () => context.go('/registration/$programId'),
                  children: selectedOptionDetails.map((o) => _InfoRow(
                    o['name'] ?? '',
                    '₩${(o['cost'] as num).toStringAsFixed(0)}',
                  )).toList(),
                ),
              if (selectedOptionDetails.isNotEmpty) const SizedBox(height: 12),

              // 룸메이트
              if (formState.roommatePreference?.isNotEmpty == true)
                _SectionCard(
                  title: l10n.summarySectionRoommate,
                  icon: Icons.hotel,
                  onEdit: () => context.go('/registration/$programId'),
                  children: [
                    _InfoRow('', formState.roommatePreference ?? '-'),
                  ],
                ),

              const SizedBox(height: 20),

              // 총 비용
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.summaryTotalCost,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₩${totalCost.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (totalCost == 0)
                      Text(
                        l10n.summaryNoPaidOptions,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 입국 카드 버튼 (공항/연락처 정보가 있을 때만 표시)
              if (program['nearest_airport'] != null ||
                  program['contact1_name'] != null ||
                  program['contact2_name'] != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.flight_land),
                  label: Text(l10n.summaryViewImmigration),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A3A6B),
                    side: const BorderSide(color: Color(0xFF1A3A6B)),
                  ),
                  onPressed: () => context.push('/program/$programId/immigration'),
                ),

              const SizedBox(height: 24),

              // 제출 버튼
              ElevatedButton(
                onPressed: () => _submit(context, ref, options),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.summarySubmit),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/registration/$programId'),
                child: Text(l10n.summaryEditBtn),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> options,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // 제출 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.summarySubmit),
        content: Text(l10n.summarySubmitConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.summarySubmit),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref
          .read(registrationFormProvider(programId).notifier)
          .submit(options);

      if (!context.mounted) return;
      Navigator.pop(context); // 로딩 닫기

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.summarySubmitDone),
          content: Text(l10n.summarySubmitDoneMsg),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      );

      if (context.mounted) context.go('/home');
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // 로딩 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.summarySubmitFailed('$e')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}

// ─── 섹션 카드 위젯 ─────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback? onEdit;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(AppLocalizations.of(context)!.actionEdit),
                  ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
