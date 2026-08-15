import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../program/providers/program_provider.dart';
import '../../../core/utils/export_service.dart';
import 'package:mana/l10n/app_localizations.dart';
import 'roster_table_screen.dart';
import 'tour_signups_screen.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/service_role_label.dart';
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

            // 담당자가 이 수양회에서 할 수 있는 일들.
            //
            // 여덟 개를 한 줄에 하나씩 쌓으면 큰 화면에서 화면 하나를 통째로
            // 쓰면서도 절반이 빈 채로 남고, 아래쪽 것은 스크롤해야 보인다.
            // 넓으면 세 개씩 늘어놓는다.
            _MenuGrid(
              items: [
                (
                  icon: Icons.fact_check_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  title: l10n.rdyOpenCard,
                  subtitle: l10n.rdyOpenCardSub,
                  onTap: () =>
                      context.push('/leader/program/$programId/readiness'),
                ),
                (
                  icon: Icons.dashboard_customize_outlined,
                  color: Colors.indigo,
                  title: l10n.setupTitle,
                  subtitle: l10n.dashSetupSubtitle,
                  onTap: () => context.push('/leader/program/$programId/setup'),
                ),
                // 담당자도 참석자다. 이 수양회를 열어 둔 채로 자기 등록을
                // 바로 열 수 있어야 한다.
                (
                  icon: Icons.how_to_reg_outlined,
                  color: Colors.teal,
                  title: l10n.homeAlsoAttending,
                  subtitle: l10n.homeAlsoAttendingSub,
                  onTap: () => context.push('/registration/$programId'),
                ),
                (
                  icon: Icons.folder_copy_outlined,
                  color: Colors.deepOrange,
                  title: l10n.libTitle,
                  subtitle: l10n.dashLibrarySubtitle,
                  onTap: () =>
                      context.push('/leader/program/$programId/library'),
                ),
                (
                  icon: Icons.campaign_outlined,
                  color: Colors.amber,
                  title: l10n.annTitle,
                  subtitle: l10n.dashAnnounceSub,
                  onTap: () =>
                      context.push('/leader/program/$programId/notify'),
                ),
                (
                  icon: Icons.admin_panel_settings_outlined,
                  color: Colors.blueGrey,
                  title: l10n.dashAdmins,
                  subtitle: l10n.dashAdminsSub,
                  onTap: () =>
                      context.push('/leader/program/$programId/admins'),
                ),
                (
                  icon: Icons.assignment_ind_outlined,
                  color: Colors.green,
                  title: l10n.asnTitle,
                  subtitle: l10n.dashAssignSubtitle,
                  onTap: () =>
                      context.push('/leader/program/$programId/assign'),
                ),
                (
                  icon: Icons.directions_bus_outlined,
                  color: Colors.brown,
                  title: l10n.dspTitle,
                  subtitle: l10n.dashDispatchSubtitle,
                  onTap: () =>
                      context.push('/leader/program/$programId/dispatch'),
                ),
              ],
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

            // 참가자 목록은 여기 두지 않는다. 맨 위 "총 등록" 카드가 이미
            // 같은 사람들을 보여 주고, 눌러서 표로 여니 아래에 다섯 명을
            // 다시 늘어놓을 이유가 없다 — 스크롤만 길어진다.

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

/// 담당자 메뉴를 넓으면 세 개씩, 좁으면 한 개씩.
///
/// 항목마다 Card 를 손으로 늘어놓다가 목록으로 바꿨다 — 여덟 개가 같은
/// 모양인데 코드가 여덟 벌이면 하나만 고치고 나머지를 잊는다.
typedef _MenuItem = ({
  IconData icon,
  Color color,
  String title,
  String subtitle,
  VoidCallback onTap,
});

class _MenuGrid extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // 한 칸이 280 아래로 내려가면 제목이 두 줄로 접힌다.
        final columns = (box.maxWidth / 300).floor().clamp(1, 3);
        if (columns == 1) {
          return Column(
            children: [
              for (final it in items) ...[
                _MenuCard(item: it),
                const SizedBox(height: 10),
              ],
            ],
          );
        }
        const gap = 10.0;
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final it in items)
              SizedBox(
                width: width,
                child: _MenuCard(item: it),
              ),
          ],
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: item.onTap,
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
    // 미리보기는 숫자와 같은 응답에서 온다. 따로 조회하면 카드 숫자와
    // 미리보기가 어긋날 자리가 또 생긴다 — 이미 두 번 겪었다.
    final preview = (stats!['preview'] as Map?) ?? const {};
    List<Map<String, dynamic>> rows(String key) =>
        ((preview[key] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .toList();

    /// 봉사 줄은 역할 이름과 확정/필요를 보여 준다. 다 채운 역할은
    /// 크림색을 쓰지 않는다 — 크림색은 "아직 안 끝난" 쪽이다.
    ///
    /// 역할에 필요 인원을 아직 아무것도 안 잡아 뒀으면 보여 줄 역할 줄이
    /// 없다. 그때 미리보기를 비워 두면 카드가 "5명" 위에 "아직 없습니다" 를
    /// 띄워, 자원자가 없다는 뜻으로 읽힌다 — 실제로 그렇게 읽혔다.
    /// 그런 경우에는 **자원한 사람**을 대신 보여 준다.
    List<Map<String, dynamic>> serviceRows() {
      final roles = rows('services');
      if (roles.isNotEmpty) {
        return [
          for (final x in roles)
            {
              'name': serviceRoleLabel(l10n, x),
              'country': null,
              'detail': l10n.dashRoleFilled(
                ((x['filled'] ?? 0) as num).toInt(),
                ((x['needed'] ?? 0) as num).toInt(),
              ),
              'submitted': ((x['short'] ?? 0) as num).toInt() == 0,
            },
        ];
      }
      return [
        for (final v in rows('volunteers'))
          () {
            final assigned = ((v['assigned'] ?? 0) as num).toInt();
            return {
              'name': v['name'],
              'country': v['country'],
              // "자원했다" 와 "맡았다" 는 다른 말이다. 줄마다 분명히 하지
              // 않으면, 자원자 5명 옆의 빈 자리가 자원자가 없다는 뜻으로
              // 읽힌다.
              'detail': assigned > 0
                  ? l10n.dashAssignedCount(assigned)
                  : l10n.dashNotAssigned,
              // 아직 아무것도 안 맡은 사람이 크림색이다 — 다른 화면과 같은
              // 뜻으로, 담당자가 손대야 할 줄이다.
              'submitted': assigned > 0,
            };
          }(),
      ];
    }

    // 카드 크기를 화면 너비에 비례해 늘리지 않는다.
    //
    // 예전에는 2열 고정에 childAspectRatio 로 높이를 정했더니, 컴퓨터
    // 브라우저에서 카드 하나가 화면 절반(940×620)이 됐다. 숫자 하나 보여
    // 주는 칸이 그만큼 클 이유가 없다.
    //
    // 이제 열 수만 너비에 맞춰 늘리고 **높이는 어디서나 116** 이다.
    // 너비는 MediaQuery 가 아니라 실제 제약을 쓴다 — 바깥 여백만큼 어긋난다.
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 12.0;
        const cardHeight = 214.0;
        final columns = (box.maxWidth / 300).floor().clamp(1, 4);
        final cardWidth = (box.maxWidth - (columns - 1) * gap) / columns;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cardWidth / cardHeight,
          children: [
            _StatCard(
              label: l10n.dashStatTotal,
              total: n('total_registrations'),
              preview: rows('recent'),
              value: l10n.unitPeople(n('total_registrations')),
              icon: Icons.people,
              color: Colors.blue,
              onOpen: () => _openTable(context, programId, RosterView.all),
            ),
            // "등록 완료" 카드가 있던 자리. 완료 여부는 참가자 표 안에서 한
            // 사람씩 노란 줄로 보이므로 카드 하나를 통째로 쓸 일이 아니었고,
            // 담당자가 급히 알아야 하는 것은 어느 투어가 얼마나 찼는가였다.
            _StatCard(
              label: l10n.dashStatTours,
              tourPreview: rows('tours'),
              value: l10n.unitPeople(n('tour_signup_count')),
              icon: Icons.tour,
              color: Colors.green,
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TourSignupsScreen(programId: programId),
                ),
              ),
            ),
            _StatCard(
              label: l10n.dashStatFoodRestriction,
              total: n('food_restriction_count'),
              preview: rows('meals'),
              value: l10n.unitPeople(n('food_restriction_count')),
              icon: Icons.restaurant,
              color: Colors.orange,
              onOpen: () => _openTable(context, programId, RosterView.meals),
            ),
            // 입금 카드는 두지 않는다. 입금은 이제 참가자 표 안에서
            // 사람마다 적고 고치므로(053), 같은 것을 카드로 한 번 더
            // 보여 주면 어느 쪽이 최신인지 헷갈릴 뿐이다.
            // 봉사. 큰 숫자는 **자원자 수** 다 — 등록할 때 "할 수 있다" 고
            // 적어 낸 사람. 역할을 맡은 것은 아니고, 누구에게 맡길지는
            // 담당자가 정한다. 미리보기에는 역할별 확정/필요를 보여 준다.
            _StatCard(
              label: l10n.dashStatVolunteers,
              total: n('volunteer_count'),
              preview: serviceRows(),
              value: l10n.unitPeople(n('volunteer_count')),
              openLabel: l10n.dashOpenService,
              icon: Icons.volunteer_activism_outlined,
              color: Colors.pink,
              onOpen: () =>
                  context.push('/leader/program/$programId/assign?tab=2'),
            ),
            _StatCard(
              label: l10n.dashStatArrival,
              total: n('arrival_flight_count'),
              preview: rows('arrival'),
              value: l10n.unitPeople(n('arrival_flight_count')),
              icon: Icons.flight_land,
              color: Colors.purple,
              onOpen: () => _openTable(context, programId, RosterView.arrival),
            ),
          ],
        );
      },
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

  /// 카드 안에 보여 줄 사람 몇 줄. [{name, country, submitted, detail}]
  final List<Map<String, dynamic>> preview;

  /// 투어 카드만 사람 대신 투어별 줄을 보여 준다 — 담당자가 먼저 보는 것이
  /// "어느 투어가 찼나" 이기 때문이다. [{name, signup_count, capacity}]
  final List<Map<String, dynamic>> tourPreview;

  /// 미리보기에 다 못 담은 나머지 수. "나머지 n명 보기" 로 쓴다.
  final int total;

  /// 아래 링크 문구를 바꿔야 할 때. 봉사 카드는 표가 아니라 배정 화면을
  /// 열므로 "표로 보기" 라고 하면 거짓말이 된다.
  final String? openLabel;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onOpen,
    this.preview = const [],
    this.tourPreview = const [],
    this.total = 0,
    this.openLabel,
  });

  /// 아직 등록을 완료하지 않은 사람의 배경. 표·투어 명단과 같은 크림색이다.
  static Color _cream(ThemeData theme) => theme.brightness == Brightness.dark
      ? const Color(0xFF3E3524)
      : const Color(0xFFFFF8E7);

  Widget _line(
    BuildContext context, {
    required String who,
    String where = '',
    String state = '',
    bool cream = false,
    bool good = true,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: cream
          ? BoxDecoration(
              color: _cream(theme),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              who,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          if (where.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              where,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
          if (state.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              state,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: good ? Colors.green[700] : Colors.orange[900],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTour = tourPreview.isNotEmpty;
    final shown = isTour ? tourPreview.length : preview.length;
    final rest = total - shown;

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              if (onOpen != null) ...[
                const Spacer(),
                Icon(Icons.open_in_full, size: 13, color: Colors.grey[400]),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 6),
          // 남는 자리에 미리보기를 넣는다. 넘치면 잘라 낸다 — 카드 높이는
          // 어디서나 같아야 한다.
          Expanded(
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTour)
                    for (final t in tourPreview)
                      Builder(
                        builder: (ctx) {
                          final n = (t['signup_count'] as num?)?.toInt() ?? 0;
                          final cap = (t['capacity'] as num?)?.toInt();
                          final full = cap != null && n >= cap;
                          return _line(
                            ctx,
                            who: '${t['name'] ?? ''}',
                            where: l10n.dashUnitPeopleShort(n),
                            state: n == 0
                                ? l10n.dashTourNobody
                                : (full
                                      ? l10n.dashTourFull
                                      : l10n.dashTourRoom),
                            cream: n == 0,
                            good: !full && n > 0,
                          );
                        },
                      )
                  else if (preview.isEmpty)
                    Text(
                      l10n.dashPreviewEmpty,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    )
                  else
                    for (final p in preview)
                      _line(
                        context,
                        who: '${p['name'] ?? ''}',
                        where:
                            WorldCountries.display(p['country'] as String?) ??
                            '',
                        state: '${p['detail'] ?? ''}',
                        cream: p['submitted'] == false,
                        good: p['submitted'] != false,
                      ),
                ],
              ),
            ),
          ),
          if (onOpen != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  openLabel ??
                      (isTour
                          ? l10n.dashByTour
                          : (rest > 0
                                ? l10n.dashMoreCount(rest)
                                : l10n.dashSeeAll)),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );

    if (onOpen == null) return Card(child: body);

    // 두 번 누르기·길게 누르기는 그대로 두고, 아래 "더 보기" 를 더했다.
    // 두 번 누르기만 있으면 그 사실을 아는 사람만 열 수 있다.
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
