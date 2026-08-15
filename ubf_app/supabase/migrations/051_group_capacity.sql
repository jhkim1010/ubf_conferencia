-- 051: 말씀조에도 정원
--
-- 방에는 정원이 있는데(010) 조에는 없었다. 그래서 편성 준비에서 조를 봐도
-- "몇 명까지 받을 셈인가" 가 화면 어디에도 없고, 자동 배정은 사람을 조 수로
-- 나눠 고르게만 담았다. 여덟 명이 앉을 방에 열두 명이 배정되는 일이 그래서
-- 생긴다.
--
-- **비워 두는 것도 뜻이 있다** — "정하지 않음". 지금까지 만든 조가 전부
-- 그 상태이며, 그때는 예전처럼 고르게 나눈다.
ALTER TABLE groups
  ADD COLUMN IF NOT EXISTS capacity INTEGER;

COMMENT ON COLUMN groups.capacity IS
  '조 정원. NULL 이면 정하지 않음 — 자동 배정이 고르게 나눈다.';

-- 0 이나 음수는 아무도 못 들어가는 조가 된다. 화면에서 지우면 NULL 로
-- 오므로, 0 을 막아도 "정하지 않음" 은 그대로 쓸 수 있다.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'groups_capacity_positive'
  ) THEN
    ALTER TABLE groups
      ADD CONSTRAINT groups_capacity_positive
      CHECK (capacity IS NULL OR capacity > 0);
  END IF;
END $$;
