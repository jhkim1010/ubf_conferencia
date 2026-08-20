import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  hotelNights,
  hotelCost,
  nightsBetween,
  dayOf,
} from '../src/services/hotel_nights.js';

// 수양회 전후 호텔 박수 (060)
//
// 운영 자료 그대로 쓴다: 수양회 2027-01-21~01-24, 투어는 01-25~01-27,
// 호텔 1박 100.

const CONF = { start: '2027-01-21', end: '2027-01-24' };

test('날짜만 본다 — 시각은 셈에 넣지 않는다', () => {
  assert.equal(dayOf('2027-01-20T23:55:00.000'), '2027-01-20');
  assert.equal(dayOf('2027-01-20'), '2027-01-20');
  assert.equal(dayOf(''), null);
  assert.equal(dayOf(null), null);
});

test('밤 수 세기', () => {
  assert.equal(nightsBetween('2027-01-20', '2027-01-21'), 1);
  assert.equal(nightsBetween('2027-01-21', '2027-01-21'), 0);
  assert.equal(nightsBetween('2027-01-25', '2027-01-21'), -4);
});

test('첫날 와서 마지막날 가면 추가가 없다', () => {
  // 21일 도착, 24일 저녁 출발 — 수양회 안에서 다 잔다.
  const r = hotelNights({
    ...CONF,
    arrival: '2027-01-21T09:00:00.000',
    departure: '2027-01-24T20:00:00.000',
  });
  assert.deepEqual([r.before, r.after, r.nights], [0, 0, 0]);
});

test('일찍 오면 그만큼 앞에서 잔다', () => {
  const r = hotelNights({
    ...CONF,
    arrival: '2027-01-20T14:00:00.000',
    departure: '2027-01-24T20:00:00.000',
  });
  assert.deepEqual([r.before, r.after], [1, 0]);
});

test('늦게 가면 그만큼 뒤에서 잔다', () => {
  const r = hotelNights({
    ...CONF,
    arrival: '2027-01-21',
    departure: '2027-01-27',
  });
  assert.deepEqual([r.before, r.after, r.nights], [0, 3, 3]);
});

test('투어를 하면 그 끝날까지는 이미 잔다', () => {
  // 우수아이아 투어가 27일에 끝난다. 27일에 떠나면 추가가 없다.
  const r = hotelNights({
    ...CONF,
    arrival: '2027-01-21',
    departure: '2027-01-27',
    tours: [{ end: '2027-01-27', includesLodging: true }],
  });
  assert.equal(r.after, 0);
  assert.equal(r.stayEnd, '2027-01-27');
});

test('투어 뒤에도 남으면 그때부터 센다', () => {
  const r = hotelNights({
    ...CONF,
    arrival: '2027-01-20',
    departure: '2027-01-30',
    tours: [
      { end: '2027-01-26', includesLodging: true },
      { end: '2027-01-27', includesLodging: true },
    ],
  });
  // 하루 먼저 오고, 27일 투어 끝난 뒤 사흘 더.
  assert.deepEqual([r.before, r.after, r.nights], [1, 3, 4]);
});

test('늦게 오거나 일찍 가는 것은 추가가 아니다', () => {
  // 22일에 와서 23일에 가도 "마이너스 숙박" 은 없다.
  const r = hotelNights({
    ...CONF,
    arrival: '2027-01-22',
    departure: '2027-01-23',
  });
  assert.deepEqual([r.before, r.after], [0, 0]);
});

test('비행 일정이 없으면 0 이다', () => {
  const r = hotelNights({ ...CONF, arrival: null, departure: null });
  assert.deepEqual([r.before, r.after], [0, 0]);
});

test('이상한 날짜는 표시를 남긴다', () => {
  // 운영에 도착이 다섯 달 전인 줄이 실제로 있었다. 그대로 곱하면 한 사람
  // 앞으로 수천 달러가 붙는다. **조용히 자르지는 않는다** — 자르면 오래
  // 묵는 사람에게 덜 받는다.
  const r = hotelNights({
    ...CONF,
    arrival: '2026-08-02',
    departure: '2027-01-24',
  });
  assert.ok(r.before > 100);
  assert.equal(r.suspect, true);
});

