// 참가자 텔레그램 연결 (047) — 순수 로직
//
// 텔레그램에서 돌아오는 것을 해석하는 부분만 여기 둔다. DB 도 네트워크도
// 없으므로 테스트할 수 있다. 실제로 여기서 틀리면 "연결했는데 아무 일도
// 안 일어나는" 증상이 되고, 그때는 어디가 잘못됐는지 알아내기가 어렵다.

/// 연결 코드. 짧으면 남의 코드를 맞힐 수 있고, 길면 사람이 옮겨 적지
/// 못한다 — 링크로 열리므로 옮겨 적을 일은 없지만, 그래도 눈에 보인다.
const CODE_RE = /^[a-z0-9]{10}$/;

export function isValidLinkCode(v) {
  return typeof v === 'string' && CODE_RE.test(v);
}

/// `/start <code>` 하나를 읽는다.
///
/// 텔레그램은 `/start` 만 오는 경우(버튼 없이 봇을 연 사람), 다른 명령,
/// 봇 자신이 보낸 것, 편집된 메시지 등 여러 가지를 준다. 코드가 붙은
/// `/start` 만 쓴다.
///
/// 반환: { code, chatId } 또는 null
export function readStart(update) {
  const msg = update?.message ?? update?.edited_message;
  const text = typeof msg?.text === 'string' ? msg.text.trim() : '';
  const chatId = msg?.chat?.id;
  if (chatId == null) return null;
  // 봇끼리 주고받는 것은 무시한다.
  if (msg?.from?.is_bot === true) return null;

  // `/start코드` 는 없다. 반드시 빈칸으로 나뉜다. 봇 이름이 붙는
  // `/start@my_bot <code>` 형태도 실제로 온다.
  const m = text.match(/^\/start(?:@\S+)?\s+(\S+)$/);
  if (!m) return null;

  const code = m[1].toLowerCase();
  if (!isValidLinkCode(code)) return null;
  return { code, chatId: String(chatId) };
}

/// 여러 update 에서 연결할 것들을 뽑는다.
///
/// 같은 코드가 여러 번 오면 **마지막 것**을 쓴다 — 사람이 링크를 두 번
/// 눌렀다면 나중 대화방이 지금 열려 있는 쪽이다.
///
/// 반환: { links: [{code, chatId}], nextOffset }
///
/// nextOffset 은 **본 것 중 가장 큰 update_id + 1** 이다. 이것을 저장하지
/// 않으면 같은 update 를 계속 다시 받는다.
export function collectLinks(updates) {
  const byCode = new Map();
  let maxId = null;
  for (const u of updates ?? []) {
    if (typeof u?.update_id === 'number') {
      maxId = maxId == null ? u.update_id : Math.max(maxId, u.update_id);
    }
    const hit = readStart(u);
    if (hit) byCode.set(hit.code, hit);
  }
  return {
    links: [...byCode.values()],
    nextOffset: maxId == null ? null : maxId + 1,
  };
}
