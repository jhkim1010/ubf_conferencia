#!/usr/bin/env bash
# QR 나눔 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-cards.sh
#
# 이 기능은 **참가자끼리 서로 보는 첫 기능**이다. 가장 중요한 것은
#   1) 꺼 둔 연락처가 응답에 실리지 않는가 (값으로 찾는다)
#   2) 19세 이하의 연락처 잠금을 직접 호출로 뚫을 수 없는가
#   3) QR 을 새로 만들면 예전 코드가 그 자리에서 막히는가
# 화면에서 감추는 것만으로는 부족하다 — 예전 앱과 직접 호출은 화면을 거치지 않는다.
set -uo pipefail
API="${API:-http://localhost:3000}"

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
jq_() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); String((r$1) ?? '')"; }

A=$(login "card-a-$$@test.local")   # 어른
B=$(login "card-b-$$@test.local")   # 어른
J=$(login "card-j-$$@test.local")   # 19세 이하

# 나이는 프로필에 있다. 잠금 판정이 이 값을 본다.
setAge() { curl -s -o /dev/null -X PATCH "$API/auth/profile" \
  -H "Authorization: Bearer $1" -H 'Content-Type: application/json' \
  --data-binary "$(printf '{"name":"%s","age":%s,"region":"AR"}' "$2" "$3")"; }
setAge "$A" "명함A" 34
setAge "$B" "명함B" 41
setAge "$J" "주니어" 16

me()   { curl -s "$API/cards/me" -H "Authorization: Bearer $1"; }
save() { curl -s -o /dev/null -w '%{http_code}' -X PUT "$API/cards/me" \
  -H "Authorization: Bearer $1" -H 'Content-Type: application/json' -d "$2"; }
byTok(){ curl -s "$API/cards/by-token/$2" -H "Authorization: Bearer $1"; }

# 모든 항목을 켜 달라고 요청한다. 어른은 그대로, 주니어는 연락이 잠긴다.
ALL_ON='{"lifeVerseRef":"요한복음 10:10","prayerTopics":["가족","캠퍼스"],
  "email":"A@Example.COM","whatsapp":"+54 (11) 3456-7890","phone":"01134567890",
  "instagram":"https://www.instagram.com/maria.f?igshid=zz","x":"@mariaf",
  "youtube":"https://youtube.com/channel/UC12345",
  "showEmail":true,"showWhatsapp":true,"showPhone":true,
  "showInstagram":true,"showX":true,"showYoutube":true}'

echo "── 명함 만들기 ──"
TOK_A=$(me "$A" | jq_ ".share_token")
[ ${#TOK_A} -ge 16 ] && ok "처음 열면 명함과 QR 토큰이 만들어진다" \
  || bad "명함 생성" "토큰" "$TOK_A"
eq "저장된다" '200' "$(save "$A" "$ALL_ON")"

echo
echo "── 붙여넣은 주소에서 아이디만 남는다 ──"
CARD=$(byTok "$B" "$TOK_A")
eq "인스타그램"  'maria.f'          "$(printf '%s' "$CARD" | jq_ ".card.channels.instagram")"
eq "유튜브 채널" 'channel/UC12345'  "$(printf '%s' "$CARD" | jq_ ".card.channels.youtube")"
eq "왓츠앱"      '+541134567890'    "$(printf '%s' "$CARD" | jq_ ".card.contacts.whatsapp")"
eq "이메일 소문자" 'a@example.com'  "$(printf '%s' "$CARD" | jq_ ".card.contacts.email")"

echo
echo "── 꺼 두면 응답에 아예 없다 ──"
# 값을 보내고 화면에서 감추면, 화면을 거치지 않는 호출에 그대로 새어 나간다.
SOME_OFF=$(printf '%s' "$ALL_ON" | sed 's/"showWhatsapp":true/"showWhatsapp":false/; s/"showPhone":true/"showPhone":false/; s/"showX":true/"showX":false/')
eq "일부를 끄고 저장" '200' "$(save "$A" "$SOME_OFF")"
CARD=$(byTok "$B" "$TOK_A")
case "$CARD" in
  *"+541134567890"*) bad "끈 왓츠앱이 응답에 없다" "없음" "번호가 그대로 있음" ;;
  *) ok "끈 왓츠앱 번호가 응답에 없다" ;;
esac
case "$CARD" in
  *"mariaf"*) bad "끈 X 아이디가 응답에 없다" "없음" "아이디가 그대로 있음" ;;
  *) ok "끈 X 아이디가 응답에 없다" ;;
esac
eq "  켜 둔 것은 그대로 나온다" 'maria.f' "$(printf '%s' "$CARD" | jq_ ".card.channels.instagram")"
eq "  요절은 남는다" '요한복음 10:10' "$(printf '%s' "$CARD" | jq_ ".card.lifeVerseRef")"

