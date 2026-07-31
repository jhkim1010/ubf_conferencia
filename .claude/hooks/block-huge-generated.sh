#!/usr/bin/env bash
# PreToolUse (Read) — 거대한 생성물 파일 읽기를 막는다.
#
# 배경: l10n 생성물은 app_localizations.dart 83KB(3108줄), 로케일별 35KB 씩이다.
# 다 읽으면 190KB 가 넘어 컨텍스트가 날아간다. 실제로 T001(언어 선택) 작업에서
# autocompact 가 3회 연속 thrashing 하며 Conductor 가 멈춰 섰다.
#
# 이 파일들은 flutter gen-l10n 산출물이라 읽을 이유가 거의 없다.
# 키 존재 확인이 필요하면 grep 을 쓰면 된다.
#
# 규약: PreToolUse 는 exit 2 로 도구 실행을 막고 stderr 를 모델에게 전달한다.

set -uo pipefail

input="$(cat)"
f="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -z "$f" ] && exit 0

case "$f" in
  *app_localizations*.dart) ;;
  *) exit 0 ;;
esac

# offset/limit 으로 일부만 읽는 것은 허용한다 (의도적으로 좁혀 읽는 경우).
if printf '%s' "$input" | jq -e '.tool_input.limit != null' >/dev/null 2>&1; then
  exit 0
fi

name="$(basename "$f")"
{
  echo "생성물 파일 전체 읽기를 막았습니다: ${name}"
  echo
  echo "이 파일은 flutter gen-l10n 산출물이고 매우 큽니다"
  echo "(app_localizations.dart 는 3100줄 / 83KB). 전부 읽으면 컨텍스트가 소진됩니다."
  echo
  echo "필요한 작업별 대안:"
  echo "  · 키가 있는지 확인      → grep -n '키이름' ubf_app/lib/l10n/app_en.arb"
  echo "  · 문자열을 추가/수정    → .arb 파일 3개를 고치고 flutter gen-l10n 을 실행"
  echo "  · 일부만 봐야 함        → Read 에 offset/limit 을 지정"
  echo
  echo "생성물은 직접 편집하지 않습니다. 원본은 lib/l10n/app_{en,ko,es}.arb 입니다."
} >&2
exit 2
