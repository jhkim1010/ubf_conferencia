// 배차 엔진 테스트 — DB 비의존 순수 함수
// 실행: cd server && npm test
//
// 이 엔진이 틀리면 사람이 공항에 발이 묶인다. 정상 경로보다 경계 조건에 무게를 둔다.

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  autoDispatch,
  departureDeadline,
  isPickupExempt,
  planRuns,
} from '../src/services/dispatch_engine.js';

// 테스트 가독성을 위한 시각 헬퍼 (고정 기준 시각 + 분 단위 오프셋)
const T0 = Date.UTC(2026, 7, 1, 9, 0, 0);
const at = (min) => T0 + min * 60 * 1000;

// personId → runId 매핑으로 변환 (단언을 읽기 쉽게)
const byPerson = (assignments) =>
  Object.fromEntries(assignments.map((a) => [a.personId, a.runId]));

const reasons = (unassigned) =>
  Object.fromEntries(unassigned.map((u) => [u.personId, u.reason]));

describe('autoDispatch', () => {
  test('같은 공항 승객을 정원까지 채운다', () => {
    const { assignments, unassigned } = autoDispatch({
      runs: [{ id: 'v1', airport: 'ICN', capacity: 3 }],
      people: [
        { id: 'p1', airport: 'ICN', timeAt: at(0) },
        { id: 'p2', airport: 'ICN', timeAt: at(10) },
        { id: 'p3', airport: 'ICN', timeAt: at(20) },
      ],
    });
    assert.equal(assignments.length, 3);
    assert.deepEqual(byPerson(assignments), { p1: 'v1', p2: 'v1', p3: 'v1' });
    assert.deepEqual(unassigned, []);
  });

  test('정원을 넘으면 no_van 으로 남긴다', () => {
    const { assignments, unassigned } = autoDispatch({
      runs: [{ id: 'v1', airport: 'ICN', capacity: 2 }],
      people: [
        { id: 'p1', airport: 'ICN', timeAt: at(0) },
        { id: 'p2', airport: 'ICN', timeAt: at(5) },
        { id: 'p3', airport: 'ICN', timeAt: at(10) },
      ],
    });
    assert.equal(assignments.length, 2);
    assert.deepEqual(reasons(unassigned), { p3: 'no_van' });
  });

  test('공항이 다르면 서로의 밴에 배정되지 않는다', () => {
    const { assignments, unassigned } = autoDispatch({
      runs: [
        { id: 'icn', airport: 'ICN', capacity: 5 },
        { id: 'gmp', airport: 'GMP', capacity: 5 },
      ],
      people: [
        { id: 'a', airport: 'ICN', timeAt: at(0) },
        { id: 'b', airport: 'GMP', timeAt: at(0) },
      ],
    });
    assert.deepEqual(byPerson(assignments), { a: 'icn', b: 'gmp' });
    assert.deepEqual(unassigned, []);
  });

  test('밴이 없는 공항의 승객은 no_van 이 된다', () => {
    const { assignments, unassigned } = autoDispatch({
      runs: [{ id: 'icn', airport: 'ICN', capacity: 5 }],
      people: [{ id: 'x', airport: 'PUS', timeAt: at(0) }],
    });
    assert.deepEqual(assignments, []);
    assert.deepEqual(reasons(unassigned), { x: 'no_van' });
  });

  test('시간창(windowMin)을 벗어난 승객은 다른 밴으로 간다', () => {
    // v1 의 anchor 는 p1 의 시각. p2 는 120분 뒤라 기본 창(90분) 밖 → v2 로.
    const { assignments } = autoDispatch({
      runs: [
        { id: 'v1', airport: 'ICN', capacity: 4 },
        { id: 'v2', airport: 'ICN', capacity: 4 },
      ],
      people: [
        { id: 'p1', airport: 'ICN', timeAt: at(0) },
        { id: 'p2', airport: 'ICN', timeAt: at(120) },
      ],
    });
    const m = byPerson(assignments);
    assert.equal(m.p1, 'v1');
    assert.notEqual(m.p2, m.p1, '시간창 밖 승객은 같은 밴에 묶이면 안 된다');
  });

  test('시간창 경계값은 포함이다 (<= windowMs)', () => {
    const { assignments } = autoDispatch({
      runs: [
        { id: 'v1', airport: 'ICN', capacity: 4 },
        { id: 'v2', airport: 'ICN', capacity: 4 },
      ],
      people: [
        { id: 'p1', airport: 'ICN', timeAt: at(0) },
        { id: 'p2', airport: 'ICN', timeAt: at(90) }, // 정확히 90분
      ],
      windowMin: 90,
    });
    assert.equal(byPerson(assignments).p2, 'v1', '경계값은 같은 밴에 포함되어야 한다');
  });

  test('시간창 밖이고 여분 밴도 없으면 no_van', () => {
    const { assignments, unassigned } = autoDispatch({
      runs: [{ id: 'v1', airport: 'ICN', capacity: 4 }],
      people: [
        { id: 'p1', airport: 'ICN', timeAt: at(0) },
        { id: 'p2', airport: 'ICN', timeAt: at(200) },
      ],
    });
    assert.deepEqual(byPerson(assignments), { p1: 'v1' });
    assert.deepEqual(reasons(unassigned), { p2: 'no_van' });
  });

  test('needsPickup === false 는 배차 대상도 미배차 목록도 아니다', () => {
    const { assignments, unassigned } = autoDispatch({
      runs: [{ id: 'v1', airport: 'ICN', capacity: 5 }],
      people: [
        { id: 'self', airport: 'ICN', timeAt: at(0), needsPickup: false },
        { id: 'p1', airport: 'ICN', timeAt: at(5), needsPickup: true },
      ],
    });
    assert.deepEqual(byPerson(assignments), { p1: 'v1' });
    assert.deepEqual(unassigned, [], '자차 이용자는 미배차로도 보고되지 않아야 한다');
  });

  test('needsPickup 이 미지정이면 픽업 대상으로 본다', () => {
    const { assignments } = autoDispatch({
      runs: [{ id: 'v1', airport: 'ICN', capacity: 5 }],
      people: [{ id: 'p1', airport: 'ICN', timeAt: at(0) }],
    });
    assert.equal(assignments.length, 1);
  });

  test('시각 미상은 no_time 으로 분류된다', () => {
    const { assignments, unassigned } = autoDispatch({
      runs: [{ id: 'v1', airport: 'ICN', capacity: 5 }],
      people: [
        { id: 'nan', airport: 'ICN', timeAt: NaN },
        { id: 'missing', airport: 'ICN' },
        { id: 'ok', airport: 'ICN', timeAt: at(0) },
      ],
    });
    assert.deepEqual(byPerson(assignments), { ok: 'v1' });
    assert.deepEqual(reasons(unassigned), { nan: 'no_time', missing: 'no_time' });
  });

  test('시각이 뒤섞여 들어와도 이른 시각부터 배차한다', () => {
    const { assignments, unassigned } = autoDispatch({
      runs: [{ id: 'v1', airport: 'ICN', capacity: 2 }],
      people: [
        { id: 'late', airport: 'ICN', timeAt: at(300) },
        { id: 'early', airport: 'ICN', timeAt: at(0) },
        { id: 'mid', airport: 'ICN', timeAt: at(30) },
      ],
    });
    // early(anchor) + mid 가 타고, late 는 시간창 밖 + 정원 소진
    assert.deepEqual(byPerson(assignments), { early: 'v1', mid: 'v1' });
    assert.deepEqual(reasons(unassigned), { late: 'no_van' });
  });

  test('정원이 큰 밴부터 채운다', () => {
    const { assignments } = autoDispatch({
      runs: [
        { id: 'small', airport: 'ICN', capacity: 1 },
        { id: 'big', airport: 'ICN', capacity: 5 },
      ],
      people: [{ id: 'p1', airport: 'ICN', timeAt: at(0) }],
    });
    assert.equal(byPerson(assignments).p1, 'big');
  });

  test('빈 입력에서 안전하게 동작한다', () => {
    assert.deepEqual(autoDispatch({ runs: [], people: [] }), {
      assignments: [],
      unassigned: [],
    });
  });

  test('승객이 없으면 배차도 없다', () => {
    const r = autoDispatch({ runs: [{ id: 'v1', airport: 'ICN', capacity: 3 }], people: [] });
    assert.deepEqual(r.assignments, []);
  });
});

