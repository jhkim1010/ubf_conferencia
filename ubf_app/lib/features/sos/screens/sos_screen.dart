import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

enum SituationType {
  health('health', Colors.red),
  safety('safety', Colors.deepOrange),
  lost  ('lost',   Colors.orange);

  const SituationType(this.value, this.color);
  final String value;
  final Color color;
}

// 상황 유형의 현재 언어 라벨 (이모지 포함)
String _situationLabel(SituationType t, AppLocalizations l10n) => switch (t) {
      SituationType.health => l10n.sosHealth,
      SituationType.safety => l10n.sosSafety,
      SituationType.lost => l10n.sosLost,
    };

class SosScreen extends ConsumerStatefulWidget {
  final String programId;

  const SosScreen({super.key, required this.programId});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  SituationType _selected = SituationType.health;
  final _messageController = TextEditingController();
  bool _isSending = false;
  Position? _position;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // GPS 권한 요청 및 현재 위치 취득
  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (!serviceEnabled) {
        setState(() => _locationError = l10n.sosGpsOff);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _locationError = l10n.sosPermDenied);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() => _position = pos);
    } catch (e) {
      if (mounted) {
        setState(() => _locationError =
            AppLocalizations.of(context)!.sosLocationError('$e'));
      }
    }
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSending = true);

    try {
      final user = ref.read(currentUserProvider);
      await ApiClient.sendSos(
        programId: widget.programId,
        situationType: _selected.value,
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        realName: user.name,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: Text(l10n.sosSentTitle),
          content: Text(l10n.sosSentMsg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // SOS 화면
              },
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sosSendFailed('$e')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        title: Text(l10n.sosTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 경고 배너
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.sosBanner,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 상황 선택
            Text(
              l10n.sosSelectType,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...SituationType.values.map((type) {
              final selected = _selected == type;
              return GestureDetector(
                onTap: () => setState(() => _selected = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? type.color.withValues(alpha: 0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? type.color : Colors.grey[300]!,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_situationLabel(type, l10n), style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check_circle, color: type.color),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // 추가 메시지 (선택)
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.sosMessageLabel,
                hintText: l10n.sosMessageHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // GPS 상태 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _position != null ? Colors.green[300]! : Colors.orange[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _position != null ? Icons.location_on : Icons.location_off,
                    color: _position != null ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _position != null
                          ? l10n.sosGpsConfirmed('(${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)})')
                          : (_locationError ?? l10n.sosGpsChecking),
                      style: TextStyle(
                        fontSize: 13,
                        color: _position != null ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                  if (_position == null && _locationError != null)
                    TextButton(
                      onPressed: _requestLocation,
                      child: Text(l10n.actionRetry),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // SOS 전송 버튼
            ElevatedButton.icon(
              onPressed: _isSending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.emergency, size: 24),
              label: Text(_isSending ? l10n.sosSending : l10n.sosSend),
            ),
          ],
        ),
      ),
    );
  }
}
