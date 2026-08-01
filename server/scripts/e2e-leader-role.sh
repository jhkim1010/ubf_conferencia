#!/usr/bin/env bash
# 리더 역할 지속 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-leader-role.sh
#
# 확인하는 것:
#   · 인앱으로 리더가 된 뒤 **다시 로그인해도** 리더로 남는가
#     (앱 화면은 role 로 홈을 고른다. role 이 participant 로 남으면 리더가
#      참가자 홈으로 떨어져 자기 수양회에 못 들어간다 — 실제로 그랬다.)
#   · 중복 등록이 500 이 아니라 이유가 보이는 코드로 막히는가
set -uo pipefail
API="${API:-http://localhost:3000}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$2" "$3"; }

# 매번 새 계정을 쓴다. 남은 계정을 재사용하면 "이미 리더" 로 갈려 결과가 흐려진다.
WHO="rolecheck-$$@test.local"

login() {
  curl -s -X POST "$API/auth/dev-login" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\"}" | node -pe "JSON.parse(require('fs').readFileSync(0)).token"
}
me() { # $1=token $2=필드
  curl -s "$API/auth/me" -H "Authorization: Bearer $1" \
    | node -pe "String(JSON.parse(require('fs').readFileSync(0))['$2'])"
}
becomeLeader() { # $1=token → http code
  curl -s -o /dev/null -w '%{http_code}' -X POST "$API/leaders/register" \
    -H "Authorization: Bearer $1" -H 'Content-Type: application/json' \
    -d '{"name":"역할검증"}'
}

T=$(login "$WHO")
[ "$T" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

echo "── 리더가 되기 전 ──"
eq "역할은 participant"        'participant' "$(me "$T" role)"
eq "isLeader 는 false"         'false'       "$(me "$T" isLeader)"
eq "프로그램 목록은 403"       '403' "$(curl -s -o /dev/null -w '%{http_code}' \
      "$API/programs" -H "Authorization: Bearer $T")"

echo
echo "── 리더 등록 직후 ──"
eq "등록 성공"                 '200'   "$(becomeLeader "$T")"
eq "역할이 admin 이 된다"      'admin' "$(me "$T" role)"
eq "isLeader 는 true"          'true'  "$(me "$T" isLeader)"

echo
echo "── 다시 로그인한 뒤 (앱 재시작에 해당) ──"
T2=$(login "$WHO")
eq "역할이 admin 으로 남는다"  'admin' "$(me "$T2" role)"
eq "isLeader 도 true"          'true'  "$(me "$T2" isLeader)"
eq "프로그램 목록에 들어간다"  '200' "$(curl -s -o /dev/null -w '%{http_code}' \
      "$API/programs" -H "Authorization: Bearer $T2")"

echo
echo "── 중복 등록 ──"
eq "다시 등록하면 400 (500 아님)" '400' "$(becomeLeader "$T2")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
