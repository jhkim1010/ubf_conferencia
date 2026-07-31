#!/usr/bin/env bash
# ubf.coolsistema.com 배포
#
#   ./deploy.sh              웹 + API 배포
#   ./deploy.sh --web        웹만
#   ./deploy.sh --api        API 만
#   ./deploy.sh --check      현재 배포 상태만 확인
#
# 전제: SSH 키로 deploy@62.72.7.245 접속 가능, 서버 초기 설정 완료
#       (초기 설정은 deploy/bootstrap.sh 참조 — 한 번만 실행)
#
# 이 서버에는 다른 서비스가 여럿 돌고 있다. 이 스크립트는 /srv/ubf 와
# ubf-api 서비스, ubf vhost 만 다루며 그 밖은 건드리지 않는다.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/opt/homebrew/bin:$PATH"

HOST="${UBF_HOST:-deploy@62.72.7.245}"
REMOTE=/srv/ubf
DOMAIN=ubf.coolsistema.com

DO_WEB=1; DO_API=1; CHECK_ONLY=0
for a in "$@"; do
  case "$a" in
    --web)   DO_API=0 ;;
    --api)   DO_WEB=0 ;;
    --check) CHECK_ONLY=1 ;;
  esac
done

say() { echo "▸ $1"; }

status() {
  ssh -o BatchMode=yes "$HOST" '
    echo "  API   : $(systemctl is-active ubf-api 2>/dev/null)"
    echo "  health: $(curl -s --max-time 3 http://127.0.0.1:3100/health || echo 실패)"
    echo "  웹    : $(ls /srv/ubf/web/main.dart.js 2>/dev/null >/dev/null && stat -c %y /srv/ubf/web/main.dart.js | cut -d. -f1 || echo 없음)"
  '
  echo "  공개  : $(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "https://$DOMAIN/" 2>/dev/null)"
  echo "  API공개: $(curl -s --max-time 8 "https://$DOMAIN/api/health" 2>/dev/null)"
}

if [ "$CHECK_ONLY" = "1" ]; then say "현재 상태"; status; exit 0; fi

# ── 웹 ────────────────────────────────────────────────────────
# API_BASE_URL 을 /api 로 박는다. 같은 도메인이라 상대 경로면 충분하고
# CORS 도 필요 없다. 기본값(localhost:3000)으로 빌드하면 사용자 브라우저가
# 자기 PC 를 호출해 아무것도 동작하지 않는다.
#
# --pwa-strategy=none: 서비스 워커를 만들지 않는다. 배포 후 코드를 고쳐도
# 브라우저가 옛 번들을 계속 보여주는 문제를 원천 차단한다.
if [ "$DO_WEB" = "1" ]; then
  say "웹 빌드 (API_BASE_URL=/api, 서비스 워커 없음)"
  ( cd "$ROOT/ubf_app" && flutter build web --release \
      --pwa-strategy=none \
      --dart-define=API_BASE_URL=/api ) || exit 1

  say "웹 전송"
  rsync -az --delete -e ssh "$ROOT/ubf_app/build/web/" "$HOST:$REMOTE/web/" || exit 1
fi

# ── API ───────────────────────────────────────────────────────
if [ "$DO_API" = "1" ]; then
  say "API 전송"
  # .env 는 서버에만 있고 전송하지 않는다. node_modules 도 서버에서 설치한다.
  rsync -az --delete \
    --exclude node_modules --exclude .env --exclude '.env.*' \
    -e ssh "$ROOT/server/" "$HOST:$REMOTE/api/" || exit 1

  say "의존성 설치 + 재시작"
  ssh -o BatchMode=yes "$HOST" '
    cd /srv/ubf/api && npm ci --omit=dev --silent 2>&1 | tail -3
    sudo systemctl restart ubf-api
    sleep 3
  ' || exit 1
fi

echo ""
say "결과"
status
echo ""
echo "  https://$DOMAIN"
