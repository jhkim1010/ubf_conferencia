# ubf_conferencia

UBF 국제 컨퍼런스 참가자 관리 시스템. 3개 컴포넌트 모노레포.

| 디렉터리 | 스택 | 역할 |
|---|---|---|
| `ubf_app/` | Flutter 3.44.6 / Dart | 메인 앱 (web·android·ios·windows·linux·macos) |
| `server/` | Node ESM + Express 4 + Postgres(Neon) | REST API |
| `ubf_watch/` | Flutter (Wear OS) | 워치 컴패니언 — 초기 단계 |

## 명령

```bash
# 서버 (server/)
npm run dev          # node --watch src/index.js
npm start
npm run migrate      # ⚠ 아래 "마이그레이션" 절을 먼저 읽을 것

# 앱 (ubf_app/)
flutter pub get      # gen-l10n 도 함께 실행됨
flutter analyze
flutter run -d chrome

./flutter_run.sh -d chrome   # 루트에서 실행. 로그를 logs/flutter_<ts>.log 로 저장

# 웹으로 실제 확인할 때 (루트에서)
./serve-web.sh               # 빌드 + API(:3000, stage DB) + 웹(:8080) 기동
./serve-web.sh --no-build    # 이미 빌드돼 있으면
```

**웹 검증은 `./serve-web.sh` 를 쓰십시오.** `flutter build web` 을 직접 돌리지 마십시오 —
기본 빌드는 서비스 워커를 등록해 예전 번들을 캐시합니다. 코드를 고쳐 다시 빌드해도
브라우저가 옛 화면을 계속 보여주며, 이 함정에 실제로 빠진 적이 있습니다.
스크립트는 `--pwa-strategy=none` 으로 빌드해 서비스 워커를 만들지 않습니다.

**포트 8080 을 바꾸지 마십시오.** 구글 OAuth 는 승인된 JavaScript 원본을 origin(포트 포함)
단위로 검사합니다. Google Cloud Console 에 `http://localhost:8080` 만 등록돼 있어
다른 포트로 띄우면 로그인이 `400 origin_mismatch` 로 막힙니다.

릴리스 빌드는 `.github/workflows/build-release.yml` 이 담당하며 서비스 워커를 그대로 둡니다.
`serve-web.sh` 는 로컬 검증 전용입니다.

`node`/`flutter`/`dart`는 `/opt/homebrew/bin`에 있습니다. 비로그인 셸에서는 PATH에 없으므로
`export PATH="/opt/homebrew/bin:$PATH";`를 앞에 붙이거나 `zsh -lc '...'`로 실행하십시오.

서버는 `PORT`(기본 3000), `DATABASE_URL`, `JWT_SECRET`, `GOOGLE_CLIENT_ID`,
`GOOGLE_IOS_CLIENT_ID`, `ALLOWED_ORIGINS`를 사용합니다. `server/.env`는 커밋하지 않습니다.
헬스체크: `GET /health`.

---

## 서버 규칙

**ESM 전용.** `import`/`export`만 씁니다. `require`는 쓰지 않습니다.

**DB 접근은 `src/db.js`의 `sql` 태그 함수 하나로 통일**되어 있습니다. `pg.Pool`을 라우트에서
직접 만들지 마십시오.

```js
import { sql } from '../db.js';

const rows = await sql`SELECT * FROM users WHERE id = ${userId}`;   // 자동 파라미터화
await sql.transaction(async (client) => { /* client.query(...) */ });  // BEGIN/COMMIT/ROLLBACK
```

값 보간은 `$n` 플레이스홀더로 변환됩니다. **식별자(테이블·컬럼명)는 보간할 수 없습니다** —
동적 컬럼이 필요하면 허용 목록으로 분기하십시오.

**인증은 `src/middleware/auth.js`**의 `requireAuth` / `requireProgramAdmin`을 씁니다.
Google ID 토큰(네이티브) 또는 accessToken(웹) → 자체 JWT 교환 구조입니다. 이 흐름은
웹 로그인 수정 과정에서 다층으로 손본 부분이라, 건드릴 때는 네이티브·웹 양쪽을 모두 확인하십시오.

**새 라우터를 추가하면 `src/index.js`의 `app.use('/<path>', router)` 목록에 등록**해야 합니다.
빠뜨리면 조용히 404가 납니다.

**비즈니스 로직은 `src/services/`로 분리**합니다. 현재 `assignment_engine.js`(그룹 배정),
`dispatch_engine.js`(교통 배차)가 있고, 라우트는 데이터 로드 → 엔진 호출 → 영속화만 담당합니다.
알림은 `fcm.js`(푸시), `telegram.js`를 통합니다.

