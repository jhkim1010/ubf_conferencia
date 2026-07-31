## 이 저장소에서의 태스크 분해

**3축을 기준으로 분해하십시오**: `ubf_app/`(Flutter) · `server/`(API) ·
`ubf_app/supabase/migrations/`(스키마). 대부분의 기능은 세 축을 모두 건드리며,
**스키마 → API → 화면** 순서 의존성이 있습니다. 화면 Agent를 API 확정 전에 띄우면
재작업이 발생합니다.

## worktree 주의

태스크마다 `.worktrees/task-NNN-<ts>`가 생성되지만, 이 저장소에서 주의할 점이 있습니다.

- **`ubf_app/`은 worktree마다 `flutter pub get`이 필요**합니다. `.dart_tool/`은
  worktree에 따라오지 않습니다. Agent 프롬프트에 이 단계를 넣으십시오.
- **`server/node_modules`도 마찬가지**입니다. 서버 작업 Agent에게 `npm install` 단계를 주십시오.
- **DB는 worktree 격리 대상이 아닙니다.** 여러 태스크가 같은 Neon 인스턴스를 공유합니다.
  스키마를 건드리는 태스크는 **동시에 두 개 이상 배정하지 마십시오** —
  Master에게 `--exclusive` 태스크로 제안하십시오.

## 병렬 배정 금지 조합

같은 시점에 병렬로 돌리면 충돌하는 것들입니다. 순차로 묶으십시오.

- 마이그레이션을 추가하는 태스크 2개 이상 (번호 충돌 + 공유 DB)
- ARB 3파일을 동시에 건드리는 태스크 2개 이상 (`app_en/ko/es.arb`는 충돌 다발 지점)
- `server/src/index.js` 라우터 등록이 필요한 태스크 2개 이상 (같은 블록을 수정)

## Agent 프롬프트에 포함할 것

각 Agent를 띄울 때 작업 디렉터리와 함께 아래를 명시하십시오.

```
작업 전: cd <worktree>/ubf_app && flutter pub get      # Flutter 작업 시
작업 전: cd <worktree>/server && npm install           # 서버 작업 시
PATH: export PATH="/opt/homebrew/bin:$PATH"            # 비로그인 셸에서 필요
```

## 통합 전 확인 (Step 6.5 잔여물 검사에 추가)

```bash
cd ubf_app && flutter analyze          # 무경고
git diff --stat                         # 범위 밖 변경 없음
git diff --name-only | grep -E 'app_localizations.*\.dart|\.dart_tool|/build/|\.env'
#   ↑ 위 grep 이 무언가 출력하면 커밋하지 말 것 (생성물/비밀 유출)
```

ARB를 건드린 태스크라면 `en`/`ko`/`es` 세 파일의 키 집합이 일치하는지 확인하십시오.

## rebase 시

`ubf_app/lib/l10n/*.arb`와 `server/src/index.js`의 라우터 등록 블록은 충돌 빈발 지점입니다.
의미 기준으로 병합하십시오 — 양쪽 항목을 **모두** 살리는 것이 거의 항상 정답입니다.
한쪽을 버리면 조용히 기능이 사라집니다.
