import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';
import '../providers/transport_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// PRD F5 — 운행 배차판 (관리자)
// 명부(기사·정원)를 먼저 등록 → 자동/수동으로 승객을 채운다.
class DispatchScreen extends StatelessWidget {
  final String programId;
  const DispatchScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dspTitle),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.flight_land),
                text: l10n.dspTabArrival,
              ),
              Tab(
                icon: const Icon(Icons.flight_takeoff),
                text: l10n.dspTabDeparture,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DispatchTab(programId: programId, direction: 'arrival'),
            _DispatchTab(programId: programId, direction: 'departure'),
          ],
        ),
      ),
    );
  }
}

String _hhmm(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

// member의 항공편에서 편명·시각 라벨
String _flightLabel(Map<String, dynamic> m, String direction) {
  final f =
      (direction == 'arrival' ? m['arrivalFlight'] : m['departureFlight'])
          as Map<String, dynamic>?;
  if (f == null) return '';
  final no = f['flight_no'] as String? ?? '';
  final t = _hhmm(
    direction == 'arrival'
        ? f['scheduled_arrival'] as String?
        : f['scheduled_departure'] as String?,
  );
  return [no, t].where((s) => s.isNotEmpty).join(' · ');
}

class _DispatchTab extends ConsumerWidget {
  final String programId;
  final String direction;
  const _DispatchTab({required this.programId, required this.direction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final key = (programId, direction);
    final async = ref.watch(transportRunsProvider(key));
    void refresh() => ref.invalidate(transportRunsProvider(key));

    Future<void> auto() async {
      try {
        final r = await ApiClient.autoDispatch(programId, direction);
        refresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.dspAutoDone(
                  (r['assigned'] as num).toInt(),
                  (r['unassigned'] as num).toInt(),
                ),
              ),
            ),
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      }
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
      data: (data) {
        final runs = (data['runs'] as List).cast<Map<String, dynamic>>();
        final unassigned = (data['unassigned'] as List)
            .cast<Map<String, dynamic>>();
        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showVanDialog(context, refresh),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.dspAddVan),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: runs.isEmpty ? null : auto,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(l10n.dspAutoDispatch),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 배차 준비. 담당자가 처음 묻는 것은 "차를 몇 대 불러야 하나"
              // 인데, 지금까지 그 답이 화면 어디에도 없었다. 도착 시각은
              // 이미 등록서에 다 있으므로 화면이 먼저 세어 준다.
              _PlanBoard(
                programId: programId,
                direction: direction,
                buckets: ((data['plan'] as List?) ?? const [])
                    .cast<Map<String, dynamic>>(),
                onChanged: refresh,
              ),
              const SizedBox(height: 12),
              _UnassignedCard(
                direction: direction,
                people: unassigned,
                onTap: (p) => _pickVan(context, runs, p, refresh),
              ),
              const SizedBox(height: 12),
              if (runs.isEmpty)
                _emptyHint(Icons.directions_bus_outlined, l10n.dspNoRuns)
              else
                ...runs.map((run) => _vanCard(context, run, refresh)),
            ],
          ),
        );
      },
    );
  }

  Widget _vanCard(
    BuildContext context,
    Map<String, dynamic> run,
    VoidCallback refresh,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final members = (run['members'] as List).cast<Map<String, dynamic>>();
    final cap = (run['capacity'] as num).toInt();
    final driver = run['driver_name'] as String?;
    final vehicle = run['vehicle'] as String?;
    final phone = run['driver_phone'] as String?;
    final depart = _hhmm(run['depart_at'] as String?);
    final full = members.length >= cap;
    final title = [
      vehicle,
      driver ?? l10n.dspDriverUnset,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    final sub = [
      run['airport'] as String? ?? '',
      if (phone != null && phone.isNotEmpty) phone,
      if (depart.isNotEmpty) depart,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_bus,
                  size: 18,
                  color: Color(0xFF0F7A6E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (sub.isNotEmpty)
                        Text(
                          sub,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${members.length}/$cap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: full ? Colors.green : const Color(0xFF0F7A6E),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      _showVanDialog(context, refresh, existing: run);
                    } else if (v == 'delete') {
                      await ApiClient.deleteRun(programId, run['id'] as String);
                      refresh();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.dspDeleteVan),
                    ),
                  ],
                ),
              ],
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: members.map((m) {
                  final label = _flightLabel(m, direction);
                  final name = m['name'] as String? ?? '';
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: const Color(0xFF0F7A6E),
                      child: Text(
                        name.isNotEmpty ? name.characters.first : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    label: Text(
                      label.isEmpty ? name : '$name  $label',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () async {
                      await ApiClient.unassignFromRun(
                        programId,
                        run['id'] as String,
                        registrationId: m['registrationId'] as String?,
                        companionId: m['companionId'] as String?,
                      );
                      refresh();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 미배차 인원을 특정 밴에 수동 배정
  Future<void> _pickVan(
    BuildContext context,
    List<Map<String, dynamic>> runs,
    Map<String, dynamic> person,
    VoidCallback refresh,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (runs.isEmpty) return;
    final runId = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(l10n.dspPickVan),
        children: runs.map((run) {
          final n = (run['members'] as List).length;
          final cap = (run['capacity'] as num).toInt();
          final title = [
            run['vehicle'],
            run['driver_name'],
          ].where((s) => s != null && '$s'.isNotEmpty).join(' · ');
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, run['id'] as String),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_bus,
                  size: 18,
                  color: Color(0xFF0F7A6E),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('${run['airport']} · $title')),
                Text(
                  '$n/$cap',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (runId == null) return;
    try {
      await ApiClient.assignToRun(
        programId,
        runId,
        registrationId: person['registrationId'] as String?,
        companionId: person['companionId'] as String?,
      );
      refresh();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showVanDialog(
    BuildContext context,
    VoidCallback refresh, {
    Map<String, dynamic>? existing,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _VanDialog(existing: existing),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await ApiClient.createRun(programId, {
          'direction': direction,
          ...result,
        });
      } else {
        await ApiClient.updateRun(programId, existing['id'] as String, result);
      }
      refresh();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── 미배차 카드 ───────────────────────────────────────────────
class _UnassignedCard extends StatelessWidget {
  final String direction;
  final List<Map<String, dynamic>> people;
  final void Function(Map<String, dynamic>) onTap;
  const _UnassignedCard({
    required this.direction,
    required this.people,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (people.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              l10n.dspAllAssigned,
              style: TextStyle(color: Colors.green[800]),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dspUnassignedCount(people.length),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.amber[900],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: people.map((p) {
              final name = '${p['name'] ?? ''}';
              final time = _hhmm(p['timeAt'] as String?);
              final label = [name, if (time.isNotEmpty) time].join('  ');
              return ActionChip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.amber[700],
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                label: Text(label, style: const TextStyle(fontSize: 12)),
                onPressed: () => onTap(p),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── 밴(명부) 등록·수정 다이얼로그 ─────────────────────────────
class _VanDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _VanDialog({this.existing});

  @override
  State<_VanDialog> createState() => _VanDialogState();
}

class _VanDialogState extends State<_VanDialog> {
  final _airport = TextEditingController();
  final _vehicle = TextEditingController();
  final _driverName = TextEditingController();
  final _driverPhone = TextEditingController();
  final _capacity = TextEditingController(text: '7');
  final _meetPoint = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _airport.text = e['airport'] as String? ?? '';
      _vehicle.text = e['vehicle'] as String? ?? '';
      _driverName.text = e['driver_name'] as String? ?? '';
      _driverPhone.text = e['driver_phone'] as String? ?? '';
      _capacity.text = '${e['capacity'] ?? 7}';
      _meetPoint.text = e['meet_point'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _airport.dispose();
    _vehicle.dispose();
    _driverName.dispose();
    _driverPhone.dispose();
    _capacity.dispose();
    _meetPoint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.dspNewVan : l10n.dspEditVan),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _airport,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: '${l10n.dspAirport} *',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${l10n.dspCapacityLabel} *',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vehicle,
              decoration: InputDecoration(labelText: l10n.dspVehicle),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _driverName,
              decoration: InputDecoration(
                labelText: '${l10n.dspDriverName} *',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _driverPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.dspDriverPhone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _meetPoint,
              decoration: InputDecoration(
                labelText: l10n.dspMeetPoint,
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: () {
            final airport = _airport.text.trim();
            final driver = _driverName.text.trim();
            final cap = int.tryParse(_capacity.text.trim());
            if (airport.isEmpty || driver.isEmpty || cap == null || cap <= 0) {
              return;
            }
            Navigator.pop(context, {
              'airport': airport,
              'capacity': cap,
              'vehicle': _vehicle.text.trim(),
              'driverName': driver,
              'driverPhone': _driverPhone.text.trim(),
              'meetPoint': _meetPoint.text.trim(),
            });
          },
          child: Text(l10n.actionConfirm),
        ),
      ],
    );
  }
}

Widget _emptyHint(IconData icon, String message) => Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  ),
);

/// 도착 시간대별 필요 차량.
///
/// 묶는 규칙은 서버가 정하고(dispatch_engine.planRuns) 여기서는 그리기만
/// 한다 — 앱이 따로 묶으면 자동 배차가 채우는 것과 어긋난다.
class _PlanBoard extends StatelessWidget {
  final String programId;
  final String direction;
  final List<Map<String, dynamic>> buckets;
  final VoidCallback onChanged;

  const _PlanBoard({
    required this.programId,
    required this.direction,
    required this.buckets,
    required this.onChanged,
  });

  static String _hhmm(Object? iso) {
    final s = '${iso ?? ''}';
    if (s.length < 16) return '';
    return s.substring(11, 16);
  }

  static String _mmdd(Object? iso) {
    final s = '${iso ?? ''}';
    if (s.length < 10) return '';
    return s.substring(5, 10).replaceAll('-', '/');
  }

  Future<void> _make(BuildContext context, Map<String, dynamic> b) async {
    final n = ((b['vans_to_add'] ?? 0) as num).toInt();
    try {
      for (var i = 0; i < n; i++) {
        await ApiClient.createRun(programId, {
          'direction': direction,
          'airport': b['airport'],
          // 첫 승객 도착 시각을 출발 시각의 기본값으로 둔다. 담당자가
          // 고치면 되지만, 비워 두면 명부가 시각 없이 늘어선다.
          'departAt': b['from'],
          'capacity': 7,
          // 이름을 비워 두면 명부에 "(이름 없음)" 이 늘어선다. 시각·공항으로
          // 붙여 두면 어느 묶음의 차인지 바로 보이고, 담당자가 고치면 된다.
          'vehicle': '${_hhmm(b['from'])} ${b['airport'] ?? ''}'.trim(),
        });
      }
      onChanged();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (buckets.isEmpty) {
      return _emptyHint(Icons.schedule, l10n.dspPlanNone);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dspPlanTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        for (final b in buckets)
          Builder(
            builder: (ctx) {
              final add = ((b['vans_to_add'] ?? 0) as num).toInt();
              final have = ((b['run_ids'] as List?) ?? const []).length;
              final people = ((b['people'] ?? 0) as num).toInt();
              final members = ((b['members'] as List?) ?? const [])
                  .cast<Map<String, dynamic>>();
              final from = _hhmm(b['from']);
              final to = _hhmm(b['to']);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: add > 0 ? const Color(0xFFFDF1E6) : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_mmdd(b['from'])} · $from'
                              '${to != from ? ' ~ $to' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            add > 0
                                ? l10n.dspPlanNeed(have + add, add)
                                : l10n.dspPlanOk(have),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: add > 0
                                  ? Colors.orange[900]
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${b['airport'] ?? ''} · ${l10n.dspPlanPeople(people)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      for (final m in members.take(4))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 46,
                                child: Text(
                                  _hhmm(m['timeAt']),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${m['name'] ?? ''}',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                              if (m['assigned'] != true)
                                Text(
                                  l10n.dspUnassignedFlight,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[900],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (add > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton(
                            onPressed: () => _make(context, b),
                            child: Text(l10n.dspMakeVans(add)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