echo
echo "── 19세 이하 연락처 잠금 ──"
# 화면이 아니라 서버가 막아야 한다.
eq "주니어도 저장 자체는 된다" '200' "$(save "$J" "$ALL_ON")"
TOK_J=$(me "$J" | jq_ ".share_token")
eq "  화면에 잠금이라고 알린다" 'true' "$(me "$J" | jq_ ".junior_locked")"
JCARD=$(byTok "$A" "$TOK_J")
eq "  이메일이 나가지 않는다"  '' "$(printf '%s' "$JCARD" | jq_ ".card.contacts.email")"
eq "  왓츠앱이 나가지 않는다"  '' "$(printf '%s' "$JCARD" | jq_ ".card.contacts.whatsapp")"
eq "  전화가 나가지 않는다"    '' "$(printf '%s' "$JCARD" | jq_ ".card.contacts.phone")"
# 채널은 이미 공개된 계정이라 잠그지 않는다.
eq "  채널은 나눌 수 있다" 'maria.f' "$(printf '%s' "$JCARD" | jq_ ".card.channels.instagram")"
eq "  요절·기도제목도 나눈다" '요한복음 10:10' "$(printf '%s' "$JCARD" | jq_ ".card.lifeVerseRef")"

echo
echo "── 저장과 되돌리기 ──"
UID_A=$(printf '%s' "$CARD" | jq_ ".userId")
eq "읽자마자 저장되지는 않는다" 'false' "$(printf '%s' "$CARD" | jq_ ".alreadySaved")"
BODY_SAVE='{"friendUserId":"'"$UID_A"'"}'
eq "친구로 저장한다" '201' \
  "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/cards/connections" \
     -H "Authorization: Bearer $B" -H 'Content-Type: application/json' -d "$BODY_SAVE")"
eq "  목록에 들어간다" '명함A' \
  "$(curl -s "$API/cards/connections" -H "Authorization: Bearer $B" \
     | node -pe "JSON.parse(require('fs').readFileSync(0)).map(c=>c.card.name).join(',')")"
eq "  두 번 저장해도 하나다" '1' \
  "$(curl -s -o /dev/null -X POST "$API/cards/connections" -H "Authorization: Bearer $B" \
      -H 'Content-Type: application/json' -d "$BODY_SAVE";
     curl -s "$API/cards/connections" -H "Authorization: Bearer $B" \
     | node -pe "String(JSON.parse(require('fs').readFileSync(0)).length)")"
eq "내 명함은 저장할 수 없다" '400' \
  "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/cards/connections" \
     -H "Authorization: Bearer $B" -H 'Content-Type: application/json' \
     -d '{"friendUserId":"'"$(me "$B" | jq_ ".user_id")"'"}')"

# 준 것을 돌려받을 수 있어야 마음 놓고 준다.
SB=$(curl -s "$API/cards/saved-by" -H "Authorization: Bearer $A")
eq "나를 저장한 사람이 보인다" '명함B' "$(printf '%s' "$SB" | node -pe "JSON.parse(require('fs').readFileSync(0)).map(c=>c.name).join(',')")"
eq "  저장은 한쪽 방향이다"   'false' "$(printf '%s' "$SB" | jq_ "[0].savedBack")"
CID=$(printf '%s' "$SB" | jq_ "[0].id")
eq "연결을 끊는다" '200' \
  "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/cards/saved-by/$CID" -H "Authorization: Bearer $A")"
eq "  상대 목록에서 사라진다" '0' \
  "$(curl -s "$API/cards/connections" -H "Authorization: Bearer $B" \
     | node -pe "String(JSON.parse(require('fs').readFileSync(0)).length)")"

echo
echo "── QR 새로 만들기 ──"
NEW_TOK=$(curl -s -X POST "$API/cards/me/token" -H "Authorization: Bearer $A" | jq_ ".shareToken")
[ "$NEW_TOK" != "$TOK_A" ] && ok "새 토큰이 나온다" || bad "토큰 재발급" "다른 값" "$NEW_TOK"
eq "  예전 QR 은 막힌다" '404' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/cards/by-token/$TOK_A" -H "Authorization: Bearer $B")"
eq "  새 QR 은 열린다"   '200' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/cards/by-token/$NEW_TOK" -H "Authorization: Bearer $B")"
eq "저장할 때 토큰이 바뀌지 않는다" '200' "$(save "$A" "$SOME_OFF")"
eq "  같은 QR 이 계속 열린다" '200' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/cards/by-token/$NEW_TOK" -H "Authorization: Bearer $B")"

echo
echo "── 잘못된 코드 ──"
# 경로 탈출(`../../etc`)은 curl 과 express 가 라우팅 전에 정규화해 버려서
# 핸들러까지 오지도 않는다 — 그걸로는 토큰 검사를 확인할 수 없다.
# 핸들러에 실제로 닿는 값으로 본다.
eq "너무 짧은 코드는 400" '400' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/cards/by-token/short" -H "Authorization: Bearer $B")"
eq "이상한 문자가 섞이면 400" '400' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/cards/by-token/aaaa%20bbbb%20cccc%20dddd" -H "Authorization: Bearer $B")"
eq "없는 코드는 404"   '404' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/cards/by-token/aaaaaaaaaaaaaaaaaaaaaa" -H "Authorization: Bearer $B")"
eq "로그인 없으면 401" '401' \
  "$(curl -s -o /dev/null -w '%{http_code}' "$API/cards/by-token/$NEW_TOK")"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
