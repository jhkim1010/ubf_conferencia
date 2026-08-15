import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  AUDIENCE_KINDS,
  isValidAudience,
  audienceFromBody,
} from '../src/services/audience.js';

const UUID = '0f8fad5b-d9cb-469f-a165-70867728950e';

// 대상을 하나 골라야 하는 갈래. 없으면 좁히려던 것이 전체로 넓어진다.
const NEEDS_ID = { room: UUID, group: UUID, service: 'pickup' };

test('아는 갈래만 받는다', () => {
  for (const kind of AUDIENCE_KINDS) {
    const a = NEEDS_ID[kind] ? { kind, id: NEEDS_ID[kind] } : { kind };
    assert.equal(isValidAudience(a), true, kind);
  }
  assert.equal(isValidAudience({ kind: 'everyone' }), false);
  assert.equal(isValidAudience(null), false);
  assert.equal(isValidAudience('all'), false);
});

test('봉사팀은 역할 키로 고른다', () => {
  // 역할 키는 UUID 가 아니다. 담당자가 만든 역할은 'custom:...' 로 온다.
  assert.equal(isValidAudience({ kind: 'service', id: 'pickup' }), true);
  assert.equal(
    isValidAudience({ kind: 'service', id: 'custom:iguazu-bus-01' }),
    true,
  );
  // 어느 팀인지 모르는 채로 보내면 전체에게 가는 셈이다.
  assert.equal(isValidAudience({ kind: 'service' }), false);
  assert.equal(isValidAudience({ kind: 'service', id: '' }), false);
  assert.equal(isValidAudience({ kind: 'service', id: 'x'.repeat(61) }), false);
});

test('방·조는 대상 id 가 있어야 한다', () => {
  // 어느 방인지 모르는 채로 보내면, 좁히려던 것이 전체로 넓어진다.
  assert.equal(isValidAudience({ kind: 'room' }), false);
  assert.equal(isValidAudience({ kind: 'room', id: '' }), false);
  assert.equal(isValidAudience({ kind: 'room', id: '짧음' }), false);
  assert.equal(isValidAudience({ kind: 'group', id: UUID }), true);
});

test('안 보냈으면 전체다', () => {
  // 예전 앱이 보내는 요청도 그대로 동작해야 한다.
  assert.deepEqual(audienceFromBody({}), { kind: 'all' });
  assert.deepEqual(audienceFromBody({ audience: null }), { kind: 'all' });
});

test('이상한 값이면 null — 전체로 넓히지 않는다', () => {
  // 여기서 전체로 떨어뜨리면, 한 방에만 보내려던 공지가 전원에게 간다.
  assert.equal(audienceFromBody({ audience: { kind: 'nope' } }), null);
  assert.equal(audienceFromBody({ audience: { kind: 'room' } }), null);
  assert.equal(audienceFromBody({ audience: 7 }), null);
});

test('제대로 온 값은 그대로', () => {
  assert.deepEqual(audienceFromBody({ audience: { kind: 'room', id: UUID } }), {
    kind: 'room',
    id: UUID,
  });
  assert.deepEqual(audienceFromBody({ audience: { kind: 'unsubmitted' } }), {
    kind: 'unsubmitted',
    id: null,
  });
});
