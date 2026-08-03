#!/usr/bin/env bash
# 같은 지부 지부장의 수양회 알림(033) 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-chapter-programs.sh
#
# 가장 중요한 것은 **앱이 "내 지부는 이것" 이라고 우길 수 없는가**다.
# 우길 수 있으면 아무 지부나 적어 남의 수양회 UUID 를 받아 갈 수 있고,
# UUID 는 참가의 열쇠이므로 그것은 자물쇠를 없애는 것과 같다.
set -uo pipefail
API="${API:-http://localhost:3000}"

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
jq_() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); String((r$1) ?? '')"; }
names() { curl -s "$API/programs/for-my-chapter" -H "Authorization: Bearer $1" \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).map(p=>p.name).sort().join(',')"; }

# 지부장 두 명 — 같은 나라의 다른 지부
L1=$(login "chp-lead1-$$@test.local")
L2=$(login "chp-lead2-$$@test.local")
# 형제 둘 — 각각 그 지부 소속
M1=$(login "chp-mem1-$$@test.local")
NEW=$(login "chp-new-$$@test.local")   # 한 번도 등록한 적 없는 사람

reg() { # $1=토큰 $2=이름 $3=지부 → leaders 등록 + 지부 기록
  local body='{"name":"'"$2"'","chapter":"'"$3"'","nationIso":"AR"}'
  curl -s -X POST "$API/leaders/register" -H "Authorization: Bearer $1" \
    -H 'Content-Type: application/json' -d "$body" \
    | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null
}
NL1=$(reg "$L1" "부에노스 지부장" "BUENOS AIRES"); [ -n "$NL1" ] && L1="$NL1"
NL2=$(reg "$L2" "코르도바 지부장" "CORDOBA");     [ -n "$NL2" ] && L2="$NL2"

mk() { # $1=리더토큰 $2=이름 → id
  curl -s -X POST "$API/programs" -H "Authorization: Bearer $1" \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"$2\",\"location\":\"검증\",\"startDate\":\"2027-07-01\",
         \"endDate\":\"2027-07-05\",\"programType\":\"local\",\"feeBasic\":10}" \
    | jq_ ".id || r.existingId"
}
P1=$(mk "$L1" "부에노스수양회-$$")
P2=$(mk "$L2" "코르도바수양회-$$")
[ ${#P1} -eq 36 ] && [ ${#P2} -eq 36 ] || { echo "생성 실패"; exit 1; }

echo "── 처음 오는 사람 ──"
# 나라·지부를 알 방법이 없다. UUID 가 유일한 길이고 그것이 맞다.
eq "아무것도 안 나온다" '' "$(names "$NEW")"

echo
echo "── 우리 지부 지부장의 수양회 ──"
# 형제가 부에노스아이레스 지부로 한 번 등록한다(다른 수양회에).
OTHER=$(mk "$L2" "지난수양회-$$")
curl -s -o /dev/null -X PUT "$API/registrations/$OTHER/me" -H "Authorization: Bearer $M1" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"형제","country":"AR","branch":"BUENOS AIRES","feeTier":"basic"}'
eq "우리 지부 것만 보인다" "부에노스수양회-$$" "$(names "$M1")"

echo
echo "── 이미 등록한 수양회는 알리지 않는다 ──"
curl -s -o /dev/null -X PUT "$API/registrations/$P1/me" -H "Authorization: Bearer $M1" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"형제","country":"AR","branch":"BUENOS AIRES","feeTier":"basic"}'
eq "목록에서 빠진다" '' "$(names "$M1")"

echo
echo "── 앱이 지부를 우길 수 없다 ──"
# 이 경로는 몸통을 받지 않는다. 서버가 내 등록서만 보고 판단한다.
eq "지부를 보내도 무시된다" '' \
  "$(curl -s "$API/programs/for-my-chapter?branch=CORDOBA&country=AR" \
      -H "Authorization: Bearer $M1" \
      | node -pe "JSON.parse(require('fs').readFileSync(0)).map(p=>p.name).join(',')")"
eq "로그인 없으면 401" '401' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/for-my-chapter")"

echo
echo "── 경로가 /:id 에 먹히지 않는다 ──"
# for-my-chapter 가 프로그램 id 로 잡히면 UUID 파싱에서 깨진다.
eq "200 으로 목록을 준다" '200' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/programs/for-my-chapter" -H "Authorization: Bearer $M1")"

for id in "$P1" "$P2" "$OTHER"; do
  curl -s -o /dev/null -X DELETE "$API/programs/$id" -H "Authorization: Bearer $L1" \
    -H 'Content-Type: application/json' -d '{"confirmName":"x"}' 2>/dev/null
done

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
