#!/usr/bin/env bash
# 수양회 전후 숙박(호텔) 등급 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-hotel.sh
#
# 규칙: 등급은 관리자가 정하고, **외국에서 오는 사람만** 고른다. 개최국
# 참가자는 수양회 전후에 집으로 간다.
#
# 화면에서 감추는 것만으로는 부족하다. 예전 앱과 직접 호출은 그 화면을
# 거치지 않으므로 서버가 떨어뜨리는지 여기서 확인한다.
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
# 인증은 15분에 20회 제한이다. 토큰이 안 나오면 그 자리에서 멈춘다 —
# "undefined" 를 들고 진행하면 레이트 리밋을 기능 실패로 보고하게 된다.
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
NEW_LT=$(curl -s -X POST "$API/leaders/register" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"name":"e2e 리더"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

KR=$(login "ht-kr-$$@test.local")   # 해외 참가자 → 고를 수 있다
AR=$(login "ht-ar-$$@test.local")   # 개최국 참가자 → 못 고른다

HOTELS='[{"key":"h1","labels":{"ko":"3성급","en":"3-star","es":"3 estrellas"},"pricePerNight":50},
         {"key":"h2","labels":{"ko":"4성급","en":"4-star","es":"4 estrellas"},"pricePerNight":80},
         {"key":"h3","labels":{"ko":"금액 미정","en":"TBD","es":"Por definir"}}]'

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"숙박검증-%s","location":"호텔","startDate":"2027-07-01",
       "programType":"international","hostCountry":"AR","feeBasic":200,
       "hotelOptions":%s}' "$$" "$HOTELS")" \
  | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''")
[ -n "$P" ] || { echo "생성 실패"; exit 1; }

save() { # $1=토큰 $2=country $3=등급(빈 값이면 안 보냄) $4=전 $5=후 → http code
  local d="{\"realName\":\"숙박\",\"country\":\"$2\",\"branch\":\"검증\",\"feeTier\":\"basic\""
  if [ -n "$3" ]; then
    local k="\"$3\""; [ "$3" = null ] && k=null
    d="$d,\"hotelOptionKey\":$k,\"hotelNightsBefore\":$4,\"hotelNightsAfter\":$5"
  fi
  curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/registrations/$P/me" \
    -H "Authorization: Bearer $1" -H 'Content-Type: application/json' -d "$d}"
}
mine() { # $1=토큰 → "등급/전/후"
  curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $1" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0))||{};
                [r.hotel_option_key, r.hotel_nights_before, r.hotel_nights_after]
                  .map(v => String(v ?? 'null')).join('/')"
}
opts() {
  curl -s "$API/programs/$P" -H "Authorization: Bearer $LT" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0));
                (r.hotel_options||[]).map(o=>o.key+':'+String(o.pricePerNight)).join(',')"
}

echo "── 관리자가 정한 등급 ──"
eq "등급 목록이 저장된다" 'h1:50,h2:80,h3:null' "$(opts)"

echo
echo "── 해외 참가자 ──"
eq "고를 수 있다"        '200'      "$(save "$KR" KR h2 2 3)"
eq "  선택이 저장된다"   'h2/2/3'   "$(mine "$KR")"

echo
echo "── 개최국 참가자 ──"
# 자격이 없어도 저장 자체는 통과시킨다. 422 로 막으면 화면에 항목이 안 보이는
# 사람이 이름 한 글자도 못 고치는 상태에 갇힌다(할인에서 겪은 일이다).
eq "저장은 된다"          '200'      "$(save "$AR" AR h2 2 3)"
eq "  선택은 남지 않는다" 'null/0/0' "$(mine "$AR")"

echo
echo "── 잘못된 입력 ──"
eq "없는 등급은 떨어진다"   '200'      "$(save "$KR" KR h9 2 3)"
eq "  선택이 비워진다"      'null/0/0' "$(mine "$KR")"
eq "음수 박수는 0 으로"     '200'      "$(save "$KR" KR h1 -5 2)"
eq "  0/2 로 남는다"        'h1/0/2'   "$(mine "$KR")"
eq "상한을 넘으면 잘린다"   '200'      "$(save "$KR" KR h1 999 0)"
eq "  60 박으로 남는다"     'h1/60/0'  "$(mine "$KR")"

echo
echo "── 숙박 칸을 안 보낸 저장 ──"
# 임시저장처럼 이 단계를 안 거치는 저장이 선택을 날려 버리면 안 된다.
eq "다른 칸만 저장해도"   '200'     "$(save "$KR" KR "" 0 0)"
eq "  선택이 그대로 남는다" 'h1/60/0' "$(mine "$KR")"

echo
echo "── 스스로 비우기 ──"
eq "등급을 null 로 보내면" '200'      "$(save "$KR" KR null 0 0)"
eq "  선택이 지워진다"     'null/0/0' "$(mine "$KR")"

curl -s -o /dev/null -X DELETE "$API/programs/$P" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"confirmName":"숙박검증-%s"}' "$$")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
