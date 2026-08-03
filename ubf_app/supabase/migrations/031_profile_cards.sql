-- 031: QR 나눔 — 명함(요절·기도제목·연락처·채널)과 친구 목록
--
-- 수양회에서 만난 사람과 연락처를 주고받는다. 종이 쪽지와 카톡 아이디 교환을
-- 대신한다. 상대의 QR 을 읽으면 명함이 뜨고, 저장하면 수양회가 끝난 뒤에도
-- 언제든 다시 본다.
--
-- users 에 붙이지 않고 따로 둔다. 명함은 나눔 기능의 것이고 users 는
-- 로그인·권한의 것이다 — 섞으면 명함 항목 하나 고칠 때마다 인증 경로를
-- 건드리게 된다.

CREATE TABLE IF NOT EXISTS profile_cards (
  user_id        UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,

  photo_url      TEXT,
  life_verse_ref  TEXT,   -- '요한복음 10:10'
  life_verse_text TEXT,   -- 본문 (선택)
  -- 기도제목은 여러 줄이다. 한 칸에 몰아넣으면 화면에서 다시 쪼개야 하고,
  -- 쪼개는 규칙이 화면마다 달라진다.
  prayer_topics  JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- 연락 수단. 값과 공개 여부를 따로 둔다 — 껐다고 지우면 다시 켤 때
  -- 처음부터 적어야 한다.
  email          TEXT,
  whatsapp       TEXT,
  phone          TEXT,
  show_email     BOOLEAN NOT NULL DEFAULT FALSE,
  show_whatsapp  BOOLEAN NOT NULL DEFAULT FALSE,
  show_phone     BOOLEAN NOT NULL DEFAULT FALSE,

  -- 채널. 아이디만 저장하고 주소는 앱이 만든다 — 사람마다 @maria.f,
  -- instagram.com/maria.f, 전체 주소를 섞어 적는데 그대로 저장하면
  -- 눌렀을 때 열리지 않는다.
  instagram      TEXT,
  x_handle       TEXT,
  youtube        TEXT,
  show_instagram BOOLEAN NOT NULL DEFAULT FALSE,
  show_x         BOOLEAN NOT NULL DEFAULT FALSE,
  show_youtube   BOOLEAN NOT NULL DEFAULT FALSE,

  -- QR 에 담기는 값. 개인정보가 아니라 이 토큰 하나다.
  -- 새로 만들면 예전 QR 은 그 자리에서 무효가 된다 — 사진에 찍혀도 취소할
  -- 방법이 있어야 마음 놓고 보여준다.
  share_token    TEXT NOT NULL,

  -- 'token'  = QR 을 읽은 사람만 (기본)
  -- 'program'= 같은 수양회 참가자 전체
  visibility     TEXT NOT NULL DEFAULT 'token',

  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_profile_cards_token
  ON profile_cards (share_token);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profile_cards_visibility_check'
  ) THEN
    ALTER TABLE profile_cards
      ADD CONSTRAINT profile_cards_visibility_check
      CHECK (visibility IN ('token', 'program'));
  END IF;
END $$;

-- 친구 목록. **한쪽 방향이다** — 읽은 사람이 저장한다.
-- 양쪽이 모두 눌러야 성립하게 하면, 공항에서 헤어지기 직전에 한 사람이
-- 못 누르는 순간 아무것도 남지 않는다.
CREATE TABLE IF NOT EXISTS card_connections (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  -- 어느 수양회에서 만났는지. "작년 수양회에서 만난 그 브라질 형제"가
  -- 사람을 찾는 실제 방식이다.
  program_id     UUID REFERENCES programs(id) ON DELETE SET NULL,
  met_on         DATE NOT NULL DEFAULT CURRENT_DATE,
  -- 메모는 **저장한 쪽만** 본다. 상대에게 보이면 아무도 솔직하게 적지 않는다.
  note           TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 같은 사람을 두 번 저장하지 않는다. 두 번 읽어도 목록은 하나여야 한다.
CREATE UNIQUE INDEX IF NOT EXISTS idx_card_connections_pair
  ON card_connections (owner_user_id, friend_user_id);

-- "나를 저장한 사람" 목록을 보여주고 하나씩 끊을 수 있어야 한다 —
-- 준 것을 돌려받을 수 있어야 마음 놓고 준다.
CREATE INDEX IF NOT EXISTS idx_card_connections_friend
  ON card_connections (friend_user_id);
