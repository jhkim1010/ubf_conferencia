import { Router } from 'express';
import { sql } from '../db.js';
import { requireAuth, requireProgramAdmin } from '../middleware/auth.js';
import { autoDispatch, departureDeadline } from '../services/dispatch_engine.js';

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

// 프로그램+방향의 픽업 대상(등록자+동반자) 로드 → { people, meta, info }
//   people: 엔진 입력  meta: key→{regId,compId}  info: key→표시용
async function loadDispatchPeople(programId, direction) {
  const [regs, comps] = await Promise.all([
    sql`
      SELECT id, real_name AS name, needs_pickup, arrival_flight, departure_flight
      FROM registrations
      WHERE program_id = ${programId} AND submitted = true
        AND real_name IS NOT NULL AND real_name <> ''
    `,
    sql`
      SELECT c.id, c.real_name AS name, c.needs_pickup, c.same_flight_as_primary,
             c.arrival_flight, c.departure_flight,
             r.arrival_flight AS p_arrival, r.departure_flight AS p_departure
      FROM companions c
      JOIN registrations r ON r.id = c.registration_id
      WHERE r.program_id = ${programId} AND r.submitted = true
    `,
  ]);

  const people = [];
  const meta = new Map();
  const info = new Map();

  for (const r of regs) {
    const flight = direction === 'arrival' ? r.arrival_flight : r.departure_flight;
    const { airport, timeAt } = pickFlight(flight, direction);
    const key = `reg:${r.id}`;
    meta.set(key, { regId: r.id, compId: null });
    info.set(key, { name: r.name, airport, timeAt, flight });
    people.push({ id: key, airport, timeAt, needsPickup: r.needs_pickup });
  }
  for (const c of comps) {
    const own = direction === 'arrival' ? c.arrival_flight : c.departure_flight;
    const primary = direction === 'arrival' ? c.p_arrival : c.p_departure;
    const flight = c.same_flight_as_primary ? primary : own;
    const { airport, timeAt } = pickFlight(flight, direction);
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
            'name', COALESCE(reg.real_name, comp.real_name),
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

    res.json({ direction, runs, unassigned });
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
      SELECT id, needs_pickup FROM registrations
      WHERE program_id = ${programId} AND user_id = ${req.user.userId}
    `;
    if (!me) return res.json({ needsPickup: true, arrival: null, departure: null });

    // 내가 탄 밴(등록자 기준) + 동승자 이름
    const runs = await sql`
      SELECT tr.direction, tr.airport, tr.depart_at, tr.vehicle,
             tr.driver_name, tr.driver_phone, tr.meet_point,
        (SELECT COALESCE(json_agg(COALESCE(reg2.real_name, comp2.real_name)) FILTER (WHERE ra2.id IS NOT NULL), '[]')
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
    res.json({ needsPickup: me.needs_pickup, arrival, departure });
  } catch (err) {
    console.error('내 이동 정보 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
});

export default router;
