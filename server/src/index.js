import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import cron from 'node-cron';
import { sql } from './db.js';
import jwt from 'jsonwebtoken';
import { googleLogin, kakaoLogin, requireAuth } from './middleware/auth.js';
import { sendDailySummary } from './services/telegram.js';
import { notifyProgramParticipants } from './services/fcm.js';
import programsRouter from './routes/programs.js';
import registrationsRouter from './routes/registrations.js';
import leadersRouter from './routes/leaders.js';
import paymentsRouter from './routes/payments.js';
import adminsRouter from './routes/admins.js';
import schedulesRouter from './routes/schedules.js';
import sosRouter from './routes/sos.js';
import roomsRouter from './routes/rooms.js';
import groupsRouter from './routes/groups.js';
import buddyRequestsRouter from './routes/buddy_requests.js';
import companionsRouter from './routes/companions.js';
import assignmentsRouter from './routes/assignments.js';
import transportRouter from './routes/transport.js';
import serviceSignupsRouter from './routes/service_signups.js';

const app = express();
const PORT = process.env.PORT ?? 3000;
const IS_PROD = process.env.NODE_ENV === 'production';

// ── 기동 전 안전 점검 ────────────────────────────────────────
// 설정이 빠졌을 때 조용히 취약한 상태로 뜨는 것보다 아예 뜨지 않는 편이 낫다.
{
  const fail = [];
  if (!process.env.DATABASE_URL) fail.push('DATABASE_URL 미설정');
  if (!process.env.JWT_SECRET) fail.push('JWT_SECRET 미설정');
  else if (process.env.JWT_SECRET.length < 32) fail.push('JWT_SECRET 이 32자 미만');
  if (IS_PROD && !process.env.ALLOWED_ORIGINS) {
    fail.push('운영 환경인데 ALLOWED_ORIGINS 미설정');
  }
  if (fail.length > 0) {
    console.error('✗ 기동 거부 — 설정 문제:');
    for (const f of fail) console.error('   · ' + f);
    process.exit(1);
  }
}

// ── 보안 헤더 ────────────────────────────────────────────────
// 이 서버는 JSON API 만 제공한다. 정적 파일은 nginx 가 서빙하므로
// CSP 는 nginx 쪽에서 붙인다(여기서 켜면 API 응답에만 걸려 의미가 없다).
app.use(helmet({ contentSecurityPolicy: false }));

// nginx 뒤에 있을 때 실제 클라이언트 IP 를 얻으려면 필요하다.
// 없으면 레이트 리밋이 모든 요청을 프록시 IP 하나로 묶어 무력해진다.
if (IS_PROD) app.set('trust proxy', 1);

// ── 레이트 리밋 ──────────────────────────────────────────────
// 인증 경로는 별도로 더 조인다. 무차별 시도와 토큰 발급 남용을 막는다.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: '시도가 너무 잦습니다. 잠시 후 다시 시도해 주세요.' },
});
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 300,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: '요청이 너무 많습니다.' },
});

// CORS 설정
const allowedOrigins = (process.env.ALLOWED_ORIGINS ?? '').split(',');
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('CORS 정책 위반'));
    }
  },
  credentials: true,
}));

app.use(express.json({ limit: '10mb' }));

// 헬스체크 (리미터 적용 전 — 모니터링이 막히면 안 된다)
app.get('/health', (_, res) => res.json({ status: 'ok' }));

app.use(apiLimiter);

// 인증
app.post('/auth/google', authLimiter, googleLogin);
app.post('/auth/kakao', authLimiter, kakaoLogin);
// /auth/dev-login — 개발 전용 테스트 로그인 (OAuth 생략)
//
// 이 엔드포인트는 **아무 이메일로나 유효한 JWT 를 발급한다.** 열려 있으면
// 누구든 director 를 포함한 임의의 계정으로 로그인할 수 있고, 참석자 명부·
// 질병 정보·위치가 그대로 열린다.
//
// 이전에는 NODE_ENV !== 'production' 이면 열렸다. 즉 NODE_ENV 를 빠뜨리면
// 켜지는 fail-open 구조였다. 이제 ENABLE_DEV_LOGIN=1 을 **명시**해야만 켜진다.
// 설정을 빠뜨리면 꺼진다(fail-closed).
const DEV_LOGIN_ENABLED = !IS_PROD && process.env.ENABLE_DEV_LOGIN === '1';

