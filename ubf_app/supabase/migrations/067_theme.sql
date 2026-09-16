-- 067: 수양회 말씀 제목과 성경 본문
--
-- 수양회에는 이름과 별개로 그 해의 말씀 제목이 있다. 이름은 행정용이고
-- ("La Conferencia del año nuevo ... 2027"), 제목은 그 모임이 무엇을 위한
-- 것인지 말한다. 지금까지는 어디에도 적을 자리가 없어서 포스터와 단톡방에만
-- 있었다.
--
-- 두 칸 다 **한 줄**이다. 말씀 전문을 적는 칸은 두지 않는다 — 전문은 자료실
-- (030)에 올리는 것이 맞고, 여기에 넣으면 등록 첫 화면이 성경 본문으로
-- 채워진다.
--
-- 비워 두면 화면에 아무것도 안 나온다. 이미 만들어 둔 수양회는 그대로다.
--
-- 번호가 066 을 건너뛴다. 숙박 단가 범위와 개최국 참석자 숙박 작업이
-- 스키마를 안 바꿨는데 코드 주석이 그 번호를 쓰고 있어서, 여기서 066 을
-- 쓰면 번호가 가리키는 것이 엇갈린다. 064 도 같은 이유로 비어 있다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS theme_title TEXT;
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS theme_verse TEXT;

COMMENT ON COLUMN programs.theme_title IS
  '수양회 말씀 제목. 한 줄이며 등록 첫 화면 맨 위에 나온다(067)';
COMMENT ON COLUMN programs.theme_verse IS
  '말씀 제목의 성경 본문(장절). 전문이 아니라 "마태복음 5:14-16" 같은 표기(067)';
