import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth } from '../middleware/auth.js';
import {
  applyJuniorLock,
  isJunior,
  isValidToken,
  newShareToken,
  normalizeEmail,
  normalizeHandle,
  normalizePhone,
  normalizePrayerTopics,
  publicCard,
} from '../services/profile_card.js';

const router = Router();

// QR 나눔(031) — 명함과 친구 목록
//
// 수양회에서 만난 사람과 요절·기도제목·연락처를 주고받는다.
// QR 에는 개인정보가 아니라 토큰 하나가 담기고, 내용은 그때그때 여기서
// 가져간다 — 본인이 고치면 나눈 사람 모두에게 바뀐 내용이 보인다.

// 명함 + 그 사람의 표시 정보를 한 번에 읽는다.
// 이름·나라·지부는 users 와 가장 최근 등록에서 온다.
async function loadCardByToken(token) {
  const [row] = await sql`
    SELECT c.*, u.name, u.age,
           r.bible_name, r.country, r.branch
    FROM profile_cards c
    JOIN users u ON u.id = c.user_id
    LEFT JOIN LATERAL (
      SELECT bible_name, country, branch
      FROM registrations
      WHERE user_id = c.user_id
      ORDER BY updated_at DESC NULLS LAST
      LIMIT 1
    ) r ON TRUE
    WHERE c.share_token = ${token}
  `;
  return row ?? null;
}

// ─── 내 명함 ─────────────────────────────────────────────────

