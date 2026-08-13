#!/usr/bin/env bash
# 현장 대표 연락처를 여러 명 둘 수 있는가 — 040
#
# 사용: API=http://localhost:3000 ./scripts/e2e-program-contacts.sh
#
# 005 에서 두 명분을 컬럼으로 박아 뒀는데, 실제로는 공항·숙소·차량을 나눠
# 맡는 사람이 그보다 많다. 목록으로 바꾸되 **이미 적어 둔 두 명이 사라지지
# 않아야** 하고, 옛 앱이 깔린 기기에서도 계속 보여야 한다.
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
  -d '{"name":"연락처 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

mk() { # $1=본문 조각 → 수양회 id
  curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"name":"연락처검증-%s-%s","location":"x","startDate":"2027-07-01",
         "programType":"international","feeBasic":100,%s}' "$$" "$2" "$1")" \
    | jq_ "r.id || r.existingId"
}
GET() { curl -s "$API/programs/$1" -H "Authorization: Bearer $LT"; }
names() { GET "$1" | jq_ "r.contacts.map(c => c.name).join()"; }

echo "── 넷을 적어 만든다 ──"
P=$(mk '"contacts":[
   {"name":"Marcos Kim","phone":"+54-11-3012-3113"},
   {"name":"Nicolas Mendoza","phone":"+54-11-2554-6976"},
   {"name":"  Ana   Perez  ","phone":" +54-11-1111-2222 "},
   {"name":"","phone":""}]' a)
[ -n "$P" ] && [ "$P" != "ERR" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }
eq "셋이 저장된다 (빈 줄은 버린다)" 'Marcos Kim,Nicolas Mendoza,Ana Perez' "$(names "$P")"
eq "  공백이 정리된다" '+54-11-1111-2222' "$(GET "$P" | jq_ 'r.contacts[2].phone')"
# 옛 앱이 깔린 기기는 아직 이 컬럼을 읽는다.
eq "  앞의 둘은 옛 칸에도 적힌다" 'Marcos Kim' "$(GET "$P" | jq_ 'r.contact1_name')"
eq "    둘째도"                   'Nicolas Mendoza' "$(GET "$P" | jq_ 'r.contact2_name')"

echo
echo "── 열 명까지 ──"
MANY=$(node -pe "JSON.stringify(Array.from({length:15},(_,i)=>({name:'사람'+i,phone:''+i})))")
curl -s -o /dev/null -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' --data-binary "$(printf '{"contacts":%s}' "$MANY")"
eq "열 명에서 자른다" '10' "$(GET "$P" | jq_ 'r.contacts.length')"

echo
echo "── 연락처를 건드리지 않는 저장 ──"
# 참가비만 고치는 저장이 연락처를 지워 버리면 안 된다.
curl -s -o /dev/null -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"feeBasic":222}'
eq "목록이 그대로" '10' "$(GET "$P" | jq_ 'r.contacts.length')"
eq "  참가비는 바뀐다" '222' "$(GET "$P" | jq_ 'Number(r.fee_basic)')"

echo
echo "── 빈 목록을 보내면 지운다 ──"
curl -s -o /dev/null -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"contacts":[]}'
eq "비워진다" '0' "$(GET "$P" | jq_ 'r.contacts.length')"
eq "  옛 칸도 비워진다" '' "$(GET "$P" | jq_ 'r.contact1_name')"

echo
echo "── 옛 앱이 보내는 네 칸도 받는다 ──"
Q=$(mk '"contact1Name":"옛하나","contact1Phone":"1",
        "contact2Name":"옛둘","contact2Phone":"2"' b)
eq "목록으로 나온다" '옛하나,옛둘' "$(names "$Q")"

echo
echo "── 이 기능이 생기기 전 수양회 ──"
# contacts 는 비어 있고 005 의 두 컬럼에만 값이 있는 상태를 만든다.
# 경로는 스크립트가 아니라 **서버 폴더 기준**이고, 오류를 삼키지 않는다.
# 처음에 ../src/db.js 로 적고 2>/dev/null 을 붙였더니 아무 일도 일어나지
# 않은 채 검사가 통과했다 — 되돌려 놓을 것이 없으니 늘 통과한다.
node -e '
import("./src/db.js").then(async ({sql}) => {
  await sql`UPDATE programs SET contacts = $$[]$$::jsonb WHERE id = ${process.argv[1]}`;
  process.exit(0);
});' "$Q" || { echo "  ! 옛 상태를 만들지 못했습니다"; fail=$((fail+1)); }
# 정말 비워졌는지 먼저 본다. 안 비워졌으면 아래 검사는 뜻이 없다.
eq "  옛 상태가 만들어졌다" '0' \
   "$(node -pe "
      import('./src/db.js').then(async ({sql}) => {
        const r = await sql\`SELECT jsonb_array_length(contacts) AS n FROM programs WHERE id = '$Q'\`;
        console.log(r[0].n); process.exit(0);
      }); ''" 2>/dev/null)"
eq "옛 두 칸에서 만들어 준다" '옛하나,옛둘' "$(names "$Q")"

echo
echo "── 한쪽만 아는 경우 ──"
# 번호만 아는 사람도 있고, 이름만 적어 두고 나중에 채우기도 한다.
curl -s -o /dev/null -X PATCH "$API/programs/$Q" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"contacts":[{"name":"이름만"},{"phone":"+54-11-9"}]}'
eq "둘 다 남는다" '이름만,' "$(names "$Q")"
eq "  번호만 있는 줄도" '+54-11-9' "$(GET "$Q" | jq_ 'r.contacts[1].phone')"

echo
echo "── 참가자도 볼 수 있다 ──"
PART=$(login "ctc-part-$$@test.local")
eq "참가자 조회에도 목록이 온다" '이름만,' \
   "$(curl -s "$API/programs/$Q" -H "Authorization: Bearer $PART" \
      | jq_ "r.contacts.map(c => c.name).join()")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
