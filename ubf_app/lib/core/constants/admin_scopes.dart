import 'package:flutter/material.dart';
import 'package:mana/l10n/app_localizations.dart';

/// 공동 관리자가 맡는 분야 (059)
///
/// 서버의 SCOPES 와 **이름이 하나하나 같아야 한다**. 어긋나면 화면에서 고른
/// 분야가 서버에서 버려지고, 담당자는 골랐는데 안 된다고 여긴다.
/// 그것을 test/admin_scopes_test.dart 가 지킨다.
class AdminScope {
  final String key;
  final IconData icon;
  const AdminScope(this.key, this.icon);

  String label(AppLocalizations l) => switch (key) {
    'transport' => l.scopeTransport,
    'rooms' => l.scopeRooms,
    'groups' => l.scopeGroups,
    'ledger' => l.scopeLedger,
    'service' => l.scopeService,
    'registration' => l.scopeRegistration,
    'comms' => l.scopeComms,
    'schedule' => l.scopeSchedule,
    'medical' => l.scopeMedical,
    _ => key,
  };

  String hint(AppLocalizations l) => switch (key) {
    'transport' => l.scopeTransportHint,
    'rooms' => l.scopeRoomsHint,
    'groups' => l.scopeGroupsHint,
    'ledger' => l.scopeLedgerHint,
    'service' => l.scopeServiceHint,
    'registration' => l.scopeRegistrationHint,
    'comms' => l.scopeCommsHint,
    'schedule' => l.scopeScheduleHint,
    'medical' => l.scopeMedicalHint,
    _ => '',
  };
}

const adminScopes = <AdminScope>[
  AdminScope('transport', Icons.airport_shuttle_outlined),
  AdminScope('rooms', Icons.meeting_room_outlined),
  AdminScope('groups', Icons.menu_book_outlined),
  AdminScope('ledger', Icons.account_balance_wallet_outlined),
  AdminScope('service', Icons.volunteer_activism_outlined),
  AdminScope('registration', Icons.how_to_reg_outlined),
  AdminScope('comms', Icons.campaign_outlined),
  AdminScope('schedule', Icons.event_outlined),
  AdminScope('medical', Icons.medical_services_outlined),
];

/// 서버가 준 값 → 화면이 쓰는 집합.
///
/// **비어 있거나 없으면 전부다.** 059 이전에 세운 사람이 그렇고, 그 사람의
/// 권한을 화면이 마음대로 좁히면 안 된다.
Set<String>? scopesOf(Object? raw) {
  if (raw is! List || raw.isEmpty) return null;
  final s = raw.map((e) => '$e').toSet();
  return s.contains('all') ? null : s;
}

/// 이 분야를 볼 수 있는가. null 이면 전부라는 뜻이다.
bool canSee(Set<String>? mine, String scope) =>
    mine == null || mine.contains(scope);
