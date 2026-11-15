import '../../l10n/app_localizations.dart';

/// 국제 수양회의 인원 표시 — "전체 (외국 n)".
///
/// [foreign] 은 서버가 국제 수양회일 때만 채워 보낸다(개최국이 아닌 나라에서
/// 오는 사람 수). 지역 수양회나 개최국을 안 정한 수양회는 null 이고, 그때는
/// [base] 를 그대로 돌려준다 — "(외국 0명)" 을 붙이면 셀 수 없는 것을 0 으로
/// 센 것처럼 보인다.
///
/// 숫자는 문자열로 올 수도 있다(Postgres COUNT 는 bigint).
String withForeignCount(AppLocalizations l10n, String base, Object? foreign) {
  final n = foreign is num ? foreign.toInt() : int.tryParse('${foreign ?? ''}');
  return n == null ? base : l10n.withForeign(base, n);
}
