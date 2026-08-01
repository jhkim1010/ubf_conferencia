import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/api_client.dart';

// 내 등록 정보 조회
final registrationProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
      (_, programId) => ApiClient.getMyRegistration(programId),
    );

// ─── 등록 폼 상태 ────────────────────────────────────────────

class RegistrationFormState {
  final String programId;
  final String? country;
  final String? branch;
  final String? realName;
  final String? bibleName;
  final String? gender;
  final int? age;
  final Map<String, dynamic>? arrivalFlight;
  final Map<String, dynamic>? departureFlight;
  final String? foodRequirements; // 섭취 불가능한 음식 / 식이 제한
  final String? medicalConditions; // 질병 유무
  final bool skipsBreakfast; // 아침 식사 주로 안 함
  final List<String> selectedOptions;
  final String? roommatePreference;
  final List<String> volunteerResources;
  final String? volunteerNote;
  final String? feeTier; // 'basic' | 'premium' | null(미선택)
  final bool discountRequested; // 할인 신청 여부
  final String? discountOptionKey; // programs.discount_options[].key
  final String? discountReason; // 보충 설명(선택)

  const RegistrationFormState({
    required this.programId,
    this.country,
    this.branch,
    this.realName,
    this.bibleName,
    this.gender,
    this.age,
    this.arrivalFlight,
    this.departureFlight,
    this.foodRequirements,
    this.medicalConditions,
    this.skipsBreakfast = false,
    this.selectedOptions = const [],
    this.roommatePreference,
    this.volunteerResources = const [],
    this.volunteerNote,
    this.feeTier,
    this.discountRequested = false,
    this.discountOptionKey,
    this.discountReason,
  });

  RegistrationFormState copyWith({
    String? country,
    String? branch,
    String? realName,
    String? bibleName,
    String? gender,
    int? age,
    Map<String, dynamic>? arrivalFlight,
    Map<String, dynamic>? departureFlight,
    String? foodRequirements,
    String? medicalConditions,
    bool? skipsBreakfast,
    List<String>? selectedOptions,
    String? roommatePreference,
    List<String>? volunteerResources,
    String? volunteerNote,
    String? feeTier,
    bool? discountRequested,
    String? discountOptionKey,
    String? discountReason,
    // copyWith 는 `??` 로 병합하므로 null 을 넘겨 값을 지울 수 없다.
    // 할인 신청 철회는 "지우는" 동작이라 별도 플래그가 필요하다.
    bool clearDiscount = false,
  }) {
    return RegistrationFormState(
      programId: programId,
      country: country ?? this.country,
      branch: branch ?? this.branch,
      realName: realName ?? this.realName,
      bibleName: bibleName ?? this.bibleName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      arrivalFlight: arrivalFlight ?? this.arrivalFlight,
      departureFlight: departureFlight ?? this.departureFlight,
      foodRequirements: foodRequirements ?? this.foodRequirements,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      skipsBreakfast: skipsBreakfast ?? this.skipsBreakfast,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      roommatePreference: roommatePreference ?? this.roommatePreference,
      volunteerResources: volunteerResources ?? this.volunteerResources,
      volunteerNote: volunteerNote ?? this.volunteerNote,
      feeTier: feeTier ?? this.feeTier,
      discountRequested: clearDiscount
          ? false
          : (discountRequested ?? this.discountRequested),
      discountOptionKey: clearDiscount
          ? null
          : (discountOptionKey ?? this.discountOptionKey),
      discountReason: clearDiscount
          ? null
          : (discountReason ?? this.discountReason),
    );
  }

  Map<String, dynamic> toJson() => {
    'programId': programId,
    'country': country,
    'branch': branch,
    'realName': realName,
    'bibleName': bibleName,
    'gender': gender,
    'age': age,
    'arrivalFlight': arrivalFlight,
    'departureFlight': departureFlight,
    'foodRequirements': foodRequirements,
    'medicalConditions': medicalConditions,
    'skipsBreakfast': skipsBreakfast,
    'selectedOptions': selectedOptions,
    'roommatePreference': roommatePreference,
    'volunteerResources': volunteerResources,
    'volunteerNote': volunteerNote,
    'feeTier': feeTier,
    'discountRequested': discountRequested,
    'discountOptionKey': discountOptionKey,
    'discountReason': discountReason,
  };

