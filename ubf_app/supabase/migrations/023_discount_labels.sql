-- 023: 할인 항목 문구를 3개 언어로
--
-- 할인 항목 문구는 관리자가 직접 쓴다(행사마다 일정이 달라 ARB 로 번역할 수
-- 없다). 그런데 한 줄만 받으니 "1일만 참석"이라고 적으면 스페인어 사용자는
-- 읽지 못한 채 고르게 된다. 돈이 걸린 선택지라 더 나쁘다.
--
-- 이제 ko/en/es 를 각각 받는다. 비워 두면 기본 문구(label)로 대체한다 —
-- 세 칸을 모두 채우도록 강제하면 한 언어만 쓰는 지부가 항목을 못 만든다.
--
-- 저장 위치:
--   programs.discount_options[].labels = {"ko":…,"en":…,"es":…}
--     JSONB 안이라 스키마 변경이 필요 없다. 기존 항목은 labels 가 없고
--     label 만 있으며, 앱이 label 로 대체한다.
--   registrations.discount_option_labels
--     등록 시점의 문구를 언어별로 그대로 보관한다. 담당자가 자기 언어로 보고,
--     관리자가 나중에 항목을 고쳐도 "무엇을 보고 신청했는지"가 남는다.
--     기존 discount_option_label(TEXT)은 그대로 둔다 — 목록·CSV 가 쓴다.
--
-- 주의: migrate.js 는 이력을 추적하지 않고 매 실행마다 전체를 재적용한다.
-- 모든 구문이 멱등이어야 한다.

ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS discount_option_labels JSONB;
