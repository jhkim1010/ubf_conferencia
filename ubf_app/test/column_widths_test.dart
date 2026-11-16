import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/column_widths.dart';

void main() {
  test('바꾸지 않은 칸은 기본 폭이다', () {
    final w = ColumnWidths();
    expect(w.of('name', 240), 240);
    expect(w.isCustom('name'), isFalse);
  });

  test('끌면 넓어지고 줄어들되 범위를 넘지 않는다', () {
    final w = ColumnWidths();
    w.resize('name', 240, 30);
    expect(w.of('name', 240), 270);
    w.resize('name', 240, -1000);
    expect(w.of('name', 240), ColumnWidths.min);
    w.resize('name', 240, 5000);
    expect(w.of('name', 240), ColumnWidths.max);
  });

  test('되돌리면 기본 폭으로 간다 — 코드의 기본값이 바뀌어도 따라간다', () {
    final w = ColumnWidths()..resize('name', 240, 30);
    w.reset('name');
    expect(w.of('name', 300), 300);
  });

  test('저장했다 불러오면 같다', () {
    final w = ColumnWidths()..resize('phone', 160, -20);
    final back = ColumnWidths.decode(w.encode());
    expect(back.of('phone', 160), 140);
    expect(back.of('name', 240), 240);
  });

  test('깨진 저장값은 기본 폭으로 간다', () {
    expect(ColumnWidths.decode('not json').of('a', 100), 100);
    expect(ColumnWidths.decode('[1,2]').of('a', 100), 100);
    expect(ColumnWidths.decode('{"a":"x","b":9999}').of('a', 100), 100);
    expect(ColumnWidths.decode('{"b":9999}').of('b', 100), ColumnWidths.max);
    expect(ColumnWidths.decode(null).of('a', 100), 100);
  });
}
