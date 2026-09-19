-- 071: 말씀 제목과 투어를 네 언어로
--
-- 070 이 공지를 옮겼다. 그런데 등록 첫 화면 맨 위에 가장 크게 떠 있는
-- 말씀 제목은 여전히 담당자가 적은 한 언어뿐이다 — 운영에는
-- "Apacentad la grey de Dios" 가 스페인어로만 들어 있고, 한국인 선교사가
-- 그 화면을 열면 읽을 수 없는 말이 가장 크게 떠 있다.
--
-- 투어도 같다. 담당자가 이미 설명 칸에 한국어와 스페인어를 손으로 섞어
-- 적고 있다 — 사람이 손으로 메우고 있다는 뜻이다.
--
-- **수양회 이름과 장소는 옮기지 않는다.** 고유명사에 가깝고, 국가 이름을
-- 영어로 두기로 한 것과 같은 판단이다. "Pilar, Buenos Aires" 를
-- "필라르, 부에노스아이레스" 로 바꾸면 택시 기사에게 보여 줄 수가 없다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS theme_title_i18n JSONB;
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS name_i18n JSONB;
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS description_i18n JSONB;

-- 성경 본문만은 **기계에 맡기지 않는다.**
--
-- "1Pedro 5:2a" 를 번역기에 넣으면 엉뚱한 말이 된다. 책 이름은 언어마다
-- 정해진 표기가 있고(베드로전서 / 1 Peter / 1Pedro), 그것은 번역이 아니라
-- 약속이다. 할인 항목(023)·숙박 수준(028)처럼 담당자가 직접 적는다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS theme_verse_i18n JSONB;

COMMENT ON COLUMN programs.theme_title_i18n IS
  '{ko,en,es,pt} 자동 번역. 비어 있으면 원문(theme_title)을 쓴다(071)';
COMMENT ON COLUMN programs.theme_verse_i18n IS
  '{ko,en,es,pt} 담당자가 직접 적는다. 기계 번역이 아니다(071)';
COMMENT ON COLUMN program_options.name_i18n IS
  '{ko,en,es,pt} 자동 번역. 비어 있으면 원문(name)을 쓴다(071)';
COMMENT ON COLUMN program_options.description_i18n IS
  '{ko,en,es,pt} 자동 번역. 비어 있으면 원문(description)을 쓴다(071)';
