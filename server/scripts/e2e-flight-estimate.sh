#!/usr/bin/env bash
# 예상 도착·출발 날짜 종단 검증 (021)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-flight-estimate.sh
#
# 핵심은 "저장되는가"가 아니라 **예상이 확정으로 집계되지 않는가**이다.
# 예전에는 arrival_flight 가 NULL 만 아니면 항공편 완료로 세서, 아직 예매도
# 하지 않은 사람이 확정 항공편과 똑같이 잡혔다. 오류가 나지 않아 담당자는
# 다 모였다고 믿게 되는 종류의 오답이다.
#
# 서버가 ENABLE_DEV_LOGIN=1 로 떠 있어야 한다.
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
login() {
  curl -s -X POST "$API/auth/dev-login" -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"email":"%s"}' "$1")" | node -pe "JSON.parse(require('fs').readFileSync(0)).token"
}
jqf() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); const v=$1; v===undefined?'undefined':JSON.stringify(v)"; }

E=flight@test.com
T=$(login $E); LT=$(login "$LEADER")
[ "$T" != undefined ] && [ "$LT" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

PROG=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"name":"항공편검증용(e2e)","location":"테스트","startDate":"2027-03-01","hostCountry":"KR"}' \
  | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''")
[ -n "$PROG" ] || { echo "검증용 수양회 생성 실패"; exit 1; }
echo "검증용 수양회: $PROG"
echo

# 검증이 끝나면 만든 수양회를 지운다.
#
# 예전에는 지우지 않아 DB 에 같은 이름의 수양회가 계속 쌓였다. 등록자가 있으면
# 서버가 이름 확인을 요구하므로(428) confirmName 을 함께 보낸다 — 이것을
# 빠뜨리면 조용히 실패하고 찌꺼기가 남는다. trap 이라 도중에 죽어도 지운다.
cleanup_program() {
  [ -n "${PROG:-}" ] || return 0
  curl -s -o /dev/null -X DELETE "$API/programs/$PROG" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
    -d '{"confirmName":"항공편검증용(e2e)"}'
}
trap cleanup_program EXIT


save() {
  curl -s -X PUT "$API/registrations/$PROG/me" -H "Authorization: Bearer $T" \
    -H 'Content-Type: application/json' -d "$1" >/dev/null
}
stats() { curl -s "$API/programs/$PROG/stats" -H "Authorization: Bearer $LT" | jqf "$1"; }
mine() {
  curl -s "$API/programs/$PROG/registrations" -H "Authorization: Bearer $LT" \
    | node -pe "const rs=JSON.parse(require('fs').readFileSync(0));
       const r=rs.find(x=>x.real_name==='항공편테스트')||{}; const v=$1;
       v===undefined?'undefined':JSON.stringify(v)"
}

echo "── 예매 전: 날짜만 ──"
save '{"realName":"항공편테스트","country":"BR","branch":"상파울루",
  "arrivalFlight":{"estimated":true,"scheduled_arrival":"2027-02-28T10:00:00.000Z"}}'
eq "예상 플래그 저장"        'true'  "$(mine 'r.arrival_flight.estimated')"
eq "날짜는 남는다"           'true'  "$(mine '!!r.arrival_flight.scheduled_arrival')"
eq "확정으로 세지 않는다"     'false' "$(mine 'r.arrival_confirmed')"
eq "통계에도 안 잡힌다"       '0'     "$(stats 'Number(r.arrival_flight_count)')"

echo
echo "── 예매 후: 항공편 번호 입력 ──"
save '{"realName":"항공편테스트","country":"BR","branch":"상파울루",
  "arrivalFlight":{"estimated":false,"flight_no":"LA8084","scheduled_arrival":"2027-02-28T10:00:00.000Z"}}'
eq "확정으로 센다"           'true'  "$(mine 'r.arrival_confirmed')"
eq "통계에 잡힌다"           '1'     "$(stats 'Number(r.arrival_flight_count)')"

echo
echo "── 번호 없이 날짜만 (예상 표시도 없음) ──"
# 마중을 나갈 수 없으므로 확정이 아니다.
save '{"realName":"항공편테스트","country":"BR","branch":"상파울루",
  "arrivalFlight":{"scheduled_arrival":"2027-02-28T10:00:00.000Z"}}'
eq "번호 없으면 미확정"       'false' "$(mine 'r.arrival_confirmed')"
eq "통계 0"                  '0'     "$(stats 'Number(r.arrival_flight_count)')"

echo
echo "── 예매했다가 다시 예상으로 ──"
save '{"realName":"항공편테스트","country":"BR","branch":"상파울루",
  "arrivalFlight":{"estimated":true,"flight_no":"LA8084","scheduled_arrival":"2027-02-28T10:00:00.000Z"}}'
eq "예상이면 번호가 있어도 미확정" 'false' "$(mine 'r.arrival_confirmed')"

echo
echo "통과 $pass  실패 $fail"
[ "$fail" -eq 0 ]
