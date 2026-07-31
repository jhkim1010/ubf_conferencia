import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

// 언어 선택 시트 (A002)
// 로그인 전에도 쓸 수 있어야 한다 — 읽을 수 없는 언어로 로그인 화면이 떠 있으면
// 진입 자체가 막히기 때문이다.

Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _LanguageSheet(),
  );
}

/// 앱바 등에 놓는 언어 아이콘 버튼.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.language),
      tooltip: l10n.languageTitle,
      onPressed: () => showLanguagePicker(context),
    );
  }
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              l10n.languageTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final (code, label) in supportedLanguages)
            ListTile(
              title: Text(label),
              trailing: current?.languageCode == code
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () async {
                await notifier.setLocale(code);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          const Divider(height: 1),
          ListTile(
            title: Text(l10n.languageSystem),
            trailing: current == null
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () async {
              await notifier.useSystemLocale();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
