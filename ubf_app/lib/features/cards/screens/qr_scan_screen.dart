import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:mana/l10n/app_localizations.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/join_link.dart';
import '../providers/card_provider.dart';
import '../widgets/card_view.dart';

/// 이 플랫폼에서 카메라로 읽을 수 있는가.
///
/// mobile_scanner 는 안드로이드·iOS·macOS·웹만 지원한다. Windows·Linux 에서는
/// 화면을 띄우지 않는다 — 눌러도 아무 일도 안 일어나는 버튼은 고장으로 읽힌다.
bool get qrScanSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

// QR 읽기(031)
//
// **읽자마자 저장되지 않는다.** 보고 나서 저장을 누른다 —
// "충분히 교제했고 나누고 싶을 때"가 이 기능의 조건이다.
class QrScanScreen extends ConsumerStatefulWidget {
  final String? programId;
  const QrScanScreen({super.key, this.programId});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  Map<String, dynamic>? _preview;
  bool _handling = false;

  /// QR 에는 `https://…/c/<토큰>` 이 들어 있다. 다른 앱이 만든 코드가
  /// 읽힐 수도 있으므로 우리 형식이 아니면 조용히 넘긴다.
  String? _tokenFrom(String raw) {
    final m = RegExp(r'/c/([A-Za-z0-9_-]{16,64})$').firstMatch(raw.trim());
    if (m != null) return m.group(1);
    return isValidCardToken(raw.trim()) ? raw.trim() : null;
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_handling || _preview != null) return;
    final raw = cap.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final token = _tokenFrom(raw);
    if (token == null) return;

    setState(() => _handling = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final data = await ApiClient.openCardByToken(token);
      if (mounted) setState(() => _preview = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.statusCode == 409
                ? l10n.cardSelfScan
                : (e.statusCode == 404 ? l10n.cardExpiredCode : e.message),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    await ApiClient.saveConnection(
      friendUserId: _preview!['userId'] as String,
      programId: widget.programId,
    );
    ref.invalidate(connectionsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.cardSaved)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cardScan)),
      body: !qrScanSupported
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.cardScanUnsupported,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 280,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(onDetect: _onDetect),
                      if (_preview == null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              color: Colors.black54,
                              child: Text(
                                l10n.cardScanPoint,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_preview != null)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        CardView(
                          card: _preview!['card'] as Map<String, dynamic>,
                        ),
                        const SizedBox(height: 16),
                        if (_preview!['alreadySaved'] == true)
                          Text(
                            l10n.cardAlreadySaved,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          )
                        else
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.person_add_alt),
                            label: Text(l10n.cardSaveFriend),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.cardDontSave),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
