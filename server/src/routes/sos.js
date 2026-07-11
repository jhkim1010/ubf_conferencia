import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';
import { notifyProgramAdmins } from '../services/telegram.js';
import { sendPushNotification } from '../services/fcm.js';

const router = Router();

const SITUATION_LABELS = {
  health:  '🚑 건강/의료 응급',
  safety:  '🆘 신변 위협',
  lost:    '🗺️ 길을 잃음',
};

// POST /sos - SOS 발령 (참가자)
router.post('/', requireAuth, async (req, res) => {
  const {
    programId, situationType, latitude, longitude, message, realName,
  } = req.body;

  if (!programId || !situationType) {
    return res.status(400).json({ error: 'programId, situationType이 필요합니다' });
  }

  try {
    // 프로그램 존재 확인
    const [program] = await sql`
      SELECT id, name FROM programs WHERE id = ${programId}
    `;
    if (!program) return res.status(404).json({ error: '프로그램을 찾을 수 없습니다' });

    const [alert] = await sql`
      INSERT INTO sos_alerts
        (program_id, user_id, real_name, latitude, longitude, situation_type, message)
      VALUES (
        ${programId}, ${req.user.userId},
        ${realName ?? req.user.name ?? null},
        ${latitude ?? null}, ${longitude ?? null},
        ${situationType}, ${message ?? null}
      )
      RETURNING id, created_at
    `;

    const name = realName ?? req.user.name ?? '참가자';
    const label = SITUATION_LABELS[situationType] ?? situationType;
    const locationLine = latitude && longitude
      ? `\n📍 위치: https://maps.google.com/?q=${latitude},${longitude}`
      : '\n📍 위치: 수신 불가';
    const msgLine = message ? `\n💬 "${message}"` : '';

    const telegramMsg =
      `🆘 <b>[${program.name}] SOS 긴급 알림</b>\n\n` +
      `👤 ${name}\n` +
      `⚠️ 상황: ${label}` +
      locationLine +
      msgLine +
      `\n\n<i>앱에서 확인하고 즉시 대응해 주세요.</i>`;

    // Telegram 관리자 알림 (즉시)
    notifyProgramAdmins(programId, telegramMsg).catch(err =>
      console.error('SOS Telegram 알림 오류:', err.message)
    );

    // 관리자 FCM 푸시 알림
    const adminTokens = await sql`
      SELECT DISTINCT r.fcm_token
      FROM registrations r
      JOIN users u ON u.id = r.user_id
      WHERE r.program_id = ${programId}
        AND r.fcm_token IS NOT NULL
        AND (
          u.role IN ('director', 'admin')
          OR EXISTS (
            SELECT 1 FROM program_admins pa
            WHERE pa.program_id = ${programId} AND pa.user_id = u.id
          )
        )
    `;
    const tokens = adminTokens.map(t => t.fcm_token);
    sendPushNotification(
      tokens,
      `🆘 SOS: ${name}`,
      `${label}${locationLine.replace('\n', '')}`,
      { type: 'sos', alertId: alert.id, programId }
    ).catch(console.error);

    res.status(201).json({ id: alert.id, createdAt: alert.created_at });
  } catch (err) {
    console.error('SOS 발령 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /sos/:programId - 프로그램의 SOS 목록 (admin 이상)
router.get('/:programId', requireAuth, requireProgramAdmin, async (req, res) => {
  try {
    const alerts = await sql`
      SELECT s.*,
        u.email AS user_email
      FROM sos_alerts s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE s.program_id = ${req.params.programId}
      ORDER BY s.created_at DESC
    `;
    res.json(alerts);
  } catch (err) {
    console.error('SOS 목록 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /sos/:alertId/resolve - SOS 해제 (admin 이상)
router.patch('/:alertId/resolve', requireAuth, async (req, res) => {
  try {
    const [alert] = await sql`
      UPDATE sos_alerts
      SET status = 'resolved', resolved_by = ${req.user.userId}, resolved_at = NOW()
      WHERE id = ${req.params.alertId}
      RETURNING id, program_id, real_name
    `;
    if (!alert) return res.status(404).json({ error: 'SOS 알림을 찾을 수 없습니다' });

    // 해제 알림 (Telegram)
    const telegramMsg =
      `✅ <b>SOS 해제됨</b>\n\n` +
      `👤 ${alert.real_name ?? '참가자'} 의 SOS가 해제되었습니다.`;
    notifyProgramAdmins(alert.program_id, telegramMsg).catch(console.error);

    res.json({ success: true });
  } catch (err) {
    console.error('SOS 해제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
