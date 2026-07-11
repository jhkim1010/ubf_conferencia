// Firebase Cloud Messaging (FCM) 서비스
// 환경변수: FIREBASE_SERVICE_ACCOUNT (서비스 계정 JSON 문자열)
// Firebase Console → 프로젝트 설정 → 서비스 계정 → 새 비공개 키 생성

let _messaging = null;

// firebase-admin 초기화 (FIREBASE_SERVICE_ACCOUNT 환경변수가 있을 때만 활성화)
async function getMessaging() {
  if (_messaging) return _messaging;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!serviceAccountJson) return null;

  try {
    const admin = (await import('firebase-admin')).default;
    if (!admin.apps.length) {
      const serviceAccount = JSON.parse(serviceAccountJson);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    _messaging = admin.messaging();
    return _messaging;
  } catch (err) {
    console.warn('Firebase Admin 초기화 실패:', err.message);
    return null;
  }
}

// ─── 단일 또는 다중 토큰에 푸시 알림 전송 ─────────────────────
export async function sendPushNotification(tokens, title, body, data = {}) {
  if (!tokens || tokens.length === 0) return;

  const messaging = await getMessaging();
  if (!messaging) {
    console.warn('Firebase 미설정 — FCM 전송 건너뜀');
    return;
  }

  // 유효한 토큰만 필터링
  const validTokens = tokens.filter(t => t && typeof t === 'string');
  if (validTokens.length === 0) return;

  try {
    if (validTokens.length === 1) {
      await messaging.send({
        token: validTokens[0],
        notification: { title, body },
        data,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } else {
      // 최대 500개씩 배치 전송
      const chunks = [];
      for (let i = 0; i < validTokens.length; i += 500) {
        chunks.push(validTokens.slice(i, i + 500));
      }
      for (const chunk of chunks) {
        await messaging.sendEachForMulticast({
          tokens: chunk,
          notification: { title, body },
          data,
          android: { priority: 'high' },
          apns: { payload: { aps: { sound: 'default' } } },
        });
      }
    }
    console.log(`FCM 전송 완료 (${validTokens.length}명): ${title}`);
  } catch (err) {
    console.error('FCM 전송 오류:', err.message);
  }
}

// ─── 프로그램 참가자 전체에게 알림 전송 ──────────────────────────
export async function notifyProgramParticipants(sql, programId, title, body, data = {}) {
  try {
    const rows = await sql`
      SELECT fcm_token FROM registrations
      WHERE program_id = ${programId}
        AND fcm_token IS NOT NULL
    `;
    const tokens = rows.map(r => r.fcm_token);
    await sendPushNotification(tokens, title, body, data);
  } catch (err) {
    console.error('참가자 FCM 전송 오류:', err.message);
  }
}
