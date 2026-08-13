#!/usr/bin/env bash
# 수양회를 고쳐도 이미 한 투어 신청이 살아남는가
#
# 사용: API=http://localhost:3000 ./scripts/e2e-tour-option-stability.sh
#
# 예전에는 저장할 때마다 옵션을 전부 비활성화하고 새로 넣었다. 그래서 저장할
# 때마다 옵션 id 가 바뀌었고, 이미 신청한 사람의 selected_options 는 죽은
# id 를 가리키게 됐다. 그 선택은 투어 화면에서 사라지는데 대시보드 카드에는
# 남아서, 운영에서 카드는 4명인데 안에는 2명이었다.
#
# 여기서 보는 것은 셋이다.
#   1. 고쳐도 옵션 id 가 그대로다
#   2. 이미 한 신청이 화면에서 사라지지 않는다
#   3. 카드 숫자와 투어 화면이 같은 것을 센다
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
  -d '{"name":"옵션안정 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"옵션안정검증-%s","location":"x","startDate":"2027-07-01",
       "programType":"international","feeBasic":100,
       "options":[{"name":"시티투어","cost":50},{"name":"이과수","cost":120}]}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

GET() { curl -s "$API/programs/$P" -H "Authorization: Bearer $LT"; }
optId() { GET | jq_ "r.program_options.find(o => o.name === '$1').id"; }
SIGN() { curl -s "$API/programs/$P/tour-signups" -H "Authorization: Bearer $LT"; }
tour() { SIGN | jq_ "r.tours.find(t => t.name === '$1').$2"; }
card() { curl -s "$API/programs/$P/stats" -H "Authorization: Bearer $LT" | jq_ 'r.tour_signup_count'; }

CITY=$(optId 시티투어)
IGZ=$(optId 이과수)

# 참가자가 시티투어를 신청한다.
T1=$(login "opt-a-$$@test.local")
curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $T1" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"realName":"김요한","country":"KR","gender":"M","age":30,
       "selectedOptions":["%s"]}' "$CITY")" > /dev/null

echo "── 신청 직후 ──"
eq "투어 화면에 한 명" '1' "$(tour 시티투어 signup_count)"
eq "  카드도 한 명"   '1' "$(card)"

echo
echo "── 수양회를 고친다 (이름만 바꾸고 저장) ──"
# 화면이 보내는 그대로 — 옵션에 id 가 들어 있다.
BODY=$(printf '{"name":"옵션안정검증-%s(수정)","options":[
   {"id":"%s","name":"시티투어","cost":60},
   {"id":"%s","name":"이과수","cost":120}]}' "$$" "$CITY" "$IGZ")
eq "저장이 통한다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$API/programs/$P" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      --data-binary "$BODY")"
eq "옵션 id 가 그대로다" "$CITY" "$(optId 시티투어)"
eq "  바꾼 값은 반영된다" '60' "$(GET | jq_ "r.program_options.find(o => o.name === '시티투어').cost")"
# 여기가 핵심. 예전에는 이 자리에서 신청이 사라졌다.
eq "신청이 살아남는다" '1' "$(tour 시티투어 signup_count)"
eq "  이름도 그대로"   '김요한' "$(tour 시티투어 "people.map(p => p.real_name).join()")"
eq "  카드와 화면이 같다" "$(tour 시티투어 signup_count)" "$(card)"

echo
echo "── 투어를 하나 지운다 ──"
BODY2=$(printf '{"options":[{"id":"%s","name":"시티투어","cost":60}]}' "$CITY")
curl -s -o /dev/null -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' --data-binary "$BODY2"
eq "목록에서 빠진다" '1' "$(GET | jq_ 'r.program_options.length')"
eq "  남은 투어의 신청은 그대로" '1' "$(tour 시티투어 signup_count)"

echo
echo "── 새 투어를 더한다 (id 없이) ──"
BODY3=$(printf '{"options":[{"id":"%s","name":"시티투어","cost":60},{"name":"새 투어","cost":10}]}' "$CITY")
curl -s -o /dev/null -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' --data-binary "$BODY3"
eq "새 투어가 생긴다" '2' "$(GET | jq_ 'r.program_options.length')"
eq "  기존 id 는 그대로" "$CITY" "$(optId 시티투어)"

echo
echo "── 옛 클라이언트처럼 id 없이 저장하면 (신청이 미아가 된다) ──"
# 이 경우까지 막지는 않는다. 대신 카드가 미아를 세지 않는지를 본다 —
# 예전에는 세어서 카드 4명 / 화면 2명이 됐다.
curl -s -o /dev/null -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"options":[{"name":"시티투어","cost":60}]}'
eq "화면에서는 0명" '0' "$(tour 시티투어 signup_count)"
eq "  카드도 0명 (같은 것을 센다)" '0' "$(card)"

echo
echo "── 미아를 고치는 스크립트 ──"
node scripts/repair-orphan-tour-choices.js --yes > /dev/null 2>&1
eq "신청이 살아 있는 투어로 옮겨진다" '1' "$(tour 시티투어 signup_count)"
eq "  카드도 따라온다" '1' "$(card)"

echo
echo "── 같은 투어를 두 번 담아도 ──"
NEWCITY=$(optId 시티투어)
curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $T1" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"realName":"김요한","country":"KR","gender":"M","age":30,
       "selectedOptions":["%s","%s","%s"]}' "$NEWCITY" "$NEWCITY" "$NEWCITY")" > /dev/null
# 세는 쪽은 사람 단위라 중복이 있어도 1 이 나온다 — 그것으로는 중복 제거를
# 확인할 수 없다(그렇게 썼다가 제거를 빼도 통과했다). 저장된 배열을 본다.
eq "저장된 배열에 한 번만 들어간다" '1' \
   "$(curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $T1" \
      | jq_ 'r.selected_options.length')"
eq "  세는 쪽도 한 명" '1' "$(tour 시티투어 signup_count)"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
