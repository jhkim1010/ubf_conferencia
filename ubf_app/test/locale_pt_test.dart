// 포르투갈어(pt) 지원.
//
// 브라질에서도 참석한다. 스페인어로 대신 읽게 두면 안 된다 — 가깝다고 해서
// 읽히는 언어가 아니다.
//
// 여기서 보는 것은 "ARB 파일이 있다"가 아니라 **기기가 포르투갈어면 실제로
// 포르투갈어가 나오는가**다. 로케일이 목록에 없으면 조용히 영어로 떨어지는데,
// 그건 화면을 열어 보기 전에는 드러나지 않는다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana/l10n/app_localizations.dart';

void main() {
  test('지원 언어에 pt 가 들어 있다', () {
    final codes = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toSet();
    expect(codes, containsAll(<String>{'ko', 'en', 'es', 'pt'}));
  });

  test('pt 를 불러오면 포르투갈어가 나온다', () async {
    final pt = await AppLocalizations.delegate.load(const Locale('pt'));
    // 스페인어와 눈에 띄게 다른 문장들. 여기가 스페인어면 번역이 새어 들어온 것이다.
    expect(pt.actionSave, 'Salvar'); // es: Guardar
    expect(pt.actionDelete, 'Excluir'); // es: Eliminar
    expect(pt.commonLoading, 'Carregando…'); // es: Cargando…
    expect(pt.regStepFood, 'Refeições'); // es: Comidas
    expect(pt.mealsDownloadPdf, 'Baixar PDF'); // es: Descargar PDF
  });

  test('pt 가 모든 키를 갖는다 — 빠지면 그 자리만 영어가 된다', () async {
    // 개수는 arb-parity 가 보지만, 실제로 불러왔을 때 비어 있지 않은지는
    // 여기서 본다. 빈 문자열도 "번역됨"으로 세어지기 때문이다.
    final pt = await AppLocalizations.delegate.load(const Locale('pt'));
    for (final s in [
      pt.appTagline,
      pt.authSignInGoogle,
      pt.regTitle,
      pt.summaryTitle,
      pt.dashTitle,
      pt.sosTitle,
      pt.hotelTitle,
      pt.tgSectionTitle,
      pt.privacyTitle,
    ]) {
      expect(s.trim(), isNotEmpty);
    }
  });

  test('브라질 기기(pt_BR)도 포르투갈어로 붙는다', () {
    // 앱은 언어 코드로만 맞춘다(app.dart 의 localeResolutionCallback).
    // 지역까지 맞추려 들면 pt_BR 이 목록에 없어 영어로 떨어진다.
    const device = Locale('pt', 'BR');
    final match = AppLocalizations.supportedLocales.where(
      (l) => l.languageCode == device.languageCode,
    );
    expect(match, isNotEmpty);
  });
}
