import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/i18n_text.dart';

// 담당자가 적은 글을 보는 사람의 언어로 (071·072)
//
// 한 언어밖에 없을 수 있다는 것이 화면 문구와 다른 점이다. 없으면 원문으로
// 돌아간다 — 빈 화면보다 못 읽는 글이 낫다.

void main() {
  const i18n = {'ko': '하나님의 양 떼를 치라', 'es': 'Apacentad la grey de Dios'};

  test('그 사람의 언어로', () {
    expect(pickI18n(i18n, 'ko', '원문'), '하나님의 양 떼를 치라');
    expect(pickI18n(i18n, 'es', '원문'), 'Apacentad la grey de Dios');
  });

  test('없는 언어면 원문', () {
    // 번역이 실패한 언어가 여기로 온다.
    expect(
      pickI18n(i18n, 'pt', 'Apacentad la grey de Dios'),
      'Apacentad la grey de Dios',
    );
  });

  test('번역 덩이가 아예 없으면 원문', () {
    // 071 이전에 적어 둔 글, 번역기를 안 붙인 수양회가 이 상태다.
    expect(pickI18n(null, 'en', '원문'), '원문');
    expect(pickI18n('문자열이 왔다', 'en', '원문'), '원문');
  });

  test('빈 값은 번역으로 치지 않는다', () {
    expect(pickI18n({'en': '   '}, 'en', '원문'), '원문');
  });

  test('원문마저 없으면 null — 화면이 그 줄을 통째로 감춘다', () {
    expect(pickI18n(null, 'en', null), isNull);
    expect(pickI18n(null, 'en', '  '), isNull);
    expect(pickI18n(const {}, 'en', ''), isNull);
  });
}
