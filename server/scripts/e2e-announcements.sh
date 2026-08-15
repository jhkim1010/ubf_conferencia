#!/usr/bin/env bash
# 공지 보내기 — 전체 또는 일부에게 (044)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-announcements.sh
#
# 좁히려던 것이 넓어지는 쪽이 가장 나쁘다. 한 방에만 보내려던 공지가 전원에게
# 가면 되돌릴 수 없다. 그래서 대상이 이상하면 아무에게도 보내지 않는다.
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
  -d '{"name":"공지 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"공지검증-%s","location":"x","startDate":"2027-07-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

send() { # $1=본문 조각 → http 코드
  curl -s -o /dev/null -w '%{http_code}' -X POST "$API/announcements/$P" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
    --data-binary "$1"
}
LIST() { curl -s "$API/announcements/$P" -H "Authorization: Bearer $LT"; }

echo "── 전체에게 ──"
eq "보내진다" '201' "$(send '{"body":"내일 아침 7시 강당에 모입니다"}')"
eq "  기록이 남는다" '1' "$(LIST | jq_ 'r.length')"
eq "  대상은 전체"   'all' "$(LIST | jq_ 'r[0].audience_kind')"
# 보낸 뒤 다시 세면 사람이 바뀌어 있다. 보낼 당시 몇 대에 갔는지를 남긴다.
eq "  보낸 기기 수가 남는다" '0' "$(LIST | jq_ 'Number(r[0].recipients)')"

echo
echo "── 방·조에만 ──"
ROOM=$(curl -s -X POST "$API/rooms/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"name":"302호","roomType":"dorm","capacity":4,"gender":"M"}' | jq_ "r.id")
eq "방에만 보낼 수 있다" '201' \
   "$(send "$(printf '{"body":"302호 물이 안 나옵니다","audience":{"kind":"room","id":"%s"}}' "$ROOM")")"
eq "  대상이 남는다" 'room' "$(LIST | jq_ 'r[0].audience_kind')"
eq "  어느 방인지도" "$ROOM" "$(LIST | jq_ 'r[0].audience_id')"

echo
echo "── 좁히려던 것이 넓어지면 안 된다 ──"
# 대상이 이상하면 아무에게도 보내지 않는다. 전체로 떨어뜨리지 않는다.
eq "모르는 갈래는 400" '400' "$(send '{"body":"x","audience":{"kind":"everyone"}}')"
eq "방인데 id 가 없으면 400" '400' "$(send '{"body":"x","audience":{"kind":"room"}}')"
eq "  남의 수양회 방이면 404" '404' \
   "$(send '{"body":"x","audience":{"kind":"room","id":"0f8fad5b-d9cb-469f-a165-70867728950e"}}')"
eq "  막힌 것들은 기록도 안 남는다" '2' "$(LIST | jq_ 'r.length')"

echo
echo "── 내용 ──"
eq "빈 내용은 400" '400' "$(send '{"body":"   "}')"
eq "  긴 내용은 잘린다" '1000' \
   "$(send "$(node -pe "JSON.stringify({body: 'ㄱ'.repeat(3000)})")" > /dev/null; LIST | jq_ 'r[0].body.length')"

echo
echo "── 봉사팀에 보내기 ──"
# "픽업 담당들만" 처럼 팀 하나에 말할 일이 실제로 많다. 대상은 방·조와
# 달리 UUID 가 아니라 역할 키다.
curl -s -o /dev/null -X PUT "$API/service-signups/$P/roles" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"roles":[{"key":"pickup","enabled":true,"needed":2}]}'
eq "봉사팀에 보낸다" '201' \
   "$(send '{"body":"픽업 담당들 9시에 모입니다","audience":{"kind":"service","id":"pickup"}}')"
eq "  대상이 남는다"   'service' "$(LIST | jq_ 'r[0].audience_kind')"
eq "  어느 팀인지도"   'pickup'  "$(LIST | jq_ 'r[0].audience_id')"
# 어느 팀인지 없으면 전체에게 가는 셈이다 — 좁히려던 것이 넓어지는 쪽이
# 가장 나쁘다.
eq "팀을 안 고르면 400" '400' \
   "$(send '{"body":"x","audience":{"kind":"service"}}')"
# 담당자가 만든 역할도 보낼 수 있어야 한다.
curl -s -o /dev/null -X PUT "$API/service-signups/$P/roles" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"roles":[{"key":"pickup","enabled":true,"needed":2},
                {"key":"custom:iguazu-bus-01","label":"이과수 버스","enabled":true,"needed":1}]}'
eq "자유 역할 팀에도 보낸다" '201' \
   "$(send '{"body":"버스 인솔 모임","audience":{"kind":"service","id":"custom:iguazu-bus-01"}}')"

echo
echo "── 권한 ──"
OTHER=$(login "ann-other-$$@test.local")
eq "담당자가 아니면 403" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/announcements/$P" \
      -H "Authorization: Bearer $OTHER" -H 'Content-Type: application/json' \
      -d '{"body":"x"}')"
eq "  목록도 못 본다" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/announcements/$P" \
      -H "Authorization: Bearer $OTHER")"
eq "로그인 없으면 401" '401' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/announcements/$P")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
