import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/api_client.dart';
import '../providers/card_provider.dart';

// 나눔 설정(031)
//
// **준 것을 돌려받을 수 있어야 마음 놓고 준다.** 누가 내 명함을 갖고 있는지
// 보이고, 하나씩 끊을 수 있다.
class CardPrivacyScreen extends ConsumerWidget {
  const CardPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final savedBy = ref.watch(savedByProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cardPrivacyTitle)),
      body: savedBy.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (rows) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.cardSavedBy(rows.length),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text(
                l10n.cardSavedByEmpty,
                style: TextStyle(color: Colors.grey[600]),
              ),
            for (final raw in rows)
              _SavedByTile(row: raw as Map<String, dynamic>),
          ],
        ),
      ),
    );
  }
}

class _SavedByTile extends ConsumerWidget {
  final Map<String, dynamic> row;
  const _SavedByTile({required this.row});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final met = '${row['metOn'] ?? ''}'.split('T').first;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${row['name'] ?? ''}'),
        subtitle: Text(
          [
            row['programName'] ?? '',
            met,
          ].where((s) => '$s'.isNotEmpty).join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 저장은 한쪽 방향이다 — QR 을 든 사람은 상대를 갖고 있지 않다.
            // 여기서 한 번 누르면 서로 갖게 된다.
            if (row['savedBack'] != true)
              TextButton(
                onPressed: () async {
                  await ApiClient.saveConnection(
                    friendUserId: row['userId'] as String,
                  );
                  ref.invalidate(connectionsProvider);
                  ref.invalidate(savedByProvider);
                },
                child: Text(l10n.cardSaveBack),
              ),
            TextButton(
              onPressed: () async {
                await ApiClient.revokeSavedBy(row['id'] as String);
                ref.invalidate(savedByProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.cardRevokeDone)));
                }
              },
              child: Text(
                l10n.cardRevoke,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
