# A003 · 준비 현황 화면 (Organizer Readiness)

작성 2026-07-31 · 상태: 결정 확정, 구현 대기

수양회를 준비하는 사람이 **지금 무엇이 막혀 있고 누구에게 연락해야 하는지**를 한 화면에서
보게 한다. 기존 대시보드를 대체하지 않고 보완한다.

---

## 1. 배경 — 관리자 화면은 이미 있다

리더용 화면이 7개 있다. **처음부터 만들지 말 것.**

| 라우트 | 내용 |
|---|---|
| `/leader/create-program` | 수양회 생성 (이름·장소·기간·개최국·최인접공항·입국정보·옵션비용) |
| `/leader/program/:id/dashboard` | 통계 6종 + 참석자 목록 + 결제대기 + 공지 발송 + Excel/CSV |
| `/leader/program/:id/setup` | 방·조 설정 |
| `/leader/program/:id/assign` | 배정 |
| `/leader/program/:id/dispatch` | 배차 |
| `/leader/program/:id/edit` | 프로그램 수정 |

기존 대시보드 통계: 총 등록 / 제출 / 식이제한 / 결제대기 / 도착항공 / 결제확인
(`GET /programs/:id/stats`, `server/src/routes/programs.js:242`)

### 없는 것 — 이 문서가 채우려는 것

- **국내·해외 구분**: 참석자 목록에 국가가 뜨지만 나누거나 거를 수 없다.
  두 집단은 막히는 지점이 다르다 — 개최국 참석자는 항공편 단계를 건너뛴다.
- **어디서 막혔는지**: `registrations.submitted` 는 참/거짓뿐이라 8단계 중 어디서
  멈췄는지 알 수 없다.
- **준비 충족도**: 숙소 정원 대비 인원처럼 "모자란가"를 알 수 없다.
- **D-day / 마감**: 남은 기간 감각이 없다. 등록 마감일 자체가 데이터에 없다.

---

## 2. 확정된 결정

| # | 쟁점 | 결정 |
|---|---|---|
| D1 | 기존 대시보드와의 관계 | **별도 화면으로 추가.** 대시보드에 진입 카드 1개를 붙인다. 기존 화면은 건드리지 않는다 |
| D2 | 집계 위치 | **서버에서 SQL 로 집계.** 화면이 여러 엔드포인트를 조합하지 않게 한 응답으로 묶는다 |
| D3 | 막힌 단계 판정 | **기존 컬럼의 채움 여부로 유추한다.** 스텝별 완료 플래그를 새로 저장하지 않는다 — 등록 플로우가 바뀔 때마다 동기화 부담이 생긴다 |
| D4 | 담당자 지정 | **이번 범위 밖.** 항목별 담당자는 후속 작업 |
| D5 | 화면 폭 | **웹/태블릿 우선.** 리더는 주로 큰 화면에서 쓴다. 모바일에서는 카드가 세로로 쌓이면 된다 |

---

## 3. 데이터 모델

마이그레이션은 `ubf_app/supabase/migrations/` 에 두고 **사용되지 않은 다음 번호**를 쓴다
(현재 `014_` 까지 있음). 모든 구문이 멱등이어야 한다.

```sql
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS registration_deadline DATE,
  ADD COLUMN IF NOT EXISTS capacity              INTEGER,
  ADD COLUMN IF NOT EXISTS base_fee              NUMERIC(10,2);
```

- `registration_deadline` — D-day 와 "마감 임박" 판정의 기준. 지금은 수양회 시작일밖에
  없어 등록을 언제까지 받는지 앱이 알지 못한다.
- `capacity` — 전체 수용 인원. 숙소 정원과 별개다.
- `base_fee` — 기본 참가비. 지금은 옵션 비용만 있어 미납 집계가 부정확하다.

세 컬럼 모두 **nullable** 이다. 기존 프로그램은 값이 없어도 화면이 동작해야 한다
(해당 카드는 "설정 안 됨"으로 표시).

---

## 4. API

### `GET /programs/:id/readiness` (신규)

`requireAuth` + `requireLeader`. 아래를 **한 응답**으로 반환한다.

