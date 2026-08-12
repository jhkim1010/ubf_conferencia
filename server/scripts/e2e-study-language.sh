#!/usr/bin/env bash
# 말씀 공부 언어 · 소수 인원 방침 · 출발 자가 확인 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-study-language.sh
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
jqf() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); JSON.stringify($1)"; }

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
PT=$(login "sl-p-$$@test.local")
[ "$LT" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

PROG=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"말씀언어검증-%s","location":"검증","startDate":"2027-08-01",
       "programType":"international","hostCountry":"AR",
       "smallCohortPolicy":"absorb","minTeamSize":6}' "$$")" \
  | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''")
[ -n "$PROG" ] || { echo "생성 실패"; exit 1; }

prog() { curl -s "$API/programs/$PROG" -H "Authorization: Bearer $LT"; }
save() { # $1=본문 → http code
  curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/registrations/$PROG/me" \
    -H "Authorization: Bearer $PT" -H 'Content-Type: application/json' -d "$1"
}
mine() { curl -s "$API/registrations/$PROG/me" -H "Authorization: Bearer $PT"; }

echo "── 소수 인원 방침 (관리자가 정한다) ──"
eq "생성 시 방침이 저장된다"    '"absorb"' "$(prog | jqf 'r.small_cohort_policy')"
eq "최소 인원도 저장된다"        '6'        "$(prog | jqf 'Number(r.min_team_size)')"
curl -s -o /dev/null -X PATCH "$API/programs/$PROG" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"smallCohortPolicy":"merge","minTeamSize":4}'
eq "수정된다"                    '"merge"'  "$(prog | jqf 'r.small_cohort_policy')"
eq "  최소 인원도"               '4'        "$(prog | jqf 'Number(r.min_team_size)')"
eq "모르는 방침은 400"           '400' "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH \
      "$API/programs/$PROG" -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      -d '{"smallCohortPolicy":"whatever"}')"
eq "  거부 후 값이 그대로"       '"merge"'  "$(prog | jqf 'r.small_cohort_policy')"
eq "범위 밖 최소 인원은 400"     '400' "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH \
      "$API/programs/$PROG" -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
      -d '{"minTeamSize":99}')"

echo
echo "── 참석자가 고른 공부 언어 ──"
eq "저장된다" '200' "$(save '{"realName":"언어검증","country":"AR","branch":"검증","studyLanguage":"es"}')"
eq "  es 로 남는다"              '"es"' "$(mine | jqf 'r.study_language')"
eq "대문자도 받아 소문자로"      '200'  "$(save '{"realName":"언어검증","country":"AR","studyLanguage":"KO"}')"
eq "  ko 로 저장된다"            '"ko"' "$(mine | jqf 'r.study_language')"
# 안 보냈다고 지우면 안 된다. 임시저장처럼 이 화면을 안 거치는 저장이
# 참석자가 고른 언어를 날려 버리면 배정이 통째로 어긋난다.
eq "안 보내면 기존 값을 지우지 않는다" '200' "$(save '{"realName":"언어검증","country":"AR"}')"
eq "  ko 가 그대로"              '"ko"' "$(mine | jqf 'r.study_language')"
eq "두 글자가 아니면 무시한다"   '200'  "$(save '{"realName":"언어검증","country":"AR","studyLanguage":"korean"}')"
eq "  기존 값이 유지된다"        '"ko"' "$(mine | jqf 'r.study_language')"

echo
echo "── 출발 자가 확인 (API 없이 본인이 답한다) ──"
chk() { curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/registrations/$PROG/departure-check" \
    -H "Authorization: Bearer $PT" -H 'Content-Type: application/json' -d "$1"; }
eq "정상 출발"                   '200' "$(chk '{"status":"on_time"}')"
eq "  상태가 남는다"             '"on_time"' "$(mine | jqf 'r.departure_check.status')"
eq "  답한 시각도 남는다"        'true' "$(mine | jqf 'Boolean(r.departure_check.answered_at)')"
# 지연인데 새 시각이 없으면 픽업 담당자는 아무것도 다시 짤 수 없다.
eq "지연인데 시각이 없으면 400"  '400' "$(chk '{"status":"delayed"}')"
eq "지연 + 새 시각"              '200' "$(chk '{"status":"delayed","newTime":"2027-08-05T15:40"}')"
eq "  새 시각이 남는다"          '"2027-08-05T15:40"' "$(mine | jqf 'r.departure_check.new_time')"
eq "결항"                        '200' "$(chk '{"status":"cancelled","note":"항공사 취소"}')"
eq "  메모가 남는다"             '"항공사 취소"' "$(mine | jqf 'r.departure_check.note')"
eq "모르는 상태는 400"           '400' "$(chk '{"status":"maybe"}')"
eq "  마지막 답이 그대로"        '"cancelled"' "$(mine | jqf 'r.departure_check.status')"

curl -s -o /dev/null -X DELETE "$API/programs/$PROG" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"confirmName":"말씀언어검증-'$$'"}'

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
