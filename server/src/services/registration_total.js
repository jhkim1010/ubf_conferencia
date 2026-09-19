// 이 사람이 우리에게 낼 돈 (064)
//
// 라우트 안에 흩어져 있던 셈을 여기로 꺼냈다. 돈이고, 관리자 명단과 CSV 가
// 이 숫자를 그대로 쓴다. 인라인으로 두면 고칠 때마다 손으로 확인해야 한다.
//
// **전후 숙박비도 여기 들어간다.** 주최가 방을 잡고 받아서 호텔에 내므로
// 참가자가 호텔에 직접 내는 돈이 아니다. 투어 값에 안 들어 있는 밥값·항공권
// (061·062)은 **안 들어간다** — 그쪽은 참가자가 따로 쓰는 돈이고 예상이다.
//
// 합계는 **서버가 계산한다.** 클라이언트가 보낸 값은 쓰지 않는다. 예전에 앱이
// 보내던 값은 투어 옵션만 더하고 참가비 등급을 빼먹어서, 요약 화면은 U$320
// 인데 DB 에는 0 이 저장됐다.
//
// DB 도 HTTP 도 쓰지 않는다. test/registration_total.test.js 로 그대로 확인한다.

import { hotelCost } from './hotel_nights.js';

function money(v) {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 ? n : 0;
}

/// 고른 등급으로 그 밤들에 드는 돈.
///
/// 등급을 안 골랐거나 없는 등급을 가리키면 0 이다 — 단가를 알 수 없으니
/// 셀 수가 없다. 이때 화면은 "등급을 고르면 더해집니다" 라고 말해야 한다.
/// 0 이라고만 해 두면 숙박이 공짜라는 뜻이 된다.
export function hotelCostOf({ options, key, nights, people = 1 }) {
  if (!key || !Array.isArray(options)) return 0;
  const picked = options.find((o) => o && o.key === key);
  // 단가는 한 사람 한 밤 값이다. **침대를 쓰는 동반자만큼 인원이 는다**(069) —
  // 보호자와 같이 자는 아기는 안 센다. 못 읽으면 한 사람으로 둔다.
  const n = Number(people);
  const heads = Number.isFinite(n) && n >= 1 ? Math.trunc(n) : 1;
  // 셈 자체는 060 의 hotelCost 가 한다. 두 벌로 두면 반올림이 갈린다.
  return hotelCost(nights, picked?.pricePerNight) * heads;
}

/// **등급을 안 고른 사람도 기본 참가비를 낸다.** 예전에는 0 으로 두어,
/// 등급 화면을 지나치기만 한 사람의 낼 돈이 0 이 됐다 — 운영 명단 열둘 중
/// 여섯이 그랬다. 참가비를 안 내는 참가자는 없다.
export function tierFeeOf({ tier, feeBasic, feePremium }) {
  return tier === 'premium' ? money(feePremium) : money(feeBasic);
}

/// 낼 돈 전체. 0 아래로는 안 내려간다.
///
/// 승인된 할인만 뺀다. 신청 중인 금액을 미리 빼면 아직 결정되지 않은 감액이
/// 확정된 것처럼 장부에 남는다 — 그 판단은 담당자 몫이다.
export function registrationTotal({
  tier,
  feeBasic,
  feePremium,
  optionsCost = 0,
  hotelOptions,
  hotelKey,
  hotelNights = 0,
  hotelPeople = 1,
  approvedDiscount = 0,
}) {
  const tierFee = tierFeeOf({ tier, feeBasic, feePremium });
  const hotelCost = hotelCostOf({
    options: hotelOptions,
    key: hotelKey,
    nights: hotelNights,
    people: hotelPeople,
  });
  const total = Math.max(
    0,
    tierFee + money(optionsCost) + hotelCost - money(approvedDiscount),
  );
  return {
    tierFee,
    hotelCost,
    total: Math.round(total * 100) / 100,
  };
}
