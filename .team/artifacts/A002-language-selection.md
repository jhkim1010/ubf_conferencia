# A002 · 앱 내 언어 선택

작성 2026-07-31 · 상태: 결정 확정, 구현 대기 · 범위: Flutter 단독 (스키마·API 변경 없음)

사용자가 앱 안에서 한국어 / English / Español 를 직접 고를 수 있게 한다.

---

## 1. 현재 동작과 문제

`ubf_app/lib/app.dart` 의 `MaterialApp.router` 에는 `locale:` 이 지정되어 있지 않고,
`localeResolutionCallback` 이 **기기 언어**를 따른다. 지원 언어(ko/en/es)면 그 언어,
그 외에는 영어로 폴백한다. 앱 안에 언어를 바꿀 수단이 전혀 없다
(`localeProvider` / `setLocale` 류 코드 없음).

국제 수양회에서 실제로 문제가 된다. 예를 들어 브라질 개최 수양회에 한국인 선교사가
참석하는데 기기가 포르투갈어로 설정되어 있으면, 포르투갈어는 지원 언어가 아니므로
**영어로 폴백**된다. 한국어를 읽을 수 있는데도 영어를 보게 된다.

---

## 2. 결정

| # | 쟁점 | 결정 |
|---|---|---|
| D1 | 기본값 | **기기 언어 유지.** 사용자가 고르기 전에는 지금 동작과 완전히 같다 |
| D2 | 저장 위치 | **`SharedPreferences`.** 기기 로컬. 서버 동기화는 하지 않는다(로그인 전에도 바꿀 수 있어야 하므로) |
| D3 | 언어 이름 표기 | **각 언어를 그 언어로 적는다** — `한국어` / `English` / `Español`. 번역하지 않는다 |
| D4 | 진입점 | **로그인 화면 + 홈 앱바.** 로그인 전에 바꿀 수 있어야 한다 — 읽을 수 없는 언어로 로그인 화면이 떠 있으면 진입 자체가 막힌다 |
| D5 | "기기 언어 따르기" 선택지 | **둔다.** 명시 선택을 해제하고 기본 동작으로 돌아갈 수 있어야 한다 |

---

## 3. 구현

### 상태

`lib/core/providers/locale_provider.dart` (신규)

```dart
// null = 기기 언어를 따른다 (명시 선택 없음)
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(...);
```

- `SharedPreferences` 키: `app_locale`. 값은 `'ko'` / `'en'` / `'es'`, 미설정이면 키 없음
- 앱 시작 시 저장값을 읽어 초기 상태로 넣는다
- 선택 해제(기기 언어 따르기) 시 키를 삭제한다

기존 Riverpod 관례를 따른다 — **코드 생성(`@riverpod`, `.g.dart`)을 쓰지 않는다.**
저장소에 생성물이 하나도 없다.

### 앱 연결

`lib/app.dart` — `UbfApp` 은 이미 `ConsumerStatefulWidget` 이므로 그대로 `ref.watch` 할 수 있다.

```dart
locale: ref.watch(localeProvider),   // null 이면 localeResolutionCallback 이 동작
```

**`localeResolutionCallback` 은 지우지 말 것.** `locale` 이 null 일 때의 기기 언어 폴백을
그대로 담당한다. 이게 D1(기본 동작 보존)을 지키는 방법이다.

### 화면

`lib/features/settings/widgets/language_picker.dart` (신규) — 재사용 가능한 선택 위젯.
`showModalBottomSheet` 로 띄우고, 4개 항목(한국어 / English / Español / 기기 언어 따르기)에
현재 선택 표시. 선택 즉시 반영하고 시트를 닫는다.

진입점 2곳:
- **로그인 화면** (`features/auth/screens/login_screen.dart`) — 상단이나 하단에 언어 아이콘
- **홈 앱바** (`features/home/screens/home_screen.dart`) — 기존 로그아웃 아이콘 옆

시각 규약은 기존과 동일 — `AppTheme.primary`(#1565C0), Material 3, radius 12.

### 문자열

ARB **3개 모두**에 추가한다 (`app_en.arb` 가 키 템플릿):

| 키 | 용도 |
|---|---|
| `languageTitle` | 시트 제목 — "언어" / "Language" / "Idioma" |
| `languageSystem` | "기기 언어 따르기" / "Use device language" / "Usar idioma del dispositivo" |

**언어 이름 자체는 ARB 에 넣지 않는다** (D3 — 번역하지 않으므로 코드에 상수로 둔다).

---

## 4. 검증

```bash
./verify.sh flutter-analyze dart-format arb-parity
```

- `arb-parity` 가 3개 ARB 의 키 집합 불일치를 잡는다
- `app_localizations*.dart` 는 생성물이다. 직접 편집하지 말고 `flutter gen-l10n` 을 쓴다

`verify.sh` 로 자동 판정되지 않아 **직접 확인해야 하는 것**:

1. 언어를 바꾸면 화면이 **즉시** 그 언어로 바뀐다 (재시작 없이)
2. 앱을 껐다 켜도 선택이 **유지**된다
3. "기기 언어 따르기" 를 고르면 기기 언어로 돌아간다
4. 한 번도 고르지 않은 상태에서는 **기존과 동일하게** 동작한다 (회귀 없음)
5. 로그인 **전** 화면에서도 바꿀 수 있다

Flutter 쪽은 위젯 테스트가 없다(`widget_test.dart` 는 플레이스홀더). "테스트 통과"를
근거로 쓰지 말고, 위 5개를 실제로 확인한 방법과 결과를 보고에 적는다.

---

## 5. 범위 밖

- 서버에 언어 저장 / 사용자 프로필 동기화
- 포르투갈어 등 지원 언어 추가 (ARB 신설이 필요한 별개 작업)
- 알림·이메일의 언어 (서버가 보내는 것)
