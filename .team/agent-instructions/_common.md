이 저장소는 `ubf_conferencia` — UBF 국제 컨퍼런스 참가자 관리 시스템입니다.
`ubf_app/`(Flutter 3.44.6) · `server/`(Node ESM + Express + Postgres/Neon) · `ubf_watch/`(Wear OS, 초기 단계).

루트 `CLAUDE.md`에 전체 규약이 있습니다. 작업 시작 전에 읽으십시오. 아래는 위반 빈도가 높은 항목만 추린 것입니다.

## 반드시 지킬 것

**서버는 ESM 전용.** `require` 금지.

**DB는 `server/src/db.js`의 `sql` 태그 함수로만** 접근합니다. 라우트에서 `pg.Pool`을 직접 만들지
마십시오. 트랜잭션은 `sql.transaction(async (client) => ...)`. 값 보간은 자동 파라미터화되지만
**식별자(테이블·컬럼명)는 보간 불가** — 동적 컬럼은 허용 목록으로 분기하십시오.

**새 라우터는 `server/src/index.js`의 `app.use(...)` 목록에 등록**해야 합니다. 빠뜨리면 조용히 404입니다.

**마이그레이션은 `ubf_app/supabase/migrations/`** 에 있습니다(server 아래가 아님). `migrate.js`에
적용 이력 추적이 **없어서 매 실행마다 전체가 재실행**됩니다. 그러므로:
- 모든 구문이 멱등이어야 합니다 (`IF NOT EXISTS` / `IF EXISTS`).
- 파괴적 구문(`DROP COLUMN`, 무조건 `DELETE`/`UPDATE`) 금지.
- 새 파일은 `014_`부터. 기존 번호 재사용 금지 (`012_`가 이미 중복돼 있습니다).
- `npm run migrate` 출력에 `✗`가 있으면 실패입니다. 반드시 읽으십시오.

**Flutter는 feature-first** — `lib/features/<도메인>/{screens,providers}`. 새 기능은 새 도메인
폴더로. `core/`나 다른 도메인에 섞지 마십시오.

**Riverpod은 손으로 선언합니다. 코드 생성을 쓰지 않습니다** — `@riverpod`나 `.g.dart`를
도입하지 마십시오. 기존 패턴(`StateNotifierProvider`, 파생 `Provider`, `FutureProvider.family`)을
따르십시오.

**HTTP는 `core/utils/api_client.dart`의 static `ApiClient`만** 사용합니다. 화면·프로바이더에서
`http` 패키지 직접 호출 금지. `ApiClient`의 플랫폼별 토큰 저장 분기(웹·macOS는
SharedPreferences, iOS·Android는 FlutterSecureStorage)를 제거하지 마십시오.

**UI 문자열은 3개 ARB 전부에 추가** — `lib/l10n/app_en.arb`(템플릿) / `app_ko.arb` / `app_es.arb`.
하나라도 빠지면 그 로케일에서 누락됩니다. `app_localizations*.dart`는 생성물이므로 직접 편집 금지.

주석·문서는 한국어로 씁니다 (기존 코드 관례).

## 검증 — `./verify.sh` 를 통과시킬 것

저장소 루트의 `./verify.sh` 가 단일 검증 진입점입니다. 작업을 마치기 전에 통과시키십시오.

```bash
./verify.sh --changed     # 변경 파일에 해당하는 검사만 — 작업 중 반복 실행용
./verify.sh               # 전체 — 완료 보고 전 최종 확인
./verify.sh --list        # 검사 목록
```

종료 코드 0=통과, 1=실패. **SKIP(전제 미충족)은 통과가 아닙니다** — 요약에 건너뜀 건수가
있으면 무엇이 왜 건너뛰어졌는지 확인하고 보고에 적으십시오.

**일부 검사는 훅으로 자동 실행됩니다.** 파일을 편집하면 해당 종류에 맞는 빠른 검사가
즉시 돌고, 실패하면 편집이 차단되며 원인이 전달됩니다. `.dart` 편집 시 `flutter analyze`
가 비동기로 돌고 실패할 때만 알려옵니다. `git commit` 직전에는 `secrets`/`artifacts` 가
돌아 비밀정보·산출물 커밋을 차단합니다.

훅이 실패를 알려오면 **고친 뒤 진행하십시오.** 우회하지 마십시오 — 검사를 비활성화하거나,
검사를 통과시키기 위해 검사 자체를 수정하거나, 다른 도구로 우회 편집하지 마십시오.
오탐이라고 판단되면 그 근거와 함께 사용자에게 확인을 요청하십시오.

검사 항목: `flutter-analyze` `dart-format` `server-syntax` `arb-parity` `route-parity`
`migration-numbers` `migration-safety` `secrets` `artifacts` `server-smoke`

**테스트 스위트는 없습니다.** `widget_test.dart` 는 플레이스홀더이고 서버에는 러너가
없습니다. "테스트 통과"를 완료 근거로 쓰지 마십시오 — 근거는 `./verify.sh` 출력입니다.
새 테스트 추가는 환영하며, `server/src/services/` 의 두 엔진은 DB 없이 검증 가능하므로
`node --test` 대상으로 적합합니다.

`dart-format` 은 변경된 파일만 봅니다. 기존 파일을 수정하면 그 파일의 포맷도 맞추십시오.

`node`/`flutter`/`dart`는 `/opt/homebrew/bin`에 있습니다. 비로그인 셸에서는 PATH에 없으므로
`export PATH="/opt/homebrew/bin:$PATH";`를 붙이거나 `zsh -lc '...'`로 실행하십시오.

## 하지 말 것

- `server/.env` 커밋, 커넥션 문자열·토큰을 코드나 커밋 메시지에 노출
- 생성물(`app_localizations*.dart`, `build/`, `.dart_tool/`) 편집
- 기존 마이그레이션 파일 사후 수정
- 요청하지 않은 리팩터링·의존성 추가·포맷 일괄 변경
