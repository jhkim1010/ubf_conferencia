#!/usr/bin/env bash
# 통화 규칙 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-currency-rule.sh
#
# 규칙:
#   · 국제 수양회는 항상 USD — 여러 나라에서 오는 참가자가 한 화면에서
#     서로 다른 통화를 보면 자기가 얼마를 내는지 비교할 수 없다.
#   · 지역 수양회는 그 나라 통화를 고를 수 있다.
#
# 화면에서 통화 선택을 숨기는 것만으로는 부족하다. 예전 앱이나 직접 호출은
# 그 화면을 거치지 않으므로 서버가 강제하는지 여기서 확인한다.
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
login() {
  curl -s -X POST "$API/auth/dev-login" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\"}" | node -pe "JSON.parse(require('fs').readFileSync(0)).token"
}

LT=$(login "$LEADER")
[ "$LT" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

mk() { # $1=이름 $2=programType $3=currency → programId
  curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"$1\",\"location\":\"통화검증\",\"startDate\":\"2027-06-01\",
         \"programType\":\"$2\",\"currency\":\"$3\",\"feeBasic\":100}" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''"
}
cur() { # $1=programId → 저장된 통화
  curl -s "$API/programs/$1" -H "Authorization: Bearer $LT" \
    | node -pe "JSON.parse(require('fs').readFileSync(0)).currency||''"
}
patch() { # $1=programId $2=programType $3=currency → http code
  curl -s -o /dev/null -w '%{http_code}' -X PATCH "$API/programs/$1" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
    -d "{\"programType\":\"$2\",\"currency\":\"$3\"}"
}
cleanup() { curl -s -o /dev/null -X DELETE "$API/programs/$1" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' -d '{}'; }

echo "── 국제 수양회 ──"
I=$(mk "통화검증-국제-$$(date +%s 2>/dev/null || echo x)" international ARS)
[ -n "$I" ] || { echo "생성 실패"; exit 1; }
eq "ARS 를 보내도 USD 로 저장된다"        'USD' "$(cur "$I")"
eq "KRW 로 수정해도 USD 로 남는다"        '200' "$(patch "$I" international KRW)"
eq "  수정 후에도 USD"                   'USD' "$(cur "$I")"

echo
echo "── 지역 수양회 ──"
L=$(mk "통화검증-지역-$$(date +%s 2>/dev/null || echo y)" local ARS)
[ -n "$L" ] || { echo "생성 실패"; exit 1; }
eq "고른 통화가 그대로 저장된다"          'ARS' "$(cur "$L")"
eq "다른 나라 통화로 바꿀 수 있다"        '200' "$(patch "$L" local BRL)"
eq "  BRL 로 남는다"                     'BRL' "$(cur "$L")"

echo
echo "── 유형을 바꿀 때 ──"
eq "지역→국제 로 바꾸면 USD 가 된다"      '200' "$(patch "$L" international BRL)"
eq "  USD 로 강제된다"                   'USD' "$(cur "$L")"
eq "국제→지역 은 다시 고를 수 있다"       '200' "$(patch "$L" local ARS)"
eq "  ARS 로 저장된다"                   'ARS' "$(cur "$L")"

echo
echo "── 잘못된 입력 ──"
eq "세 글자가 아닌 통화는 400"            '400' "$(patch "$L" local peso)"
eq "  거부 후 값이 바뀌지 않는다"         'ARS' "$(cur "$L")"

cleanup "$I"; cleanup "$L"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
