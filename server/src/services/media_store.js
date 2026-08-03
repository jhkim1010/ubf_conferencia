// 올린 파일 저장 — 사진과 PDF.
//
// 저장 위치는 **웹을 서비스하는 그 서버의 디스크**다. 새 서비스도 새 요금도
// 없고, nginx 가 /media/ 로 그대로 내보낸다. 배포(rsync --delete)는 web/ 만
// 건드리므로 여기 있는 파일은 배포해도 살아남는다.
//
// 대신 **디스크는 백업되지 않는다.** DB 는 Neon 이 백업하지만 이 폴더는
// 아니다. 사진·자료가 날아가도 등록·배정은 그대로라 감수할 만하다고 보고
// 고른 방식이다. 나중에 옮기게 되면 저장된 경로만 바꾸면 된다.

import { randomUUID } from 'crypto';
import { mkdir, writeFile, unlink } from 'fs/promises';
import { join } from 'path';

// 갈래마다 상한이 다르다.
//
// 사진은 앱이 미리 줄여서 올린다(image_picker 의 maxWidth·imageQuality).
// 서버는 줄이지 않는다 — sharp 같은 네이티브 이미지 라이브러리를 들이면
// 배포가 그만큼 깨지기 쉬워진다. 대신 **너무 큰 것은 받지 않는다.**
//
// PDF 는 줄일 수 없다. 수양회 교재가 스캔본이면 몇 MB 는 예사다.
const LIMITS = {
  image: 1_500_000,
  pdf: 12_000_000,
};

export const MAX_IMAGE_BYTES = LIMITS.image;
export const MAX_PDF_BYTES = LIMITS.pdf;

// 종류는 클라이언트 말을 믿지 않고 **내용의 첫 바이트**로 정한다.
// 이름만 .jpg 인 파일은 얼마든지 만들 수 있다.
export function sniffFile(buf) {
  if (!buf || buf.length < 12) return null;
  if (buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) {
    return { ext: 'jpg', mime: 'image/jpeg', family: 'image' };
  }
  if (
    buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47 &&
    buf[4] === 0x0d && buf[5] === 0x0a && buf[6] === 0x1a && buf[7] === 0x0a
  ) {
    return { ext: 'png', mime: 'image/png', family: 'image' };
  }
  // WebP: 'RIFF' .... 'WEBP'
  if (
    buf.toString('latin1', 0, 4) === 'RIFF' &&
    buf.toString('latin1', 8, 12) === 'WEBP'
  ) {
    return { ext: 'webp', mime: 'image/webp', family: 'image' };
  }
  if (buf.toString('latin1', 0, 5) === '%PDF-') {
    return { ext: 'pdf', mime: 'application/pdf', family: 'pdf' };
  }
  return null;
}

// data URL(`data:image/jpeg;base64,...`)도, 순수 base64 도 받는다.
// 예전 클라이언트가 base64 로 보내는 경로를 위해 남겨 둔다.
export function decodeBase64(raw) {
  if (typeof raw !== 'string' || raw.length === 0) return null;
  const comma = raw.startsWith('data:') ? raw.indexOf(',') : -1;
  const b64 = comma >= 0 ? raw.slice(comma + 1) : raw;
  let buf;
  try {
    buf = Buffer.from(b64, 'base64');
  } catch {
    return null;
  }
  return buf.length > 0 ? buf : null;
}

// 폴더는 갈래로 나눈다 — 나중에 "명함 사진만 지운다" 같은 일을 할 수 있어야
// 한다. **클라이언트가 준 문자열을 경로에 넣지 않는다.** 넣으면
// `../../etc` 같은 값으로 아무 데나 쓸 수 있다.
const KINDS = new Set(['program', 'card', 'receipt', 'library']);
export function normalizeKind(v) {
  return KINDS.has(v) ? v : 'misc';
}

export function mediaRoot() {
  return process.env.MEDIA_DIR || '/srv/ubf/media';
}

/// 저장하고 공개 경로를 돌려준다. 파일명은 무작위다 —
/// 원본 이름을 쓰면 남의 파일을 덮어쓰거나 이름에서 정보가 샌다.
/// 원본 이름이 필요하면 DB 에 따로 적는다(라이브러리의 제목처럼).
export async function saveFile(buf, kind) {
  const kind2 = normalizeKind(kind);
  const type = sniffFile(buf);
  if (!type) throw new Error('UNSUPPORTED_TYPE');
  if (buf.length > LIMITS[type.family]) throw new Error('TOO_LARGE');

  const dir = join(mediaRoot(), kind2);
  await mkdir(dir, { recursive: true });
  const name = `${randomUUID()}.${type.ext}`;
  await writeFile(join(dir, name), buf);
  return {
    url: `/media/${kind2}/${name}`,
    mime: type.mime,
    family: type.family,
    bytes: buf.length,
  };
}

/// 지우기. 우리가 만든 경로 형태(/media/<갈래>/<uuid>.<ext>)만 받는다 —
/// 임의 경로를 받으면 그것으로 서버의 아무 파일이나 지울 수 있다.
const URL_RE = /^\/media\/([a-z]+)\/([0-9a-f-]{36}\.[a-z0-9]{3,4})$/;
export async function deleteByUrl(url) {
  const m = URL_RE.exec(String(url ?? ''));
  if (!m || !KINDS.has(m[1])) return false;
  try {
    await unlink(join(mediaRoot(), m[1], m[2]));
    return true;
  } catch {
    // 이미 없으면 그것대로 목적은 이룬 것이다.
    return false;
  }
}
