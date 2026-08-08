import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'file_download.dart';

// 표 하나를 PDF·엑셀로 내보낸다.
//
// 대시보드의 카드마다 다른 표가 나오지만 내보내는 방식은 같다. 화면마다
// 따로 만들면 글꼴·여백·머리글 처리가 조금씩 달라지고, 그러다 한 화면만
// 한글이 깨진다.
class TableExport {
  /// pdf 패키지의 기본 글꼴에는 한글이 없다. 그대로 두면 이름이 전부
  /// 두부(□)로 나오는데, PDF 는 열어 보기 전에는 그 사실이 드러나지 않는다.
  static pw.Font? _font;

  static Future<pw.Font> _loadFont() async {
    final cached = _font;
    if (cached != null) return cached;
    final data = await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
    return _font = pw.Font.ttf(data);
  }

  /// 파일명에 쓸 수 없는 글자를 걷어낸다. 수양회 이름에 '/' 나 ':' 가
  /// 들어가면 저장이 통째로 실패한다.
  static String safeName(String s) =>
      s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

  static Future<Uint8List> buildPdf({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    List<double>? columnFlex,
  }) async {
    final font = await _loadFont();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 36),
        header: (c) => c.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  title,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
        footer: (c) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${c.pageNumber} / ${c.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (c) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
          ),
          if (subtitle.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text('—', style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: columnFlex == null
                  ? null
                  : {
                      for (var i = 0; i < columnFlex.length; i++)
                        i: pw.FlexColumnWidth(columnFlex[i]),
                    },
              headers: headers,
              data: rows,
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3.5,
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> sharePdf({
    required String fileBase,
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    List<double>? columnFlex,
  }) async {
    final bytes = await buildPdf(
      title: title,
      subtitle: subtitle,
      headers: headers,
      rows: rows,
      columnFlex: columnFlex,
    );
    await saveBytes(bytes, '${safeName(fileBase)}.pdf', subject: title);
  }

  static Future<void> shareExcel({
    required String fileBase,
    required String sheetName,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final excel = Excel.createExcel();
    // 시트 이름에는 쓸 수 없는 글자가 있고 길이 제한도 있다. 넘기면
    // 파일이 열리지 않는다.
    final name = safeName(sheetName);
    final sheet = excel[name.length > 28 ? name.substring(0, 28) : name];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#455A64'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final v = rows[r][c];
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
        );
        // 숫자로 보이는 값은 숫자로 넣는다. 문자열로 넣으면 엑셀에서
        // 합계를 낼 수 없다.
        final n = num.tryParse(v);
        cell.value = n == null
            ? TextCellValue(v)
            : (n is int ? IntCellValue(n) : DoubleCellValue(n.toDouble()));
      }
    }
    // 이름 칸은 좁으면 읽을 수 없다.
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, i == 0 ? 6 : 18);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    await saveBytes(
      Uint8List.fromList(bytes),
      '${safeName(fileBase)}.xlsx',
      subject: sheetName,
    );
  }
}