주석은 한국어로 씁니다 (기존 코드 관례).

---

## 마이그레이션 — 주의 필요

SQL 파일 위치는 **`ubf_app/supabase/migrations/`** 입니다. `server/` 아래가 아닙니다.
(Supabase는 쓰지 않습니다. Neon Postgres를 씁니다. 경로만 초기 흔적으로 남아 있습니다.)

`server/src/db/migrate.js`에는 **적용 이력 추적 테이블이 없습니다.** 실행할 때마다 파일명
정렬 순으로 **전체를 매번 재실행**합니다. 실패한 구문은 `✗`로 기록하되 중단하지 않고
끝까지 진행한 뒤(모든 문제를 한 번에 보기 위함), **실패가 하나라도 있으면 exit 1**로 끝납니다.

따라서:

- **모든 마이그레이션은 멱등이어야 합니다.** `CREATE TABLE IF NOT EXISTS`,
  `ADD COLUMN IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`, `DROP ... IF EXISTS`.
  기존 파일들이 이 규칙을 따르고 있으니 그대로 맞추십시오.
- `npm run migrate`는 실패 시 exit 1입니다. 종료 코드를 확인하십시오.
- 파괴적 구문(`DROP COLUMN`, `DELETE`, `UPDATE` 전체 갱신)은 재실행 시 데이터가 날아갑니다.
  넣지 마십시오.

번호는 재사용하지 마십시오. `verify.sh migration-numbers`가 중복을 잡습니다.
(과거 `012_`가 중복되어 `012_transport.sql` → `014_transport.sql`로 정리했습니다.
이력 추적이 없어 파일명이 어디에도 기록되지 않고 모든 구문이 멱등이라 DB에는 무영향이었습니다.)

---

## Flutter 앱 규칙

**구조는 feature-first**입니다.

```
lib/
  main.dart, app.dart          # 앱 진입 + GoRouter 정의
  core/
    constants/                 # app_constants, countries, ubf_chapters, world_countries
    utils/                     # api_client, flight_api_service, export_service
    theme/
  features/<도메인>/
    screens/                   # 화면 (필요 시 steps/ 하위 분할)
    providers/                 # Riverpod
  l10n/                        # ARB + 생성된 AppLocalizations
```

현재 도메인: `auth` `registration` `schedule` `transport` `assignment` `program`
`dashboard` `setup` `home`. 새 기능은 새 도메인 폴더로 추가하고, 화면을 `core/`나
다른 도메인에 섞지 마십시오.

**상태관리는 Riverpod을 손으로 선언**합니다. `riverpod_annotation`이 의존성에 있지만
**코드 생성은 쓰지 않습니다** — `@riverpod`도 `.g.dart`도 저장소에 없습니다. 기존 패턴을 따르십시오:

```dart
class AuthNotifier extends StateNotifier<AuthState> { ... }
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// 파생 값은 얇은 Provider 로
final userRoleProvider = Provider<UserRole>((ref) => ref.watch(authProvider).role);

// 서버 조회는 FutureProvider.family
final myTransportProvider = FutureProvider.family<Map<String, dynamic>, String>(...);
```

상태 클래스는 불변 + `const` 생성자 + `copyWith` 형태입니다.

**HTTP는 `core/utils/api_client.dart`의 static `ApiClient`만** 씁니다. 화면이나 프로바이더에서
`http` 패키지를 직접 부르지 마십시오. 토큰 저장은 플랫폼별로 갈립니다 —
웹/macOS는 `SharedPreferences`, iOS/Android는 `FlutterSecureStorage` (macOS 키체인
엔타이틀먼트 회피). 이 분기를 지우지 마십시오.

`AppConstants.apiBaseUrl`은 `http://localhost:3000` 하드코딩입니다. 배포 대상을 바꿀 때
여기를 함께 확인하십시오.

**라우팅은 `app.dart` 안의 단일 `GoRouter`** 정의입니다. 화면을 추가하면 여기에 `GoRoute`를
등록합니다.

**사용자 역할은 `UserRole { director, admin, participant }`** 이며 서버 문자열과 1:1로 맞춰야
합니다. 여기에 값을 추가하면 서버 쪽도 함께 바꿔야 합니다.

---

## 다국어 — 3개 언어 동시 갱신

`lib/l10n/app_en.arb`(키 템플릿) · `app_ko.arb` · `app_es.arb`.

**문자열을 추가하면 3개 ARB 전부에 넣어야 합니다.** 하나라도 빠뜨리면 해당 로케일에서
누락됩니다. `app_localizations*.dart`는 `flutter gen-l10n`(또는 `flutter pub get`) 산출물이므로
**직접 편집하지 마십시오.**

