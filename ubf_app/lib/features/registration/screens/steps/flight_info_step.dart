import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/flight_api_service.dart';
import '../../providers/registration_provider.dart';

// 도착/출발 비행기 정보 입력 + AviationStack API 연동
class FlightInfoStep extends ConsumerStatefulWidget {
  final String programId;
  final bool isArrival;
  final bool enabled;

  const FlightInfoStep({
    super.key,
    required this.programId,
    required this.isArrival,
    this.enabled = true,
  });

  @override
  ConsumerState<FlightInfoStep> createState() => _FlightInfoStepState();
}

class _FlightInfoStepState extends ConsumerState<FlightInfoStep> {
  late final TextEditingController _dateLabelController; // 날짜 표시용
  late final TextEditingController _flightNoController;
  late final TextEditingController _airportController;
  late final TextEditingController _timeController; // 항공편 조회 시각 표시용

  DateTime? _selectedDate;
  bool _isSearching = false;
  String? _searchError;
  FlightInfo? _flightInfo;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registrationFormProvider(widget.programId));
    final data = widget.isArrival ? state.arrivalFlight : state.departureFlight;

    // 저장된 날짜 복원
    final savedDateStr = widget.isArrival
        ? (data?['scheduled_arrival'] as String?)
        : (data?['scheduled_departure'] as String?);
    if (savedDateStr != null && savedDateStr.isNotEmpty) {
      _selectedDate = DateTime.tryParse(savedDateStr);
    }

    _dateLabelController = TextEditingController(text: _formatDate(_selectedDate));
    _flightNoController = TextEditingController(text: data?['flight_no'] ?? '');
    _airportController = TextEditingController(
      text: widget.isArrival
          ? (data?['arrival_airport'] ?? '')
          : (data?['departure_airport'] ?? ''),
    );
    _timeController = TextEditingController(
      text: widget.isArrival
          ? (data?['scheduled_arrival'] ?? '')
          : (data?['scheduled_departure'] ?? ''),
    );
  }

  @override
  void dispose() {
    _dateLabelController.dispose();
    _flightNoController.dispose();
    _airportController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    // 출발 스텝이면 도착일 +3일부터 선택 가능
    DateTime firstDate = DateTime(2020);
    DateTime initialDate = _selectedDate ?? DateTime.now();

    if (!widget.isArrival) {
      final arrivalStr = ref
          .read(registrationFormProvider(widget.programId))
          .arrivalFlight?['scheduled_arrival'] as String?;
      if (arrivalStr != null && arrivalStr.isNotEmpty) {
        final arrivalDate = DateTime.tryParse(arrivalStr);
        if (arrivalDate != null) {
          firstDate = arrivalDate.add(const Duration(days: 3));
          // initialDate가 firstDate보다 이전이면 조정
          if (initialDate.isBefore(firstDate)) initialDate = firstDate;
        }
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _dateLabelController.text = _formatDate(picked);
    });
    _saveToProvider();
  }

  // 항공편 번호로 정보 자동 조회
  Future<void> _searchFlight() async {
    final flightNo = _flightNoController.text.trim();
    if (flightNo.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final info = await FlightApiService.fetchFlightInfo(flightNo);

    if (!mounted) return;

    if (info == null) {
      setState(() {
        _searchError = '항공편 정보를 찾을 수 없습니다. 직접 입력해 주세요.';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _flightInfo = info;
      _isSearching = false;

      if (widget.isArrival) {
        _airportController.text = info.arrivalAirport;
        final arrival = info.scheduledArrival?.toLocal();
        if (arrival != null) {
          _selectedDate = arrival;
          _dateLabelController.text = _formatDate(arrival);
          _timeController.text = arrival.toString();
        }
      } else {
        _airportController.text = info.departureAirport;
        final departure = info.scheduledDeparture?.toLocal();
        if (departure != null) {
          _selectedDate = departure;
          _dateLabelController.text = _formatDate(departure);
          _timeController.text = departure.toString();
        }
      }
    });

    _saveToProvider();
  }

  void _saveToProvider() {
    final manualDateStr = _selectedDate?.toIso8601String();
    final flightData = {
      'flight_no': _flightNoController.text.trim(),
      // 항공편 조회 결과가 없으면 airline은 빈 문자열로 유지
      'airline': _flightInfo?.airline ?? '',
      // 공항은 항상 컨트롤러(직접 입력 포함) 값 우선 사용
      'arrival_airport': widget.isArrival
          ? _airportController.text.trim()
          : (_flightInfo?.arrivalAirport ?? ''),
      'departure_airport': widget.isArrival
          ? (_flightInfo?.departureAirport ?? '')
          : _airportController.text.trim(),
      // 날짜: 항공편 조회 결과 우선, 없으면 달력에서 수동 선택한 날짜
      'scheduled_arrival': widget.isArrival
          ? (_flightInfo?.scheduledArrival?.toIso8601String() ?? manualDateStr)
          : (_flightInfo?.scheduledArrival?.toIso8601String()),
      'scheduled_departure': widget.isArrival
          ? (_flightInfo?.scheduledDeparture?.toIso8601String())
          : (_flightInfo?.scheduledDeparture?.toIso8601String() ?? manualDateStr),
      'terminal': _flightInfo?.terminal,
    };

    final notifier = ref.read(registrationFormProvider(widget.programId).notifier);
    if (widget.isArrival) {
      notifier.updateArrivalFlight(flightData);
    } else {
      notifier.updateDepartureFlight(flightData);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const Center(child: Text('이 섹션은 비활성화되어 있습니다'));
    }

    final label = widget.isArrival ? '도착' : '출발';
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '$label 비행기 정보',
          style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        // ── 날짜 선택 (첫 번째 필드) ──────────────────────
        TextField(
          readOnly: true,
          controller: _dateLabelController,
          decoration: InputDecoration(
            labelText: '$label 날짜 *',
            hintText: '날짜를 선택하세요',
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate,
            ),
          ),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        // ── 항공편 번호 + 자동 조회 ───────────────────────
        TextField(
          controller: _flightNoController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: '항공편 번호',
            hintText: '예: KE123, OZ456',
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: '항공편 자동 조회',
                    onPressed: _searchFlight,
                  ),
          ),
          onChanged: (_) => _saveToProvider(),
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Text(
            _searchError!,
            style: TextStyle(color: Colors.orange[700], fontSize: 12),
          ),
        ],
        if (_flightInfo != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_flightInfo!.airline} (${_flightInfo!.flightNo})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_flightInfo!.departureAirport} → ${_flightInfo!.arrivalAirport}',
                  style: const TextStyle(fontSize: 13),
                ),
                if (_flightInfo!.status != null)
                  Text(
                    '상태: ${_flightInfo!.status}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // ── 공항 ─────────────────────────────────────────
        TextField(
          controller: _airportController,
          decoration: InputDecoration(
            labelText: '$label 공항',
            hintText: '항공편 번호 검색 시 자동 입력',
          ),
          onChanged: (_) => _saveToProvider(),
        ),
        const SizedBox(height: 12),
        // ── 예정 시각 (항공편 조회 시 자동 입력) ───────────
        TextField(
          controller: _timeController,
          decoration: InputDecoration(
            labelText: '$label 예정 시각',
            hintText: '항공편 번호 검색 시 자동 입력',
          ),
          onChanged: (_) => _saveToProvider(),
        ),
      ],
    );
  }
}
