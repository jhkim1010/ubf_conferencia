#!/usr/bin/env python3
"""lib/core/constants/world_countries.dart 를 생성한다.

    cd ubf_app && python3 scripts/gen_countries.py

매핑 표는 scripts/countries_table.py 에 있다. 국가를 추가·수정할 때는 표만
고치고 이 스크립트를 다시 돌린다. 생성된 Dart 파일은 손으로 고치지 말 것.

검증은 scripts/check_countries.py 가 한다 (verify.sh country-mapping).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'lib', 'core', 'constants', 'world_countries.dart')

ns = {}
with open(os.path.join(HERE, 'countries_table.py'), encoding='utf-8') as f:
    exec(compile(f.read(), 'countries_table.py', 'exec'), ns)
TABLE, ALIASES = ns['TABLE'], ns['UBF_ALIASES']

rows = sorted(TABLE, key=lambda t: t[2])  # 영문명 순

legacy = {}
for ko, iso, en, es in rows:
    legacy[ko] = iso          # 예전 users.region / programs.host_country (한글)
    legacy[en.upper()] = iso  # 예전 registrations.country (영문 대문자)
for k, v in ALIASES.items():
    legacy[k.upper()] = v     # UBF 지부 목록의 어긋난 표기


def q(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


out = []
w = out.append
w("""// 국가 목록. **생성 파일이므로 손으로 고치지 말 것.**
// 고칠 때는 scripts/countries_table.py 를 고치고 scripts/gen_countries.py 를 돌린다.
//
// **저장하는 값은 ISO 3166-1 alpha-2 코드**이고, 화면에 보이는 이름은 영어다.
// 사용자 언어가 한국어든 스페인어든 국가명은 영어로 통일한다 — 국가명을
// 번역해 두면 같은 나라가 언어마다 다른 문자열이 되어 비교가 깨진다.
//
// 예전에는 표시명을 그대로 저장했고, 그 표시명의 출처가 두 개였다.
// users.region 에는 '아르헨티나'(한글), registrations.country 에는
// 'ARGENTINA'(영문)가 들어가 같은 나라를 가리키면서도 절대 일치하지 않았다.
// 국내 참석자 판정·코호트 집계·봉사 자격이 모두 조용히 틀렸다.
// 019 마이그레이션이 기존 값을 코드로 되돌린다.

class Country {
  /// DB 에 저장되는 값.
  final String iso;

  /// 화면 표시명. 항상 영어다.
  final String name;

  const Country(this.iso, this.name);
}

class WorldCountries {
  const WorldCountries._();

  /// 영문명 순으로 정렬돼 있다. 화면에서 그대로 쓰면 된다.
  static const List<Country> all = [""")
for ko, iso, en, es in rows:
    w(f"    Country({q(iso)}, {q(en)}),")
w("""  ];

  static const Map<String, String> _byIso = {""")
for ko, iso, en, es in rows:
    w(f"    {q(iso)}: {q(en)},")
w("""  };

  /// ISO 코드로 표시명을 얻는다. 모르는 코드면 코드를 그대로 돌려준다 —
  /// 빈칸을 보여주면 값이 없는 것인지 모르는 것인지 구분되지 않는다.
  static String? nameOf(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return _byIso[iso] ?? iso;
  }

  static bool isKnown(String? iso) => iso != null && _byIso.containsKey(iso);

  /// 저장된 값이 무엇이든 화면에 보일 영문 국가명으로.
  ///
  /// 019 마이그레이션이 놓친 행과 예전 버전 앱이 저장한 값이 섞여 있을 수 있어
  /// 표시 지점에서는 항상 이것을 쓴다. 해석되지 않으면 원래 값을 그대로 보여준다.
  static String? display(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final iso = isoForLegacy(value);
    return iso == null ? value : nameOf(iso);
  }

  /// 예전 표기(한글 표시명, UBF 지부 목록의 영문 표기)를 ISO 로 되돌린다.
  /// 이미 ISO 면 그대로 돌려준다.
  static String? isoForLegacy(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty) return null;
    if (_byIso.containsKey(v)) return v;
    return _legacy[v] ?? _legacy[v.toUpperCase()];
  }

  // 예전 표기 → ISO. 한글 표시명, 영문명(대문자), UBF 지부 목록의 어긋난 표기.
  static const Map<String, String> _legacy = {""")
for k in sorted(legacy):
    w(f"    {q(k)}: {q(legacy[k])},")
w("""  };
}
""")

with open(OUT, 'w', encoding='utf-8') as f:
    f.write("\n".join(out))
print(f'생성: {os.path.relpath(OUT, HERE)} — 국가 {len(rows)}개, legacy 키 {len(legacy)}개',
      file=sys.stderr)
