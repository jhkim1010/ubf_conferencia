#!/usr/bin/env bash
# 봉사 신청 API 종단 검증 (A001 T2)
#
# 사용: API=http://localhost:3000 PROG=<programId> STAGE_URL=<direct url> ./scripts/e2e-service-signup.sh
#
# 자격 3조건(개최국/선교사/5년이상목자)과 픽업 면허 제한이 서버에서 실제로
# 강제되는지 확인한다. 통과뿐 아니라 **차단되어야 할 때 차단되는지**를 본다.

# 이 스크립트는 /auth/dev-login 을 쓴다. 서버가 ENABLE_DEV_LOGIN=1 로 떠 있어야 한다
# (기본은 비활성 — 설정을 빠뜨리면 닫히는 fail-closed 구조다).
set -uo pipefail
API="${API:-http://localhost:3000}"
PROG="${PROG:?PROG 필요}"
STAGE_URL="${STAGE_URL:?STAGE_URL(DATABASE_URL_DIRECT) 필요}"

pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; echo "      기대: $2"; echo "      실제: $3"; fail=$((fail+1)); }

login() {
  curl -s -X POST "$API/auth/dev-login" -H 'Content-Type: application/json' \
    --data-binary "$(printf '{"email":"%s"}' "$1")" | node -pe "JSON.parse(require('fs').readFileSync(0)).token"
}
jqf() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); const v=$1; v===undefined?'undefined':JSON.stringify(v)"; }

# 사용자 속성을 직접 세팅한다 (프로필 UI 는 아직 없다)
setuser() { # $1=email $2=church_role|NULL $3=shepherd_since|NULL $4=license
  DATABASE_URL="$STAGE_URL" node --input-type=module -e "
import pg from 'pg';const p=new pg.Pool({connectionString:process.env.DATABASE_URL});
await p.query(\"UPDATE users SET church_role=\$1, shepherd_since=\$2, has_driver_license=\$3 WHERE email=\$4\",
  ['$2'==='NULL'?null:'$2', '$3'==='NULL'?null:Number('$3'), '$4'==='true', '$1']);
await p.end();" 2>/dev/null
}
setcountry() { # $1=email $2=country
  DATABASE_URL="$STAGE_URL" node --input-type=module -e "
import pg from 'pg';const p=new pg.Pool({connectionString:process.env.DATABASE_URL});
await p.query(\"UPDATE registrations r SET country=\$1 FROM users u WHERE u.id=r.user_id AND u.email=\$2 AND r.program_id=\$3\",
  ['$2','$1','$PROG']);
await p.end();" 2>/dev/null
}

E=svc@test.com
# 등록이 없으면 만든다
T=$(login $E)
curl -s -X PUT "$API/registrations/$PROG/me" -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' \
  -d '{"realName":"봉사테스트","country":"PE","branch":"리마","foodRequirements":"없음"}' >/dev/null

echo "── 자격 없음 (해외 + 직분 없음) ──"
setuser $E NULL NULL false; setcountry $E PE
R=$(curl -s "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T")
[ "$(echo "$R" | jqf 'r.eligible')" = 'false' ] \
  && ok "eligible=false" || bad "eligible" 'false' "$(echo "$R" | jqf 'r.eligible')"
C=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/service-signups/$PROG/me" \
  -H "Authorization: Bearer $T" -H 'Content-Type: application/json' \
  -d '{"items":[{"service_key":"cleaning"}]}')
[ "$C" = "403" ] && ok "자격 없으면 저장 차단 (403)" || bad "저장 차단" '403' "$C"

echo
echo "── 자격 1: 개최국 참석자 ──"
setcountry $E BR
R=$(curl -s "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T")
[ "$(echo "$R" | jqf 'r.reasons')" = '["domestic"]' ] \
  && ok "reasons=[domestic]" || bad "reasons" '["domestic"]' "$(echo "$R" | jqf 'r.reasons')"

echo
echo "── 자격 2: 선교사 (해외여도 통과) ──"
setcountry $E PE; setuser $E misionero NULL false
R=$(curl -s "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T")
[ "$(echo "$R" | jqf 'r.reasons')" = '["missionary"]' ] \
  && ok "reasons=[missionary]" || bad "reasons" '["missionary"]' "$(echo "$R" | jqf 'r.reasons')"

