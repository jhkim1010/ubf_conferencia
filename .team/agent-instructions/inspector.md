## 이 저장소 전용 검사 항목

**"테스트 통과"는 이 저장소에서 유효한 증거가 아닙니다.** 기존 스위트는 플레이스홀더뿐입니다.
Implementer가 "테스트 통과"만 근거로 제시했다면 NOGO 사유입니다. 실행 명령과 실제 출력을
요구하십시오.

기본 5개 기준에 더해 아래를 확인하십시오. 하나라도 걸리면 NOGO입니다.

### 1. 배선 누락
- 새 라우터가 `server/src/index.js`의 `app.use('/<path>', ...)`에 등록되었는가
- 새 화면이 `ubf_app/lib/app.dart`의 `GoRouter` 라우트에 등록되었는가

### 2. 마이그레이션 안전성
- 파일이 `ubf_app/supabase/migrations/`에 있는가 (server 아래에 만들었다면 NOGO)
- **모든 구문이 멱등인가** — `migrate.js`는 이력 추적 없이 매번 전체를 재실행합니다
- 파괴적 구문(`DROP COLUMN`, 조건 없는 `DELETE`/`UPDATE`)이 없는가
- 번호가 기존 파일과 겹치지 않는가 (`012_`가 이미 중복 상태)
- 기존 마이그레이션 파일을 사후 수정하지 않았는가
- **두 번 연속 실행해도 `✗`가 없는가**를 직접 확인하십시오

### 3. 다국어 완전성
`app_en.arb` / `app_ko.arb` / `app_es.arb` 세 파일의 키 집합이 일치하는가.
`app_localizations*.dart`(생성물)를 직접 편집하지 않았는가.

### 4. 계층 규약
- DB 접근이 `sql` 태그 함수를 경유하는가 (`pg.Pool` 직접 생성 시 NOGO)
- 비즈니스 로직이 `src/services/`에 있는가 (라우트 안에 엔진 로직을 박았다면 지적)
- Flutter에서 `http` 패키지 직접 호출이 없는가 (`ApiClient` 경유)
- Riverpod 코드 생성(`@riverpod`, `.g.dart`)을 도입하지 않았는가
- 새 기능이 `lib/features/<도메인>/` 아래 배치되었는가

### 5. 정합성
- `UserRole`(Dart) ↔ 서버 역할 문자열이 양쪽 모두 반영되었는가
- `ApiClient`의 플랫폼별 토큰 저장 분기가 보존되었는가
- 인증 흐름 변경 시 네이티브(idToken)·웹(accessToken) 양쪽이 검증되었는가

### 6. 위생
- `server/.env`나 커넥션 문자열·토큰이 diff에 포함되지 않았는가
- 생성물(`build/`, `.dart_tool/`, `app_localizations*.dart`)이 diff에 섞이지 않았는가
- 요청 범위를 넘는 리팩터링·의존성 추가·포맷 일괄 변경이 없는가

## 직접 실행할 것

보고서를 읽는 것으로 끝내지 말고 최소한 아래는 직접 돌리십시오.

```bash
cd ubf_app && flutter analyze          # 무경고여야 함
node --check server/src/<변경파일>.js
git diff --stat                        # 범위 밖 변경 확인
```
