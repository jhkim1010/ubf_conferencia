#!/usr/bin/env bash
# 공항 픽업 명단에서 개최국 참가자를 빼는 규칙 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-pickup-host-country.sh
#
# 규칙: 국제 수양회의 개최국 참가자는 현지에서 오가므로 공항 픽업 대상이
# 아니다. 항공편이 없다는 이유로 미배차 칸에 계속 쌓이면 정작 마중이 필요한
# 사람이 묻힌다.
#
# 예외 둘을 함께 확인한다 — 이 둘이 깨지면 사람이 공항에 발이 묶인다.
#   1) 개최국 사람이라도 **항공편을 적어 냈으면 남는다** (국내선으로 온다)
#   2) 지역 수양회에는 적용하지 않는다 (전원이 개최국 사람이라 명단이 빈다)
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
# 로그인 실패를 삼키지 않는다.
#
# 인증 경로는 15분에 20회로 제한된다(index.js authLimiter). 이 스크립트는 한 번
# 도는 데 9번을 쓰므로 연달아 두 번 돌리면 걸린다. 예전에는 토큰 자리에
# "undefined" 가 들어간 채로 계속 진행해, 레이트 리밋을 **기능 실패로**
# 보고했다 — 규칙을 일부러 깨고 확인하던 중 실제로 그렇게 속았다.
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

LT=$(login "$LEADER")
# 리더 자격을 스스로 확보한다(미리 손질된 DB 를 요구하지 않기 위해).
NEW_LT=$(curl -s -X POST "$API/leaders/register" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"name":"e2e 리더"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"
[ "$LT" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

AR=$(login "pk-ar-$$@test.local")     # 개최국 사람, 항공편 없음 → 빠져야 한다
ARF=$(login "pk-arf-$$@test.local")   # 개최국 사람, 국내선 있음 → 남아야 한다
KR=$(login "pk-kr-$$@test.local")     # 해외 사람, 항공편 없음  → 남아야 한다

FLIGHT='{"flight_no":"AR1234","arrival_airport":"EZE","scheduled_arrival":"2027-07-01T08:00:00Z"}'

mk() { # $1=이름 $2=programType $3=hostCountry(빈 값이면 없음)
  local host="null"; [ -n "$3" ] && host="\"$3\""
  curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"name":"%s","location":"픽업제외검증","startDate":"2027-07-01",
         "programType":"%s","hostCountry":%s,"nearestAirport":"EZE",
         "feeBasic":200}' "$1" "$2" "$host")" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''"
}
# 미배차 목록은 submitted=true 인 사람만 본다. 저장만 하고 제출을 빠뜨리면
# 아무도 목록에 없어 "제외가 동작했다"로 잘못 읽힌다.
enroll() { # $1=programId $2=token $3=이름 $4=country $5=항공편JSON(빈 값이면 없음)
  local d="{\"realName\":\"$3\",\"country\":\"$4\",\"branch\":\"검증\",\"feeTier\":\"basic\""
  [ -n "$5" ] && d="$d,\"arrivalFlight\":$5"
  curl -s -o /dev/null -X PUT "$API/registrations/$1/me" \
    -H "Authorization: Bearer $2" -H 'Content-Type: application/json' -d "$d}"
  curl -s -o /dev/null -X POST "$API/registrations/$1/me/submit" \
    -H "Authorization: Bearer $2" -H 'Content-Type: application/json' -d '{}'
}
unassigned() { # $1=programId → 미배차 이름들 (정렬·쉼표 구분)
  curl -s "$API/transport/$1/runs?direction=arrival" -H "Authorization: Bearer $LT" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0));
                (r.unassigned||[]).map(u=>u.name).sort().join(',')"
}
exempt() { # $1=programId $2=token → 내 이동 정보의 pickupExempt
  curl -s "$API/transport/$1/my-transport" -H "Authorization: Bearer $2" \
    | node -pe "String(JSON.parse(require('fs').readFileSync(0)).pickupExempt)"
}
pickupNeeded() { # $1=programId → 준비 현황이 세는 픽업 인원
  curl -s "$API/programs/$1/readiness" -H "Authorization: Bearer $LT" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0));
                String(r?.readiness?.transport?.needed ?? 'null')"
}
cleanup() { # $1=programId $2=name
  curl -s -o /dev/null -X DELETE "$API/programs/$1" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"confirmName":"%s"}' "$2")"; }

echo "── 국제 수양회 (개최국 AR) ──"
I=$(mk "픽업제외-국제-$$" international AR)
[ -n "$I" ] || { echo "생성 실패"; exit 1; }
enroll "$I" "$AR"  "현지사람"   AR ""
enroll "$I" "$ARF" "국내선사람" AR "$FLIGHT"
enroll "$I" "$KR"  "해외사람"   KR ""

eq "미배차에 개최국 무항공편만 빠진다" '국내선사람,해외사람' "$(unassigned "$I")"
eq "  준비 현황도 같은 수를 센다"      '2'                   "$(pickupNeeded "$I")"

echo
echo "── 참가자 본인 화면 ──"
# 명단에서 빠졌다는 사실을 본인에게 알려야 한다. 알리지 않으면 오지 않을
# 차를 공항에서 기다린다.
eq "개최국 무항공편은 대상이 아니라고 알린다" 'true'  "$(exempt "$I" "$AR")"
eq "국내선을 적어 낸 사람은 대상이다"         'false' "$(exempt "$I" "$ARF")"
eq "해외 참석자는 대상이다"                   'false' "$(exempt "$I" "$KR")"

echo
echo "── 개최국을 옮기면 제외 대상도 옮겨간다 ──"
curl -s -o /dev/null -X PATCH "$API/programs/$I" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"programType":"international","hostCountry":"KR"}'
eq "이제 KR 참석자가 빠진다" '국내선사람,현지사람' "$(unassigned "$I")"
eq "  KR 참석자 본인도 안다" 'true'                "$(exempt "$I" "$KR")"

echo
echo "── 지역 수양회 ──"
# 전원이 개최국 사람이므로 적용하면 명단이 통째로 빈다.
L=$(mk "픽업제외-지역-$$" local AR)
[ -n "$L" ] || { echo "생성 실패"; exit 1; }
enroll "$L" "$AR" "현지사람" AR ""
eq "지역 수양회는 아무도 빼지 않는다" '현지사람' "$(unassigned "$L")"
eq "  본인 화면도 평소대로"           'false'    "$(exempt "$L" "$AR")"

cleanup "$I" "픽업제외-국제-$$"
cleanup "$L" "픽업제외-지역-$$"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
