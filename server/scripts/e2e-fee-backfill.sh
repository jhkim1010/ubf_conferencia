#!/usr/bin/env bash
# 참가비 등급 일괄 지정 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-fee-backfill.sh
#
# 실제로 있었던 일에서 나온 기능이다. 담당자가 금액을 설명 칸에 적어
# 참가비가 비어 있었고, 그 사이 등록한 8명은 참가비 화면을 아예 못 봤다.
# 나중에 금액을 고쳐도 그 8명의 총액은 그대로였고, 그 사실이 어디에도
# 보이지 않았다.
#
# 두 가지를 본다:
#   1) 준비 현황이 "참가비 미선택 N명" 을 세는가
#   2) 일괄 지정이 총액을 서버 식(등급 + 투어 − 승인된 할인)으로 다시 계산하는가
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
jq_() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); String((r$1) ?? '')"; }

LT=$(login "$LEADER")
NEW_LT=$(curl -s -X POST "$API/leaders/register" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"name":"e2e 리더"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"
A=$(login "fb-a-$$@test.local")
B=$(login "fb-b-$$@test.local")

NAME="참가비검증-$$"
# 참가비를 아직 안 정한 채로 만든다 — 실제로 그렇게 시작한다.
P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"%s","location":"검증","startDate":"2027-07-01",
       "programType":"international"}' "$NAME")" | jq_ ".id || r.existingId")
[ ${#P} -eq 36 ] || { echo "생성 실패: $P"; exit 1; }

save() { curl -s -o /dev/null -X PUT "$API/registrations/$P/me" \
  -H "Authorization: Bearer $1" -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"realName":"%s","country":"KR","branch":"검증"}' "$2")"; }
# total_cost 는 numeric 이라 드라이버에 따라 "200" 도 "200.00" 도 온다.
# 표기로 비교하면 값이 맞아도 실패한다 — 숫자로 맞춰 본다.
total() { curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $1" \
  | node -pe "String(Number(JSON.parse(require('fs').readFileSync(0)).total_cost ?? 0))"; }
tier()  { curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $1" | jq_ ".fee_tier"; }
missing() { curl -s "$API/programs/$P/readiness" -H "Authorization: Bearer $LT" \
  | node -pe "const r=JSON.parse(require('fs').readFileSync(0));
              String(r?.readiness?.fees?.missing ?? 'null')"; }
backfill() { curl -s -o /dev/null -w '%{http_code}' -X POST "$API/programs/$P/fee-tier-backfill" \
  -H "Authorization: Bearer $1" -H 'Content-Type: application/json' --data-binary "$(printf '{"tier":"%s"}' "$2")"; }

save "$A" "가나"
save "$B" "다라"

echo "── 참가비를 안 정한 동안 ──"
eq "등급이 비어 있다"          '' "$(tier "$A")"
eq "준비 현황이 2명이라 알린다" '2'    "$(missing)"

echo
echo "── 금액이 없으면 맞출 수 없다 ──"
# 그대로 두면 전원이 0원이 된다.
eq "422 로 막는다" '422' "$(backfill "$LT" basic)"

echo
echo "── 참가비를 정한 뒤 ──"
curl -s -o /dev/null -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"feeBasic":200,"feePremium":300}'
eq "이미 등록한 사람은 그대로 0" '0' "$(total "$A")"
eq "  여전히 2명이 미선택"      '2'     "$(missing)"

echo
echo "── 일괄 지정 ──"
eq "맞춘다"                '200' "$(backfill "$LT" basic)"
eq "  등급이 채워진다"     'basic' "$(tier "$A")"
eq "  총액이 다시 계산된다" '200' "$(total "$A")"
eq "  미선택이 0 이 된다"   '0'     "$(missing)"

echo
echo "── 이미 고른 사람은 건드리지 않는다 ──"
# 고급을 고른 사람을 기본으로 내리면 그 사람은 왜 싸졌는지 모른다.
curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $B" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"다라","country":"KR","branch":"검증","feeTier":"premium"}'
eq "고급 300 이 된다" '300' "$(total "$B")"
eq "다시 눌러도 0건"  '200'    "$(backfill "$LT" basic)"
eq "  고급 그대로"    'premium' "$(tier "$B")"
eq "  총액도 그대로"  '300'  "$(total "$B")"

echo
echo "── 권한 ──"
eq "참가자는 못 누른다 403" '403' "$(backfill "$A" basic)"

curl -s -o /dev/null -X DELETE "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' --data-binary "$(printf '{"confirmName":"%s"}' "$NAME")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
