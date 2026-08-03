import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/api_client.dart';
import '../providers/card_provider.dart';
import '../widgets/card_view.dart';

// 친구 상세(031)
//
// 기도제목은 **복사가 아니라 연결**이다. 본인이 고치면 여기도 바뀐다 —
// 그래야 계속 기도할 수 있다.
//
// 메모는 **저장한 쪽만** 본다. 상대에게 보이면 아무도 솔직하게 적지 않는다.
class FriendDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> row;
  const FriendDetailScreen({super.key, required this.row});

  @override
  ConsumerState<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends ConsumerState<FriendDetailScreen> {
  late final TextEditingController _note = TextEditingController(
    text: widget.row['note'] as String? ?? '',
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final card = widget.row['card'] as Map<String, dynamic>? ?? {};
    final met = '${widget.row['metOn'] ?? ''}'.split('T').first;

    return Scaffold(
      appBar: AppBar(
        title: Text('${card['name'] ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: l10n.friendsRemove,
            onPressed: () async {
              await ApiClient.deleteConnection(widget.row['id'] as String);
              ref.invalidate(connectionsProvider);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardView(card: card),
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.friendsNote,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) async {
              await ApiClient.updateConnectionNote(
                widget.row['id'] as String,
                v.trim().isEmpty ? null : v.trim(),
              );
              ref.invalidate(connectionsProvider);
            },
          ),
          if (met.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.friendsMetOn(met),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
