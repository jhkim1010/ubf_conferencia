import 'package:flutter_test/flutter_test.dart';
import 'package:mana/core/utils/venue_link.dart';

// 장소 홈페이지 (065)
//
// 담당자가 손으로 적는 칸이라 무엇이든 들어온다. 열 수 있는 것만 열고,
// 나머지는 링크로 만들지 않는다는 계약을 여기서 고정한다.

void main() {
  group('여는 것', () {
    test('https 주소', () {
      final v = VenueLink.parse('https://www.hotelpilar.com.ar');
      expect(v, isNotNull);
      expect(v!.uri.toString(), 'https://www.hotelpilar.com.ar');
    });

    test('http 도 연다', () {
      expect(VenueLink.parse('http://hotelpilar.com.ar'), isNotNull);
    });

    test('갈래의 대소문자는 가리지 않는다', () {
      expect(VenueLink.parse('HTTPS://hotelpilar.com.ar'), isNotNull);
    });

    test('앞뒤 공백은 턴다 — 붙여넣기에 흔히 남는다', () {
      final v = VenueLink.parse('  https://hotelpilar.com.ar/salones  ');
      expect(v, isNotNull);
      expect(v!.host, 'hotelpilar.com.ar');
    });

    test('경로와 물음표가 붙어 있어도 그대로 연다', () {
      final v = VenueLink.parse(
        'https://maps.google.com/?q=Pilar+Buenos+Aires',
      );
      expect(v, isNotNull);
      expect(v!.host, 'maps.google.com');
    });
  });

  group('안 여는 것', () {
    test('비어 있으면 링크가 아니다', () {
      expect(VenueLink.parse(null), isNull);
      expect(VenueLink.parse(''), isNull);
      expect(VenueLink.parse('   '), isNull);
    });

    test('갈래가 없으면 안 연다', () {
      // 담당자가 "hotelpilar.com.ar" 만 적는 일이 흔하다. 여기서 https 를
      // 붙여 주고 싶지만, 그러면 우리가 주소를 지어내는 것이 된다.
      expect(VenueLink.parse('hotelpilar.com.ar'), isNull);
      expect(VenueLink.parse('www.hotelpilar.com.ar'), isNull);
    });

    test('http 아닌 갈래는 안 연다', () {
      // 여기가 핵심이다. 링크 자리에 아무 문자열이나 넣을 수 있으면
      // 눌렀을 때 무슨 일이 나는지 보증할 수 없다.
      expect(VenueLink.parse('javascript:alert(1)'), isNull);
      expect(VenueLink.parse('file:///etc/passwd'), isNull);
      expect(VenueLink.parse('tel:+5491112345678'), isNull);
      expect(VenueLink.parse('mailto:a@b.com'), isNull);
    });

    test('호스트가 없으면 열어도 갈 데가 없다', () {
      expect(VenueLink.parse('https://'), isNull);
    });

    test('그냥 문장을 적어 두었으면 안 연다', () {
      expect(VenueLink.parse('호텔 홈페이지 찾아보세요'), isNull);
    });
  });

  group('보여줄 도메인', () {
    test('www 는 뗀다 — 자리만 먹는다', () {
      expect(
        VenueLink.parse('https://www.hotelpilar.com.ar')!.host,
        'hotelpilar.com.ar',
      );
    });

    test('www 가 아닌 앞자리는 남긴다', () {
      expect(
        VenueLink.parse('https://maps.hotelpilar.com.ar')!.host,
        'maps.hotelpilar.com.ar',
      );
    });

    test('긴 경로는 안 보여준다 — 장소 이름을 가린다', () {
      expect(
        VenueLink.parse(
          'https://hotelpilar.com.ar/es/salones/convenciones/2027',
        )!.host,
        'hotelpilar.com.ar',
      );
    });
  });
}
