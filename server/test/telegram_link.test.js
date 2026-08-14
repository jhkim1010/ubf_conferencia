import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  isValidLinkCode,
  readStart,
  collectLinks,
} from '../src/services/telegram_link.js';

// 여기서 틀리면 증상은 "연결했는데 아무 일도 안 일어난다" 하나뿐이고,
// 텔레그램이 무엇을 보냈는지는 볼 수 없다. 그래서 형태별로 못 박아 둔다.

const msg = (text, extra = {}) => ({
  update_id: 1,
  message: { chat: { id: 12345 }, text, ...extra },
});

test('코드 형식', () => {
  assert.equal(isValidLinkCode('0123456789'), true);
  assert.equal(isValidLinkCode('abcdef0123'), true);
  assert.equal(isValidLinkCode('SHORT'), false);
  assert.equal(isValidLinkCode('0123456789a'), false, '길면 안 된다');
  assert.equal(isValidLinkCode('012345678-'), false, '기호는 안 된다');
  assert.equal(isValidLinkCode(null), false);
});

test('/start 코드를 읽는다', () => {
  assert.deepEqual(readStart(msg('/start abcdef0123')), {
    code: 'abcdef0123',
    chatId: '12345',
  });
});

test('봇 이름이 붙어도 읽는다', () => {
  // 그룹에서 열면 `/start@mana_bot <code>` 로 온다.
  assert.deepEqual(readStart(msg('/start@mana_bot abcdef0123')), {
    code: 'abcdef0123',
    chatId: '12345',
  });
});

test('대문자로 와도 같은 코드다', () => {
  assert.equal(readStart(msg('/start ABCDEF0123'))?.code, 'abcdef0123');
});

test('코드 없는 /start 는 무시한다', () => {
  // 링크가 아니라 봇을 그냥 연 사람. 누구인지 알 방법이 없다.
  assert.equal(readStart(msg('/start')), null);
});

test('다른 말은 무시한다', () => {
  assert.equal(readStart(msg('안녕하세요')), null);
  assert.equal(readStart(msg('/help abcdef0123')), null);
  assert.equal(readStart(msg('/start abcdef0123 그리고 더')), null);
});

test('봇이 보낸 것은 무시한다', () => {
  assert.equal(
    readStart(msg('/start abcdef0123', { from: { is_bot: true } })),
    null,
  );
});

test('대화방이 없으면 무시한다', () => {
  assert.equal(readStart({ update_id: 1, message: { text: '/start abcdef0123' } }), null);
  assert.equal(readStart(null), null);
  assert.equal(readStart({}), null);
});

test('여러 개에서 뽑고 다음 자리를 알려 준다', () => {
  const updates = [
    { update_id: 10, message: { chat: { id: 1 }, text: '/start aaaaaaaaaa' } },
    { update_id: 11, message: { chat: { id: 2 }, text: '안녕' } },
    { update_id: 12, message: { chat: { id: 3 }, text: '/start bbbbbbbbbb' } },
  ];
  const { links, nextOffset } = collectLinks(updates);
  assert.equal(links.length, 2);
  assert.equal(nextOffset, 13, '가장 큰 update_id + 1');
});

test('같은 코드가 두 번 오면 나중 것', () => {
  // 링크를 두 번 눌렀다면 나중 대화방이 지금 열려 있는 쪽이다.
  const { links } = collectLinks([
    { update_id: 1, message: { chat: { id: 100 }, text: '/start aaaaaaaaaa' } },
    { update_id: 2, message: { chat: { id: 200 }, text: '/start aaaaaaaaaa' } },
  ]);
  assert.deepEqual(links, [{ code: 'aaaaaaaaaa', chatId: '200' }]);
});

test('아무것도 없으면 자리도 안 옮긴다', () => {
  // null 을 저장하면 offset 이 지워져 예전 것을 다시 받는다.
  assert.deepEqual(collectLinks([]), { links: [], nextOffset: null });
  assert.deepEqual(collectLinks(undefined), { links: [], nextOffset: null });
});

test('읽을 것이 없어도 자리는 옮긴다', () => {
  // 쓸모없는 메시지만 왔어도 그것들은 이미 봤다. 안 옮기면 영원히 다시 온다.
  const { links, nextOffset } = collectLinks([
    { update_id: 7, message: { chat: { id: 1 }, text: '안녕' } },
  ]);
  assert.equal(links.length, 0);
  assert.equal(nextOffset, 8);
});
