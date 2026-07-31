---
id: 001
title: 앱 내 언어 선택 (한국어/English/Español)
priority: high
created_at: 2026-07-31T12:45:45.017Z
---

## Task
## 무엇을

사용자가 앱 안에서 한국어 / English / Español 를 직접 고를 수 있게 한다.
현재는 기기 언어만 따르고 앱 안에서 바꿀 수단이 전혀 없다.

## 반드시 먼저 읽을 것

**`.team/artifacts/A002-language-selection.md`** — 전체 명세, 확정된 결정 5건,
구현 지침, 검증 항목이 모두 여기 있다. 이 문서를 따른다.

저장소 규약은 루트 **`CLAUDE.md`** 를 따른다.

## 범위

Flutter 단독. 스키마·API 변경 없음. `server/` 는 건드리지 않는다.

- `lib/core/providers/locale_provider.dart` 신규 (null = 기기 언어 따르기)
- `lib/app.dart` 의 MaterialApp.router 에 locale: 연결
- `lib/features/settings/widgets/language_picker.dart` 신규 (bottom sheet)
- 진입점 2곳: 로그인 화면, 홈 앱바
- ARB 3개(app_en.arb 템플릿 / app_ko.arb / app_es.arb)에 문자열 2개 추가

## 절대 깨뜨리면 안 되는 것

localeResolutionCallback 을 지우지 말 것. locale 이 null 일 때 기존 기기 언어
폴백을 그대로 담당한다. 한 번도 언어를 고르지 않은 사용자는 지금과 완전히
동일하게 동작해야 한다.

Riverpod 코드 생성(@riverpod, .g.dart)을 도입하지 말 것. 이 저장소는 수동 선언
방식이고 생성물이 하나도 없다.

app_localizations*.dart 는 생성물이다. 직접 편집하지 말고 flutter gen-l10n 을 쓴다.

## 완료 기준

  ./verify.sh flutter-analyze dart-format arb-parity

이것만으로는 부족하다. 아래 5가지를 실제로 실행해 확인하고, 확인한 방법과
결과를 완료 보고에 적을 것:

1. 언어를 바꾸면 화면이 즉시 그 언어로 바뀐다 (재시작 없이)
2. 앱을 껐다 켜도 선택이 유지된다
3. "기기 언어 따르기" 를 고르면 기기 언어로 돌아간다
4. 한 번도 고르지 않은 상태에서는 기존과 동일하게 동작한다 (회귀 없음)
5. 로그인 전 화면에서도 바꿀 수 있다

Flutter 위젯 테스트는 이 저장소에 없다(widget_test.dart 는 플레이스홀더).
"테스트 통과"를 완료 근거로 쓰지 말 것.
