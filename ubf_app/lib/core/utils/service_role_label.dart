import 'package:mana/l10n/app_localizations.dart';

/// 봉사 역할의 이름.
///
/// 서버는 키만 안다(service_roles.js). 기본 역할의 이름은 앱이 4개 언어로
/// 붙이고, 담당자가 그 자리에서 만든 역할(custom:)은 적어 준 이름을 그대로
/// 쓴다 — 번역할 방법이 없다.
///
/// core 에 두는 이유는 담당자 화면(assignment)과 참가자 화면(home)이 둘 다
/// 쓰기 때문이다. 한쪽에 두고 다른 쪽에서 가져다 쓰면 도메인이 섞인다.
String serviceRoleLabel(AppLocalizations l10n, Map<String, dynamic> role) {
  final custom = role['label'] as String?;
  if (custom != null && custom.isNotEmpty) return custom;
  return switch (role['key']) {
    'special_song' => l10n.svcRoleSpecialSong,
    'mc' => l10n.svcRoleMc,
    'pickup' => l10n.svcRolePickup,
    'cleaning' => l10n.svcRoleCleaning,
    'tour_guide' => l10n.svcRoleTourGuide,
    'meal_prep' => l10n.svcRoleMealPrep,
    'lodging_backup' => l10n.svcRoleLodgingBackup,
    'registration_desk' => l10n.svcRoleRegistrationDesk,
    'interpreter' => l10n.svcRoleInterpreter,
    'photo_video' => l10n.svcRolePhotoVideo,
    'medical' => l10n.svcRoleMedical,
    'group_study_leader' => l10n.svcRoleGroupStudyLeader,
    _ => l10n.svcRoleOther,
  };
}

/// 배정 상태를 사람이 읽는 말로.
String serviceStatusLabel(AppLocalizations l10n, String? status) =>
    switch (status) {
      'invited' => l10n.svcStatusInvited,
      'applied' => l10n.svcStatusApplied,
      'awaiting_approval' => l10n.svcStatusApproval,
      'confirmed' => l10n.svcStatusConfirmed,
      'rejected' => l10n.svcStatusRejected,
      'declined' => l10n.svcStatusDeclined,
      _ => '',
    };
