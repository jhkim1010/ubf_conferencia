import 'package:flutter/material.dart';
import '../../../core/utils/tour_extras.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../program/providers/program_provider.dart';
import '../providers/registration_provider.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/money.dart';
import '../../../core/constants/world_countries.dart';

// 등록 요약 화면 - 모든 정보 확인 + 총 비용 표시
// 날짜만 보여준다. 서버가 주는 값은 '2027-02-10T03:00:00.000Z' 같은 타임스탬프라
// 그대로 붙이면 시각과 UTC 표시까지 화면에 나온다. 실제로 그렇게 나오고 있었다.
//
// 문자열 앞부분을 자르기만 한다. DateTime 으로 파싱하면 UTC → 로컬 변환이 일어나
// 시차에 따라 날짜가 하루 밀린다 (수양회 시작일이 하루 당겨져 보이게 된다).
String _ymd(Object? raw) {
  if (raw == null) return '';
  final s = raw.toString();
  return s.length >= 10 ? s.substring(0, 10) : s;
}

// 항공편 카드의 줄들.
//
// 예매 전이면 항공편 번호·공항 줄을 빼고 날짜에 "(예상 — 미예매)" 를 붙인다.
// 빈 칸으로 남겨 두면 "아직 안 적은 사람"과 "아직 안 산 사람"이 구별되지
// 않는다 — 담당자가 배차를 짤 때 이 둘을 다르게 다뤄야 한다.
List<Widget> _flightRows(
  AppLocalizations l10n,
  Map<String, dynamic> flight, {
  required String airportLabel,
  required String airportKey,
  required String whenLabel,
  required String whenKey,
}) {
  final when = _flightWhen(flight[whenKey]);
  if (flight['estimated'] == true) {
    return [
      _InfoRow(
        whenLabel,
        when.isEmpty
            ? l10n.expFlightEstimated
            : '$when ${l10n.expFlightEstimated}',
      ),
    ];
  }

  String orDash(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? '-' : s;
  }

  return [
    _InfoRow(l10n.summaryFlightNo, orDash(flight['flight_no'])),
    _InfoRow(airportLabel, orDash(flight[airportKey])),
    _InfoRow(whenLabel, when.isEmpty ? '-' : when),
  ];
}

// 항공편 시각. 날짜 + (있으면) 시:분.
//
// 여기도 자르기만 한다 — _ymd 와 같은 이유다. 자정(00:00)은 시각을 붙이지
// 않는다. 예매 전 예상 날짜는 시각 없이 자정으로 저장되므로, 그대로 붙이면
// "새벽 0시 도착"이라는 없는 정보를 만들어 낸다.
String _flightWhen(Object? raw) {
  final s = raw?.toString() ?? '';
  if (s.length < 10) return s;
  final date = s.substring(0, 10);
  if (s.length < 16 || s[10] != 'T') return date;
  final time = s.substring(11, 16);
  return time == '00:00' ? date : '$date $time';
}

