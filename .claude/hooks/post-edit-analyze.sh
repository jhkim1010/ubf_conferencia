#!/usr/bin/env bash
# PostToolUse (Edit|Write) — .dart 편집 후 flutter analyze.
#
# analyze 는 약 2.8초가 걸린다. 편집마다 블로킹하면 에이전트 작업 흐름을 크게 늦추므로
# settings.json 에서 asyncRewake 로 등록한다: 백그라운드로 돌고, 실패(exit 2)일 때만
# 모델을 깨워 결과를 전달한다.
#
# 규약: 실패 시 exit 2, 그 외 exit 0.

set -uo pipefail

input="$(cat)"
f="$(printf '%s' "$input" | jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null)"
[ -z "$f" ] && exit 0
case "$f" in *.dart) ;; *) exit 0 ;; esac
# 생성물은 검사 대상이 아니다
case "$f" in *app_localizations*.dart) exit 0 ;; esac

root="$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -x "$root/verify.sh" ] || exit 0
cd "$root" || exit 0

out="$(./verify.sh flutter-analyze 2>&1)"
status=$?

if [ $status -ne 0 ]; then
  {
    echo "flutter analyze 실패 — ${f#"$root"/} 편집 이후 정적 분석 경고가 있습니다."
    echo
    printf '%s\n' "$out"
  } >&2
  exit 2
fi

exit 0
