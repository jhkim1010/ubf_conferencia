import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/constants/world_countries.dart';
import '../../../core/utils/media_url.dart';

// 남의 명함 한 장. 미리보기와 친구 상세가 같은 것을 보여준다 —
// 따로 만들면 한쪽만 고치게 된다.
class CardView extends StatelessWidget {
  final Map<String, dynamic> card;
  const CardView({super.key, required this.card});

  // 채널은 아이디만 저장돼 있다. 주소는 여기서 만든다 —
  // 그래야 화면에는 @maria.f 로 보이고 눌렀을 때 정식 주소로 열린다.
  static Uri? _channelUri(String kind, String handle) => switch (kind) {
    'instagram' => Uri.parse('https://instagram.com/$handle'),
    'x' => Uri.parse('https://x.com/$handle'),
    'youtube' => Uri.parse(
      handle.startsWith('channel/')
          ? 'https://youtube.com/$handle'
          : 'https://youtube.com/@$handle',
    ),
    _ => null,
  };

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final photo = card['photoUrl'] as String?;
    final bible = card['bibleName'] as String?;
    final contacts = (card['contacts'] as Map?)?.cast<String, dynamic>() ?? {};
    final channels = (card['channels'] as Map?)?.cast<String, dynamic>() ?? {};
    final topics = (card['prayerTopics'] as List?) ?? const [];
    final where = [
      WorldCountries.display(card['country'] as String?) ?? '',
      (card['branch'] as String?) ?? '',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: photo == null
                  ? null
                  : NetworkImage(mediaUrl(photo)),
              child: photo == null ? const Icon(Icons.person_outline) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      card['name'] ?? '',
                      if (bible != null && bible.isNotEmpty) '($bible)',
                    ].join(' '),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (where.isNotEmpty)
                    Text(
                      where,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        if ((card['lifeVerseRef'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['lifeVerseRef'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if ((card['lifeVerseText'] as String?)?.isNotEmpty ?? false)
                  Text(
                    card['lifeVerseText'] as String,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],

        if (topics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.cardPrayerTopics,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          for (final t in topics)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('· $t'),
            ),
        ],

        const SizedBox(height: 14),
        if (contacts.isEmpty && channels.isEmpty)
          Text(
            l10n.cardNoContacts,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (contacts['whatsapp'] != null)
                _btn(
                  Icons.chat_bubble_outline,
                  l10n.cardOpenWhatsapp,
                  () => _open(
                    Uri.parse(
                      'https://wa.me/${'${contacts['whatsapp']}'.replaceAll('+', '')}',
                    ),
                  ),
                ),
              if (contacts['email'] != null)
                _btn(
                  Icons.mail_outline,
                  l10n.cardOpenEmail,
                  () => _open(Uri.parse('mailto:${contacts['email']}')),
                ),
              if (contacts['phone'] != null)
                _btn(
                  Icons.phone_outlined,
                  '${contacts['phone']}',
                  () => _open(Uri.parse('tel:${contacts['phone']}')),
                ),
              for (final e in channels.entries)
                _btn(
                  switch (e.key) {
                    'instagram' => Icons.camera_alt_outlined,
                    'youtube' => Icons.play_circle_outline,
                    _ => Icons.alternate_email,
                  },
                  '@${e.value}',
                  () {
                    final uri = _channelUri(e.key, '${e.value}');
                    if (uri != null) _open(uri);
                  },
                ),
            ],
          ),
      ],
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12.5)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
      );
}
