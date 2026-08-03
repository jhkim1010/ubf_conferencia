#!/usr/bin/env bash
# 수양회별 텔레그램 봇 종단 검증
#
# 사용: API=http://localhost:3000 ./scripts/e2e-telegram-bot.sh
#
# 가장 중요한 것은 **토큰이 응답으로 새지 않는가**다. 프로그램 조회는 참가자
# 누구나 부를 수 있는 경로라, SELECT p.* 로 그대로 내보내면 등록한 사람
# 전원이 그 봇으로 아무 메시지나 보낼 수 있게 된다.
set -uo pipefail
API="${API:-http://localhost:3000}"
LEADER="${LEADER:-leader@test.com}"

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

LT=$(login "$LEADER")
NEW_LT=$(curl -s -X POST "$API/leaders/register" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"name":"e2e 리더"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"
PT=$(login "tg-part-$$@test.local")

# 형식만 맞는 가짜 토큰. 실제로 전송하지 않으므로 텔레그램에 닿지 않는다.
TOKEN='123456789:AAFAKEfakeFAKEfake0123456789abcdefgh'
BAD='123:short'

mk() { # $1=이름 $2=봇토큰(빈 값이면 안 보냄) → id 또는 http 코드
  local d="{\"name\":\"$1\",\"location\":\"텔레그램\",\"startDate\":\"2027-07-01\",
            \"programType\":\"international\",\"hostCountry\":\"AR\",\"feeBasic\":100"
  [ -n "$2" ] && d="$d,\"telegramBotToken\":\"$2\",\"telegramChatId\":\"-1001234567890\""
  curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/json' -d "$d}" \
    | node -pe "const r=JSON.parse(require('fs').readFileSync(0)); r.id||r.existingId||r.error||''"
}
mkCode() { # $1=이름 $2=봇토큰 → http 코드
  curl -s -o /dev/null -w '%{http_code}' -X POST "$API/programs" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
    -d "{\"name\":\"$1\",\"location\":\"텔레그램\",\"startDate\":\"2027-07-01\",
         \"programType\":\"international\",\"feeBasic\":100,\"telegramBotToken\":\"$2\"}"
}
# 응답 어디에도 토큰 문자열이 없어야 한다. 키 이름이 아니라 값으로 찾는다 —
# 이름을 바꿔 담아도 새는 것은 마찬가지다.
leaks() { # $1=programId $2=토큰 → yes/no
  local body; body=$(curl -s "$API/programs/$1" -H "Authorization: Bearer $PT")
  case "$body" in *"$2"*) echo yes ;; *) echo no ;; esac
}
listLeaks() { # $1=토큰 → yes/no
  local body; body=$(curl -s "$API/programs" -H "Authorization: Bearer $LT")
  case "$body" in *"$1"*) echo yes ;; *) echo no ;; esac
}
configured() { # $1=programId → true/false
  curl -s "$API/programs/$1" -H "Authorization: Bearer $PT" \
    | node -pe "String(JSON.parse(require('fs').readFileSync(0)).telegram_bot_configured)"
}
chatId() { # $1=programId
  curl -s "$API/programs/$1" -H "Authorization: Bearer $PT" \
    | node -pe "String(JSON.parse(require('fs').readFileSync(0)).telegram_chat_id)"
}
patch() { # $1=programId $2=json 조각 → http 코드
  curl -s -o /dev/null -w '%{http_code}' -X PATCH "$API/programs/$1" \
    -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' -d "$2"
}
cleanup() { curl -s -o /dev/null -X DELETE "$API/programs/$1" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d "{\"confirmName\":\"$2\"}"; }

NAME="텔레그램검증-$$"
P=$(mk "$NAME" "$TOKEN")
[ ${#P} -eq 36 ] || { echo "생성 실패: $P"; exit 1; }

echo "── 토큰이 새지 않는다 ──"
eq "참가자 조회에 토큰이 없다" 'no' "$(leaks "$P" "$TOKEN")"
eq "리더 목록에도 없다"        'no' "$(listLeaks "$TOKEN")"
eq "  대신 설정 여부만 알린다" 'true' "$(configured "$P")"
eq "  단톡방 id 는 보인다"     '-1001234567890' "$(chatId "$P")"

echo
echo "── 형식 검사 ──"
# 붙여넣다 잘린 토큰을 그대로 저장하면 알림이 조용히 안 간다.
eq "잘린 토큰은 400"    '400' "$(mkCode "텔레그램형식-$$" "$BAD")"
eq "수정에서도 400"     '400' "$(patch "$P" "{\"telegramBotToken\":\"$BAD\"}")"
eq "  기존 설정은 남는다" 'true' "$(configured "$P")"

echo
echo "── 다른 항목만 고쳐도 토큰이 지워지지 않는다 ──"
# 화면은 토큰을 읽을 수 없다(응답에 없다). 매번 다시 보내라고 하면 담당자가
# 참가비만 고칠 때마다 토큰을 잃는다.
eq "참가비만 수정"        '200'  "$(patch "$P" '{"feeBasic":150}')"
eq "  토큰이 그대로 남는다" 'true' "$(configured "$P")"

echo
echo "── 스스로 비우기 ──"
eq "빈 문자열을 보내면" '200'   "$(patch "$P" '{"telegramBotToken":""}')"
eq "  설정이 풀린다"    'false' "$(configured "$P")"

cleanup "$P" "$NAME"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
