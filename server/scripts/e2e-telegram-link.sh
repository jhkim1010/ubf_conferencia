#!/usr/bin/env bash
# 참가자 텔레그램 연결 (047)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-telegram-link.sh
#
# 실제 연결은 사람이 텔레그램에서 /start 를 눌러야 일어나므로 여기서는
# 흉내낼 수 없다. 대신 **봇이 없을 때 화면이 조용해지는지** 를 본다 —
# 이 수양회들은 대부분 봇을 안 정해 두고, 그때 눌러도 아무 일이 안 나는
# 버튼이 떠 있으면 그것이 더 나쁘다.
#
# /start 를 읽는 부분은 test/telegram_link.test.js 가 형태별로 못 박는다.
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
  -d '{"name":"텔레그램 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"텔레그램검증-%s","location":"x","startDate":"2027-12-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

ME=$(login "tg-me-$$@test.local")
LINK() { curl -s "$API/telegram/$P/link" -H "Authorization: Bearer $1"; }

echo "── 등록하기 전 ──"
# 등록 행이 없으면 연결할 대상도 없다.
eq "등록이 없으면 404" '404' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/telegram/$P/link" \
      -H "Authorization: Bearer $ME")"

curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $ME" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"텔레","country":"KR","gender":"M","age":30}'

echo
echo "── 봇을 안 정해 둔 수양회 ──"
# 여기가 이 검사의 핵심이다. 봇이 없으면 앱은 카드를 아예 안 그린다.
eq "물어볼 수는 있다"     '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/telegram/$P/link" -H "Authorization: Bearer $ME")"
eq "  쓸 수 없다고 답한다" 'false' "$(LINK "$ME" | jq_ 'r.available')"
eq "  아직 연결 안 됨"     'false' "$(LINK "$ME" | jq_ 'r.linked')"
eq "  링크는 주지 않는다"  ''      "$(LINK "$ME" | jq_ 'r.url')"

echo
echo "── 확인을 눌러도 조용하다 ──"
# 봇이 없으면 가져올 것도 없다. 500 이 나면 앱에 빨간 줄이 뜬다.
eq "확인이 통한다"   '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/telegram/$P/link/check" \
      -H "Authorization: Bearer $ME")"
eq "  연결 안 됨"   'false' \
   "$(curl -s -X POST "$API/telegram/$P/link/check" -H "Authorization: Bearer $ME" | jq_ 'r.linked')"

echo
echo "── 연결 끊기 ──"
# 연결한 적이 없어도 실패하면 안 된다 — 사람은 상태를 모르고 누른다.
eq "끊기가 통한다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/telegram/$P/link" \
      -H "Authorization: Bearer $ME")"

echo
echo "── 남의 등록 ──"
# 다른 사람이 이 수양회에 등록하지 않았다면 아무것도 볼 수 없다.
OTHER=$(login "tg-other-$$@test.local")
eq "등록 안 한 사람은 404" '404' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/telegram/$P/link" \
      -H "Authorization: Bearer $OTHER")"
eq "  로그인 없이도 401"  '401' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/telegram/$P/link")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
