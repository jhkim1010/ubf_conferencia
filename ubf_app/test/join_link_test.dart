// 초대 링크 — UUID 를 주소에 실어 보낸다.
//
// 여기서 틀리면 두 가지로 나타난다. 느슨하면 아무 문자열이나 경로에 붙고,
// 빡빡하면 멀쩡한 링크가 안 먹어 결국 참가자에게 UUID 를 손으로 묻게 된다.

import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/join_link.dart';

const _uuid = '6f0c1a2b-3c4d-4e5f-8a9b-0c1d2e3f4a5b';

void main() {
  group('programIdFromQuery', () {
    test('program / uuid / id / p 어느 이름으로 와도 받는다', () {
      // 안내문을 쓰는 사람마다 다른 이름을 쓴다. 링크가 안 먹는 것보다 낫다.
      for (final key in ['program', 'uuid', 'id', 'p']) {
        expect(programIdFromQuery({key: _uuid}), _uuid, reason: key);
      }
    });

    test('없으면 null', () {
      expect(programIdFromQuery(const {}), isNull);
      expect(programIdFromQuery(const {'other': _uuid}), isNull);
    });

    test('UUID 가 아니면 받지 않는다', () {
      // 검사하지 않으면 `?program=<script>` 가 그대로 경로에 붙는다.
      for (final bad in [
        '<script>alert(1)</script>',
        '../../admin',
        '6f0c1a2b',
        '',
        '   ',
        '6f0c1a2b3c4d4e5f8a9b0c1d2e3f4a5b', // 하이픈 없음
      ]) {
        expect(programIdFromQuery({'program': bad}), isNull, reason: bad);
      }
    });

    test('앞뒤 공백과 대문자를 정리한다', () {
      // 메신저로 붙여넣으면 공백이 따라온다.
      expect(
        programIdFromQuery({'program': '  ${_uuid.toUpperCase()}  '}),
        _uuid,
      );
    });

    test('앞의 이름이 비어 있으면 다음 이름을 본다', () {
      expect(programIdFromQuery({'program': 'x', 'uuid': _uuid}), _uuid);
    });
  });

  group('joinLinkFor', () {
    test('배포 주소에 붙여 만든다', () {
      expect(joinLinkFor(_uuid), '$webBaseUrl/?program=$_uuid');
    });

    test('만든 링크를 다시 읽으면 같은 UUID 가 나온다', () {
      // 만드는 쪽과 읽는 쪽이 어긋나면 링크가 조용히 안 먹는다.
      final q = Uri.parse(joinLinkFor(_uuid)).queryParameters;
      expect(programIdFromQuery(q), _uuid);
    });
  });

  group('PendingJoin', () {
    setUp(PendingJoin.take); // 테스트 사이에 값이 새지 않도록

    test('꺼내면 지워진다', () {
      // 남겨 두면 이후에 홈으로 갈 때마다 등록 화면으로 끌려간다.
      PendingJoin.remember(_uuid);
      expect(PendingJoin.isPending, isTrue);
      expect(PendingJoin.take(), _uuid);
      expect(PendingJoin.isPending, isFalse);
      expect(PendingJoin.take(), isNull);
    });

    test('나중 링크가 앞선 링크를 덮는다', () {
      const other = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
      PendingJoin.remember(_uuid);
      PendingJoin.remember(other);
      expect(PendingJoin.take(), other);
    });
  });
}