echo
echo "── 자격 3: 목자 연차 경계 ──"
Y=$(date +%Y)
setuser $E maestro_biblico $((Y-4)) false
R=$(curl -s "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T")
[ "$(echo "$R" | jqf 'r.eligible')" = 'false' ] \
  && ok "4년차 → 자격 없음" || bad "4년차" 'false' "$(echo "$R" | jqf 'r.eligible')"
setuser $E maestro_biblico $((Y-5)) false
R=$(curl -s "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T")
[ "$(echo "$R" | jqf 'r.reasons')" = '["shepherd_5y"]' ] \
  && ok "5년차 → 자격 있음 (경계 포함)" || bad "5년차" '["shepherd_5y"]' "$(echo "$R" | jqf 'r.reasons')"

echo
echo "── 픽업: 운전면허 제한 ──"
C=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/service-signups/$PROG/me" \
  -H "Authorization: Bearer $T" -H 'Content-Type: application/json' \
  -d '{"items":[{"service_key":"pickup","can_provide_vehicle":true,"vehicle_seats":7}]}')
[ "$C" = "403" ] && ok "면허 없으면 픽업 차단 (403)" || bad "픽업 차단" '403' "$C"
setuser $E maestro_biblico $((Y-5)) true
R=$(curl -s -X PUT "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' \
  -d '{"items":[{"service_key":"pickup","can_provide_vehicle":true,"vehicle_seats":7}]}')
[ "$(echo "$R" | jqf 'r.signups && r.signups[0] && r.signups[0].vehicle_seats')" = '7' ] \
  && ok "면허 있으면 픽업 저장 + 상세 보존" || bad "픽업 저장" '7' "$(echo "$R" | jqf 'r.signups')"

echo
echo "── D7: 승인 필요 항목은 awaiting_approval ──"
R=$(curl -s -X PUT "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' \
  -d '{"items":[{"service_key":"group_study_leader"},{"service_key":"cleaning"}]}')
GS=$(echo "$R" | jqf "r.signups.find(s=>s.service_key==='group_study_leader').status")
CL=$(echo "$R" | jqf "r.signups.find(s=>s.service_key==='cleaning').status")
[ "$GS" = '"awaiting_approval"' ] && ok "그룹공부 리더 → awaiting_approval" || bad "리더 상태" '"awaiting_approval"' "$GS"
[ "$CL" = '"applied"' ] && ok "청소 → applied" || bad "청소 상태" '"applied"' "$CL"

echo
echo "── 알 수 없는 항목 거부 ──"
C=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/service-signups/$PROG/me" \
  -H "Authorization: Bearer $T" -H 'Content-Type: application/json' \
  -d '{"items":[{"service_key":"__bogus__"}]}')
[ "$C" = "400" ] && ok "미정의 항목 차단 (400)" || bad "미정의 항목" '400' "$C"

echo
echo "── D6: 거절 기록과 되돌리기 ──"
curl -s -X POST "$API/service-signups/$PROG/decline" -H "Authorization: Bearer $T" >/dev/null
R=$(curl -s "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T")
[ "$(echo "$R" | jqf 'r.declined')" = 'true' ] && ok "거절 기록됨" || bad "거절" 'true' "$(echo "$R" | jqf 'r.declined')"
[ "$(echo "$R" | jqf 'r.signups.length')" = '0' ] && ok "거절 시 기존 신청 정리" || bad "신청 정리" '0' "$(echo "$R" | jqf 'r.signups.length')"
curl -s -X PUT "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' -d '{"items":[{"service_key":"cleaning"}]}' >/dev/null
R=$(curl -s "$API/service-signups/$PROG/me" -H "Authorization: Bearer $T")
[ "$(echo "$R" | jqf 'r.declined')" = 'false' ] \
  && ok "다시 신청하면 거절 해제 (마음이 바뀔 수 있다)" || bad "거절 해제" 'false' "$(echo "$R" | jqf 'r.declined')"

echo
echo "════════════════════════════════"
echo "통과 $pass · 실패 $fail"
[ $fail -eq 0 ] || exit 1
