#!/usr/bin/env bash
# 대시보드 카드의 미리보기 — 숫자와 같은 요청에서 온다
#
# 사용: API=http://localhost:3000 ./scripts/e2e-dashboard-preview.sh
#
# 카드 안에 최근 몇 줄을 보여 준다. 그 줄을 따로 조회하면 "카드는 4명인데
# 미리보기는 둘" 같은 어긋남이 또 생긴다 — 식사 제한(036)과 투어(02ff25a)에서
# 이미 두 번 겪었다. 그래서 숫자와 한 요청에서 온다.
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
  -d '{"name":"미리보기 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"미리보기검증-%s","location":"x","startDate":"2027-07-01",
       "programType":"international","hostCountry":"AR","feeBasic":100,
       "options":[{"name":"가 인기투어","cost":50},{"name":"나 빈투어","cost":10}]}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

OPT=$(curl -s "$API/programs/$P" -H "Authorization: Bearer $LT" \
  | jq_ "r.program_options.find(o => o.name === '가 인기투어').id")

STATS() { curl -s "$API/programs/$P/stats" -H "Authorization: Bearer $LT"; }

enroll() { # $1=이름 $2=식사제한 $3=투어신청여부 $4=제출여부
  local t; t=$(login "prv-$1-$$@test.local")
  local opts='[]'
  [ "$3" = yes ] && opts="[\"$OPT\"]"
  curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"realName":"%s","country":"KR","gender":"M","age":30,
         "foodRequirements":"%s","selectedOptions":%s}' "$1" "$2" "$opts")" > /dev/null
  [ "$4" = yes ] && curl -s -X POST "$API/registrations/$P/me/submit" \
    -H "Authorization: Bearer $t" > /dev/null
  printf '%s' "$t"
}

echo "── 다섯 명 (최근 순으로 쌓는다) ──"
enroll 김요한 '없음'   yes yes > /dev/null
enroll 이사라 '견과류' yes no  > /dev/null
enroll 박누가 '없음'   no  yes > /dev/null
enroll 최마리아 '유당' no  yes > /dev/null
enroll 정바울 '없음'   no  no  > /dev/null

echo
echo "── 총 등록 미리보기 ──"
eq "세 줄까지만 온다" '3' "$(STATS | jq_ 'r.preview.recent.length')"
# 최근 순이어야 한다. 오래된 사람이 위에 있으면 미리보기의 뜻이 없다.
eq "  가장 최근 사람이 맨 위" '정바울' "$(STATS | jq_ 'r.preview.recent[0].name')"
# 크림색으로 구분하려면 완료 여부가 있어야 한다.
eq "  완료 여부가 함께 온다" 'false' "$(STATS | jq_ 'r.preview.recent[0].submitted')"
eq "  나라도 함께 온다"     'KR'    "$(STATS | jq_ 'r.preview.recent[0].country')"
eq "카드 숫자는 다섯"        '5'     "$(STATS | jq_ 'r.total_registrations')"

echo
echo "── 투어 미리보기 ──"
# 사람이 아니라 투어별 줄이다 — 담당자가 먼저 보는 것은 "어느 투어가 찼나".
eq "신청 많은 투어가 위" '가 인기투어' "$(STATS | jq_ 'r.preview.tours[0].name')"
eq "  신청 수가 함께"     '2'          "$(STATS | jq_ 'r.preview.tours[0].signup_count')"
# 아무도 신청 안 한 투어가 빠지면 담당자가 봐야 할 상황이 안 보인다.
eq "빈 투어도 남는다"     '나 빈투어'  "$(STATS | jq_ 'r.preview.tours[1].name')"
eq "  0 으로 온다"        '0'          "$(STATS | jq_ 'r.preview.tours[1].signup_count')"
eq "카드 숫자와 맞는다"   '2'          "$(STATS | jq_ 'r.tour_signup_count')"

echo
echo "── 식사 제한 미리보기 ──"
# "없음"을 고른 사람이 섞이면 안 된다.
eq "제한을 적은 사람만" '이사라,최마리아' \
   "$(STATS | jq_ "r.preview.meals.map(x => x.name).join()")"
eq "  무엇을 못 먹는지도" '견과류' "$(STATS | jq_ 'r.preview.meals[0].detail')"
# 크림색으로 구분하려면 여기에도 완료 여부가 있어야 한다 — 처음에 이 칸만
# 빠뜨려서 식사 제한 카드에서는 아직인 사람이 표시되지 않았다.
eq "  완료 여부도 함께"   'false'  "$(STATS | jq_ 'r.preview.meals[0].submitted')"
eq "    완료한 사람은 true" 'true'  "$(STATS | jq_ 'r.preview.meals[1].submitted')"
eq "카드 숫자와 맞는다"   '2'      "$(STATS | jq_ 'r.food_restriction_count')"

echo
echo "── 비어 있을 때 ──"
# 빈 배열이어야 한다. null 이 오면 앱의 `as List?` 가 그대로 빈 화면이 된다.
eq "항공편 미리보기는 빈 배열" '[]' \
   "$(STATS | node -pe "JSON.stringify(JSON.parse(require('fs').readFileSync(0)).preview.arrival)")"
eq "입금 대기도 빈 배열"       '[]' \
   "$(STATS | node -pe "JSON.stringify(JSON.parse(require('fs').readFileSync(0)).preview.pending)")"

echo
echo "── 이름 없는 등록은 미리보기에도 안 나온다 ──"
BLANK=$(login "prv-blank-$$@test.local")
curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $BLANK" \
  -H 'Content-Type: application/json' -d '{"country":"KR"}' > /dev/null
eq "맨 위가 그대로" '정바울' "$(STATS | jq_ 'r.preview.recent[0].name')"
eq "  숫자도 그대로" '5'     "$(STATS | jq_ 'r.total_registrations')"

echo
echo "── 권한 ──"
OTHER=$(login "prv-other-$$@test.local")
eq "담당자가 아니면 403" '403' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/$P/stats" \
      -H "Authorization: Bearer $OTHER")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
