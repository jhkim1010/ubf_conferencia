import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  normalizeTourFlights,
  tourMovements,
  cleanTime,
} from '../src/services/tour_flights.js';

const IGU = '11111111-1111-1111-1111-111111111111';
const CITY = '22222222-2222-2222-2222-222222222222';

test('정리: 빈 구간·모르는 값은 버리고 날짜순으로 둔다', () => {
  const out = normalizeTourFlights(
    [
      { kind: 'tour_return', tour_id: IGU, date: '2027-01-09', flight_no: ' ar1735 ', time: '19:10' },
      { kind: 'tour_out', tour_id: IGU, date: '2027-01-07', flight_no: 'AR1730', time: '8:10' },
      { kind: 'tour_out' }, // 아무것도 안 적음
      'junk',
    ],
    { tourIds: [IGU] },
  );
  assert.equal(out.length, 2);
  assert.equal(out[0].kind, 'tour_out');
  assert.equal(out[0].time, '08:10');
  assert.equal(out[1].flight_no, 'AR1735');
});

test('정리: 투어가 하나면 어느 투어인지 채우고, 안 고른 투어는 떼어 낸다', () => {
  const one = normalizeTourFlights(
    [{ kind: 'tour_out', date: '2027-01-07' }],
    { tourIds: [IGU] },
  );
  assert.equal(one[0].tour_id, IGU);

  const two = normalizeTourFlights(
    [{ kind: 'tour_out', tour_id: 'not-mine', date: '2027-01-07' }],
    { tourIds: [IGU, CITY] },
  );
  assert.equal(two[0].tour_id, null);
});

test('정리: 투어를 안 고른 사람의 투어 구간은 남기지 않는다(기타는 남는다)', () => {
  const out = normalizeTourFlights(
    [
      { kind: 'tour_out', date: '2027-01-07' },
      { kind: 'other', date: '2027-01-08', from: 'EZE' },
    ],
    { tourIds: [] },
  );
  assert.deepEqual(out.map((l) => l.kind), ['other']);
});

test('정리: 바로 집에 가면 돌아오는 편은 없다', () => {
  const out = normalizeTourFlights(
    [
      { kind: 'tour_out', date: '2027-01-07' },
      { kind: 'tour_return', date: '2027-01-09' },
    ],
    { tourIds: [IGU], homeFromTour: true },
  );
  assert.deepEqual(out.map((l) => l.kind), ['tour_out']);
});

test('정리: 예매 전이면 편명·시각을 두지 않는다', () => {
  const [leg] = normalizeTourFlights(
    [{ kind: 'tour_return', date: '2027-01-09', flight_no: 'AR1', time: '10:00', estimated: true }],
    { tourIds: [IGU] },
  );
  assert.equal(leg.flight_no, '');
  assert.equal(leg.time, null);
  assert.equal(leg.estimated, true);
});

test('시각: 이상한 값은 null', () => {
  assert.equal(cleanTime('25:00'), null);
  assert.equal(cleanTime('abc'), null);
  assert.equal(cleanTime('7:05'), '07:05');
});

test('묶음: 같은 날 같은 편끼리, 동반자는 같은 편이라고 한 구간에서만 센다', () => {
  const out = tourMovements([
    {
      registration_id: 'a', name: 'A',
      tour_flights: [{ kind: 'tour_out', tour_id: IGU, date: '2027-01-07', flight_no: 'AR1730', time: '08:10', with_companions: true }],
      companions: [{ tour_ids: [IGU] }, { tour_ids: [] }],
    },
    {
      registration_id: 'b', name: 'B',
      tour_flights: [
        { kind: 'tour_out', tour_id: IGU, date: '2027-01-07', flight_no: 'AR1730' },
        { kind: 'tour_return', tour_id: IGU, date: '2027-01-09', estimated: true, flight_no: '' },
      ],
      companions: [{ tour_ids: [IGU] }],
    },
  ]);
  assert.equal(out.travelers, 2);
  assert.equal(out.groups.length, 2);
  const [outbound, back] = out.groups;
  assert.equal(outbound.kind, 'tour_out');
  // A 와 그 투어에 가는 동반자 하나, 그리고 B(동반자는 같은 편이라 안 했다)
  assert.equal(outbound.heads, 3);
  assert.equal(outbound.time, '08:10');
  assert.equal(back.estimated, true);
  // A 는 가는 편만 있고 돌아오는 편이 없다
  assert.deepEqual(out.missing.return.map((p) => p.name), ['A']);
});

test('빈 곳: 버스로 가는 투어(가는 편이 없음)는 세지 않고, 바로 귀국인데 집 편이 없으면 센다', () => {
  const out = tourMovements([
    { registration_id: 'bus', name: 'Bus', tour_flights: [] },
    {
      registration_id: 'd', name: 'D', home_from_tour: true,
      tour_flights: [{ kind: 'tour_out', date: '2027-01-07', flight_no: 'X1' }],
      departure_flight: null,
    },
    {
      registration_id: 'e', name: 'E', home_from_tour: true,
      tour_flights: [],
      departure_flight: { scheduled_departure: '2027-01-09T13:00:00', departure_airport: 'IGR' },
    },
  ]);
  assert.deepEqual(out.missing.return, []);
  assert.deepEqual(out.missing.home.map((p) => p.name), ['D']);
  const igr = out.direct.find((d) => d.airport === 'IGR');
  assert.equal(igr.date, '2027-01-09');
  assert.equal(igr.heads, 1);
});
