import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/api_client.dart';
import '../../providers/buddy_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// PRD F3 — 룸메이트·말씀조 지목(요청) + 받은 요청 수락/거절
class BuddyStep extends ConsumerStatefulWidget {
  final String programId;
  final bool enabled;

  const BuddyStep({super.key, required this.programId, this.enabled = true});

  @override
  ConsumerState<BuddyStep> createState() => _BuddyStepState();
}

class _BuddyStepState extends ConsumerState<BuddyStep> {
  String _query = '';

  void _refresh() {
    ref.invalidate(myBuddyRequestsProvider(widget.programId));
    ref.invalidate(buddyCandidatesProvider(widget.programId));
  }

  Future<void> _send(String toId, String kind) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.sendBuddyRequest(widget.programId, toId, kind);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.buddyReqSent)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _respond(String id, String action) async {
    try {
      await ApiClient.respondBuddyRequest(widget.programId, id, action);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.enabled) {
      return Center(child: Text(l10n.sectionDisabled));
    }

    final candidatesAsync = ref.watch(buddyCandidatesProvider(widget.programId));
    final requestsAsync = ref.watch(myBuddyRequestsProvider(widget.programId));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.buddyTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(l10n.buddyDesc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),

        // ── 받은 요청 (수락/거절) ─────────────────────────────
        requestsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (data) {
            final received = (data['received'] as List? ?? [])
                .where((r) => r['status'] == 'pending')
                .toList();
            if (received.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(l10n.buddyReceivedSection),
                ...received.map((r) => _ReceivedCard(
                      req: r,
                      onAccept: () => _respond(r['id'] as String, 'accept'),
                      onDecline: () => _respond(r['id'] as String, 'decline'),
                    )),
                const SizedBox(height: 12),
              ],
            );
          },
        ),

        // ── 내가 보낸 요청 (상태) ─────────────────────────────
        requestsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (data) {
            final sent = (data['sent'] as List? ?? []);
            if (sent.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(l10n.buddySentSection),
                ...sent.map((r) => _SentTile(req: r)),
                const SizedBox(height: 12),
              ],
            );
          },
        ),

        // ── 후보 검색 + 지목 ─────────────────────────────────
        TextField(
          decoration: InputDecoration(
            hintText: l10n.buddySearchHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.buddyRoommateSameGenderNote,
                    style: TextStyle(fontSize: 12, color: Colors.amber[900])),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        candidatesAsync.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          error: (e, _) => Text(l10n.commonErrorDetail('$e')),
          data: (candidates) {
            final filtered = candidates.where((c) {
              if (_query.isEmpty) return true;
              final name = ('${c['real_name'] ?? ''} ${c['bible_name'] ?? ''}').toLowerCase();
              return name.contains(_query);
            }).toList();
            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text(l10n.buddyNoCandidates,
                    style: TextStyle(color: Colors.grey[500]))),
              );
            }
            return Column(
              children: filtered.map((c) => _CandidateTile(
                    candidate: c,
                    onRoommate: () => _send(c['id'] as String, 'roommate'),
                    onGroup: () => _send(c['id'] as String, 'group'),
                  )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );
}

String _kindLabel(String kind, AppLocalizations l10n) =>
    kind == 'roommate' ? l10n.buddyKindRoommate : l10n.buddyKindGroup;

Color _genderColor(String? g) => g == 'M'
    ? const Color(0xFF3B6FB0)
    : (g == 'F' ? const Color(0xFFB0547E) : Colors.grey);

Widget _avatar(String? name, String? gender) => CircleAvatar(
      radius: 16,
      backgroundColor: _genderColor(gender),
      child: Text(
        (name != null && name.isNotEmpty) ? name.characters.first : '?',
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );

class _CandidateTile extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final VoidCallback onRoommate;
  final VoidCallback onGroup;
  const _CandidateTile({
    required this.candidate,
    required this.onRoommate,
    required this.onGroup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = candidate['real_name'] as String? ?? '';
    final sub = [candidate['branch'], candidate['country']]
        .where((e) => e != null && '$e'.isNotEmpty).join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            _avatar(name, candidate['gender'] as String?),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (sub.isNotEmpty)
                    Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.buddySendRoommate,
              icon: const Icon(Icons.meeting_room_outlined, size: 20),
              onPressed: onRoommate,
            ),
            IconButton(
              tooltip: l10n.buddySendGroup,
              icon: const Icon(Icons.groups_outlined, size: 20),
              onPressed: onGroup,
            ),
          ],
        ),
      ),
    );
  }
}

class _SentTile extends StatelessWidget {
  final Map<String, dynamic> req;
  const _SentTile({required this.req});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = req['status'] as String;
    final (label, color) = switch (status) {
      'accepted' => (l10n.buddyStatusAccepted, Colors.green),
      'declined' => (l10n.buddyStatusDeclined, Colors.grey),
      _ => (l10n.buddyStatusPending, Colors.orange),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: _avatar(req['otherName'] as String?, req['otherGender'] as String?),
        title: Text(req['otherName'] as String? ?? ''),
        subtitle: Text(l10n.buddyRequestLine(_kindLabel(req['kind'] as String, l10n)),
            style: const TextStyle(fontSize: 11)),
        trailing: Chip(
          label: Text(label, style: TextStyle(fontSize: 11, color: color)),
          backgroundColor: color.withValues(alpha: 0.1),
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

class _ReceivedCard extends StatelessWidget {
  final Map<String, dynamic> req;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _ReceivedCard({
    required this.req,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _avatar(req['otherName'] as String?, req['otherGender'] as String?),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(req['otherName'] as String? ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(l10n.buddyRequestLine(_kindLabel(req['kind'] as String, l10n)),
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            TextButton(onPressed: onDecline, child: Text(l10n.buddyDecline)),
            FilledButton(onPressed: onAccept, child: Text(l10n.buddyAccept)),
          ],
        ),
      ),
    );
  }
}
