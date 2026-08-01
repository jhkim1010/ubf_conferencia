#!/usr/bin/env bash
# 참가비 등급 + 할인 신청 API 종단 검증 (018)
#
# 사용: API=http://localhost:3000 ./scripts/e2e-fee-discount.sh
#
# 검증용 수양회를 직접 만든다. 실제 계정이 소유한 수양회를 건드리면
# 참가비를 테스트 값으로 덮어쓰게 된다.
#
# 핵심은 "저장되는가"가 아니라 **등록자가 넘어서면 안 되는 선이 막히는가**이다.
#   - 등록자가 status/amount 를 직접 지정해도 무시되는가
#   - 수양회가 제공하지 않는 등급을 고르면 걸러지는가
#   - 목록에 없는 할인 항목 key 를 보내면 신청이 성립하지 않는가
#   - 담당자가 금액 없이 승인할 수 있는가 (없어야 한다)
#   - 신청 항목을 바꾸면 이전 승인이 무효화되는가
#
# 서버가 ENABLE_DEV_LOGIN=1 로 떠 있어야 한다.
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
jqf() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); const v=$1; v===undefined?'undefined':JSON.stringify(v)"; }

E=fee@test.com
T=$(login $E)
LT=$(login "$LEADER")
[ "$T" != undefined ] && [ "$LT" != undefined ] || { echo "로그인 실패 — ENABLE_DEV_LOGIN=1 확인"; exit 1; }

# 전용 수양회 확보. 이미 있으면 409 와 함께 existingId 를 돌려준다.
PROG=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"name":"참가비검증용(e2e)","location":"테스트","startDate":"2027-01-05","hostCountry":"PE"}' \
  | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||''")
[ -n "$PROG" ] || { echo "검증용 수양회 생성 실패 — $LEADER 가 리더인지 확인"; exit 1; }
echo "검증용 수양회: $PROG"
echo

save() { # $1=json body
  curl -s -X PUT "$API/registrations/$PROG/me" -H "Authorization: Bearer $T" \
    -H 'Content-Type: application/json' -d "$1"
}
# 이 등록자의 행만 골라낸다
mine() {
  curl -s "$API/programs/$PROG/registrations" -H "Authorization: Bearer $LT" \
    | node -pe "const rs=JSON.parse(require('fs').readFileSync(0));
       const r=rs.find(x=>x.real_name==='참가비테스트')||{}; const v=$1;
       v===undefined?'undefined':JSON.stringify(v)"
}
regid() {
  curl -s "$API/programs/$PROG/registrations" -H "Authorization: Bearer $LT" \
    | node -pe "const rs=JSON.parse(require('fs').readFileSync(0));
       (rs.find(x=>x.real_name==='참가비테스트')||{}).id||''"
}

echo "── 준비: 수양회에 등급과 할인 항목 설정 ──"
curl -s -X PATCH "$API/programs/$PROG" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{
    "feeBasic":150,"feePremium":250,
    "feeBasicDesc":"단체실","feePremiumDesc":"2인실",
    "discountOptions":[
      {"key":"d1","label":"1일만 참석","labels":{"ko":"1일만 참석","en":"One day only","es":"Solo un día"},"amount":40},
      {"key":"d2","label":"2일 참석","amount":25},
      {"key":"d3","label":"기타 사정","amount":null}
    ]}' >/dev/null
P=$(curl -s "$API/programs/$PROG" -H "Authorization: Bearer $T")
eq "fee_basic 저장"        '150' "$(echo "$P" | jqf 'Number(r.fee_basic)')"
eq "fee_premium 저장"      '250' "$(echo "$P" | jqf 'Number(r.fee_premium)')"
eq "할인 항목 3개"          '3'   "$(echo "$P" | jqf 'r.discount_options.length')"
eq "할인 항목 문구 보존"     '"1일만 참석"' "$(echo "$P" | jqf 'r.discount_options[0].label')"

echo
echo "── 통화 (지역 수양회가 정한다) ──"
# 환율 변환은 하지 않는다. 저장은 ISO 4217 코드이고 표시 기호는 앱이 만든다.
#
# 이 수양회는 국제(기본값)라 통화가 USD 로 고정된다. 통화를 **고를 수 있는지**
# 보려면 지역 수양회여야 한다 — 국제로 두면 무엇을 보내든 USD 라서, 아래
# 검사들이 "고정돼서" 통과하는지 "제대로 저장돼서" 통과하는지 구별되지 않는다.
# 국제 고정 규칙 자체는 e2e-currency-rule.sh 가 따로 본다.
eq "국제는 USD 고정"        '"USD"' "$(echo "$P" | jqf 'r.currency')"
curl -s -X PATCH "$API/programs/$PROG" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"programType":"local","currency":"KRW"}' >/dev/null
eq "지역으로 바꾸면 통화 변경" '"KRW"' "$(curl -s "$API/programs/$PROG" -H "Authorization: Bearer $T" | jqf 'r.currency')"
eq "소문자도 받아 대문자로" '"ARS"' "$(curl -s -X PATCH "$API/programs/$PROG" -H "Authorization: Bearer $LT" \
      -H 'Content-Type: application/json' -d '{"programType":"local","currency":"ars"}' >/dev/null; \
      curl -s "$API/programs/$PROG" -H "Authorization: Bearer $T" | jqf 'r.currency')"