// GET /cards/me — 내 명함 (내 것이므로 값이 그대로 온다)
router.get('/me', requireAuth, async (req, res) => {
  try {
    let [row] = await sql`
      SELECT * FROM profile_cards WHERE user_id = ${req.user.userId}
    `;
    // 처음 열면 만들어 준다. "만들기" 버튼을 따로 두면 그 버튼을 안 누른
    // 사람은 QR 을 보여줄 수 없다.
    if (!row) {
      [row] = await sql`
        INSERT INTO profile_cards (user_id, share_token)
        VALUES (${req.user.userId}, ${newShareToken()})
        ON CONFLICT (user_id) DO UPDATE SET updated_at = NOW()
        RETURNING *
      `;
    }
    const [{ age }] = await sql`
      SELECT age FROM users WHERE id = ${req.user.userId}
    `;
    res.json({
      ...row,
      // 화면이 연락처 칸을 잠근 채로 보여주려면 이유를 알아야 한다.
      junior_locked: isJunior(age),
    });
  } catch (err) {
    console.error('명함 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PUT /cards/me — 내 명함 저장
router.put('/me', requireAuth, async (req, res) => {
  const b = req.body ?? {};
  try {
    const [user] = await sql`SELECT age FROM users WHERE id = ${req.user.userId}`;

    // 켜 달라는 대로 두되, 19세 이하는 연락을 잠근다.
    // **화면에서 감추는 것만으로는 부족하다** — 예전 앱이나 직접 호출은
    // 그 화면을 거치지 않는다.
    const flags = applyJuniorLock(
      {
        show_email: b.showEmail === true,
        show_whatsapp: b.showWhatsapp === true,
        show_phone: b.showPhone === true,
        show_instagram: b.showInstagram === true,
        show_x: b.showX === true,
        show_youtube: b.showYoutube === true,
      },
      user?.age,
    );

    const topics = normalizePrayerTopics(b.prayerTopics);
    const visibility = b.visibility === 'program' ? 'program' : 'token';

    await sql`
      INSERT INTO profile_cards (
        user_id, share_token,
        photo_url, life_verse_ref, life_verse_text, prayer_topics,
        email, whatsapp, phone, instagram, x_handle, youtube,
        show_email, show_whatsapp, show_phone,
        show_instagram, show_x, show_youtube,
        visibility
      ) VALUES (
        ${req.user.userId}, ${newShareToken()},
        ${b.photoUrl ?? null},
        ${b.lifeVerseRef ?? null},
        ${b.lifeVerseText ?? null},
        ${JSON.stringify(topics ?? [])}::jsonb,
        ${normalizeEmail(b.email)},
        ${normalizePhone(b.whatsapp)},
        ${normalizePhone(b.phone)},
        ${normalizeHandle(b.instagram)},
        ${normalizeHandle(b.x)},
        ${normalizeHandle(b.youtube, { allowSlash: true })},
        ${flags.show_email}, ${flags.show_whatsapp}, ${flags.show_phone},
        ${flags.show_instagram}, ${flags.show_x}, ${flags.show_youtube},
        ${visibility}
      )
      ON CONFLICT (user_id) DO UPDATE SET
        photo_url       = EXCLUDED.photo_url,
        life_verse_ref  = EXCLUDED.life_verse_ref,
        life_verse_text = EXCLUDED.life_verse_text,
        -- 안 보냈으면 지우지 않는다. 사진만 바꾸는 저장이 기도제목을
        -- 날려 버리면 안 된다.
        prayer_topics   = CASE WHEN ${topics !== null}
                            THEN EXCLUDED.prayer_topics
                            ELSE profile_cards.prayer_topics END,
        email           = EXCLUDED.email,
        whatsapp        = EXCLUDED.whatsapp,
        phone           = EXCLUDED.phone,
        instagram       = EXCLUDED.instagram,
        x_handle        = EXCLUDED.x_handle,
        youtube         = EXCLUDED.youtube,
        show_email      = EXCLUDED.show_email,
        show_whatsapp   = EXCLUDED.show_whatsapp,
        show_phone      = EXCLUDED.show_phone,
        show_instagram  = EXCLUDED.show_instagram,
        show_x          = EXCLUDED.show_x,
        show_youtube    = EXCLUDED.show_youtube,
        visibility      = EXCLUDED.visibility,
        -- 토큰은 저장할 때마다 바뀌면 안 된다. 이미 나눠 준 QR 이 전부
        -- 무효가 된다. 바꾸는 것은 아래 전용 경로에서만 한다.
        updated_at      = NOW()
    `;
    res.json({ ok: true, juniorLocked: isJunior(user?.age) });
  } catch (err) {
    console.error('명함 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// POST /cards/me/token — QR 새로 만들기
//
// 사진에 찍혔거나 모르는 사람이 저장했을 때 쓴다. 예전 QR 은 그 자리에서
// 무효가 된다. **이미 저장한 친구는 그대로 남는다** — 토큰은 처음 여는
// 열쇠일 뿐이고, 저장된 연결은 따로 있다.
router.post('/me/token', requireAuth, async (req, res) => {
  try {
    const token = newShareToken();
    const [row] = await sql`
      UPDATE profile_cards SET share_token = ${token}, updated_at = NOW()
      WHERE user_id = ${req.user.userId}
      RETURNING share_token
    `;
    if (!row) return res.status(404).json({ error: '명함이 없습니다' });
    res.json({ shareToken: row.share_token });
  } catch (err) {
    console.error('QR 재발급 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ─── 남의 명함 열기 ──────────────────────────────────────────

// GET /cards/by-token/:token — QR 을 읽은 뒤 미리보기
//
// 읽자마자 저장되지 않는다. 보고 나서 저장을 누른다 —
// "충분히 교제했고 나누고 싶을 때"가 이 기능의 조건이다.
router.get('/by-token/:token', requireAuth, async (req, res) => {
  if (!isValidToken(req.params.token)) {
    return res.status(400).json({ error: '올바른 코드가 아닙니다' });
  }
  try {
    const row = await loadCardByToken(req.params.token);
    // 없는 토큰과 만료된(새로 만든) 토큰을 구분해 알리지 않는다.
    if (!row) return res.status(404).json({ error: '만료되었거나 없는 코드입니다' });
    if (row.user_id === req.user.userId) {
      return res.status(409).json({ code: 'SELF', error: '내 명함입니다' });
    }

    const [saved] = await sql`
      SELECT id FROM card_connections
      WHERE owner_user_id = ${req.user.userId} AND friend_user_id = ${row.user_id}
    `;
    res.json({
      userId: row.user_id,
      alreadySaved: !!saved,
      card: publicCard(row, {
        name: row.name,
        bibleName: row.bible_name,
        country: row.country,
        branch: row.branch,
      }),
    });
  } catch (err) {
    console.error('명함 열기 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ─── 친구 목록 ───────────────────────────────────────────────

// POST /cards/connections — 친구로 저장
router.post('/connections', requireAuth, async (req, res) => {
  const { friendUserId, programId, note } = req.body ?? {};
  if (!friendUserId || friendUserId === req.user.userId) {
    return res.status(400).json({ error: '저장할 수 없습니다' });
  }
  try {
    await sql`
      INSERT INTO card_connections (owner_user_id, friend_user_id, program_id, note)
      VALUES (${req.user.userId}, ${friendUserId}, ${programId ?? null}, ${note ?? null})
      -- 두 번 읽어도 목록은 하나여야 한다. 만난 날은 처음 것을 남긴다.
      ON CONFLICT (owner_user_id, friend_user_id) DO UPDATE SET
        note = COALESCE(EXCLUDED.note, card_connections.note)
    `;
    res.status(201).json({ ok: true });
  } catch (err) {
    console.error('친구 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// GET /cards/connections — 내가 저장한 사람들
router.get('/connections', requireAuth, async (req, res) => {
  try {
    const rows = await sql`
      SELECT cc.id, cc.friend_user_id, cc.program_id, cc.met_on, cc.note,
             p.name AS program_name,
             c.*, u.name, r.bible_name, r.country, r.branch
      FROM card_connections cc
      JOIN users u ON u.id = cc.friend_user_id
      LEFT JOIN profile_cards c ON c.user_id = cc.friend_user_id
      LEFT JOIN programs p ON p.id = cc.program_id
      LEFT JOIN LATERAL (
        SELECT bible_name, country, branch
        FROM registrations WHERE user_id = cc.friend_user_id
        ORDER BY updated_at DESC NULLS LAST LIMIT 1
      ) r ON TRUE
      WHERE cc.owner_user_id = ${req.user.userId}
      ORDER BY cc.met_on DESC, u.name
    `;
    res.json(
      rows.map((row) => ({
        id: row.id,
        userId: row.friend_user_id,
        programId: row.program_id,
        programName: row.program_name,
        metOn: row.met_on,
        note: row.note,
        card: publicCard(row, {
          name: row.name,
          bibleName: row.bible_name,
          country: row.country,
          branch: row.branch,
        }),
      })),
    );
  } catch (err) {
    console.error('친구 목록 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// PATCH /cards/connections/:id — 내 메모 (저장한 쪽만 본다)
router.patch('/connections/:id', requireAuth, async (req, res) => {
  try {
    const [row] = await sql`
      UPDATE card_connections SET note = ${req.body?.note ?? null}
      WHERE id = ${req.params.id} AND owner_user_id = ${req.user.userId}
      RETURNING id
    `;
    if (!row) return res.status(404).json({ error: '없습니다' });
    res.json({ ok: true });
  } catch (err) {
    console.error('메모 저장 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /cards/connections/:id — 내 목록에서 지우기
router.delete('/connections/:id', requireAuth, async (req, res) => {
  try {
    await sql`
      DELETE FROM card_connections
      WHERE id = ${req.params.id} AND owner_user_id = ${req.user.userId}
    `;
    res.json({ ok: true });
  } catch (err) {
    console.error('친구 삭제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ─── 나를 저장한 사람 ────────────────────────────────────────
//
// 준 것을 돌려받을 수 있어야 마음 놓고 준다. 누가 내 명함을 갖고 있는지
// 보이고, 하나씩 끊을 수 있다.
//
// 여기서 "나도 저장" 을 누르면 서로 갖게 된다 — 저장은 한쪽 방향이라
// QR 을 든 사람은 상대를 갖고 있지 않다.
router.get('/saved-by', requireAuth, async (req, res) => {
  try {
    const rows = await sql`
      SELECT cc.id, cc.owner_user_id, cc.met_on, u.name,
             p.name AS program_name,
             EXISTS (
               SELECT 1 FROM card_connections back
               WHERE back.owner_user_id = ${req.user.userId}
                 AND back.friend_user_id = cc.owner_user_id
             ) AS saved_back
      FROM card_connections cc
      JOIN users u ON u.id = cc.owner_user_id
      LEFT JOIN programs p ON p.id = cc.program_id
      WHERE cc.friend_user_id = ${req.user.userId}
      ORDER BY cc.met_on DESC
    `;
    res.json(
      rows.map((r) => ({
        id: r.id,
        userId: r.owner_user_id,
        name: r.name,
        programName: r.program_name,
        metOn: r.met_on,
        savedBack: r.saved_back,
      })),
    );
  } catch (err) {
    console.error('나를 저장한 사람 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// DELETE /cards/saved-by/:id — 상대가 가진 내 명함을 끊는다
router.delete('/saved-by/:id', requireAuth, async (req, res) => {
  try {
    await sql`
      DELETE FROM card_connections
      WHERE id = ${req.params.id} AND friend_user_id = ${req.user.userId}
    `;
    res.json({ ok: true });
  } catch (err) {
    console.error('연결 끊기 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
