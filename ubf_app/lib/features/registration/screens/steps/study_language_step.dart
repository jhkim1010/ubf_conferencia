import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana/l10n/app_localizations.dart';
import '../../providers/registration_provider.dart';

// 말씀 공부 언어 선택
//
// 성경공부 팀은 이 값으로 갈린다(025). 말이 통하지 않으면 공부가 되지 않으므로
// 언어가 연령보다 먼저다.
//
// **짐작하지 않고 묻는다.** 앱 표시 언어나 국가로 유추하면 틀린다 —
// 아르헨티나에 사는 한인 2세는 스페인어로 공부하고, 스페인어권에 파송된
// 한국인 선교사는 한국어로 공부한다. 둘 다 흔하다.
//
// 다만 앱을 그 언어로 읽고 있다는 것은 약한 단서는 되므로, 현재 앱 언어를
// 미리 골라 두고 바꿀 수 있게 한다. 아무것도 안 고른 채 넘어가는 것보다 낫다.
class StudyLanguageStep extends ConsumerWidget {
  final String programId;

  const StudyLanguageStep({super.key, required this.programId});

  /// 고를 수 있는 언어. 앱이 지원하는 세 가지다.
  ///
  /// 각 언어를 **그 언어로** 적는다. 한국어만 읽는 사람에게 "스페인어"라고
  /// 적어 봐야 자기 언어를 못 찾는다 — 자기 언어는 자기 글자로 보여야 한다.
  static const options = [
    (code: 'ko', label: '한국어'),
    (code: 'en', label: 'English'),
    (code: 'es', label: 'Español'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final form = ref.watch(registrationFormProvider(programId));
    final notifier = ref.read(registrationFormProvider(programId).notifier);

    // 아직 안 골랐으면 앱 언어를 미리 켜 둔다(저장은 고른 뒤에).
    final picked = form.studyLanguages.isNotEmpty
        ? form.studyLanguages
        : [Localizations.localeOf(context).languageCode];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(
          Icons.menu_book_outlined,
          size: 44,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          l10n.studyLangTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.studyLangBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.studyLangMulti,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),

        for (final o in options) ...[
          _LangCard(
            label: o.label,
            selected: picked.contains(o.code),
            // 첫 번째가 주 언어다. 어느 것이 팀을 가르는지 보여야
            // 순서를 바꿀 생각이라도 할 수 있다.
            badge: picked.isNotEmpty && picked.first == o.code
                ? l10n.studyLangPrimary
                : null,
            onTap: () => notifier.toggleStudyLanguage(o.code),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 4),
        Text(
          l10n.studyLangPrimaryNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),

        const SizedBox(height: 8),
        Text(
          l10n.studyLangNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _LangCard extends StatelessWidget {
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _LangCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : Colors.grey[300]!,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(
                // 하나만 고르는 것이 아니므로 동그라미가 아니라 네모다.
                selected
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                color: selected ? theme.colorScheme.primary : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
