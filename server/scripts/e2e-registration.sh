#!/usr/bin/env bash
# 등록 플로우 API 종단 검증 — 국내(개최국) / 해외 두 시나리오
#
# 사용: API=http://localhost:3000 PROG=<programId> ./scripts/e2e-registration.sh
#
# UI 렌더링(항공편 생략 카드)은 확인하지 못한다. 그 전제가 되는 데이터 경로
# — 개최국 판정에 쓰이는 host_country / users.region, 항공편 유무 저장 — 을 검증한다.

# 이 스크립트는 /auth/dev-login 을 쓴다. 서버가 ENABLE_DEV_LOGIN=1 로 떠 있어야 한다
# (기본은 비활성 — 설정을 빠뜨리면 닫히는 fail-closed 구조다).
set -uo pipefail
API="${API:-http://localhost:3000}"
PROG="${PROG:?PROG(programId) 가 필요합니다}"

pass=0; fail=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
bad()  { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }

login() { # $1=email
  curl -s -X POST "$API/auth/dev-login" -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"email":"%s"}' "$1")" | node -pe "JSON.parse(require('fs').readFileSync(0)).token"
}
jqf() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); const v=$1; v===undefined?'undefined':JSON.stringify(v)"; }

echo "── 사전 확인 ─────────────────────────────"
HOST=$(curl -s "$API/programs/$PROG" -H "Authorization: Bearer $(login dev@test.com)" | jqf 'r.host_country')
[ "$HOST" = '"BR"' ] && ok "프로그램 개최국 = BR" || bad "개최국" '"BR"' "$HOST"

echo
echo "── 시나리오 A: 국내 참석자 (region=BR, 개최국과 동일) ──"
TA=$(login dev@test.com)
curl -s -X PUT "$API/registrations/$PROG/me" -H "Authorization: Bearer $TA" -H 'Content-Type: application/json' \
  -d '{"realName":"김국내","country":"BR","branch":"상파울루","gender":"M","age":29,
       "foodRequirements":"채식","volunteerResources":["driving","cooking"]}' > /dev/null
RA=$(curl -s "$API/registrations/$PROG/me" -H "Authorization: Bearer $TA")

[ "$(echo "$RA" | jqf 'r.real_name')" = '"김국내"' ] \
  && ok "이름 저장" || bad "이름 저장" '"김국내"' "$(echo "$RA" | jqf 'r.real_name')"
[ "$(echo "$RA" | jqf 'r.arrival_flight')" = 'null' ] \
  && ok "항공편 없이 저장됨 (국내는 생략 가능)" || bad "항공편" 'null' "$(echo "$RA" | jqf 'r.arrival_flight')"

SA=$(curl -s -X POST "$API/registrations/$PROG/me/submit" -H "Authorization: Bearer $TA")
RA2=$(curl -s "$API/registrations/$PROG/me" -H "Authorization: Bearer $TA")
[ "$(echo "$RA2" | jqf 'r.submitted')" = 'true' ] \
  && ok "항공편 없이 제출 완료 — 국내 참석자는 막히지 않는다" \
  || bad "제출" 'true' "$(echo "$RA2" | jqf 'r.submitted')  응답=$SA"

echo
echo "── 시나리오 B: 해외 참석자 (region=PE) ──"
TB=$(login overseas@test.com)
curl -s -X PUT "$API/registrations/$PROG/me" -H "Authorization: Bearer $TB" -H 'Content-Type: application/json' \
  -d '{"realName":"Maria Silva","country":"PE","branch":"리마","gender":"F","age":34,
       "arrivalFlight":{"flight_no":"LA8062","arrival_airport":"GRU","scheduled_arrival":"2026-08-13T21:40:00Z"},
       "departureFlight":{"flight_no":"LA8063","departure_airport":"GRU","scheduled_departure":"2026-08-19T09:15:00Z"},
       "foodRequirements":"알레르기: 견과류"}' > /dev/null
RB=$(curl -s "$API/registrations/$PROG/me" -H "Authorization: Bearer $TB")

[ "$(echo "$RB" | jqf 'r.real_name')" = '"Maria Silva"' ] \
  && ok "이름 저장" || bad "이름 저장" '"Maria Silva"' "$(echo "$RB" | jqf 'r.real_name')"
[ "$(echo "$RB" | jqf 'r.arrival_flight && r.arrival_flight.flight_no')" = '"LA8062"' ] \
  && ok "도착 항공편 저장" || bad "도착 항공편" '"LA8062"' "$(echo "$RB" | jqf 'r.arrival_flight')"
[ "$(echo "$RB" | jqf 'r.departure_flight && r.departure_flight.flight_no')" = '"LA8063"' ] \
  && ok "출발 항공편 저장" || bad "출발 항공편" '"LA8063"' "$(echo "$RB" | jqf 'r.departure_flight')"

curl -s -X POST "$API/registrations/$PROG/me/submit" -H "Authorization: Bearer $TB" > /dev/null
RB2=$(curl -s "$API/registrations/$PROG/me" -H "Authorization: Bearer $TB")
[ "$(echo "$RB2" | jqf 'r.submitted')" = 'true' ] \
  && ok "제출 완료" || bad "제출" 'true' "$(echo "$RB2" | jqf 'r.submitted')"

echo
echo "── 관리자 집계 반영 확인 ──"
TL=$(login leader@test.com)
ST=$(curl -s "$API/admins/programs/$PROG" -H "Authorization: Bearer $TL")
echo "  응답: $(echo "$ST" | head -c 300)"

echo
echo "════════════════════════════════"
echo "통과 $pass · 실패 $fail"
[ $fail -eq 0 ] || exit 1
