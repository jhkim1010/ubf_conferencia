import '../constants/world_countries.dart';
import 'money.dart';
import 'payment_state.dart';

/// 명단 표를 칼럼으로 줄 세울 때 쓰는 값 (057)
///
/// **표에 적힌 글자가 아니라 원래 값으로 견준다.** 나이를 글자로 보면
/// "9" 가 "41" 보다 뒤로 가고, 담당자는 화면이 고장 났다고 여긴다.
///
/// 화면에서 빼 둔 이유는 눈으로만 확인할 수 없어서다. 여기 있으면
/// test/roster_sort_test.dart 가 대신 지킨다.

/// 표시할 이름. 세례명이 있으면 그것, 없으면 본명.
String rosterNameKey(Map<String, dynamic> r) {
  final bible = '${r['bible_name'] ?? ''}'.trim();
  final legal = '${r['real_name'] ?? ''}'.trim();
  return (bible.isNotEmpty ? bible : legal).toLowerCase();
}

/// 성별로 묶고 그 안에서 나이순.
///
/// 나이를 안 적은 사람은 맨 뒤로 보낸다 — 0으로 두면 갓난아기처럼 맨 앞에
/// 선다. 세 자리로 채워 글자로 견줘도 수처럼 서게 한다.
String rosterAgeKey(Map<String, dynamic> r) {
  final g = switch (r['gender']) {
    'M' => 'M',
    'F' => 'F',
    _ => '?',
  };
  final age = r['age'] is int
      ? r['age'] as int
      : int.tryParse('${r['age'] ?? ''}') ?? 0;
  final n = age > 0 ? age : 999;
  return '$g${n.toString().padLeft(3, '0')}';
}

/// 입금. **미납이 위로 온다** — 담당자가 이 칸을 누르는 까닭은 받을 돈을
/// 찾기 위해서다. 같은 상태면 낼 돈이 많은 쪽이 먼저.
String rosterPayKey(Map<String, dynamic> r) {
  final pay = (r['payment'] as Map?) ?? const {};
  final due = Money.parse(r['amount_due']) ?? 0;
  final st = payStateOf(
    due: due,
    paid: Money.parse(pay['amount']) ?? 0,
    status: pay['status'] as String?,
  );
  // 낼 돈이 많은 쪽을 앞으로 보내려고 뒤집는다.
  final inv = (999999 - due).clamp(0, 999999);
  return '${st.index}${inv.toStringAsFixed(2).padLeft(12, '0')}';
}

String rosterCountryKey(Map<String, dynamic> r) =>
    (WorldCountries.display(r['country'] as String?) ?? '').toLowerCase();

String rosterBranchKey(Map<String, dynamic> r) =>
    '${r['branch'] ?? ''}'.toLowerCase();

/// 전화번호. 숫자만 남겨 견준다 — "+54 9 11…" 과 "1130…" 이 적은 모양
/// 때문에 엉뚱한 자리에 서지 않게.
String rosterPhoneKey(Map<String, dynamic> r) =>
    '${r['phone'] ?? ''}'.replaceAll(RegExp(r'\D'), '');

/// 숙박비. 수로 서게 자릿수를 채운다. 낼 숙박비가 없으면 빈 값이다 —
/// 빈 값은 [compareRosterKeys] 가 맨 뒤로 보낸다.
String rosterHotelKey(Map<String, dynamic> r) {
  final cost = Money.parse(r['hotel_cost']) ?? 0;
  return cost > 0 ? cost.toStringAsFixed(2).padLeft(12, '0') : '';
}

/// 두 줄 세우기 값을 견준다.
///
/// **빈 값은 오름차순이든 내림차순이든 맨 뒤다.** 전화번호를 안 적은
/// 사람이 대부분이라, 빈 값을 그냥 견주면 오름차순일 때 빈 줄만 한 화면
/// 가득 나오고 정작 번호가 있는 사람은 아래로 밀린다.
int compareRosterKeys(String a, String b, {required bool ascending}) {
  if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
  final c = a.compareTo(b);
  return ascending ? c : -c;
}