test('평범한 길이는 표시하지 않는다', () => {
  const r = hotelNights({
    ...CONF,
    arrival: '2027-01-19',
    departure: '2027-01-26',
  });
  assert.equal(r.suspect, false);
});

test('숙박비는 박수 곱하기 1박 요금', () => {
  assert.equal(hotelCost(4, 100), 400);
  assert.equal(hotelCost(0, 100), 0);
  assert.equal(hotelCost(3, null), 0);
  assert.equal(hotelCost(2, 33.33), 66.66);
});

test('숙박이 안 든 투어는 그 기간도 호텔비를 센다', () => {
  // 당일치기 시내 투어는 그날 밤 잘 곳을 따로 잡아야 한다(060).
  const included = hotelNights({
    ...CONF,
    arrival: '2027-01-21',
    departure: '2027-01-27',
    tours: [{ end: '2027-01-27', includesLodging: true }],
  });
  const not = hotelNights({
    ...CONF,
    arrival: '2027-01-21',
    departure: '2027-01-27',
    tours: [{ end: '2027-01-27', includesLodging: false }],
  });
  assert.equal(included.after, 0, '숙박 포함인데 돈을 받는다');
  assert.equal(not.after, 3, '숙박이 안 드는데 안 받는다');
});

test('포함인 투어와 아닌 투어가 섞이면 포함인 쪽까지만 덮는다', () => {
  const r = hotelNights({
    ...CONF,
    arrival: '2027-01-21',
    departure: '2027-01-30',
    tours: [
      { end: '2027-01-27', includesLodging: false }, // 기간을 늘리지 않는다
      { end: '2027-01-26', includesLodging: true },
    ],
  });
  assert.equal(r.stayEnd, '2027-01-26');
  assert.equal(r.after, 4);
});

// ── 061: 투어 끝날과 두 번 셈 ────────────────────────────────────────

const R = { start: '2027-01-21', end: '2027-01-24' };

test('숙박 투어의 끝날 밤은 덮지 않는다 — 그날은 돌아오는 날이다', () => {
  const tour = { end: '2027-01-27', includesLodging: true };
  // 27일에 돌아와 그날 떠나면 더 잘 것이 없다
  assert.equal(
    hotelNights({ ...R, arrival: '2027-01-21', departure: '2027-01-27', tours: [tour] }).after,
    0,
  );
  // 27일에 돌아와 28일에 떠나면 27일 밤은 호텔에서 잔다
  assert.equal(
    hotelNights({ ...R, arrival: '2027-01-21', departure: '2027-01-28', tours: [tour] }).after,
    1,
  );
  // 30일에 떠나면 27·28·29 세 밤
  assert.equal(
    hotelNights({ ...R, arrival: '2027-01-21', departure: '2027-01-30', tours: [tour] }).after,
    3,
  );
});

test('숙박이 안 든 투어에 예상 금액이 적혀 있으면 그 기간을 또 세지 않는다', () => {
  // 적어 둔 금액을 따로 보여 주면서 같은 밤을 호텔 요금으로 또 세면
  // 참가자는 한 밤에 두 번 낸다.
  const paid = { end: '2027-01-27', includesLodging: false, estLodgingCost: 240 };
  assert.equal(
    hotelNights({ ...R, arrival: '2027-01-21', departure: '2027-01-27', tours: [paid] }).after,
    0,
  );
});

test('금액을 안 적었으면 예전대로 그 기간도 호텔비로 센다', () => {
  // 아무 값도 없으면 그것이 우리가 아는 전부다.
  const unknown = { end: '2027-01-27', includesLodging: false };
  assert.equal(
    hotelNights({ ...R, arrival: '2027-01-21', departure: '2027-01-27', tours: [unknown] }).after,
    3,
  );
});

test('예상 금액 0 도 적어 둔 것이다', () => {
  const free = { end: '2027-01-27', includesLodging: false, estLodgingCost: 0 };
  assert.equal(
    hotelNights({ ...R, arrival: '2027-01-21', departure: '2027-01-27', tours: [free] }).after,
    0,
  );
});
