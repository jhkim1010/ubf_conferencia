#!/usr/bin/env bash
# 수양회 삭제 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-program-delete.sh
#
# 확인하는 것:
#   · 행이 실제로 지워지지 않고 비활성화되는가 (등록·배정 기록이 남아야 한다)
#   · 등록자가 있으면 이름 확인 없이는 막히는가
#   · 남의 수양회를 지울 수 없는가
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
OT=$(login other-leader@test.com)   # 리더가 아닌 계정
PT=$(login deltest@test.com)        # 등록자
[ "$LT" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

mk() { # $1=이름 → programId
  curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"name":"%s","location":"테스트","startDate":"2027-06-01"}' "$1")" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''"
}
del() { # $1=programId $2=token $3=confirmName → http code
  local body='{}'
  [ -n "${3:-}" ] && body="{\"confirmName\":\"$3\"}"
  curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/programs/$1" \
    -H "Authorization: Bearer $2" -H 'Content-Type: application/json' -d "$body"
}
visible() { # 목록에 보이는가
  curl -s "$API/programs" -H "Authorization: Bearer $LT" \
    | node -pe "const rs=JSON.parse(require('fs').readFileSync(0));
       String(rs.some(p=>p.id==='$1'))"
}

echo "── 등록자가 없는 수양회 ──"
A=$(mk '삭제검증-빈(e2e)')
[ -n "$A" ] || { echo "생성 실패"; exit 1; }
eq "목록에 보인다"          'true'  "$(visible "$A")"
eq "확인 없이 삭제된다"      '200'   "$(del "$A" "$LT")"
eq "목록에서 사라진다"       'false' "$(visible "$A")"
eq "조회도 404"             '404'   "$(curl -s -o /dev/null -w '%{http_code}' \
      "$API/programs/$A" -H "Authorization: Bearer $LT")"

echo
echo "── 등록자가 있는 수양회 ──"
B=$(mk '삭제검증-등록자있음(e2e)')
curl -s -X PUT "$API/registrations/$B/me" -H "Authorization: Bearer $PT" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"삭제테스트","country":"KR","branch":"서울"}' >/dev/null
eq "이름 없이는 막힌다"       '428'   "$(del "$B" "$LT")"
eq "틀린 이름도 막힌다"       '428'   "$(del "$B" "$LT" '아무거나')"
eq "아직 목록에 있다"        'true'  "$(visible "$B")"
eq "이름을 맞추면 삭제"       '200'   "$(del "$B" "$LT" '삭제검증-등록자있음(e2e)')"
eq "목록에서 사라진다"        'false' "$(visible "$B")"

echo
echo "── 행은 남아 있는가 (소프트 삭제) ──"
# 등록 기록이 사라지면 안 된다. 참가자 목록 조회가 403(비활성)이어도
# 행 자체는 DB 에 남아야 한다 — 여기서는 재삭제가 403 인 것으로 확인한다.
eq "이미 지운 것은 다시 못 지운다" '403' "$(del "$B" "$LT")"

echo
echo "── 남의 수양회 ──"
C=$(mk '삭제검증-소유권(e2e)')
eq "리더가 아니면 403"       '403'   "$(del "$C" "$OT")"
eq "그대로 남아 있다"        'true'  "$(visible "$C")"
del "$C" "$LT" >/dev/null   # 정리

echo
echo "통과 $pass  실패 $fail"
[ "$fail" -eq 0 ]
