#!/usr/bin/env bash
# 공동 관리자 세우기 — 만든 사람이 정한다
#
# 사용: API=http://localhost:3000 ./scripts/e2e-program-admins.sh
#
# 예전에는 director 만 부를 수 있는 API 뿐이었고 앱에는 화면이 없었다.
# 그래서 수양회를 만든 사람은 명단을 함께 볼 사람을 세울 방법이 없었다.
#
# 여기서 보는 것은 셋이다.
#   1. 만든 사람은 세울 수 있고, 공동 관리자는 더 세우지 못한다
#   2. 만든 사람은 뺄 수 없다 (빼면 수양회가 잠긴다)
#   3. 세워진 사람은 실제로 명단·배정을 볼 수 있다
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
login() {
  local body; body=$(curl -s -X POST "$API/auth/dev-login" \
    -H 'Content-Type: application/json' -d "{\"email\":\"$1\"}")
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
  -d '{"name":"관리자지정 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"관리자검증-$$\",\"location\":\"어딘가\",\"startDate\":\"2027-07-01\",
       \"programType\":\"international\",\"feeBasic\":100}" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

MAIL_A="padm-a-$$@test.local"
MAIL_B="padm-b-$$@test.local"
enroll() { # $1=이메일 $2=이름 → 토큰
  local t; t=$(login "$1")
  curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    -d "{\"realName\":\"$2\",\"country\":\"KR\",\"gender\":\"M\",\"age\":30}" > /dev/null
  printf '%s' "$t"
}
TA=$(enroll "$MAIL_A" 김요한)
TB=$(enroll "$MAIL_B" 이사라)
# 끝까지 관리자가 되지 않는 사람. TB 는 뒤에서 관리자가 되므로 "아무나
# 막히는가" 를 확인하는 데 쓸 수 없다 — 처음에 그렇게 썼다가 200 이 나왔다.
TC=$(enroll "padm-c-$$@test.local" 박누가)
RA=$(curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $TA" | jq_ "r.id")

LIST() { curl -s "$API/admins/programs/$P" -H "Authorization: Bearer $LT"; }

echo "── 처음에는 만든 사람뿐 ──"
eq "목록에 한 명" '1' "$(LIST | jq_ 'r.length')"
# 화면은 "누가 이 수양회를 볼 수 있는가" 를 보여 준다. 만든 사람이 빠지면
# 목록이 비어 보이고, 자기가 왜 보이는지 알 수 없다.
eq "  그 한 명이 만든 사람" 'true' "$(LIST | jq_ 'r[0].is_owner')"

echo
echo "── 참가자 명단에서 골라 세운다 ──"
eq "명단에서 고르면 세워진다" 'true' \
   "$(curl -s -X POST "$API/admins/programs/$P" -H "Authorization: Bearer $LT" \
      -H 'Content-Type: application/json' \
      -d "{\"registrationId\":\"$RA\"}" | jq_ 'r.success')"
eq "  목록이 두 명" '2' "$(LIST | jq_ 'r.length')"
eq "  만든 사람이 맨 위" 'true' "$(LIST | jq_ 'r[0].is_owner')"

echo
echo "── 목록에 없는 사람은 이메일로 ──"
eq "이메일로 세운다" 'true' \
   "$(curl -s -X POST "$API/admins/programs/$P" -H "Authorization: Bearer $LT" \
      -H 'Content-Type: application/json' \
      -d "{\"email\":\"$MAIL_B\"}" | jq_ 'r.success')"
# 대소문자가 달라도 같은 사람이다. 구글 주소를 손으로 옮겨 적으면 흔하다.
eq "  대소문자가 달라도 같은 사람" '3' "$(LIST | jq_ 'r.length')"
eq "없는 이메일이면 404" '404' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/admins/programs/$P" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      -d '{"email":"nobody-here@test.local"}')"
eq "이메일도 참가자도 없으면 400" '400' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/admins/programs/$P" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' -d '{}')"

echo
echo "── 세워진 사람은 실제로 볼 수 있다 ──"
# 목록에만 오르고 화면이 안 열리면 세운 뜻이 없다.
eq "참가자 명단이 열린다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/registrations" \
      -H "Authorization: Bearer $TA")"
eq "봉사 배정도 열린다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/service-signups/$P/board" \
      -H "Authorization: Bearer $TA")"

echo
echo "── 공동 관리자는 관리자를 더 세우지 못한다 ──"
# 한 번 들어온 사람이 다른 사람을 계속 불러들이면, 만든 사람이 그 사실을
# 모른 채 지나간다.
eq "목록도 못 본다" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/admins/programs/$P" \
      -H "Authorization: Bearer $TA")"
eq "세우지도 못한다" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/admins/programs/$P" \
      -H "Authorization: Bearer $TA" -H 'Content-Type: application/json' \
      -d "{\"email\":\"$MAIL_B\"}")"

echo
echo "── 만든 사람은 뺄 수 없다 ──"
# 빼고 나면 아무도 관리자를 세울 수 없어 수양회가 잠긴다.
OWNER=$(LIST | jq_ 'r.find(x => x.is_owner).id')
eq "만든 사람 제거는 409" '409' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/admins/programs/$P/$OWNER" \
      -H "Authorization: Bearer $LT")"
eq "  목록은 그대로 셋" '3' "$(LIST | jq_ 'r.length')"

echo
echo "── 빼기 ──"
UA=$(LIST | jq_ "r.find(x => x.email === '$MAIL_A').id")
eq "공동 관리자는 뺄 수 있다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/admins/programs/$P/$UA" \
      -H "Authorization: Bearer $LT")"
eq "  목록이 둘" '2' "$(LIST | jq_ 'r.length')"
eq "  빠진 사람은 명단을 못 본다" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/registrations" \
      -H "Authorization: Bearer $TA")"

echo
echo "── 권한을 넓힌 화면 셋이 여전히 막히는지 ──"
# stats·registrations·readiness 를 requireLeader 에서 requireProgramAdmin 으로
# 옮겼다. 넓힌 쪽만 확인하고 좁은 쪽을 안 보면, 아무나 명단을 보게 된다.
for path in stats registrations readiness; do
  eq "  등록만 한 사람은 $path 403" '403' \
     "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/$path" \
        -H "Authorization: Bearer $TC")"
  eq "  로그인 없으면 $path 401" '401' \
     "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/$path")"
done

echo
echo "── 남의 수양회 ──"
OTHER_LT=$(login "padm-other-$$@test.local")
OTHER_LT=$(curl -s -X POST "$API/leaders/register" -H "Authorization: Bearer $OTHER_LT" \
  -H 'Content-Type: application/json' -d '{"name":"남"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''")
eq "다른 리더는 403" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/admins/programs/$P" \
      -H "Authorization: Bearer $OTHER_LT")"
eq "로그인 없으면 401" '401' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/admins/programs/$P")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
