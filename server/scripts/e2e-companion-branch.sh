#!/usr/bin/env bash
# 동반자 지부 물려받기(032) 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-companion-branch.sh
#
# 동반자는 거의 언제나 등록자와 같은 지부다. 다시 적게 하면 같은 지부가
# 'São Paulo UBF' / 'Sao Paulo' / 'SP UBF' 로 갈라져 적힌다.
#
# 중요한 것은 **적어 둔 값을 지우지 않는가**다. 체크를 풀면 예전에 적은
# 값이 다시 보여야 한다 — 지워 버리면 잠깐 켰다 끈 사람이 처음부터 다시 적는다.
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
login() {
  local body; body=$(curl -s -X POST "$API/auth/dev-login" \
    -H 'Content-Type: application/json' -d "{\"email\":\"$1\"}")
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
U=$(login "cb-$$@test.local")

NAME="동반지부검증-$$"
P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"$NAME\",\"location\":\"검증\",\"startDate\":\"2027-07-01\",
       \"programType\":\"international\",\"feeBasic\":100}" | jq_ ".id || r.existingId")
[ ${#P} -eq 36 ] || { echo "생성 실패: $P"; exit 1; }

# 등록자는 'São Paulo UBF' 지부다.
curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $U" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"등록자","country":"BR","branch":"São Paulo UBF","feeTier":"basic"}'

put() { curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/companions/$P/me" \
  -H "Authorization: Bearer $U" -H 'Content-Type: application/json' -d "$1"; }
get() { curl -s "$API/companions/$P/me" -H "Authorization: Bearer $U"; }

echo "── 같은 지부 (기본) ──"
BODY_SAME='{"companions":[{"realName":"João","sameBranchAsPrimary":true,"branch":""}]}'
eq "저장된다" '200' "$(put "$BODY_SAME")"
eq "  실제 지부는 등록자의 것" 'São Paulo UBF' "$(get | jq_ "[0].effective_branch")"
eq "  적어 둔 값은 비어 있다"  ''              "$(get | jq_ "[0].branch")"
eq "  체크가 켜져 있다"        'true'          "$(get | jq_ "[0].same_branch_as_primary")"

echo
echo "── 다른 지부 ──"
BODY_OTHER='{"companions":[{"realName":"João","sameBranchAsPrimary":false,"branch":"Rio UBF"}]}'
eq "저장된다" '200' "$(put "$BODY_OTHER")"
eq "  적은 대로 쓴다" 'Rio UBF' "$(get | jq_ "[0].effective_branch")"

echo
echo "── 체크를 켜도 적어 둔 값은 남는다 ──"
# 지워 버리면 잠깐 켰다 끈 사람이 처음부터 다시 적어야 한다.
BODY_BACK='{"companions":[{"realName":"João","sameBranchAsPrimary":true,"branch":"Rio UBF"}]}'
eq "체크를 켜고 저장" '200' "$(put "$BODY_BACK")"
eq "  실제 지부는 등록자의 것" 'São Paulo UBF' "$(get | jq_ "[0].effective_branch")"
eq "  적어 둔 값이 남아 있다"  'Rio UBF'       "$(get | jq_ "[0].branch")"

echo
echo "── 등록자가 지부를 바꾸면 함께 따라간다 ──"
# 물려받기의 요점이다. 값을 복사해 두면 여기서 어긋난다.
curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $U" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"등록자","country":"BR","branch":"Campinas UBF","feeTier":"basic"}'
eq "동반자 지부도 바뀐다" 'Campinas UBF' "$(get | jq_ "[0].effective_branch")"

curl -s -o /dev/null -X DELETE "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d "{\"confirmName\":\"$NAME\"}"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
