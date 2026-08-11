#!/usr/bin/env bash
# 투어별 신청 상황 — 대시보드 "등록 완료" 카드를 대신하는 화면
#
# 사용: API=http://localhost:3000 ./scripts/e2e-tour-signups.sh
#
# 담당자가 이 화면에서 알아야 하는 것은 셋이다: 어느 투어가 얼마나 찼는가,
# 누가 신청했는가, 그중 누가 아직 등록을 안 끝냈는가.
#
# 신청자가 없는 투어가 목록에서 빠지지 않는지를 특히 본다 — 아무도 신청하지
# 않은 투어야말로 담당자가 봐야 할 상황인데, 없으면 보이지 않는다.
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
  -d '{"name":"투어신청 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"투어신청검증-$$\",\"location\":\"이과수\",\"startDate\":\"2027-07-01\",
       \"programType\":\"international\",\"feeBasic\":100,
       \"options\":[{\"name\":\"가 이과수\",\"cost\":120,\"capacity\":2},
                    {\"name\":\"나 아무도\",\"cost\":50}]}" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

OPT=$(curl -s "$API/programs/$P" -H "Authorization: Bearer $LT" \
  | jq_ "r.program_options.find(o => o.name === '가 이과수').id")

join() { # $1=이름 $2=제출여부 $3=투어신청여부
  local t; t=$(login "ts-$1-$$@test.local")
  local opts='[]'
  [ "$3" = yes ] && opts="[\"$OPT\"]"
  curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    -d "{\"realName\":\"$1\",\"country\":\"KR\",\"gender\":\"M\",\"age\":30,
         \"selectedOptions\":$opts}" > /dev/null
  [ "$2" = yes ] && curl -s -X POST "$API/registrations/$P/me/submit" \
    -H "Authorization: Bearer $t" > /dev/null
  printf '%s' "$t"
}

echo "── 신청 둘(하나는 아직 등록 진행 중) · 투어 안 간 사람 하나 ──"
join 김요한 yes yes > /dev/null
join 이사라 no  yes > /dev/null
join 박누가 yes no  > /dev/null

SIGN() { curl -s "$API/programs/$P/tour-signups" -H "Authorization: Bearer $LT"; }
tour() { SIGN | jq_ "r.tours.find(t => t.name === '$1').$2"; }

eq "투어 둘이 모두 나온다" '2' "$(SIGN | jq_ 'r.tours.length')"
# 아무도 신청하지 않은 투어가 빠지면, 담당자가 봐야 할 상황이 안 보인다.
eq "  아무도 신청 안 한 투어도 남는다" '0' "$(tour '나 아무도' 'signup_count')"

echo
echo "── 각 투어의 신청 상황 ──"
eq "신청 수"       '2' "$(tour '가 이과수' 'signup_count')"
eq "  그중 등록 완료" '1' "$(tour '가 이과수' 'submitted_count')"
eq "  정원 2 · 잔여 0" '0' "$(tour '가 이과수' 'remaining')"
# 정원이 없으면 잔여도 없다. 0 을 주면 "다 찼다" 로 읽힌다.
eq "  정원 없는 투어의 잔여는 빈 값" '' "$(tour '나 아무도' 'remaining')"

echo
echo "── 사람마다 완료 여부가 붙는다 (표에서 노란 줄로 구분한다) ──"
eq "신청자 이름이 나온다" '김요한,이사라' \
   "$(tour '가 이과수' "people.map(p => p.real_name).join(',')")"
eq "  완료한 사람"   '김요한' \
   "$(tour '가 이과수' "people.filter(p => p.submitted).map(p => p.real_name).join(',')")"
eq "  아직인 사람"   '이사라' \
   "$(tour '가 이과수' "people.filter(p => !p.submitted).map(p => p.real_name).join(',')")"
eq "투어를 안 간 사람은 어느 투어에도 없다" '' \
   "$(SIGN | jq_ "r.tours.flatMap(t => t.people).filter(p => p.real_name === '박누가').map(p => p.real_name).join(',')")"

echo
echo "── 대시보드 카드 숫자 ──"
# 카드는 "n명" 이라고 말한다. 신청 건수가 아니라 사람 수여야 한다.
eq "투어를 하나라도 신청한 사람 수" '2' \
   "$(curl -s "$API/programs/$P/stats" -H "Authorization: Bearer $LT" \
      | jq_ 'r.tour_signup_count')"

echo
echo "── 이름 없는 등록은 여기에도 안 나온다 ──"
BLANK=$(login "ts-blank-$$@test.local")
curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $BLANK" \
  -H 'Content-Type: application/json' \
  -d "{\"country\":\"KR\",\"selectedOptions\":[\"$OPT\"]}" > /dev/null
eq "명단은 그대로 두 명" '2' "$(tour '가 이과수' 'signup_count')"

echo
echo "── 권한 ──"
OTHER=$(login "ts-other-$$@test.local")
eq "담당자가 아니면 403" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/tour-signups" \
      -H "Authorization: Bearer $OTHER")"
eq "로그인 없으면 401" '401' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/tour-signups")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
