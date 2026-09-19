-- 070: 공지를 네 언어로
--
-- 공지는 담당자가 적은 언어 그대로 전원에게 간다. 스페인어로 적으면 한국인
-- 선교사가, 한국어로 적으면 현지 참가자가 못 읽는다. "3조는 강당 앞에
-- 모여 주세요" 를 못 읽으면 그 사람은 안 온다.
--
-- 짧은 이름(할인 항목 023, 숙박 수준 028)은 담당자가 언어별로 직접 적는다.
-- 공지는 그렇게 못 한다 — 급할 때 네 번 적으라고 하면 결국 한 언어로만
-- 보내게 된다. 그래서 저장할 때 기계가 옮긴다.
--
-- **원문을 지우지 않는다.** title·body 는 담당자가 적은 그대로 남고,
-- 번역은 옆에 따로 쌓인다. 기계가 엉뚱하게 옮겨도 무엇을 적었는지는
-- 남아 있어야 하고, 화면도 "자동 번역" 이라고 밝힌다.
--
-- 번역기를 안 붙인 서버에서는 이 칸이 비어 있고, 그때는 예전처럼 원문이
-- 그대로 나간다.
ALTER TABLE announcements
  ADD COLUMN IF NOT EXISTS title_i18n JSONB;
ALTER TABLE announcements
  ADD COLUMN IF NOT EXISTS body_i18n JSONB;

-- 담당자가 무슨 말로 적었는가. 그 언어는 번역하지 않고 원문을 쓴다.
ALTER TABLE announcements
  ADD COLUMN IF NOT EXISTS source_lang TEXT;

COMMENT ON COLUMN announcements.title_i18n IS
  '{ko,en,es,pt} 자동 번역. 비어 있으면 원문(title)을 쓴다(070)';
COMMENT ON COLUMN announcements.body_i18n IS
  '{ko,en,es,pt} 자동 번역. 비어 있으면 원문(body)을 쓴다(070)';
COMMENT ON COLUMN announcements.source_lang IS
  '담당자가 적은 언어. 그 언어는 번역이 아니라 원문이다(070)';
