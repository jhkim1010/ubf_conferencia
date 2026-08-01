import 'package:flutter/material.dart';

// Mana Watch — Wear OS(갤럭시 워치) 컴패니언
// Phase 5.1 스캐폴드: 3개 글랜스 카드(일정·픽업·SOS)를 스와이프.
// 지금은 목업 데이터로 에뮬레이터에서 바로 동작 — 실 API 연동은 다음 단계(폰→워치 토큰 전달 후).

void main() => runApp(const ManaWatchApp());

class ManaWatchApp extends StatelessWidget {
  const ManaWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mana Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3FA99A), // 운행 teal
          secondary: Color(0xFF5E92F3),
          surface: Color(0xFF15211F),
        ),
        useMaterial3: true,
      ),
      home: const WatchHome(),
    );
  }
}

class WatchHome extends StatefulWidget {
  const WatchHome({super.key});

  @override
  State<WatchHome> createState() => _WatchHomeState();
}

class _WatchHomeState extends State<WatchHome> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 원형 화면에서 모서리가 잘리므로 콘텐츠를 가운데로 모으고 여백을 둔다.
    final size = MediaQuery.of(context).size;
    final inset = size.width * 0.12;

    const pages = [
      _ScheduleCard(),
      _PickupCard(),
      SosCard(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(inset),
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: pages,
            ),
          ),
          // 페이지 인디케이터(하단)
          Positioned(
            bottom: size.height * 0.06,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                final on = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: on ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: on ? const Color(0xFF3FA99A) : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// 카드 공통 골격: 아이콘 + 라벨 + 본문
class _GlanceCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final Widget child;

  const _GlanceCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// W1 — 내 다음 일정
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard();

  @override
  Widget build(BuildContext context) {
    return const _GlanceCard(
      icon: Icons.event,
      accent: Color(0xFF5E92F3),
      label: '다음 일정',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('14:00',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
          SizedBox(height: 2),
          Text('개회 예배', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          SizedBox(height: 2),
          Text('본당 2층', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

// W2 — 내 픽업 차편
class _PickupCard extends StatelessWidget {
  const _PickupCard();

  @override
  Widget build(BuildContext context) {
    return const _GlanceCard(
      icon: Icons.directions_bus,
      accent: Color(0xFF3FA99A),
      label: '내 픽업',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('1호차 · 14:20',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 3),
          Text('기사 요셉', style: TextStyle(fontSize: 12, color: Colors.white70)),
          SizedBox(height: 3),
          Text('집결 · T1 5번 출구',
              style: TextStyle(fontSize: 12, color: Colors.white), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// W4 — SOS 손목 버튼
class SosCard extends StatelessWidget {
  const SosCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _GlanceCard(
      icon: Icons.emergency_share,
      accent: const Color(0xFFD0433B),
      label: 'SOS',
      child: GestureDetector(
        onTap: () => _confirm(context),
        child: Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: Color(0xFFD0433B),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('SOS',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF15211F),
        title: const Text('SOS 발령', style: TextStyle(fontSize: 15)),
        content: const Text('현재 위치와 함께 관리자에게\n긴급 알림을 보냅니다.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD0433B)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS 전송됨 (목업)'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('보내기'),
          ),
        ],
      ),
    );
  }
}
