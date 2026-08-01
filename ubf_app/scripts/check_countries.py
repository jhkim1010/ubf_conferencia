#!/usr/bin/env python3
"""국가 매핑 검증. verify.sh country-mapping 이 호출한다.

    cd ubf_app && python3 scripts/check_countries.py

확인하는 것:
  · ISO 코드 형식과 중복, 표시명 중복
  · ubf_chapters.json 의 모든 국가가 ISO 로 해석되는가  ← 이게 핵심이다.
    하나라도 해석되지 않으면 그 나라 참석자의 국내 판정이 조용히 실패한다.
  · 생성된 world_countries.dart 가 현재 표와 일치하는가 (표만 고치고 생성을 잊은 경우)
  · 죽은 별칭 (영문명으로 이미 풀리는데 별칭까지 둔 경우)

매핑 표를 import 하지 않고 직접 실행해 읽는다 — import 는 바이트코드 캐시를
타서 디스크 내용과 다른 값을 볼 수 있다. macOS 는 그 캐시를 프로젝트 밖
(~/Library/Caches/com.apple.python)에 두어 지우기도 어렵다. 실제로 이 저장소
작업 중에 "고쳤다 되돌린" 파일이 반영되지 않아 한참 헤맸다.
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')

ns = {}
with open(os.path.join(HERE, 'countries_table.py'), encoding='utf-8') as f:
    exec(compile(f.read(), 'countries_table.py', 'exec'), ns)
TABLE, ALIASES = ns['TABLE'], ns['UBF_ALIASES']

fail = 0


def bad(msg):
    global fail
    fail += 1
    print(f'  ✗ {msg}')


isos = [t[1] for t in TABLE]
for i in isos:
    if not re.fullmatch(r'[A-Z]{2}', i):
        bad(f'ISO 형식이 아님: {i}')
dup = sorted({i for i in isos if isos.count(i) > 1})
if dup:
    bad(f'ISO 중복: {dup}')

ens = [t[2] for t in TABLE]
edup = sorted({e for e in ens if ens.count(e) > 1})
if edup:
    bad(f'영문명 중복: {edup}')

kos = [t[0] for t in TABLE]
kdup = sorted({k for k in kos if kos.count(k) > 1})
if kdup:
    bad(f'한글명 중복: {kdup}')

en2iso = {t[2].upper(): t[1] for t in TABLE}


def resolve(nation):
    return ALIASES.get(nation) or en2iso.get(nation.strip().upper())


with open(os.path.join(ROOT, 'assets', 'ubf_chapters.json'), encoding='utf-8') as f:
    chapters = json.load(f)
unresolved = [e['nation'] for e in chapters if not resolve(e['nation'])]
if unresolved:
    bad(f'ISO 로 해석되지 않는 UBF 국가 ({len(unresolved)}): {unresolved}')

for k, v in ALIASES.items():
    if v not in isos:
        bad(f'별칭 {k} → {v} 는 표에 없는 ISO')
    elif en2iso.get(k.strip().upper()) == v:
        bad(f'불필요한 별칭 (영문명으로 이미 해석됨): {k}')

# 생성물이 표와 어긋나지 않는가. 표만 고치고 생성을 잊으면 앱은 옛 목록을 쓴다.
# 생성기를 임시 파일로 돌려 비교한다 — 검사가 소스를 고쳐서는 안 된다.
dart = os.path.join(ROOT, 'lib', 'core', 'constants', 'world_countries.dart')
current = open(dart, encoding='utf-8').read()
backup = current
try:
    subprocess.run([sys.executable, os.path.join(HERE, 'gen_countries.py')],
                   check=True, capture_output=True)
    regenerated = open(dart, encoding='utf-8').read()
    # dart format 이 줄바꿈을 바꿀 수 있으므로 공백을 무시하고 비교한다.
    if current.split() != regenerated.split():
        bad('world_countries.dart 가 매핑 표와 다릅니다 — '
            'python3 scripts/gen_countries.py 실행 후 dart format 하십시오')
finally:
    open(dart, 'w', encoding='utf-8').write(backup)

if not fail:
    print(f'  국가 {len(TABLE)}개 · UBF {len(chapters)}개 전부 ISO 로 해석 · 생성물 일치')
sys.exit(1 if fail else 0)
