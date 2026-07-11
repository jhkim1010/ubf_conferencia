import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

// 항공편 정보 모델
class FlightInfo {
  final String flightNo;
  final String airline;
  final String departureAirport;
  final String arrivalAirport;
  final DateTime? scheduledDeparture;
  final DateTime? scheduledArrival;
  final String? terminal;
  final String? status;

  const FlightInfo({
    required this.flightNo,
    required this.airline,
    required this.departureAirport,
    required this.arrivalAirport,
    this.scheduledDeparture,
    this.scheduledArrival,
    this.terminal,
    this.status,
  });

  Map<String, dynamic> toJson() => {
    'flight_no': flightNo,
    'airline': airline,
    'departure_airport': departureAirport,
    'arrival_airport': arrivalAirport,
    'scheduled_departure': scheduledDeparture?.toIso8601String(),
    'scheduled_arrival': scheduledArrival?.toIso8601String(),
    'terminal': terminal,
    'status': status,
  };

  factory FlightInfo.fromJson(Map<String, dynamic> json) => FlightInfo(
    flightNo: json['flight_no'] ?? '',
    airline: json['airline'] ?? '',
    departureAirport: json['departure_airport'] ?? '',
    arrivalAirport: json['arrival_airport'] ?? '',
    scheduledDeparture: json['scheduled_departure'] != null
        ? DateTime.tryParse(json['scheduled_departure'])
        : null,
    scheduledArrival: json['scheduled_arrival'] != null
        ? DateTime.tryParse(json['scheduled_arrival'])
        : null,
    terminal: json['terminal'],
    status: json['status'],
  );
}

// AviationStack API 연동 서비스
class FlightApiService {
  static Future<FlightInfo?> fetchFlightInfo(String flightIata) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.aviationStackBaseUrl}/flights'
        '?access_key=${AppConstants.aviationStackApiKey}'
        '&flight_iata=${flightIata.toUpperCase()}'
        '&limit=1',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final flights = data['data'] as List?;

      if (flights == null || flights.isEmpty) return null;

      final flight = flights.first;
      return FlightInfo(
        flightNo: flight['flight']?['iata'] ?? flightIata,
        airline: flight['airline']?['name'] ?? '',
        departureAirport: flight['departure']?['airport'] ?? '',
        arrivalAirport: flight['arrival']?['airport'] ?? '',
        scheduledDeparture: DateTime.tryParse(
          flight['departure']?['scheduled'] ?? '',
        ),
        scheduledArrival: DateTime.tryParse(
          flight['arrival']?['scheduled'] ?? '',
        ),
        terminal: flight['arrival']?['terminal'],
        status: flight['flight_status'],
      );
    } catch (e) {
      return null;
    }
  }
}
