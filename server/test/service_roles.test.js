import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  DEFAULT_SERVICE_ROLES,
  MAX_ROLES,
  MAX_LABEL,
  MAX_NEEDED,
  isValidRoleKey,
  isCustomKey,
  normalizeServiceRoles,
  rolesOf,
  statusOnInvite,
  statusOnConfirm,
  statusOnRespond,
  occupiesSeat,
  tallyRole,
  sortRoles,
} from '../src/services/service_roles.js';

const CUSTOM = 'custom:9f2c1a4b-77de';

test('기본 역할에는 담당자가 물어본 것들이 들어 있다', () => {
  const keys = DEFAULT_SERVICE_ROLES.map((r) => r.key);
  for (const k of ['tour_guide', 'meal_prep', 'lodging_backup', 'pickup', 'group_study_leader']) {
    assert.ok(keys.includes(k), `빠졌다: ${k}`);
  }
});

test('말씀조 리더만 승인이 필요하다', () => {
  const needsApproval = DEFAULT_SERVICE_ROLES
    .filter((r) => r.requires_approval)
    .map((r) => r.key);
  assert.deepEqual(needsApproval, ['group_study_leader']);
});

test('역할 키는 기본 목록이거나 custom: 형태만', () => {
  assert.equal(isValidRoleKey('pickup'), true);
  assert.equal(isValidRoleKey(CUSTOM), true);
  for (const bad of ['', 'custom:', 'custom:ab', 'unknown_role', 'custom:대문자없음ABC', null, 7]) {
    assert.equal(isValidRoleKey(bad), false, `막지 못했다: ${String(bad)}`);
  }
});

test('자유 역할은 이름이 없으면 버린다', () => {
  // 화면에 "custom:9f2c…" 라고 뜨느니 없는 편이 낫다.
  assert.deepEqual(normalizeServiceRoles([{ key: CUSTOM }]), []);
  assert.deepEqual(normalizeServiceRoles([{ key: CUSTOM, label: '   ' }]), []);
  const [ok] = normalizeServiceRoles([{ key: CUSTOM, label: ' 이과수  버스 인솔 ' }]);
  assert.equal(ok.label, '이과수 버스 인솔');
});

test('기본 역할에 적어 보낸 이름은 무시한다', () => {
  // 이름이 두 곳에 있으면 언젠가 어긋난다. 기본 역할의 이름은 앱이 붙인다.
  const [r] = normalizeServiceRoles([{ key: 'pickup', label: '내 맘대로 이름' }]);
  assert.equal('label' in r, false);
});

test('이름 길이를 자른다', () => {
  const [r] = normalizeServiceRoles([{ key: CUSTOM, label: 'ㄱ'.repeat(300) }]);
  assert.equal(r.label.length, MAX_LABEL);
});

test('필요 인원은 0 이상의 정수', () => {
  const needed = (v) => normalizeServiceRoles([{ key: 'pickup', needed: v }])[0].needed;
  assert.equal(needed(4), 4);
  assert.equal(needed('4'), 4);
  assert.equal(needed(4.9), 4);
  assert.equal(needed(-3), 0);
  assert.equal(needed('넷'), 0);
  assert.equal(needed(undefined), 0);
  assert.equal(needed(99999), MAX_NEEDED);
});

test('같은 역할은 한 번만, 상한을 넘기면 자른다', () => {
  assert.equal(normalizeServiceRoles([{ key: 'pickup' }, { key: 'pickup' }]).length, 1);
  const many = Array.from({ length: 50 }, (_, i) => ({
    key: `custom:role-${String(i).padStart(6, '0')}`,
    label: `역할${i}`,
  }));
  assert.equal(normalizeServiceRoles(many).length, MAX_ROLES);
});

test('못 쓸 항목만 버리고 나머지는 살린다', () => {
  const out = normalizeServiceRoles([
    { key: 'pickup', needed: 4 },
    { key: 'nope' },
    null,
    'text',
    { key: CUSTOM, label: '이과수 인솔', needed: 2 },
  ]);
  assert.deepEqual(out.map((r) => r.key), ['pickup', CUSTOM]);
});

