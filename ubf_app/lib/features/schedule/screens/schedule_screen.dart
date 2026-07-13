import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// 프로그램 일정 화면
// - 관리자(admin/director): 일정 추가/삭제/타임존 변경 가능
// - 참가자: 읽기 전용
class ScheduleScreen extends ConsumerStatefulWidget {
  final String programId;

  const ScheduleScreen({super.key, required this.programId});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  // 디바이스 타임존 (일정 추가 시 기본값으로 사용)
  String _deviceTimezone = 'UTC';

  @override
  void initState() {
    super.initState();
    _loadDeviceTimezone();
    _load();
  }

  // 디바이스 타임존 자동 감지
  Future<void> _loadDeviceTimezone() async {
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      if (mounted) setState(() => _deviceTimezone = tz);
    } catch (_) {
      // 감지 실패 시 UTC 유지
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.getSchedules(widget.programId);
      setState(() => _schedules = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.schLoadFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final tzCtrl    = TextEditingController(text: _deviceTimezone);
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.schAddTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: l10n.schTitleLabel, hintText: l10n.schTitleHint),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: l10n.schDescLabel),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(pickedDate == null
                      ? l10n.epPickDate
                      : DateFormat('yyyy.MM.dd').format(pickedDate!)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setS(() => pickedDate = d);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(pickedTime == null
                      ? l10n.schPickTime
                      : pickedTime!.format(ctx)),
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) setS(() => pickedTime = t);
                  },
                ),
                const SizedBox(height: 16),
                // 타임존: 디바이스 타임존으로 자동 설정, 수정 가능
                TextField(
                  controller: tzCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.schTimezone,
                    hintText: 'Asia/Seoul',
                    helperText: l10n.schTzAuto,
                    prefixIcon: const Icon(Icons.public, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: l10n.schTzReset,
                      onPressed: () => tzCtrl.text = _deviceTimezone,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || pickedDate == null || pickedTime == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.schAllRequired)),
                  );
                  return;
                }
                final dt = DateTime(
                  pickedDate!.year, pickedDate!.month, pickedDate!.day,
                  pickedTime!.hour, pickedTime!.minute,
                );
                try {
                  await ApiClient.createSchedule(widget.programId, {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    'scheduledAt': dt.toUtc().toIso8601String(),
                    'timezone': tzCtrl.text.trim().isEmpty ? _deviceTimezone : tzCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.schAddFailed('$e'))),
                    );
                  }
                }
              },
              child: Text(l10n.actionAdd),
            ),
          ],
        ),
      ),
    );
  }

  // 관리자: 타임존 변경 다이얼로그
  Future<void> _showTimezoneEditDialog(Map<String, dynamic> schedule) async {
    final l10n = AppLocalizations.of(context)!;
    final tzCtrl = TextEditingController(text: schedule['timezone'] as String? ?? 'UTC');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.schTzChangeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tzCtrl,
              decoration: InputDecoration(
                labelText: l10n.schTimezone,
                hintText: 'Asia/Seoul',
                prefixIcon: const Icon(Icons.public, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, size: 18),
                  tooltip: l10n.schTzUseDevice,
                  onPressed: () => tzCtrl.text = _deviceTimezone,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.schTzExamples,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newTz = tzCtrl.text.trim();
    if (newTz.isEmpty || newTz == schedule['timezone']) return;

    try {
      await ApiClient.updateSchedule(widget.programId, schedule['id'] as String, {
        'timezone': newTz,
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.schTzChangeFailed('$e'))),
        );
      }
    }
  }

  Future<void> _delete(String scheduleId) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.schDeleteTitle),
        content: Text(l10n.schDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiClient.deleteSchedule(widget.programId, scheduleId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.schDeleteFailed('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentUserProvider).isAdmin;
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('MM/dd(E) HH:mm', Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.regScheduleTooltip)),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'add_schedule',
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: Text(l10n.schAddTitle),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _schedules.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.schEmpty,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _schedules.length,
                      itemBuilder: (_, i) {
                        final s = _schedules[i] as Map<String, dynamic>;
                        final scheduledAt = DateTime.parse(s['scheduled_at']).toLocal();
                        final isPast = scheduledAt.isBefore(DateTime.now());
                        final timezone = s['timezone'] as String? ?? 'UTC';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.grey[200]
                                    : Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${scheduledAt.month}/${scheduledAt.day}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isPast ? Colors.grey : Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isPast ? Colors.grey : Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Text(
                              s['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isPast ? Colors.grey[500] : null,
                                decoration: isPast ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (s['description'] != null)
                                  Text(s['description'] as String),
                                Text(
                                  fmt.format(scheduledAt),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                                // 타임존 표시 (관리자는 탭으로 변경 가능)
                                GestureDetector(
                                  onTap: isAdmin ? () => _showTimezoneEditDialog(s) : null,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.public, size: 11, color: Colors.grey[400]),
                                      const SizedBox(width: 3),
                                      Text(
                                        timezone,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                      ),
                                      if (isAdmin) ...[
                                        const SizedBox(width: 3),
                                        Icon(Icons.edit, size: 11, color: Colors.grey[400]),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: isAdmin
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _delete(s['id'] as String),
                                  )
                                : (s['notification_sent'] == true
                                    ? const Icon(Icons.notifications_active,
                                        color: Colors.green, size: 18)
                                    : null),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
