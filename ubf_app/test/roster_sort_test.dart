// 명단 표를 칼럼으로 줄 세우는 값 (057)
//
// **글자로 견주면 조용히 틀린다.** "9" 는 "41" 보다 크고, 그러면 아홉 살이
// 마흔한 살보다 뒤에 선다. 담당자는 화면이 고장 났다고 여기지, 정렬 방식을
// 의심하지 않는다. 그래서 화면 밖으로 빼서 여기서 지킨다.

import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/roster_sort.dart';

List<Map<String, dynamic>> sortedBy(
  List<Map<String, dynamic>> rows,
  String Function(Map<String, dynamic>) key,
) => [...rows]..sort((a, b) => key(a).compareTo(key(b)));

void main() {
  test('나이는 글자가 아니라 수로 선다', () {
    final rows = [
      {'real_name': 'c', 'gender': 'M', 'age': 41},
      {'real_name': 'a', 'gender': 'M', 'age': 9},
      {'real_name': 'b', 'gender': 'M', 'age': 100},
    ];
    final out = sortedBy(rows, rosterAgeKey).map((r) => r['age']).toList();
    expect(out, [9, 41, 100]);
  });

  test('성별로 묶고 그 안에서 나이순', () {
    final rows = [
      {'gender': 'F', 'age': 20},
      {'gender': 'M', 'age': 60},
      {'gender': 'F', 'age': 70},
      {'gender': 'M', 'age': 30},
    ];
    final out = sortedBy(
      rows,
      rosterAgeKey,
    ).map((r) => '${r['gender']}${r['age']}').toList();
    expect(out, ['F20', 'F70', 'M30', 'M60']);
  });

  test('나이를 안 적은 사람은 맨 뒤', () {
    // 0 으로 두면 갓난아기처럼 맨 앞에 서고, 담당자가 그 줄부터 본다.
    final rows = [
      {'gender': 'M', 'age': null},
      {'gender': 'M', 'age': 70},
      {'gender': 'M', 'age': 20},
    ];
    final out = sortedBy(rows, rosterAgeKey).map((r) => r['age']).toList();
    expect(out, [20, 70, null]);
  });

  test('이름은 세례명이 먼저, 없으면 본명', () {
    expect(
      rosterNameKey({'bible_name': 'Marcos', 'real_name': 'Kim'}),
      'marcos',
    );
    expect(rosterNameKey({'bible_name': '', 'real_name': 'Kim'}), 'kim');
    expect(rosterNameKey({'real_name': 'Kim'}), 'kim');
  });

  test('입금은 미납이 위로, 같은 상태면 낼 돈이 많은 쪽이 먼저', () {
    // 이 칸을 누르는 까닭은 받을 돈을 찾기 위해서다.
    final rows = [
      {
        'amount_due': 200,
        'payment': {'status': 'confirmed', 'amount': 200},
      },
      {
        'amount_due': 300,
        'payment': {'status': null, 'amount': 0},
      },
      {
        'amount_due': 900,
        'payment': {'status': null, 'amount': 0},
      },
    ];
    final out = sortedBy(
      rows,
      rosterPayKey,
    ).map((r) => r['amount_due']).toList();
    expect(out.first, 900, reason: '가장 많이 받을 사람이 위에 없다');
    expect(out.last, 200, reason: '완납한 사람이 위로 왔다');
  });

  test('나라는 표시명으로 선다', () {
    // 저장값은 ISO 다. 코드로 견주면 화면 순서와 달라 보인다.
    expect(rosterCountryKey({'country': 'AR'}), 'argentina');
    expect(rosterCountryKey({'country': null}), '');
  });
}
