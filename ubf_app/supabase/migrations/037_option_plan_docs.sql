-- 037: 투어 옵션에 계획서 PDF 를 **여러 장** 붙인다
--
-- 지금까지 자료는 brochure_url 한 칸뿐이었고, 그나마 담당자가 주소를 손으로
-- 붙여넣는 칸이었다. 실제로는 일정표·비용안내·신청서처럼 여러 장을 나눠
-- 주는 경우가 보통이라, 한 칸으로는 나머지를 어디에도 둘 수 없었다.
--
-- 배열이 아니라 JSONB 인 이유: 파일마다 **이름**이 있어야 한다.
-- /media/program/9f2c….pdf 만 나열하면 참가자는 어느 것이 일정표인지
-- 알 수 없다. 저장은 무작위 이름으로 하므로(media_store.js) 원본 이름은
-- 여기 적어 두는 수밖에 없다.
--
--   [{"url": "/media/program/<uuid>.pdf", "name": "일정표", "bytes": 91234}]
--
-- brochure_url 은 그대로 둔다. 이미 넣어 둔 링크가 있고, 유튜브나 구글
-- 드라이브처럼 우리가 받지 않는 주소를 붙여넣는 길도 남겨야 한다.
-- 파괴적 구문 금지 규칙에 따라 옮기거나 지우지 않는다.
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS plan_docs JSONB DEFAULT '[]'::jsonb;
