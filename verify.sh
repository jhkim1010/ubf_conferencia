#!/usr/bin/env bash
# ubf_conferencia 검증 진입점
#
# 검사는 잘게 나뉘어 있고 각각 독립 실행 가능하다. 훅(PostToolUse / Stop / pre-commit)에서
# 필요한 검사만 골라 거는 것을 전제로 설계했다.
#
#   ./verify.sh                    전체 실행 (실패가 있어도 끝까지 돌고 마지막에 요약)
#   ./verify.sh arb-parity         특정 검사만
#   ./verify.sh route-parity server-syntax
#   ./verify.sh --list             검사 목록
#   ./verify.sh --changed          변경된 파일에 해당하는 검사만 (훅용)
#
# 종료 코드: 0=전부 통과, 1=하나 이상 실패
# SKIP(전제 미충족)은 실패로 치지 않지만 요약에 별도 표시한다.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$ROOT/ubf_app"
SRV="$ROOT/server"
MIGRATIONS="$APP/supabase/migrations"

# flutter/node 는 /opt/homebrew/bin 에 있다. 비로그인 셸 대비.
export PATH="/opt/homebrew/bin:$PATH"

if [ -t 1 ]; then
  R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[1m'; N=$'\033[0m'
else
  R=''; G=''; Y=''; B=''; N=''
fi

PASSED=(); FAILED=(); SKIPPED=()

pass() { PASSED+=("$1"); printf '%s✓%s %s\n' "$G" "$N" "$1"; }
fail() { FAILED+=("$1"); printf '%s✗%s %s\n' "$R" "$N" "$1"; [ $# -gt 1 ] && printf '    %s\n' "$2"; }
skip() { SKIPPED+=("$1"); printf '%s–%s %s (%s)\n' "$Y" "$N" "$1" "${2:-전제 미충족}"; }

# ─────────────────────────────────────────────────────────────
# 검사 정의. 함수명 규칙: check_<이름>  (하이픈은 밑줄로)
# ─────────────────────────────────────────────────────────────

# Flutter 정적 분석. 경고 1건이라도 있으면 실패.
check_flutter_analyze() {
  command -v flutter >/dev/null || { skip flutter-analyze "flutter 없음"; return 0; }
  local out
  out="$(cd "$APP" && flutter analyze --no-pub 2>&1)"
  if printf '%s' "$out" | grep -qE 'No issues found'; then
    pass flutter-analyze
  else
    fail flutter-analyze "$(printf '%s' "$out" | grep -E '^\s+(error|warning|info)' | head -5)"
  fi
}

# 변경된 Dart 파일만 포맷 검사.
# 저장소 전체는 아직 dart format 기준을 만족하지 않으므로(47개 중 40개) 전체 검사는 하지 않는다.
# 새로 건드리는 파일만 기준을 지키게 해서 점진적으로 수렴시킨다.
check_dart_format() {
  command -v dart >/dev/null || { skip dart-format "dart 없음"; return 0; }
  local files
  files="$(changed_files | grep -E '^ubf_app/.*\.dart$' | grep -v '/l10n/app_localizations' || true)"
  [ -z "$files" ] && { skip dart-format "변경된 dart 파일 없음"; return 0; }
  local bad
  bad="$(cd "$ROOT" && echo "$files" | xargs dart format --output=none --set-exit-if-changed 2>&1 | grep '^Changed' || true)"
  if [ -z "$bad" ]; then
    pass dart-format
  else
    fail dart-format "$(echo "$bad" | head -5)"
  fi
}

# 서버 JS 구문 검사. 테스트가 없는 만큼 최소한 파싱은 보장한다.
check_server_syntax() {
  command -v node >/dev/null || { skip server-syntax "node 없음"; return 0; }
  local bad=""
  while IFS= read -r f; do
    node --check "$f" 2>/dev/null || bad="$bad$f"$'\n'
  done < <(find "$SRV/src" -name '*.js' -not -path '*/node_modules/*')
  if [ -z "$bad" ]; then
    pass server-syntax
  else
    fail server-syntax "$(printf '%s' "$bad" | head -5)"
  fi
}

# ARB 3개 파일의 키 집합 일치 검사.
# @-접두 키(메타데이터·@@locale)는 로케일마다 다르므로 비교 대상에서 제외한다.
check_arb_parity() {
  command -v jq >/dev/null || { skip arb-parity "jq 없음"; return 0; }
  local en ko es diff_ko diff_es
  en="$(jq -r 'keys[]|select(startswith("@")|not)' "$APP/lib/l10n/app_en.arb" | sort)"
  ko="$(jq -r 'keys[]|select(startswith("@")|not)' "$APP/lib/l10n/app_ko.arb" | sort)"
  es="$(jq -r 'keys[]|select(startswith("@")|not)' "$APP/lib/l10n/app_es.arb" | sort)"
  diff_ko="$(diff <(echo "$en") <(echo "$ko") | grep -E '^[<>]' || true)"
  diff_es="$(diff <(echo "$en") <(echo "$es") | grep -E '^[<>]' || true)"
  if [ -z "$diff_ko" ] && [ -z "$diff_es" ]; then
    pass arb-parity
  else
    local msg=""
    [ -n "$diff_ko" ] && msg="ko 불일치: $(echo "$diff_ko" | head -3 | tr '\n' ' ')"
    [ -n "$diff_es" ] && msg="$msg / es 불일치: $(echo "$diff_es" | head -3 | tr '\n' ' ')"
    fail arb-parity "$msg  (< 는 en 에만, > 는 해당 로케일에만 존재)"
  fi
}

# routes/*.js 와 index.js 의 app.use 등록 정합성.
# 등록을 빠뜨리면 서버는 정상 기동하고 해당 경로만 조용히 404 가 된다.
check_route_parity() {
  local files mounted missing
  files="$(ls "$SRV/src/routes" | sed 's/\.js$//' | tr '_' '-' | sort)"
  mounted="$(grep -oE "app\.use\('/[a-z-]+'" "$SRV/src/index.js" | grep -oE "/[a-z-]+" | tr -d '/' | sort)"
  missing="$(comm -23 <(echo "$files") <(echo "$mounted"))"
  if [ -z "$missing" ]; then
    pass route-parity
  else
    fail route-parity "index.js 에 app.use 등록 누락: $(echo "$missing" | tr '\n' ' ')"
  fi
}

# 마이그레이션 번호 중복 검사.
# migrate.js 는 파일명 정렬 순으로 실행하므로 번호가 겹치면 적용 순서가 모호해진다.
check_migration_numbers() {
  local dups
  dups="$(ls "$MIGRATIONS" | grep -oE '^[0-9]+' | sort | uniq -d)"
  if [ -z "$dups" ]; then
    pass migration-numbers
  else
    fail migration-numbers "번호 중복: $(echo "$dups" | tr '\n' ' ') — 새 파일은 사용되지 않은 다음 번호를 쓸 것"
  fi
}

# 마이그레이션 안전성 정적 검사.
# migrate.js 는 적용 이력을 추적하지 않아 매 실행마다 전체를 재적용한다.
# 따라서 비멱등·파괴적 구문은 두 번째 실행에서 데이터를 파괴한다.
check_migration_safety() {
  local offenders="" f body base hit
  # 부정 선읽기 (?!) 는 PCRE 전용이라 grep -E 에서 쓸 수 없다.
  # "후보를 뽑고 → 안전 표현이 없는 것만 남긴다" 2단계로 처리한다.
  # \s 대신 POSIX 클래스를 쓴다 (BSD grep 호환).
  for f in "$MIGRATIONS"/*.sql; do
    base="$(basename "$f")"
    body="$(grep -vE '^[[:space:]]*--' "$f")"

    hit="$(printf '%s\n' "$body" | grep -iE 'CREATE[[:space:]]+TABLE' \
           | grep -viE 'IF[[:space:]]+NOT[[:space:]]+EXISTS' | head -1)"
    [ -n "$hit" ] && offenders="$offenders$base: CREATE TABLE 에 IF NOT EXISTS 없음 — $(echo "$hit" | cut -c1-60)"$'\n'

    hit="$(printf '%s\n' "$body" | grep -iE 'DROP[[:space:]]+(COLUMN|TABLE|TYPE|INDEX)' \
           | grep -viE 'IF[[:space:]]+EXISTS' | head -1)"
    [ -n "$hit" ] && offenders="$offenders$base: DROP 에 IF EXISTS 없음 — $(echo "$hit" | cut -c1-60)"$'\n'

    # 파괴적 구문: 재실행되면 데이터가 사라진다
    hit="$(printf '%s\n' "$body" | grep -iE 'DROP[[:space:]]+COLUMN' | head -1)"
    [ -n "$hit" ] && offenders="$offenders$base: DROP COLUMN 은 재실행 시 데이터 손실 — $(echo "$hit" | cut -c1-60)"$'\n'

    hit="$(printf '%s\n' "$body" | grep -iE '^[[:space:]]*DELETE[[:space:]]+FROM' \
           | grep -viE 'WHERE' | head -1)"
    [ -n "$hit" ] && offenders="$offenders$base: WHERE 없는 DELETE — $(echo "$hit" | cut -c1-60)"$'\n'

    hit="$(printf '%s\n' "$body" | grep -iE '^[[:space:]]*UPDATE[[:space:]]+[a-z_]+[[:space:]]+SET' \
           | grep -viE 'WHERE' | head -1)"
    [ -n "$hit" ] && offenders="$offenders$base: WHERE 없는 UPDATE — $(echo "$hit" | cut -c1-60)"$'\n'
  done
  if [ -z "$offenders" ]; then
    pass migration-safety
  else
    fail migration-safety "$(printf '%s' "$offenders" | head -6)"
  fi
}

# 비밀정보 유출 검사. 추적 중인 파일에 커넥션 문자열이나 .env 가 들어갔는지 본다.
check_secrets() {
  local hits=""
  git -C "$ROOT" ls-files | grep -E '(^|/)\.env($|\.)' | head -3 \
    | while read -r f; do echo "추적 중인 .env: $f"; done > /tmp/.vsec1 2>/dev/null || true
  hits="$(cat /tmp/.vsec1 2>/dev/null || true)"; rm -f /tmp/.vsec1
  local urls
  urls="$(git -C "$ROOT" grep -nIE 'postgres(ql)?://[^ "'"'"'\)]*:[^ @"'"'"']+@' -- \
          ':!*.md' ':!.claude/*' ':!.team/*' 2>/dev/null | head -3 || true)"
  [ -n "$urls" ] && hits="$hits$urls"
  if [ -z "$hits" ]; then
    pass secrets
  else
    fail secrets "$(printf '%s' "$hits" | head -4)"
  fi
}

# 생성물 취급 검사.
#
# app_localizations*.dart 는 이 저장소가 의도적으로 커밋한다(빌드에서 gen-l10n 없이 쓰기 위함).
# 따라서 "추적된다"는 사실 자체는 문제가 아니다. 진짜 실패 모드는 손으로 편집하는 것이므로,
# ARB 변경 없이 생성물만 바뀐 경우를 잡는다.
check_artifacts() {
  local tracked handedit
  tracked="$(git -C "$ROOT" ls-files | grep -E '(/build/|\.dart_tool/)' | head -5 || true)"
  if [ -n "$tracked" ]; then
    fail artifacts "빌드 산출물이 추적되고 있음: $(echo "$tracked" | tr '\n' ' ')"
    return 0
  fi

  local ch; ch="$(changed_files)"
  if grep -qE '^ubf_app/lib/l10n/app_localizations.*\.dart$' <<<"$ch" \
     && ! grep -qE '^ubf_app/lib/l10n/.*\.arb$' <<<"$ch"; then
    handedit="$(grep -E '^ubf_app/lib/l10n/app_localizations.*\.dart$' <<<"$ch" | tr '\n' ' ')"
    fail artifacts "ARB 변경 없이 생성물이 수정됨(손편집 의심): $handedit — .arb 를 고치고 flutter gen-l10n 을 실행할 것"
    return 0
  fi
  pass artifacts
}

# 서버 기동 스모크. DATABASE_URL 이 있어야 하므로 CI 에서는 보통 SKIP 된다.
check_server_smoke() {
  command -v node >/dev/null || { skip server-smoke "node 없음"; return 0; }
  [ -f "$SRV/.env" ] || [ -n "${DATABASE_URL:-}" ] || { skip server-smoke "DATABASE_URL 없음"; return 0; }
  [ -d "$SRV/node_modules" ] || { skip server-smoke "node_modules 없음 (npm install 필요)"; return 0; }

  local port=${SMOKE_PORT:-3999} log=/tmp/ubf-smoke.$$ pid
  # dotenv 는 .env 를 cwd 기준으로 찾는다. 반드시 server/ 에서 기동해야 한다.
  # exec 로 서브셸을 node 로 치환한다 — 그래야 $! 가 node 자신의 PID 가 되어
  # kill 이 실제로 서버를 종료시킨다(서브셸만 죽이면 node 가 남는다).
  ( cd "$SRV" && PORT=$port exec node src/index.js ) >"$log" 2>&1 &
  pid=$!
  local ok=""
  for _ in $(seq 1 25); do
    if curl -sf --max-time 1 "http://127.0.0.1:$port/health" >/dev/null 2>&1; then ok=1; break; fi
    kill -0 $pid 2>/dev/null || break
    sleep 0.4
  done
  kill $pid 2>/dev/null; wait $pid 2>/dev/null
  if [ -n "$ok" ]; then
    pass server-smoke
    rm -f "$log"
  else
    fail server-smoke "기동 실패 또는 /health 무응답: $(tail -3 "$log" | tr '\n' ' ')"
    rm -f "$log"
  fi
}

# ─────────────────────────────────────────────────────────────

ALL_CHECKS=(
  flutter-analyze
  dart-format
  server-syntax
  arb-parity
  route-parity
  migration-numbers
  migration-safety
  secrets
  artifacts
  server-smoke
)

# 변경 파일 목록.
#
# 기본은 로컬 작업 기준 — HEAD 대비 워킹트리 + 스테이지 + 미추적 파일.
# CI 처럼 워킹트리가 깨끗한 환경에서는 이 목록이 비어 변경분 검사가 무의미하게 통과한다.
# 그래서 VERIFY_BASE 가 주어지면 그 커밋 대비 diff 를 쓴다 (예: VERIFY_BASE=origin/main).
changed_files() {
  if [ -n "${VERIFY_BASE:-}" ]; then
    git -C "$ROOT" diff --name-only "$VERIFY_BASE"...HEAD 2>/dev/null && return 0
    printf '기준 ref 를 찾을 수 없음: %s\n' "$VERIFY_BASE" >&2
    return 0
  fi
  {
    git -C "$ROOT" diff --name-only HEAD 2>/dev/null
    git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null
  } | sort -u
}

# --changed: 변경 파일에 해당하는 검사만 고른다. 훅에서 쓰는 모드.
select_by_changes() {
  local files sel=()
  files="$(changed_files)"
  [ -z "$files" ] && return 0
  grep -qE '^ubf_app/.*\.dart$'            <<<"$files" && sel+=(flutter-analyze dart-format)
  grep -qE '^ubf_app/lib/l10n/.*\.arb$'    <<<"$files" && sel+=(arb-parity)
  grep -qE '^server/src/.*\.js$'           <<<"$files" && sel+=(server-syntax route-parity server-smoke)
  grep -qE '^ubf_app/supabase/migrations/' <<<"$files" && sel+=(migration-numbers migration-safety)
  sel+=(secrets artifacts)
  printf '%s\n' "${sel[@]}" | awk '!seen[$0]++'
}

run_check() {
  local fn="check_${1//-/_}"
  if declare -F "$fn" >/dev/null; then "$fn"; else
    printf '%s알 수 없는 검사: %s%s\n' "$R" "$1" "$N" >&2; return 2
  fi
}

main() {
  local targets=()
  case "${1:-}" in
    --list) printf '%s\n' "${ALL_CHECKS[@]}"; return 0 ;;
    --changed)
      mapfile -t targets < <(select_by_changes)
      [ ${#targets[@]} -eq 0 ] && { echo "변경 없음 — 검사 생략"; return 0; }
      ;;
    "") targets=("${ALL_CHECKS[@]}") ;;
    *)  targets=("$@") ;;
  esac

  printf '%s검사 %d개 실행%s\n\n' "$B" "${#targets[@]}" "$N"
  for c in "${targets[@]}"; do run_check "$c"; done

  printf '\n%s요약%s  통과 %d  실패 %d  건너뜀 %d\n' \
    "$B" "$N" "${#PASSED[@]}" "${#FAILED[@]}" "${#SKIPPED[@]}"
  if [ ${#FAILED[@]} -gt 0 ]; then
    printf '%s실패: %s%s\n' "$R" "${FAILED[*]}" "$N"
    return 1
  fi
  return 0
}

main "$@"
