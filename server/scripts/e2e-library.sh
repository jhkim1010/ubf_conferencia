#!/usr/bin/env bash
# 파일 업로드 + 수양회 자료실 종단 검증
#
# 사용: API=http://localhost:3000 MEDIA_DIR=/tmp/ubf-media ./scripts/e2e-library.sh
#
# 업로드는 서버가 남의 파일 창고가 되기 쉬운 자리다. 정상 경로보다
# **속이려는 입력**에 무게를 둔다 — 이미지가 아닌 것, 경로를 벗어나는 값,
# 로그인하지 않은 요청.
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
PT=$(login "lib-part-$$@test.local")

TMP=$(mktemp -d)
# 진짜 PDF 와 진짜 JPEG 의 첫 바이트. 내용은 중요하지 않고 머리만 맞으면 된다.
printf '%%PDF-1.7\n%%\xe2\xe3\xcf\xd3\n1 0 obj\n<<>>\nendobj\n' > "$TMP/ok.pdf"
printf '\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01' > "$TMP/ok.jpg"
# 이름만 .pdf 인 파일. 확장자를 믿으면 이것이 통과한다.
printf '<?php system($_GET[0]); ?>                    ' > "$TMP/evil.pdf"

up() { # $1=파일 $2=kind $3=토큰 → JSON
  curl -s -X POST "$API/media?kind=$2" -H "Authorization: Bearer $3" \
    -H 'Content-Type: application/octet-stream' --data-binary "@$1"
}
upCode() { # $1=파일 $2=kind $3=토큰 → http 코드
  curl -s -o /dev/null -w '%{http_code}' -X POST "$API/media?kind=$2" \
    -H "Authorization: Bearer $3" -H 'Content-Type: application/octet-stream' \
    --data-binary "@$1"
}
jq_() { node -pe "const r=JSON.parse(require('fs').readFileSync(0)); String((r$1) ?? '')"; }

P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"자료실검증-$$\",\"location\":\"도서관\",\"startDate\":\"2027-07-01\",
       \"programType\":\"international\",\"feeBasic\":100}" \
  | jq_ ".id || r.existingId")
[ ${#P} -eq 36 ] || { echo "생성 실패: $P"; exit 1; }

echo "── 업로드 ──"
PDF_URL=$(up "$TMP/ok.pdf" library "$LT" | jq_ ".url")
case "$PDF_URL" in
  /media/library/*.pdf) ok "PDF 를 올리면 /media/library/ 아래에 무작위 이름으로 저장된다" ;;
  *) bad "PDF 업로드" "/media/library/<uuid>.pdf" "$PDF_URL" ;;
esac
IMG_URL=$(up "$TMP/ok.jpg" program "$LT" | jq_ ".url")
case "$IMG_URL" in
  /media/program/*.jpg) ok "사진은 갈래별 폴더로 나뉜다" ;;
  *) bad "사진 업로드" "/media/program/<uuid>.jpg" "$IMG_URL" ;;
esac

echo
echo "── 속이려는 입력 ──"
# 이름이 .pdf 여도 내용이 PDF 가 아니면 받지 않는다.
eq "이름만 .pdf 인 파일은 415"   '415' "$(upCode "$TMP/evil.pdf" library "$LT")"
# 갈래를 경로로 쓰면 아무 데나 쓸 수 있다. 모르는 갈래는 misc 로 떨어진다.
MISC=$(up "$TMP/ok.jpg" '../../etc' "$LT" | jq_ ".url")
case "$MISC" in
  /media/misc/*) ok "모르는 갈래는 misc 로 떨어진다 (경로 탈출 없음)" ;;
  *) bad "갈래 정규화" "/media/misc/…" "$MISC" ;;
esac
eq "로그인 없으면 401" '401' \
  "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/media?kind=library" \
     -H 'Content-Type: application/octet-stream' --data-binary "@$TMP/ok.pdf")"

echo
echo "── 자료실 ──"
add() { curl -s -X POST "$API/library/$P" -H "Authorization: Bearer $1" \
  -H 'Content-Type: application/json' -d "$2"; }
addCode() { curl -s -o /dev/null -w '%{http_code}' -X POST "$API/library/$P" \
  -H "Authorization: Bearer $1" -H 'Content-Type: application/json' -d "$2"; }

# JSON 은 변수에 담아 넘긴다.
#
# "$(addCode ... "{\"title\":…}")" 처럼 큰따옴표 안에 명령치환을 중첩하면
# 이스케이프가 안쪽까지 살아남지 못해 본문이 깨진다. 그러면 서버가 400 을
# 주는데, **제목이 없어서가 아니라 JSON 이 깨져서**다 — 검사가 통과해도
# 아무것도 확인하지 못한 것이다. 실제로 그렇게 통과하고 있었다.
BODY_OK='{"title":"1과 교재","fileUrl":"'"$PDF_URL"'","mime":"application/pdf"}'
BODY_NO_TITLE='{"fileUrl":"'"$PDF_URL"'"}'
BODY_AS_PART='{"title":"x","fileUrl":"'"$PDF_URL"'"}'

ID=$(add "$LT" "$BODY_OK" | jq_ ".id")
[ ${#ID} -eq 36 ] && ok "담당자가 자료를 등록한다" || bad "자료 등록" "uuid" "$ID"

eq "제목이 없으면 400" '400' "$(addCode "$LT" "$BODY_NO_TITLE")"
# 임의 주소를 받으면 자료실이 아무 사이트로나 사람을 보내는 통로가 된다.
eq "외부 주소는 400"   '400' "$(addCode "$LT" '{"title":"x","fileUrl":"https://evil.example/x.pdf"}')"
eq "경로 탈출도 400"   '400' "$(addCode "$LT" '{"title":"x","fileUrl":"/media/library/../../../etc/passwd"}')"
eq "참가자는 등록 못 한다 403" '403' "$(addCode "$PT" "$BODY_AS_PART")"

titles() { curl -s "$API/library/$P" -H "Authorization: Bearer $1" \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).map(r=>r.title).join(',')"; }
eq "참가자도 목록을 본다" '1과 교재' "$(titles "$PT")"

echo
echo "── 안 보이게 두기 ──"
# 수양회 전날 미리 올려 두고 당일 아침에 여는 식으로 쓴다.
curl -s -o /dev/null -X PATCH "$API/library/$P/$ID" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d '{"isPublished":false}'
eq "내리면 참가자에게 안 보인다" '' "$(titles "$PT")"
eq "  담당자에게는 보인다" '1과 교재' \
  "$(curl -s "$API/library/$P/all" -H "Authorization: Bearer $LT" \
     | node -pe "JSON.parse(require('fs').readFileSync(0)).map(r=>r.title).join(',')")"

echo
echo "── 삭제 ──"
eq "자료를 지운다" '200' \
  "$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$API/library/$P/$ID" -H "Authorization: Bearer $LT")"
# 파일도 함께 지운다. 남기면 아무도 볼 수 없는 파일이 디스크에 쌓인다.
MEDIA="${MEDIA_DIR:-/tmp/ubf-media}"
LEFT="$MEDIA/library/$(basename "$PDF_URL")"
[ -f "$LEFT" ] && bad "파일도 지워진다" "없음" "$LEFT 남아 있음" || ok "파일도 함께 지워진다"

curl -s -o /dev/null -X DELETE "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d "{\"confirmName\":\"자료실검증-$$\"}"
rm -rf "$TMP"

echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
