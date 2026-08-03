import 'package:flutter/material.dart';
import 'package:mana/l10n/app_localizations.dart';

// 수양회 전용 텔레그램 봇 설정(029).
//
// 새 등록과 정보 수정 알림이 이 봇으로 나간다. 비워 두면 서버 기본 봇을 쓴다.
//
// **저장된 토큰은 화면으로 돌아오지 않는다.** 서버가 어떤 응답에도 싣지
// 않기 때문이다 — 프로그램 조회는 참가자도 부를 수 있는 경로라, 토큰이 실리면
// 등록한 사람 전원이 그 봇으로 아무 메시지나 보낼 수 있게 된다.
//
// 그래서 이 위젯은 "설정되어 있음"만 알려 주고, 칸은 비워 둔다.
//   비워 두고 저장 → 기존 토큰 유지
//   새로 입력      → 교체
//   해제 버튼      → 빈 문자열을 보내 지운다
class TelegramSection extends StatelessWidget {
  final TextEditingController tokenController;
  final TextEditingController chatIdController;

  /// 서버가 알려 준 설정 여부(telegram_bot_configured).
  final bool configured;

  /// 해제 버튼. 새 수양회 만들기 화면에서는 지울 것이 없으므로 null 이다.
  final VoidCallback? onClear;

  const TelegramSection({
    super.key,
    required this.tokenController,
    required this.chatIdController,
    this.configured = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.send_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.tgSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tgSectionHelp,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        if (configured) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green[800],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.tgConfigured,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                    if (onClear != null)
                      TextButton(
                        onPressed: onClear,
                        child: Text(l10n.tgClearToken),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tgTokenHidden,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        TextFormField(
          controller: tokenController,
          decoration: InputDecoration(
            labelText: l10n.tgBotToken,
            hintText: l10n.tgBotTokenHint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          // 토큰은 비밀값이다. 어깨너머로 보이지 않게 가린다.
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: chatIdController,
          decoration: InputDecoration(
            labelText: l10n.tgChatId,
            hintText: l10n.tgChatIdHint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          autocorrect: false,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tgHowTo,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
