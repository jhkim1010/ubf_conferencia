# Windows에서 Mana Watch를 Wear OS 에뮬레이터로 실행하기

> 대상: 개발환경이 없는 Windows PC. 아래 순서대로 하면 `ubf_watch`(워치 앱)를
> 갤럭시 워치용 **Wear OS 에뮬레이터**에서 실행할 수 있습니다. (실기기 불필요)

## 1. Git 설치
- https://git-scm.com/download/win → 설치(기본값).

## 2. Flutter SDK 설치
1. https://docs.flutter.dev/get-started/install/windows → Flutter SDK zip 다운로드.
2. `C:\src\flutter` 에 압축 해제(경로에 공백·한글 없게).
3. 시스템 환경변수 `Path`에 `C:\src\flutter\bin` 추가.
4. 새 PowerShell에서 확인: `flutter --version`

## 3. Android Studio 설치 (SDK + 에뮬레이터)
1. https://developer.android.com/studio → 설치.
2. 첫 실행 시 **Android SDK, SDK Platform-Tools, Emulator**가 함께 설치됨.
3. 라이선스 동의: PowerShell에서
   ```
   flutter doctor --android-licenses
   ```
   (모두 `y`)
4. 상태 점검:
   ```
   flutter doctor
   ```
   Android toolchain·Android Studio 항목에 체크(✓)가 뜨면 됨.

## 4. Wear OS 에뮬레이터(AVD) 만들기
1. Android Studio → **More Actions → Virtual Device Manager** (또는 Device Manager).
2. **Create Device → 카테고리 `Wear OS`** → 예: **Wear OS Large Round** 선택 → Next.
3. 시스템 이미지: **API 34**(Wear OS 4) 또는 **API 30**(Wear OS 3, 갤럭시 워치4 기준) 다운로드 → 선택 → Finish.
4. Device Manager에서 그 워치 AVD의 ▶(재생)로 부팅 → 원형 워치 화면이 뜨면 성공.

## 5. 저장소 클론
```
cd C:\projects
git clone git@github.com:jhkim1010/ubf_conferencia.git
cd ubf_conferencia\ubf_watch
```
> SSH 키가 이 PC에 없으면 HTTPS로: `git clone https://github.com/jhkim1010/ubf_conferencia.git`

## 6. 워치 앱 실행
```
flutter pub get
flutter devices        # 실행 중인 Wear OS 에뮬레이터가 목록에 보여야 함
flutter run            # 에뮬레이터가 하나면 자동 선택
```
- 여러 기기가 있으면: `flutter run -d <에뮬레이터_id>` (id는 `flutter devices`에 표시).
- 실행되면 워치 화면에 **3개 카드**가 뜹니다 — 좌우로 스와이프:
  1. **다음 일정** (14:00 개회 예배 · 본당 2층)
  2. **내 픽업** (1호차 · 14:20 · 집결 T1 5번 출구)
  3. **SOS** (빨간 버튼 → 확인 → 전송)
- 지금은 **목업 데이터**입니다. 실 서버 연동(내 일정/픽업/SOS 실제 전송)은 다음 단계(폰→워치 토큰 전달)에서.

## 7. 자주 겪는 문제
| 증상 | 해결 |
|---|---|
| `flutter devices`에 에뮬레이터 안 보임 | 4단계에서 워치 AVD를 먼저 부팅했는지 확인 |
| Gradle/최초 빌드가 느림 | 첫 빌드는 의존성 다운로드로 수 분 소요 — 정상 |
| `minSdk` 오류 | 워치 앱은 `minSdk 30`. API 30↑ 이미지의 AVD 사용 |
| 라이선스 오류 | `flutter doctor --android-licenses` 다시 동의 |

## 참고 — 맥에서도 동일
이 저장소가 있는 macOS에서도 Android Studio로 Wear OS AVD를 만들면 `cd ubf_watch && flutter run`으로 똑같이 실행됩니다. (Windows 전용 아님)
