import { Router } from 'express';
import express from 'express';
import { requireAuth } from '../middleware/auth.js';
import {
  decodeBase64,
  mediaRoot,
  saveFile,
  MAX_IMAGE_BYTES,
  MAX_PDF_BYTES,
} from '../services/media_store.js';

const router = Router();

// POST /media?kind=program|card|library — 파일 하나 올리기 (사진 또는 PDF)
//
// 본문은 **바이트 그대로**다(application/octet-stream).
// base64 로 받으면 33% 가 부풀어, 교재 PDF 같은 큰 파일에서 손해가 크다.
// multipart 를 쓰지 않는 이유는 의존성(multer)을 하나 덜 들이기 위해서다.
//
// 예전 방식(JSON + base64)도 그대로 받는다 — 이미 그렇게 보내는 화면이
// 생기면 한쪽만 고치다 조용히 깨진다.
//
// 로그인한 사람만 올릴 수 있다. 누구나 올릴 수 있으면 이 서버는 남의 파일
// 창고가 된다.
router.post(
  '/',
  requireAuth,
  express.raw({ type: 'application/octet-stream', limit: '16mb' }),
  async (req, res) => {
  try {
    const buf = Buffer.isBuffer(req.body) && req.body.length > 0
      ? req.body
      : decodeBase64(req.body?.data);
    if (!buf) return res.status(400).json({ error: '파일 데이터가 없습니다' });

    const saved = await saveFile(buf, req.query?.kind ?? req.body?.kind);
    res.status(201).json(saved);
  } catch (err) {
    if (err.message === 'UNSUPPORTED_TYPE') {
      // 내용의 첫 바이트로 판단한다. 확장자만 .jpg 인 파일은 여기서 걸린다.
      return res
        .status(415)
        .json({ error: 'JPEG·PNG·WebP 사진 또는 PDF 만 올릴 수 있습니다' });
    }
    if (err.message === 'TOO_LARGE') {
      return res.status(413).json({
        error:
          `파일이 너무 큽니다 (사진 ${Math.round(MAX_IMAGE_BYTES / 1000)}KB · ` +
          `PDF ${Math.round(MAX_PDF_BYTES / 1_000_000)}MB 까지)`,
      });
    }
    console.error('파일 업로드 오류:', err);
    res.status(500).json({ error: '서버 오류' });
  }
  },
);

// 개발 중에는 이 서버가 직접 /media 를 내보낸다.
//
// 운영에서는 nginx 가 맡는다(deploy/nginx-ubf.conf). 여기 두는 이유는
// serve-web.sh 로 로컬 확인할 때 사진이 안 보이면 기능을 확인할 수 없기
// 때문이다. 운영에서는 nginx 가 먼저 잡으므로 이 경로까지 오지 않는다.
export const mediaStatic = express.static(mediaRoot(), {
  index: false,
  maxAge: '30d',
  setHeaders: (res) => {
    // 업로드된 파일이 브라우저에서 다른 타입으로 해석되지 않게 한다.
    res.setHeader('X-Content-Type-Options', 'nosniff');
  },
});

export default router;
