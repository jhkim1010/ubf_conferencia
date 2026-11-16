// 담당자가 비행 일정·전후 숙박을 고친다
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { planTravelEdit, cleanFlight } from '../src/services/travel_edit.js';

// 수양회 1/21~1/24, 개최국 AR, 하룻밤 30.
const program = {
  start_date: '2027-01-21',
  end_date: '2027-01-24',
  host_country: 'AR',
  hotel_options: [{ key: 'std', label: 'Standard', pricePerNight: 30 }],
};

const existing = {
  country: 'KR',
  arrival_flight: { flight_no: 'KE1', scheduled_arrival: '2027-01-20T09:00:00.000' },
  departure_flight: { flight_no: 'KE2', scheduled_departure: '2027-01-24T22:00:00.000' },
  hotel_option_key: 'std',
  hotel_nights_before: 1,
  hotel_nights_after: 0,
  hotel_before_self: false,
  hotel_after_self: false,
};

test('도착을 앞당기면 박수가 비행 일정을 따라간다', () => {
  const p = planTravelEdit({
    existing,
    program,
    body: {
      arrivalFlight: { flight_no: 'KE9', scheduled_arrival: '2027-01-18T07:00:00.000' },
    },
  });
  assert.equal(p.nightsBefore, 3);
  assert.equal(p.nightsAfter, 0);
  assert.equal(p.arrival.flight_no, 'KE9');
  // 안 보낸 출발편과 등급은 그대로다.
  assert.equal(p.departure.flight_no, 'KE2');
  assert.equal(p.hotelKey, 'std');
});

test('숙박만 고쳐도 비행편은 그대로다', () => {
  const p = planTravelEdit({ existing, program, body: { hotelOptionKey: null } });
  assert.equal(p.hotelKey, null);
  assert.equal(p.arrival.flight_no, 'KE1');
  assert.equal(p.nightsBefore, 1);
  assert.equal(p.hotelDropped, false);
});

test('숙박이 든 투어의 끝날까지는 이미 묵는다', () => {
  const p = planTravelEdit({
    existing,
    program,
    tours: [{ end: '2027-01-27', includesLodging: true }],
    body: {
      departureFlight: { flight_no: 'KE2', scheduled_departure: '2027-01-29T10:00:00' },
    },
  });
  assert.equal(p.nightsAfter, 2);
});

test('앞뒤를 모두 스스로 해결하면 잡을 방이 없다', () => {
  const p = planTravelEdit({
    existing,
    program,
    body: { hotelBeforeSelf: true },
  });
  assert.equal(p.beforeSelf, true);
  assert.equal(p.hotelKey, null);
  // 박수는 남긴다 — 마중·배웅에 필요하다.
  assert.equal(p.nightsBefore, 1);
  assert.equal(p.hotelDropped, false);
});

test('없는 등급은 떨어뜨리고 그 사실을 알린다', () => {
  const p = planTravelEdit({ existing, program, body: { hotelOptionKey: 'vip' } });
  assert.equal(p.hotelKey, null);
  assert.equal(p.hotelDropped, true);
});

test('비행편을 지우면 적힌 박수를 쓴다(차로 오는 사람)', () => {
  const p = planTravelEdit({
    existing,
    program,
    body: {
      arrivalFlight: null,
      departureFlight: null,
      hotelNightsBefore: 2,
      hotelNightsAfter: 1,
    },
  });
  assert.equal(p.arrival, null);
  assert.equal(p.departure, null);
  assert.equal(p.nightsBefore, 2);
  assert.equal(p.nightsAfter, 1);
});

test('비행 일정이 있으면 적어 보낸 박수는 무시한다', () => {
  const p = planTravelEdit({
    existing,
    program,
    body: { hotelNightsBefore: 9 },
  });
  assert.equal(p.nightsBefore, 1);
});

test('항공편 정리: 모르는 칸은 버리고, 빈 것은 없음이다', () => {
  const f = cleanFlight({
    flight_no: ' KE1 ',
    scheduled_arrival: '2027-01-20T09:00',
    evil: 'x',
  });
  assert.equal(f.flight_no, 'KE1');
  assert.equal(f.scheduled_arrival, '2027-01-20T09:00');
  assert.equal(f.evil, undefined);
  assert.equal(cleanFlight({ flight_no: '', scheduled_arrival: 'tomorrow' }), null);
  assert.equal(cleanFlight('KE1'), null);
  // 예매 전(날짜만, 021)도 적힌 것이다.
  const est = cleanFlight({ estimated: true, scheduled_arrival: '2027-01-19' });
  assert.equal(est.estimated, true);
});
