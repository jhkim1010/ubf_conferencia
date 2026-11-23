import { test } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';

import { verifyAppleToken, APPLE_ISSUER } from '../src/services/apple_token.js';

const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = { ...publicKey.export({ format: 'jwk' }), kid: 'k1', alg: 'RS256', use: 'sig' };
const fetchKeys = async () => [jwk];
const AUD = ['com.ubf.ubfApp'];

function sign(claims, opts = {}) {
  return jwt.sign(
    { sub: '001.abc', email: 'a@privaterelay.appleid.com', email_verified: 'true', ...claims },
    opts.key ?? privateKey,
    { algorithm: 'RS256', keyid: opts.kid ?? 'k1', issuer: opts.iss ?? APPLE_ISSUER,
      audience: opts.aud ?? 'com.ubf.ubfApp', expiresIn: opts.exp ?? '5m' },
  );
}

test('애플이 서명한 토큰을 받아 sub·email 을 꺼낸다', async () => {
  const r = await verifyAppleToken(sign({}), { audiences: AUD, fetchKeys });
  assert.deepEqual(r, { sub: '001.abc', email: 'a@privaterelay.appleid.com', emailVerified: true });
});

test('다른 앱(번들 ID)에 발급된 토큰은 받지 않는다', async () => {
  await assert.rejects(verifyAppleToken(sign({}, { aud: 'com.other.app' }), { audiences: AUD, fetchKeys }));
});

test('발급자가 애플이 아니면 받지 않는다', async () => {
  await assert.rejects(verifyAppleToken(sign({}, { iss: 'https://evil.example' }), { audiences: AUD, fetchKeys }));
});

test('다른 키로 서명한 토큰은 받지 않는다', async () => {
  const other = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 }).privateKey;
  await assert.rejects(verifyAppleToken(sign({}, { key: other }), { audiences: AUD, fetchKeys }));
});

test('모르는 kid 는 받지 않는다', async () => {
  await assert.rejects(verifyAppleToken(sign({}, { kid: 'nope' }), { audiences: AUD, fetchKeys }));
});

test('만료된 토큰은 받지 않는다', async () => {
  await assert.rejects(verifyAppleToken(sign({}, { exp: -10 }), { audiences: AUD, fetchKeys }));
});

test('email_verified 가 없으면 확인 안 된 것으로 본다', async () => {
  const r = await verifyAppleToken(sign({ email_verified: undefined }), { audiences: AUD, fetchKeys });
  assert.equal(r.emailVerified, false);
});
