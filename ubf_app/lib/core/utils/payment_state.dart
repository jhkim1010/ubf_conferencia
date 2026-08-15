import 'package:mana/l10n/app_localizations.dart';

/// 입금 상태 — 낼 돈과 낸 돈에서 하나로 정한다.
///
/// **서버의 payment_state.js 와 같은 규칙이다.** 두 곳에 두는 것이 마음에
/// 들지는 않지만, 표는 이미 받아 둔 행으로 그 자리에서 다시 그려야 하고
/// 서버에 다시 묻지 않는다. 규칙이 바뀌면 양쪽을 함께 고쳐야 한다 —
/// 그래서 판정 자체는 이 한 함수에만 둔다.
enum PayState { unpaid, partial, paid, pending }

PayState payStateOf({num? due, num? paid, String? status}) {
  final owed = (due ?? 0) > 0 ? (due ?? 0) : 0;
  // 확인된 것만 낸 것으로 센다. 거절은 낸 것이 아니다.
  final got = (status == 'confirmed' && (paid ?? 0) > 0) ? (paid ?? 0) : 0;

  // 확인 전에는 금액과 상관없이 대기 — 확인하지 않은 돈을 세면 장부가
  // 실제보다 커진다.
  if (status == 'pending') return PayState.pending;
  if (owed == 0) return PayState.paid;
  if (got <= 0) return PayState.unpaid;
  if (got < owed) return PayState.partial;
  return PayState.paid;
}

String payStateLabel(AppLocalizations l10n, PayState s) => switch (s) {
  PayState.unpaid => l10n.payUnpaid,
  PayState.partial => l10n.payPartial,
  PayState.paid => l10n.payPaid,
  PayState.pending => l10n.payPending,
};
