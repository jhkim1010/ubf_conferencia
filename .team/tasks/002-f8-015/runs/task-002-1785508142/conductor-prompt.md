# Task Assignment

## Task Content

---
id: 002
title: F8 봉사신청 스키마 (015 마이그레이션)
priority: high
run_after_all: true
exclusive: true
created_at: 2026-07-31T14:29:02.708Z
---

## Task
## 무엇을

F8 봉사 참여 신청 기능의 DB 스키마를 만든다. 마이그레이션 파일 하나만 추가한다.

## 반드시 먼저 읽을 것

**`.team/artifacts/A001-f8-service-signup.md`** — 4절 "데이터 모델"에 필요한 DDL 이
그대로 있다. 확정된 결정 7건(D1~D7)도 여기 있다. 이 문서를 따른다.

저장소 규약은 루트 **`CLAUDE.md`** 를 따른다.

## 범위 — 이것만 한다

`ubf_app/supabase/migrations/015_service_signup.sql` **파일 하나.**

- `users` 에 컬럼 추가: is_missionary, is_missionary_verified, shepherd_since,
  shepherd_verified, has_driver_license, driver_license_country
- `programs` 에 컬럼 추가: service_options (JSONB)
- `registrations` 에 컬럼 추가: service_declined (BOOLEAN)
- `service_signups` 테이블 신규 + 인덱스

**API 도 화면도 건드리지 않는다.** server/ 와 ubf_app/lib/ 는 수정 대상이 아니다.

## 절대 지킬 것

`migrate.js` 에는 적용 이력 추적이 없어 매 실행마다 전체가 재실행된다. 따라서:

- 모든 구문이 멱등이어야 한다 — CREATE TABLE IF NOT EXISTS,
  ADD COLUMN IF NOT EXISTS, CREATE INDEX IF NOT EXISTS
- 파괴적 구문 금지 — DROP COLUMN, 조건 없는 DELETE/UPDATE
- 파일 번호는 015. 기존 번호를 재사용하지 말 것
- 기존 마이그레이션 파일을 수정하지 말 것

## 완료 기준

```bash
./verify.sh migration-numbers migration-safety
```

정적 검사만으로는 부족하다. **실제 DB 에 적용해 확인할 것:**

stage DB 접속 정보가 server/.env.stage 에 있다. 운영 DB 를 쓰지 말 것.

```bash
cd server
STAGE=$(grep '^DATABASE_URL_DIRECT=' .env.stage | cut -d= -f2-)
DATABASE_URL="$STAGE" node src/db/migrate.js   # 1회차 — exit 0 이어야 함
DATABASE_URL="$STAGE" node src/db/migrate.js   # 2회차 — 역시 exit 0 (멱등성 실증)
```

두 번 모두 종료 코드 0 이고 출력에 ✗ 가 없어야 한다. 실행한 명령과 결과를
완료 보고에 그대로 적을 것.

테이블·컬럼이 실제로 생겼는지도 조회해 확인하고 결과를 보고에 넣을 것.

## 주의

큰 파일을 통째로 읽지 말 것. 필요한 부분만 grep 으로 찾아 좁혀 읽는다.
컨텍스트가 가득 차면 압축이 반복되며 작업이 멈춘다.


## Working Directory

All work must be done within the git worktree `/Users/marcoskim/Trabajos_Programacion/ubf_conferencia/.worktrees/task-002-1785508142`.
```bash
cd /Users/marcoskim/Trabajos_Programacion/ubf_conferencia/.worktrees/task-002-1785508142
```
Do not make changes directly on the main branch.

Branch name: `task-002-1785508142/task`

## Pre-work Verification (Bootstrap)

The worktree only contains tracked files. Before starting work, verify the following:
- If `package.json` exists, run `npm install`
- Check for runtime directories listed in `.gitignore` (`node_modules/`, `dist/`, `workspace/`, etc.) and rebuild if necessary
- Set up `.envrc` or environment variables

## Output Directory

```
/Users/marcoskim/Trabajos_Programacion/ubf_conferencia/.team/tasks/002-f8-015/runs/task-002-1785508142
```

Write the result summary to `/Users/marcoskim/Trabajos_Programacion/ubf_conferencia/.team/tasks/002-f8-015/runs/task-002-1785508142/summary.md`.

## Merge Target Branch

Merge the deliverables of this task into `main`.
Follow the delivery method (local merge or PR) as specified in conductor-role.md's completion procedures.

## Completion Notification

Follow the completion procedures in `conductor-role.md` ("Completion Procedures" Steps 1-12). In particular:
- Step 11: `cmux-team close-task --task-id <TASK_ID> --deliverable-kind <files|merged|pr|none> ... --journal "..."` closes the task and internally sends CONDUCTOR_DONE to daemon. **`--deliverable-kind` is required** and must match the delivery method chosen in Step 9 (merged / pr / files / none). See `conductor-role.md` Step 11 for details.
- Step 12: Display the completion report on the session.

**Do not call `cmux-team send CONDUCTOR_DONE --success true` yourself** — close-task does that on your behalf. Use the `--success false` path in `conductor-role.md` Step 8 only when you need to abort without calling close-task (e.g. rebase conflict).
