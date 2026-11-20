// 대표자가 함께 등록한 동반자가 **자기 계정으로 또 등록한** 경우.
//
// 동반자의 비용은 대표자가 낸다(2026-11 결정). 그런데 그 사람이 따로
// 등록하면 같은 사람이 두 번 셈에 들어간다 — 대표자 등록의 동반자로 한 번,
// 자기 등록으로 한 번. 인원도 둘, 참가비도 둘이 된다.
//
// 그래서 그런 등록을 "대표자가 낸다(covered)" 로 본다:
//   - 그 등록의 낼 돈은 0 이다. 돈은 대표자 등록의 동반자 몫으로 이미 셌다.
//   - 인원은 등록으로 한 번만 센다. 동반 인원에서 뺀다.
//   - 방·말씀조에서는 동반자 줄이 그 사람이다. 자기 등록은 빼고 본다.
//
// 동반자 줄에는 그 사람의 등록 id 가 없으므로 이름으로 찾는다
// (room_occupant.js nameKey). **이름이 같은 등록이 꼭 하나일 때만** 잇는다.
// 둘 이상이면 누구인지 알 수 없어 그대로 둔다 — 돈을 엉뚱한 사람에게서
// 빼는 것보다 담당자가 보고 고치는 편이 낫다.
//
// DB 를 안 쓰는 판정(coverMap)은 room_occupant.js 에 있고
// test/companion_cover.test.js 로 본다.

import { sql } from '../db.js';
import { coverMap, nameKey } from './room_occupant.js';

export { coverMap };

/// 수양회 [programId] 의 덮인 등록들. 참가로 치는 등록끼리만 본다.
export async function loadCoverMap(programId) {
  const [companions, registrations] = await Promise.all([
    sql`
      SELECT c.id, c.registration_id, c.real_name, c.registers_separately,
             c.study_group
        FROM companions c
        JOIN registrations r ON r.id = c.registration_id
       WHERE r.program_id = ${programId}
         AND counts_as_participant(r.real_name, r.submitted, r.cancelled_at)
         AND c.registers_separately = false
       ORDER BY c.created_at
    `,
    sql`
      SELECT id, real_name FROM registrations
       WHERE program_id = ${programId}
         AND counts_as_participant(real_name, submitted, cancelled_at)
    `,
  ]);
  return coverMap(companions, registrations);
}

/// 등록 하나가 덮였는가. 덮였으면 대표자 이름까지 돌려준다.
export async function coverOf(registrationId) {
  if (!registrationId) return null;
  const [reg] = await sql`
    SELECT program_id FROM registrations WHERE id = ${registrationId}
  `;
  if (!reg) return null;
  const hit = (await loadCoverMap(reg.program_id)).get(registrationId);
  if (!hit) return null;
  const [p] = await sql`
    SELECT display_name(bible_name, real_name) AS name
      FROM registrations WHERE id = ${hit.primaryId}
  `;
  return { ...hit, primaryName: p?.name ?? null };
}

/// 동반 인원 — 함께 등록한 동반자 중 자기 등록이 **없는** 사람.
/// 자기 등록이 있으면 등록 인원으로 이미 셌다.
export async function jointCompanionHeadcount(programId) {
  const [{ n }] = await sql`
    SELECT COUNT(*)::int AS n
      FROM companions c
      JOIN registrations r ON r.id = c.registration_id
     WHERE r.program_id = ${programId}
       AND counts_as_participant(r.real_name, r.submitted, r.cancelled_at)
       AND c.registers_separately = false
  `;
  const covered = (await loadCoverMap(programId)).size;
  return Math.max(0, n - covered);
}

/// 동반자 이름 [names] 와 이름이 같은 등록들 — 동반자를 고친 뒤 그 사람들의
/// 낼 돈을 다시 세는 데 쓴다(덮였다가 풀렸거나, 새로 덮였거나).
export async function registrationsNamed(programId, names, exceptId) {
  const keys = new Set((names ?? []).map(nameKey).filter(Boolean));
  if (keys.size === 0) return [];
  const regs = await sql`
    SELECT id, real_name FROM registrations
     WHERE program_id = ${programId} AND id <> ${exceptId}
  `;
  return regs.filter((r) => keys.has(nameKey(r.real_name))).map((r) => r.id);
}
