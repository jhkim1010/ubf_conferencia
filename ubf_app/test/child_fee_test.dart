import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/child_fee.dart';

// 어린이 참가비 (073)
//
// 서버의 services/companion_role.js 와 **같은 규칙**이어야 한다. 갈라지면
// 등록 화면이 말한 금액과 명단에 남는 금액이 달라진다. 그래서 서버 쪽
// test/companion_role.test.js 와 같은 경우들을 여기서도 확인한다.

Map<String, dynamic> kid(int? age, {Object? feeShare}) => {
  'registersSeparately': false,
  'age': age,
  'feeShare': ?feeShare,
};

void main() {
  group('나이로 정하는 몫', () {
    const p = ChildFeePolicy.fallback; // 4~8살 절반

    test('구간보다 어리면 안 받는다', () {
      expect(p.shareForAge(0), 0);
      expect(p.shareForAge(3), 0);
    });

    test('구간 안이면 절반 — 경계를 포함한다', () {
      // 네 살과 여덟 살이 빠지면 "4살부터 8살까지" 를 그렇게 읽은 것이 아니다.
      expect(p.shareForAge(4), 0.5);
      expect(p.shareForAge(6), 0.5);
      expect(p.shareForAge(8), 0.5);
    });

    test('구간보다 많으면 어른과 같이 전액', () {
      expect(p.shareForAge(9), 1);
      expect(p.shareForAge(40), 1);
    });

    test('나이를 모르면 받지 않는다', () {
      // 잘못 받는 쪽이 덜 받는 쪽보다 나쁘다 — 서버도 같은 판단이다.
      expect(p.shareForAge(null), 0);
    });
  });

  group('수양회가 정한 구간을 읽는다', () {
    test('칸이 비어 있으면 기본값', () {
      final p = ChildFeePolicy.of({});
      expect(p.minAge, 4);
      expect(p.maxAge, 8);
      expect(p.rate, 0.5);
    });

    test('적어 둔 값을 그대로 쓴다', () {
      final p = ChildFeePolicy.of({
        'fee_child_age_min': 6,
        'fee_child_age_max': 12,
        'fee_child_rate': 0.3,
      });
      expect(p.shareForAge(5), 0);
      expect(p.shareForAge(6), 0.3);
      expect(p.shareForAge(12), 0.3);
      expect(p.shareForAge(13), 1);
    });

    test('문자열로 와도 읽는다', () {
      // 서버의 NUMERIC 은 문자열로 올 수 있다.
      final p = ChildFeePolicy.of({
        'fee_child_age_min': '4',
        'fee_child_age_max': '8',
        'fee_child_rate': '0.50',
      });
      expect(p.rate, 0.5);
      expect(p.shareForAge(5), 0.5);
    });

    test('거꾸로 적힌 구간에서도 무너지지 않는다', () {
      final p = ChildFeePolicy.of({
        'fee_child_age_min': 9,
        'fee_child_age_max': 4,
      });
      expect(p.valid, isFalse);
      expect(p.shareForAge(3), 0);
      expect(p.shareForAge(10), 1);
    });

    test('못 읽는 값은 기본값으로 돌아간다', () {
      final p = ChildFeePolicy.of({
        'fee_child_age_min': 'abc',
        'fee_child_rate': 'x',
      });
      expect(p.minAge, 4);
      expect(p.rate, 0.5);
    });

    test('inUse 는 안내 문구를 띄울지 가른다', () {
      expect(ChildFeePolicy.fallback.inUse, isTrue);
      // 전액이면 어른과 같아 "절반" 같은 말이 뜻을 잃는다.
      expect(ChildFeePolicy.of({'fee_child_rate': 1}).inUse, isFalse);
      expect(ChildFeePolicy.of({'fee_child_rate': 0}).inUse, isFalse);
    });
  });

  group('동반자 한 사람의 몫', () {
    const p = ChildFeePolicy.fallback;

    test('따로 등록하면 0 — 자기 등록에서 낸다', () {
      expect(p.shareForCompanion({'registersSeparately': true, 'age': 6}), 0);
      // 칸이 아예 없는 옛 줄도 "따로 등록" 으로 본다(069).
      expect(p.shareForCompanion({'age': 6}), 0);
    });

    test('사람별로 적어 둔 몫이 나이보다 먼저다', () {
      expect(p.shareForCompanion(kid(30, feeShare: 0.5)), 0.5);
      // 0 도 뜻이 있다 — "이 아이는 안 받기로 정했다".
      expect(p.shareForCompanion(kid(8, feeShare: 0)), 0);
      // 범위 밖은 무시하고 나이로 돌아간다.
      expect(p.shareForCompanion(kid(8, feeShare: 5)), 0.5);
    });

    test('서버가 준 snake_case 도 읽는다', () {
      expect(
        p.shareForCompanion({'registers_separately': false, 'age': 6}),
        0.5,
      );
    });
  });

  group('합계', () {
    const p = ChildFeePolicy.fallback;

    test('아기는 0, 어린이는 절반, 열 살은 전액', () {
      expect(p.totalFor([kid(1), kid(7), kid(10)], 80), 120);
    });

    test('등급을 안 골랐으면 0 이다', () {
      // 0 으로 두고 화면이 "등급을 고르면 더해집니다" 라고 말한다.
      expect(p.totalFor([kid(6)], 0), 0);
    });

    test('빈 목록은 0', () {
      expect(p.totalFor([], 80), 0);
    });

    test('반올림은 센트까지', () {
      final third = ChildFeePolicy.of({'fee_child_rate': 1 / 3});
      expect(third.totalFor([kid(6)], 100), 33.33);
    });
  });
}
