// Apple 로 로그인 — 아이폰이 건네는 identityToken 검증 (2026-11)
//
// 애플 심사 지침 4.8: 구글 로그인만 있는 앱은 "Apple 로 로그인" 도 함께
// 내야 한다. 아이폰은 애플이 서명한 JWT(identityToken) 를 준다. 애플의
// 공개키(JWKS)로 서명을 확인하고, 발급자·대상(우리 번들 ID)·만료를 본다.
//
// 키 목록을 가져오는 일(fetchKeys)은 밖에서 넣는다 — 테스트가 네트워크
// 없이 돌게 하려는 것이다(test/apple_token.test.js).

import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';

export const APPLE_ISSUER = 'https://appleid.apple.com';
const KEYS_URL = 'https://appleid.apple.com/auth/keys';

let cache = { at: 0, keys: [] };

async function defaultFetchKeys() {
  // 애플은 키를 가끔 바꾼다. 한 시간 넘게 묵은 목록은 다시 받는다.
  if (Date.now() - cache.at < 60 * 60 * 1000 && cache.keys.length) return cache.keys;
  const res = await fetch(KEYS_URL);
  if (!res.ok) throw new Error(`apple keys ${res.status}`);
  const { keys } = await res.json();
  cache = { at: Date.now(), keys };
  return keys;
}

/// 맞으면 { sub, email, emailVerified } 를, 틀리면 예외를 던진다.
///
/// audiences: 받아 줄 번들 ID 들(아이폰 앱, 맥 앱).
export async function verifyAppleToken(identityToken, { audiences, fetchKeys = defaultFetchKeys }) {
  if (!audiences?.length) throw new Error('APPLE_BUNDLE_IDS 가 비어 있습니다');
  const decoded = jwt.decode(identityToken, { complete: true });
  if (!decoded?.header?.kid) throw new Error('토큰 형식이 아닙니다');

  let keys = await fetchKeys();
  let jwk = keys.find((k) => k.kid === decoded.header.kid);
  if (!jwk && fetchKeys === defaultFetchKeys) {
    // 애플이 방금 키를 바꿨을 수 있다. 한 번만 새로 받는다.
    cache.at = 0;
    keys = await fetchKeys();
    jwk = keys.find((k) => k.kid === decoded.header.kid);
  }
  if (!jwk) throw new Error('맞는 애플 키가 없습니다');

  const publicKey = crypto.createPublicKey({ key: jwk, format: 'jwk' });
  const payload = jwt.verify(identityToken, publicKey, {
    algorithms: ['RS256'],
    issuer: APPLE_ISSUER,
    audience: audiences,
  });
  if (!payload.sub) throw new Error('sub 가 없습니다');
  return {
    sub: payload.sub,
    email: payload.email ?? null,
    // 애플은 문자열 "true" 로 줄 때도 있다.
    emailVerified: payload.email_verified === true || payload.email_verified === 'true',
  };
}