UI 문자열을 Dart 코드에 하드코딩하지 마십시오.

---

## 검증 — `./verify.sh`

**변경 후에는 `./verify.sh`를 통과시키십시오.** 이것이 이 저장소의 단일 검증 진입점입니다.

```bash
./verify.sh                  # 전체 (실패가 있어도 끝까지 돌고 요약)
./verify.sh --changed        # 변경된 파일에 해당하는 검사만 — 작업 중 빠른 확인용
./verify.sh --list           # 검사 목록
./verify.sh arb-parity       # 특정 검사만
```

검사는 잘게 나뉘어 있고 각각 독립 실행 가능합니다. 훅에서 필요한 것만 골라 걸 수 있게 한 설계입니다.

| 검사 | 잡는 것 |
|---|---|
| `flutter-analyze` | Dart 정적 분석 경고 |
| `dart-format` | 변경된 dart 파일의 포맷 (전체가 아닌 변경분만) |
| `server-syntax` | 서버 JS 파싱 오류 |
| `unit-tests` | `server/test/` 단위 테스트 (`node --test`) |
| `arb-parity` | `en`/`ko`/`es` ARB 키 집합 불일치 |
| `route-parity` | `routes/*.js` ↔ `index.js` 등록 누락 (조용한 404) |
| `migration-numbers` | 마이그레이션 번호 중복 |
| `migration-safety` | 비멱등·파괴적 SQL (`IF NOT EXISTS` 누락, `WHERE` 없는 `DELETE`/`UPDATE`) |
| `secrets` | 추적 파일 내 커넥션 문자열·`.env` |
| `artifacts` | 빌드 산출물 추적, ARB 없이 생성물만 손편집 |
| `server-smoke` | 서버 기동 + `/health` 응답 |

종료 코드는 0(전부 통과) / 1(하나 이상 실패)입니다. 전제가 없어 건너뛴 검사(SKIP)는
실패로 치지 않지만 요약에 별도로 표시되므로, **SKIP이 많으면 통과를 신뢰하지 마십시오.**

`VERIFY_BASE`를 주면 워킹트리 대신 해당 커밋 대비 diff로 변경 파일을 판정합니다
(CI에서 사용). 예: `VERIFY_BASE=origin/main ./verify.sh dart-format`

### 자동 실행되는 훅

`.claude/settings.json`에 훅이 걸려 있어 **아래는 직접 실행하지 않아도 자동으로 돕니다.**

| 시점 | 대상 | 실행 | 동작 |
|---|---|---|---|
| 파일 편집 직후 | 편집한 파일 종류에 맞는 빠른 검사 | 블로킹 (~1초 이내) | 실패 시 편집이 차단되고 원인이 전달됨 |
| `.dart` 편집 직후 | `flutter analyze` | 비동기 (~3초) | 실패할 때만 알림 |
| `git commit` 직전 | `secrets` `artifacts` | 블로킹 | 비밀정보·산출물이 있으면 커밋 차단 |
| 턴 종료 직전 | `./verify.sh --changed` | 블로킹 | 실패 시 종료가 차단됨 |

턴 종료 훅이 따로 있는 이유는, 편집 직후 훅이 "방금 건드린 파일"만 보기 때문입니다.
여러 파일에 걸친 변경은 개별 시점에는 정합했다가 최종 상태에서 깨질 수 있습니다
(라우터 파일을 만들고 `index.js` 등록을 잊은 채 다른 작업으로 넘어가는 경우 등).

**cmux-team이 관리하는 세션(`CMUX_SURFACE` 설정됨)에서는 종료를 차단하지 않고 보고만
합니다.** cmux-team은 Agent의 Stop 훅에서 완료를 daemon에 보고하고 daemon이 done-marker를
쓰는데, 여기서 종료를 막으면 Conductor가 "완료"로 알고 결과를 통합하는 동안 Agent는 계속
작업하는 경쟁 상태가 생기기 때문입니다. 그 경로는 Inspection 단계가 대신 잡습니다.
해제하려면 `UBF_STOP_HOOK=off`.

편집 직후 훅은 파일 종류로 검사를 고릅니다 — `.arb`→`arb-parity`,
`server/src/routes/*.js`→`server-syntax`+`route-parity`, `migrations/*.sql`→
`migration-numbers`+`migration-safety`, `.dart`→`dart-format`. `secrets`는 항상 돕니다.

훅이 실패를 알려오면 고친 뒤 진행하십시오. 훅을 우회하려 하지 말고, 오탐이라고 판단되면
사용자에게 확인을 요청하십시오. 훅 구현은 `.claude/hooks/`에 있습니다.

