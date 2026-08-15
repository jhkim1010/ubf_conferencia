#!/usr/bin/env bash
# 수양회 장부 (053)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-ledger.sh
#
# 담당자가 묻는 것은 하나다: "지금 얼마가 모자라나". 참가비는 payments 에,
# 지원과 지출은 장부에 있으므로 **둘을 더해야** 답이 된다. 여기서 보는 것도
# 그 합계다.
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
  -d '{"name":"장부 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

# 참가비 200 짜리 수양회.
P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"장부검증-%s","location":"x","startDate":"2027-09-01",
       "programType":"international","feeBasic":200}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

LEDGER() { curl -s "$API/ledger/$P" -H "Authorization: Bearer $LT"; }
SUM() { LEDGER | jq_ "r.summary.$1"; }
ADD() { curl -s -o /dev/null -w '%{http_code}' -X POST "$API/ledger/$P" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  --data-binary "$1"; }

echo "── 비어 있을 때 ──"
eq "줄이 없다"     '0' "$(LEDGER | jq_ 'r.entries.length')"
eq "  남은 돈 0"   '0' "$(SUM balance)"

echo
echo "── 지원과 지출 ──"
eq "지원을 적는다" '201' "$(ADD '{"kind":"income","amount":1000,"title":"지부 지원금"}')"
eq "지출을 적는다" '201' "$(ADD '{"kind":"expense","amount":300,"title":"버스 대절","note":"이과수 왕복"}')"
eq "  들어온 돈"   '1000' "$(SUM support)"
eq "  나간 돈"     '300'  "$(SUM spent)"
eq "  남은 돈"     '700'  "$(SUM balance)"

echo
echo "── 참가비까지 합친다 ──"
# 장부와 참가비를 따로 보면 "지금 얼마가 모자라나" 에 답할 수 없다.
T=$(login "lg-a-$$@test.local")
curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"김참가","country":"KR","gender":"M","age":30}'
R=$(curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $T" | jq_ "r.id")
eq "낼 참가비가 잡힌다" '200' "$(SUM owed)"
# 아직 안 냈으므로 손에 있는 돈은 그대로다.
eq "  남은 돈은 그대로" '700' "$(SUM balance)"
eq "  다 걷히면"        '900' "$(SUM expected)"

# 절반만 받았고 확인했다.
curl -s -o /dev/null -X PATCH "$API/programs/$P/registrations/$R" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"payment":{"amount":100,"status":"confirmed"}}'
eq "받은 만큼 수금에 오른다" '100' "$(SUM collected)"
eq "  남은 돈도 오른다"      '800' "$(SUM balance)"
eq "  받을 돈은 줄어든다"    '100' "$(SUM owed)"

# 확인 전 금액은 세지 않는다 — 장부가 실제보다 커진다.
curl -s -o /dev/null -X PATCH "$API/programs/$P/registrations/$R" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"payment":{"amount":200,"status":"pending"}}'
eq "확인 전 금액은 수금이 아니다" '0'   "$(SUM collected)"
eq "  남은 돈이 되돌아간다"       '700' "$(SUM balance)"

echo
echo "── 고치고 지우기 ──"
E=$(LEDGER | jq_ "r.entries.find(x => x.kind === 'expense').id")
curl -s -o /dev/null -X PATCH "$API/ledger/$P/$E" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"kind":"expense","amount":500,"title":"버스 대절"}'
eq "고치면 합계가 따라온다" '500' "$(SUM spent)"
eq "  지운다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/ledger/$P/$E" \
      -H "Authorization: Bearer $LT")"
eq "  나간 돈이 0"          '0'  "$(SUM spent)"
eq "  없는 줄을 지우면 404" '404' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/ledger/$P/$E" \
      -H "Authorization: Bearer $LT")"

echo
echo "── 받지 않는 값 ──"
# 금액은 늘 양수다. 음수 지출이 섞이면 합계를 아무도 못 믿는다.
eq "0 원은 거절"       '400' "$(ADD '{"kind":"expense","amount":0,"title":"x"}')"
eq "음수는 거절"       '400' "$(ADD '{"kind":"expense","amount":-5,"title":"x"}')"
eq "모르는 갈래는 거절" '400' "$(ADD '{"kind":"기부","amount":5,"title":"x"}')"
# 무엇에 쓴 돈인지 없으면 나중에 아무도 못 알아본다.
eq "내용이 없으면 거절" '400' "$(ADD '{"kind":"expense","amount":5,"title":"  "}')"

echo
echo "── 권한 ──"
OTHER=$(login "lg-other-$$@test.local")
eq "담당자가 아니면 403" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/ledger/$P" \
      -H "Authorization: Bearer $OTHER")"
eq "  적지도 못한다" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/ledger/$P" \
      -H "Authorization: Bearer $OTHER" -H 'Content-Type: application/json' \
      -d '{"kind":"income","amount":1,"title":"x"}')"
eq "로그인 없으면 401" '401' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/ledger/$P")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
