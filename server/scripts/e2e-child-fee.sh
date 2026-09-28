#!/usr/bin/env bash
# 어린이 참가비(073) 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-child-fee.sh
#
# 아이는 구글 계정이 없어 자기 등록이 없다. 그래서 참가비가 보호자의 낼 돈에
# 붙는다. 이 스크립트는 담당자가 구간을 정하는 데서부터 보호자의 낼 돈이
# 명단에 남는 데까지를 한 번에 확인한다:
#
#   수양회 만들기(구간) → 등록 → 동반자 추가 → 등급 바꾸기 → 사람별 예외
#   → 담당자가 구간을 고침 → 등급 일괄 지정
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
    exit 1
  fi
  printf '%s' "$tok"
}
jq_() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); String((r$1) ?? '')"; }
num() { node -pe "Number(require('fs').readFileSync(0,'utf8').trim() || 0)"; }

LT=$(login "$LEADER")
NEW_LT=$(curl -s -X POST "$API/leaders/register" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"name":"e2e 리더"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"
U=$(login "cf-$$@test.local")
U2=$(login "cf2-$$@test.local")

code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

echo "── 담당자: 구간을 잘못 적으면 막는다 ──"
eq "비율에 퍼센트(50)를 그대로 보내면 400" '400' "$(code -X POST "$API/programs" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"cf-bad-%s","location":"x","startDate":"2027-07-01","programType":"international","feeBasic":100,"feeChildRate":50}' $$)")"
eq "시작 나이가 끝보다 크면 400" '400' "$(code -X POST "$API/programs" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"cf-bad2-%s","location":"x","startDate":"2027-07-01","programType":"international","feeBasic":100,"feeChildAgeMin":9,"feeChildAgeMax":4}' $$)")"

echo
echo "── 담당자: 4~8살 절반, 9살부터 전액 ──"
P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"어린이참가비-%s","location":"검증","startDate":"2027-07-01",
       "programType":"international","feeBasic":100,"feePremium":200,
       "feeChildAgeMin":4,"feeChildAgeMax":8,"feeChildRate":0.5}' $$)" | jq_ ".id || r.existingId")
[ ${#P} -eq 36 ] || { echo "생성 실패: $P"; exit 1; }
PROG=$(curl -s "$API/programs/$P" -H "Authorization: Bearer $U")
eq "등록자도 구간을 읽는다 (시작)" '4'   "$(printf '%s' "$PROG" | jq_ ".fee_child_age_min")"
eq "  (끝)"                         '8'   "$(printf '%s' "$PROG" | jq_ ".fee_child_age_max")"
eq "  (비율)"                       '0.5' "$(printf '%s' "$PROG" | jq_ ".fee_child_rate" | num)"

total() { curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $1" | jq_ ".total_cost" | num; }
putreg() { curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/registrations/$P/me" \
  -H "Authorization: Bearer $1" -H 'Content-Type: application/json' --data-binary "$2"; }
putkids() { curl -s -X PUT "$API/companions/$P/me" \
  -H "Authorization: Bearer $1" -H 'Content-Type: application/json' --data-binary "$2"; }

echo
echo "── 보호자: 기본 등급으로 등록 ──"
eq "등록된다" '200' "$(putreg "$U" '{"realName":"보호자","country":"BR","branch":"x","feeTier":"basic"}')"
eq "혼자일 때 100" '100' "$(total "$U")"

echo
echo "── 아이 셋: 3살·6살·12살 ──"
# 3살 0 · 6살 50 · 12살 100 → 100 + 150
KIDS='{"companions":[
  {"realName":"아기","age":3,"registersSeparately":false},
  {"realName":"여섯살","age":6,"registersSeparately":false},
  {"realName":"열두살","age":12,"registersSeparately":false}]}'
R=$(putkids "$U" "$KIDS")
eq "저장하면서 낼 돈을 돌려준다" '250' "$(printf '%s' "$R" | jq_ ".totalCost" | num)"
eq "명단에 남는 낼 돈도 250"     '250' "$(total "$U")"

echo
echo "── 경계는 포함한다: 4살·8살은 절반, 9살은 전액 ──"
R=$(putkids "$U" '{"companions":[
  {"realName":"넷","age":4,"registersSeparately":false},
  {"realName":"여덟","age":8,"registersSeparately":false},
  {"realName":"아홉","age":9,"registersSeparately":false}]}')
eq "100 + 50 + 50 + 100" '300' "$(total "$U")"

echo
echo "── 나이를 모르면 받지 않는다 ──"
putkids "$U" '{"companions":[{"realName":"모름","registersSeparately":false}]}' >/dev/null
eq "100 그대로" '100' "$(total "$U")"

echo
echo "── 따로 등록하는 사람은 여기서 안 받는다 ──"
putkids "$U" '{"companions":[{"realName":"어른","age":30,"registersSeparately":true}]}' >/dev/null
eq "100 그대로" '100' "$(total "$U")"

echo
echo "── 사람별 예외: 6살인데 안 받기로(0) ──"
putkids "$U" '{"companions":[{"realName":"여섯살","age":6,"registersSeparately":false,"feeShare":0}]}' >/dev/null
eq "0 은 정책보다 먼저다" '100' "$(total "$U")"
eq "  저장된 값은 0 (NULL 이 아니다)" '0' \
  "$(curl -s "$API/companions/$P/me" -H "Authorization: Bearer $U" | jq_ "[0].fee_share" | num)"

echo
echo "── 등급을 바꾸면 아이 몫도 따라간다 ──"
putkids "$U" "$KIDS" >/dev/null
eq "고급으로 바꾸기" '200' "$(putreg "$U" '{"realName":"보호자","country":"BR","branch":"x","feeTier":"premium"}')"
# 200 + 0 + 100 + 200
eq "200 + 100 + 200" '500' "$(total "$U")"

echo
echo "── 담당자가 구간을 12살까지로 넓힌다 ──"
eq "수정된다" '200' "$(code -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"feeChildAgeMax":12}')"
# 12살이 절반이 된다: 200 + 100 + 100
eq "먼저 등록한 집도 따라 고쳐진다" '400' "$(total "$U")"
eq "끝 나이를 시작보다 작게 고치면 400" '400' "$(code -X PATCH "$API/programs/$P" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' -d '{"feeChildAgeMax":2}')"

echo
echo "── 등급을 못 고른 집을 담당자가 일괄 지정 ──"
eq "등급 없이 등록" '200' "$(putreg "$U2" '{"realName":"보호자2","country":"BR","branch":"x"}')"
putkids "$U2" '{"companions":[{"realName":"여섯살","age":6,"registersSeparately":false}]}' >/dev/null
# 등급을 안 골라도 기본 참가비를 낸다(registration_total.js tierFeeOf).
# 아이 몫도 그 기본 등급을 따라간다.
eq "등급이 없어도 기본 등급으로 100 + 50" '150' "$(total "$U2")"
code -X POST "$API/programs/$P/fee-tier-backfill" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"tier":"basic"}' >/dev/null
eq "지정 뒤 100 + 50" '150' "$(total "$U2")"

# 정리
curl -s -o /dev/null -X DELETE "$API/programs/$P?force=1" -H "Authorization: Bearer $LT"

echo
echo "통과 $pass  실패 $fail"
[ "$fail" -eq 0 ]
