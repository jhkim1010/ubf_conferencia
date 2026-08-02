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
// country 를 모르면 제외하지 않는다 — 잘못 빼는 쪽이 잘못 남기는 쪽보다 나쁘다.
export function isPickupExempt({ programType, hostCountry, country, hasFlight }) {
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
