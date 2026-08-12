#!/usr/bin/env bash
# 이름 없는 등록은 명단에서 빠진다 — 038
#
# 사용: API=http://localhost:3000 ./scripts/e2e-nameless.sh
#
# 앱을 열면 등록 행이 먼저 생기고 이름은 다음 화면에서 받는다. 그래서
# 열어만 보고 만 사람이 빈 행으로 남아 참가자 명단에 "이름 없는 등록자"로
# 섞였다. 운영에서 실제로 그렇게 보였다.
#
# **명단과 카드 숫자가 같은 판정을 쓰는지**가 이 시험의 핵심이다. 한쪽만
# 거르면 "10명인데 9명만 보인다"가 된다 — 식사 제한에서 똑같이 겪었다(036).
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
# 값을 못 꺼내면 ERR. 빈 문자열로 두면 응답이 통째로 비어도 검사가 통과한다.
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
  -d '{"name":"이름없음 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"이름없음검증-%s","location":"어딘가","startDate":"2027-07-01",
       "programType":"international","feeBasic":100}' "$$")" \
  | jq_ "r.id || r.existingId")
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

# 이름을 적은 사람 둘, 앱만 열어 본 사람 하나.
enroll() { # $1=이메일꼬리 $2=이름(비면 안 적은 것) $3=제출여부
  local t; t=$(login "nameless-$1-$$@test.local")
  if [ -n "$2" ]; then
    curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
      -H 'Content-Type: application/json' \
      --data-binary "$(printf '{"realName":"%s","country":"KR","gender":"M","age":30}' "$2")" > /dev/null
  else
    # 이름 없이 저장 — 앱이 화면을 넘어가며 만드는 빈 행과 같은 모양이다.
    curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $t" \
      -H 'Content-Type: application/json' -d '{"country":"KR"}' > /dev/null
  fi
  [ "$3" = "yes" ] && curl -s -X POST "$API/registrations/$P/me/submit" \
    -H "Authorization: Bearer $t" > /dev/null
  printf '%s' "$t"
}

echo "── 세 사람: 이름 둘 · 이름 없음 하나 ──"
enroll a "김요한" yes > /dev/null
enroll b "이사라" no  > /dev/null
BLANK=$(enroll c "" no)

roster() { curl -s "$API/programs/$P/registrations" -H "Authorization: Bearer $LT"; }
stats()  { curl -s "$API/programs/$P/stats" -H "Authorization: Bearer $LT"; }

eq "명단에 두 명만 나온다" '2' "$(roster | jq_ 'r.length')"
eq "  이름 없는 행은 없다" '' \
   "$(roster | jq_ "r.filter(x => !x.real_name || !x.real_name.trim()).map(x => x.id).join(',')")"

echo
echo "── 카드 숫자도 같은 판정을 쓴다 ──"
# 여기가 어긋나면 "10명인데 9명만 보인다" 가 된다.
eq "총 등록도 2" '2' "$(stats | jq_ 'r.total_registrations')"
eq "  등록 완료는 1" '1' "$(stats | jq_ 'r.submitted_count')"
eq "  명단 수 = 총 등록" "$(roster | jq_ 'r.length')" "$(stats | jq_ 'r.total_registrations')"

echo
echo "── 이름을 적으면 그때 들어온다 ──"
curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $BLANK" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"박마리아","country":"AR","gender":"F","age":25}' > /dev/null
eq "명단이 세 명이 된다" '3' "$(roster | jq_ 'r.length')"
eq "  카드도 3"          '3' "$(stats | jq_ 'r.total_registrations')"

echo
echo "── 공백만 적은 것은 이름이 아니다 ──"
curl -s -X PUT "$API/registrations/$P/me" -H "Authorization: Bearer $BLANK" \
  -H 'Content-Type: application/json' -d '{"realName":"   "}' > /dev/null
eq "다시 두 명으로 돌아간다" '2' "$(roster | jq_ 'r.length')"
eq "  카드도 2"             '2' "$(stats | jq_ 'r.total_registrations')"

echo
echo "── 준비 현황에는 남는다 ──"
# 이 화면은 "아직 시작도 안 한 사람이 누구인가" 를 보여 주는 것이 일이다.
# 여기서까지 빼면 챙겨야 할 사람이 화면에서 사라진다.
eq "이름 없는 사람이 '개인정보' 단계에서 막힌 것으로 나온다" 'personal' \
   "$(curl -s "$API/programs/$P/readiness" -H "Authorization: Bearer $LT" \
      | jq_ "(r.blocked || []).filter(b => !(b.name || \"\").trim()).map(b => b.stuck_at).join(',')")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
