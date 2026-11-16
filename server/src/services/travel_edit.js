// 담당자가 한 사람의 비행 일정·전후 숙박을 고친다 — 순수 부분.
//
// 전화나 메신저로 "비행기가 바뀌었어요" 라고만 알려 오는 사람이 많다.
// 본인이 앱을 다시 열어 고치기를 기다리면 배차와 방이 옛 일정으로 잡힌다.
//
// **박수는 여기서도 비행 일정에서 낸다(060).** 담당자가 박수를 따로 적게
// 하면 등록 화면과 두 벌이 되고, 두 벌은 언젠가 갈라진다. 등록 라우트와
// 같은 함수(hotelNights · resolveHotelChoice · chargeableNights)를 쓴다.
//
// DB 도 HTTP 도 쓰지 않는다. test/travel_edit.test.js 로 그대로 확인한다.

import { hotelNights, chargeableNights } from './hotel_nights.js';
import { resolveHotelChoice, normalizeNights } from './hotel.js';

const has = (o, k) => !!o && Object.prototype.hasOwnProperty.call(o, k);

// 등록 화면(flight_info_step.dart)이 저장하는 칸들. 그 밖의 것은 받지 않는다.
const TEXT_KEYS = [
  'flight_no',
  'airline',
  'departure_airport',
  'arrival_airport',
  'terminal',
  'note',
];

/// 날짜·시각 문자열을 그대로 두되, 앞이 'YYYY-MM-DD' 가 아니면 버린다.
/// 시간대는 붙이지 않는다 — 항공편 시각은 **그 지역 시각**이다(hotel_nights.js).
function cleanWhen(v) {
  const s = typeof v === 'string' ? v.trim() : '';
  return /^\d{4}-\d{2}-\d{2}/.test(s) ? s.slice(0, 32) : null;
}

/// 본문에서 온 항공편 하나를 저장할 꼴로. null 이면 "항공편 없음" 이다.
///
/// 편명도 날짜도 없고 예매 전 표시도 없으면 적힌 것이 없는 것이다 —
/// 빈 객체를 남기면 명단에 빈 비행편 줄이 생긴다.
export function cleanFlight(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const out = {};
  for (const k of TEXT_KEYS) {
    const v = raw[k];
    out[k] = typeof v === 'string' ? v.trim().slice(0, 200) : '';
  }
  out.scheduled_arrival = cleanWhen(raw.scheduled_arrival);
  out.scheduled_departure = cleanWhen(raw.scheduled_departure);
  out.estimated = raw.estimated === true;
  if (raw.status != null) out.status = String(raw.status).slice(0, 40);

  const empty =
    !out.flight_no &&
    !out.scheduled_arrival &&
    !out.scheduled_departure &&
    !out.estimated;
  return empty ? null : out;
}

/**
 * 고친 뒤의 값을 낸다.
 *
 * existing: 지금 등록 행(arrival_flight, departure_flight, country,
 *           hotel_option_key, hotel_nights_before/after,
 *           hotel_before_self/after_self)
 * program:  start_date, end_date, hotel_options, host_country
 * tours:    신청한 투어 `{ end, includesLodging, estLodgingCost }`
 * body:     arrivalFlight · departureFlight · hotelOptionKey ·
 *           hotelBeforeSelf · hotelAfterSelf · hotelNightsBefore/After
 *
 * **본문에 없는 칸은 지금 값을 그대로 둔다.** 비행편만 고치러 들어온
 * 담당자가 숙박 등급을 날리면 안 된다.
 */
export function planTravelEdit({ existing, program, tours = [], body = {} }) {
  const arrival = has(body, 'arrivalFlight')
    ? cleanFlight(body.arrivalFlight)
    : (existing.arrival_flight ?? null);
  const departure = has(body, 'departureFlight')
    ? cleanFlight(body.departureFlight)
    : (existing.departure_flight ?? null);

  // 비행 일정이 있으면 박수는 거기서 나온다. 없으면(차로 오는 사람, 066)
  // 적힌 박수를 쓴다 — 담당자가 보냈으면 그것, 아니면 지금 값.
  const hasFlightDates = !!(
    arrival?.scheduled_arrival || departure?.scheduled_departure
  );
  let before;
  let after;
  if (hasFlightDates) {
    const s = hotelNights({
      start: program.start_date,
      end: program.end_date,
      arrival: arrival?.scheduled_arrival,
      departure: departure?.scheduled_departure,
      tours,
    });
    before = s.before;
    after = s.after;
  } else {
    before = normalizeNights(
      has(body, 'hotelNightsBefore')
        ? body.hotelNightsBefore
        : existing.hotel_nights_before,
    );
    after = normalizeNights(
      has(body, 'hotelNightsAfter')
        ? body.hotelNightsAfter
        : existing.hotel_nights_after,
    );
  }

  const beforeSelf = has(body, 'hotelBeforeSelf')
    ? body.hotelBeforeSelf === true
    : existing.hotel_before_self === true;
  const afterSelf = has(body, 'hotelAfterSelf')
    ? body.hotelAfterSelf === true
    : existing.hotel_after_self === true;

  // 등급은 그 수양회에 있는 것이어야 한다. 없는 것을 보내면 떨어뜨린다.
  const wanted = has(body, 'hotelOptionKey')
    ? body.hotelOptionKey
    : existing.hotel_option_key;
  const hotel = resolveHotelChoice({
    options: program.hotel_options,
    hostCountry: program.host_country,
    country: existing.country,
    optionKey: wanted,
    nightsBefore: before,
    nightsAfter: after,
  });

  // 남은 밤을 전부 스스로 해결하면 잡을 방이 없다 — 등록 라우트와 같은 규칙.
  const billed = chargeableNights({ before, after, beforeSelf, afterSelf });
  const hotelKey = (beforeSelf || afterSelf) && billed === 0 ? null : hotel.key;

  return {
    arrival,
    departure,
    nightsBefore: before,
    nightsAfter: after,
    beforeSelf,
    afterSelf,
    hotelKey,
    // 고른 등급을 못 쓰게 됐는지 — 담당자에게 알려야 한다. 조용히 지우면
    // "분명 골랐는데" 가 된다.
    hotelDropped: !!wanted && hotelKey === null && billed > 0,
  };
}
