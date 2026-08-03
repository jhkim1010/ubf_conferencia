import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 앱 내 언어 선택 (A002)
//
// 상태가 null 이면 "명시 선택 없음" — MaterialApp 의 localeResolutionCallback 이
// 기존대로 기기 언어를 따른다. 한 번도 고르지 않은 사용자는 종전과 동일하게 동작한다.

/// 선택 가능한 언어. 이름은 각 언어로 적는다(번역하지 않는다).
const supportedLanguages = <(String code, String label)>[
  ('ko', '한국어'),
  ('en', 'English'),
  ('es', 'Español'),
  // 브라질에서도 참석한다. 스페인어로 대신 읽게 두면 안 된다 —
  // 가깝다고 해서 읽히는 언어가 아니다.
  ('pt', 'Português'),
];

const _prefsKey = 'app_locale';

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    if (!supportedLanguages.any((l) => l.$1 == code)) return;
    state = Locale(code);
  }

  /// 언어를 명시 선택한다.
  Future<void> setLocale(String code) async {
    if (!supportedLanguages.any((l) => l.$1 == code)) return;
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  /// 명시 선택을 해제하고 기기 언어를 따른다.
  Future<void> useSystemLocale() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);
