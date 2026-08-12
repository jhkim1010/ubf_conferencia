#!/usr/bin/env bash
# 봉사 담당자 배정 — 지명 · 수락 · 확정 (039)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-service-assign.sh
#
# 015 는 참가자가 신청하는 데까지만 있었고 담당자 쪽이 통째로 없었다.
# 여기서 보는 것은 넷이다.
#   1. 지명은 부탁이지 확정이 아니다 (본인이 수락해야 확정)
#   2. 승인이 필요한 역할은 수락해도 바로 확정되지 않는다
#   3. 남의 부탁에 대신 답할 수 없다
#   4. 부족 인원이 숫자로 맞게 나온다
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
# 값을 못 꺼내면 ERR. 빈 문자열이면 응답이 통째로 비어도 검사가 통과한다.
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
  -d '{"name":"봉사배정 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"봉사배정검증-%s","location":"어딘가","startDate":"2027-07-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

enroll() { # $1=이름 → 토큰
  local t; t=$(login "svc-$1-$$@test.local")
  curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"realName":"%s","country":"KR","gender":"M","age":30}' "$1")" > /dev/null
  printf '%s' "$t"
}
regId() { # $1=참가자토큰
  curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $1" | jq_ "r.id"
}
BOARD() { curl -s "$API/service-signups/$P/board" -H "Authorization: Bearer $LT"; }
role() { BOARD | jq_ "r.roles.find(x => x.key === '$1').$2"; }

T1=$(enroll 김요한); R1=$(regId "$T1")
T2=$(enroll 이사라); R2=$(regId "$T2")
T3=$(enroll 박누가); R3=$(regId "$T3")

echo "── 역할 구성 ──"
# 기본 역할 + 담당자가 직접 만든 역할
ROLES='[{"key":"pickup","enabled":true,"needed":3},
        {"key":"meal_prep","enabled":true,"needed":2},
        {"key":"group_study_leader","enabled":true,"requires_approval":true,"needed":1},
        {"key":"custom:iguazu-bus-01","label":"  이과수  버스 인솔  ","enabled":true,"needed":1},
        {"key":"nope","enabled":true},
        {"key":"custom:no-label-01","enabled":true}]'
eq "역할 구성이 저장된다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/service-signups/$P/roles" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      --data-binary "$(printf '{"roles":%s}' "$ROLES")")"
eq "  모르는 키와 이름 없는 자유 역할은 버린다" '4' "$(BOARD | jq_ 'r.roles.length')"
eq "  자유 역할의 이름은 공백이 정리된다" '이과수 버스 인솔' \
   "$(role 'custom:iguazu-bus-01' 'label')"

echo
echo "── 지명은 부탁이지 확정이 아니다 ──"
invBody() { printf '{"registrationId":"%s","serviceKey":"%s"}' "$1" "$2"; }
inv() { curl -s -X POST "$API/service-signups/$P/invite" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' --data-binary "$(invBody "$1" "$2")"; }
# 코드만 필요할 때. 토큰을 골라 쓸 수 있어야 한다(권한 검사).
invCode() { # $1=등록id $2=역할 $3=토큰
  curl -s -o /dev/null -w '%{http_code}' -X POST "$API/service-signups/$P/invite" \
    -H "Authorization: Bearer $3" -H 'Content-Type: application/json' \
    --data-binary "$(invBody "$1" "$2")"
}
S1=$(inv "$R1" pickup | jq_ "r.id")
eq "지명하면 수락 대기" 'invited' "$(role pickup "people.find(p => p.registration_id === '$R1').status")"
eq "  아직 확정은 0" '0' "$(role pickup 'confirmed')"
# 답이 없다고 자리를 비워 두면 같은 자리에 또 부탁하게 된다.
eq "  자리는 이미 찼다고 센다" '1' "$(role pickup 'filled')"
eq "  3명 중 2명 부족" '2' "$(role pickup 'short')"

echo
echo "── 본인이 답한다 ──"
resp() { curl -s -X POST "$API/service-signups/$P/$1/respond" -H "Authorization: Bearer $2" \
  -H 'Content-Type: application/json' --data-binary "$(printf '{"accepted":%s}' "$3")"; }
eq "수락하면 확정" 'confirmed' "$(resp "$S1" "$T1" true | jq_ 'r.status')"
eq "  이미 답한 부탁에는 다시 못 답한다" '409' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/service-signups/$P/$S1/respond" \
      -H "Authorization: Bearer $T1" -H 'Content-Type: application/json' -d '{"accepted":true}')"

S2=$(inv "$R2" pickup | jq_ "r.id")
eq "거절하면 declined" 'declined' "$(resp "$S2" "$T2" false | jq_ 'r.status')"
eq "  거절한 사람은 자리를 비운다" '1' "$(role pickup 'filled')"
# 거절했던 사람에게 다시 부탁하는 일은 실제로 흔하다.
inv "$R2" pickup > /dev/null
eq "  다시 지명할 수 있다" 'invited' \
   "$(role pickup "people.find(p => p.registration_id === '$R2').status")"

echo
echo "── 남의 부탁에는 답할 수 없다 ──"
eq "다른 사람이 답하면 404" '404' \
   "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/service-signups/$P/$S1/respond" \
      -H "Authorization: Bearer $T3" -H 'Content-Type: application/json' -d '{"accepted":true}')"

