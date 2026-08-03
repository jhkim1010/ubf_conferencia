import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/media_url.dart';
import '../providers/card_provider.dart';
import 'qr_scan_screen.dart';

// 나눔 친구 목록(031)
//
// **수양회별로 묶는다.** "작년 수양회에서 만난 그 브라질 형제"가 사람을
// 찾는 실제 방식이다. 이름만 나열하면 몇 년 뒤에는 못 찾는다.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(connectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.friendsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: l10n.cardTitle,
            onPressed: () => context.push('/cards/me'),
          ),
        ],
      ),
      floatingActionButton: qrScanSupported
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cards/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.cardScan),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.friendsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }

          // 수양회별로 묶는다. 수양회가 적히지 않은 것은 맨 뒤로 모은다.
          final groups = <String, List<Map<String, dynamic>>>{};
          for (final raw in rows) {
            final r = raw as Map<String, dynamic>;
            final card = r['card'] as Map<String, dynamic>? ?? {};
            final hay = [
              card['name'] ?? '',
              card['bibleName'] ?? '',
              WorldCountries.display(card['country'] as String?) ?? '',
            ].join(' ').toLowerCase();
            if (_q.isNotEmpty && !hay.contains(_q.toLowerCase())) continue;
            final key =
                (r['programName'] as String?) ?? l10n.friendsOtherPrograms;
            groups.putIfAbsent(key, () => []).add(r);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.friendsSearch,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 14),
              for (final g in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(
                    '${g.key} · ${g.value.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                for (final r in g.value) _FriendTile(row: r),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Map<String, dynamic> row;
  const _FriendTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final card = row['card'] as Map<String, dynamic>? ?? {};
    final photo = card['photoUrl'] as String?;
    final where = WorldCountries.display(card['country'] as String?) ?? '';
    final met = '${row['metOn'] ?? ''}'.split('T').first;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: photo == null ? null : NetworkImage(mediaUrl(photo)),
          child: photo == null ? const Icon(Icons.person_outline) : null,
        ),
        title: Text(
          '${card['name'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text([where, met].where((s) => s.isNotEmpty).join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/cards/friend', extra: row),
      ),
    );
  }
}