app.post('/auth/dev-login', authLimiter, async (req, res) => {
  if (!DEV_LOGIN_ENABLED) {
    return res.status(404).json({ error: 'Not found' });
  }

  const email = req.body.email ?? 'dev@test.com';
  const name  = req.body.name  ?? '테스트 사용자';

  try {
    const [user] = await sql`
      INSERT INTO users (google_id, email, name, profile_completed)
      VALUES (${'dev:' + email}, ${email}, ${name}, TRUE)
      ON CONFLICT (google_id)
      DO UPDATE SET name = EXCLUDED.name, updated_at = NOW()
      RETURNING id, email, name, role, age, region, profile_completed AS "profileCompleted"
    `;

    const [leader] = await sql`SELECT id FROM leaders WHERE user_id = ${user.id}`;
    const role     = user.role ?? (leader ? 'admin' : 'participant');
    const isLeader = role === 'director' || role === 'admin' || !!leader;

    const token = jwt.sign(
      { userId: user.id, email: user.email, name: user.name, role, isLeader, leaderId: leader?.id ?? null },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    console.log(`[DEV-LOGIN] email=${email} userId=${user.id} role=${role}`);
    res.json({ token, user: { id: user.id, email: user.email, name: user.name, role }, isLeader });
  } catch (err) {
    console.error('dev-login 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// /auth/me — DB에서 최신 프로필 조회
app.get('/auth/me', requireAuth, async (req, res) => {
  try {
    const [user] = await sql`
      SELECT id AS "userId", email, name, role, age, region, profile_completed AS "profileCompleted"
      FROM users WHERE id = ${req.user.userId}
    `;
    if (!user) return res.status(401).json({ error: '사용자 없음' });

    const [leader] = await sql`SELECT id FROM leaders WHERE user_id = ${req.user.userId}`;
    res.json({
      ...user,
      isLeader: user.role === 'director' || user.role === 'admin' || !!leader,
      leaderId: leader?.id ?? null,
    });
  } catch (err) {
    console.error('/auth/me 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// /auth/profile — 프로필 저장 (이름 확정, 나이, 지역)
app.patch('/auth/profile', requireAuth, async (req, res) => {
  const { name, age, region } = req.body;
  if (!name || !age || !region) {
    return res.status(400).json({ error: 'name, age, region 모두 필요합니다' });
  }
  try {
    await sql`
      UPDATE users
      SET name = ${name}, age = ${age}, region = ${region},
          profile_completed = TRUE, updated_at = NOW()
      WHERE id = ${req.user.userId}
    `;
    console.log(`[PROFILE] 완료 | userId=${req.user.userId} name="${name}" age=${age} region="${region}"`);
    res.json({ ok: true });
  } catch (err) {
    console.error('/auth/profile 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// API 라우터
app.use('/programs', programsRouter);
app.use('/registrations', registrationsRouter);
app.use('/leaders', leadersRouter);
app.use('/payments', paymentsRouter);
app.use('/admins', adminsRouter);
app.use('/schedules', schedulesRouter);
app.use('/sos', sosRouter);
app.use('/rooms', roomsRouter);
app.use('/groups', groupsRouter);
app.use('/buddy-requests', buddyRequestsRouter);
app.use('/companions', companionsRouter);
app.use('/assignments', assignmentsRouter);
app.use('/transport', transportRouter);
app.use('/service-signups', serviceSignupsRouter);

// 에러 핸들러
app.use((err, req, res, _next) => {
  console.error(err.stack);
  res.status(500).json({ error: '서버 내부 오류' });
});

// ─── Cron: 매분 일정 알림 확인 (시작 5분 전 발송) ──────────────
// scheduled_at은 UTC로 저장되므로 타임존 무관하게 NOW() 비교가 정확함
// 각 일정의 timezone 컬럼은 앱 표시용이며 cron 로직에는 영향 없음
cron.schedule('* * * * *', async () => {
  try {
    const due = await sql`
      SELECT ps.id, ps.program_id, ps.title, ps.description, p.name AS program_name
      FROM program_schedules ps
      JOIN programs p ON p.id = ps.program_id
      WHERE ps.notification_sent = false
        AND ps.scheduled_at BETWEEN NOW() + INTERVAL '4 minutes 30 seconds'
                                 AND NOW() + INTERVAL '5 minutes 30 seconds'
    `;

    for (const schedule of due) {
      // 손목(Wear OS) 가독성: 행사명이 제목에 먼저, 본문은 "5분 후 시작"이 앞쪽.
      // (프로그램명은 제목 공간을 차지하므로 본문 끝으로)
      const title = `📅 ${schedule.title}`;
      const body  = schedule.description
        ? `5분 후 시작 · ${schedule.description} · ${schedule.program_name}`
        : `5분 후 시작 · ${schedule.program_name}`;

      // FCM으로 참가자 전체에게 알림
      await notifyProgramParticipants(sql, schedule.program_id, title, body, {
        type: 'schedule',
        scheduleId: schedule.id,
        programId: schedule.program_id,
      });

      // 발송 완료 표시
      await sql`
        UPDATE program_schedules SET notification_sent = true WHERE id = ${schedule.id}
      `;

      console.log(`[schedule] 알림 전송: ${title}`);
    }
  } catch (err) {
    console.error('[cron schedule] 오류:', err.message);
  }
});

// ─── Cron: 매일 19:00 일일 요약 Telegram 전송 ─────────────────
cron.schedule('0 19 * * *', () => {
  console.log('[cron] 일일 요약 전송 시작...');
  sendDailySummary().catch(err =>
    console.error('[cron] 일일 요약 전송 실패:', err.message)
  );
}, { timezone: 'Asia/Seoul' });

app.listen(PORT, () => {
  console.log(`UBF API 서버 실행 중: http://localhost:${PORT}`);
  console.log(`환경: ${process.env.NODE_ENV ?? 'development'}`);
  // 위험한 설정은 눈에 띄게 알린다. 조용히 켜져 있는 것이 가장 나쁘다.
  if (DEV_LOGIN_ENABLED) {
    console.warn('⚠ /auth/dev-login 이 열려 있습니다 (ENABLE_DEV_LOGIN=1).');
    console.warn('  아무 이메일로나 로그인됩니다. 공개 서버에서는 절대 켜지 마십시오.');
  } else {
    console.log('dev-login: 비활성 (404)');
  }
});
