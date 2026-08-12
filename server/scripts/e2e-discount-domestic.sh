#!/usr/bin/env bash
# 할인 자격(개최국 참석자) 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-discount-domestic.sh
#
# 규칙: 할인은 개최국에서 오는 사람만 신청할 수 있다. 할인 항목은
# "1일만 참석" 처럼 현지에서 오가는 사람을 전제로 만들어지기 때문이다.
# 지역 수양회는 개최국이 없다 — 참가자가 모두 같은 나라라 제한하지 않는다.
#
# 화면에서 감추는 것만으로는 부족하다. 예전 앱과 직접 호출은 그 화면을
# 거치지 않으므로 서버가 막는지 여기서 확인한다.
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

LT=$(login "$LEADER")

# 리더 자격을 스스로 확보한다.
#
# 예전에는 이 계정이 미리 리더로 만들어져 있다고 가정했다. 그래서 e2e 가
# **미리 손질된 DB**를 필요로 했고, 결국 운영 DB 를 검증에 쓰게 됐다.
# 이미 리더면 400 이 돌아오고 기존 토큰을 그대로 쓴다.
NEW_LT=$(curl -s -X POST "$API/leaders/register" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"name":"e2e 리더"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"
AR=$(login "dc-ar-$$@test.local")   # 개최국(아르헨티나)에서 오는 사람
KR=$(login "dc-kr-$$@test.local")   # 다른 나라에서 오는 사람
[ "$LT" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

DISCOUNTS='[{"key":"d1","labels":{"ko":"1일만 참석","en":"One day only"},"amount":50}]'

mk() { # $1=이름 $2=programType $3=hostCountry(빈 값이면 없음)
  local host="null"; [ -n "$3" ] && host="\"$3\""
  curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"name":"%s","location":"할인자격검증","startDate":"2027-07-01",
         "programType":"%s","hostCountry":%s,
         "feeBasic":200,"discountOptions":%s}' "$1" "$2" "$host" "$DISCOUNTS")" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''"
}
save() { # $1=programId $2=token $3=country $4=할인신청여부 → http code
  local d="{\"realName\":\"할인자격\",\"country\":\"$3\",\"branch\":\"검증\",\"feeTier\":\"basic\""
  [ "$4" = yes ] && d="$d,\"discountRequested\":true,\"discountOptionKey\":\"d1\""
  curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/registrations/$1/me" \
    -H "Authorization: Bearer $2" -H 'Content-Type: application/json' -d "$d}"
}
requested() { # $1=programId $2=token → 저장된 신청 여부
  curl -s "$API/registrations/$1/me" -H "Authorization: Bearer $2" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); String(r?.discount_requested ?? 'null')"
}
# 등록자가 있으면 서버가 이름 확인을 요구한다(428). 빠뜨리면 조용히 실패하고
# 검증용 수양회가 DB 에 쌓인다 — 실제로 그렇게 쌓였다.
cleanup() { # $1=programId $2=name
  curl -s -o /dev/null -X DELETE "$API/programs/$1" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"confirmName":"%s"}' "$2")"; }

echo "── 국제 수양회 (개최국 AR) ──"
I=$(mk "할인자격-국제-$$" international AR)
[ -n "$I" ] || { echo "생성 실패"; exit 1; }
eq "개최국 참석자는 신청된다"      '200' "$(save "$I" "$AR" AR yes)"
eq "  신청으로 저장된다"           'true' "$(requested "$I" "$AR")"

# 자격이 없으면 **신청만 떨어뜨리고 저장은 통과시킨다.**
#
# 처음에는 422 로 거절했는데, 그러면 자격을 잃은 사람이 이름 한 글자도 저장할
# 수 없게 된다 — 화면에 할인 항목이 안 보이므로 스스로 취소할 수도 없다.
# 에뮬레이터로 확인하다 실제로 그 상태에 갇혔다.
eq "다른 나라 참석자도 저장은 된다" '200'   "$(save "$I" "$KR" KR yes)"
eq "  신청은 남지 않는다"           'false' "$(requested "$I" "$KR")"
eq "  할인 없이 저장해도 된다"      '200'   "$(save "$I" "$KR" KR no)"

echo
echo "── 개최국을 옮기면 자격도 옮겨간다 ──"
# 자격은 저장 시점에 판정한다. 개최국이 바뀌었는데 예전 판정을 그대로 쓰면
# 이제는 해당 없는 사람이 계속 신청할 수 있다.
curl -s -o /dev/null -X PATCH "$API/programs/$I" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"programType":"international","hostCountry":"KR"}'
eq "개최국이 KR 이 되면 KR 이 신청된다" '200'   "$(save "$I" "$KR" KR yes)"
eq "  신청으로 남는다"                  'true'  "$(requested "$I" "$KR")"
# 자격을 잃은 AR 참석자는 갇히지 않는다. 저장은 되고 예전 신청은 사라진다.
eq "AR 은 저장은 되고"                  '200'   "$(save "$I" "$AR" AR yes)"
eq "  예전 신청이 사라진다"             'false' "$(requested "$I" "$AR")"

echo
echo "── 지역 수양회 (개최국 없음) ──"
L=$(mk "할인자격-지역-$$" local "")
[ -n "$L" ] || { echo "생성 실패"; exit 1; }
eq "아무 나라나 신청된다"          '200' "$(save "$L" "$KR" KR yes)"
eq "  신청으로 저장된다"           'true' "$(requested "$L" "$KR")"

cleanup "$I" "할인자격-국제-$$"
cleanup "$L" "할인자격-지역-$$"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
