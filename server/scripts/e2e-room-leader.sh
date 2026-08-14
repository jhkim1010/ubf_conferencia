#!/usr/bin/env bash
# 방장 (046)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-room-leader.sh
#
# 방장은 **그 방에서 자는 사람** 이라야 한다. 방에 없는 사람을 방장으로
# 세우면 현장에서 아무 소용이 없는데, 화면에는 이름이 있으니 아무도
# 알아채지 못한다. 그 규칙은 컬럼 제약으로 표현할 수 없어(배정이 다른 표에
# 있다) 라우트에서 본다 — 그래서 여기서 검사한다.
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
  -d '{"name":"방장 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"방장검증-%s","location":"x","startDate":"2027-11-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

ROOM=$(curl -s -X POST "$API/rooms/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"name":"301","floor":"3층","roomType":"dorm","capacity":4,"gender":"M"}' \
  | jq_ "r.id")
[ -n "$ROOM" ] && [ "$ROOM" != "ERR" ] || { echo "방을 만들지 못했습니다"; exit 1; }

person() { # $1=이름 → 등록 id
  local t; t=$(login "rl-$1-$$@test.local")
  curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"realName":"%s","country":"KR","gender":"M","age":30}' "$1")" \
    | jq_ "r.id || r.registration?.id"
}
A=$(person 방사람)
B=$(person 딴사람)
[ -n "$A" ] && [ "$A" != "ERR" ] || { echo "등록 id 를 못 얻었습니다: $A"; exit 1; }

curl -s -o /dev/null -X POST "$API/assignments/$P/rooms/assign" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"roomId":"%s","registrationId":"%s"}' "$ROOM" "$A")"

BOARD() { curl -s "$API/assignments/$P/rooms" -H "Authorization: Bearer $LT"; }
LEADER_OF() { BOARD | jq_ "r.rooms.find(x => x.id === '$ROOM').leaderRegistrationId"; }
SET() { # $1=등록id (빈 값이면 내림) → 상태 코드
  curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/assignments/$P/rooms/$ROOM/leader" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"registrationId":%s}' "$([ -n "$1" ] && printf '"%s"' "$1" || echo null)")"
}

echo "── 처음에는 방장이 없다 ──"
eq "배정은 됐다" '1' "$(BOARD | jq_ "r.rooms.find(x => x.id === '$ROOM').members.length")"
eq "  방장은 비어 있다" '' "$(LEADER_OF)"

echo
echo "── 방에 있는 사람을 세운다 ──"
eq "세워진다"       '200' "$(SET "$A")"
eq "  화면에도 온다" "$A" "$(LEADER_OF)"

echo
echo "── 방에 없는 사람은 안 된다 ──"
# 여기가 이 검사의 핵심이다. 통과하면 현장에서 연락이 닿지 않는 방장이 생긴다.
eq "거절한다"          '400' "$(SET "$B")"
eq "  방장은 그대로"   "$A"  "$(LEADER_OF)"

echo
echo "── 내릴 수 있다 ──"
eq "내려진다"     '200' "$(SET "")"
eq "  비어 있다"  ''    "$(LEADER_OF)"

echo
echo "── 방에서 빼면 방장도 아니다 ──"
curl -s -o /dev/null -X PUT "$API/assignments/$P/rooms/$ROOM/leader" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"registrationId":"%s"}' "$A")"
eq "다시 세웠다" "$A" "$(LEADER_OF)"
curl -s -o /dev/null -X DELETE "$API/assignments/$P/rooms/$A" -H "Authorization: Bearer $LT"
eq "  빼면 함께 내려간다" '' "$(LEADER_OF)"

echo
echo "── 자동 배정이 사람을 옮겨도 ──"
# 자동 배정은 배정을 통째로 다시 짠다. 방장을 그대로 두면 그 방에서 자지도
# 않는 사람이 방장으로 남는다.
curl -s -o /dev/null -X POST "$API/assignments/$P/rooms/assign" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"roomId":"%s","registrationId":"%s"}' "$ROOM" "$A")"
curl -s -o /dev/null -X PUT "$API/assignments/$P/rooms/$ROOM/leader" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"registrationId":"%s"}' "$A")"
ROOM2=$(curl -s -X POST "$API/rooms/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"name":"302","floor":"3층","roomType":"dorm","capacity":4,"gender":"M"}' | jq_ "r.id")
curl -s -o /dev/null -X POST "$API/assignments/$P/rooms/auto" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{}'
# 자동 배정 뒤에도 남아 있다면, 그 방에 실제로 있는 사람이라야 한다.
eq "남은 방장은 그 방 사람이다" 'true' \
   "$(BOARD | jq_ 'r.rooms.every(x => !x.leaderRegistrationId
        || x.members.some(m => m.registrationId === x.leaderRegistrationId))')"

echo
echo "── 권한 ──"
OTHER=$(login "rl-other-$$@test.local")
eq "담당자가 아니면 403" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/assignments/$P/rooms/$ROOM/leader" \
      -H "Authorization: Bearer $OTHER" -H 'Content-Type: application/json' \
      --data-binary "$(printf '{"registrationId":"%s"}' "$A")")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
