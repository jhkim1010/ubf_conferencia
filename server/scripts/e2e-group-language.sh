#!/usr/bin/env bash
# 말씀조의 공부 언어 (025 의 칸을 마침내 쓴다)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-group-language.sh
#
# groups.study_language 는 025 부터 있었지만 **아무도 쓰지 않았다** — 배정
# 엔진과 화면이 읽기만 하고, 저장할 길이 없었다. 그래서 모든 조가 "아무나
# 받는 조" 였고 화면의 언어 줄은 늘 비어 있었다. 브라우저로 실제 화면을
# 보다가 드러난 구멍이다.
#
# 여기서 보는 것은 셋이다.
#   1. 만들 때·고칠 때 언어가 저장된다
#   2. 배정 화면이 그 값을 받는다
#   3. 다른 것만 고치는 저장이 언어를 지우지 않는다
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
login() {
  local body; body=$(curl -s -X POST "$API/auth/dev-login" \
    -H 'Content-Type: application/json' --data-binary "$(printf '{"email":"%s"}' "$1")")
  local tok; tok=$(printf '%s' "$body" \
    | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
  if [ -z "$tok" ]; then
    echo "로그인 실패($1): $body" >&2
    echo "  레이트 리밋이면 서버를 다시 띄우거나 15분 기다리십시오." >&2
    exit 1
  fi
  printf '%s' "$tok"
}
jq_() { node -pe "
  try {
    const r = JSON.parse(require('fs').readFileSync(0));
    const v = ($1);
    console.log(v === undefined || v === null ? '' : String(v));
  } catch (e) { console.log('ERR'); }
  ''" ; }

LT=$(login "$LEADER")
NEW_LT=$(curl -s -X POST "$API/leaders/register" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"name":"조언어 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"조언어검증-%s","location":"x","startDate":"2027-08-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

mk() { # $1=본문 → 조 id
  curl -s -X POST "$API/groups/$P" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' --data-binary "$1" | jq_ "r.id"
}
LANG_OF() { # $1=조 id — 배정 화면이 받는 값
  curl -s "$API/assignments/$P/groups" -H "Authorization: Bearer $LT" \
    | jq_ "(r.groups.find(g => g.id === '$1') || {}).studyLanguage"
}

echo "── 만들 때 ──"
G=$(mk '{"name":"1조","studyLanguage":"ko"}')
[ -n "$G" ] && [ "$G" != "ERR" ] || { echo "조를 만들지 못했습니다"; exit 1; }
eq "언어가 저장된다"        'ko' "$(LANG_OF "$G")"
# 정하지 않는 것도 뜻이 있다 — "아무나 받는 조".
G2=$(mk '{"name":"2조"}')
eq "  안 정하면 비어 있다"  ''   "$(LANG_OF "$G2")"
# 모르는 값을 저장해 버리면 배정 엔진이 아무도 넣지 못하는 조가 생긴다.
G3=$(mk '{"name":"3조","studyLanguage":"클링온"}')
eq "  모르는 값은 안 받는다" ''  "$(LANG_OF "$G3")"

echo
echo "── 고칠 때 ──"
curl -s -o /dev/null -X PATCH "$API/groups/$P/$G2" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"studyLanguage":"es"}'
eq "나중에 정할 수 있다" 'es' "$(LANG_OF "$G2")"
# 화면에서 "정하지 않음" 을 고르면 빈 문자열이 온다.
curl -s -o /dev/null -X PATCH "$API/groups/$P/$G2" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"studyLanguage":""}'
eq "  빈 값이면 되돌린다"  ''  "$(LANG_OF "$G2")"

echo
echo "── 다른 것만 고칠 때 ──"
# 조 이름만 고치는 저장이 애써 정한 언어를 지우면 안 된다.
curl -s -o /dev/null -X PATCH "$API/groups/$P/$G" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"name":"1조 (수정)"}'
eq "언어는 그대로" 'ko' "$(LANG_OF "$G")"
eq "  이름은 바뀐다" '1조 (수정)' \
   "$(curl -s "$API/groups/$P" -H "Authorization: Bearer $LT" \
      | jq_ "r.groups.find(g => g.id === '$G').name")"
# 모르는 값이 오면 손대지 않는다 — 지우는 것보다 그대로 두는 쪽이 안전하다.
curl -s -o /dev/null -X PATCH "$API/groups/$P/$G" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"studyLanguage":"엉뚱한값"}'
eq "  모르는 값에도 그대로" 'ko' "$(LANG_OF "$G")"

echo
echo "── 목록에도 실린다 ──"
# 편성 준비 화면이 이 목록으로 언어 칸을 채운다.
eq "조 목록이 언어를 준다" 'ko' \
   "$(curl -s "$API/groups/$P" -H "Authorization: Bearer $LT" \
      | jq_ "r.groups.find(g => g.id === '$G').studyLanguage")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