test('구성이 비어 있으면 기본 구성을 쓴다', () => {
  assert.equal(rolesOf([]).length, DEFAULT_SERVICE_ROLES.length);
  assert.equal(rolesOf(null).length, DEFAULT_SERVICE_ROLES.length);
  assert.equal(rolesOf([{ key: 'pickup', needed: 2 }]).length, 1);
});

test('지명은 승인이 필요한 역할이라도 먼저 본인 수락을 기다린다', () => {
  // 순서를 뒤집으면 지부장이 승인해 둔 사람이 나중에 거절하는 일이 생긴다.
  assert.equal(statusOnInvite(), 'invited');
});

test('확정 — 승인이 필요한 역할은 바로 확정되지 않는다', () => {
  assert.equal(statusOnConfirm({ key: 'pickup' }), 'confirmed');
  assert.equal(
    statusOnConfirm({ key: 'group_study_leader', requires_approval: true }),
    'awaiting_approval',
  );
});

test('본인이 답했을 때', () => {
  assert.equal(statusOnRespond({ key: 'pickup' }, true), 'confirmed');
  assert.equal(statusOnRespond({ key: 'pickup' }, false), 'declined');
  assert.equal(
    statusOnRespond({ key: 'group_study_leader', requires_approval: true }, true),
    'awaiting_approval',
  );
  assert.equal(
    statusOnRespond({ key: 'group_study_leader', requires_approval: true }, false),
    'declined',
  );
});

test('자리를 차지하는 상태 — 대기도 센다', () => {
  // 답이 없다고 자리를 비워 두면 담당자가 같은 자리에 또 부탁하게 된다.
  assert.equal(occupiesSeat('applied'), true);
  assert.equal(occupiesSeat('invited'), true);
  assert.equal(occupiesSeat('awaiting_approval'), true);
  assert.equal(occupiesSeat('confirmed'), true);
  assert.equal(occupiesSeat('rejected'), false);
  assert.equal(occupiesSeat('declined'), false);
});

test('역할 하나의 집계', () => {
  const signups = [
    { service_key: 'pickup', status: 'confirmed' },
    { service_key: 'pickup', status: 'invited' },
    { service_key: 'pickup', status: 'declined' },
    { service_key: 'pickup', status: 'applied' },
    { service_key: 'mc', status: 'confirmed' },
  ];
  const t = tallyRole({ key: 'pickup', needed: 4 }, signups);
  assert.deepEqual(t, {
    needed: 4, filled: 3, confirmed: 1, waiting: 1, applied: 1, short: 1,
  });
});

test('필요 인원을 안 정했으면 부족분도 없다', () => {
  // 0 으로 두면 모든 역할이 "다 찼다" 로 보인다.
  const t = tallyRole({ key: 'mc', needed: 0 }, []);
  assert.equal(t.short, 0);
});

test('넘치게 채워도 부족분은 음수가 되지 않는다', () => {
  const signups = Array.from({ length: 5 }, () => ({
    service_key: 'mc', status: 'confirmed',
  }));
  assert.equal(tallyRole({ key: 'mc', needed: 2 }, signups).short, 0);
});

test('모자란 역할이 위로 온다', () => {
  const roles = [
    { key: 'mc', needed: 1 },
    { key: 'pickup', needed: 4 },
    { key: 'cleaning', needed: 0 },
  ];
  const signups = [{ service_key: 'mc', status: 'confirmed' }];
  const sorted = sortRoles(roles, signups).map((r) => r.key);
  // pickup 4명 부족 → mc 는 다 참 → cleaning 은 인원 미정
  assert.equal(sorted[0], 'pickup');
});

test('부족분이 같으면 답을 기다리는 사람이 많은 쪽이 위로', () => {
  const roles = [{ key: 'mc', needed: 0 }, { key: 'cleaning', needed: 0 }];
  const signups = [
    { service_key: 'cleaning', status: 'invited' },
    { service_key: 'cleaning', status: 'invited' },
  ];
  assert.equal(sortRoles(roles, signups)[0].key, 'cleaning');
});

test('정렬이 원본 배열을 건드리지 않는다', () => {
  const roles = [{ key: 'mc', needed: 0 }, { key: 'pickup', needed: 9 }];
  const before = roles.map((r) => r.key);
  sortRoles(roles, []);
  assert.deepEqual(roles.map((r) => r.key), before);
});
