#!/usr/bin/env bash
# 일정에 이어 둔 봉사 (045)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-schedule-service.sh
#
# 일정 알림은 이미 시작 5분 전에 나간다. 거기에 "이 순서에 봉사자가 아직
# 모자랍니다" 를 얹는다 — 사람들이 그 일을 가장 떠올리는 순간이다.
#
# 크론은 직접 돌릴 수 없으므로, 여기서는 **저장과 판정**을 본다:
# 역할이 제대로 이어지는지, 모자랄 때만 모집이 열리는지.
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
  -d '{"name":"일정봉사 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"일정봉사검증-%s","location":"x","startDate":"2027-07-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

curl -s -o /dev/null -X PUT "$API/service-signups/$P/roles" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"roles":[{"key":"meal_prep","enabled":true,"needed":4}]}'

mk() { # $1=제목 $2=봉사키(없으면 빈칸)
  curl -s -X POST "$API/schedules/$P" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"title":"%s","scheduledAt":"2027-07-01T17:00:00Z","serviceKey":"%s"}' "$1" "$2")"
}
LIST() { curl -s "$API/schedules/$P" -H "Authorization: Bearer $LT"; }

echo "── 일정에 역할을 잇는다 ──"
S1=$(mk 저녁식사준비 meal_prep | jq_ "r.id")
eq "이어진다" 'meal_prep' "$(LIST | jq_ "r.find(x => x.id === '$S1').service_key")"
# 모르는 값이 붙으면 알림에 "custom:9f2c…" 같은 것이 나간다.
S2=$(mk 개회예배 엉뚱한값 | jq_ "r.id")
eq "  모르는 값은 안 잇는다" '' "$(LIST | jq_ "r.find(x => x.id === '$S2').service_key")"

echo
echo "── 고칠 때 ──"
# 제목만 고치는 저장이 이어 둔 역할을 지우면 안 된다.
# 이 검사는 요청이 실패해도 통과한다 — 값이 안 바뀌는 것이 정답이기
# 때문이다. 실제로 성공했는지 먼저 본다. (여기서 200 을 안 보다가, 시각을
# 안 보내는 저장이 전부 500 이던 것을 놓칠 뻔했다.)
eq "제목만 고치는 저장이 통한다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$API/schedules/$P/$S1" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      -d '{"title":"저녁 식사 준비(수정)"}')"
eq "  제목만 고쳐도 역할은 그대로" 'meal_prep' \
   "$(LIST | jq_ "r.find(x => x.id === '$S1').service_key")"
# 빈 문자열은 "끊겠다" 는 뜻이다.
eq "  끊는 저장도 통한다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$API/schedules/$P/$S1" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      -d '{"serviceKey":""}')"
eq "  빈 값이면 끊는다" '' "$(LIST | jq_ "r.find(x => x.id === '$S1').service_key")"
curl -s -o /dev/null -X PATCH "$API/schedules/$P/$S1" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"serviceKey":"meal_prep"}'
eq "  다시 이을 수 있다" 'meal_prep' \
   "$(LIST | jq_ "r.find(x => x.id === '$S1').service_key")"

echo
echo "── 알림이 나갈 때의 판정 ──"
# 크론은 여기서 못 돌리므로, 크론이 쓰는 것과 같은 판정을 확인한다.
BOARD() { curl -s "$API/service-signups/$P/board" -H "Authorization: Bearer $LT"; }
eq "지금은 4명 부족" '4' \
   "$(BOARD | jq_ "r.roles.find(x => x.key === 'meal_prep').short")"

# 네 명을 채우면 부족이 0 이 되고, 알림에 줄이 붙지 않아야 한다.
for n in 가 나 다 라; do
  t=$(login "sch-$n-$$@test.local")
  curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"realName":"손%s","country":"KR","gender":"M","age":30}' "$n")" > /dev/null
  curl -s -o /dev/null -X POST "$API/service-signups/$P/apply" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' -d '{"serviceKey":"meal_prep"}'
done
eq "네 명이 손을 들면 부족 0" '0' \
   "$(BOARD | jq_ "r.roles.find(x => x.key === 'meal_prep').short")"
# 다 찬 역할까지 알리면 정작 급한 일정 알림도 무시당한다.
eq "  다 찼으므로 모집도 안 열린다" '' \
   "$(curl -s "$API/service-signups/$P/open" -H "Authorization: Bearer $(login "sch-x-$$@test.local")" \
      | jq_ 'r.map(x => x.service_key).join()')"

echo
echo "── 권한 ──"
OTHER=$(login "sch-other-$$@test.local")
eq "담당자가 아니면 일정을 못 만든다" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/schedules/$P" \
      -H "Authorization: Bearer $OTHER" -H 'Content-Type: application/json' \
      -d '{"title":"x","scheduledAt":"2027-07-01T17:00:00Z"}')"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