String _period(Object? start, Object? end) {
  final a = _ymd(start);
  final b = _ymd(end);
  if (b.isEmpty || b == a) return a;
  return '$a ~ $b';
}

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
          final currency = Currency.of(program['currency'] as String?);

          // 수양회 전후 숙박(028). 등급을 고른 사람에게만 보여준다.
          // 예상 금액은 여기서 계산한다 — 저장해 두면 단가를 고친 뒤에도
          // 옛 금액이 남아 참가자와 담당자가 다른 숫자를 본다.
          final hotelOptions = List<Map<String, dynamic>>.from(
            program['hotel_options'] as List? ?? const [],
          );
          final hotelPicked = hotelOptions
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (o) => o?['key'] == formState.hotelOptionKey,
                orElse: () => null,
              );
          final hotelNights =
              formState.hotelNightsBefore + formState.hotelNightsAfter;
          final hotelPerNight = Money.parse(hotelPicked?['pricePerNight']);
          final hotelEstimate = hotelPerNight != null && hotelNights > 0
              ? hotelPerNight * hotelNights
              : null;

          final selectedOptionDetails = options
              .where(
                (o) => formState.selectedOptions.contains(o['id'] as String),
              )
              .toList();

          double totalCost = selectedOptionDetails.fold(
            0.0,
            (sum, o) => sum + (Money.parse(o['cost']) ?? 0).toDouble(),
          );

          // 참가비 등급과 확정된 할인을 합계에 반영한다. 투어 비용만 더하면
          // 참가자가 실제로 내야 할 금액과 다른 숫자를 보게 된다.
          final tierFee = switch (formState.feeTier) {
            'basic' => Money.parse(program['fee_basic']),
            'premium' => Money.parse(program['fee_premium']),
            _ => null,
          };
          totalCost += (tierFee ?? 0).toDouble();

          // 승인된 할인만 뺀다. 신청 중인 금액을 미리 빼면 아직 결정되지도 않은
          // 감액을 확정된 것처럼 보여주게 된다.
          final saved = ref.watch(registrationProvider(programId)).valueOrNull;
          final approvedDiscount = saved?['discount_status'] == 'approved'
              ? Money.parse(saved?['discount_amount'])?.toDouble() ?? 0
              : 0.0;
          totalCost = (totalCost - approvedDiscount).clamp(
            0.0,
            double.infinity,
          );

          // 따로 나갈 돈 한 줄(061). 호텔 숙박비 + 투어에 안 들어 있는 것.
          //
          // 금액을 모르는 것이 섞이면 그 사실을 함께 말한다 — 아는 것만
          // 더해 놓으면 그것이 전부인 줄 알고 돈을 덜 챙겨 온다.
          final extras = TourExtras.of(selectedOptionDetails);
          final extrasKnown = extras.known + (hotelEstimate?.toDouble() ?? 0);
          final extrasUnsure =
              extras.unknown.isNotEmpty ||
              // 호텔 등급을 아직 안 골랐는데 묵을 밤은 있다.
              (hotelNights > 0 && hotelEstimate == null);
          final extrasLine = switch (extrasLineOf(
            known: extrasKnown,
            unsure: extrasUnsure,
          )) {
            ExtrasLine.none => null,
            ExtrasLine.known => l10n.summaryPlusEstimated(
              currency.format(extrasKnown),
            ),
            ExtrasLine.knownAndUnsure => l10n.summaryPlusEstimatedSome(
              currency.format(extrasKnown),
            ),
            ExtrasLine.unsureOnly => l10n.summaryPlusUnknownOnly,
          };

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
                    _InfoRow(
                      l10n.summaryPeriod,
                      _period(program['start_date'], program['end_date']),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 개인 정보
              _SectionCard(
                title: l10n.regStepPersonal,
                icon: Icons.person,
                onEdit: () => context.go('/registration/$programId'),
                children: [
                  _InfoRow(
                    l10n.summaryCountry,
                    WorldCountries.display(formState.country) ?? '-',
                  ),
                  _InfoRow(l10n.summaryBranch, formState.branch ?? '-'),
                  _InfoRow(l10n.summaryRealName, formState.realName ?? '-'),
                  _InfoRow(l10n.summaryBibleName, formState.bibleName ?? '-'),
                  _InfoRow(
                    l10n.regGender,
                    formState.gender == 'M'
                        ? l10n.genderMale
                        : formState.gender == 'F'
                        ? l10n.genderFemale
                        : '-',
                  ),
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
                  children: _flightRows(
                    l10n,
                    formState.arrivalFlight!,
                    airportLabel: l10n.summaryArrAirport,
                    airportKey: 'arrival_airport',
                    whenLabel: l10n.summaryArrTime,
                    whenKey: 'scheduled_arrival',
                  ),
                ),
              if (formState.arrivalFlight != null) const SizedBox(height: 12),

              // 출발 비행기
              if (formState.departureFlight != null)
                _SectionCard(
                  title: l10n.regStepDeparture,
                  icon: Icons.flight_takeoff,
                  onEdit: () => context.go('/registration/$programId'),
                  children: _flightRows(
                    l10n,
                    formState.departureFlight!,
                    airportLabel: l10n.summaryDepAirport,
                    airportKey: 'departure_airport',
                    whenLabel: l10n.summaryDepTime,
                    whenKey: 'scheduled_departure',
                  ),
                ),
              if (formState.departureFlight != null) const SizedBox(height: 12),

              // 음식 특별 사항
              if (formState.foodRequirements?.isNotEmpty == true)
                _SectionCard(
                  title: l10n.summarySectionFood,
                  icon: Icons.restaurant,
                  onEdit: () => context.go('/registration/$programId'),
                  children: [_InfoRow('', formState.foodRequirements ?? '-')],
                ),
              if (formState.foodRequirements?.isNotEmpty == true)
                const SizedBox(height: 12),

              // 선택 옵션
              if (selectedOptionDetails.isNotEmpty)
                _SectionCard(
                  title: l10n.summarySectionOptions,
                  icon: Icons.checklist,
                  onEdit: () => context.go('/registration/$programId'),
                  children: selectedOptionDetails
                      .map(
                        (o) => _InfoRow(
                          o['name'] ?? '',
                          currency.format(Money.parse(o['cost'])),
                        ),
                      )
                      .toList(),
                ),
              if (selectedOptionDetails.isNotEmpty) const SizedBox(height: 12),

              // 룸메이트
              if (formState.roommatePreference?.isNotEmpty == true)
                _SectionCard(
                  title: l10n.summarySectionRoommate,
                  icon: Icons.hotel,
                  onEdit: () => context.go('/registration/$programId'),
                  children: [_InfoRow('', formState.roommatePreference ?? '-')],
                ),

              // 수양회 전후 숙박(028). 고른 사람에게만 보인다.
              //
              // 참가비 총액과 **분리해서** 보여준다. 아래 총액에 섞어 놓으면
              // 그 금액을 입금해야 하는 줄 알고, 호텔 값을 두 번 내거나
              // 아예 안 내게 된다.
              if (hotelPicked != null) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: l10n.summarySectionHotel,
                  icon: Icons.hotel_outlined,
                  onEdit: () => context.go('/registration/$programId'),
                  children: [
                    _InfoRow(
                      optionLabelFor(
                        hotelPicked,
                        Localizations.localeOf(context).languageCode,
                      ),
                      hotelEstimate != null
                          ? currency.format(hotelEstimate)
                          : l10n.hotelPriceTbd,
                    ),
                    _InfoRow(
                      '',
                      l10n.summaryHotelNights(
                        formState.hotelNightsBefore,
                        formState.hotelNightsAfter,
                      ),
                    ),
                    _InfoRow('', l10n.hotelNotInFee),
                  ],
                ),
              ],

              // 참가비 등급 + 할인
              if (tierFee != null || formState.discountRequested) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: l10n.regStepFee,
                  icon: Icons.payments_outlined,
                  onEdit: () => context.go('/registration/$programId'),
                  children: [
                    if (tierFee != null)
                      _InfoRow(
                        formState.feeTier == 'premium'
                            ? l10n.feeTierPremium
                            : l10n.feeTierBasic,
                        currency.format(tierFee),
                      ),
                    if (formState.discountRequested)
                      _InfoRow(
                        l10n.discountTitle,
                        // 승인 전에는 금액이 아니라 상태를 보여준다.
                        approvedDiscount > 0
                            ? '- ${currency.format(approvedDiscount)}'
                            : saved?['discount_status'] == 'rejected'
                            ? l10n.discountStatusRejected
                            : l10n.discountStatusPending,
                      ),
                  ],
                ),
              ],

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
                      currency.format(totalCost),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
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
                    // 참가비 옆에 **따로 나갈 돈**을 함께 말해 준다(061).
                    // 호텔 숙박비와 투어에 안 들어 있는 것들이다. 합계에
                    // 더하지는 않는다 — 우리에게 내는 돈이 아니고 예상일
                    // 뿐이라, 더하면 확정된 청구서처럼 보인다.
                    if (extrasLine != null) ...[
                      const Divider(height: 20),
                      Text(
                        extrasLine,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.summaryExtrasHelp,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
                  onPressed: () =>
                      context.push('/program/$programId/immigration'),
                ),

              // 내 이동(배차) 버튼 — 국제 수양회에서 항공편 있을 때
              if (program['program_type'] != 'local')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.directions_bus),
                    label: Text(l10n.mtrTitle),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F7A6E),
                      side: const BorderSide(color: Color(0xFF0F7A6E)),
                    ),
                    onPressed: () =>
                        context.push('/program/$programId/my-transport'),
                  ),
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
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
