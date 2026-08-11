-- 039: 봉사 담당자 배정 — 지명 · 수락 · 필요 인원
--
-- 015 에서 참가자가 봉사를 **신청**하는 데까지는 만들어 뒀는데, 담당자가
-- 그것을 보고 확정하는 쪽이 통째로 없었다. 신청을 받아도 아무도 볼 수 없는
-- 상태였다.
--
-- 여기서 더하는 것은 셋이다.
--
-- 1. 역할마다 **필요 인원**. "픽업 4명 필요 · 2명 확정" 처럼 부족분이 늘
--    숫자로 보여야 한다. 없으면 담당자는 무엇이 모자란지 끝까지 모른다.
--    programs.service_options(015) 의 원소에 needed 를 얹는다.
--    자유 추가 역할은 key 가 'custom:<uuid>' 이고 label 을 함께 갖는다 —
--    기본 역할의 이름은 ARB 로 4개 언어를 관리하지만, 담당자가 그 자리에서
--    만든 역할까지 번역할 수는 없다.
--
-- 2. **지명 후 수락**. 담당자가 찍는 것은 부탁이지 확정이 아니다.
--    invited(수락 대기) 와 declined(본인이 거절) 를 상태에 더한다.
--
-- 3. 역할마다 **책임자 한 명**(is_lead).

-- ── 상태값 확장 ────────────────────────────────────────────────
-- CHECK 제약은 바꿔 다는 수밖에 없다. 새 집합이 기존 집합을 포함하므로
-- 이미 저장된 행은 전부 통과한다 — 데이터가 날아가지 않는다.
-- DROP ... IF EXISTS 뒤에 다시 다는 형태라 여러 번 실행해도 같다.
ALTER TABLE service_signups
  DROP CONSTRAINT IF EXISTS service_signups_status_check;

ALTER TABLE service_signups
  ADD CONSTRAINT service_signups_status_check
  CHECK (status IN (
    'applied',            -- 참가자가 스스로 신청
    'invited',            -- 담당자가 지명, 본인 수락 대기
    'awaiting_approval',  -- 승인이 필요한 역할 (말씀조 리더 등)
    'confirmed',          -- 확정
    'rejected',           -- 담당자가 반려
    'declined'            -- 본인이 어렵다고 답함
  ));

-- ── 지명·수락 기록 ─────────────────────────────────────────────
ALTER TABLE service_signups
  -- 역할의 책임자. 한 역할에 한 명만 두지만 제약으로 걸지는 않는다 —
  -- 옮기는 중간에 잠깐 둘이 되는 것을 막으면 화면이 먼저 막힌다.
  ADD COLUMN IF NOT EXISTS is_lead      BOOLEAN NOT NULL DEFAULT FALSE,
  -- 누가 지명했는지. 참가자가 스스로 신청한 것과 구분된다.
  ADD COLUMN IF NOT EXISTS invited_by   UUID REFERENCES leaders(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS invited_at   TIMESTAMPTZ,
  -- 본인이 수락/거절한 시각. 오래 답이 없는 사람을 찾는 데 쓴다.
  ADD COLUMN IF NOT EXISTS responded_at TIMESTAMPTZ;

-- 담당자 화면은 "이 수양회의 봉사 신청 전부"를 한 번에 읽는다.
-- service_signups 에는 program_id 가 없고 registrations 를 거쳐야 하므로,
-- 조인 쪽 색인이 필요하다(registration_id 색인은 015 에 이미 있다).
CREATE INDEX IF NOT EXISTS idx_service_signups_key
  ON service_signups(service_key);
