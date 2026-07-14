import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import { sql } from '../db.js';

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// 허용할 Client ID 목록 (Web + iOS/macOS)
const allowedAudiences = [
  process.env.GOOGLE_CLIENT_ID,         // Web Client ID
  process.env.GOOGLE_IOS_CLIENT_ID,     // iOS/macOS Client ID
].filter(Boolean);

// Google ID 토큰 검증 → 자체 JWT 발급
export async function googleLogin(req, res) {
  const { idToken, accessToken } = req.body;

  if (!idToken && !accessToken) {
    return res.status(400).json({ error: 'idToken 또는 accessToken이 필요합니다' });
  }

  try {
    let googleId, email, name;

    if (idToken) {
      // 네이티브(iOS/macOS/Android): ID 토큰 검증
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: allowedAudiences,
      });
      const payload = ticket.getPayload();
      googleId = payload.sub;
      email = payload.email;
      name = payload.name;
    } else {
      // 웹: google_sign_in 이 idToken 을 주지 않으므로 accessToken 으로 처리
      // 1) tokeninfo 로 토큰 검증 + audience 확인 (토큰 치환 공격 방지)
      const tiRes = await fetch(
        `https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(accessToken)}`
      );
      if (!tiRes.ok) throw new Error(`tokeninfo 오류: ${tiRes.status}`);
      const tokenInfo = await tiRes.json();
      if (!allowedAudiences.includes(tokenInfo.aud)) {
        throw new Error(`audience 불일치: ${tokenInfo.aud}`);
      }
      googleId = tokenInfo.sub;
      email = tokenInfo.email;
      // 2) 이름은 userinfo 로 조회 (없으면 이메일로 대체)
      const uiRes = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      name = uiRes.ok ? ((await uiRes.json()).name ?? email) : email;
    }

    // users 테이블에 upsert (첫 로그인 시 자동 생성)
    const [user] = await sql`
      INSERT INTO users (google_id, email, name)
      VALUES (${googleId}, ${email}, ${name})
      ON CONFLICT (google_id)
      DO UPDATE SET email = EXCLUDED.email, name = EXCLUDED.name, updated_at = NOW()
      RETURNING id, email, name, role
    `;

    // 리더 여부 확인 (기존 leaders 테이블 호환)
    const [leader] = await sql`
      SELECT id FROM leaders WHERE user_id = ${user.id}
    `;

    // role: director > admin (leaders 테이블에 있으면 admin 이상) > participant
    const role = user.role ?? (leader ? 'admin' : 'participant');
    const isLeader = role === 'director' || role === 'admin';

    const token = jwt.sign(
      {
        userId: user.id,
        email: user.email,
        name: user.name,
        role,
        isLeader,
        leaderId: leader?.id ?? null,
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    console.log(`[LOGIN] Google | userId=${user.id} email=${email} role=${role} isLeader=${isLeader}`);
    return res.json({
      token,
      user: { id: user.id, email: user.email, name: user.name, role },
      isLeader,
    });
  } catch (err) {
    console.error('Google 로그인 오류:', err);
    return res.status(401).json({ error: '인증에 실패했습니다' });
  }
}

// 카카오 액세스 토큰 → 사용자 정보 조회 → 자체 JWT 발급
export async function kakaoLogin(req, res) {
  const { accessToken } = req.body;
  if (!accessToken) {
    return res.status(400).json({ error: 'accessToken이 필요합니다' });
  }

  try {
    // 카카오 사용자 정보 API 호출
    const kakaoRes = await fetch('https://kapi.kakao.com/v2/user/me', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!kakaoRes.ok) throw new Error(`카카오 API 오류: ${kakaoRes.status}`);

    const kakaoUser = await kakaoRes.json();
    const kakaoId   = String(kakaoUser.id);
    const email     = kakaoUser.kakao_account?.email ?? null;
    const name      = kakaoUser.kakao_account?.profile?.nickname
                   ?? kakaoUser.properties?.nickname
                   ?? '카카오 사용자';

    // google_id 컬럼에 kakao:{id} 형태로 저장 (기존 스키마 재활용)
    const syntheticId = `kakao:${kakaoId}`;

    const [user] = await sql`
      INSERT INTO users (google_id, email, name)
      VALUES (${syntheticId}, ${email}, ${name})
      ON CONFLICT (google_id)
      DO UPDATE SET name = EXCLUDED.name, updated_at = NOW()
      RETURNING id, email, name, role
    `;

    const [leader] = await sql`
      SELECT id FROM leaders WHERE user_id = ${user.id}
    `;

    const role     = user.role ?? (leader ? 'admin' : 'participant');
    const isLeader = role === 'director' || role === 'admin';

    const token = jwt.sign(
      { userId: user.id, email: user.email, name: user.name, role, isLeader, leaderId: leader?.id ?? null },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    console.log(`[LOGIN] Kakao | userId=${user.id} kakaoId=${kakaoId} role=${role} isLeader=${isLeader}`);
    return res.json({
      token,
      user: { id: user.id, email: user.email, name: user.name, role },
      isLeader,
    });
  } catch (err) {
    console.error('카카오 로그인 오류:', err);
    return res.status(401).json({ error: '카카오 인증에 실패했습니다' });
  }
}

// JWT 인증 미들웨어
export function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: '인증 토큰이 없습니다' });
  }

  const token = authHeader.slice(7);

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: '유효하지 않은 토큰입니다' });
  }
}

// 리더(admin 이상) 전용 미들웨어 — 기존 호환용
export function requireLeader(req, res, next) {
  if (!req.user?.isLeader) {
    return res.status(403).json({ error: '관리자 권한이 필요합니다' });
  }
  next();
}

// director 전용 미들웨어
export function requireDirector(req, res, next) {
  if (req.user?.role !== 'director') {
    return res.status(403).json({ error: 'director 권한이 필요합니다' });
  }
  next();
}

// 특정 프로그램의 admin 이상 확인 미들웨어 팩토리
// router.get('/route', requireAuth, requireProgramAdmin, handler) 형식으로 사용
// req.params.programId 또는 req.params.id 에서 프로그램 ID 추출
export async function requireProgramAdmin(req, res, next) {
  const { role, userId } = req.user ?? {};
  if (!userId) return res.status(401).json({ error: '인증이 필요합니다' });

  // director는 모든 프로그램 접근 가능
  if (role === 'director') return next();

  const programId = req.params.programId ?? req.params.id;
  if (!programId) return res.status(400).json({ error: 'programId가 없습니다' });

  try {
    // program_admins 또는 프로그램 생성자(leader)인지 확인
    const [access] = await sql`
      SELECT 1
      FROM (
        SELECT pa.user_id
        FROM program_admins pa
        WHERE pa.program_id = ${programId} AND pa.user_id = ${userId}
        UNION
        SELECT l.user_id
        FROM programs p
        JOIN leaders l ON l.id = p.leader_id
        WHERE p.id = ${programId} AND l.user_id = ${userId}
      ) t
    `;

    if (!access) {
      return res.status(403).json({ error: '해당 프로그램의 관리자 권한이 없습니다' });
    }

    next();
  } catch (err) {
    console.error('프로그램 관리자 권한 확인 오류:', err);
    return res.status(500).json({ error: '서버 오류' });
  }
}
