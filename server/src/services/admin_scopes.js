// 공동 관리자가 맡은 분야 — 순수 부분.
//
// **여기에는 DB 를 부르지 않는다.** auth.js 는 db.js 를 불러오고, db.js 는
// 불러오는 순간 DATABASE_URL 을 요구한다. 그래서 이 목록을 auth.js 에 두면
// 단위 테스트가 DB 없이는 뜨지 못하고, .env 가 있는 개발자 기계에서만
// 통과한다 — CI 에서는 처음부터 끝까지 빨간불이었다.

// 이름은 화면이 갈라지는 자리를 따라 지었다. 라우트마다 requireScope 로
// 어느 분야인지 적어야 하고, **안 적으면 검사가 막는다**(admin_scopes.test.js)
// — 안 적힌 라우트는 조용히 아무나 통과하기 때문이다.
export const SCOPES = [
  'transport',    // 픽업·교통·배차
  'rooms',        // 숙소
  'groups',       // 말씀공부 조
  'ledger',       // 장부·참가비
  'service',      // 봉사
  'registration', // 등록·명단
  'comms',        // 공지·자료실
  'schedule',     // 일정
  'medical',      // 의료·안전(SOS·질병 정보)
];

/// 이 사람이 이 수양회에서 맡은 분야.
/// null = 전부 · false = 권한 없음 · 배열 = 그 분야만.
export function requireScope(...needed) {
  return (req, res, next) => {
    const mine = req.adminScopes;
    if (mine === null || mine === undefined) return next(); // 전부
    if (needed.some((n) => mine.includes(n))) return next();
    return res.status(403).json({ error: '이 분야는 맡지 않으셨습니다' });
  };
}
