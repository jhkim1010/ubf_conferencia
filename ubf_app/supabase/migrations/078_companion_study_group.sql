-- 078: 함께 등록한 동반자의 말씀조(분반)
--
-- 같은 비행기로 함께 오는 가족은 **대표자의 등록 안에서 끝낸다.** 이름·나이·
-- 성별·같은 방(077)에 더해 "같은 분반에서 공부하는가" 를 묻는다.
--
-- 지금까지 함께 등록한 동반자는 말씀조에 아예 안 들어갔다(069). 아기를 생각한
-- 규칙이었는데, 어른 배우자도 같은 칸으로 적으면 조가 없는 사람이 된다.
--
--   same   대표자와 같은 조. 자동 배정은 대표자와 한 묶음으로 다룬다.
--   other  조에 들지만 대표자와 따로. 한 사람으로 배정한다.
--   none   조에 안 든다(아기·어린이). 069 까지의 뜻이다.
--
-- 기본은 none 이다 — 지금까지의 모든 동반자가 그렇게 다뤄져 왔다.
-- 따로 등록하는 동반자는 자기 등록으로 조에 들므로 이 칸을 쓰지 않는다.
ALTER TABLE companions
  ADD COLUMN IF NOT EXISTS study_group TEXT NOT NULL DEFAULT 'none';

-- DROP 뒤에 ADD 하므로 여러 번 돌려도 같은 결과다.
DO $$ BEGIN
  ALTER TABLE companions DROP CONSTRAINT IF EXISTS companions_study_group_check;
  ALTER TABLE companions
    ADD CONSTRAINT companions_study_group_check
    CHECK (study_group IN ('same', 'other', 'none'));
END $$;

COMMENT ON COLUMN companions.study_group IS
  'same=대표자와 같은 말씀조, other=따로 배정, none=조에 안 듦(078)';

-- 말씀조에도 동반자가 든다. room_assignments(011)와 같은 모양이다 —
-- 등록 아니면 동반자, 둘 중 하나.
ALTER TABLE group_members
  ADD COLUMN IF NOT EXISTS companion_id UUID REFERENCES companions(id) ON DELETE CASCADE;

DO $$ BEGIN
  ALTER TABLE group_members DROP CONSTRAINT IF EXISTS group_members_one_person;
  ALTER TABLE group_members
    ADD CONSTRAINT group_members_one_person CHECK (
      (registration_id IS NOT NULL AND companion_id IS NULL) OR
      (registration_id IS NULL AND companion_id IS NOT NULL)
    );
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_group_member_comp
  ON group_members(companion_id) WHERE companion_id IS NOT NULL;
