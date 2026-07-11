# UBF 등록 앱 - 시작 가이드

## 프로젝트 구조

```
UBF_registrador/
├── server/          # Node.js Express API 서버 (Neon PostgreSQL)
└── ubf_app/         # Flutter 앱 (iOS/Android/macOS/Windows)
```

---

## 1단계: Neon PostgreSQL 설정

1. [https://console.neon.tech](https://console.neon.tech) 접속 → 새 프로젝트 생성
2. 프로젝트명: `ubf-registrador`
3. **Connection string** 복사 (예: `postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require`)

---

## 2단계: Google OAuth 설정

1. [https://console.cloud.google.com](https://console.cloud.google.com) 접속
2. 새 프로젝트 생성 → **APIs & Services → Credentials**
3. **OAuth 2.0 Client ID** 생성
   - Android: 패키지명 `com.ubf.ubf_app` + SHA-1 지문
   - iOS: 번들 ID `com.ubf.ubfApp`
   - Web: 개발용 `http://localhost`
4. **Client ID** 복사

---

## 3단계: 서버 설정 및 실행

```bash
cd server

# .env 파일 수정
nano .env
# DATABASE_URL=<Neon connection string>
# JWT_SECRET=<임의의 긴 문자열, 예: openssl rand -hex 32>
# GOOGLE_CLIENT_ID=<Google OAuth Client ID>
# TELEGRAM_BOT_TOKEN=<Telegram Bot Token — @BotFather에서 발급, 선택사항>

# DB 스키마 적용
npm run migrate

# 개발 서버 실행
npm run dev
# → http://localhost:3000
```

---

## 4단계: Flutter 앱 실행

```bash
cd ubf_app

# lib/core/constants/app_constants.dart 수정
# apiBaseUrl: 'http://localhost:3000'  (개발)
# apiBaseUrl: 'https://your-domain.com'  (배포)

# 패키지 설치
flutter pub get

# 로컬 실행
flutter run

# 플랫폼별 빌드
flutter build apk          # Android
flutter build ios          # iOS
flutter build macos        # macOS
flutter build windows      # Windows
```

---

## 5단계: 처음 사용 흐름

1. 앱 실행 → 구글 로그인
2. 홈 화면에서 **"리더이신가요? 리더로 전환하기"** 클릭
3. 이름 입력 → 리더 등록 완료
4. **새 프로그램 생성** → UUID 발급
5. UUID를 참가자들에게 카카오톡/이메일로 공유
6. 참가자: UUID 입력 → 6단계 등록 진행

---

## 서버 API 엔드포인트 요약

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/auth/google` | 구글 ID 토큰 → JWT 교환 |
| GET | `/auth/me` | 현재 사용자 정보 |
| GET | `/programs/:id` | 프로그램 조회 (UUID) |
| POST | `/programs` | 프로그램 생성 (리더) — `nearestAirport`, `contact1Name/Phone`, `contact2Name/Phone` 포함 |
| GET | `/programs/:id/stats` | 통계 대시보드 (리더) |
| GET | `/programs/:id/registrations` | 참가자 목록 (리더) |
| GET | `/registrations/:programId/me` | 내 등록 정보 |
| PUT | `/registrations/:programId/me` | 등록 저장 (upsert) |
| POST | `/registrations/:programId/me/submit` | 최종 제출 |
| POST | `/leaders/register` | 리더 등록 |
| POST | `/payments` | 입금 등록 |
| PATCH | `/payments/:id/confirm` | 입금 승인 (리더) |
| PATCH | `/payments/:id/reject` | 입금 반려 (리더) |
| GET | `/admins/programs/:programId` | 프로그램 관리자 목록 (director) |
| POST | `/admins/programs/:programId` | 관리자 지정 - body: `{email}` (director) |
| DELETE | `/admins/programs/:programId/:userId` | 관리자 제거 (director) |
| PATCH | `/admins/me/telegram` | 내 Telegram chat_id 설정 - body: `{telegramChatId}` |
| PATCH | `/admins/programs/:programId/telegram` | 프로그램 Telegram chat_id 설정 (director) |
| GET | `/schedules/:programId` | 프로그램 일정 목록 |
| POST | `/schedules/:programId` | 일정 추가 (admin 이상) |
| PATCH | `/schedules/:programId/:scheduleId` | 일정 수정 (admin 이상) |
| DELETE | `/schedules/:programId/:scheduleId` | 일정 삭제 (admin 이상) |
| POST | `/sos` | SOS 발령 (참가자) — GPS + 상황 유형 전송 |
| GET | `/sos/:programId` | SOS 목록 조회 (admin 이상) |
| PATCH | `/sos/:alertId/resolve` | SOS 해제 (admin 이상) |

---

## 역할(Role) 시스템

| Role | 설명 |
|------|------|
| `director` | 최고 관리자 — 모든 프로그램 관리, admin 지정 가능 |
| `admin` | 담당 프로그램 관리 — 통계/참가자/입금 확인 가능 |
| `participant` | 일반 참가자 — UUID 입력 후 등록 진행 |

- `director`로 승격: DB에서 직접 `UPDATE users SET role='director' WHERE email='...'`
- `admin` 지정: `POST /admins/programs/:programId` (director 전용)

## Telegram 알림 설정

1. Telegram에서 `@BotFather`로 봇 생성 → `TELEGRAM_BOT_TOKEN` 발급
2. 일일 요약 수신 그룹에 봇을 초대 → 그룹 chat_id 확인
3. `PATCH /admins/programs/:programId/telegram` 으로 chat_id 등록
4. 관리자 개인 알림: `PATCH /admins/me/telegram` 으로 개인 chat_id 등록
5. 매일 19:00 (Asia/Seoul) 등록 현황 자동 전송

---

## 추가 설정 (선택)

### AviationStack API (항공편 자동 조회)
- [https://aviationstack.com](https://aviationstack.com) 무료 계정 → API 키 발급
- `ubf_app/lib/core/constants/app_constants.dart`의 `aviationStackApiKey` 입력

### Firebase Push 알림
- Firebase Console → 새 프로젝트 → `flutterfire configure` 실행
- `ubf_app/lib/main.dart`의 Firebase 초기화 주석 해제
- 서버 `.env`에 `FIREBASE_SERVICE_ACCOUNT` 추가 (서비스 계정 JSON 문자열)
  - Firebase Console → 프로젝트 설정 → 서비스 계정 → 새 비공개 키 생성

---

## 입국 안내 카드 기능

참가자가 공항 입국 시 감사관에게 앱 화면을 직접 보여줄 수 있는 카드입니다.

**프로로그램 생성 시 입력 항목 (선택)**
- 가까운 공항명 (예: 인천국제공항 ICN)
- 현장 대표 연락처 2명 (이름 + 전화번호)

**참가자 사용 방법**
1. 등록 요약 화면 → **입국 안내 카드 보기** 버튼 클릭
2. 카드 화면에서 우측 상단 **전체화면** 버튼 클릭
3. 감사관에게 화면을 보여주면 됨
4. 화면을 탭하면 전체화면 해제

**카드 표시 내용** (한국어 + 영어 병기)
- 프로그램명 / PURPOSE OF VISIT
- 장소 / VENUE
- 기간 / DATE
- 가까운 공항 / NEAREST AIRPORT
- 현장 연락처 2명 / ON-SITE CONTACT

> 공항/연락처 정보가 등록되지 않은 프로그램은 버튼이 표시되지 않음

---

## SOS 긴급 알림 기능

참가자가 앱에서 SOS 버튼을 누르면 관리자에게 즉시 알림이 전달됩니다.

**참가자 흐름**
1. 화면 하단의 빨간 **SOS** 플로팅 버튼 클릭
2. 확인 다이얼로그 → SOS 화면으로 이동
3. 상황 유형 선택: 🚑 건강/의료 응급 / 🆘 신변 위협 / 🗺️ 길을 잃음
4. 추가 메시지 입력 (선택)
5. GPS 위치 자동 취득 (권한 필요)
6. **SOS 전송** 버튼 클릭

**관리자 수신 내용**
- FCM 푸시 알림 (앱)
- Telegram 메시지: 참가자 이름, 상황 유형, Google Maps 위치 링크, 메시지

**관리자 처리**
- 대시보드에서 SOS 목록 확인
- 처리 완료 후 해제(resolve) → 해제 알림이 Telegram으로 전송됨

> GPS 권한이 거부된 경우에도 위치 없이 SOS 전송 가능

---

## 일정 알림 기능

관리자가 등록한 프로그램 일정이 **시작 5분 전**에 참가자 전원에게 자동으로 푸시 알림이 전송됩니다.

**일정 추가 (admin/director)**
1. 프로그램 일정 화면 → 우하단 **일정 추가** 버튼
2. 제목, 설명(선택), 날짜, 시간 입력 → 추가

**알림 동작**
- 서버 크론잡이 매분 실행되어 5분 후 시작 예정인 일정을 감지
- 해당 프로그램 참가자 전체에게 FCM 푸시 알림 발송
- 한 일정당 한 번만 발송 (`notification_sent` 플래그 관리)
- 일정 시간 수정 시 알림이 재발송되도록 초기화됨
- `scheduled_at`은 UTC로 저장되므로 크론잡 비교는 타임존에 무관하게 정확함
- 각 일정에 `timezone` 필드가 저장되며 **앱 표시용**으로 사용됨
- 일정 생성 시 **생성자의 디바이스 타임존이 자동 감지**되어 기본값으로 설정됨
- 관리자는 일정 목록에서 타임존 레이블을 탭하여 변경/확정 가능

> Firebase 설정이 없으면 FCM 알림은 건너뛰어지며 서버는 정상 동작합니다.

