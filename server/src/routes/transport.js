import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';
import {
  autoDispatch,
  departureDeadline,
  isPickupExempt,
  planRuns,
} from '../services/dispatch_engine.js';

const router = Router();

// ── 공항·시각 추출 ────────────────────────────────────────────
// flight: JSONB(도착/출발) → { airport, timeAt(ms) }. direction별 키가 다름.
function pickFlight(flight, direction) {
  if (!flight || typeof flight !== 'object') return { airport: null, timeAt: NaN };
  const airport = direction === 'arrival' ? flight.arrival_airport : flight.departure_airport;
  const raw = direction === 'arrival' ? flight.scheduled_arrival : flight.scheduled_departure;
  let timeAt = raw ? Date.parse(raw) : NaN;
  // 출발은 비행 시각에서 공항 도착 데드라인으로 역산(여유 강제)
  if (direction === 'departure') timeAt = departureDeadline(timeAt);
  return { airport: airport || null, timeAt };
}

// 공항이든 시각이든 하나라도 있으면 "항공편을 적어 냈다"고 본다.
// flight_confirmed(021)보다 느슨하다 — 편명 없이 날짜만 적은 예상 항공편이라도
// 비행기로 온다는 뜻이므로 픽업 명단에서 빼면 안 된다.
function hasFlightInfo({ airport, timeAt }) {
  return !!airport || (typeof timeAt === 'number' && !Number.isNaN(timeAt));
}

// 프로그램+방향의 픽업 대상(등록자+동반자) 로드 → { people, meta, info }
//   people: 엔진 입력  meta: key→{regId,compId}  info: key→표시용
//
// 개최국 참가자는 여기서 걸러진다(isPickupExempt). 걸러진 사람은 meta/info 에도
// 넣지 않으므로 미배차 목록·자동 배차 양쪽에서 함께 사라진다. 이미 밴에 타
// 있는 사람은 건드리지 않는다 — 명부(runs) 조회는 별도 질의다.
async function loadDispatchPeople(programId, direction) {
  const [[program], regs, comps] = await Promise.all([
    sql`SELECT program_type, host_country FROM programs WHERE id = ${programId}`,
    sql`
      SELECT id, display_name(bible_name, real_name) AS name, country, needs_pickup, pickup_from,
             arrival_flight, departure_flight
      FROM registrations
      WHERE program_id = ${programId} AND submitted = true
        AND real_name IS NOT NULL AND real_name <> ''
    `,
    sql`
      SELECT c.id, c.real_name AS name, c.needs_pickup, c.same_flight_as_primary,
             c.arrival_flight, c.departure_flight,
             r.country AS p_country,
             r.arrival_flight AS p_arrival, r.departure_flight AS p_departure
      FROM companions c
      JOIN registrations r ON r.id = c.registration_id
      WHERE r.program_id = ${programId} AND r.submitted = true
    `,
  ]);

  const programType = program?.program_type ?? null;
  const hostCountry = program?.host_country ?? null;

  const people = [];
  const meta = new Map();
  const info = new Map();

  for (const r of regs) {
    const flight = direction === 'arrival' ? r.arrival_flight : r.departure_flight;
    const { airport, timeAt } = pickFlight(flight, direction);
    if (
      isPickupExempt({
        programType,
        hostCountry,
        country: r.country,
        hasFlight: hasFlightInfo({ airport, timeAt }),
        pickupFrom: r.pickup_from,
      })
    ) {
      continue;
    }
    const key = `reg:${r.id}`;
    meta.set(key, { regId: r.id, compId: null });
    // 공항이 아닌 곳에서 태우는 사람이 있다(035). 어디서 태울지 모르면
    // 배차판에 이름만 뜨고 담당자가 다시 물어봐야 한다.
    info.set(key, {
      name: r.name,
      airport: airport ?? r.pickup_from,
      timeAt,
      flight,
    });
    people.push({ id: key, airport, timeAt, needsPickup: r.needs_pickup });
  }
  for (const c of comps) {
    const own = direction === 'arrival' ? c.arrival_flight : c.departure_flight;
    const primary = direction === 'arrival' ? c.p_arrival : c.p_departure;
    const flight = c.same_flight_as_primary ? primary : own;
    const { airport, timeAt } = pickFlight(flight, direction);
    // 동반자는 국적 칸이 따로 없다. 등록자와 함께 오므로 등록자의 나라로 본다.
    if (
      isPickupExempt({
        programType,
        hostCountry,
        country: c.p_country,
        hasFlight: hasFlightInfo({ airport, timeAt }),
      })
    ) {
      continue;
    }
    const key = `comp:${c.id}`;
    meta.set(key, { regId: null, compId: c.id });
    info.set(key, { name: c.name, airport, timeAt, flight });
    people.push({ id: key, airport, timeAt, needsPickup: c.needs_pickup });
  }

  return { people, meta, info };
}

