import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';
import '../providers/transport_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// PRD F5 — 참가자 내 이동 정보 (도착 픽업 · 출발 드롭 · 자차 토글)
class MyTransportScreen extends ConsumerWidget {
  final String programId;
  const MyTransportScreen({super.key, required this.programId});

  String _hhmm(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(myTransportProvider(programId));
    void refresh() => ref.invalidate(myTransportProvider(programId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mtrTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (data) {
          final needsPickup = data['needsPickup'] as bool? ?? true;
          // 국제 수양회의 개최국 참석자는 배차판에 올라가지 않는다(서버 판정).
          // 그 사실을 여기서 말해 주지 않으면 오지 않을 차를 기다리게 된다.
          final pickupExempt = data['pickupExempt'] as bool? ?? false;
          final arrival = data['arrival'] as Map<String, dynamic>?;
          final departure = data['departure'] as Map<String, dynamic>?;
          // 대상이 아니어도 담당자가 손으로 태워 둔 경우가 있다. 그때는 배차
          // 카드를 그대로 보여준다 — 실제로 그 차를 타야 하기 때문이다.
          final showArrival = arrival != null || !pickupExempt;
          final showDeparture = departure != null || !pickupExempt;
          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (showArrival) ...[
                  _runCard(
                    context,
                    title: l10n.mtrArrival,
                    route: l10n.mtrArrivalRoute(
                      arrival?['airport'] as String? ?? '—',
                    ),
                    run: arrival,
                    color: const Color(0xFF0F7A6E),
                    emptyText: l10n.mtrPending,
                  ),
                  const SizedBox(height: 12),
                ],
                if (showDeparture) ...[
                  _runCard(
                    context,
                    title: l10n.mtrDeparture,
                    route: l10n.mtrDepartureRoute(
                      departure?['airport'] as String? ?? '—',
                    ),
                    run: departure,
                    color: const Color(0xFF1565C0),
                    emptyText: l10n.mtrPending,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                if (pickupExempt)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: Text(
                        l10n.mtrHostCountryTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.mtrHostCountryDesc),
                      isThreeLine: true,
                    ),
                  )
                else
                  // 자차 이동 토글
                  Card(
                    child: SwitchListTile(
                      secondary: const Icon(Icons.directions_car_outlined),
                      title: Text(
                        l10n.mtrSelfDrive,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.mtrSelfDriveDesc),
                      value: !needsPickup,
                      onChanged: (selfDrive) async {
                        try {
                          await ApiClient.setMyPickup(programId, !selfDrive);
                          refresh();
                        } on ApiException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _runCard(
    BuildContext context, {
    required String title,
    required String route,
    required Map<String, dynamic>? run,
    required Color color,
    required String emptyText,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final assigned = run != null;
    final driver = run?['driver_name'] as String?;
    final phone = run?['driver_phone'] as String?;
    final vehicle = run?['vehicle'] as String?;
    final meet = run?['meet_point'] as String?;
    final depart = _hhmm(run?['depart_at'] as String?);
    final coPax = (run?['co_passengers'] as List?)?.cast<String>() ?? const [];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.28)!],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  assigned ? l10n.mtrAssigned : l10n.mtrPendingBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            route,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (!assigned)
            Text(
              emptyText,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            )
          else ...[
            if (vehicle != null && vehicle.isNotEmpty || depart.isNotEmpty)
              _kv(
                l10n.mtrVehicle,
                [
                  vehicle ?? '',
                  if (depart.isNotEmpty) depart,
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
            if (driver != null && driver.isNotEmpty)
              _kv(
                l10n.mtrDriver,
                [
                  driver,
                  if (phone != null && phone.isNotEmpty) phone,
                ].join(' · '),
              ),
            if (coPax.isNotEmpty) _kv(l10n.mtrCoPassengers, coPax.join(', ')),
            if (meet != null && meet.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.mtrMeetPoint} · $meet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            k,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
