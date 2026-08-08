import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../program/providers/program_provider.dart';
import '../../../core/utils/export_service.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'roster_table_screen.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/money.dart';

// 리더용 대시보드 - 통계 + 참가자 관리
class DashboardScreen extends ConsumerWidget {
  final String programId;

  const DashboardScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(programByIdProvider(programId));
    final statsAsync = ref.watch(programStatsProvider(programId));
    final registrationsAsync = ref.watch(
      programRegistrationsProvider(programId),
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: programAsync.when(
          data: (p) => Text(p?['name'] ?? l10n.dashTitle),
          loading: () => Text(l10n.dashTitle),
          error: (_, _) => Text(l10n.dashTitle),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.dashEditSettings,
            onPressed: () => context.push('/leader/program/$programId/edit'),
          ),
          // 내보내기 메뉴
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: l10n.dashExport,
            onSelected: (val) async {
              final registrations = (registrationsAsync.valueOrNull ?? [])
                  .cast<Map<String, dynamic>>();
              final programName =
                  (programAsync.valueOrNull?['name'] as String?) ?? 'program';
              // 내보내기 파일도 수양회가 정한 통화를 따른다.
              final currency = Currency.of(
                programAsync.valueOrNull?['currency'] as String?,
              );
              if (val == 'csv') {
                await ExportService.exportToCsv(
                  registrations,
                  programName,
                  l10n,
                  currency: currency,
                );
              } else {
                await ExportService.exportToExcel(
                  registrations,
                  programName,
                  l10n,
                  currency: currency,
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'excel', child: Text(l10n.dashExportExcel)),
              PopupMenuItem(value: 'csv', child: Text(l10n.dashExportCsv)),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(programStatsProvider(programId));
          ref.invalidate(programRegistrationsProvider(programId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 통계 카드 그리드
            statsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(l10n.commonErrorDetail('$e')),
              data: (stats) => _StatsGrid(stats: stats, programId: programId),
            ),
            const SizedBox(height: 20),

            // 편성 준비 — 방·조 정의 (배정 전 단계)
            // 준비 현황 — 막힌 지점과 연락 대상 (A003)
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  l10n.rdyOpenCard,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.rdyOpenCardSub),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/leader/program/$programId/readiness'),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_outlined,
                    color: Colors.indigo,
                  ),
                ),
                title: Text(
                  l10n.setupTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.dashSetupSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/leader/program/$programId/setup'),
              ),
            ),
            const SizedBox(height: 10),

