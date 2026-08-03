-- 033: 지부장이 어느 지부인지 서버가 알게 한다
--
-- 같은 지부 형제들에게 "지부장 OOO 님이 만든 수양회가 있습니다" 를 알리려면
-- 서버가 지부장↔지부를 알아야 한다. 지금까지 leaders 에는 이메일과 이름뿐이고,
-- 지부↔지부장 이메일 대응표(94개 지부)는 **앱 안에만** 있었다.
--
-- 대응표를 서버로 복사하지 않는다. 같은 표가 두 곳에 생기면 지부 목록이
-- 바뀔 때 한쪽만 고쳐 조용히 어긋난다. 대신 **지부장이 "예, 제가 지부장입니다"
-- 를 누르는 그 순간** 앱이 자기가 찾아낸 지부를 함께 보내고, 서버는 그것을
-- 적어 둔다. 사람이 직접 확인한 값이라 표보다 믿을 만하다.
--
-- nation_iso 는 ISO 코드다. registrations.country 와 맞춰 보기 위해서다 —
-- UBF 목록의 표기('BRASIL', 'U. S. A.')를 그대로 넣으면 절대 일치하지 않는다
-- (019 가 정리한 문제와 같다).
ALTER TABLE leaders
  ADD COLUMN IF NOT EXISTS chapter    TEXT,
  ADD COLUMN IF NOT EXISTS nation_iso TEXT;

-- 같은 지부 사람에게 그 지부장의 수양회를 찾아 주는 질의가 이 두 칸을 본다.
CREATE INDEX IF NOT EXISTS idx_leaders_chapter
  ON leaders (nation_iso, chapter);
