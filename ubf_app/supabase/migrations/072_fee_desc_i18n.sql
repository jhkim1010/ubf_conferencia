-- 072: 참가비 등급 설명도 네 언어로
--
-- 071 이 말씀 제목과 투어를 옮겼다. 등급 설명이 빠져 있었는데, 운영에는
-- "desde almuerzo de 21 hasta cena de 24 de Enero, 2027, hospedaje
-- (desde 21-23. Enero) está incluido" 가 스페인어로만 들어 있다.
--
-- 이 줄은 **참가자가 반드시 읽어야 하는 글**이다. 값에 무엇이 들어 있는지가
-- 여기 적히고, 못 읽으면 나중에 "그럼 밥값은?" 이 된다. 등록 첫 화면에서
-- 일부러 본문 두 배로 키워 둔 줄이기도 하다.
--
-- 071 파일을 고치지 않고 새로 만든다. 이미 올라간 마이그레이션은 사후에
-- 고치지 않는 것이 이 저장소의 규칙이다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS fee_basic_desc_i18n JSONB;
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS fee_premium_desc_i18n JSONB;

COMMENT ON COLUMN programs.fee_basic_desc_i18n IS
  '{ko,en,es,pt} 자동 번역. 비어 있으면 원문(fee_basic_desc)을 쓴다(072)';
COMMENT ON COLUMN programs.fee_premium_desc_i18n IS
  '{ko,en,es,pt} 자동 번역. 비어 있으면 원문(fee_premium_desc)을 쓴다(072)';
