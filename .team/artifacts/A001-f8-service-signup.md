# A001 · F8 봉사 참여 신청 (Service Signup)

작성 2026-07-31 · 상태: 결정 확정, 구현 대기

수양회에서 섬김(특송·사회·픽업·청소·그룹공부 리더 등)에 참여할 사람을 등록 단계에서
모집한다. 자격이 되는 참가자에게만 노출한다.

---

## 1. 배경 — 기존 &lsquo;재능&rsquo; 스텝과 다른 기능이다

등록 플로우에 이미 `volunteer_resources_step.dart` 가 있고
`registrations.volunteer_resources TEXT[]` 에 저장한다. **이것을 확장하지 말고 별개로 만든다.**

| | 기존 · 재능 (`volunteer_resources`) | 신규 · 섬김 (F8) |
|---|---|---|
| 묻는 것 | 무엇을 **할 수 있는가** | 무엇을 **맡아 주겠는가** |
| 예 | 피아노, 기타, 번역, 사진, 의료 | 특송, 사회자, 픽업, 청소, 그룹공부 리더 |
| 대상 | 전원 | 자격자만 |
| 성격 | 인력 풀 정보 (참고용) | 배정 대상 (담당자 확정 필요) |
| 저장 | `registrations.volunteer_resources` | `service_signups` (신규 테이블) |

두 화면이 비슷해 보이면 참가자가 혼동한다. 문구에서 성격 차이를 분명히 한다
(재능 = "가능한 것", 섬김 = "맡아 주실 수 있는 것").

---

## 2. 확정된 결정

아래는 대화에서 권장안대로 확정한 것이다. 이견이 생기면 **이 문서를 먼저 고치고**
구현을 바꾼다.

| # | 쟁점 | 결정 |
|---|---|---|
| D1 | 선교사·목자 정보 입력 주체 | **자기 신고 + 관리자 확인 플래그.** 확인 전에도 신청은 받되 담당자 목록에 미확인 표시 |
| D2 | 목자 5년 계산 | **`shepherd_since`(시작 연도)를 저장하고 앱에서 계산.** 연차를 저장하면 매년 낡는다 |
| D3 | 봉사 항목 구성 | **프로그램별로 설정.** `programs.service_options` 에 두고 관리자 화면에서 켜고 끈다. 코드 고정 금지 |
| D4 | 신청과 확정 구분 | **`status` 로 구분** (`applied` / `confirmed` / `rejected`). 담당자 확정 화면은 후속 작업 |
| D5 | 운전면허 입력 위치 | **프로필 속성으로 한 번만 받는다** (`users.has_driver_license`). 재능 칩의 `driving` 은 그대로 두되 픽업 자격 판정에 쓰지 않는다 |
| D6 | 거절자 재노출 | **거절도 기록하고 스텝은 계속 접근 가능.** 마음이 바뀌는 경우가 많다 |

---

## 3. 자격 조건

세 조건 중 **하나라도** 만족하면 스텝이 나타난다. 하나도 만족하지 않으면
스텝 자체를 만들지 않는다(비활성 안내 화면도 띄우지 않는다).

| 조건 | 판정 | 현재 상태 |
|---|---|---|
| 개최국 참석자 | `users.region == programs.host_country` | **이미 있음** — `registration_flow_screen.dart` 에 동일 판정이 있다(항공편 생략용). 재사용할 것 |
| 선교사 | `users.is_missionary == true` | 신규 컬럼 |
| 5년 이상 목자 | `users.shepherd_since` 가 있고 `현재연도 - shepherd_since >= 5` | 신규 컬럼 |

**픽업 항목만 추가 조건**: `users.has_driver_license == true` 여야 선택 가능.
미보유 시 카드는 보이되 비활성 + 사유 표시.

자격 판정은 **서버에서도 검증한다.** 클라이언트만 믿지 않는다.

---

## 4. 데이터 모델

마이그레이션 파일은 `ubf_app/supabase/migrations/` 에 두고 **`015_` 부터** 시작한다
(`012_` 가 과거에 중복되어 정리한 이력이 있다). 모든 구문은 멱등이어야 한다 —
`migrate.js` 는 적용 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.

### users (컬럼 추가)

```sql
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_missionary       BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_missionary_verified BOOLEAN NOT NULL DEFAULT FALSE,  -- D1 관리자 확인
  ADD COLUMN IF NOT EXISTS shepherd_since      INTEGER,                            -- D2 시작 연도
  ADD COLUMN IF NOT EXISTS shepherd_verified   BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS has_driver_license  BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS driver_license_country TEXT;
```

### programs (컬럼 추가) — D3

```sql
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS service_options JSONB DEFAULT '[]'::jsonb;
```