// ── GET 배차판 (밴 + 탑승자 + 미배차) ─────────────────────────
router.get('/:programId/runs', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  const direction = req.query.direction === 'departure' ? 'departure' : 'arrival';
  try {
    const runs = await sql`
      SELECT tr.id, tr.airport, tr.depart_at, tr.vehicle, tr.driver_name, tr.driver_phone,
             tr.capacity, tr.meet_point,
        COALESCE(json_agg(
          json_build_object(
            'registrationId', ra.registration_id,
            'companionId', ra.companion_id,
            'name', COALESCE(display_name(reg.bible_name, reg.real_name), comp.real_name),
            'arrivalFlight', COALESCE(reg.arrival_flight, comp.arrival_flight),
            'departureFlight', COALESCE(reg.departure_flight, comp.departure_flight)
          ) ORDER BY COALESCE(reg.real_name, comp.real_name)
        ) FILTER (WHERE ra.id IS NOT NULL), '[]') AS members
      FROM transport_runs tr
      LEFT JOIN run_assignments ra ON ra.run_id = tr.id
      LEFT JOIN registrations reg ON reg.id = ra.registration_id
      LEFT JOIN companions comp ON comp.id = ra.companion_id
      WHERE tr.program_id = ${programId} AND tr.direction = ${direction}
      GROUP BY tr.id
      ORDER BY tr.airport, tr.depart_at NULLS LAST, tr.created_at
    `;

    // 미배차: 픽업 대상 중 이 방향에서 아직 어느 밴에도 없는 사람
    const [{ people, meta, info }, assigned] = await Promise.all([
      loadDispatchPeople(programId, direction),
      sql`
        SELECT ra.registration_id, ra.companion_id
        FROM run_assignments ra
        JOIN transport_runs tr ON tr.id = ra.run_id
        WHERE tr.program_id = ${programId} AND tr.direction = ${direction}
      `,
    ]);
    const assignedKeys = new Set(
      assigned.map((a) => (a.registration_id ? `reg:${a.registration_id}` : `comp:${a.companion_id}`)),
    );
    const unassigned = people
      .filter((p) => p.needsPickup !== false && !assignedKeys.has(p.id))
      .map((p) => {
        const d = info.get(p.id);
        const m = meta.get(p.id);
        return {
          registrationId: m.regId,
          companionId: m.compId,
          name: d.name,
          airport: d.airport,
          timeAt: Number.isNaN(d.timeAt) ? null : new Date(d.timeAt).toISOString(),
          reason: Number.isNaN(d.timeAt) ? 'no_time' : 'unassigned',
        };
      });

    // 시간대별 필요 대수(042 배차 준비). 담당자가 배차에서 처음 묻는 것은
    // "차를 몇 대 불러야 하나" 인데, 지금까지 그 답이 화면 어디에도 없었다.
    //
    // **자동 배차와 같은 규칙으로 묶는다** — 여기서 센 대수와 실제로 채워지는
    // 대수가 다르면 숫자가 거짓말이 된다.
    const plan = planRuns({
      runs: runs.map((r) => ({
        id: r.id,
        airport: r.airport,
        capacity: r.capacity,
      })),
      people,
      windowMin: 90,
      vanSeats: 7,
    }).map((b) => ({
      airport: b.airport,
      from: new Date(b.from).toISOString(),
      to: new Date(b.to).toISOString(),
      people: b.personIds.length,
      seats_needed: b.seatsNeeded,
      seats_have: b.seatsHave,
      vans_to_add: b.vansToAdd,
      run_ids: b.runIds,
      // 이 묶음에 속한 사람들. 화면이 편명·시각으로 줄을 그린다.
      members: b.personIds.map((pid) => {
        const d = info.get(pid);
        const m2 = meta.get(pid);
        return {
          registrationId: m2?.regId ?? null,
          companionId: m2?.compId ?? null,
          name: d?.name ?? '',
          timeAt: d && !Number.isNaN(d.timeAt)
            ? new Date(d.timeAt).toISOString()
            : null,
          assigned: assignedKeys.has(pid),
        };
      }),
    }));

    res.json({ direction, runs, unassigned, plan });
  } catch (err) {
    console.error('배차판 조회 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── POST 밴(명부) 생성 ────────────────────────────────────────
router.post('/:programId/runs', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  const { direction, airport, capacity, vehicle, driverName, driverPhone, departAt, meetPoint } = req.body;
  if (!['arrival', 'departure'].includes(direction) || !airport) {
    return res.status(400).json({ error: 'direction과 airport는 필수입니다' });
  }
  const cap = Number(capacity);
  if (!Number.isInteger(cap) || cap <= 0) {
    return res.status(400).json({ error: 'capacity는 1 이상의 정수여야 합니다' });
  }
  try {
    const [run] = await sql`
      INSERT INTO transport_runs
        (program_id, direction, airport, capacity, vehicle, driver_name, driver_phone, depart_at, meet_point)
      VALUES (${programId}, ${direction}, ${airport}, ${cap},
              ${vehicle ?? null}, ${driverName ?? null}, ${driverPhone ?? null},
              ${departAt ?? null}, ${meetPoint ?? null})
      RETURNING id
    `;
    res.status(201).json({ id: run.id });
  } catch (err) {
    console.error('밴 생성 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── PATCH 밴 수정 ─────────────────────────────────────────────
router.patch('/:programId/runs/:runId', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId, runId } = req.params;
  const { airport, capacity, vehicle, driverName, driverPhone, departAt, meetPoint } = req.body;
  try {
    const [run] = await sql`SELECT id, capacity FROM transport_runs WHERE id = ${runId} AND program_id = ${programId}`;
    if (!run) return res.status(404).json({ error: '밴을 찾을 수 없습니다' });

    if (capacity != null) {
      const cap = Number(capacity);
      if (!Number.isInteger(cap) || cap <= 0) {
        return res.status(400).json({ error: 'capacity는 1 이상의 정수여야 합니다' });
      }
      const [{ count }] = await sql`SELECT COUNT(*)::int AS count FROM run_assignments WHERE run_id = ${runId}`;
      if (cap < count) {
        return res.status(422).json({ code: 'CAPACITY_BELOW_ASSIGNED', error: `이미 배정된 ${count}명보다 작을 수 없습니다` });
      }
    }

    await sql`
      UPDATE transport_runs SET
        airport      = COALESCE(${airport ?? null}, airport),
        capacity     = COALESCE(${capacity ?? null}, capacity),
        vehicle      = ${vehicle ?? null},
        driver_name  = ${driverName ?? null},
        driver_phone = ${driverPhone ?? null},
        depart_at    = ${departAt ?? null},
        meet_point   = ${meetPoint ?? null}
      WHERE id = ${runId}
    `;
    res.json({ ok: true });
  } catch (err) {
    console.error('밴 수정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── DELETE 밴 삭제 (배정도 CASCADE 해제) ──────────────────────
router.delete('/:programId/runs/:runId', requireAuth, requireProgramAdmin, async (req, res) => {
  try {
    await sql`DELETE FROM transport_runs WHERE id = ${req.params.runId} AND program_id = ${req.params.programId}`;
    res.json({ ok: true });
  } catch (err) {
    console.error('밴 삭제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── POST 자동 배차 (명부에 승객 채움) ─────────────────────────
router.post('/:programId/runs/auto', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId } = req.params;
  const direction = req.query.direction === 'departure' ? 'departure' : 'arrival';
  const windowMin = Number(req.body?.windowMin) > 0 ? Number(req.body.windowMin) : 90;
  try {
    const [runs, { people, meta }] = await Promise.all([
      sql`SELECT id, airport, capacity FROM transport_runs WHERE program_id = ${programId} AND direction = ${direction}`,
      loadDispatchPeople(programId, direction),
    ]);
    if (runs.length === 0) {
      return res.status(422).json({ code: 'NO_RUNS', error: '먼저 기사·차량(밴)을 등록하세요' });
    }

    const { assignments, unassigned } = autoDispatch({ runs, people, windowMin });

    await sql.transaction(async (client) => {
      await client.query(
        `DELETE FROM run_assignments
         WHERE run_id IN (SELECT id FROM transport_runs WHERE program_id = $1 AND direction = $2)`,
        [programId, direction],
      );
      for (const a of assignments) {
        const m = meta.get(a.personId);
        await client.query(
          `INSERT INTO run_assignments (run_id, registration_id, companion_id) VALUES ($1, $2, $3)`,
          [a.runId, m.regId, m.compId],
        );
      }
    });

    res.json({ assigned: assignments.length, unassigned: unassigned.length });
  } catch (err) {
    console.error('자동 배차 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── POST 수동 배정 { registrationId | companionId } (정원 검증) ─
router.post('/:programId/runs/:runId/assign', requireAuth, requireProgramAdmin, async (req, res) => {
  const { programId, runId } = req.params;
  const { registrationId, companionId } = req.body;
  if (!registrationId === !companionId) {
    return res.status(400).json({ error: 'registrationId 또는 companionId 중 하나만 필요합니다' });
  }
  try {
    const [run] = await sql`
      SELECT tr.direction, tr.capacity,
             (SELECT COUNT(*) FROM run_assignments WHERE run_id = tr.id) AS occupied
      FROM transport_runs tr WHERE tr.id = ${runId} AND tr.program_id = ${programId}
    `;
    if (!run) return res.status(404).json({ error: '밴을 찾을 수 없습니다' });
    if (Number(run.occupied) >= run.capacity) {
      return res.status(422).json({ code: 'RUN_FULL', error: '밴 정원이 가득 찼습니다' });
    }

    await sql.transaction(async (client) => {
      // 같은 방향의 다른 밴에서 이 사람 제거 (한 방향 1밴)
      if (registrationId) {
        await client.query(
          `DELETE FROM run_assignments ra USING transport_runs tr
           WHERE ra.run_id = tr.id AND tr.program_id = $1 AND tr.direction = $2 AND ra.registration_id = $3`,
          [programId, run.direction, registrationId],
        );
        await client.query(
          `INSERT INTO run_assignments (run_id, registration_id) VALUES ($1, $2)`,
          [runId, registrationId],
        );
      } else {
        await client.query(
          `DELETE FROM run_assignments ra USING transport_runs tr
           WHERE ra.run_id = tr.id AND tr.program_id = $1 AND tr.direction = $2 AND ra.companion_id = $3`,
          [programId, run.direction, companionId],
        );
        await client.query(
          `INSERT INTO run_assignments (run_id, companion_id) VALUES ($1, $2)`,
          [runId, companionId],
        );
      }
    });
    res.json({ success: true });
  } catch (err) {
    console.error('수동 배정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── DELETE 탑승 해제 { registrationId | companionId } ─────────
router.delete('/:programId/runs/:runId/pax', requireAuth, requireProgramAdmin, async (req, res) => {
  const { runId } = req.params;
  const { registrationId, companionId } = req.body;
  try {
    if (registrationId) {
      await sql`DELETE FROM run_assignments WHERE run_id = ${runId} AND registration_id = ${registrationId}`;
    } else if (companionId) {
      await sql`DELETE FROM run_assignments WHERE run_id = ${runId} AND companion_id = ${companionId}`;
    } else {
      return res.status(400).json({ error: 'registrationId 또는 companionId가 필요합니다' });
    }
    res.json({ success: true });
  } catch (err) {
    console.error('탑승 해제 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── PATCH 내 픽업 필요 여부(자차 토글) ────────────────────────
router.patch('/:programId/my-pickup', requireAuth, async (req, res) => {
  const { programId } = req.params;
  const { needsPickup } = req.body;
  try {
    const result = await sql`
      UPDATE registrations SET needs_pickup = ${needsPickup !== false}, updated_at = NOW()
      WHERE program_id = ${programId} AND user_id = ${req.user.userId}
      RETURNING id
    `;
    if (result.length === 0) return res.status(404).json({ error: '등록 정보가 없습니다' });
    res.json({ needsPickup: needsPickup !== false });
  } catch (err) {
    console.error('픽업 설정 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

// ── GET 내 이동 정보(참가자) ──────────────────────────────────
router.get('/:programId/my-transport', requireAuth, async (req, res) => {
  const { programId } = req.params;
  try {
    const [me] = await sql`
      SELECT r.id, r.needs_pickup, r.country, r.arrival_flight, r.departure_flight,
             p.program_type, p.host_country
      FROM registrations r
      JOIN programs p ON p.id = r.program_id
      WHERE r.program_id = ${programId} AND r.user_id = ${req.user.userId}
    `;
    if (!me) {
      return res.json({ needsPickup: true, pickupExempt: false, arrival: null, departure: null });
    }

    // 명단에서 빠진 사람에게는 그 사실을 알려야 한다. 배차판에는 없는데 화면은
    // "곧 배차될 예정입니다"라고 말하면, 오지 않을 차를 공항에서 기다린다.
    // 할인 신청에서 같은 함정을 한 번 만들었다(registrations.js 참조).
    const pickupExempt = isPickupExempt({
      programType: me.program_type,
      hostCountry: me.host_country,
      country: me.country,
      hasFlight:
        hasFlightInfo(pickFlight(me.arrival_flight, 'arrival')) ||
        hasFlightInfo(pickFlight(me.departure_flight, 'departure')),
    });

    // 내가 탄 밴(등록자 기준) + 동승자 이름
    const runs = await sql`
      SELECT tr.direction, tr.airport, tr.depart_at, tr.vehicle,
             tr.driver_name, tr.driver_phone, tr.meet_point,
        (SELECT COALESCE(json_agg(COALESCE(display_name(reg2.bible_name, reg2.real_name), comp2.real_name)) FILTER (WHERE ra2.id IS NOT NULL), '[]')
         FROM run_assignments ra2
         LEFT JOIN registrations reg2 ON reg2.id = ra2.registration_id
         LEFT JOIN companions comp2 ON comp2.id = ra2.companion_id
         WHERE ra2.run_id = tr.id AND ra2.registration_id IS DISTINCT FROM ${me.id}) AS co_passengers
      FROM run_assignments ra
      JOIN transport_runs tr ON tr.id = ra.run_id
      WHERE tr.program_id = ${programId} AND ra.registration_id = ${me.id}
    `;
    const arrival = runs.find((r) => r.direction === 'arrival') ?? null;
    const departure = runs.find((r) => r.direction === 'departure') ?? null;
    res.json({ needsPickup: me.needs_pickup, pickupExempt, arrival, departure });
  } catch (err) {
    console.error('내 이동 정보 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
