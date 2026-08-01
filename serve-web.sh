#!/usr/bin/env bash
# 로컬 웹 검증용 — 빌드 + 서버 기동을 한 번에.
#
# 사용법:
#   ./serve-web.sh              stage DB 로 API + 웹 기동
#   ./serve-web.sh --no-build   빌드 없이 서버만 (이미 빌드돼 있을 때)
#   ./serve-web.sh --prod-db    운영 DB 사용 (기본은 stage)
#
# DB 파일은 셋이다. **기본값은 반드시 stage 여야 한다** —
# 한동안 .env.stage 가 실제 운영 DB 를 가리키고 있었고, 그래서 e2e 검증이
# 운영 데이터에 찌꺼기를 남겼다.
#
#   server/.env        stage  (npm run dev 기본값도 여기)
#   server/.env.stage  stage
#   server/.env.prod   운영. --prod-db 로 명시할 때만
#
# 이 스크립트는 **로컬 검증 전용**이다. 릴리스 빌드는 .github/workflows/
# build-release.yml 이 담당하며 그쪽은 건드리지 않는다.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$ROOT/ubf_app"
SRV="$ROOT/server"
export PATH="/opt/homebrew/bin:$PATH"

# 포트는 고정이다. 바꾸지 말 것 —
# 구글 OAuth 는 승인된 JavaScript 원본을 origin(포트 포함) 단위로 검사한다.
# Google Cloud Console 에 http://localhost:8080 만 등록돼 있어 다른 포트로
# 띄우면 로그인이 400 origin_mismatch 로 막힌다.
WEB_PORT=8080
API_PORT=3000

BUILD=1
DB_FILE=".env.stage"
for a in "$@"; do
  case "$a" in
    --no-build) BUILD=0 ;;
    --prod-db)  DB_FILE=".env.prod" ;;
  esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  로컬 웹 검증 환경"
echo "  DB: server/$DB_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$SRV/$DB_FILE" ]; then
  echo "✗ $SRV/$DB_FILE 이 없습니다."
  exit 1
fi

# ── 웹 빌드 ───────────────────────────────────────────────
# --pwa-strategy=none 이 핵심이다. 기본 빌드는 서비스 워커를 등록해
# 예전 번들을 캐시하므로, 코드를 고쳐 다시 빌드해도 브라우저가 옛 화면을
# 계속 보여준다. 실제로 이 함정에 빠져 한참을 헤맸다.
if [ "$BUILD" = "1" ]; then
  echo "▸ 웹 빌드 (서비스 워커 없음)"
  ( cd "$APP" && flutter build web --release --pwa-strategy=none ) || exit 1
fi

# ── API 서버 ──────────────────────────────────────────────
pkill -f 'node src/index.js' 2>/dev/null
sleep 1
DB_URL="$(grep '^DATABASE_URL=' "$SRV/$DB_FILE" | cut -d= -f2-)"
# 자식이 이 스크립트의 stdout 파이프를 잡고 있으면 스크립트가 끝나도
# 호출한 쪽이 EOF 를 못 받아 멈춘 것처럼 보인다. stdio 를 전부 끊는다.
( cd "$SRV" && nohup env \
    DATABASE_URL="$DB_URL" \
    PORT="$API_PORT" \
    NODE_ENV=development \
    ENABLE_DEV_LOGIN=1 \
    ALLOWED_ORIGINS="http://localhost:$WEB_PORT,http://127.0.0.1:$WEB_PORT" \
    node src/index.js > /tmp/ubf-api.log 2>&1 ) </dev/null >/dev/null 2>&1 &
sleep 4

# ── 웹 서버 ───────────────────────────────────────────────
pkill -f "http.server $WEB_PORT" 2>/dev/null
sleep 1
( cd "$APP/build/web" && nohup python3 -m http.server "$WEB_PORT" --bind 127.0.0.1 \
    > /tmp/ubf-web.log 2>&1 ) </dev/null >/dev/null 2>&1 &
sleep 2

echo ""
api_ok=$(curl -s --max-time 3 "http://localhost:$API_PORT/health" || echo "")
web_ok=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://localhost:$WEB_PORT/" || echo "")
[ -n "$api_ok" ] && echo "  ✓ API  http://localhost:$API_PORT  $api_ok" \
                 || echo "  ✗ API 기동 실패 — /tmp/ubf-api.log 확인"
[ "$web_ok" = "200" ] && echo "  ✓ 웹   http://localhost:$WEB_PORT" \
                      || echo "  ✗ 웹 기동 실패 — /tmp/ubf-web.log 확인"

sw=$(curl -s "http://localhost:$WEB_PORT/flutter_service_worker.js" 2>/dev/null | wc -c | tr -d ' ')
[ "$sw" = "0" ] && echo "  ✓ 서비스 워커 없음 (캐시 문제 없음)" \
                || echo "  ⚠ 서비스 워커가 남아 있습니다 ($sw 바이트) — --pwa-strategy=none 확인"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  http://localhost:$WEB_PORT 에서 확인하십시오."
echo ""
echo "  이전 방문에서 서비스 워커가 남아 있다면 한 번만 콘솔(F12)에서:"
echo "    (async()=>{for(const r of await navigator.serviceWorker.getRegistrations())await r.unregister();for(const k of await caches.keys())await caches.delete(k);location.reload()})()"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
