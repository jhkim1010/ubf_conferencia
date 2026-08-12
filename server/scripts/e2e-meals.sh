#!/usr/bin/env bash
# 식사 제한 명단 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-meals.sh
#
# 준비 현황 카드의 "식사 제한 N명"과 카드를 열었을 때 나오는 명단은 **같은
# 판정**(has_food_restriction, 027)을 써야 한다. 두 곳에 각각 적으면 반드시
# 어긋나고, 어긋난 채로 주방에 명단이 넘어간다.
#
# "없음"만 걸러내던 시절에는 스페인어로 "ninguno" 라고 적은 사람이 전부
# 제한자로 잡혔다. 포르투갈어를 넣을 때도 화면 문구만 옮기고 판정 낱말을
# 빠뜨려 "Nenhum" 이 제한자로 잡혔다 — 네 언어를 모두 확인한다.
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
# 로그인 실패를 삼키지 않는다.
#
# 인증 경로는 15분에 20회로 제한된다(index.js authLimiter). 이 스크립트는 한 번
# 도는 데 9번을 쓰므로 연달아 두 번 돌리면 걸린다. 예전에는 토큰 자리에
# "undefined" 가 들어간 채로 계속 진행해, 레이트 리밋을 **기능 실패로**
# 보고했다 — 규칙을 일부러 깨고 확인하던 중 실제로 그렇게 속았다.
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

LT=$(login "$LEADER")
NEW_LT=$(curl -s -X POST "$API/leaders/register" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"name":"e2e 리더"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"
[ "$LT" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"식단검증-%s","location":"주방","startDate":"2027-07-01",
       "programType":"international","hostCountry":"AR","feeBasic":100}' "$$")" \
  | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''")
[ -n "$P" ] || { echo "생성 실패"; exit 1; }

enroll() { # $1=토큰별칭 $2=이름 $3=식사제한 $4=아침거름(yes/no)
  local tk; tk=$(login "meal-$1-$$@test.local")
  local skip=false; [ "$4" = yes ] && skip=true
  curl -s -o /dev/null -X PUT "$API/registrations/$P/me" \
    -H "Authorization: Bearer $tk" -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"realName":"%s","country":"KR","branch":"검증","feeTier":"basic",
         "foodRequirements":"%s","skipsBreakfast":%s}' "$2" "$3" "$skip")"
}
names() {
  curl -s "$API/programs/$P/meals" -H "Authorization: Bearer $LT" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0));
                (r.people||[]).map(p=>p.real_name).sort().join(',')"
}
field() { # $1=키
  curl -s "$API/programs/$P/meals" -H "Authorization: Bearer $LT" \
    | node -pe "String(JSON.parse(require('fs').readFileSync(0))['$1'])"
}
statCount() {
  curl -s "$API/programs/$P/stats" -H "Authorization: Bearer $LT" \
    | node -pe "String(JSON.parse(require('fs').readFileSync(0)).food_restriction_count ?? 'null')"
}
cardCount() {
  curl -s "$API/programs/$P/readiness" -H "Authorization: Bearer $LT" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0));
                String(r?.readiness?.meals?.restricted ?? 'null')"
}

enroll allergy  "땅콩"     "땅콩 알레르기"  yes
enroll vegan    "비건"     "Vegetariana"    no
enroll koNone   "없음이"   "없음"           no
enroll esNone   "ninguno"  "ninguno"        no
enroll enNo     "no"       "No"             no
enroll dash     "대시"     "-"              no
enroll ptNone   "nenhum"   "Nenhum"         no
enroll blank    "무기재"   ""               no

echo "── 명단 ──"
eq "제한을 적은 사람만 나온다" '땅콩,비건' "$(names)"
eq "  전체 인원도 함께 준다"   '8'         "$(field total)"
eq "  아침 거름 수를 센다"     '1'         "$(field skips_breakfast)"

echo
echo "── 카드와 명단이 같은 수를 말한다 ──"
# 이것이 이 기능의 핵심이다. 카드는 4명, 명단은 2명이면 어느 쪽도 못 믿는다.
eq "준비 현황 카드도 2명" '2' "$(cardCount)"
# 대시보드 통계도 같은 판정을 써야 한다. 여기만 예전 조건이 남아 있어서
# 카드는 4명, 표는 2명이 됐다.
eq "대시보드 통계도 2명"  '2' "$(statCount)"

echo
echo "── 권한 ──"
OTHER=$(login "meal-outsider-$$@test.local")
eq "관리자가 아니면 403" '403' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/meals" -H "Authorization: Bearer $OTHER")"
eq "로그인 없으면 401" '401' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/meals")"

curl -s -o /dev/null -X DELETE "$API/programs/$P" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"confirmName":"식단검증-%s"}' "$$")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
