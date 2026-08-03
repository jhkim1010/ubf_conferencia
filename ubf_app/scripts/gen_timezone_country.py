#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""IANA 시간대 → ISO 3166-1 alpha-2 국가 코드 표를 만든다.

  python3 scripts/gen_timezone_country.py zone.tab > lib/core/constants/timezone_country.dart

원본: https://raw.githubusercontent.com/eggert/tz/main/zone.tab
zone.tab 은 "국가코드<TAB>좌표<TAB>시간대" 형식이고 '#' 로 시작하는 줄은 주석이다.

이 표를 손으로 적지 않는 이유: 448줄이라 한 줄만 잘못 옮겨도 그 나라 사람
전원이 엉뚱한 국가로 기본 선택된다. 그리고 틀려도 아무 오류가 나지 않는다.
"""
import sys

def main(path):
    rows = []
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line or line.startswith('#'):
            continue
        parts = line.split('\t')
        if len(parts) < 3:
            continue
        iso, zone = parts[0].strip(), parts[2].strip()
        if len(iso) == 2 and zone:
            rows.append((zone, iso))
    rows.sort()

    out = [
        '// IANA 시간대 → 국가(ISO 3166-1 alpha-2).',
        '// **생성 파일이므로 손으로 고치지 말 것.**',
        '// 고칠 때는 scripts/gen_timezone_country.py 를 돌린다.',
        '//',
        '// 시간대를 쓰는 이유: 위치에서 나온 값인데 권한을 묻지 않고, 웹·데스크톱',
        '// 에서도 얻을 수 있다. 앱 언어로 짐작하면 틀린다 — 아르헨티나에 사는',
        '// 한국인 선교사의 폰은 한국어다.',
        '//',
        '// 어디까지나 **기본 선택**이다. 참가자가 바꿀 수 있어야 한다.',
        'const Map<String, String> timezoneToCountry = {',
    ]
    for zone, iso in rows:
        out.append(f"  '{zone}': '{iso}',")
    out.append('};')
    print('\n'.join(out))

if __name__ == '__main__':
    main(sys.argv[1])