eq "두 글자 거부"          '400' "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$API/programs/$PROG" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' -d '{"currency":"US"}')"
eq "숫자 섞인 코드 거부"    '400' "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$API/programs/$PROG" \
      -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' -d '{"currency":"U5D"}')"
# 등록자는 통화를 바꿀 수 없다 — 저장 본문에 넣어도 무시돼야 한다.
# 지역 수양회(ARS)에서 확인한다. 국제였다면 어차피 USD 라 권한 검사가 통과한
# 것인지 고정 규칙이 막은 것인지 알 수 없다.
save '{"realName":"참가비테스트","country":"PE","currency":"JPY"}' >/dev/null
eq "등록자는 통화를 못 바꾼다" '"ARS"' "$(curl -s "$API/programs/$PROG" -H "Authorization: Bearer $T" | jqf 'r.currency')"
# 뒤 검사들은 이 수양회를 국제 기준으로 계속 쓴다. 원래대로 되돌린다.
curl -s -X PATCH "$API/programs/$PROG" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"programType":"international"}' >/dev/null

echo
echo "── 할인 문구 3개 언어 ──"
# 한 줄만 받으면 다른 언어 사용자는 읽지 못한 채 고르게 된다.
eq "ko 문구"               '"1일만 참석"'  "$(echo "$P" | jqf 'r.discount_options[0].labels.ko')"
eq "en 문구"               '"One day only"' "$(echo "$P" | jqf 'r.discount_options[0].labels.en')"
eq "es 문구"               '"Solo un día"'  "$(echo "$P" | jqf 'r.discount_options[0].labels.es')"
# 한 언어만 적어도 항목이 만들어져야 한다 — 세 칸을 강제하면 못 만드는 지부가 생긴다
eq "일부만 적어도 저장"      '3'  "$(echo "$P" | jqf 'r.discount_options.length')"
eq "labels 없는 항목도 유지" '"2일 참석"' "$(echo "$P" | jqf 'r.discount_options[1].label')"

echo
echo "── 참가비 등급 ──"
save '{"realName":"참가비테스트","country":"PE","branch":"리마","feeTier":"premium"}' >/dev/null
eq "premium 선택"          '"premium"' "$(mine 'r.fee_tier')"
save '{"realName":"참가비테스트","country":"PE","branch":"리마","feeTier":"vip"}' >/dev/null
eq "없는 등급(vip) 무시"    'null'      "$(mine 'r.fee_tier')"

# 프리미엄을 제공하지 않는 상태로 바꾸면 premium 선택은 성립하지 않아야 한다
curl -s -X PATCH "$API/programs/$PROG" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"feePremium":null}' >/dev/null
save '{"realName":"참가비테스트","country":"PE","branch":"리마","feeTier":"premium"}' >/dev/null
eq "제공 안 하는 등급 차단"  'null'      "$(mine 'r.fee_tier')"
curl -s -X PATCH "$API/programs/$PROG" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"feePremium":250}' >/dev/null

echo
echo "── 합계는 서버가 계산한다 ──"
# 클라이언트가 보낸 totalCost 를 그대로 믿으면 낼 금액을 등록자가 정하게 된다.
# 실제로 앱은 투어 비용만 더하고 참가비 등급을 빼먹어 DB 에 0 이 저장됐었다.
save '{"realName":"참가비테스트","country":"PE","branch":"리마","feeTier":"premium","totalCost":99999}' >/dev/null
eq "등급 참가비가 합계에 반영"   '250' "$(mine 'Number(r.total_cost)')"
eq "클라이언트 totalCost 무시"   'true' "$(mine 'Number(r.total_cost) !== 99999')"
save '{"realName":"참가비테스트","country":"PE","branch":"리마","feeTier":"basic"}' >/dev/null
eq "등급을 바꾸면 합계도 바뀐다" '150' "$(mine 'Number(r.total_cost)')"
save '{"realName":"참가비테스트","country":"PE","branch":"리마"}' >/dev/null
eq "등급 미선택이면 0"          '0'   "$(mine 'Number(r.total_cost)')"

