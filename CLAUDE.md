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
```

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
정렬 순으로 **전체를 매번 재실행**하고, 실패한 구문은 `✗`로 로그만 남기고 넘어갑니다.

따라서:

- **모든 마이그레이션은 멱등이어야 합니다.** `CREATE TABLE IF NOT EXISTS`,
  `ADD COLUMN IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`, `DROP ... IF EXISTS`.
  기존 파일들이 이 규칙을 따르고 있으니 그대로 맞추십시오.
- `npm run migrate` 출력에 `✗`가 있으면 성공이 아닙니다. 반드시 읽고 판단하십시오.
- 파괴적 구문(`DROP COLUMN`, `DELETE`, `UPDATE` 전체 갱신)은 재실행 시 데이터가 날아갑니다.
  넣지 마십시오.

**알려진 문제**: `012_program_host_country.sql`과 `012_transport.sql`이 번호가 겹칩니다.
정렬은 파일명 기준이라 현재는 결정적으로 동작하지만, 새 파일은 `014_`부터 시작하고
번호를 재사용하지 마십시오.

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

## 테스트 현실

**실질적인 테스트가 없습니다.** `ubf_app/test/widget_test.dart`와
`ubf_watch/test/widget_test.dart` 둘 다 `expect(true, isTrue)` 플레이스홀더이고,
서버에는 테스트 러너 자체가 없습니다.

그러므로 "테스트가 통과했다"를 검증 근거로 삼을 수 없습니다. 변경 후 최소 확인선:

- Flutter: `flutter analyze` 무경고
- 서버: `node --check <파일>` + 실제 엔드포인트 호출 (`curl`)
- DB가 걸린 변경: 마이그레이션을 실제로 적용해 보고 `✗`가 없는지 확인

테스트를 새로 추가하는 것은 환영하지만, 있지도 않은 스위트를 근거로 완료를 보고하지 마십시오.

---

## CI

`.github/workflows/build-release.yml` — **태그 푸시에서만** 동작합니다. PR/푸시 CI는 없습니다.
Flutter 3.44.6 고정, web/android(APK)/windows/linux/macos 6개 잡. 앱 버전이나 Flutter
버전을 올릴 때 이 워크플로의 `FLUTTER_VERSION`을 함께 맞추십시오.

Windows 인스톨러 등 산출물은 `~/Dropbox/Personal de m. Marcos`에 복사하는 것이 관례입니다.

---

## 하지 말 것

- `app_localizations*.dart`, `ubf_app/build/`, `.dart_tool/` 직접 편집
- `server/.env` 커밋, 커넥션 문자열·토큰을 코드나 커밋 메시지에 넣기
- 마이그레이션에 비멱등·파괴적 구문 넣기, 기존 마이그레이션 파일 사후 수정
- 라우트에서 `pg.Pool` 직접 생성, 화면에서 `http` 직접 호출
- 요청하지 않은 리팩터링·의존성 추가·포맷 일괄 변경