**훅이 자동으로 잡아주므로 같은 검사를 손으로 반복할 필요는 없습니다.** 다만 훅은 편집한
파일에 해당하는 것만 돌리므로, 작업을 마칠 때 `./verify.sh` 전체를 한 번 통과시키십시오.

### 검사·게이트를 추가하거나 고칠 때 — 반드시 깨뜨려 볼 것

`verify.sh`의 검사, `.claude/hooks/`의 훅, CI 스텝을 만들거나 수정했다면
**"통과했다"로 끝내지 마십시오.** 잘못 만든 검사는 항상 통과하므로, 정상 입력에서의
통과와 구분되지 않습니다.

1. 정상 입력에서 통과 확인
2. **위반을 일부러 만들어 실제로 실패하는지 확인** (검사는 exit 1, 훅은 exit 2)
3. 만든 위반을 원상복구하고 `git status`로 확인
4. 깨뜨려 본 방법과 그때의 출력을 보고에 포함

이 저장소에서 실제로 세 번 발생한 유형입니다 — `grep -E`에 PCRE 부정 선읽기를 써서
마이그레이션 안전성 검사가 아무것도 잡지 못한 채 통과, CI 포맷 검사가 항상 SKIP,
`mapfile`(bash 4+)을 bash 3.2에서 써서 `--changed`가 아무 검사도 안 하고 통과.

관련해서:

- **SKIP은 통과가 아닙니다.** 전제가 없어 검사가 돌지 않은 것입니다.
- **`verify.sh`는 bash 3.2에서 돌아야 합니다** (macOS 기본). `mapfile` / `readarray` /
  `declare -A` / `${v^^}` 금지.
- **로컬(macOS, bash 3.2)과 CI(ubuntu, bash 5)는 환경이 다릅니다.** 한쪽만 확인하고
  양쪽에서 동작한다고 단정하지 마십시오.

### 테스트 현실

**서버**에는 단위 테스트가 있습니다 — `cd server && npm test` (Node 내장 러너, 의존성 없음).
현재 대상은 `src/services/`의 순수 로직 엔진 두 개(배정·배차) 46개이며 `./verify.sh unit-tests`
로도 돕니다. **이 엔진들을 수정하면 테스트도 함께 갱신하십시오.** DB나 HTTP가 필요 없는
로직을 새로 만들면 `server/test/*.test.js`에 추가하십시오.

**Flutter**는 여전히 실질적인 테스트가 없습니다. `ubf_app/test/widget_test.dart`와
`ubf_watch/test/widget_test.dart` 둘 다 `expect(true, isTrue)` 플레이스홀더입니다.
Flutter 쪽 변경에 대해 "테스트가 통과했다"를 완료 근거로 삼지 마십시오 — 근거는
`flutter analyze`와 실제 실행입니다.

라우트·화면처럼 테스트가 어려운 영역은 실행 검증으로 대체하고, 무엇을 어떻게 확인했는지
명령과 출력으로 남기십시오.

`dart-format`은 변경된 파일만 봅니다. 저장소 전체는 아직 `dart format` 기준을 만족하지
않으므로(47개 중 40개), 손대는 파일부터 기준을 맞춰 점진적으로 수렴시키는 방식입니다.
기존 파일을 수정하면 그 파일의 포맷도 함께 맞춰야 합니다.

---

## CI

- **`verify.yml`** — push(main) / PR / 수동. `./verify.sh`의 검사들을 3개 잡
  (정합성 · 서버 · Flutter)으로 나눠 돌리는 머지 전 게이트입니다.
  `server-smoke`는 `DATABASE_URL_CI` 시크릿이 설정된 경우에만 실제로 동작하고,
  없으면 SKIP됩니다.
- **`build-release.yml`** — `v*` 태그 푸시에서만 동작하는 릴리스 빌드.
  web/android(APK)/windows/linux/macos.

두 워크플로 모두 Flutter 3.44.6으로 고정돼 있습니다. 버전을 올릴 때 양쪽의
`FLUTTER_VERSION`을 함께 맞추십시오.

Windows 인스톨러 등 산출물은 `~/Dropbox/Personal de m. Marcos`에 복사하는 것이 관례입니다.

---

## 하지 말 것

- `app_localizations*.dart`, `ubf_app/build/`, `.dart_tool/` 직접 편집
- `server/.env` 커밋, 커넥션 문자열·토큰을 코드나 커밋 메시지에 넣기
- 마이그레이션에 비멱등·파괴적 구문 넣기, 기존 마이그레이션 파일 사후 수정
- 라우트에서 `pg.Pool` 직접 생성, 화면에서 `http` 직접 호출
- 요청하지 않은 리팩터링·의존성 추가·포맷 일괄 변경