describe('departureDeadline', () => {
  test('기본 여유 210분을 역산한다', () => {
    const depart = at(600);
    assert.equal(departureDeadline(depart), depart - 210 * 60 * 1000);
  });

  test('여유 시간을 지정할 수 있다', () => {
    const depart = at(600);
    assert.equal(departureDeadline(depart, 60), depart - 60 * 60 * 1000);
  });

  test('숫자가 아니면 NaN 을 반환한다', () => {
    assert.ok(Number.isNaN(departureDeadline(NaN)));
    assert.ok(Number.isNaN(departureDeadline(undefined)));
    assert.ok(Number.isNaN(departureDeadline(null)));
    assert.ok(Number.isNaN(departureDeadline('2026-08-01')));
  });

  test('데드라인은 출발 시각보다 항상 이르다', () => {
    const depart = at(600);
    assert.ok(departureDeadline(depart) < depart);
  });
});

describe('isPickupExempt — 국제 수양회 개최국 참가자', () => {
  const intl = { programType: 'international', hostCountry: 'AR' };

  test('개최국 참가자는 항공편이 없으면 명단에서 빠진다', () => {
    assert.equal(isPickupExempt({ ...intl, country: 'AR', hasFlight: false }), true);
  });

  test('항공편을 적어 냈으면 개최국 참가자라도 남는다', () => {
    // 국토가 넓은 나라의 국내선. 빼면 아무도 공항에 나가지 않는다.
    assert.equal(isPickupExempt({ ...intl, country: 'AR', hasFlight: true }), false);
  });

  test('해외 참가자는 항공편이 없어도 남는다', () => {
    // 아직 항공편을 못 적었을 뿐이다. 미배차로 보여야 담당자가 챙긴다.
    assert.equal(isPickupExempt({ ...intl, country: 'KR', hasFlight: false }), false);
  });

  test('지역 수양회에는 적용하지 않는다', () => {
    // 참가자가 모두 같은 나라 사람이라 적용하면 명단이 통째로 비어 버린다.
    assert.equal(
      isPickupExempt({ programType: 'local', hostCountry: 'AR', country: 'AR', hasFlight: false }),
      false,
    );
  });

  test('개최국이 정해지지 않았으면 아무도 빼지 않는다', () => {
    assert.equal(
      isPickupExempt({ programType: 'international', hostCountry: null, country: 'AR', hasFlight: false }),
      false,
    );
  });

  test('참가자 국가를 모르면 빼지 않는다', () => {
    // 잘못 빼는 쪽이 잘못 남기는 쪽보다 나쁘다.
    for (const country of [null, undefined, '']) {
      assert.equal(isPickupExempt({ ...intl, country, hasFlight: false }), false);
    }
  });

  test('태워 달라고 적어 냈으면 빼지 않는다', () => {
    // 개최국 사람도 버스터미널·지부 앞에서 태워야 할 수 있다(035).
    // 예전에는 물어본 적이 없어서 그 사실이 어디에도 남지 않았다.
    assert.equal(
      isPickupExempt({ ...intl, country: 'AR', hasFlight: false, pickupFrom: 'Retiro 터미널' }),
      false,
    );
  });

  test('빈 문자열이나 공백만 적었으면 적지 않은 것이다', () => {
    for (const v of ['', '   ', null, undefined]) {
      assert.equal(
        isPickupExempt({ ...intl, country: 'AR', hasFlight: false, pickupFrom: v }),
        true,
        String(v),
      );
    }
  });

  test('다른 나라 사람은 이름이 비슷해도 빼지 않는다', () => {
    assert.equal(isPickupExempt({ ...intl, country: 'AU', hasFlight: false }), false);
  });
});

