-- 025: 말씀 공부 언어 + 소수 인원 처리 방침
--
-- 성경공부 팀은 **사용 언어**로 먼저 갈리고, 그 안에서 연령대로 나뉜다.
-- Adulto 20세 이상 / Junior 19세 이하.
--
-- 언어를 짐작하지 않고 참석자에게 직접 묻는다. 앱 표시 언어나 국가로
-- 유추하면 틀린다 — 아르헨티나에 사는 한인 2세는 스페인어로 공부하고,
-- 스페인어권에 파송된 한국인 선교사는 한국어로 공부한다. 둘 다 흔하다.

-- ── 참석자가 고른 공부 언어 ──────────────────────────────────
-- ISO 639-1 두 글자. 목록을 CHECK 로 못박지 않는다 — 지부가 늘면
-- 마이그레이션을 다시 써야 하고, 기존 마이그레이션은 고치지 않는 것이 규칙이다.
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS study_language TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'registrations_study_language_format'
  ) THEN
    ALTER TABLE registrations
      ADD CONSTRAINT registrations_study_language_format
      CHECK (study_language IS NULL OR study_language ~ '^[a-z]{2}$');
  END IF;
END $$;

-- ── 조 자체가 어느 칸에 속하는지 ─────────────────────────────
-- 엔진이 사람을 조에 나눠 담으려면 조가 어느 (언어 × 연령대) 칸인지 알아야
-- 한다. 없으면 "스페인어 Junior 를 한국어 Adulto 조에 넣지 않는다"를
-- 표현할 방법이 없다.
--
-- 둘 다 NULL 이면 "아무나 받는 조"다. 025 이전에 만들어진 조가 이 상태이며,
-- 그대로 두면 예전 수양회의 배정이 깨지지 않는다.
ALTER TABLE groups
  ADD COLUMN IF NOT EXISTS study_language TEXT,
  ADD COLUMN IF NOT EXISTS age_band       TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'groups_age_band_values'
  ) THEN
    ALTER TABLE groups
      ADD CONSTRAINT groups_age_band_values
      CHECK (age_band IS NULL OR age_band IN ('adulto', 'junior'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_groups_cohort
  ON groups(program_id, study_language, age_band);

-- ── 인원이 적은 칸을 어떻게 할지 ─────────────────────────────
-- 스페인어 Junior 가 3명뿐인 경우가 실제로 생긴다. 자동으로 처리하면
-- 왜 그렇게 배정됐는지 아무도 모르므로, 관리자가 미리 정해 둔다.
--
--   absorb — 같은 언어의 Adulto 조로 올린다 (말이 통하는 쪽을 우선)
--   merge  — 같은 연령대의 다른 언어 조와 합친다 (또래를 우선)
--   keep   — 그대로 둔다. 받을 조가 없으면 미배정으로 남겨 관리자가 본다
--
-- 기본값은 keep 이다. 조용히 옮기는 것보다 "3명이 남았습니다"를 보여 주는
-- 편이 낫다 — 옮기는 것은 되돌리기 어렵고, 남기는 것은 아니다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS small_cohort_policy TEXT NOT NULL DEFAULT 'keep',
  ADD COLUMN IF NOT EXISTS min_team_size       INTEGER NOT NULL DEFAULT 5;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'programs_small_cohort_policy_values'
  ) THEN
    ALTER TABLE programs
      ADD CONSTRAINT programs_small_cohort_policy_values
      CHECK (small_cohort_policy IN ('absorb', 'merge', 'keep'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'programs_min_team_size_range'
  ) THEN
    ALTER TABLE programs
      ADD CONSTRAINT programs_min_team_size_range
      CHECK (min_team_size BETWEEN 1 AND 50);
  END IF;
END $$;
