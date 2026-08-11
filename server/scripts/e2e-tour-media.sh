#!/usr/bin/env bash
# 투어 옵션 자료(사진 여러 장 · 계획서 PDF 여러 장) 종단 검증 — 037
#
# 사용: API=http://localhost:3000 MEDIA_DIR=/tmp/ubf-media ./scripts/e2e-tour-media.sh
#
# 저장한 값은 참가자 화면에서 **그대로 열린다.** 그래서 정상 경로보다
# 속이려는 입력에 무게를 둔다 — 실행 통로가 되는 주소, 남의 경로, 같은 파일.
# 단위 시험(test/option_media.test.js)이 함수를 보고, 여기서는 그 판단이
# 실제로 DB 까지 이어지는지를 본다.
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
# 값을 못 꺼내면 ERR 를 낸다.
#
# 처음에는 그냥 빈 문자열이 나가게 뒀는데, 응답 모양이 달라 아무것도 못 꺼낸
# 상태에서 "나쁜 주소가 없다('')" 검사가 통과해 버렸다. 못 꺼낸 것과
# 정말 없는 것은 다르다.
jq_() { node -pe "
  try {
    const r = JSON.parse(require('fs').readFileSync(0));
    const v = (r$1);
    console.log(v === undefined || v === null ? '' : String(v));
  } catch (e) { console.log('ERR'); }
  ''" ; }
node_() { node -pe "
  try {
    const r = JSON.parse(require('fs').readFileSync(0));
    const o = r.program_options[0];
    console.log($1);
  } catch (e) { console.log('ERR'); }
  ''" ; }

LT=$(login "$LEADER")
NEW_LT=$(curl -s -X POST "$API/leaders/register" \
  -H "Authorization: Bearer $LT" -H 'Content-Type: application/json' \
  -d '{"name":"투어자료 e2e"}' \
  | node -pe "JSON.parse(require('fs').readFileSync(0)).token || ''" 2>/dev/null)
[ -n "$NEW_LT" ] && LT="$NEW_LT"

TMP=$(mktemp -d)
printf '%%PDF-1.7\n%%\xe2\xe3\xcf\xd3\n1 0 obj\n<<>>\nendobj\n' > "$TMP/plan.pdf"
printf '\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01' > "$TMP/photo.jpg"

up() { # $1=파일 → 저장된 주소
  curl -s -X POST "$API/media?kind=program" -H "Authorization: Bearer $LT" \
    -H 'Content-Type: application/octet-stream' --data-binary "@$1" | jq_ ".url"
}

echo "── 담당자가 올린다 ──"
PDF1=$(up "$TMP/plan.pdf")
PDF2=$(up "$TMP/plan.pdf")
IMG1=$(up "$TMP/photo.jpg")
IMG2=$(up "$TMP/photo.jpg")
case "$PDF1" in
  /media/program/*.pdf) ok "계획서 PDF 가 올라간다" ;;
  *) bad "계획서 PDF 가 올라간다" "/media/program/<uuid>.pdf" "$PDF1" ;;
esac
case "$IMG1" in
  /media/program/*.jpg) ok "사진이 올라간다" ;;
  *) bad "사진이 올라간다" "/media/program/<uuid>.jpg" "$IMG1" ;;
esac
[ "$PDF1" != "$PDF2" ] \
  && ok "같은 파일도 매번 새 이름으로 저장된다" \
  || bad "같은 파일도 매번 새 이름으로 저장된다" "다른 주소" "$PDF1"

# 올린 파일이 실제로 받아지는지. 주소만 돌려주고 못 받으면 소용이 없다.
eq "올린 계획서를 다시 받을 수 있다" '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API$PDF1")"

echo
echo "── 수양회에 투어를 만들고 자료를 붙인다 ──"
# 사진 둘 · 계획서 둘. 여기에 **막아야 하는 것들**을 섞는다.
OPTS=$(cat <<JSON
[{"name":"이과수 투어","cost":120,"capacity":40,
  "photoUrls":["$IMG1","$IMG2","$IMG1","javascript:alert(1)"],
  "planDocs":[
    {"url":"$PDF1","name":"일정표","bytes":91234},
    {"url":"$PDF2","name":"  비용   안내  "},
    {"url":"$PDF1","name":"같은 파일 다시"},
    {"url":"javascript:alert(1)","name":"나쁨"},
    {"url":"/media/../../etc/passwd","name":"경로벗어남"},
    {"name":"주소 없음"}
  ]}]
JSON
)
P=$(curl -s -X POST "$API/programs" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"투어자료검증-$$\",\"location\":\"이과수\",\"startDate\":\"2027-07-01\",
       \"programType\":\"international\",\"feeBasic\":100,\"options\":$OPTS}" \
  | jq_ ".id || r.existingId")
[ -n "$P" ] || { echo "수양회를 만들지 못했습니다"; exit 1; }

GET() { curl -s "$API/programs/$P" -H "Authorization: Bearer $LT"; }
docs() { GET | node_ "(o.planDocs || []).map(d => d.name).join('|')"; }
urls() { GET | node_ "(o.photoUrls || []).join('|')"; }

eq "계획서 두 장이 이름 그대로 나온다" '일정표|비용 안내' "$(docs)"
eq "사진 두 장이 나온다"               "$IMG1|$IMG2"      "$(urls)"
eq "  크기도 함께 저장된다" '91234' \
   "$(GET | jq_ ".program_options[0].planDocs[0].bytes")"

echo
echo "── 속이려는 값은 저장되지 않는다 ──"
# 이 값들은 참가자 화면에서 launchUrl 로 그대로 열린다.
eq "실행 통로가 되는 주소(javascript:)가 빠진다" '' \
   "$(GET | node_ "[...(o.planDocs||[]).map(d=>d.url), ...(o.photoUrls||[])]
        .filter(u => /^javascript:/i.test(u)).join(',')")"
eq "경로를 벗어나는 주소가 빠진다" '' \
   "$(GET | node_ "(o.planDocs||[]).map(d=>d.url).filter(u => u.includes('..')).join(',')")"
eq "같은 파일은 한 번만 들어간다" '2' \
   "$(GET | jq_ ".program_options[0].planDocs.length")"
eq "  사진도 중복이 빠진다" '2' "$(GET | jq_ ".program_options[0].photoUrls.length")"

echo
echo "── 상한 ──"
MANY=$(node -pe "
  JSON.stringify([{name:'많이',cost:0,planDocs:
    Array.from({length:25},(_,i)=>({url:'/media/program/'+String(i).padStart(8,'0')+'-d9cb-469f-a165-70867728950e.pdf',name:'p'+i}))}])")
eq "옵션 고치기가 통한다" '200' "$(curl -s -o /dev/null -w '%{http_code}' \
  -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d "{\"options\":$MANY}")"
eq "계획서는 열 장까지만 저장된다" '10' "$(GET | jq_ ".program_options[0].planDocs.length")"

echo
echo "── 옵션을 고쳐도 자료가 살아남는다 ──"
KEEP=$(cat <<JSON
[{"name":"이과수 투어","cost":150,
  "planDocs":[{"url":"$PDF1","name":"일정표"}],"photoUrls":["$IMG1"]}]
JSON
)
curl -s -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' -d "{\"options\":$KEEP}" > /dev/null
eq "고친 뒤에도 계획서가 남는다" '일정표' "$(GET | jq_ ".program_options[0].planDocs[0].name")"
eq "  파일도 그대로 받아진다"   '200' \
   "$(curl -s -o /dev/null -w '%{http_code}' "$API$PDF1")"

echo
echo "── 자료가 없는 투어 ──"
curl -s -X PATCH "$API/programs/$P" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"options":[{"name":"자료없음","cost":0}]}' > /dev/null
# 여기서 null 이 나가면 앱의 `as List?` 가 그대로 빈 화면이 된다.
eq "계획서 칸은 빈 목록으로 온다" '[]' \
   "$(GET | node_ "JSON.stringify(o.planDocs)")"

rm -rf "$TMP"
echo
echo "통과 $pass · 실패 $fail"
[ "$fail" -eq 0 ]
