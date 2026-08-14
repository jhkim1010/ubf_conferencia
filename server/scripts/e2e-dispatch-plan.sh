#!/usr/bin/env bash
# 배차 준비 — 도착 시간대별 필요 차량 (042)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-dispatch-plan.sh
#
# 담당자가 배차에서 처음 묻는 것은 "차를 몇 대 불러야 하나" 인데, 지금까지
# 그 답이 화면 어디에도 없었다. 도착 시각은 이미 등록서에 다 있다.
#
# **여기서 센 대수만큼 밴을 만들면 자동 배차에 미배차가 남지 않아야 한다.**
# 그러지 않으면 숫자가 거짓말이 된다.
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
  -d '{"name":"배차준비 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"배차준비검증-%s","location":"x","startDate":"2027-07-01",
       "programType":"international","hostCountry":"AR","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

lands() { # $1=이름 $2=시각(ISO) $3=공항
  local t; t=$(login "dp-$1-$$@test.local")
  curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"realName":"%s","country":"KR","gender":"M","age":30,
         "arrivalFlight":{"arrival_airport":"%s","scheduled_arrival":"%s","flight_no":"XX100"}}' \
         "$1" "$3" "$2")" > /dev/null
  # 배차판은 **제출한 사람만** 본다. 제출하지 않으면 명단이 통째로 비어,
  # "미배차 없음" 같은 검사가 빈 목록끼리 비교하며 거짓 통과한다.
  curl -s -o /dev/null -X POST "$API/registrations/$P/me/submit" -H "Authorization: Bearer $t"
}
BOARD() { curl -s "$API/transport/$P/runs?direction=arrival" -H "Authorization: Bearer $LT"; }
plan() { BOARD | jq_ "r.plan$1"; }

echo "── 같은 공항, 가까운 시각 ──"
lands 김요한 '2027-07-01T06:10:00Z' EZE
lands 이사라 '2027-07-01T07:20:00Z' EZE
lands 박누가 '2027-07-01T14:20:00Z' EZE
# 명단이 비면 아래 검사들이 전부 빈 값끼리 비교하며 통과한다. 먼저 본다.
eq "배차 대상이 잡힌다" '3' "$(BOARD | jq_ 'r.unassigned.length')"
eq "시간대가 둘로 갈린다" '2' "$(plan '.length')"
eq "  이른 쪽이 먼저"     '2' "$(plan '[0].people')"
eq "  늦은 쪽은 한 명"    '1' "$(plan '[1].people')"

echo
echo "── 공항이 다르면 안 묶는다 ──"
# 한 대로 두 공항을 갈 수는 없다.
lands 최마리아 '2027-07-01T06:30:00Z' AEP
eq "시간대가 셋"        '3' "$(plan '.length')"
eq "  AEP 는 따로"      'AEP' \
   "$(plan ".find(b => b.people === 1 && b.airport === 'AEP').airport")"

echo
echo "── 필요 대수 ──"
# 7인승 기준. 아직 밴이 하나도 없으니 전부 부족이다.
eq "이른 시간대는 1대 필요" '1' \
   "$(plan ".find(b => b.airport === 'EZE' && b.people === 2).vans_to_add")"
eq "  이미 있는 자리는 0"   '0' \
   "$(plan ".find(b => b.airport === 'EZE' && b.people === 2).seats_have")"

echo
echo "── 밴을 만들면 부족이 줄어든다 ──"
VAN=$(curl -s -X POST "$API/transport/$P/runs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"direction":"arrival","airport":"EZE","capacity":7,"vehicle":"1호차"}' | jq_ "r.id")
eq "자리가 잡힌다"     '7' \
   "$(plan ".find(b => b.airport === 'EZE' && b.people === 2).seats_have")"
eq "  더 만들 것 없음" '0' \
   "$(plan ".find(b => b.airport === 'EZE' && b.people === 2).vans_to_add")"

echo
echo "── 센 대수와 자동 배차가 어긋나지 않는다 ──"
# 여기가 핵심. 부족하다고 말한 만큼 만들면 미배차가 남지 않아야 한다.
for n in 가 나 다 라 마 바; do lands "손님$n" '2027-07-01T14:30:00Z' EZE; done
NEED=$(plan ".find(b => b.airport === 'EZE' && b.people >= 7).vans_to_add")
eq "부족하다고 말한다" '1' "$NEED"
i=0
while [ "$i" -lt "${NEED:-0}" ]; do
  curl -s -o /dev/null -X POST "$API/transport/$P/runs" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"direction":"arrival","airport":"EZE","capacity":7,"vehicle":"추가%s호차"}' "$i")"
  i=$((i+1))
done
curl -s -o /dev/null -X POST "$API/transport/$P/runs/auto" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"direction":"arrival"}'
eq "  자동 배차 뒤 미배차 없음 (EZE)" '0' \
   "$(BOARD | jq_ "r.unassigned.filter(u => u.airport === 'EZE').length")"

echo
echo "── 태워 달라고 안 한 사람 ──"
# 자차로 오는 사람 때문에 차를 더 부르면 안 된다.
SOLO=$(login "dp-solo-$$@test.local")
curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $SOLO" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"자차","country":"KR","gender":"M","age":30,"needsPickup":false,
       "arrivalFlight":{"arrival_airport":"EZE","scheduled_arrival":"2027-07-01T06:15:00Z"}}' > /dev/null
curl -s -o /dev/null -X POST "$API/registrations/$P/me/submit" -H "Authorization: Bearer $SOLO"
eq "시간대 인원이 그대로" '2' \
   "$(plan ".find(b => b.airport === 'EZE' && b.from.startsWith('2027-07-01T06')).people")"

echo
echo "── 권한 ──"
OTHER=$(login "dp-other-$$@test.local")
eq "담당자가 아니면 403" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/transport/$P/runs?direction=arrival" \
      -H "Authorization: Bearer $OTHER")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
