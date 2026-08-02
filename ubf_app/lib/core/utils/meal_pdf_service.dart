import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../l10n/app_localizations.dart';
import '../constants/world_countries.dart';
import 'file_download.dart';

// 식사 제한 명단 PDF — 주방·구매 담당에게 그대로 넘길 수 있는 한 장짜리 문서.
//
// 화면에서 사람마다 따로 보면 장을 볼 수 없다. "누가 무엇을 못 먹는지"를
// 한 문서로 합쳐 인쇄하거나 보내라는 것이 이 기능의 요구다.
class MealPdfService {
  // pdf 패키지의 기본 글꼴(Helvetica)에는 한글이 없다. 그대로 두면 이름이
  // 전부 두부(□)로 나오는데, PDF 는 열어 보기 전에는 그 사실이 드러나지
  // 않는다 — 주방에 넘긴 뒤에야 알게 된다. 그래서 폰트를 번들에 넣는다.
  //
  // 한 번 읽어 두고 재사용한다. 2.4MB 를 매번 파싱할 이유가 없다.
  static pw.Font? _font;

  static Future<pw.Font> _loadFont() async {
    final cached = _font;
    if (cached != null) return cached;
    final data = await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
    return _font = pw.Font.ttf(data);
  }

  static String _ymd(Object? raw) {
    final s = raw?.toString() ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  // 파일명에 쓸 수 없는 글자를 걷어낸다. 수양회 이름에 '/' 나 ':' 가 들어가면
  // 저장이 통째로 실패한다.
  static String _safeName(String s) =>
      s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

  // 문서 생성과 저장을 나눠 둔다. 저장은 플랫폼마다 다르고 테스트에서 부를 수
  // 없지만, "한글이 두부로 나오지 않는가"는 바이트만 있으면 확인할 수 있다.
  static Future<Uint8List> build({
    required Map<String, dynamic> data,
    required AppLocalizations l10n,
  }) async {
    final font = await _loadFont();
    final program = (data['program'] as Map<String, dynamic>?) ?? const {};
    final people = (data['people'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final programName = (program['name'] as String?) ?? '';
    final total = (data['total'] as int?) ?? 0;

    final theme = pw.ThemeData.withFont(base: font, bold: font);
    final doc = pw.Document(theme: theme);

    final period = [
      _ymd(program['start_date']),
      _ymd(program['end_date']),
    ].where((s) => s.isNotEmpty).join(' ~ ');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  '$programName · ${l10n.mealsTitle}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            l10n.mealsTitle,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            [
              programName,
              if (program['location'] != null) program['location'] as String,
              if (period.isNotEmpty) period,
            ].join(' · '),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            child: pw.Text(
              l10n.mealsPdfSummary(people.length, total),
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 12),
          if (people.isEmpty)
            pw.Text(
              l10n.mealsEmpty,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: const {
                // 한국어에서 이 칸 머리글은 "번호" 다. 24pt 면 두 줄로 접힌다.
                0: pw.FixedColumnWidth(34),
                1: pw.FlexColumnWidth(2.0),
                2: pw.FlexColumnWidth(1.4),
                3: pw.FlexColumnWidth(1.4),
                4: pw.FlexColumnWidth(4.2),
              },
              headers: [
                l10n.expColNo,
                l10n.summaryRealName,
                l10n.summaryCountry,
                l10n.summaryBranch,
                l10n.mealsRestriction,
              ],
              data: [
                for (var i = 0; i < people.length; i++)
                  [
                    '${i + 1}',
                    [
                      people[i]['real_name'] ?? '',
                      if ((people[i]['bible_name'] as String?)?.isNotEmpty ??
                          false)
                        '(${people[i]['bible_name']})',
                    ].join(' '),
                    WorldCountries.display(people[i]['country'] as String?) ??
                        '',
                    people[i]['branch'] ?? '',
                    // 아침을 거르는 사람은 식수 계산이 달라진다. 같은 칸에
                    // 붙여 두어야 주방이 한 줄만 보고 준비할 수 있다.
                    [
                      people[i]['food_requirements'] ?? '',
                      if (people[i]['skips_breakfast'] == true)
                        '[${l10n.mealsSkipsBreakfast}]',
                    ].where((s) => '$s'.isNotEmpty).join('  '),
                  ],
              ],
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 4,
              ),
            ),
          pw.SizedBox(height: 14),
          pw.Text(
            l10n.mealsPdfNote,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> export({
    required Map<String, dynamic> data,
    required AppLocalizations l10n,
  }) async {
    final bytes = await build(data: data, l10n: l10n);
    final programName =
        ((data['program'] as Map<String, dynamic>?)?['name'] as String?) ?? '';
    final name = _safeName('${programName}_${l10n.mealsTitle}');
    await saveBytes(
      bytes,
      '$name.pdf',
      subject: '$programName ${l10n.mealsTitle}',
    );
  }
}
