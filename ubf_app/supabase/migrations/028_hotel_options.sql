-- 028: 수양회 전후 숙박(호텔) 등급
--
-- 멀리서 오는 사람은 수양회 며칠 전에 도착하고, 투어가 끝난 뒤에도 며칠 더
-- 머문다. 그 기간의 숙소는 수양회 숙소가 아니라 호텔이다. 주최 측이 등급을
-- 정해 두면 참가자가 고른다.
--
-- 등급 목록은 programs.discount_options 와 같은 모양의 JSONB 로 둔다.
-- 별도 테이블로 만들 만큼 딸린 것이 없고(정원·날짜·사진이 없다), 같은 모양이면
-- 서버의 정리 함수와 화면 편집기를 나란히 둘 수 있다.
--
--   [{ "key": "h1",
--      "label": "4성급",
--      "labels": { "ko": "4성급", "en": "4-star", "es": "4 estrellas" },
--      "pricePerNight": 80 }]
--
-- 금액 단위는 그 수양회의 통화(programs.currency)다. 항목마다 통화를 두면
-- 같은 화면에서 단위가 섞인다.
ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS hotel_options JSONB NOT NULL DEFAULT '[]'::jsonb;

-- 참가자의 선택. 등급 하나 + 수양회 전후 박수.
--
-- 박수를 받지 않으면 등급만 알고 방을 못 잡는다 — 호텔 예약은 날짜 단위다.
-- 전/후를 나눠 받는 이유도 같다. 합계만으로는 언제 자는지 알 수 없다.
ALTER TABLE registrations
  ADD COLUMN IF NOT EXISTS hotel_option_key TEXT,
  ADD COLUMN IF NOT EXISTS hotel_nights_before INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hotel_nights_after INTEGER NOT NULL DEFAULT 0;

-- 음수 박수는 뜻이 없다. 상한(60)은 오타 방지용이다 — "20" 을 "200" 으로
-- 잘못 적으면 예상 금액이 열 배로 나와 참가자가 등록을 포기한다.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'registrations_hotel_nights_range'
  ) THEN
    ALTER TABLE registrations
      ADD CONSTRAINT registrations_hotel_nights_range
      CHECK (hotel_nights_before BETWEEN 0 AND 60
         AND hotel_nights_after  BETWEEN 0 AND 60);
  END IF;
END $$;
