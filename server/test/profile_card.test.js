// QR 나눔 — 명함 정리·공개 판정
//
// 여기서 틀리면 두 가지로 나타난다. 느슨하면 **꺼 둔 연락처가 새어 나가고**,
// 빡빡하면 멀쩡히 적은 아이디가 저장되지 않는다. 둘 다 조용하다.

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  applyJuniorLock,
  isJunior,
  isValidToken,
  newShareToken,
  normalizeEmail,
  normalizeHandle,
  normalizePhone,
  normalizePrayerTopics,
  publicCard,
  MAX_PRAYER_TOPICS,
} from '../src/services/profile_card.js';

describe('newShareToken', () => {
  test('주소에 넣을 수 있는 문자만 쓴다', () => {
    for (let i = 0; i < 20; i++) {
      const t = newShareToken();
      assert.ok(isValidToken(t), t);
      assert.equal(encodeURIComponent(t), t, t);
    }
  });

  test('매번 다르다', () => {
    const set = new Set(Array.from({ length: 50 }, newShareToken));
    assert.equal(set.size, 50);
  });

  test('아무 문자열이나 토큰으로 받지 않는다', () => {
    for (const bad of ['', 'short', '../../etc', 'a b c', null, undefined, 'a'.repeat(200)]) {
      assert.equal(isValidToken(bad), false, String(bad));
    }
  });
});

describe('normalizeHandle — 아이디만 남긴다', () => {
  test('사람들이 실제로 적는 여러 모양을 같은 값으로 만든다', () => {
    for (const raw of [
      'maria.f',
      '@maria.f',
      '  @maria.f  ',
      'instagram.com/maria.f',
      'https://instagram.com/maria.f',
      'https://www.instagram.com/maria.f',
      'https://www.instagram.com/maria.f?igshid=abc123',
      'https://instagram.com/maria.f/',
    ]) {
      assert.equal(normalizeHandle(raw), 'maria.f', raw);
    }
  });

  test('유튜브는 채널 경로도 받는다', () => {
    assert.equal(
      normalizeHandle('https://youtube.com/channel/UC12345', { allowSlash: true }),
      'channel/UC12345',
    );
    assert.equal(normalizeHandle('@MariaF', { allowSlash: true }), 'MariaF');
  });

  test('빈 값과 이상한 문자는 받지 않는다', () => {
    for (const bad of ['', '   ', '@', null, undefined, 42, '<script>', 'a b']) {
      assert.equal(normalizeHandle(bad), null, String(bad));
    }
  });
});

describe('normalizePhone', () => {
  test('숫자와 맨 앞 + 만 남긴다', () => {
    assert.equal(normalizePhone('+54 (11) 3456-7890'), '+541134567890');
    assert.equal(normalizePhone('011-3456-7890'), '01134567890');
  });

  test('길이가 말이 안 되면 받지 않는다', () => {
    for (const bad of ['123', '', '0123456789012345678', 'abc', null]) {
      assert.equal(normalizePhone(bad), null, String(bad));
    }
  });
});

describe('normalizeEmail', () => {
  test('소문자로 맞춘다', () => {
    assert.equal(normalizeEmail('  Maria@Example.COM '), 'maria@example.com');
  });
  test('형식이 아니면 받지 않는다', () => {
    for (const bad of ['maria', 'maria@', '@example.com', 'a@b', '', null]) {
      assert.equal(normalizeEmail(bad), null, String(bad));
    }
  });
});

describe('normalizePrayerTopics', () => {
  test('빈 줄을 버리고 세 개까지만 남긴다', () => {
    const r = normalizePrayerTopics(['가족', '  ', '캠퍼스', '', '건강', '넷째']);
    assert.deepEqual(r, ['가족', '캠퍼스', '건강']);
    assert.equal(r.length, MAX_PRAYER_TOPICS);
  });

  test('안 보냈으면 null — 기존 값을 건드리지 않는다', () => {
    assert.equal(normalizePrayerTopics(undefined), null);
    assert.equal(normalizePrayerTopics('가족'), null);
  });

  test('너무 긴 줄은 자른다', () => {
    const [t] = normalizePrayerTopics(['가'.repeat(500)]);
    assert.equal(t.length, 200);
  });
});

describe('주니어 잠금', () => {
  test('19세 이하는 연락을 켤 수 없다', () => {
    const on = {
      show_email: true, show_whatsapp: true, show_phone: true,
      show_instagram: true, show_x: true, show_youtube: true,
    };
    const locked = applyJuniorLock(on, 15);
    assert.equal(locked.show_email, false);
    assert.equal(locked.show_whatsapp, false);
    assert.equal(locked.show_phone, false);
    // 채널은 이미 공개된 계정이라 잠그지 않는다.
    assert.equal(locked.show_instagram, true);
    assert.equal(locked.show_youtube, true);
  });

  test('20세부터는 본인이 정한다', () => {
    const on = { show_email: true, show_phone: true };
    assert.deepEqual(applyJuniorLock(on, 20), on);
  });

  test('나이를 모르면 잠그지 않는다', () => {
    // 모른다고 잠그면 나이를 안 적은 어른이 아무것도 못 나눈다.
    const on = { show_email: true };
    for (const age of [null, undefined, NaN, 'twenty']) {
      assert.deepEqual(applyJuniorLock(on, age), on, String(age));
    }
  });

  test('경계는 19/20 이다', () => {
    assert.equal(isJunior(19), true);
    assert.equal(isJunior(20), false);
  });
});

describe('publicCard — 꺼 둔 항목은 아예 싣지 않는다', () => {
  const row = {
    photo_url: '/media/card/x.jpg',
    life_verse_ref: '요한복음 10:10',
    prayer_topics: ['가족'],
    email: 'a@b.com', whatsapp: '+541134567890', phone: '+541100000000',
    show_email: true, show_whatsapp: false, show_phone: false,
    instagram: 'maria.f', x_handle: 'mariaf', youtube: '@MariaF',
    show_instagram: true, show_x: false, show_youtube: false,
  };
  const who = { name: 'María', bibleName: 'Marta', country: 'BR', branch: 'SP' };

  test('켠 것만 나간다', () => {
    const c = publicCard(row, who);
    assert.deepEqual(c.contacts, { email: 'a@b.com' });
    assert.deepEqual(c.channels, { instagram: 'maria.f' });
  });

  test('값을 보내고 화면에서 감추지 않는다', () => {
    // 값이 응답에 실리면 화면을 거치지 않는 호출에 그대로 새어 나간다.
    const raw = JSON.stringify(publicCard(row, who));
    assert.ok(!raw.includes('+541134567890'), 'whatsapp 이 응답에 있다');
    assert.ok(!raw.includes('+541100000000'), 'phone 이 응답에 있다');
    assert.ok(!raw.includes('mariaf'), 'x 가 응답에 있다');
  });

  test('켠 항목이 하나도 없으면 빈 객체다', () => {
    const off = { ...row, show_email: false, show_instagram: false };
    const c = publicCard(off, who);
    assert.deepEqual(c.contacts, {});
    assert.deepEqual(c.channels, {});
    // 요절과 기도제목은 남는다 — 그것이 나눔의 기본이다.
    assert.equal(c.lifeVerseRef, '요한복음 10:10');
    assert.deepEqual(c.prayerTopics, ['가족']);
  });
});