  factory RegistrationFormState.fromJson(Map<String, dynamic> json) =>
      RegistrationFormState(
        programId: json['programId'] as String,
        country: json['country'] as String?,
        branch: json['branch'] as String?,
        realName: json['realName'] as String?,
        bibleName: json['bibleName'] as String?,
        gender: json['gender'] as String?,
        age: json['age'] as int?,
        arrivalFlight: json['arrivalFlight'] as Map<String, dynamic>?,
        departureFlight: json['departureFlight'] as Map<String, dynamic>?,
        foodRequirements: json['foodRequirements'] as String?,
        medicalConditions: json['medicalConditions'] as String?,
        skipsBreakfast: json['skipsBreakfast'] as bool? ?? false,
        selectedOptions: List<String>.from(json['selectedOptions'] ?? []),
        roommatePreference: json['roommatePreference'] as String?,
        volunteerResources: List<String>.from(json['volunteerResources'] ?? []),
        volunteerNote: json['volunteerNote'] as String?,
        feeTier: json['feeTier'] as String?,
        discountRequested: json['discountRequested'] as bool? ?? false,
        discountOptionKey: json['discountOptionKey'] as String?,
        discountReason: json['discountReason'] as String?,
      );
}

// ─── Notifier ────────────────────────────────────────────────

class RegistrationFormNotifier extends StateNotifier<RegistrationFormState> {
  RegistrationFormNotifier(String programId)
    : super(RegistrationFormState(programId: programId));

  static String _draftKey(String programId) => 'ubf_draft_$programId';

  // 상태 변경 + 즉시 로컬 저장
  void _update(RegistrationFormState newState) {
    state = newState;
    _persistDraft();
  }

