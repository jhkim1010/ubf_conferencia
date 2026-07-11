import 'dotenv/config';
import express from 'express';
import cors from 'cors';
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

const app = express();
const PORT = process.env.PORT ?? 3000;

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

// 헬스체크
app.get('/health', (_, res) => res.json({ status: 'ok' }));

// 인증
app.post('/auth/google', googleLogin);
app.post('/auth/kakao', kakaoLogin);
// /auth/dev-login — 개발 환경 전용 테스트 로그인 (OAuth 생략)
app.post('/auth/dev-login', async (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(403).json({ error: '운영 환경에서는 사용 불가' });
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
      const title = `📅 [${schedule.program_name}] ${schedule.title}`;
      const body  = schedule.description
        ? `5분 후 시작 • ${schedule.description}`
        : '5분 후 시작됩니다';

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
});
