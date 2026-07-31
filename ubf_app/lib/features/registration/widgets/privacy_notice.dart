import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

// 개인정보 수집·이용 안내 (등록 첫 단계 상단)
//
// 이 앱은 이름·나이·소속에 더해 질병 정보와 SOS 위치까지 다루고, 데이터는
// 참석자의 거주 국가 밖(미국)에 저장된다. 무엇이 어디로 가는지 알리지 않고
// 받는 것은 옳지 않다.
//
// 접힌 상태에서는 한 줄 요약만 보여 등록 흐름을 방해하지 않고,
// 펼치면 수집 항목·목적·열람 범위·보관 위치·기간·권리를 모두 보여준다.
class PrivacyNotice extends StatefulWidget {
  const PrivacyNotice({super.key});

  @override
  State<PrivacyNotice> createState() => _PrivacyNoticeState();
}

class _PrivacyNoticeState extends State<PrivacyNotice> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.privacyTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.privacySummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            _Section(l10n.privacyWhatTitle, l10n.privacyWhat),
            _Section(l10n.privacyWhyTitle, l10n.privacyWhy),
            _Section(l10n.privacyWhoTitle, l10n.privacyWho),
            // 국가 간 이전은 참석자가 알아야 할 사항이라 강조한다
            _Section(
              l10n.privacyWhereTitle,
              l10n.privacyWhere,
              emphasize: true,
            ),
            _Section(l10n.privacyKeepTitle, l10n.privacyKeep),
            _Section(l10n.privacyRightsTitle, l10n.privacyRights),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _expanded ? l10n.privacyLess : l10n.privacyMore,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final bool emphasize;

  const _Section(this.title, this.body, {this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasize
                  ? const Color(0xFFB26A00)
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[800],
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
