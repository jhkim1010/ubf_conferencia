## 이 저장소 계획 시 반드시 다룰 것

계획서(plan.md)에 아래 항목이 해당되면 **명시적으로** 포함하십시오. 빠지면 Design Reviewer가
반려해야 하는 항목입니다.

### 변경 범위를 3축으로 나눠 적으십시오
`ubf_app/`(Flutter) · `server/`(API) · `ubf_app/supabase/migrations/`(스키마).
대부분의 기능은 세 축을 동시에 건드립니다. 한 축만 적힌 계획은 대개 불완전합니다.

### 스키마 변경이 있으면
- 새 파일명을 정하십시오 — `014_`부터 시작, 기존 번호 재사용 금지(`012_`가 이미 중복)
- **멱등 작성 방침**을 명시하십시오 (`IF NOT EXISTS` / `IF EXISTS`).
  `migrate.js`는 이력 추적 없이 매 실행마다 전체를 재실행합니다.
- 파괴적 구문이 필요하다고 판단되면, 그것은 이 파이프라인에서 안전하지 않으므로
  대안(새 컬럼 추가 + 점진 이행)을 계획에 적으십시오.

### API 변경이 있으면
- 새 라우터라면 `server/src/index.js` 등록을 단계로 적으십시오 (누락 빈발)
- 비즈니스 로직은 `src/services/`에 둘 것인지 명시 (라우트에 로직을 박지 않음)
- 응답 스키마 변경 시 Flutter 쪽 소비 지점을 함께 나열

### 화면 변경이 있으면
- 배치될 도메인 폴더 (`lib/features/<도메인>/`)
- `app.dart`의 `GoRouter` 등록 필요 여부
- 상태관리 방식 — 기존 패턴(`StateNotifierProvider` / 파생 `Provider` /
  `FutureProvider.family`) 중 무엇인지. **코드 생성은 쓰지 않습니다.**
- **새 UI 문자열 목록** — ARB 3개(`en`/`ko`/`es`) 갱신을 단계로 포함

### 검증 계획
**이 저장소에는 동작하는 테스트 스위트가 없습니다.** "테스트 작성 후 통과 확인" 같은
막연한 검증 단계를 쓰지 마십시오. 대신 실제로 실행 가능한 것을 적으십시오:

- `flutter analyze` 무경고
- `node --check` + 구체적인 `curl` 호출 (경로·기대 응답까지)
- 마이그레이션 2회 연속 실행 후 `✗` 없음

순수 로직(`assignment_engine` / `dispatch_engine` 계열)에 대해서는 `node --test` 기반
테스트 추가를 계획에 포함시키는 것이 바람직합니다. 러너를 새로 도입하는 것이라면
그 사실을 계획에 적으십시오.

### 위험 구간
아래를 건드리는 계획이면 위험 항목으로 별도 표기하십시오.
- Google 로그인 흐름 (네이티브 idToken / 웹 accessToken 이원화 — 과거에 다층 수정한 부분)
- `ApiClient`의 플랫폼별 토큰 저장 분기 (웹·macOS ↔ iOS·Android)
- `UserRole` enum ↔ 서버 역할 문자열 (한쪽만 바꾸면 권한이 조용히 틀어짐)
- `AppConstants.apiBaseUrl` (현재 `http://localhost:3000` 하드코딩)
