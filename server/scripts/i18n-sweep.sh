#!/usr/bin/env bash
# 다국어 스윕 — 3개 언어로 전환하며 각 페이지에 미번역 문자열이 남는지 확인한다.
#
# 사용: SURFACE=surface:19 PROG=<programId> ./scripts/i18n-sweep.sh
#
# 원리: 로케일을 en/es 로 두었을 때 화면에 한글이 남아 있으면 하드코딩된
# 한국어(미번역)일 가능성이 높다. 사용자 데이터(프로그램명·사람 이름)와
# 의도적으로 한국어인 항목(언어 선택지 "한국어")은 제외 목록으로 거른다.
#
# Flutter 웹은 캔버스로 그리므로 접근성 트리(semantics)를 텍스트 원본으로 쓴다.

set -uo pipefail
SURFACE="${SURFACE:?SURFACE 필요 (예: surface:19)}"
PROG="${PROG:?PROG(programId) 필요}"
OUT="${OUT:-/tmp/i18n-sweep}"
mkdir -p "$OUT"

# 사용자 데이터·의도적 한국어 — 미번역으로 세지 않는다
EXCLUDE='한국어|2026 UBF 국제 수양회|박지부장|김국내|테스트|JungHo|Maria Silva|상파울루|리마|브라질'

ROUTES=(
  "/home|홈"
  "/leader/create-program|수양회 생성"
  "/leader/program/$PROG/dashboard|대시보드"
  "/leader/program/$PROG/edit|프로그램 수정"
  "/leader/program/$PROG/setup|방·조 설정"
  "/leader/program/$PROG/assign|배정"
  "/leader/program/$PROG/dispatch|배차"
  "/registration/$PROG|등록 플로우"
  "/registration/$PROG/summary|등록 요약"
  "/program/$PROG/schedule|일정"
  "/program/$PROG/my-transport|내 교통편"
  "/program/$PROG/immigration|입국 정보"
  "/sos/$PROG|SOS"
)

snap() { cmux browser "$SURFACE" snapshot --compact 2>/dev/null; }
semantics_on() { cmux browser "$SURFACE" eval 'const p=document.querySelector("flt-semantics-placeholder"); if(p)p.click(); "ok"' >/dev/null 2>&1; }

set_locale() { # $1 = ko|en|es|system
  if [ "$1" = "system" ]; then
    cmux browser "$SURFACE" eval 'localStorage.removeItem("flutter.app_locale"); "ok"' >/dev/null 2>&1
  else
    cmux browser "$SURFACE" eval "localStorage.setItem('flutter.app_locale', JSON.stringify('$1')); 'ok'" >/dev/null 2>&1
  fi
}

total_issues=0

for LOCALE in ko en es; do
  echo ""
  echo "════════ 로케일: $LOCALE ════════"
  set_locale "$LOCALE"
  cmux browser "$SURFACE" goto "http://localhost:8080/#/home" >/dev/null 2>&1
  sleep 5; semantics_on; sleep 1

  for entry in "${ROUTES[@]}"; do
    route="${entry%%|*}"; label="${entry##*|}"
    cmux browser "$SURFACE" goto "http://localhost:8080/#${route}" >/dev/null 2>&1
    sleep 3; semantics_on; sleep 1
    text="$(snap)"
    printf '%s' "$text" > "$OUT/${LOCALE}${route//\//_}.txt"

    # 화면이 비었는지(렌더 실패) 확인
    n=$(printf '%s' "$text" | grep -cE '^\s*-' || true)
    if [ "$n" -lt 2 ]; then
      echo "  ⚠ ${label} — 요소 ${n}개, 렌더 실패 또는 빈 화면일 수 있음"
      continue
    fi

    if [ "$LOCALE" = "ko" ]; then
      echo "  · ${label} — 요소 ${n}개"
      continue
    fi

    # en/es 에서 한글 검출
    hits="$(printf '%s' "$text" | grep -oE '"[^"]*[가-힣][^"]*"' | sort -u | grep -vE "$EXCLUDE" || true)"
    if [ -z "$hits" ]; then
      echo "  ✓ ${label} — 미번역 없음 (요소 ${n}개)"
    else
      c=$(printf '%s\n' "$hits" | grep -c . )
      echo "  ✗ ${label} — 미번역 의심 ${c}건"
      printf '%s\n' "$hits" | head -6 | sed 's/^/       /'
      total_issues=$((total_issues + c))
    fi
  done
done

echo ""
echo "════════════════════════════════"
echo "미번역 의심 총 ${total_issues}건"
echo "원본 스냅샷: $OUT/"
