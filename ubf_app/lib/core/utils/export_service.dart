import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../constants/world_countries.dart';
import 'money.dart';

// 참가자 데이터 내보내기 서비스
// 헤더·값은 관리자(호출자)의 현재 언어로 출력된다.
class ExportService {
  // 공통 헤더 (현재 언어)
  static List<String> _headers(
    AppLocalizations l10n, {
    required bool withOptions,
  }) => [
    l10n.expColNo,
    l10n.summaryRealName,
    l10n.summaryBibleName,
    l10n.summaryCountry,
    l10n.summaryBranch,
    l10n.regGender,
    l10n.summaryAge,
    l10n.expArrFlight,
    l10n.expArrTime,
    l10n.summaryArrAirport,
    l10n.expDepFlight,
    l10n.expDepTime,
    l10n.summaryDepAirport,
    l10n.summarySectionFood,
    if (withOptions) l10n.expOptions,
    l10n.summarySectionRoommate,
    l10n.expTotalCost,
    // 금액 옆에 통화를 따로 둔다. 숫자에 기호를 붙이면 엑셀에서 문자열이 되어
    // 합계를 낼 수 없고, 통화를 아예 빼면 수양회마다 단위가 달라 뜻이 없어진다.
    l10n.cpCurrency,
    l10n.expPaymentStatus,
    l10n.expSubmittedCol,
  ];

  // 항공편 번호 칸. 예매 전이면 그 사실을 적는다 — 빈 칸으로 두면 담당자가
  // "아직 안 적은 사람"과 "아직 안 산 사람"을 구별할 수 없다.
  static String _flightNo(
    AppLocalizations l10n,
    Object? confirmed,
    Map<String, dynamic>? f,
  ) {
    if (confirmed == true) return f?['flight_no'] as String? ?? '';
    if (f?['estimated'] == true) return l10n.expFlightEstimated;
    return f?['flight_no'] as String? ?? '';
  }

  // 한 참가자의 값 목록 (현재 언어)
  static List<dynamic> _row(
    AppLocalizations l10n,
    int index,
    Map<String, dynamic> r, {
    required bool withOptions,
    required Currency currency,
  }) {
    final arrival = r['arrival_flight'] as Map<String, dynamic>?;
    final departure = r['departure_flight'] as Map<String, dynamic>?;
    final gender = r['gender'] == 'M'
        ? l10n.genderMale
        : (r['gender'] == 'F' ? l10n.genderFemale : '');
    return [
      index + 1,
      r['real_name'] ?? '',
      r['bible_name'] ?? '',
      WorldCountries.display(r['country'] as String?) ?? '',
      r['branch'] ?? '',
      gender,
      r['age'] ?? '',
      _flightNo(l10n, r['arrival_confirmed'], arrival),
      arrival?['scheduled_arrival'] ?? '',
      arrival?['arrival_airport'] ?? '',
      _flightNo(l10n, r['departure_confirmed'], departure),
      departure?['scheduled_departure'] ?? '',
      departure?['departure_airport'] ?? '',
      r['food_requirements'] ?? '',
      if (withOptions) '', // 옵션명은 별도 조인 필요
      r['roommate_preference'] ?? '',
      Money.parse(r['total_cost']) ?? 0,
      currency.code,
      r['payment_status'] ?? l10n.expUnregistered,
      r['submitted'] == true ? l10n.dashStatusDone : l10n.expIncomplete,
    ];
  }

  // CSV 내보내기
  static Future<void> exportToCsv(
    List<Map<String, dynamic>> registrations,
    String programName,
    AppLocalizations l10n, {
    Currency currency = Currency.usd,
  }) async {
    final rows = <List<dynamic>>[_headers(l10n, withOptions: true)];
    for (var i = 0; i < registrations.length; i++) {
      rows.add(
        _row(l10n, i, registrations[i], withOptions: true, currency: currency),
      );
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${programName}_${l10n.expRoster}.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles([
      XFile(file.path),
    ], subject: '$programName ${l10n.expRoster}');
  }

  // Excel 내보내기
  static Future<void> exportToExcel(
    List<Map<String, dynamic>> registrations,
    String programName,
    AppLocalizations l10n, {
    Currency currency = Currency.usd,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[l10n.expRoster];

    // 헤더 스타일
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    // 헤더 작성 (엑셀은 옵션 컬럼 제외)
    final headers = _headers(l10n, withOptions: false);
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 데이터 작성
    for (var rowIdx = 0; rowIdx < registrations.length; rowIdx++) {
      final rowData = _row(
        l10n,
        rowIdx,
        registrations[rowIdx],
        withOptions: false,
        currency: currency,
      );
      for (var colIdx = 0; colIdx < rowData.length; colIdx++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx + 1),
        );
        final value = rowData[colIdx];
        if (value is int) {
          cell.value = IntCellValue(value);
        } else if (value is double) {
          cell.value = DoubleCellValue(value);
        } else {
          cell.value = TextCellValue(value.toString());
        }
      }
    }

    // 컬럼 너비 자동 조정 (본명·성경이름)
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);

    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${programName}_${l10n.expRoster}.xlsx');
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], subject: '$programName ${l10n.expRoster}');
  }
}
