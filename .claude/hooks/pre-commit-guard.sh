#!/usr/bin/env bash
# PreToolUse (Bash) — git commit 직전 차단 게이트.
#
# 되돌리기 어려운 지점에서만 막는다. 비밀정보와 빌드 산출물이 커밋에 섞이는 것은
# 커밋 후에 알아차리면 히스토리 정리가 필요해지므로 사전에 차단할 가치가 있다.
#
# 규약: PreToolUse 는 exit 2 로 도구 실행 자체를 막는다. stderr 가 모델에게 전달된다.

set -uo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$cmd" ] && exit 0

# git commit 이 아니면 통과. `git commit`, `git -C x commit` 등을 포괄한다.
printf '%s' "$cmd" | grep -qE '(^|[;&|]|\s)git(\s+-[^;&|]*)?\s+commit(\s|$)' || exit 0

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -x "$root/verify.sh" ] || exit 0
cd "$root" || exit 0

out="$(./verify.sh secrets artifacts 2>&1)"
if [ $? -ne 0 ]; then
  {
    echo "커밋을 차단했습니다 — 비밀정보 또는 빌드 산출물이 포함되어 있습니다."
    echo
    printf '%s\n' "$out"
    echo
    echo "문제를 해결한 뒤 다시 커밋하십시오. 오탐이라면 사용자에게 확인을 요청하십시오."
  } >&2
  exit 2
fi

exit 0
