#!/usr/bin/env bash
# PostToolUse (Edit|Write) — 편집한 파일 종류에 맞는 "빠른" 검사만 즉시 실행한다.
#
# 목적: 오류를 편집 직후에 되먹여 에이전트가 자기 컨텍스트 안에서 고치게 하는 것.
# 여기서 놓치면 오류가 Inspection 단계까지 살아남아 재작업 사이클이 통째로 발생한다.
#
# 지연 예산: 합계 1초 이내. flutter analyze(2.8s)는 여기 넣지 않는다(별도 async 훅).
#
# 규약: 실패 시 exit 2 — PostToolUse 에서 2 는 blocking error 로, stderr 가 모델에게 전달된다.
#       그 외에는 항상 exit 0 (훅 자체 오류로 작업을 막지 않는다).

set -uo pipefail

input="$(cat)"
f="$(printf '%s' "$input" | jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null)"
[ -z "$f" ] && exit 0

# 저장소 루트로 이동. worktree 에서도 동작해야 하므로 파일 위치 기준으로 해석한다.
root="$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -x "$root/verify.sh" ] || exit 0
cd "$root" || exit 0

# 저장소 기준 상대 경로
rel="${f#"$root"/}"

checks=()
case "$rel" in
  ubf_app/lib/l10n/*.arb)          checks+=(arb-parity) ;;
  ubf_app/lib/l10n/app_localizations*.dart) checks+=(artifacts) ;;
  *.dart)                          checks+=(dart-format) ;;
  server/src/routes/*.js|server/src/index.js) checks+=(server-syntax route-parity) ;;
  server/src/services/*.js|server/test/*.js) checks+=(server-syntax unit-tests) ;;
  server/src/*.js|server/src/**/*.js) checks+=(server-syntax) ;;
  ubf_app/supabase/migrations/*.sql) checks+=(migration-numbers migration-safety) ;;
esac

# .env / 커넥션 문자열이 섞여 들어가는 것은 파일 종류와 무관하게 항상 본다.
checks+=(secrets)

[ ${#checks[@]} -eq 0 ] && exit 0

out="$(./verify.sh "${checks[@]}" 2>&1)"
status=$?

if [ $status -ne 0 ]; then
  {
    echo "verify.sh 실패 — 방금 편집한 ${rel} 에 대한 검사에서 문제가 발견되었습니다."
    echo
    printf '%s\n' "$out"
    echo
    echo "수정한 뒤 ./verify.sh --changed 로 재확인하십시오."
  } >&2
  exit 2
fi

exit 0