  Future<void> _persistDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftKey(state.programId),
      jsonEncode(state.toJson()),
    );
  }

  // 앱 재시작 시 로컬 draft 복원 (없으면 null 반환)
  static Future<RegistrationFormState?> loadDraft(String programId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey(programId));
    if (raw == null) return null;
    try {
      return RegistrationFormState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  // 제출 완료 후 draft 삭제
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(state.programId));
  }

  // ─── 각 스텝 업데이트 ──────────────────────────────────────

  void updatePersonalInfo({
    String? country,
    String? branch,
    String? realName,
    String? bibleName,
    String? gender,
    int? age,
  }) {
    _update(
      state.copyWith(
        country: country,
        branch: branch,
        realName: realName,
        bibleName: bibleName,
        gender: gender,
        age: age,
      ),
    );
  }

  void updateArrivalFlight(Map<String, dynamic> flight) =>
      _update(state.copyWith(arrivalFlight: flight));

  void updateDepartureFlight(Map<String, dynamic> flight) =>
      _update(state.copyWith(departureFlight: flight));

  void updateFood({
    String? foodRequirements,
    String? medicalConditions,
    bool? skipsBreakfast,
  }) => _update(
    state.copyWith(
      foodRequirements: foodRequirements,
      medicalConditions: medicalConditions,
      skipsBreakfast: skipsBreakfast,
    ),
  );

  void toggleOption(String optionId) {
    final current = List<String>.from(state.selectedOptions);
    if (current.contains(optionId)) {
      current.remove(optionId);
    } else {
      current.add(optionId);
    }
    _update(state.copyWith(selectedOptions: current));
  }

  void updateRoommate(String preference) =>
      _update(state.copyWith(roommatePreference: preference));

  void toggleVolunteerResource(String key) {
    final current = List<String>.from(state.volunteerResources);
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    _update(state.copyWith(volunteerResources: current));
  }

  void updateVolunteerNote(String note) =>
      _update(state.copyWith(volunteerNote: note));

  // ─── 참가비 등급 / 할인 신청 ────────────────────────────────

  void selectFeeTier(String tier) => _update(state.copyWith(feeTier: tier));

  // 할인 항목을 고르면 신청한 것으로 본다. 별도의 "신청" 스위치를 두면
  // 항목만 고르고 스위치를 켜지 않아 신청이 사라지는 일이 생긴다.
  void selectDiscountOption(String key) =>
      _update(state.copyWith(discountRequested: true, discountOptionKey: key));

  void updateDiscountReason(String reason) =>
      _update(state.copyWith(discountReason: reason));

  void clearDiscountRequest() => _update(state.copyWith(clearDiscount: true));

  // ─── 서버 저장 (임시저장 버튼) ─────────────────────────────

  Future<void> saveProgress(List<Map<String, dynamic>> allOptions) async {
    double totalCost = 0;
    for (final option in allOptions) {
      if (state.selectedOptions.contains(option['id'])) {
        totalCost += (option['cost'] as num).toDouble();
      }
    }

    await ApiClient.saveRegistration(state.programId, {
      'country': state.country,
      'branch': state.branch,
      'realName': state.realName,
      'bibleName': state.bibleName,
      'gender': state.gender,
      'age': state.age,
      'arrivalFlight': state.arrivalFlight,
      'departureFlight': state.departureFlight,
      'foodRequirements': state.foodRequirements,
      'medicalConditions': state.medicalConditions,
      'skipsBreakfast': state.skipsBreakfast,
      'selectedOptions': state.selectedOptions,
      'roommatePreference': state.roommatePreference,
      'volunteerResources': state.volunteerResources,
      'volunteerNote': state.volunteerNote,
      'totalCost': totalCost,
      'feeTier': state.feeTier,
      'discountRequested': state.discountRequested,
      'discountOptionKey': state.discountOptionKey,
      'discountReason': state.discountReason,
    });
  }

  // 최종 제출 후 draft 삭제
  Future<void> submit(List<Map<String, dynamic>> allOptions) async {
    await saveProgress(allOptions);
    await ApiClient.submitRegistration(state.programId);
    await clearDraft();
  }

  // ─── 데이터 복원 ────────────────────────────────────────────

  // 로컬 draft 또는 DB 데이터를 메모리에 올림 (draft 우선)
  void loadFromDraft(RegistrationFormState draft) {
    state = draft;
  }

  // DB 데이터로 복원 (로컬 draft가 없을 때 fallback)
  void loadFromDb(Map<String, dynamic> data) {
    final loaded = RegistrationFormState(
      programId: state.programId,
      country: data['country'],
      branch: data['branch'],
      realName: data['real_name'],
      bibleName: data['bible_name'],
      gender: data['gender'],
      age: data['age'],
      arrivalFlight: data['arrival_flight'] as Map<String, dynamic>?,
      departureFlight: data['departure_flight'] as Map<String, dynamic>?,
      foodRequirements: data['food_requirements'],
      medicalConditions: data['medical_conditions'],
      skipsBreakfast: data['skips_breakfast'] as bool? ?? false,
      selectedOptions: List<String>.from(data['selected_options'] ?? []),
      roommatePreference: data['roommate_preference'],
      volunteerResources: List<String>.from(data['volunteer_resources'] ?? []),
      volunteerNote: data['volunteer_note'],
      feeTier: data['fee_tier'],
      discountRequested: data['discount_requested'] as bool? ?? false,
      discountOptionKey: data['discount_option_key'],
      discountReason: data['discount_reason'],
    );
    state = loaded;
    // DB에서 불러온 내용도 바로 draft로 저장
    _persistDraft();
  }
}

final registrationFormProvider =
    StateNotifierProvider.family<
      RegistrationFormNotifier,
      RegistrationFormState,
      String
    >((_, programId) => RegistrationFormNotifier(programId));
