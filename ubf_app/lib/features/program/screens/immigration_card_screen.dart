import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/program_provider.dart';
import 'package:mana/l10n/app_localizations.dart';

// 입국 카드 화면
// 참가자가 공항 입국 시 감사관에게 보여주는 화면
class ImmigrationCardScreen extends ConsumerStatefulWidget {
  final String programId;

  const ImmigrationCardScreen({super.key, required this.programId});

  @override
  ConsumerState<ImmigrationCardScreen> createState() =>
      _ImmigrationCardScreenState();
}

class _ImmigrationCardScreenState
    extends ConsumerState<ImmigrationCardScreen> {
  bool _isFullscreen = false;

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      // 화면 꺼짐 방지 + 상태바/네비게이션 숨김
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(programByIdProvider(widget.programId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A3A6B), // 공식 느낌의 짙은 파란색
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1A3A6B),
              foregroundColor: Colors.white,
              title: Text(l10n.immTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: l10n.immFullscreenTooltip,
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
      body: programAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => Center(
          child: Text(l10n.commonErrorDetail('$e'), style: const TextStyle(color: Colors.white)),
        ),
        data: (program) {
          if (program == null) {
            return Center(
              child: Text(l10n.immNotFound,
                  style: const TextStyle(color: Colors.white)),
            );
          }
          return _CardBody(
            program: program,
            isFullscreen: _isFullscreen,
            onToggleFullscreen: _toggleFullscreen,
          );
        },
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final Map<String, dynamic> program;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  const _CardBody({
    required this.program,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy. MM. dd').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _dateRange() {
    final start = program['start_date'] as String?;
    final end = program['end_date'] as String?;
    if (start == null && end == null) return '-';
    if (start != null && end != null) {
      return '${_formatDate(start)}  ~  ${_formatDate(end)}';
    }
    return _formatDate(start ?? end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contact1Name  = program['contact1_name']  as String?;
    final contact1Phone = program['contact1_phone'] as String?;
    final contact2Name  = program['contact2_name']  as String?;
    final contact2Phone = program['contact2_phone'] as String?;
    final hasContacts   = contact1Name != null || contact2Name != null;
    final hasAirport    = (program['nearest_airport'] as String?) != null;

    return GestureDetector(
      // 전체화면 상태에서 탭하면 해제
      onTap: isFullscreen ? onToggleFullscreen : null,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isFullscreen ? 24 : 20,
            vertical: isFullscreen ? 32 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 전체화면 안내 텍스트
              if (!isFullscreen) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.immBanner,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 카드 본문
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 카드 헤더
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A3A6B),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.immCardPurpose,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            program['name'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.immCardConference,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 카드 내용
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardRow(
                            label: l10n.immCardVenue,
                            value: program['location'] as String? ?? '-',
                            icon: Icons.location_on_outlined,
                          ),
                          const Divider(height: 24),
                          _CardRow(
                            label: l10n.immCardDate,
                            value: _dateRange(),
                            icon: Icons.calendar_month_outlined,
                          ),
                          if (hasAirport) ...[
                            const Divider(height: 24),
                            _CardRow(
                              label: l10n.immCardAirport,
                              value: program['nearest_airport'] as String,
                              icon: Icons.flight_land_outlined,
                            ),
                          ],
                          if (hasContacts) ...[
                            const Divider(height: 24),
                            Text(
                              l10n.immCardContact,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1A3A6B),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (contact1Name != null)
                              _ContactRow(
                                name: contact1Name,
                                phone: contact1Phone,
                              ),
                            if (contact2Name != null) ...[
                              const SizedBox(height: 10),
                              _ContactRow(
                                name: contact2Name,
                                phone: contact2Phone,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    // 카드 푸터
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Text(
                        l10n.immCardFooter,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555555),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // 전체화면 모드 해제 안내
              if (isFullscreen) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.immExitHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CardRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1A3A6B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1A3A6B),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String name;
  final String? phone;

  const _ContactRow({required this.name, this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCDD8F5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18, color: Color(0xFF1A3A6B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (phone != null)
                  Text(
                    phone!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A3A6B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF1A3A6B)),
        ],
      ),
    );
  }
}
