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

/// 등록할 때 적어 낸 자원(009)의 이름.
///
/// **역할이 아니다.** "할 수 있다" 고 적어 낸 것일 뿐이고, 누구에게 무엇을
/// 맡길지는 담당자가 정한다. 그래서 역할 이름과 섞지 않고 따로 둔다.
String volunteerResourceLabel(AppLocalizations l10n, String key) =>
    switch (key) {
      'piano' => l10n.volPiano,
      'guitar' => l10n.volGuitar,
      'bass' => l10n.volBass,
      'drums' => l10n.volDrums,
      'violin' => l10n.volViolin,
      'worship_lead' => l10n.volWorshipLead,
      'vocals' => l10n.volVocals,
      'translation' => l10n.volTranslation,
      'photography' => l10n.volPhotography,
      'sound' => l10n.volSound,
      'design' => l10n.volDesign,
      'it' => l10n.volIt,
      'childcare' => l10n.volChildcare,
      'cooking' => l10n.volCooking,
      'driving' => l10n.volDriving,
      _ => key,
    };