```jsonc
{
  "program": { "name": "...", "start_date": "...", "registration_deadline": null,
               "host_country": "BR", "capacity": null, "d_day": 14 },

  // 준비 항목 — 각 항목은 상태(ok|warn|stop|idle)와 수치를 갖는다
  "readiness": {
    "lodging":   { "status": "stop", "needed": 128, "available": 120 },
    "transport": { "status": "warn", "needed": 41,  "available": 32  },
    "flights":   { "status": "warn", "missing": 9,  "overseas_total": 38 },
    "meals":     { "status": "ok",   "restricted": 17 },
    "payment":   { "status": "warn", "confirmed": 63, "total": 86 }
  },

  // 국내/해외 코호트별 단계 진척
  "cohorts": [
    { "kind": "domestic", "country": "BR", "total": 48,
      "steps": { "personal": 48, "meals": 46, "flight": null, "lodging": 38, "submitted": 36 } },
    { "kind": "overseas", "countries": 12, "total": 38,
      "steps": { "personal": 38, "meals": 35, "flight": 29, "lodging": 27, "submitted": 25 } }
  ],

  // 연락이 필요한 사람
  "blocked": [
    { "registration_id": "...", "name": "Maria Silva", "country": "PE", "branch": "리마",
      "kind": "overseas", "stuck_at": "flight", "stalled_days": 18 }
  ]
}
```

**국내/해외 판정**: `registrations.country == programs.host_country` 이면 국내.
등록 시점의 값을 쓴다(`users.region` 이 아니라). 등록 화면에서 국가를 직접 고르므로
그쪽이 더 정확하다.

**`stuck_at` 판정 (D3)** — 앞 단계부터 채워졌는지 보고 처음 비는 곳을 반환한다:

| 단계 | 채움 판정 |
|---|---|
| `personal` | `real_name` 이 비어 있지 않음 |
| `meals` | `food_requirements IS NOT NULL` (없음도 명시적 입력으로 본다면 별도 플래그 필요 — 현재는 NULL 이면 미입력) |
| `flight` | 국내는 해당 없음(`null`). 해외는 `arrival_flight IS NOT NULL` |
| `lodging` | `room_assignments` 에 해당 등록이 있음 |
| `submitted` | `submitted = true` |

**`stalled_days`** = `NOW() - registrations.updated_at`.

`server/src/index.js` 의 `app.use` 목록 등록을 잊지 말 것 —
`verify.sh route-parity` 가 잡는다.

---

## 5. 화면

`ubf_app/lib/features/dashboard/screens/readiness_screen.dart` (신규)
라우트 `/leader/program/:id/readiness` 를 `app.dart` 의 `GoRouter` 에 등록한다.

구성(위에서 아래로):

1. **상단 바** — 프로그램명, 장소·기간·개최국, D-day 배지
2. **준비 항목 카드** — 숙소 / 픽업 배차 / 항공편 미입력 / 식사 / 참가비.
   각 카드는 상태 스트라이프(색) + 배지(글자) + 수치 + 진행 막대 + 한 줄 설명.
   **색만으로 상태를 구분하지 말 것** — 배지 텍스트를 함께 둔다.
3. **국내·해외 코호트** — 두 칸. 단계별 진척 막대. 국내의 항공편 행은 "생략"으로 표시.
4. **연락이 필요한 사람** — 필터 칩(전체/국내/해외/항공편 미입력/참가비 미납/정체) +
   표(이름·소속·막힌 단계·정체 일수·다음 할 일)

기존 대시보드(`dashboard_screen.dart`)에 이 화면으로 가는 카드 1개를 추가한다.
setup/assign/dispatch 카드와 같은 형식.

시각 규약은 기존과 동일 — `AppTheme.primary`(#1565C0), Material 3, radius 12.
새 문자열은 ARB 3개 모두.

**"다음 할 일" 버튼은 이번 범위에서는 화면 이동만 한다** (개별 알림 발송은 후속).
현재 공지는 전체 발송만 가능해 정작 필요한 사람에게 닿지 않는다.

---

## 6. 태스크 분해

| 태스크 | 범위 | 의존 |
|---|---|---|
| **T1 스키마** | `programs` 에 3개 컬럼 추가 | `--exclusive` |
| **T2 API** | `GET /programs/:id/readiness` + `index.js` 등록 | T1 |
| **T3 화면** | `readiness_screen.dart` + 라우트 + 대시보드 진입 카드 + ARB 3종 | T2 |

생성 화면(`create_program_screen.dart`)에 3개 컬럼 입력 UI 를 추가하는 것은
T3 에 포함하거나 별도 태스크로 뺀다.

---

## 7. 검증

```bash
./verify.sh
```

`verify.sh` 가 잡지 못해 직접 확인해야 하는 것:

- 등록이 0건인 프로그램에서 화면이 깨지지 않는가 (모든 수치 0, 나눗셈 주의)
- `registration_deadline` / `capacity` / `base_fee` 가 NULL 인 기존 프로그램에서
  해당 카드가 "설정 안 됨"으로 뜨는가
- 국내/해외 분류가 실제 데이터와 맞는가 — `server/scripts/seed-stage.js` 로
  두 시나리오를 만든 뒤 확인
- 3개 언어 전환 — `server/scripts/i18n-sweep.sh` 의 ROUTES 에 새 라우트를 추가할 것
