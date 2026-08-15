#!/usr/bin/env bash
# 담당자가 한 사람의 등록·입금을 손본다 (053)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-registration-edit.sh
#
# 입금은 등록자가 올린 것을 담당자가 승인/반려하는 길뿐이었다. 그런데 이
# 수양회들은 대개 현장에서 현금을 받고, 그때는 올릴 영수증이 없다. 담당자가
# 명단을 보다가 그 자리에서 적을 수 있어야 한다.
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
  -d '{"name":"등록수정 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"등록수정검증-%s","location":"x","startDate":"2027-09-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

T=$(login "re-a-$$@test.local")
curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"김참가","country":"KR","gender":"M","age":30}'
R=$(curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $T" | jq_ "r.id")
[ -n "$R" ] && [ "$R" != "ERR" ] || { echo "등록 id 를 못 얻었습니다"; exit 1; }

EDIT() { curl -s -o /dev/null -w '%{http_code}' -X PATCH \
  "$API/programs/$P/registrations/$R" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' --data-binary "$1"; }
ROW() { curl -s "$API/programs/$P/registrations" -H "Authorization: Bearer $LT" \
  | jq_ "(r.find(x => x.id === '$R') || {}).$1"; }

echo "── 등록 완료를 담당자가 켠다 ──"
# 종이로 대신 받아 적은 사람은 본인이 앱에서 제출하지 않는다.
eq "처음에는 미완료" 'false' "$(ROW submitted)"
eq "켤 수 있다"      '200'   "$(EDIT '{"submitted":true}')"
eq "  켜졌다"        'true'  "$(ROW submitted)"

echo
echo "── 낼 돈과 받았는지 ──"
eq "금액과 상태를 적는다" '200' \
   "$(EDIT '{"payment":{"amount":150,"status":"pending"}}')"
# db.js 가 NUMERIC 을 숫자로 바꿔 준다 — 문자열 '150.00' 이 아니다.
eq "  금액"   '150'  "$(ROW 'payment.amount')"
eq "  상태"   'pending' "$(ROW 'payment.status')"
# 현장에서 받으면 그 자리에서 확인으로 바꾼다.
eq "받았다고 바꾼다" '200' \
   "$(EDIT '{"payment":{"amount":150,"status":"confirmed"}}')"
eq "  확인됨" 'confirmed' "$(ROW 'payment.status')"
# 한 사람에 한 줄이다(001 의 UNIQUE). 두 번 적어도 줄이 늘지 않는다.
eq "두 번 적어도 한 줄" '1' \
   "$(curl -s "$API/programs/$P/stats" -H "Authorization: Bearer $LT" \
      | jq_ 'r.confirmed_payment_count')"

echo
echo "── 잘못 적었을 때 ──"
# 되돌릴 길이 없으면 담당자는 0 원짜리 줄을 남겨 둔다.
eq "지울 수 있다" '200' "$(EDIT '{"payment":null}')"
eq "  없어졌다"   ''    "$(ROW 'payment.status')"
eq "  등록 완료는 그대로" 'true' "$(ROW submitted)"

echo
echo "── 받지 않는 값 ──"
eq "음수 금액은 거절" '400' "$(EDIT '{"payment":{"amount":-5,"status":"pending"}}')"
eq "숫자가 아니면 거절" '400' "$(EDIT '{"payment":{"amount":"공짜","status":"pending"}}')"
# 모르는 상태는 '받을 예정' 으로 본다 — 저장을 통째로 막으면 담당자는
# 방금 적은 금액을 잃는다.
eq "모르는 상태는 대기로" '200' \
   "$(EDIT '{"payment":{"amount":10,"status":"엉뚱"}}')"
eq "  대기" 'pending' "$(ROW 'payment.status')"

echo
echo "── 권한 ──"
OTHER=$(login "re-other-$$@test.local")
eq "담당자가 아니면 403" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH \
      "$API/programs/$P/registrations/$R" -H "Authorization: Bearer $OTHER" \
      -H 'Content-Type: application/json' -d '{"submitted":false}')"
# 다른 수양회의 등록을 손댈 수 없다.
Q=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"등록수정검증-다른-%s","location":"x","startDate":"2027-09-01",
       "programType":"international","feeBasic":100}' "$$")" | jq_ "r.id || r.existingId")
eq "남의 수양회 등록은 404" '404' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH \
      "$API/programs/$Q/registrations/$R" -H "Authorization: Bearer $LT" \
      -H 'Content-Type: application/json' -d '{"submitted":false}')"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
