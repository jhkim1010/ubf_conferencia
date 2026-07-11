import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// 참가자 데이터 내보내기 서비스
class ExportService {
  // CSV 내보내기
  static Future<void> exportToCsv(
    List<Map<String, dynamic>> registrations,
    String programName,
  ) async {
    final headers = [
      '번호', '본명', '성경이름', '국가', '지부', '성별', '나이',
      '도착 항공편', '도착일시', '도착 공항',
      '출발 항공편', '출발일시', '출발 공항',
      '음식 특별 사항', '선택 옵션', '룸메이트 희망',
      '총 비용', '입금 상태', '등록 완료',
    ];

    final rows = <List<dynamic>>[headers];

    for (var i = 0; i < registrations.length; i++) {
      final r = registrations[i];
      final arrival = r['arrival_flight'] as Map<String, dynamic>?;
      final departure = r['departure_flight'] as Map<String, dynamic>?;

      rows.add([
        i + 1,
        r['real_name'] ?? '',
        r['bible_name'] ?? '',
        r['country'] ?? '',
        r['branch'] ?? '',
        r['gender'] == 'M' ? '남' : (r['gender'] == 'F' ? '여' : ''),
        r['age'] ?? '',
        arrival?['flight_no'] ?? '',
        arrival?['scheduled_arrival'] ?? '',
        arrival?['arrival_airport'] ?? '',
        departure?['flight_no'] ?? '',
        departure?['scheduled_departure'] ?? '',
        departure?['departure_airport'] ?? '',
        r['food_requirements'] ?? '',
        '', // 옵션명은 별도 조인 필요
        r['roommate_preference'] ?? '',
        r['total_cost'] ?? 0,
        r['payment_status'] ?? '미등록',
        r['submitted'] == true ? '완료' : '미완료',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${programName}_참가자명단.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '$programName 참가자 명단',
    );
  }

  // Excel 내보내기
  static Future<void> exportToExcel(
    List<Map<String, dynamic>> registrations,
    String programName,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['참가자 명단'];

    // 헤더 스타일
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    // 헤더 작성
    final headers = [
      '번호', '본명', '성경이름', '국가', '지부', '성별', '나이',
      '도착 항공편', '도착일시', '도착 공항',
      '출발 항공편', '출발일시', '출발 공항',
      '음식 특별 사항', '룸메이트 희망',
      '총 비용', '입금 상태', '등록 완료',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 데이터 작성
    for (var rowIdx = 0; rowIdx < registrations.length; rowIdx++) {
      final r = registrations[rowIdx];
      final arrival = r['arrival_flight'] as Map<String, dynamic>?;
      final departure = r['departure_flight'] as Map<String, dynamic>?;

      final rowData = [
        rowIdx + 1,
        r['real_name'] ?? '',
        r['bible_name'] ?? '',
        r['country'] ?? '',
        r['branch'] ?? '',
        r['gender'] == 'M' ? '남' : (r['gender'] == 'F' ? '여' : ''),
        r['age'] ?? '',
        arrival?['flight_no'] ?? '',
        arrival?['scheduled_arrival'] ?? '',
        arrival?['arrival_airport'] ?? '',
        departure?['flight_no'] ?? '',
        departure?['scheduled_departure'] ?? '',
        departure?['departure_airport'] ?? '',
        r['food_requirements'] ?? '',
        r['roommate_preference'] ?? '',
        r['total_cost'] ?? 0,
        r['payment_status'] ?? '미등록',
        r['submitted'] == true ? '완료' : '미완료',
      ];

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

    // 컬럼 너비 자동 조정
    sheet.setColumnWidth(1, 15); // 본명
    sheet.setColumnWidth(2, 15); // 성경이름

    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${programName}_참가자명단.xlsx');
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '$programName 참가자 명단',
    );
  }
}
