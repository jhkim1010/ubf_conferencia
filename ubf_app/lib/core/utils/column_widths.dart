import 'dart:convert';

/// 표 칸의 폭 — 담당자가 머리글 끝을 끌어 바꾼 값.
///
/// 칸마다 기본 폭이 있고, 바꾼 칸만 따로 기억한다. 기본값을 통째로
/// 저장해 두면 나중에 코드에서 기본 폭을 고쳐도 그 사람 화면에는 옛 폭이
/// 남는다.
///
/// 칸은 번호가 아니라 **이름(id)** 으로 가리킨다. 칸을 넣고 빼면 번호가
/// 밀린다 — 정렬 값을 번호로 골랐다가 실제로 칸이 하나씩 어긋난 적이 있다.
class ColumnWidths {
  /// 너무 좁으면 끌 손잡이마저 잡을 수 없다. 너무 넓으면 한 칸이 화면을
  /// 다 먹는다.
  static const double min = 48;
  static const double max = 640;

  final Map<String, double> _custom;

  ColumnWidths([Map<String, double>? custom]) : _custom = {...?custom};

  double of(String id, double fallback) => _custom[id] ?? fallback;

  bool isCustom(String id) => _custom.containsKey(id);

  /// [delta] 만큼 넓히거나 줄인다. 범위 밖으로는 안 간다.
  void resize(String id, double fallback, double delta) {
    _custom[id] = (of(id, fallback) + delta).clamp(min, max).toDouble();
  }

  /// 기본 폭으로 되돌린다.
  void reset(String id) => _custom.remove(id);

  String encode() => jsonEncode(_custom);

  /// 저장된 값이 깨져 있어도 화면은 떠야 한다 — 그때는 기본 폭으로 간다.
  static ColumnWidths decode(String? raw) {
    if (raw == null || raw.isEmpty) return ColumnWidths();
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return ColumnWidths();
      return ColumnWidths({
        for (final e in m.entries)
          if (e.value is num)
            '${e.key}': (e.value as num).toDouble().clamp(min, max).toDouble(),
      });
    } catch (_) {
      return ColumnWidths();
    }
  }
}
