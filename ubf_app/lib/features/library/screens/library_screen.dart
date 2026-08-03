import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/file_pick.dart';
import '../providers/library_provider.dart';

// 수양회 자료실(030)
//
// 담당자가 교재·순서지 PDF 를 올리고 참가자가 언제든 다시 본다.
// 종이는 잃어버리고, 단톡방에 올린 파일은 위로 밀려 사라진다.
//
// 같은 화면을 담당자와 참가자가 함께 쓴다. [isAdmin] 이 참이면 숨긴 자료까지
// 보이고 올리기·지우기가 붙는다. 화면을 둘로 나누면 목록 모양을 두 번
// 손봐야 하고, 그러다 한쪽만 고치게 된다.
class LibraryScreen extends ConsumerStatefulWidget {
  final String programId;
  final bool isAdmin;

  const LibraryScreen({
    super.key,
    required this.programId,
    this.isAdmin = false,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _busy = false;

  LibraryArgs get _args => (programId: widget.programId, all: widget.isAdmin);

  void _refresh() => ref.invalidate(programLibraryProvider(_args));

  Future<void> _open(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final uri = Uri.parse(mediaUrl(item['file_url'] as String));
      // 앱 안에 PDF 뷰어를 넣지 않는다. 기기의 기본 뷰어가 더 낫고,
      // 뷰어를 넣으면 다섯 플랫폼 빌드가 그만큼 무거워진다.
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception(uri.toString());
    } catch (e) {
      if (mounted) _snack(l10n.libOpenFailed('$e'), error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context)!;

    // PDF 는 웹에서만 고른다(file_pick.dart 참조). 여기서 버튼을 누르게 두고
    // 아무 일도 안 일어나면 고장으로 읽히므로, 왜 안 되는지 말해 준다.
    if (!canPickPdf) {
      _snack(l10n.libPickOnWeb);
      return;
    }

    final picked = await pickPdf();
    if (picked == null || !mounted) return;

    final title = await _askTitle(picked.name);
    if (title == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final up = await ApiClient.uploadFile(picked.bytes, 'library');
      await ApiClient.addLibraryItem(widget.programId, {
        'title': title,
        'fileUrl': up['url'],
        'mime': up['mime'],
        'bytes': up['bytes'],
      });
      _refresh();
    } catch (e) {
      if (mounted) _snack(l10n.libUploadFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 제목을 먼저 묻고 나서 올린다. 올린 뒤에 물으면, 제목을 안 적고 닫았을 때
  /// 아무 데도 안 붙은 파일이 서버에 남는다.
  Future<String?> _askTitle(String fileName) async {
    final l10n = AppLocalizations.of(context)!;
    // 파일명을 기본값으로 준다 — 대개 그대로 쓸 만하고, 아니면 고치면 된다.
    final c = TextEditingController(
      text: fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
    );
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.libItemTitle),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.libItemTitleHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              final t = c.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(ctx, t);
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.libDeleteTitle),
        content: Text(l10n.libDeleteBody(item['title'] as String? ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await ApiClient.deleteLibraryItem(widget.programId, item['id'] as String);
    _refresh();
  }

  Future<void> _togglePublished(Map<String, dynamic> item) async {
    await ApiClient.updateLibraryItem(widget.programId, item['id'] as String, {
      'isPublished': !(item['is_published'] as bool? ?? true),
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(programLibraryProvider(_args));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.libTitle)),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _add,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_busy ? l10n.libUploading : l10n.libAdd),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  widget.isAdmin ? l10n.libEmptyAdmin : l10n.libEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  l10n.libSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                for (final raw in items)
                  _ItemCard(
                    item: raw as Map<String, dynamic>,
                    isAdmin: widget.isAdmin,
                    onOpen: () => _open(raw),
                    onDelete: () => _delete(raw),
                    onTogglePublished: () => _togglePublished(raw),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isAdmin;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublished;

  const _ItemCard({
    required this.item,
    required this.isAdmin,
    required this.onOpen,
    required this.onDelete,
    required this.onTogglePublished,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hidden = isAdmin && item['is_published'] == false;
    final kb = ((item['bytes'] as num?)?.toInt() ?? 0) ~/ 1000;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.picture_as_pdf_outlined,
          color: hidden ? Colors.grey : theme.colorScheme.primary,
        ),
        title: Text(
          item['title'] as String? ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: hidden ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          [
            if (kb > 0) l10n.libSize(kb),
            if (hidden) l10n.libHidden,
            if ((item['description'] as String?)?.isNotEmpty ?? false)
              item['description'] as String,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onOpen,
        trailing: isAdmin
            ? PopupMenuButton<String>(
                onSelected: (v) =>
                    v == 'delete' ? onDelete() : onTogglePublished(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(hidden ? l10n.libPublished : l10n.libHidden),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.actionDelete),
                  ),
                ],
              )
            : const Icon(Icons.open_in_new, size: 18),
      ),
    );
  }
}