// ── 필요한 차량 세기 (배차 준비) ─────────────────────────────────

// 기존 테스트에 이미 at 이 있어 이름을 달리한다.
const planAt = (h, m = 0) => Date.UTC(2027, 0, 24, h, m);

test('같은 공항에서 가까운 시각끼리 한 묶음', () => {
  const people = [
    { id: 'a', airport: 'EZE', timeAt: planAt(6, 10) },
    { id: 'b', airport: 'EZE', timeAt: planAt(7, 20) },
    { id: 'c', airport: 'EZE', timeAt: planAt(14, 20) },
  ];
  const buckets = planRuns({ runs: [], people, windowMin: 90, vanSeats: 7 });
  assert.equal(buckets.length, 2);
  assert.deepEqual(buckets[0].personIds, ['a', 'b']);
  assert.deepEqual(buckets[1].personIds, ['c']);
});

test('공항이 다르면 시각이 겹쳐도 안 묶는다', () => {
  const people = [
    { id: 'a', airport: 'EZE', timeAt: planAt(9) },
    { id: 'b', airport: 'AEP', timeAt: planAt(9) },
  ];
  const buckets = planRuns({ runs: [], people });
  assert.equal(buckets.length, 2);
});

test('필요한 대수를 센다', () => {
  // 11명, 밴 7인 → 2대.
  const people = Array.from({ length: 11 }, (_, i) => ({
    id: `p${i}`, airport: 'EZE', timeAt: planAt(6) + i * 60000,
  }));
  const [b] = planRuns({ runs: [], people, vanSeats: 7 });
  assert.equal(b.seatsNeeded, 11);
  assert.equal(b.seatsHave, 0);
  assert.equal(b.vansToAdd, 2);
});

