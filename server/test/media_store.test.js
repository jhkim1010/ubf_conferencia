// 이미지 저장 로직 — DB·디스크 비의존 부분만.
//
// 여기서 틀리면 남의 파일을 덮어쓰거나, 이미지가 아닌 것을 이미지로 받아
// 서버가 남의 파일 창고가 된다. 정상 경로보다 **속이려는 입력**에 무게를 둔다.

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  decodeBase64,
  deleteByUrl,
  normalizeKind,
  sniffFile,
  MAX_IMAGE_BYTES,
  MAX_PDF_BYTES,
} from '../src/services/media_store.js';

const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 16, 0x4a, 0x46, 0x49, 0x46, 0, 1]);
const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 13]);
const webp = Buffer.concat([
  Buffer.from('RIFF', 'latin1'),
  Buffer.from([0, 0, 0, 0]),
  Buffer.from('WEBP', 'latin1'),
]);

describe('sniffFile — 내용으로 판단한다', () => {
  test('JPEG·PNG·WebP·PDF 를 알아본다', () => {
    assert.equal(sniffFile(jpeg).ext, 'jpg');
    assert.equal(sniffFile(png).ext, 'png');
    assert.equal(sniffFile(webp).ext, 'webp');
    const pdf = Buffer.from('%PDF-1.7\n%\xe2\xe3\xcf\xd3', 'latin1');
    assert.equal(sniffFile(pdf).ext, 'pdf');
    assert.equal(sniffFile(pdf).family, 'pdf');
  });

  test('이미지가 아니면 거절한다', () => {
    // 확장자만 .jpg 인 파일은 얼마든지 만들 수 있다. 첫 바이트를 본다.
    assert.equal(sniffFile(Buffer.from('<?php system($_GET[0]); ?>')), null);
    assert.equal(sniffFile(Buffer.from('GIF89a............')), null);
  });

  test('너무 짧으면 거절한다', () => {
    assert.equal(sniffFile(Buffer.from([0xff, 0xd8])), null);
    assert.equal(sniffFile(Buffer.alloc(0)), null);
    assert.equal(sniffFile(null), null);
  });
});

describe('decodeBase64Image', () => {
  test('data URL 과 순수 base64 를 모두 받는다', () => {
    const b64 = jpeg.toString('base64');
    assert.deepEqual(decodeBase64(b64), jpeg);
    assert.deepEqual(decodeBase64(`data:image/jpeg;base64,${b64}`), jpeg);
  });

  test('빈 값이면 null', () => {
    for (const v of [null, undefined, '', 123, {}]) {
      assert.equal(decodeBase64(v), null);
    }
  });
});

describe('normalizeKind — 경로에 클라이언트 문자열을 넣지 않는다', () => {
  test('아는 갈래만 그대로 쓴다', () => {
    for (const k of ['program', 'card', 'receipt']) {
      assert.equal(normalizeKind(k), k);
    }
  });

  test('모르는 값은 misc 로 떨어뜨린다', () => {
    // 이것이 없으면 `../../etc` 같은 값으로 아무 데나 쓸 수 있다.
    for (const bad of ['../../etc', '/etc/passwd', '..', '', null, undefined, 'PROGRAM']) {
      assert.equal(normalizeKind(bad), 'misc', String(bad));
    }
  });
});

test('상한이 터무니없이 크지 않다', () => {
  // 사진은 앱이 줄여서 보낸다. 상한이 느슨하면 디스크가 사진으로 찬다.
  assert.ok(MAX_IMAGE_BYTES <= 2_000_000);
  // PDF 는 줄일 수 없지만(스캔한 교재는 몇 MB 다) 무제한은 아니다.
  assert.ok(MAX_PDF_BYTES <= 16_000_000);
  assert.ok(MAX_PDF_BYTES > MAX_IMAGE_BYTES);
});

describe('deleteByUrl — 우리가 만든 경로만 지운다', () => {
  test('형태가 다르면 손대지 않는다', async () => {
    // 임의 경로를 받으면 그것으로 서버의 아무 파일이나 지울 수 있다.
    for (const bad of [
      '/etc/passwd',
      '/media/../../etc/passwd',
      '/media/program/../../../x.jpg',
      '/media/unknownkind/11111111-1111-1111-1111-111111111111.jpg',
      'media/program/11111111-1111-1111-1111-111111111111.jpg',
      '/media/program/not-a-uuid.jpg',
      '',
      null,
    ]) {
      assert.equal(await deleteByUrl(bad), false, String(bad));
    }
  });
});
