#!/usr/bin/env bash
# Stop — 턴을 마치기 전에 이번 세션의 변경분을 검증한다.
#
# 편집 직후 훅(post-edit-verify)은 "방금 건드린 파일"만 본다. 여러 파일에 걸친 변경은
# 개별 편집 시점에는 정합했다가 최종 상태에서 깨질 수 있다(예: 라우터 파일을 만들고
# index.js 등록을 잊은 채 다른 작업으로 넘어감). 이 훅이 그 틈을 막는다.
#
# ── cmux-team 세션에서 차단하지 않는 이유 (중요) ──────────────────────────
# cmux-team 은 Agent 의 Stop 훅에서 세션 상태를 daemon 에 보고하고, daemon 이
# `.team/conductors/<c>/agent-done/<a>.done` 마커를 쓴다. Conductor 의 await-agent 는
# 이 마커를 fs.watch 로 감시한다.
#
# 같은 Stop 이벤트의 훅들은 모두 실행되므로, 여기서 exit 2 로 종료를 막으면
#   - Claude 는 계속 작업하고
#   - cmux-team 훅은 이미 "완료"를 보고해 Conductor 가 결과를 통합하기 시작한다
# 는 경쟁 상태가 생긴다. 조용히 잘못된 결과를 낳는 종류라 피해야 한다.
#
# 따라서 cmux-team 이 관리하는 세션(CMUX_SURFACE 가 설정됨)에서는 결과만 알리고
# 차단하지 않는다. 그 경로는 파이프라인의 Inspection 단계가 ./verify.sh 로 잡는다.
# 일반 세션(사람이 직접 쓰는 Claude Code)에서는 차단한다.
#
# 강제 해제: UBF_STOP_HOOK=off

set -uo pipefail

[ "${UBF_STOP_HOOK:-on}" = "off" ] && exit 0

input="$(cat)"

# 무한 루프 방지 — 이미 이 훅 때문에 계속된 턴이면 다시 막지 않는다.
if printf '%s' "$input" | jq -e '.stop_hook_active == true' >/dev/null 2>&1; then
  exit 0
fi

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -x "$root/verify.sh" ] || exit 0
cd "$root" || exit 0

out="$(./verify.sh --changed 2>&1)"
status=$?
[ $status -eq 0 ] && exit 0

# cmux-team 관리 세션: 보고만 하고 통과시킨다 (위 주석의 경쟁 상태 회피)
if [ -n "${CMUX_SURFACE:-}" ]; then
  printf '%s\n' "$out" >&2
  echo "" >&2
  echo "[cmux-team 세션이라 종료를 차단하지 않았습니다. 위 실패를 완료 보고에 반드시 포함하십시오.]" >&2
  exit 0
fi

{
  echo "./verify.sh --changed 실패 — 작업을 마치기 전에 해결해야 합니다."
  echo
  printf '%s\n' "$out"
  echo
  echo "고친 뒤 ./verify.sh --changed 로 재확인하십시오."
  echo "의도한 상태이고 검사가 오탐이라면, 우회하지 말고 사용자에게 확인을 요청하십시오."
} >&2
exit 2