test('이미 만든 밴만큼 뺀다', () => {
  const people = Array.from({ length: 11 }, (_, i) => ({
    id: `p${i}`, airport: 'EZE', timeAt: planAt(6) + i * 60000,
  }));
  const [b] = planRuns({
    runs: [{ id: 'r1', airport: 'EZE', capacity: 7 }], people, vanSeats: 7,
  });
  assert.equal(b.seatsHave, 7);
  assert.equal(b.vansToAdd, 1);
  assert.deepEqual(b.runIds, ['r1']);
});

test('자리가 충분하면 더 만들 것이 없다', () => {
  const people = [
    { id: 'a', airport: 'EZE', timeAt: planAt(6) },
    { id: 'b', airport: 'EZE', timeAt: planAt(6, 30) },
  ];
  const [b] = planRuns({
    runs: [{ id: 'r1', airport: 'EZE', capacity: 7 }], people, vanSeats: 7,
  });
  assert.equal(b.vansToAdd, 0);
});

test('자차·시각 미상은 세지 않는다', () => {
  // 태워 달라고 하지 않은 사람 때문에 차를 더 부르면 안 된다.
  const people = [
    { id: 'a', airport: 'EZE', timeAt: planAt(6) },
    { id: 'b', airport: 'EZE', timeAt: planAt(6, 10), needsPickup: false },
    { id: 'c', airport: 'EZE', timeAt: null },
  ];
  const [b] = planRuns({ runs: [], people, vanSeats: 7 });
  assert.deepEqual(b.personIds, ['a']);
});

test('밴이 남으면 마지막 묶음에 붙는다', () => {
  // 어디에도 안 붙으면 화면에서 그 밴이 사라진다.
  const people = [{ id: 'a', airport: 'EZE', timeAt: planAt(6) }];
  const [b] = planRuns({
    runs: [
      { id: 'r1', airport: 'EZE', capacity: 7 },
      { id: 'r2', airport: 'EZE', capacity: 4 },
    ],
    people,
  });
  assert.deepEqual(b.runIds, ['r1', 'r2']);
  assert.equal(b.seatsHave, 11);
});

test('자동 배차가 실제로 채우는 대수와 어긋나지 않는다', () => {
  // 여기서 센 대수만큼 밴을 만들면 자동 배차에 미배차가 남지 않아야 한다.
  const people = Array.from({ length: 11 }, (_, i) => ({
    id: `p${i}`, airport: 'EZE', timeAt: planAt(6) + i * 5 * 60000,
  }));
  const [plan] = planRuns({ runs: [], people, windowMin: 90, vanSeats: 7 });
  const runs = Array.from({ length: plan.vansToAdd }, (_, i) => ({
    id: `r${i}`, airport: 'EZE', capacity: 7,
  }));
  const { unassigned } = autoDispatch({ runs, people, windowMin: 90 });
  assert.deepEqual(unassigned, []);
});

test('시각 순으로 나온다', () => {
  const people = [
    { id: 'late', airport: 'EZE', timeAt: planAt(20) },
    { id: 'early', airport: 'AEP', timeAt: planAt(6) },
  ];
  const buckets = planRuns({ runs: [], people });
  assert.deepEqual(buckets.map((b) => b.personIds[0]), ['early', 'late']);
});
