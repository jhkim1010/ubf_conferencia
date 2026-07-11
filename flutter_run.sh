#!/usr/bin/env zsh
# Flutter 디버그 실행 + 로그 자동 저장 스크립트
# 사용법:
#   ./flutter_run.sh               # 디바이스 자동 선택
#   ./flutter_run.sh -d chrome     # 특정 디바이스 지정
#   ./flutter_run.sh -d macos      # macOS 앱
#   ./flutter_run.sh --release     # 릴리즈 모드

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/ubf_app"
LOG_DIR="$SCRIPT_DIR/logs"

# logs 폴더 생성
mkdir -p "$LOG_DIR"

# 타임스탬프 기반 로그 파일명
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
LOG_FILE="$LOG_DIR/flutter_${TIMESTAMP}.log"
LATEST_LINK="$LOG_DIR/latest.log"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  UBF Flutter 디버그 실행"
echo "  로그 파일: logs/flutter_${TIMESTAMP}.log"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# latest.log 심볼릭 링크 갱신 (항상 마지막 로그를 가리킴)
ln -sf "$LOG_FILE" "$LATEST_LINK"

# flutter run 실행 — stdout/stderr 동시에 화면 출력 + 파일 저장
cd "$APP_DIR"
flutter run "$@" 2>&1 | tee "$LOG_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  실행 종료. 로그 저장됨: $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
