-- 060: 투어가 숙박을 포함하는지
--
-- 수양회 전후 호텔비는 비행 일정에서 자동으로 낸다. 그런데 투어 기간의
-- 잠자리는 투어마다 다르다 — 우수아이아처럼 사흘 가는 투어는 값에 숙박이
-- 들어 있고, 당일치기 시내 투어는 그날 밤 잘 곳을 따로 잡아야 한다.
--
-- **기본은 "포함" 이다.** 여러 날 가는 투어는 대개 숙박이 들어 있고, 잘못
-- 잡았을 때 덜 받는 쪽이 더 받는 쪽보다 낫다 — 더 받으면 참가자가 항의하고
-- 그 한 번이 신뢰를 깎는다. 덜 받은 것은 담당자가 명단에서 보고 고칠 수 있다.
ALTER TABLE program_options
  ADD COLUMN IF NOT EXISTS includes_lodging BOOLEAN NOT NULL DEFAULT true;

COMMENT ON COLUMN program_options.includes_lodging IS
  'true 면 투어 기간의 잠자리가 투어 값에 들어 있다. false 면 그 기간도 호텔비를 따로 센다(060)';