항목 배열. 각 원소는 `{ "key": "special_song", "enabled": true }` 형태.
기본 항목 키: `special_song`(특송) · `mc`(사회자) · `pickup`(픽업) · `cleaning`(청소) ·
`group_study_leader`(그룹공부 리더) · `other`(그 밖에).
라벨은 DB에 넣지 않는다 — ARB 로 3개 언어를 관리한다.

### service_signups (신규)

```sql
CREATE TABLE IF NOT EXISTS service_signups (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id UUID NOT NULL REFERENCES registrations(id) ON DELETE CASCADE,
  service_key     TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'applied',   -- D4: applied|confirmed|rejected
  note            TEXT,                              -- 'other' 항목의 자유 입력
  -- 픽업 상세 (service_key='pickup' 일 때만 의미 있음)
  can_provide_vehicle BOOLEAN,
  vehicle_seats       INTEGER,
  contact_window      TEXT,                          -- 연락 가능 시간대
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (registration_id, service_key)
);
CREATE INDEX IF NOT EXISTS idx_service_signups_reg ON service_signups(registration_id);
```

**D6**: 참여를 거절한 경우도 기록한다 — `registrations` 에
`service_declined BOOLEAN DEFAULT FALSE` 를 두고, 거절 시 `true`. 나중에 다시 들어와
선택하면 `false` 로 되돌리고 `service_signups` 를 채운다.

---

## 5. 화면 흐름

등록 플로우의 새 스텝. 4단계가 아니라 **한 스텝 안에서 상태가 전이**된다.

**① 초대** — 자격 사유 배지(예: "개최국 참석자")를 보여주고 참여 의사를 묻는다.
버튼 2개: "네, 참여할게요" / "이번에는 어렵습니다"(→ D6 기록 후 다음 스텝).

**② 봉사 선택** — 프로그램에 설정된 항목만 카드 목록으로. 복수 선택.
각 카드는 아이콘 없이 제목 + 한 줄 설명 + 체크박스. 픽업 카드에는
"운전면허 필요" 배지, 미보유 시 비활성.

**③ 픽업 조건부 확장** — 픽업 선택 시 카드 아래로 펼쳐진다.
면허 보유 확인 · 면허 발급 국가 · 차량 제공 가능 · 탑승 가능 인원.

**④ 확인** — 선택 요약 + 연락 가능 시간대. "담당자가 확인 후 연락드립니다" 안내.

문구 원칙: 확정이 아님을 분명히 한다("확정은 아니며 담당자가 확인 후 연락드립니다"),
언제든 바꿀 수 있음을 알린다.

시각 규약은 기존 등록 스텝과 동일 — `AppTheme.primary`(#1565C0), 기존 봉사 스텝의
teal 계열, radius 12, `ListView` padding 20.

---

## 6. 구현 시 주의

**등록 플로우가 조건부 스텝을 못 받는다.** `registration_flow_screen.dart` 는
`int get _totalPages => 8` 로 고정이고 `PageView` 자식도 고정 목록이다.
조건부 스텝을 넣으려면 **목록 기반으로 바꿔야 한다.** 항공편 스텝의 현재 생략 방식
(`sameCountryAsHost`)도 이때 함께 정리하는 편이 좋다. 이 리팩터링은 화면 태스크에 포함한다.

**새 라우터는 `server/src/index.js` 의 `app.use` 목록에 등록해야 한다.**
빠뜨리면 조용히 404 가 된다 (`verify.sh route-parity` 가 잡는다).

**새 문자열은 ARB 3개 모두** — `app_en.arb`(템플릿) / `app_ko.arb` / `app_es.arb`.
`verify.sh arb-parity` 가 키 집합 불일치를 잡는다.

**검증은 `./verify.sh`** 로 한다. 세부는 루트 `CLAUDE.md` 참조.

---

## 7. 태스크 분해

의존 순서: **스키마 → API → 화면**. 화면을 API 확정 전에 시작하면 재작업이 난다.

| 태스크 | 범위 | 비고 |
|---|---|---|
| **T1 스키마** | `015_service_signup.sql` — 위 4절 전부 | `--exclusive` (DB 는 worktree 로 격리되지 않는다) |
| **T2 API** | `server/src/routes/service_signups.js` + `index.js` 등록 + 서버측 자격 검증 | T1 의존 |
| **T3 화면** | `steps/service_signup_step.dart`, 플로우 가변 스텝 리팩터링, 프로필에 선교사·목자·면허 입력, ARB 3종 | T2 의존 |

관리자 확정 화면(D4 의 `confirmed`/`rejected` 전환 UI)은 이번 범위 밖. 후속 태스크.
