import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  MAX_PHOTOS,
  MAX_PLAN_DOCS,
  MAX_DOC_NAME,
  isSafeMediaUrl,
  normalizePlanDocs,
  normalizePhotoUrls,
  normalizeOptionMedia,
  normalizeOptions,
} from '../src/services/option_media.js';

const MEDIA = '/media/program/0f8fad5b-d9cb-469f-a165-70867728950e.pdf';
const MEDIA2 = '/media/program/1f8fad5b-d9cb-469f-a165-70867728950e.jpg';

test('우리가 저장한 경로와 http 링크만 받는다', () => {
  assert.equal(isSafeMediaUrl(MEDIA), true);
  assert.equal(isSafeMediaUrl('https://example.com/plan.pdf'), true);
  assert.equal(isSafeMediaUrl('http://example.com/plan.pdf'), true);
});

test('실행 통로가 되는 주소는 막는다', () => {
  // 이 값은 참가자 화면에서 그대로 열린다.
  for (const bad of [
    'javascript:alert(1)',
    'JavaScript:alert(1)',
    'data:text/html,<script>alert(1)</script>',
    'file:///etc/passwd',
    '/etc/passwd',
    '/media/../../etc/passwd',
    '',
    '   ',
    null,
    undefined,
    42,
    {},
  ]) {
    assert.equal(isSafeMediaUrl(bad), false, `막지 못했다: ${String(bad)}`);
  }
});

test('media 경로는 우리가 만드는 형태만 받는다', () => {
  // uuid 가 아니면 우리가 저장한 파일이 아니다.
  assert.equal(isSafeMediaUrl('/media/program/plan.pdf'), false);
  assert.equal(isSafeMediaUrl('/media/program/../card/x.pdf'), false);
  assert.equal(isSafeMediaUrl('/media/PROGRAM/0f8fad5b-d9cb-469f-a165-70867728950e.pdf'), false);
});

test('계획서 목록 — 이름이 없으면 기본값이 붙는다', () => {
  const out = normalizePlanDocs([{ url: MEDIA }]);
  assert.deepEqual(out, [{ url: MEDIA, name: '자료', bytes: null }]);
});

test('계획서 목록 — 이름 공백은 한 칸으로 줄이고 길이를 자른다', () => {
  const [a] = normalizePlanDocs([{ url: MEDIA, name: '  일정표   최종  ' }]);
  assert.equal(a.name, '일정표 최종');

  const [b] = normalizePlanDocs([{ url: MEDIA, name: 'ㄱ'.repeat(500) }]);
  assert.equal(b.name.length, MAX_DOC_NAME);
});

test('계획서 목록 — 크기는 양의 정수만', () => {
  const bytes = (v) => normalizePlanDocs([{ url: MEDIA, bytes: v }])[0].bytes;
  assert.equal(bytes(91234), 91234);
  assert.equal(bytes(91234.7), 91234);
  assert.equal(bytes(-5), null);
  assert.equal(bytes('91234'), null);
  assert.equal(bytes(undefined), null);
});

test('계획서 목록 — 못 쓸 항목만 버리고 나머지는 살린다', () => {
  // 하나가 이상하다고 저장 전체를 막으면 담당자는 방금 채운 내용을 다 잃는다.
  const out = normalizePlanDocs([
    { url: MEDIA, name: '일정표' },
    { url: 'javascript:alert(1)', name: '나쁨' },
    null,
    'not-an-object',
    { name: '주소 없음' },
    { url: 'https://example.com/b.pdf', name: '비용안내' },
  ]);
  assert.deepEqual(
    out.map((d) => d.name),
    ['일정표', '비용안내'],
  );
});

test('계획서 목록 — 같은 파일은 한 번만', () => {
  const out = normalizePlanDocs([
    { url: MEDIA, name: '일정표' },
    { url: MEDIA, name: '일정표(같은 파일)' },
  ]);
  assert.equal(out.length, 1);
  assert.equal(out[0].name, '일정표');
});

test('계획서 목록 — 상한을 넘기면 앞에서부터 자른다', () => {
  const many = Array.from({ length: 30 }, (_, i) => ({
    url: `/media/program/${String(i).padStart(8, '0')}-d9cb-469f-a165-70867728950e.pdf`,
    name: `${i}`,
  }));
  const out = normalizePlanDocs(many);
  assert.equal(out.length, MAX_PLAN_DOCS);
  assert.equal(out[0].name, '0');
});

test('계획서 목록 — 배열이 아니면 빈 목록', () => {
  for (const v of [null, undefined, 'x', 7, {}]) {
    assert.deepEqual(normalizePlanDocs(v), []);
  }
});

test('사진 목록 — 중복·나쁜 주소를 걸러 여섯 장까지', () => {
  assert.deepEqual(normalizePhotoUrls([MEDIA2, MEDIA2]), [MEDIA2]);
  assert.deepEqual(normalizePhotoUrls(['javascript:alert(1)']), []);

  const many = Array.from({ length: 20 }, (_, i) =>
    `/media/program/${String(i).padStart(8, '0')}-d9cb-469f-a165-70867728950e.jpg`);
  assert.equal(normalizePhotoUrls(many).length, MAX_PHOTOS);
});

test('옵션 하나 — 자료 칸만 손대고 나머지는 그대로 둔다', () => {
  const out = normalizeOptionMedia({
    name: '이과수 투어',
    cost: 120,
    capacity: 40,
    photoUrls: [MEDIA2, 'javascript:alert(1)'],
    planDocs: [{ url: MEDIA, name: '일정표' }],
    brochureUrl: 'https://example.com/b.pdf',
    videoUrl: 'javascript:alert(1)',
  });
  assert.equal(out.name, '이과수 투어');
  assert.equal(out.cost, 120);
  assert.equal(out.capacity, 40);
  assert.deepEqual(out.photoUrls, [MEDIA2]);
  assert.equal(out.planDocs.length, 1);
  assert.equal(out.brochureUrl, 'https://example.com/b.pdf');
  assert.equal(out.videoUrl, '');
});

test('옵션 하나 — 자료 칸이 아예 없어도 빈 목록으로 채워진다', () => {
  // 여기서 undefined 가 나가면 INSERT 의 json 경로가 그대로 깨진다.
  const out = normalizeOptionMedia({ name: '투어' });
  assert.deepEqual(out.photoUrls, []);
  assert.deepEqual(out.planDocs, []);
  assert.equal(out.brochureUrl, '');
  assert.equal(out.videoUrl, '');
});

test('옵션 배열이 아니면 받은 그대로 돌려준다', () => {
  // 라우트는 Array.isArray 로 다시 판단한다 — 여기서 모양을 바꾸면 안 된다.
  assert.equal(normalizeOptions(undefined), undefined);
  assert.equal(normalizeOptions(null), null);
  assert.deepEqual(normalizeOptions([]), []);
});
