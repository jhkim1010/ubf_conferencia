// 공동 관리자가 맡는 분야 — 앱 쪽 (059)
//
// **앱과 서버가 같은 이름을 써야 한다.** 어긋나면 화면에서 고른 분야가
// 서버에서 조용히 버려지고, 담당자는 골랐는데 안 된다고 여긴다.
// 이 저장소에서 식사 제한이 정확히 그렇게 두 벌이 되어 카드는 4명,
// 표는 2명이 된 적이 있다(027·036).

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/constants/admin_scopes.dart';

void main() {
  test('서버가 아는 분야와 이름이 하나하나 같다', () {
    // 서버 소스를 그대로 읽는다. 목록을 여기 다시 적으면 그것도 두 벌이다.
    final src = File(
      '../server/src/services/admin_scopes.js',
    ).readAsStringSync();
    final at = src.indexOf('export const SCOPES = [');
    // 파일이 옮겨 가면 indexOf 가 -1 을 주고 substring 이 터진다. 그때
    // "목록이 다르다"가 아니라 "어디서 읽어야 하는지 모르겠다"고 말해야
    // 고칠 곳을 바로 찾는다.
    expect(at, isNonNegative, reason: '서버에서 SCOPES 목록을 못 찾았다');
    final block = src.substring(at, src.indexOf('];', at));
    final server = RegExp(
      "'([a-z]+)'",
    ).allMatches(block).map((m) => m.group(1)!).toList();
    final app = adminScopes.map((s) => s.key).toList();
    expect(app, server, reason: '앱과 서버의 분야 이름이 다르다');
  });

  test('비어 있으면 전부라는 뜻', () {
    // 059 이전에 세운 사람은 값이 없다. 화면이 마음대로 좁히면 안 된다.
    expect(scopesOf(null), isNull);
    expect(scopesOf(const []), isNull);
    expect(scopesOf(const ['all']), isNull);
  });

  test('고른 것만 본다', () {
    final mine = scopesOf(const ['rooms', 'transport']);
    expect(canSee(mine, 'rooms'), isTrue);
    expect(canSee(mine, 'ledger'), isFalse);
  });

  test('전부면 무엇이든 본다', () {
    expect(canSee(null, 'medical'), isTrue);
  });
}
