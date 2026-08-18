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

// ─── 고른 사람들에게만 알림 전송 (044) ──────────────────────────
//
// 전체에게만 보낼 수 있으면 쓸모가 반이다. "302호 사람들만", "3조만" 처럼
// 좁혀 보내야 할 일이 실제로 더 많다.
//
// **좁히려던 것이 넓어지는 쪽이 가장 나쁘다.** 그래서 모르는 갈래가 오면
// 아무에게도 보내지 않는다 — 전체로 떨어뜨리지 않는다.
export async function notifyAudience(sql, programId, audience, title, body, data = {}) {
  try {
    const kind = audience?.kind;
    const id = audience?.id ?? null;
    let rows;

    if (kind === 'all') {
      rows = await sql`
        SELECT fcm_token FROM registrations
        WHERE program_id = ${programId} AND fcm_token IS NOT NULL
          AND counts_as_participant(real_name, submitted)
      `;
    } else if (kind === 'room') {
      rows = await sql`
        SELECT r.fcm_token FROM registrations r
        JOIN room_assignments ra ON ra.registration_id = r.id
        JOIN rooms rm ON rm.id = ra.room_id
        WHERE rm.id = ${id} AND rm.program_id = ${programId}
          AND r.fcm_token IS NOT NULL
      `;
    } else if (kind === 'group') {
      rows = await sql`
        SELECT r.fcm_token FROM registrations r
        JOIN group_members gm ON gm.registration_id = r.id
        JOIN groups g ON g.id = gm.group_id
        WHERE g.id = ${id} AND g.program_id = ${programId}
          AND r.fcm_token IS NOT NULL
      `;
    } else if (kind === 'unsubmitted') {
      rows = await sql`
        SELECT fcm_token FROM registrations
        WHERE program_id = ${programId} AND submitted = false
          AND fcm_token IS NOT NULL AND counts_as_participant(real_name, submitted)
      `;
    } else if (kind === 'unpaid') {
      rows = await sql`
        SELECT r.fcm_token FROM registrations r
        LEFT JOIN payments pay ON pay.registration_id = r.id
        WHERE r.program_id = ${programId}
          AND COALESCE(pay.status, 'none') <> 'confirmed'
          AND r.fcm_token IS NOT NULL AND counts_as_participant(r.real_name, r.submitted)
      `;
    } else if (kind === 'service') {
      // 그 역할을 **맡은** 사람. 거절·반려는 뺀다 — 안 하겠다고 한 사람에게
      // 그 일의 공지를 보내면 안 된다.
      rows = await sql`
        SELECT r.fcm_token FROM registrations r
        JOIN service_signups ss ON ss.registration_id = r.id
        WHERE r.program_id = ${programId}
          AND ss.service_key = ${id}
          AND ss.status NOT IN ('declined', 'rejected')
          AND r.fcm_token IS NOT NULL AND counts_as_participant(r.real_name, r.submitted)
      `;
    } else {
      console.error('알 수 없는 알림 대상:', kind);
      return 0;
    }

    const tokens = [...new Set(rows.map((r) => r.fcm_token))];
    await sendPushNotification(tokens, title, body, data);
    return tokens.length;
  } catch (err) {
    console.error('대상 알림 전송 오류:', err.message);
    return 0;
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