echo
echo "── 할인 신청 (등록자) ──"
save '{"realName":"참가비테스트","country":"PE","branch":"리마","feeTier":"basic",
       "discountRequested":true,"discountOptionKey":"d1","discountReason":"토요일만 참석 가능"}' >/dev/null
eq "신청 기록"             'true'          "$(mine 'r.discount_requested')"
eq "고른 항목 key"          '"d1"'          "$(mine 'r.discount_option_key')"
eq "고른 항목 문구 스냅샷"   '"1일만 참석"'   "$(mine 'r.discount_option_label')"
eq "상태는 서버가 requested" '"requested"'   "$(mine 'r.discount_status')"

# 등록자가 승인 상태와 금액을 직접 밀어넣으려 해도 반영되면 안 된다
save '{"realName":"참가비테스트","country":"PE","branch":"리마",
       "discountRequested":true,"discountOptionKey":"d1",
       "discountStatus":"approved","discountAmount":999,"discountNote":"내가 승인"}' >/dev/null
eq "등록자 status 지정 무시"  '"requested"' "$(mine 'r.discount_status')"
eq "등록자 amount 지정 무시"  'null'        "$(mine 'r.discount_amount')"

# 목록에 없는 key
save '{"realName":"참가비테스트","country":"PE","branch":"리마",
       "discountRequested":true,"discountOptionKey":"없는키","discountReason":"x"}' >/dev/null
eq "없는 key 는 신청 불성립"  'false' "$(mine 'r.discount_requested')"
eq "없는 key → 상태 없음"     'null'  "$(mine 'r.discount_status')"

echo
echo "── 할인 판단 (담당자) ──"
save '{"realName":"참가비테스트","country":"PE","branch":"리마",
       "discountRequested":true,"discountOptionKey":"d1","discountReason":"토요일만"}' >/dev/null
RID=$(regid)
[ -n "$RID" ] || { echo "등록 id 를 찾지 못함"; exit 1; }

dec() { # $1=json → http code
  curl -s -o /dev/null -w '%{http_code}' -X PATCH \
    "$API/programs/$PROG/registrations/$RID/discount" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' -d "$1"
}
eq "금액 없는 승인 거부"      '400' "$(dec '{"status":"approved"}')"
eq "음수 금액 거부"          '400' "$(dec '{"status":"approved","amount":-5}')"
eq "이상한 status 거부"       '400' "$(dec '{"status":"whatever","amount":10}')"
eq "등록자는 판단 불가"       '403' "$(curl -s -o /dev/null -w '%{http_code}' -X PATCH \
      "$API/programs/$PROG/registrations/$RID/discount" -H "Authorization: Bearer $T" \
      -H 'Content-Type: application/json' -d '{"status":"approved","amount":40}')"

eq "정상 승인"              '200' "$(dec '{"status":"approved","amount":40,"note":"지부장 확인"}')"
eq "승인 상태 반영"          '"approved"' "$(mine 'r.discount_status')"
eq "확정 금액 반영"          '40'         "$(mine 'r.discount_amount === null ? null : Number(r.discount_amount)')"

echo
echo "── 승인 후 등록자가 신청 항목을 바꾼 경우 ──"
save '{"realName":"참가비테스트","country":"PE","branch":"리마",
       "discountRequested":true,"discountOptionKey":"d2"}' >/dev/null
eq "다시 requested 로"       '"requested"' "$(mine 'r.discount_status')"
eq "확정 금액 무효화"         'null'        "$(mine 'r.discount_amount')"

# 같은 항목으로 다시 저장하면 담당자 판단이 살아 있어야 한다
dec '{"status":"approved","amount":25,"note":"재승인"}' >/dev/null
save '{"realName":"참가비테스트","country":"PE","branch":"리마","foodRequirements":"없음",
       "discountRequested":true,"discountOptionKey":"d2"}' >/dev/null
eq "같은 항목 재저장 시 승인 유지" '"approved"' "$(mine 'r.discount_status')"
eq "확정 금액 유지"               '25'         "$(mine 'r.discount_amount === null ? null : Number(r.discount_amount)')"

echo
echo "── 신청 철회 ──"
save '{"realName":"참가비테스트","country":"PE","branch":"리마","discountRequested":false}' >/dev/null
eq "철회 시 상태 제거"        'null'  "$(mine 'r.discount_status')"
eq "철회 시 금액 제거"        'null'  "$(mine 'r.discount_amount')"
eq "철회 시 문구 제거"        'null'  "$(mine 'r.discount_option_label')"

echo
echo "통과 $pass  실패 $fail"
[ "$fail" -eq 0 ]
