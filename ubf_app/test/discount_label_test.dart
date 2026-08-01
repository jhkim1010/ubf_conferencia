import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/money.dart';

// 할인 항목 문구는 관리자가 직접 쓴다(행사마다 일정이 달라 ARB 로 번역할 수
// 없다). 한 줄만 받으면 다른 언어 사용자는 읽지 못한 채 고르게 된다 —
// 돈이 걸린 선택지라 더 나쁘다.
void main() {
  const trilingual = {
    'label': 'Attending one day only',
    'labels': {
      'ko': '1일만 참석',
      'en': 'Attending one day only',
      'es': 'Asisto solo un día',
    },
  };

  test('현재 언어의 문구를 고른다', () {
    expect(discountLabelFor(trilingual, 'ko'), '1일만 참석');
    expect(discountLabelFor(trilingual, 'en'), 'Attending one day only');
    expect(discountLabelFor(trilingual, 'es'), 'Asisto solo un día');
  });

  test('그 언어가 비어 있으면 기본 문구로 대체한다', () {
    // 세 칸을 모두 채우도록 강제하지 않는다. 강제하면 한 언어만 쓰는 지부가
    // 항목을 아예 못 만든다.
    const partial = {
      'label': '1일만 참석',
      'labels': {'ko': '1일만 참석'},
    };
    expect(discountLabelFor(partial, 'ko'), '1일만 참석');
    expect(discountLabelFor(partial, 'es'), '1일만 참석');
    expect(discountLabelFor(partial, 'en'), '1일만 참석');
  });

  test('labels 가 없는 예전 항목도 그대로 동작한다', () {
    const old = {'label': '기타 사정'};
    expect(discountLabelFor(old, 'ko'), '기타 사정');
    expect(discountLabelFor(old, 'es'), '기타 사정');
  });

  test('공백만 있는 문구는 없는 것으로 본다', () {
    const spacey = {
      'label': 'Fallback',
      'labels': {'ko': '   ', 'en': 'One day'},
    };
    expect(discountLabelFor(spacey, 'ko'), 'Fallback');
    expect(discountLabelFor(spacey, 'en'), 'One day');
  });

  test('아무것도 없으면 빈 문자열', () {
    expect(discountLabelFor(const {}, 'ko'), '');
    expect(discountLabelFor(const {'label': null}, 'ko'), '');
  });

  test('모르는 언어 코드는 기본 문구', () {
    expect(discountLabelFor(trilingual, 'fr'), 'Attending one day only');
  });
}
