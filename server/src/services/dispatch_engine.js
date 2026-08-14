// 배차 엔진 (순수 함수 — DB 비의존, 테스트 용이)
// PRD F5: 기사 명부(runs)에 승객을 채운다. 밴을 새로 만들지 않음.
// 매칭 원칙: 같은 공항 → 도착 시각순 → 대기 허용폭(windowMin) 안에서 → 밴 정원까지.

// ── 픽업 대상 제외 판정 ──────────────────────────────────────
// 국제 수양회의 **개최국 참가자는 공항 픽업 명단에 넣지 않는다.** 현지에서
// 오가므로 마중 나갈 일이 없는데, 항공편이 없다는 이유로 미배차 칸에 계속
// 쌓여 정작 마중이 필요한 사람이 묻힌다.
//
// 지역 수양회(local)에는 적용하지 않는다. 참가자가 모두 같은 나라 사람이라
// 적용하면 명단이 통째로 비어 버린다.
//
// 다만 국토가 넓은 나라에서는 개최국 사람도 국내선을 타고 온다. 등록 화면이
// 그런 사람을 위해 항공편 스텝을 되살릴 수 있게 해 두었으므로
// (registration_flow_screen.dart 의 _domesticWantsFlight),
// **항공편을 실제로 적어 낸 사람은 명단에 남긴다.** 그러지 않으면 비행기로
// 오는 사람이 조용히 사라져 아무도 공항에 나가지 않는다.
//
// **태워 달라고 적어 낸 사람은 빼지 않는다**(035). 개최국 사람도 버스터미널·
// 지부 앞에서 태워야 할 수 있다. 예전에는 물어본 적이 없어서 그 사실이 어디에도
// 남지 않았고, 항공편이 없다는 이유만으로 전부 명단에서 빠졌다.
//
// country 를 모르면 제외하지 않는다 — 잘못 빼는 쪽이 잘못 남기는 쪽보다 나쁘다.
export function isPickupExempt({
  programType,
  hostCountry,
  country,
  hasFlight,
  pickupFrom,
}) {
  if (typeof pickupFrom === 'string' && pickupFrom.trim() !== '') return false;
  if (programType !== 'international') return false;
  if (!hostCountry || !country || country !== hostCountry) return false;
  return !hasFlight;
}

// ── 자동 배차 ────────────────────────────────────────────────
// runs:   [{ id, airport, capacity }]              (관리자가 등록한 명부 = 공급)
// people: [{ id, airport, timeAt, needsPickup }]   (timeAt: 정렬 가능한 숫자 — 도착 or 데드라인 epoch ms)
//   - direction='arrival'   → timeAt = 도착 시각
//   - direction='departure' → timeAt = 공항 도착 데드라인(비행 시각 − 여유)  ※ 호출부에서 계산
// windowMin: 한 밴에 함께 묶을 시각 허용폭(분)
// 반환: { assignments: [{ runId, personId }], unassigned: [{ personId, reason }] }
export function autoDispatch({ runs, people, windowMin = 90 }) {
  const assignments = [];
  const unassigned = [];
  const windowMs = windowMin * 60 * 1000;

  // 픽업 대상만 (자차·시각미상 제외)
  const pickupPeople = people.filter(
    (p) => p.needsPickup !== false && typeof p.timeAt === 'number' && !Number.isNaN(p.timeAt),
  );
  // 시각 미상은 자동 배차 불가 → 미배차로
  for (const p of people) {
    if (p.needsPickup === false) continue;
    if (typeof p.timeAt !== 'number' || Number.isNaN(p.timeAt)) {
      unassigned.push({ personId: p.id, reason: 'no_time' });
    }
  }

  // 공항별 처리
  const airports = [...new Set(pickupPeople.map((p) => p.airport))];
  for (const airport of airports) {
    // 이 공항 승객: 시각 오름차순
    const queue = pickupPeople
      .filter((p) => p.airport === airport)
      .sort((a, b) => a.timeAt - b.timeAt);

    // 이 공항 명부(밴): 남은 정원 추적. 정원 큰 밴 먼저 채워 잔여 분산 최소화.
    const vans = runs
      .filter((r) => r.airport === airport)
      .map((r) => ({ id: r.id, remaining: r.capacity, anchor: null }))
      .sort((a, b) => b.remaining - a.remaining);

    for (const person of queue) {
      // 후보 밴: 정원 남고, (아직 승객 없거나 anchor로부터 windowMs 이내)
      const van = vans.find(
        (v) => v.remaining > 0 && (v.anchor === null || person.timeAt - v.anchor <= windowMs),
      );
      if (!van) {
        // 이 공항에 남은 자리가 없거나 시간창을 크게 벗어남 → 리더 판단
        unassigned.push({ personId: person.id, reason: 'no_van' });
        continue;
      }
      if (van.anchor === null) van.anchor = person.timeAt; // 첫 승객이 시간창 기준
      van.remaining -= 1;
      assignments.push({ runId: van.id, personId: person.id });
    }
  }

  return { assignments, unassigned };
}

