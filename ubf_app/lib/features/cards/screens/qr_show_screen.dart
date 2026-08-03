import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/join_link.dart';
import '../providers/card_provider.dart';

// 내 QR 보여주기(031)
//
// 코드 안에는 개인정보가 없다. 짧은 주소 하나뿐이다 —
// 내용은 상대가 그때그때 서버에서 가져가므로 내가 고치면 바로 반영되고,
// 코드를 새로 만들면 예전 것은 그 자리에서 무효가 된다.
class QrShowScreen extends ConsumerWidget {
  const QrShowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(myCardProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cardShareTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorDetail('$e'))),
        data: (card) {
          final token = card['share_token'] as String? ?? '';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // QR 은 검은 모듈과 흰 바탕이어야 읽힌다. 어두운 화면에서도
                  // 배경을 흰색으로 고정한다 — 색을 맞추면 못 읽는다.
                  child: QrImageView(
                    data: '$webBaseUrl/c/$token',
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.cardQrHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.cardQrRotate),
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.cardQrRotate),
                      content: Text(l10n.cardQrRotateWarn),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.actionCancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.actionConfirm),
                        ),
                      ],
                    ),
                  );
                  if (yes != true) return;
                  await ApiClient.rotateShareToken();
                  ref.invalidate(myCardProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.cardQrRotated)));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
