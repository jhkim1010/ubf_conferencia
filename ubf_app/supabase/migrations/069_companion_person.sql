-- 069: 따로 등록할 수 없는 동반자
--
-- 지금 동반자 칸은 **사람 기록이 아니다.** 화면이 그렇게 말하고 있다 —
-- "동반자도 각자 따로 등록해야 합니다. 여기에 적는 것은 같은 방에 배정받기
-- 위해서입니다." 즉 같은 방으로 묶어 달라는 쪽지이고, 사람 수는 각자의
-- 등록에서 센다.
--
-- 아기는 그 등록을 만들 수 없다. 구글 계정이 없기 때문이다. 그래서 아기는
-- 어느 명단에도 없고 어느 방에도 없다.
--
-- 011 은 "사람 = 등록자 또는 동반자" 로 설계해 두었다
-- (room_assignments.companion_id 가 그 흔적이다). 배정 쪽이 그것을 한 번도
-- 쓰지 않았을 뿐이다. 그 설계를 이제 실제로 쓴다.
ALTER TABLE companions
  ADD COLUMN IF NOT EXISTS registers_separately BOOLEAN NOT NULL DEFAULT TRUE;

-- 방 정원을 한 자리 먹는가.
--
-- **"등록을 못 한다" 와 "침대를 쓴다" 는 다른 질문이다.** 여섯 살은 등록을
-- 못 하지만 침대는 쓴다. 기본값만 나이로 정하고(만 5세 이하는 안 씀) 고칠 수
-- 있게 둔다 — 다섯 살이면 따로 재우는 집도 있고, 나이로 잘라 버리면 그 집은
-- 방이 좁아지는데 고칠 방법이 없다.
ALTER TABLE companions
  ADD COLUMN IF NOT EXISTS occupies_bed BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN companions.registers_separately IS
  'false 면 이 줄이 곧 그 사람이다 — 방·식사·숙박에 센다. 말씀조에는 안 넣는다(069)';
COMMENT ON COLUMN companions.occupies_bed IS
  '방 정원을 한 자리 먹는가. 만 5세 이하는 기본 false 지만 고칠 수 있다(069)';

-- 돌 안 된 아기를 적을 수 있게 한다.
--
-- 011 의 CHECK (age > 0) 때문에 지금은 0 을 넣을 수 없어 1 살로 올려 적는
-- 수밖에 없었다. 그러면 나이로 정하는 것들(침대 기본값, 무료 여부)이 전부
-- 한 살씩 밀린다.
--
-- DROP 뒤에 ADD 하므로 여러 번 돌려도 같은 결과다.
DO $$ BEGIN
  ALTER TABLE companions DROP CONSTRAINT IF EXISTS companions_age_check;
  ALTER TABLE companions
    ADD CONSTRAINT companions_age_check
    CHECK (age IS NULL OR (age >= 0 AND age < 150));
END $$;
