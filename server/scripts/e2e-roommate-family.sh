#!/usr/bin/env bash
# 동행자 룸메이트 종단 검증 (022)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-roommate-family.sh
#
# 규칙:
#   · 같은 성별      → 지금까지처럼 허용
#   · 성별이 다르면  → 동행(가족) 관계를 밝혀야 허용
#   · 어느 쪽이든 상대의 수락이 있어야 성립한다
#
# 확인하는 것은 "요청이 저장되는가"가 아니라 **밝히지 않으면 막히는가**이다.
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }
login() {
  curl -s -X POST "$API/auth/dev-login" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\"}" | node -pe "JSON.parse(require('fs').readFileSync(0)).token"
}

LT=$(login "$LEADER")
HT=$(login husband@test.com)
WT=$(login wife@test.com)
BT=$(login brother@test.com)
for t in "$LT" "$HT" "$WT" "$BT"; do
  [ "$t" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }
done

PROG=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"name":"룸메이트검증용(e2e)","location":"테스트","startDate":"2027-04-01","hostCountry":"KR"}' \
  | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''")
[ -n "$PROG" ] || { echo "검증용 수양회 생성 실패"; exit 1; }
echo "검증용 수양회: $PROG"
echo

reg() { # $1=token $2=이름 $3=성별
  curl -s -X PUT "$API/registrations/$PROG/me" -H "Authorization: Bearer $1" \
    -H 'Content-Type: application/json' \
    -d "{\"realName\":\"$2\",\"gender\":\"$3\",\"country\":\"KR\",\"branch\":\"서울\"}" >/dev/null
}
reg "$HT" 남편 M
reg "$WT" 아내 F
reg "$BT" 형제 M

idOf() { # $1=이름
  curl -s "$API/programs/$PROG/registrations" -H "Authorization: Bearer $LT" \
    | node -pe "const rs=JSON.parse(require('fs').readFileSync(0));
       (rs.find(x=>x.real_name==='$1')||{}).id||''"
}
WIFE=$(idOf 아내); BRO=$(idOf 형제)
[ -n "$WIFE" ] && [ -n "$BRO" ] || { echo "등록 id 조회 실패"; exit 1; }

send() { # $1=대상 $2=relation → http code
  local body="{\"toRegistrationId\":\"$1\",\"kind\":\"roommate\""
  [ -n "${2:-}" ] && body="$body,\"relation\":\"$2\""
  curl -s -o /dev/null -w '%{http_code}' -X POST "$API/buddy-requests/$PROG" \
    -H "Authorization: Bearer $HT" -H 'Content-Type: application/json' -d "$body}"
}

echo "── 성별이 다른 경우 ──"
eq "관계를 안 밝히면 막힌다"  '422' "$(send "$WIFE")"
eq "peer 라고 해도 막힌다"    '422' "$(send "$WIFE" peer)"
eq "family 면 통과"          '201' "$(send "$WIFE" family)"

echo
echo "── 같은 성별 ──"
eq "관계 없이도 통과"        '201' "$(send "$BRO")"

echo
echo "── 저장된 관계 ──"
REL=$(curl -s "$API/buddy-requests/$PROG/me" -H "Authorization: Bearer $HT" \
  | node -pe "const d=JSON.parse(require('fs').readFileSync(0));
     const all=[...(d.sent||[]),...(d.received||[])];
     const r=all.find(x=>x.otherId==='$WIFE')||{}; r.relation||''")
eq "아내 요청은 family"      'family' "$REL"
REL2=$(curl -s "$API/buddy-requests/$PROG/me" -H "Authorization: Bearer $HT" \
  | node -pe "const d=JSON.parse(require('fs').readFileSync(0));
     const all=[...(d.sent||[]),...(d.received||[])];
     const r=all.find(x=>x.otherId==='$BRO')||{}; r.relation||''")
eq "형제 요청은 peer"        'peer'   "$REL2"

echo
echo "통과 $pass  실패 $fail"
[ "$fail" -eq 0 ]
