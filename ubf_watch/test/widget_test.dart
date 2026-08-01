import 'package:flutter_test/flutter_test.dart';

import 'package:mana_watch/main.dart';

void main() {
  testWidgets('Watch app shows glance cards', (tester) async {
    await tester.pumpWidget(const ManaWatchApp());
    // 첫 카드(다음 일정)가 보인다
    expect(find.text('다음 일정'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
  });
}