            // 담당자도 참석자다. 이 수양회를 열어 둔 채로 자기 등록을
            // 바로 열 수 있어야 한다 — 홈으로 나갔다 UUID 를 다시 찾는 것은
            // 자기 수양회에서 할 일이 아니다.
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.how_to_reg_outlined,
                    color: Colors.blueGrey,
                  ),
                ),
                title: Text(
                  l10n.homeAlsoAttending,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.homeAlsoAttendingSub),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/registration/$programId'),
              ),
            ),
            const SizedBox(height: 10),

            // 자료실 — 교재 PDF (030)
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_copy_outlined,
                    color: Colors.deepOrange,
                  ),
                ),
                title: Text(
                  l10n.libTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.dashLibrarySubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/leader/program/$programId/library'),
              ),
            ),
            const SizedBox(height: 10),

            // 배정 — 확정 묶음·자동배정
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_ind_outlined,
                    color: Colors.teal,
                  ),
                ),
                title: Text(
                  l10n.asnTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.dashAssignSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/leader/program/$programId/assign'),
              ),
            ),
            const SizedBox(height: 10),

            // 운행 배차 — 기사 명부·자동배차 (F5)
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7A6E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus_outlined,
                    color: Color(0xFF0F7A6E),
                  ),
                ),
                title: Text(
                  l10n.dspTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.dashDispatchSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/leader/program/$programId/dispatch'),
              ),
            ),
            const SizedBox(height: 20),

            // 입금 대기 섹션
            _SectionHeader(
              title: l10n.dashPendingPayments,
              icon: Icons.payment,
              actionLabel: l10n.dashViewAll,
              onAction: () =>
                  context.push('/leader/program/$programId/payments'),
            ),
            const SizedBox(height: 8),
            registrationsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(l10n.commonErrorDetail('$e')),
              data: (registrations) {
                final pendingPayments = registrations.where((r) {
                  final payments = r['payments'] as List?;
                  return payments?.any((p) => p['status'] == 'pending') == true;
                }).toList();

                if (pendingPayments.isEmpty) {
                  return _EmptyState(message: l10n.dashNoPendingPayments);
                }

                return Column(
                  children: pendingPayments.take(3).map((r) {
                    return _PaymentTile(
                      registration: r,
                      onTap: () =>
                          context.push('/leader/program/$programId/payments'),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // 참가자 목록
            _SectionHeader(
              title: l10n.dashAttendeeList,
              icon: Icons.people,
              actionLabel: l10n.dashViewAll,
              onAction: () =>
                  context.push('/leader/program/$programId/attendees'),
            ),
            const SizedBox(height: 8),
            registrationsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(l10n.commonErrorDetail('$e')),
              data: (registrations) {
                if (registrations.isEmpty) {
                  return _EmptyState(message: l10n.dashNoAttendees);
                }

                return Column(
                  children: registrations.take(5).map((r) {
                    return _AttendeeListTile(registration: r);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // 공지 전송 버튼
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_outlined),
              label: Text(l10n.dashSendNotice),
              onPressed: () =>
                  context.push('/leader/program/$programId/notify'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 통계 그리드 ─────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic>? stats;
  // 카드에서 표를 열려면 어느 수양회인지 알아야 한다.
  final String programId;

  const _StatsGrid({this.stats, required this.programId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (stats == null) {
      return Center(child: Text(l10n.dashNoStats));
    }
    int n(String key) => ((stats![key] ?? 0) as num).toInt();

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: l10n.dashStatTotal,
          value: l10n.unitPeople(n('total_registrations')),
          icon: Icons.people,
          color: Colors.blue,
          onOpen: () => _openTable(context, programId, RosterView.all),
        ),
        _StatCard(
          label: l10n.dashStatSubmitted,
          value: l10n.unitPeople(n('submitted_count')),
          icon: Icons.check_circle,
          color: Colors.green,
          onOpen: () => _openTable(context, programId, RosterView.submitted),
        ),
        _StatCard(
          label: l10n.dashStatFoodRestriction,
          value: l10n.unitPeople(n('food_restriction_count')),
          icon: Icons.restaurant,
          color: Colors.orange,
          onOpen: () => _openTable(context, programId, RosterView.meals),
        ),
        _StatCard(
          label: l10n.dashStatPendingPayment,
          value: l10n.unitCases(n('pending_payment_count')),
          icon: Icons.payment,
          color: Colors.red,
          onOpen: () =>
              _openTable(context, programId, RosterView.pendingPayment),
        ),
        _StatCard(
          label: l10n.dashStatArrival,
          value: l10n.unitPeople(n('arrival_flight_count')),
          icon: Icons.flight_land,
          color: Colors.purple,
          onOpen: () => _openTable(context, programId, RosterView.arrival),
        ),
        _StatCard(
          label: l10n.dashStatConfirmedPayment,
          value: l10n.unitCases(n('confirmed_payment_count')),
          icon: Icons.verified,
          color: Colors.teal,
          onOpen: () => _openTable(context, programId, RosterView.paid),
        ),
      ],
    );
  }
}

// 카드에서 표로. push 로 연다 — 라우터에 경로를 더하면 어디서든 열리는데,
// 이 표는 대시보드를 통해서만 뜻이 있다(어느 수양회인지가 카드에서 온다).
void _openTable(BuildContext context, String programId, RosterView view) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RosterTableScreen(programId: programId, view: view),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onOpen;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              if (onOpen != null) ...[
                const Spacer(),
                Icon(Icons.open_in_full, size: 13, color: Colors.grey[400]),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );

    if (onOpen == null) return Card(child: body);

    // 두 번 누르면 열린다. 그것만 두면 화면 낭독기 사용자와 마우스에
    // 익숙하지 않은 사람이 들어갈 길이 없으므로 길게 누르기도 같은 곳으로
    // 보내고, 오른쪽 위 표시로 "열 수 있다"를 알린다.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '$label. ${l10n.tblHint}',
        child: InkWell(onDoubleTap: onOpen, onLongPress: onOpen, child: body),
      ),
    );
  }
}

// ─── 섹션 헤더 ───────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

// ─── 입금 대기 타일 ──────────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> registration;
  final VoidCallback onTap;

  const _PaymentTile({required this.registration, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(registration['real_name'] ?? l10n.commonNoName),
        subtitle: Text(
          WorldCountries.display(registration['country'] as String?) ?? '',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
          ),
          child: Text(
            l10n.dashPaymentPending,
            style: TextStyle(color: Colors.orange[800], fontSize: 12),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─── 참가자 목록 타일 ────────────────────────────────────────
class _AttendeeListTile extends StatelessWidget {
  final Map<String, dynamic> registration;

  const _AttendeeListTile({required this.registration});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final submitted = registration['submitted'] == true;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: submitted ? Colors.green[100] : Colors.grey[200],
          child: Icon(
            Icons.person,
            color: submitted ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          registration['real_name'] ?? l10n.commonNoName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${WorldCountries.display(registration['country'] as String?) ?? ''}'
          ' / ${registration['branch'] ?? ''}',
        ),
        trailing: Chip(
          label: Text(
            submitted ? l10n.dashStatusDone : l10n.dashStatusInProgress,
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: submitted ? Colors.green[50] : Colors.grey[100],
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

// ─── 빈 상태 ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[500])),
      ),
    );
  }
}
