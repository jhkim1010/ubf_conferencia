#!/usr/bin/env bash
# 방마다 여유 자리 — 042
#
# 사용: API=http://localhost:3000 ./scripts/e2e-room-extra.sh
#
# 2인실에 셋, 4인실에 다섯이 들어가는 일은 수양회에서 흔하다. 정원을 3인·5인
# 으로 적어 버리면 자동 배정이 **처음부터** 그 자리를 정상 자리로 보고 채운다.
# 여유는 정원과 따로 세고, 마지막에만 쓴다.
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
  -d '{"name":"여유자리 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"여유자리검증-%s","location":"x","startDate":"2027-07-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

room() { # $1=이름 $2=정원 $3=여유 → id
  curl -s -X POST "$API/rooms/$P" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"name":"%s","roomType":"dorm","capacity":%s,"gender":"M","extraCapacity":%s}' "$1" "$2" "$3")" \
    | jq_ "r.id"
}
enroll() { # $1=이름 → 토큰
  local t; t=$(login "rex-$1-$$@test.local")
  curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"realName":"%s","country":"KR","gender":"M","age":30}' "$1")" > /dev/null
  printf '%s' "$t"
}
ASSIGN() { curl -s "$API/assignments/$P/rooms" -H "Authorization: Bearer $LT"; }
inRoom() { ASSIGN | jq_ "r.rooms.find(x => x.name === '$1').members.length"; }

echo "── 방 만들기 ──"
A=$(room 101호 2 1)
B=$(room 102호 2 1)
eq "여유가 저장된다" '1' "$(ASSIGN | jq_ "r.rooms.find(x => x.name === '101호').extra_capacity")"
# 2인실에 다섯을 넣는 것은 여유가 아니라 정원을 잘못 적은 것이다.
C=$(room 103호 2 9)
eq "  터무니없는 값은 잘린다" '3' "$(ASSIGN | jq_ "r.rooms.find(x => x.name === '103호').extra_capacity")"
curl -s -o /dev/null -X DELETE "$API/rooms/$P/$C" -H "Authorization: Bearer $LT"

echo
echo "── 정원이 남아 있으면 여유를 안 쓴다 ──"
# 안 깔아도 될 간이침대가 첫 방부터 깔리면 안 된다.
for n in 김요한 이사라 박누가; do enroll "$n" > /dev/null; done
curl -s -o /dev/null -X POST "$API/assignments/$P/rooms/auto" -H "Authorization: Bearer $LT"
eq "101호에 둘"  '2' "$(inRoom 101호)"
eq "102호에 하나" '1' "$(inRoom 102호)"

echo
echo "── 정원이 모자라면 여유를 연다 ──"
# 방 하나(2+1)에 셋.
curl -s -o /dev/null -X DELETE "$API/rooms/$P/$B" -H "Authorization: Bearer $LT"
curl -s -o /dev/null -X POST "$API/assignments/$P/rooms/auto" -H "Authorization: Bearer $LT"
eq "셋 다 101호에" '3' "$(inRoom 101호)"
eq "  남는 사람 없음" '0' "$(ASSIGN | jq_ 'r.unassigned.length')"

echo
echo "── 여유까지 차면 더는 안 들어간다 ──"
enroll 최마리아 > /dev/null
curl -s -o /dev/null -X POST "$API/assignments/$P/rooms/auto" -H "Authorization: Bearer $LT"
eq "101호는 셋에서 멈춘다" '3' "$(inRoom 101호)"
eq "  한 명이 남는다"     '1' "$(ASSIGN | jq_ 'r.unassigned.length')"

echo
echo "── 손으로 넣을 때 ──"
# 담당자가 직접 넣는 것은 "간이침대를 하나 더 놓겠다" 는 뜻이다.
LEFT=$(ASSIGN | jq_ 'r.unassigned[0].registrationId')
eq "여유가 다 찼으면 422" '422' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/assignments/$P/rooms/assign" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      --data-binary "$(printf '{"roomId":"%s","registrationId":"%s"}' "$A" "$LEFT")")"

D=$(room 104호 1 1)
eq "  정원 1 · 여유 1 이면 둘째까지 들어간다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/assignments/$P/rooms/assign" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      --data-binary "$(printf '{"roomId":"%s","registrationId":"%s"}' "$D" "$LEFT")")"

echo
echo "── 좌석 합계 ──"
# 여유를 정원에 더해 버리면 "정원 대비 등록" 이 부풀어, 실제로는 간이침대를
# 깔아야 하는 상황이 여유 있는 것처럼 보인다.
SUM() { curl -s "$API/rooms/$P" -H "Authorization: Bearer $LT"; }
eq "정원 합계에 여유가 섞이지 않는다" '3' "$(SUM | jq_ 'Number(r.summary.totalSeats)')"
eq "  여유는 따로 온다"               '2' "$(SUM | jq_ 'Number(r.summary.extraSeats)')"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