echo
echo "── 승인이 필요한 역할 ──"
S3=$(inv "$R3" group_study_leader | jq_ "r.id")
# 수락해도 바로 확정되지 않는다 — 지부장 동의가 남아 있다.
eq "수락해도 승인 대기" 'awaiting_approval' "$(resp "$S3" "$T3" true | jq_ 'r.status')"
eq "  담당자가 확정을 눌러도 승인 대기" 'awaiting_approval' \
   "$(curl -s -X PATCH "$API/service-signups/$P/$S3" -H "Authorization: Bearer $LT" \
      -H 'Content-Type: application/json' -d '{"action":"confirm"}' | jq_ 'r.status')"

echo
echo "── 책임자는 역할마다 한 명 ──"
lead() { curl -s -X PATCH "$API/service-signups/$P/$1" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' --data-binary "$(printf '{"isLead":%s}' "$2")" > /dev/null; }
lead "$S1" true
eq "책임자 한 명" '김요한' \
   "$(role pickup "people.filter(p => p.is_lead).map(p => p.real_name).join(',')")"
S2B=$(role pickup "people.find(p => p.registration_id === '$R2').id")
lead "$S2B" true
eq "  새로 세우면 앞사람은 내려온다" '이사라' \
   "$(role pickup "people.filter(p => p.is_lead).map(p => p.real_name).join(',')")"

echo
echo "── 모자란 역할이 위로 온다 ──"
# 담당자가 화면을 열자마자 할 일을 봐야 한다.
# 이 시점의 부족분: 식사 준비 2 (필요 2 · 0명) > 픽업 1 (필요 3 · 김요한 확정
# + 이사라 수락 대기) > 말씀조 리더 0 (승인 대기도 자리는 찬 것) = 인솔 0.
eq "가장 모자란 역할이 첫 번째" 'meal_prep' "$(BOARD | jq_ 'r.roles[0].key')"
eq "  그 다음이 픽업"          'pickup'    "$(BOARD | jq_ 'r.roles[1].key')"
# 따옴표를 쓰지 않는다 — jq_ 의 인자는 홑따옴표로 감싸므로 안에 따옴표를
# 넣으면 node 가 스크립트 자체를 파싱하지 못하고, try/catch 도 소용이 없다.
eq "  부족분도 그 순서"        '2-1' \
   "$(BOARD | jq_ 'r.roles.slice(0,2).map(x => x.short).join(String.fromCharCode(45))')"

echo
echo "── 반려 ──"
eq "반려하면 rejected" 'rejected' \
   "$(curl -s -X PATCH "$API/service-signups/$P/$S1" -H "Authorization: Bearer $LT" \
      -H 'Content-Type: application/json' -d '{"action":"reject"}' | jq_ 'r.status')"
eq "  반려된 사람은 자리를 비운다" '1' "$(role pickup 'filled')"

echo
echo "── 막아야 하는 것 ──"
eq "없는 역할로 지명하면 400" '400' "$(invCode "$R1" nope "$LT")"
# 켜 두지 않은 역할로는 지명할 수 없다. 화면에 없는 자리가 생긴다.
eq "이 수양회에 없는 역할이면 400" '400' "$(invCode "$R1" cleaning "$LT")"
eq "담당자가 아니면 현황을 못 본다" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/service-signups/$P/board" \
      -H "Authorization: Bearer $T1")"
eq "담당자가 아니면 지명도 못 한다" '403' "$(invCode "$R3" pickup "$T1")"
eq "로그인 없으면 401" '401' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/service-signups/$P/board")"

echo
echo "── 본인이 보는 부탁 목록 ──"
# 키만 주면 화면이 "기타" 라고 부른다 — 무엇을 부탁받았는지 모른 채
# 수락하게 된다.
inv "$R3" 'custom:iguazu-bus-01' > /dev/null
MINE() { curl -s "$API/service-signups/$P/invites" -H "Authorization: Bearer $T3"; }
eq "자유 역할의 이름이 함께 온다" '이과수 버스 인솔' \
   "$(MINE | jq_ "r.find(x => x.service_key === 'custom:iguazu-bus-01').label")"
eq "  기본 역할은 이름이 비어 있다 (앱이 붙인다)" '' \
   "$(MINE | jq_ "r.find(x => x.service_key === 'group_study_leader').label")"
eq "  승인 필요 여부도 함께" 'true' \
   "$(MINE | jq_ "r.find(x => x.service_key === 'group_study_leader').requires_approval")"

echo
echo "── 이름 없는 등록은 여기에도 안 나온다 ──"
BLANK=$(login "svc-blank-$$@test.local")
curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $BLANK" \
  -H 'Content-Type: application/json' -d '{"country":"KR"}' > /dev/null
BR=$(curl -s "$API/registrations/$P/me" -H "Authorization: Bearer $BLANK" | jq_ "r.id")
eq "이름 없는 사람은 지명할 수 없다" '404' "$(invCode "$BR" pickup "$LT")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
