import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/file_pick.dart';
import '../../../core/utils/media_url.dart';
import '../providers/card_provider.dart';

// 내 명함(031)
//
// 항목마다 스위치가 따로 있다. "원하는 정보만"이 기본이지 예외가 아니다.
// 아무것도 안 켜면 이름과 요절만 보인다.
//
// **19세 이하는 연락 항목이 잠긴다.** 화면에서 감추는 것만으로는 부족해서
// 서버도 같은 판정을 한다 — 예전 앱과 직접 호출은 이 화면을 거치지 않는다.
class MyCardScreen extends ConsumerStatefulWidget {
  const MyCardScreen({super.key});

  @override
  ConsumerState<MyCardScreen> createState() => _MyCardScreenState();
}

class _MyCardScreenState extends ConsumerState<MyCardScreen> {
  final _verseRef = TextEditingController();
  final _verseText = TextEditingController();
  final _topics = TextEditingController();
  final _email = TextEditingController();
  final _whatsapp = TextEditingController();
  final _phone = TextEditingController();
  final _instagram = TextEditingController();
  final _x = TextEditingController();
  final _youtube = TextEditingController();

  bool _showEmail = false;
  bool _showWhatsapp = false;
  bool _showPhone = false;
  bool _showInstagram = false;
  bool _showX = false;
  bool _showYoutube = false;

  String? _photoUrl;
  bool _juniorLocked = false;
  bool _loaded = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _verseRef,
      _verseText,
      _topics,
      _email,
      _whatsapp,
      _phone,
      _instagram,
      _x,
      _youtube,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Map<String, dynamic> c) {
    if (_loaded) return; // 저장 후 다시 그려질 때 사용자가 친 내용을 덮지 않는다
    _loaded = true;
    _verseRef.text = c['life_verse_ref'] as String? ?? '';
    _verseText.text = c['life_verse_text'] as String? ?? '';
    _topics.text = ((c['prayer_topics'] as List?) ?? const [])
        .map((e) => '$e')
        .join('\n');
    _email.text = c['email'] as String? ?? '';
    _whatsapp.text = c['whatsapp'] as String? ?? '';
    _phone.text = c['phone'] as String? ?? '';
    _instagram.text = c['instagram'] as String? ?? '';
    _x.text = c['x_handle'] as String? ?? '';
    _youtube.text = c['youtube'] as String? ?? '';
    _showEmail = c['show_email'] as bool? ?? false;
    _showWhatsapp = c['show_whatsapp'] as bool? ?? false;
    _showPhone = c['show_phone'] as bool? ?? false;
    _showInstagram = c['show_instagram'] as bool? ?? false;
    _showX = c['show_x'] as bool? ?? false;
    _showYoutube = c['show_youtube'] as bool? ?? false;
    _photoUrl = c['photo_url'] as String?;
    _juniorLocked = c['junior_locked'] as bool? ?? false;
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await pickImage();
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final up = await ApiClient.uploadFile(picked.bytes, 'card');
      if (mounted) setState(() => _photoUrl = up['url'] as String?);
    } catch (e) {
      if (mounted) _snack(l10n.photoUploadFailed('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ApiClient.saveMyCard({
        'photoUrl': _photoUrl,
        'lifeVerseRef': _verseRef.text.trim(),
        'lifeVerseText': _verseText.text.trim(),
        'prayerTopics': _topics.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'email': _email.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'phone': _phone.text.trim(),
        'instagram': _instagram.text.trim(),
        'x': _x.text.trim(),
        'youtube': _youtube.text.trim(),
        'showEmail': _showEmail,
        'showWhatsapp': _showWhatsapp,
        'showPhone': _showPhone,
        'showInstagram': _showInstagram,
        'showX': _showX,
        'showYoutube': _showYoutube,
      });
      ref.invalidate(myCardProvider);
      if (mounted) _snack(l10n.commonSaved);
    } catch (e) {
      if (mounted) _snack(l10n.commonErrorDetail('$e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(myCardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: l10n.cardPrivacyTitle,
            onPressed: () => context.push('/cards/privacy'),
          ),
          TextButton(
            onPressed: _busy ? null : _save,
            child: Text(l10n.actionSave),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (card) {
          _fill(card);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                l10n.cardShareIntro,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: _photoUrl == null
                          ? null
                          : NetworkImage(mediaUrl(_photoUrl!)),
                      child: _photoUrl == null
                          ? const Icon(Icons.person_outline, size: 36)
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(l10n.cardChangePhoto),
                    ),
                  ],
                ),
              ),

              _field(_verseRef, l10n.cardVerseRef, hint: l10n.cardVerseRefHint),
              _field(_verseText, l10n.cardVerseText, lines: 2),
              _field(
                _topics,
                l10n.cardPrayerTopics,
                hint: l10n.cardPrayerHint,
                lines: 3,
              ),

              const SizedBox(height: 8),
              if (_juniorLocked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l10n.cardJuniorLocked)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              _sectionLabel(l10n.cardContacts),
              _switchField(
                _email,
                l10n.cardEmail,
                _showEmail,
                (v) => setState(() => _showEmail = v),
                locked: _juniorLocked,
              ),
              _switchField(
                _whatsapp,
                l10n.cardWhatsapp,
                _showWhatsapp,
                (v) => setState(() => _showWhatsapp = v),
                locked: _juniorLocked,
              ),
              _switchField(
                _phone,
                l10n.cardPhone,
                _showPhone,
                (v) => setState(() => _showPhone = v),
                locked: _juniorLocked,
              ),

              const SizedBox(height: 8),
              _sectionLabel(l10n.cardChannels),
              _switchField(
                _instagram,
                l10n.cardInstagram,
                _showInstagram,
                (v) => setState(() => _showInstagram = v),
              ),
              _switchField(
                _x,
                l10n.cardX,
                _showX,
                (v) => setState(() => _showX = v),
              ),
              _switchField(
                _youtube,
                l10n.cardYoutube,
                _showYoutube,
                (v) => setState(() => _showYoutube = v),
              ),

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push('/cards/qr'),
                icon: const Icon(Icons.qr_code_2),
                label: Text(l10n.cardShowQr),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/cards/scan'),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l10n.cardScan),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
    child: Text(t, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  );

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  // 값과 스위치를 나란히 둔다. 껐다고 값을 지우지 않는다 —
  // 다시 켤 때 처음부터 적어야 하면 아무도 켜지 않는다.
  Widget _switchField(
    TextEditingController c,
    String label,
    bool on,
    ValueChanged<bool> onChanged, {
    bool locked = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: c,
            enabled: !locked,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Switch(
          value: locked ? false : on,
          onChanged: locked ? null : onChanged,
        ),
      ],
    ),
  );
}
