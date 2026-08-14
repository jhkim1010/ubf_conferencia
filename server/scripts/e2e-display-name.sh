#!/usr/bin/env bash
# 명단에 보이는 이름 (049)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-display-name.sh
#
# 이 공동체에서 서로 부르는 이름은 여권의 본명이 아니다 — "Kim jung ho" 가
# 아니라 "Marcos". 명단만 보고는 누가 누구인지 알아보지 못한다. 그렇다고
# 본명을 감출 수도 없다(여권·항공권·입국). 그래서 둘을 함께 적는다.
#
# **화면마다 따로 이어 붙이면 한 곳만 빠뜨렸을 때 아무도 이유를 모른다** —
# 식사 제한 인원이 카드와 표에서 달랐던 것이 바로 그런 일이었다. 그래서
# 판단은 display_name() 하나에 있고, 여기서는 여러 화면이 같은 답을
# 내놓는지 본다.
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
  -d '{"name":"이름표시 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"이름표시검증-%s","location":"x","startDate":"2027-10-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

mk() { # $1=본명 $2=세례명 $3=키
  local t; t=$(login "dn-$3-$$@test.local")
  curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"realName":"%s","bibleName":"%s","country":"KR","gender":"M","age":30}' "$1" "$2")"
}
mk 'Kim jung ho'    'Marcos' a
mk 'Josverlyn'      ''       b
mk 'Shirley Coronel' '-'     c

RECENT() { curl -s "$API/programs/$P/stats" -H "Authorization: Bearer $LT" \
  | jq_ "r.preview.recent.map(x => x.name).sort().join(' | ')"; }
UNASSIGNED() { curl -s "$API/assignments/$P/rooms" -H "Authorization: Bearer $LT" \
  | jq_ "r.unassigned.map(x => x.name).sort().join(' | ')"; }
GROUPFREE() { curl -s "$API/assignments/$P/groups" -H "Authorization: Bearer $LT" \
  | jq_ "r.unassigned.map(x => x.name).sort().join(' | ')"; }

WANT='Josverlyn | Marcos (Kim jung ho) | Shirley Coronel'

echo "── 세례명이 있으면 함께, 없으면 본명만 ──"
eq "대시보드 미리보기"  "$WANT" "$(RECENT)"
# 여러 화면이 **같은** 답을 내야 한다. 한 곳만 다르면 그 화면만 이상하고
# 아무도 이유를 모른다.
eq "  숙소 배정 화면"   "$WANT" "$(UNASSIGNED)"
eq "  말씀조 배정 화면" "$WANT" "$(GROUPFREE)"

echo
echo "── 본명은 감추지 않는다 ──"
# 여권·항공권·입국 안내는 본명이라야 한다. 괄호 안에 남아 있어야 한다.
eq "본명이 함께 있다" 'true' \
   "$(RECENT | node -pe "require('fs').readFileSync(0,'utf8').includes('(Kim jung ho)')")"

echo
echo "── 적을 것이 없어 기호만 넣은 경우 ──"
# '-' 를 그대로 쓰면 명단에 "- (Shirley Coronel)" 이라고 나온다.
eq "기호만 있으면 없는 것으로 본다" 'true' \
   "$(RECENT | node -pe "!require('fs').readFileSync(0,'utf8').includes('- (')")"

echo
echo "── 나중에 적어도 반영된다 ──"
T=$(login "dn-b-$$@test.local")
curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"Josverlyn","bibleName":"Josue","country":"KR","gender":"M","age":30}'
eq "세례명을 넣으면 바뀐다" 'Josue (Josverlyn) | Marcos (Kim jung ho) | Shirley Coronel' \
   "$(RECENT)"
# 지웠다 저장하면 빈 문자열이 남는다. 그때는 본명으로 돌아가야 한다.
curl -s -o /dev/null -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"Josverlyn","bibleName":"   ","country":"KR","gender":"M","age":30}'
eq "  지우면 본명으로 돌아간다" "$WANT" "$(RECENT)"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