// ── 출발 드롭 데드라인 계산 ──────────────────────────────────
// 비행 출발 시각(ms)에서 공항 도착 여유(bufferMin, 기본 3.5h)를 역산.
// 놓치면 안 되므로 이 값 기준으로 묶고, 여유는 강제된다.
export function departureDeadline(flightDepartMs, bufferMin = 210) {
  if (typeof flightDepartMs !== 'number' || Number.isNaN(flightDepartMs)) return NaN;
  return flightDepartMs - bufferMin * 60 * 1000;
}

// ── 필요한 차량 세기 ─────────────────────────────────────────
//
// 담당자가 배차에서 처음 묻는 것은 "차를 몇 대 불러야 하나" 인데, 지금까지는
// 그 답이 화면 어디에도 없었다. 도착 시각은 이미 등록서에 다 있으므로
// 화면이 먼저 세어 줄 수 있다.
//
// **자동 배차와 같은 규칙으로 묶는다** — 같은 공항, 앞사람 시각으로부터
// windowMin 안. 여기서 센 대수와 자동 배차가 실제로 채우는 대수가 다르면
// 숫자가 거짓말이 된다.
//
// people:    [{ id, airport, timeAt, needsPickup }]
// runs:      [{ id, airport, capacity }]
// vanSeats:  새로 만들 밴 한 대의 정원 (부족분을 몇 대로 볼지 계산용)
// 반환: [{ airport, from, to, personIds, flightsAt, seatsNeeded, seatsHave,
//         runIds, vansToAdd }]
export function planRuns({ runs = [], people = [], windowMin = 90, vanSeats = 7 }) {
  const windowMs = windowMin * 60 * 1000;
  const seats = Math.max(1, Number(vanSeats) || 1);

  const pickup = people.filter(
    (p) =>
      p.needsPickup !== false &&
      typeof p.timeAt === 'number' &&
      !Number.isNaN(p.timeAt),
  );

  const buckets = [];
  const airports = [...new Set(pickup.map((p) => p.airport))].sort();

  for (const airport of airports) {
    const queue = pickup
      .filter((p) => p.airport === airport)
      .sort((a, b) => a.timeAt - b.timeAt);

    // 앞사람으로부터 windowMs 안이면 같은 묶음. 자동 배차의 anchor 규칙과 같다.
    let current = null;
    for (const p of queue) {
      if (current === null || p.timeAt - current.from > windowMs) {
        current = { airport, from: p.timeAt, to: p.timeAt, personIds: [], flightsAt: [] };
        buckets.push(current);
      }
      current.to = Math.max(current.to, p.timeAt);
      current.personIds.push(p.id);
      if (!current.flightsAt.includes(p.timeAt)) current.flightsAt.push(p.timeAt);
    }
  }

  // 이미 만들어 둔 밴을 묶음에 붙인다. 밴에는 시각이 없을 수 있으므로
  // 공항이 같은 밴을 시각 순서대로 앞 묶음부터 나눠 준다 — 담당자가
  // 만든 순서가 곧 이른 시각부터라는 뜻이기 때문이다.
  for (const airport of airports) {
    const mine = buckets.filter((b) => b.airport === airport);
    const vans = runs.filter((r) => r.airport === airport);
    let vi = 0;
    for (const b of mine) {
      b.seatsNeeded = b.personIds.length;
      b.seatsHave = 0;
      b.runIds = [];
      while (vi < vans.length && b.seatsHave < b.seatsNeeded) {
        b.seatsHave += Math.max(0, Number(vans[vi].capacity) || 0);
        b.runIds.push(vans[vi].id);
        vi += 1;
      }
      const short = Math.max(0, b.seatsNeeded - b.seatsHave);
      b.vansToAdd = Math.ceil(short / seats);
    }
    // 남는 밴은 마지막 묶음에 붙인다. 어디에도 안 붙으면 화면에서 사라진다.
    if (vi < vans.length && mine.length > 0) {
      const last = mine[mine.length - 1];
      for (; vi < vans.length; vi += 1) {
        last.seatsHave += Math.max(0, Number(vans[vi].capacity) || 0);
        last.runIds.push(vans[vi].id);
      }
      last.vansToAdd = Math.ceil(
        Math.max(0, last.seatsNeeded - last.seatsHave) / seats,
      );
    }
  }

  // 공항이 없는(아직 밴만 만들어 둔) 경우까지 보여 줄 필요는 없다 —
  // 태울 사람이 없으면 묶음도 없다.
  return buckets.sort((a, b) => a.from - b.from || a.airport.localeCompare(b.airport));
}
