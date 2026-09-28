/// 어린이 참가비 — 나이로 정하는 몫 (073)
///
/// 서버의 `services/companion_role.js` 와 **같은 규칙**이다. 값을 내는 곳이
/// 둘이면 언젠가 갈라지고, 갈라지면 등록 화면이 말한 금액과 명단에 남는
/// 금액이 달라진다. 규칙을 고칠 때는 양쪽을 함께 고쳐야 한다.
///
/// 세 구간이다. 경계는 **포함**한다 — "4살부터 8살까지" 라고 말했을 때
/// 여덟 살이 빠지면 아무도 그렇게 읽지 않는다.
///
///   나이 < minAge          0    안 받는다
///   minAge ≤ 나이 ≤ maxAge  rate 어린이 몫 (0.5 = 절반)
///   나이 > maxAge           1    어른과 같다
///
/// DB 도 HTTP 도 쓰지 않는다. test/child_fee_test.dart 로 그대로 확인한다.
library;

class ChildFeePolicy {
  const ChildFeePolicy({
    required this.minAge,
    required this.maxAge,
    required this.rate,
  });

  /// 수양회가 정해 둔 구간. 칸이 비어 있으면 기본값(4~8살 절반)이다.
  factory ChildFeePolicy.of(Map<String, dynamic>? program) {
    int asAge(Object? v, int fallback) {
      if (v == null) return fallback;
      final n = num.tryParse(v.toString());
      if (n == null || n < 0 || n >= 150) return fallback;
      return n.truncate();
    }

    double asRate(Object? v, double fallback) {
      if (v == null) return fallback;
      final n = num.tryParse(v.toString());
      if (n == null) return fallback;
      return n.clamp(0, 1).toDouble();
    }

    return ChildFeePolicy(
      minAge: asAge(program?['fee_child_age_min'], 4),
      maxAge: asAge(program?['fee_child_age_max'], 8),
      rate: asRate(program?['fee_child_rate'], 0.5),
    );
  }

  static const ChildFeePolicy fallback = ChildFeePolicy(
    minAge: 4,
    maxAge: 8,
    rate: 0.5,
  );

  final int minAge;
  final int maxAge;

  /// 어린이가 내는 몫. 0.5 면 절반이다.
  final double rate;

  /// 거꾸로 적힌 구간은 구간이 없는 것으로 본다. 서버의 CHECK 가 막지만
  /// 그 칸을 안 거치고 들어온 값에도 무너지지 않아야 한다.
  bool get valid => minAge <= maxAge;

  /// 어린이 요금을 실제로 쓰는가. 비율이 1 이면 어른과 같아 쓸 것이 없고,
  /// 0 이면 구간 안이 무료라는 뜻이라 "절반" 같은 안내가 뜻을 잃는다.
  bool get inUse => valid && rate > 0 && rate < 1;

  /// 이 나이가 내는 몫.
  ///
  /// 나이를 모르면 **받지 않는다**(null). 잘못 받는 쪽이 덜 받는 쪽보다
  /// 나쁘다 — 서버도 같은 판단이다.
  double shareForAge(int? age) {
    if (age == null || age < 0) return 0;
    if (!valid) return age < minAge ? 0 : 1;
    if (age < minAge) return 0;
    if (age <= maxAge) return rate;
    return 1;
  }

  /// 동반자 한 사람이 내는 몫. 사람별로 적어 둔 값이 나이보다 먼저다(069 의
  /// 침대와 같은 규칙 — 사정이 다른 집이 고칠 수 있어야 한다).
  ///
  /// [registersSeparately] 가 참이면 0 이다. 그 사람은 자기 등록에서 낸다.
  double shareForCompanion(Map<String, dynamic> c) {
    if (c['registersSeparately'] != false &&
        c['registers_separately'] != false) {
      return 0;
    }
    final own = c['feeShare'] ?? c['fee_share'];
    if (own != null && own.toString().isNotEmpty) {
      final n = num.tryParse(own.toString());
      if (n != null && n >= 0 && n <= 1) return n.toDouble();
    }
    final age = num.tryParse('${c['age'] ?? ''}')?.truncate();
    return shareForAge(age);
  }

  /// 동반자들이 내는 참가비의 합.
  ///
  /// [tierFee] 는 보호자가 고른 등급의 값이다. 어린이는 자기 등급을 고를 수
  /// 없으므로 같은 등급을 따라간다.
  double totalFor(List<Map<String, dynamic>> companions, double tierFee) {
    if (tierFee <= 0) return 0;
    var sum = 0.0;
    for (final c in companions) {
      sum += tierFee * shareForCompanion(c);
    }
    return (sum * 100).roundToDouble() / 100;
  }
}
