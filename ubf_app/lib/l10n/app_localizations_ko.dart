// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Mana';

  @override
  String get actionCancel => '취소';

  @override
  String get actionSave => '저장';

  @override
  String get actionConfirm => '확인';

  @override
  String get actionDelete => '삭제';

  @override
  String get actionEdit => '편집';

  @override
  String get actionAdd => '추가';

  @override
  String get actionNext => '다음';

  @override
  String get actionPrevious => '이전';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get actionClose => '닫기';

  @override
  String get actionLogout => '로그아웃';

  @override
  String get commonLoading => '불러오는 중…';

  @override
  String get commonError => '문제가 발생했습니다';

  @override
  String get commonRequired => '필수';

  @override
  String get commonOptional => '선택';

  @override
  String get setupTitle => '편성 준비';

  @override
  String get setupTabRooms => '숙소';

  @override
  String get setupTabGroups => '말씀조';

  @override
  String get appTagline => '수양회 참가자 등록 시스템';

  @override
  String get authSignInGoogle => '구글 어카운트로 로그인하기';

  @override
  String get authSignInKakao => '카카오로 로그인하기';

  @override
  String get authSignInDev => '테스트 로그인 (dev@test.com)';

  @override
  String get authTermsNotice => '로그인하면 이용약관에 동의하는 것으로 간주합니다.';

  @override
  String authGoogleFailed(String error) {
    return '구글 로그인 실패: $error';
  }

  @override
  String authKakaoFailed(String error) {
    return '카카오 로그인 실패: $error';
  }

  @override
  String authDevFailed(String error) {
    return '테스트 로그인 실패: $error';
  }

  @override
  String get profileTitle => '프로필 설정';

  @override
  String get profileSubtitle => '참가 등록에 사용할 기본 정보를 입력하세요.\n한 번만 입력하면 됩니다.';

  @override
  String get profileNameLabel => '이름 *';

  @override
  String get profileNameHint => '실명을 입력하세요';

  @override
  String get profileNameRequired => '이름을 입력하세요';

  @override
  String get profileAgeLabel => '나이 *';

  @override
  String get profileAgeHint => '예: 28';

  @override
  String get profileAgeInvalid => '올바른 나이를 입력하세요';

  @override
  String get profileRegionLabel => '거주 지역 *';

  @override
  String get profileRegionHint => '예: 서울, 부산, New York, Toronto...';

  @override
  String get profileRegionRequired => '거주 지역을 입력하세요';

  @override
  String get profileSaveStart => '저장하고 시작하기';

  @override
  String profileSaveFailed(String error) {
    return '저장 실패: $error';
  }

  @override
  String get homeLogoutConfirmBody => '로그아웃하시겠습니까?\n다른 계정으로 로그인할 수 있습니다.';

  @override
  String get homeDirectorMode => 'Director 모드';

  @override
  String get homeManageMenu => '관리 메뉴';

  @override
  String get homeCreateProgram => '새 프로그램 생성';

  @override
  String get homeCreateProgramSub => 'UUID를 생성하고 프로그램을 설정합니다';

  @override
  String get homeProgramList => '내 프로그램 목록';

  @override
  String get homeProgramListDirectorSub => '생성한 프로그램을 관리합니다';

  @override
  String get homeProgramListAdminSub => '담당 프로그램을 관리합니다';

  @override
  String get homeAssignAdmins => '관리자 배정';

  @override
  String get homeAssignAdminsSub => '프로그램별 admin을 지정합니다';

  @override
  String get homeDirectorInfo => 'Director는 모든 프로그램을 관리하고 admin을 지정할 수 있습니다.';

  @override
  String get homeAdminMode => '관리자(Admin) 모드';

  @override
  String get homeAdminInfo => '프로그램 생성 후 UUID를 참가자들에게 공유하세요.';

  @override
  String get homeJoinTitle => '프로그램 참가';

  @override
  String get homeJoinSub => '리더에게 받은 UUID를 입력하여 프로그램에 참가하세요.';

  @override
  String get homeUuidLabel => '프로그램 UUID';

  @override
  String get homeJoinButton => '참가하기';

  @override
  String get homeRecentPrograms => '최근 참가한 프로그램';

  @override
  String get homeRemoveFromList => '목록에서 제거';

  @override
  String get homeBecomeLeader => '리더이신가요? 리더로 전환하기';

  @override
  String get homeLeaderCheckTitle => '지부장 확인';

  @override
  String homeLeaderCheckBody(String email) {
    return '로그인하신 이메일($email)이 다음 챕터의 지부장으로 등록되어 있습니다:';
  }

  @override
  String homeLeaderContinent(String value) {
    return '대륙: $value';
  }

  @override
  String homeLeaderNation(String value) {
    return '국가: $value';
  }

  @override
  String homeLeaderChapter(String value) {
    return '챕터: $value';
  }

  @override
  String get homeLeaderCheckPrompt => '지부장(리더)으로 등록하시겠습니까?';

  @override
  String get homeLeaderDeclineParticipant => '아니오, 참가자로 계속';

  @override
  String get homeLeaderConfirmRegister => '예, 리더로 등록';

  @override
  String get commonSaved => '저장되었습니다';

  @override
  String commonErrorDetail(String error) {
    return '오류: $error';
  }

  @override
  String get sectionDisabled => '이 섹션은 비활성화되어 있습니다';

  @override
  String get regTitle => '등록';

  @override
  String get regInvalidProgram => '유효하지 않은 프로그램 UUID입니다';

  @override
  String get regScheduleTooltip => '프로그램 일정';

  @override
  String get regSaveDraft => '임시저장';

  @override
  String get regReviewSummary => '요약 확인';

  @override
  String get regStepPersonal => '개인 정보';

  @override
  String get regStepArrival => '도착 비행기';

  @override
  String get regStepDeparture => '출발 비행기';

  @override
  String get regStepFood => '음식';

  @override
  String get regStepOptions => '투어/옵션';

  @override
  String get regStepRoommate => '룸메이트';

  @override
  String get regStepVolunteer => '자원봉사';

  @override
  String get roommateQuestion => '같이 머물고 싶은 분이 있으신가요?';

  @override
  String get roommateHelp =>
      '룸메이트 희망자의 이름(성경이름 또는 본명)을 입력해 주세요.\n최대한 반영하도록 노력하겠습니다.';

  @override
  String get roommateFieldLabel => '룸메이트 희망 (선택)';

  @override
  String get roommateFieldHint => '예: 베드로, 요한 (같은 방 희망)\n또는 \"없음\"으로 입력';

  @override
  String get roommateNotice => '룸메이트 배정은 리더의 재량으로 조정될 수 있습니다.';

  @override
  String get optionsNone => '이 프로그램에는 특별 옵션이 없습니다';

  @override
  String get optionsSelectPrompt => '참여할 프로그램을 선택하세요 (복수 선택 가능)';

  @override
  String get optionsFree => '무료';

  @override
  String get optionsSelectedTotal => '선택한 옵션 합계';

  @override
  String get genderMale => '남';

  @override
  String get genderFemale => '여';

  @override
  String get regContinent => '대륙 *';

  @override
  String get regContinentHint => '대륙 선택';

  @override
  String get regNation => '국가 *';

  @override
  String get regNationHint => '국가 선택';

  @override
  String get regNationDisabled => '대륙을 먼저 선택하세요';

  @override
  String get regChapter => '챕터 *';

  @override
  String get regChapterHint => '챕터 선택';

  @override
  String get regChapterNoneHint => '해당 국가에 등록된 챕터가 없습니다. 아래에 직접 입력하세요.';

  @override
  String get regChapterManualHint => '목록에 없으면 아래에 직접 입력하세요';

  @override
  String get regBranch => '지부명 *';

  @override
  String get regBranchHint => '예: Tokyo, Chicago';

  @override
  String get regRealName => '본명 *';

  @override
  String get regBibleName => '성경 이름';

  @override
  String get regBibleNameHint => '예: 베드로, 마리아';

  @override
  String get regGender => '성별';

  @override
  String get regAge => '나이 *';

  @override
  String get foodMedicalTitle => '질병 유무';

  @override
  String get foodMedicalHint => '당뇨, 고혈압, 알레르기 등 특이 질환을 입력하세요 (없으면 비워두세요)';

  @override
  String get foodRestrictionTitle => '섭취 불가능한 음식';

  @override
  String get foodRestrictionHelp => '아래에서 선택하거나 직접 입력하세요';

  @override
  String get foodRestrictionInputHint => '섭취 불가능한 음식을 입력하세요';

  @override
  String get foodVegetarian => '채식주의자 (Vegetarian)';

  @override
  String get foodVegan => '비건 (Vegan)';

  @override
  String get foodHalal => '할랄 (Halal)';

  @override
  String get foodKosher => '코셔 (Kosher)';

  @override
  String get foodGluten => '글루텐 불내증';

  @override
  String get foodPeanut => '땅콩 알레르기';

  @override
  String get foodDairy => '유제품 알레르기';

  @override
  String get foodSeafood => '해산물 알레르기';

  @override
  String get foodNone => '없음';

  @override
  String get foodBreakfastTitle => '아침 식사';

  @override
  String get foodSkipBreakfast => '아침 식사를 주로 하지 않습니다';

  @override
  String get foodSkipBreakfastSub => '식사 준비 인원 파악에 사용됩니다';

  @override
  String get flightArrival => '도착';

  @override
  String get flightDeparture => '출발';

  @override
  String flightInfoTitle(String dir) {
    return '$dir 비행기 정보';
  }

  @override
  String flightDateLabel(String dir) {
    return '$dir 날짜 *';
  }

  @override
  String flightAirportLabel(String dir) {
    return '$dir 공항';
  }

  @override
  String flightTimeLabel(String dir) {
    return '$dir 예정 시각';
  }

  @override
  String get flightPickDate => '날짜를 선택하세요';

  @override
  String get flightNumber => '항공편 번호';

  @override
  String get flightNumberHint => '예: KE123, OZ456';

  @override
  String get flightAutoSearch => '항공편 자동 조회';

  @override
  String get flightNotFound => '항공편 정보를 찾을 수 없습니다. 직접 입력해 주세요.';

  @override
  String flightStatus(String value) {
    return '상태: $value';
  }

  @override
  String get flightAutoFillHint => '항공편 번호 검색 시 자동 입력';

  @override
  String get volQuestion => '프로그램 진행에 도움을 드릴 수 있나요?';

  @override
  String get volHelp => '해당되는 항목을 모두 선택해 주세요. (선택 사항)';

  @override
  String get volOtherLabel => '기타 도움 가능한 내용 (선택)';

  @override
  String get volOtherHint => '위 목록에 없는 재능이나 자원을 적어주세요';

  @override
  String get volPiano => '피아노';

  @override
  String get volGuitar => '기타';

  @override
  String get volBass => '베이스';

  @override
  String get volDrums => '드럼';

  @override
  String get volViolin => '바이올린';

  @override
  String get volWorshipLead => '워십 인도';

  @override
  String get volVocals => '보컬';

  @override
  String get volTranslation => '통역/번역';

  @override
  String get volPhotography => '사진/영상';

  @override
  String get volSound => '음향';

  @override
  String get volDesign => '디자인';

  @override
  String get volIt => 'IT/기술';

  @override
  String get volChildcare => '어린이 돌봄';

  @override
  String get volCooking => '요리/주방';

  @override
  String get volDriving => '차량 운전';

  @override
  String get volMedical => '의료/구급';

  @override
  String get summaryTitle => '등록 요약';

  @override
  String get summarySectionProgram => '프로그램';

  @override
  String get summaryName => '이름';

  @override
  String get summaryLocation => '장소';

  @override
  String get summaryPeriod => '기간';

  @override
  String get summaryCountry => '국가';

  @override
  String get summaryBranch => '지부';

  @override
  String get summaryRealName => '본명';

  @override
  String get summaryBibleName => '성경이름';

  @override
  String get summaryAge => '나이';

  @override
  String get summaryFlightNo => '항공편';

  @override
  String get summaryArrAirport => '도착 공항';

  @override
  String get summaryArrTime => '도착 예정';

  @override
  String get summaryDepAirport => '출발 공항';

  @override
  String get summaryDepTime => '출발 예정';

  @override
  String get summarySectionFood => '음식 특별 사항';

  @override
  String get summarySectionOptions => '선택한 프로그램';

  @override
  String get summarySectionRoommate => '룸메이트 희망';

  @override
  String get summaryTotalCost => '총 납부 비용';

  @override
  String get summaryNoPaidOptions => '선택한 유료 옵션이 없습니다';

  @override
  String get summaryViewImmigration => '입국 안내 카드 보기';

  @override
  String get summarySubmit => '최종 제출';

  @override
  String get summaryEditBtn => '수정하기';

  @override
  String get summarySubmitConfirm =>
      '등록 정보를 최종 제출하시겠습니까?\n제출 후에는 수정이 제한될 수 있습니다.';

  @override
  String get summarySubmitDone => '제출 완료';

  @override
  String get summarySubmitDoneMsg => '등록이 성공적으로 제출되었습니다.\n담당자가 확인 후 연락드립니다.';

  @override
  String summarySubmitFailed(String error) {
    return '제출 실패: $error';
  }

  @override
  String get commonNoName => '이름 미입력';

  @override
  String unitPeople(int count) {
    return '$count명';
  }

  @override
  String unitCases(int count) {
    return '$count건';
  }

  @override
  String get dashTitle => '대시보드';

  @override
  String get dashExport => '내보내기';

  @override
  String get dashExportExcel => 'Excel로 내보내기';

  @override
  String get dashExportCsv => 'CSV로 내보내기';

  @override
  String get dashEditSettings => '프로그램 설정 편집';

  @override
  String get dashSetupSubtitle => '숙소·말씀조를 정의합니다 (배정 전 단계)';

  @override
  String get dashPendingPayments => '입금 확인 대기';

  @override
  String get dashViewAll => '전체 보기';

  @override
  String get dashNoPendingPayments => '입금 대기 중인 항목이 없습니다';

  @override
  String get dashAttendeeList => '참가자 목록';

  @override
  String get dashNoAttendees => '아직 등록된 참가자가 없습니다';

  @override
  String get dashSendNotice => '그룹 공지 전송';

  @override
  String get dashNoStats => '통계 데이터 없음';

  @override
  String get dashStatTotal => '총 등록';

  @override
  String get dashStatSubmitted => '등록 완료';

  @override
  String get dashStatFoodRestriction => '식사 제한';

  @override
  String get dashStatPendingPayment => '입금 대기';

  @override
  String get dashStatArrival => '도착 비행';

  @override
  String get dashStatConfirmedPayment => '입금 확인';

  @override
  String get dashPaymentPending => '확인 대기';

  @override
  String get dashStatusDone => '완료';

  @override
  String get dashStatusInProgress => '진행중';

  @override
  String get pcTitle => '프로그램 생성 완료';

  @override
  String get pcHeading => '프로그램이 생성되었습니다!';

  @override
  String get pcShareUuid => '아래 UUID를 참가자들에게 공유하세요';

  @override
  String get pcCopy => '복사하기';

  @override
  String get pcCopied => 'UUID가 복사되었습니다';

  @override
  String get pcInfo => '참가자들은 이 UUID를 앱에 입력하여 등록할 수 있습니다.';

  @override
  String get pcGoDashboard => '대시보드로 이동';

  @override
  String get pcGoHome => '홈으로';

  @override
  String get cpProgramType => '프로그램 유형';

  @override
  String get cpTypeLocal => '지역 수양회';

  @override
  String get cpTypeInternational => '국제 수양회';

  @override
  String get cpLocalNote => '지역 수양회: 항공편·투어 섹션은 자동으로 비활성화됩니다';

  @override
  String get cpBasicInfo => '기본 정보';

  @override
  String get cpNameLabel => '프로그램 이름 *';

  @override
  String get cpNameHint => '예: 2025 여름 수양회';

  @override
  String get cpNameRequired => '프로그램 이름을 입력하세요';

  @override
  String get cpLocationLabel => '장소 *';

  @override
  String get cpLocationHint => '예: 제주도 국제 컨벤션 센터';

  @override
  String get cpLocationRequired => '장소를 입력하세요';

  @override
  String get cpStartDate => '시작일 선택';

  @override
  String get cpEndDate => '종료일 선택';

  @override
  String get cpImmigrationInfo => '입국 안내 정보';

  @override
  String get cpImmigrationDesc => '참가자가 공항 입국 시 감사관에게 보여줄 정보입니다 (선택)';

  @override
  String get cpNearestAirport => '가까운 공항';

  @override
  String get cpAirportHint => '예: 인천국제공항 (ICN)';

  @override
  String get cpContacts => '현장 대표 연락처 (2명)';

  @override
  String get cpName1 => '이름 1';

  @override
  String get cpName1Hint => '홍길동';

  @override
  String get cpPhone1 => '전화번호 1';

  @override
  String get cpName2 => '이름 2';

  @override
  String get cpName2Hint => '김철수';

  @override
  String get cpPhone2 => '전화번호 2';

  @override
  String get cpSectionsTitle => '등록 섹션 활성화';

  @override
  String get cpSectionsDesc => '참가자에게 보여줄 항목을 선택하세요';

  @override
  String get cpSecVolunteer => '프로그램 진행 도움 자원 (악기, 번역 etc)';

  @override
  String get cpSpecialOptions => '특별 프로그램/투어 옵션';

  @override
  String get cpOptionsDesc => '옵션별 비용을 설정하면 참가자가 선택할 수 있습니다';

  @override
  String cpOptionCost(String value) {
    return '비용: $value';
  }

  @override
  String get cpOptionName => '옵션명';

  @override
  String get cpOptionNameHint => '제주 투어 A코스';

  @override
  String get cpOptionCostLabel => '비용';

  @override
  String get cpCreateButton => '프로그램 생성 (UUID 발급)';

  @override
  String get cpDupTitle => '이미 존재하는 프로그램';

  @override
  String get cpDupBody =>
      '같은 이름과 시작일의 프로그램이 이미 있습니다.\n기존 프로그램의 UUID 화면으로 이동할까요?';

  @override
  String get cpDupGoExisting => '기존 프로그램으로';

  @override
  String cpCreateFailed(String error) {
    return '프로그램 생성 실패: $error';
  }

  @override
  String get epSaved => '설정이 저장되었습니다';

  @override
  String get epNotFound => '프로그램을 찾을 수 없습니다';

  @override
  String get epTourLocked => '수양회가 이미 시작되어 투어 옵션을 수정할 수 없습니다';

  @override
  String epOptionContact(String value) {
    return '담당: $value';
  }

  @override
  String get epAddOption => '옵션 추가';

  @override
  String get epEditOption => '옵션 편집';

  @override
  String get epSaveChanges => '변경사항 저장';

  @override
  String get epOptionNameReq => '옵션명 *';

  @override
  String get epOptionCostNum => '비용 (숫자)';

  @override
  String get epOptionContactName => '담당자 이름';

  @override
  String get epOptionDesc => '설명 (선택)';

  @override
  String get epPickDate => '날짜 선택';

  @override
  String epPhotos(int count) {
    return '사진 ($count/5)';
  }

  @override
  String get blTitle => '리더 등록';

  @override
  String get blInfo => '리더로 등록하면 수양회 프로그램을 생성하고 참가자를 관리할 수 있습니다.';

  @override
  String get blLoginAccount => '로그인 계정';

  @override
  String get blLeaderName => '리더 이름 *';

  @override
  String get blLeaderNameHint => '참가자들에게 보여질 이름';

  @override
  String get blRegisterButton => '리더 등록 후 이벤트 생성하기';

  @override
  String blLeaderRegFailed(String error) {
    return '리더 등록 실패: $error';
  }

  @override
  String get sosTitle => '긴급 SOS';

  @override
  String get sosHealth => '🚑 건강/의료 응급';

  @override
  String get sosSafety => '🆘 신변 위협';

  @override
  String get sosLost => '🗺️ 길을 잃음';

  @override
  String get sosGpsOff => 'GPS가 꺼져 있습니다. 설정에서 활성화해 주세요.';

  @override
  String get sosPermDenied => '위치 권한이 거부되었습니다. 위치 없이 SOS를 전송합니다.';

  @override
  String sosLocationError(String error) {
    return '위치를 가져올 수 없습니다: $error';
  }

  @override
  String get sosSentTitle => 'SOS 전송 완료';

  @override
  String get sosSentMsg => '관리자에게 긴급 알림이 전송되었습니다.\n잠시만 기다려 주세요.';

  @override
  String sosSendFailed(String error) {
    return '전송 실패: $error';
  }

  @override
  String get sosBanner => '관리자에게 즉시 알림이 전송됩니다.\n긴급한 상황에서만 사용해 주세요.';

  @override
  String get sosSelectType => '상황 유형을 선택하세요';

  @override
  String get sosMessageLabel => '추가 메시지 (선택)';

  @override
  String get sosMessageHint => '현재 상황을 간단히 설명해 주세요';

  @override
  String sosGpsConfirmed(String value) {
    return 'GPS 위치 확인됨 $value';
  }

  @override
  String get sosGpsChecking => 'GPS 위치 확인 중...';

  @override
  String get sosSending => '전송 중...';

  @override
  String get sosSend => 'SOS 전송';

  @override
  String get sosFabConfirm => '관리자에게 긴급 알림을 전송하시겠습니까?';

  @override
  String schLoadFailed(String error) {
    return '일정 로드 실패: $error';
  }

  @override
  String get schAddTitle => '일정 추가';

  @override
  String get schTitleLabel => '제목 *';

  @override
  String get schTitleHint => '개회 예배';

  @override
  String get schDescLabel => '설명 (선택)';

  @override
  String get schPickTime => '시간 선택';

  @override
  String get schTimezone => '타임존';

  @override
  String get schTzAuto => '디바이스 타임존으로 자동 설정됨';

  @override
  String get schTzReset => '디바이스 타임존으로 초기화';

  @override
  String get schAllRequired => '제목, 날짜, 시간을 모두 입력하세요';

  @override
  String schAddFailed(String error) {
    return '추가 실패: $error';
  }

  @override
  String get schTzChangeTitle => '타임존 변경';

  @override
  String get schTzUseDevice => '내 디바이스 타임존 사용';

  @override
  String get schTzExamples => '예: Asia/Seoul, America/New_York, Europe/London';

  @override
  String schTzChangeFailed(String error) {
    return '타임존 변경 실패: $error';
  }

  @override
  String get schDeleteTitle => '일정 삭제';

  @override
  String get schDeleteConfirm => '이 일정을 삭제하시겠습니까?';

  @override
  String schDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get schEmpty => '등록된 일정이 없습니다';

  @override
  String get immTitle => '입국 안내 카드';

  @override
  String get immFullscreenTooltip => '전체화면 (감사관에게 보여주기)';

  @override
  String get immNotFound => '프로그램 정보를 찾을 수 없습니다.';

  @override
  String get immBanner => '우측 상단 전체화면 버튼을 눌러 감사관에게 보여주세요.';

  @override
  String get immCardPurpose => 'PURPOSE OF VISIT / 방문 목적';

  @override
  String get immCardConference => 'Religious Conference / 종교 수양회';

  @override
  String get immCardVenue => 'VENUE / 장소';

  @override
  String get immCardDate => 'DATE / 기간';

  @override
  String get immCardAirport => 'NEAREST AIRPORT / 가까운 공항';

  @override
  String get immCardContact => 'ON-SITE CONTACT / 현장 연락처';

  @override
  String get immCardFooter =>
      'I am attending the above religious conference as a participant.\n저는 위 종교 수양회 참가자입니다.';

  @override
  String get immExitHint =>
      'Tap anywhere to exit fullscreen\n화면을 탭하면 전체화면이 해제됩니다';

  @override
  String setupRoomsMade(int count) {
    return '만들어진 방 · $count개';
  }

  @override
  String get setupRoomsEmpty => '아직 방이 없습니다.\n우하단 버튼으로 방을 일괄 추가하세요.';

  @override
  String get setupBulkAddRooms => '방 일괄 추가';

  @override
  String setupRoomsAdded(int count) {
    return '방 $count개를 추가했습니다';
  }

  @override
  String get setupReconcileTitle => '정원 대비 등록';

  @override
  String get setupMale => '남자';

  @override
  String get setupFemale => '여자';

  @override
  String setupMixedSeats(int count) {
    return '부부·가족실 $count석 (가족 단위 배정)';
  }

  @override
  String setupRegVsSeats(int regs, int seats) {
    return '등록 $regs · 정원 $seats';
  }

  @override
  String setupSeatShortage(int count) {
    return '$count석 부족';
  }

  @override
  String setupRoomCapacity(int count) {
    return '$count인';
  }

  @override
  String get setupCouple => '부부실';

  @override
  String get setupCoupleSub => '2인·혼성';

  @override
  String get setupFamily => '가족실';

  @override
  String get setupFamilySub => '3~4인·혼성';

  @override
  String get setupDorm => '단체실';

  @override
  String get setupDormSub => '5인+·단일성별';

  @override
  String get setupMixed => '가족(혼성)';

  @override
  String get setupRoomType => '방 유형';

  @override
  String get setupNameRule => '이름 규칙';

  @override
  String get setupNameRuleHint => '예: 3층 3##호';

  @override
  String get setupStartNum => '시작#';

  @override
  String get setupCount => '개수';

  @override
  String get setupCapacity => '정원(인)';

  @override
  String get setupFloor => '층(선택)';

  @override
  String get setupMixedNotAllowed => '혼성 불가';

  @override
  String get setupFamilyAuto => '가족 단위 (혼성) — 자동';

  @override
  String get setupBulkValidation => '이름 규칙·개수·정원을 확인하세요';

  @override
  String setupGroupsMade(int count) {
    return '만들어진 조 · $count개';
  }

  @override
  String get setupGroupsEmpty => '아직 조가 없습니다.\n우하단 버튼으로 조를 만드세요.';

  @override
  String get setupMakeGroups => '조 만들기';

  @override
  String get setupMakeGroupsPrompt => '몇 개의 조를 만들까요? (1조, 2조 … 자동 생성)';

  @override
  String get setupGroupCount => '조 개수';

  @override
  String get setupGroupCountSuffix => '개';

  @override
  String get setupMake => '만들기';

  @override
  String setupGroupsCreated(int count) {
    return '조 $count개를 만들었습니다';
  }

  @override
  String get setupMakeGroupsFirst => '조를 먼저 만들어 주세요';

  @override
  String setupEvenPerGroup(int count) {
    return '조당 $count명씩 균등';
  }

  @override
  String setupUnevenPerGroup(int remCount, int bigger, int base) {
    return '$remCount개 조는 $bigger명, 나머지는 $base명';
  }

  @override
  String get setupGroupSummary => '편성 요약';

  @override
  String setupRegAndGroups(int total, int groups) {
    return '등록 $total명 · $groups개 조';
  }

  @override
  String setupBalancePreview(String preview) {
    return '연령·성비 균형 배정 시 — $preview';
  }

  @override
  String setupLeaderless(int count) {
    return '조장 미지정 $count개';
  }

  @override
  String get setupNoPassageLocation => '본문·장소 미입력';

  @override
  String get setupNoLeader => '조장 미지정';

  @override
  String get setupEditGroupMenu => '조장·본문·장소 편집';

  @override
  String setupEditGroupTitle(String name) {
    return '$name 편집';
  }

  @override
  String get setupGroupName => '조 이름';

  @override
  String get setupLeaderName => '조장(목자) 이름';

  @override
  String get setupLeaderPhone => '조장 연락처';

  @override
  String get setupPassage => '본문 (예: 요한복음 10장)';

  @override
  String get setupLocation => '모임 장소';

  @override
  String get expColNo => '번호';

  @override
  String get expArrFlight => '도착 항공편';

  @override
  String get expArrTime => '도착일시';

  @override
  String get expDepFlight => '출발 항공편';

  @override
  String get expDepTime => '출발일시';

  @override
  String get expOptions => '선택 옵션';

  @override
  String get expTotalCost => '총 비용';

  @override
  String get expPaymentStatus => '입금 상태';

  @override
  String get expSubmittedCol => '등록 완료';

  @override
  String get expUnregistered => '미등록';

  @override
  String get expIncomplete => '미완료';

  @override
  String get expRoster => '참가자 명단';

  @override
  String get regStepCompanion => '동반자';

  @override
  String get regStepBuddy => '함께하기 지목';

  @override
  String get buddyTitle => '함께하고 싶은 사람';

  @override
  String get buddyDesc => '지목하면 상대에게 요청이 갑니다. 상대가 수락해야 확정됩니다.';

  @override
  String get buddyRoommateSection => '룸메이트 요청';

  @override
  String get buddyGroupSection => '말씀조 요청';

  @override
  String get buddySearchHint => '이름·성경이름으로 검색…';

  @override
  String get buddySendRoommate => '룸메이트로 요청';

  @override
  String get buddySendGroup => '같은 조로 요청';

  @override
  String get buddySentSection => '내가 보낸 요청';

  @override
  String get buddyReceivedSection => '받은 요청';

  @override
  String get buddyStatusPending => '대기중';

  @override
  String get buddyStatusAccepted => '수락됨';

  @override
  String get buddyStatusDeclined => '거절됨';

  @override
  String get buddyAccept => '수락';

  @override
  String get buddyDecline => '거절';

  @override
  String get buddyKindRoommate => '룸메이트';

  @override
  String get buddyKindGroup => '말씀조';

  @override
  String get buddyReqSent => '요청을 보냈습니다';

  @override
  String get buddyRoommateSameGenderNote => '룸메이트는 같은 성별에게만 요청할 수 있어요.';

  @override
  String get buddyReceivedEmpty => '받은 요청이 없습니다';

  @override
  String get buddyNoCandidates => '아직 지목할 다른 참가자가 없습니다';

  @override
  String buddyRequestLine(String kind) {
    return '$kind 요청';
  }

  @override
  String get companionTitle => '동반 가족/참석자';

  @override
  String get companionDesc => '부부·가족이 함께 오면 추가하세요. 인원수·픽업에 각각 반영됩니다.';

  @override
  String get companionAdd => '동반자 추가';

  @override
  String get companionEmpty => '혼자 참석하면 비워두세요.';

  @override
  String get companionLanguage => '사용 언어';

  @override
  String get companionSameFlight => '대표자와 같은 항공편';

  @override
  String get companionArrivalFlightNo => '동반자 도착 항공편';

  @override
  String get companionDepartureFlightNo => '동반자 출발 항공편';

  @override
  String get companionNeedsPickup => '픽업 필요';

  @override
  String companionCount(int count) {
    return '동반자 $count명';
  }

  @override
  String get companionAddTitle => '동반자 추가';

  @override
  String get companionEditTitle => '동반자 편집';

  @override
  String get asnTitle => '배정';

  @override
  String get asnAutoAssign => '자동 배정';

  @override
  String asnAutoRoomsDone(int count) {
    return '숙소 자동배정 완료 — $count명 배정';
  }

  @override
  String asnAutoGroupsDone(int count) {
    return '말씀조 자동배정 완료 — $count명 배정';
  }

  @override
  String asnUnplaced(int count) {
    return '미배치 $count명';
  }

  @override
  String get asnUnassigned => '미배정';

  @override
  String asnUnassignedCount(int count) {
    return '미배정 $count명';
  }

  @override
  String get asnPickRoom => '방 선택';

  @override
  String get asnPickGroup => '조 선택';

  @override
  String get asnNoRooms => '먼저 편성 준비에서 방을 만드세요';

  @override
  String get asnNoGroups => '먼저 편성 준비에서 조를 만드세요';

  @override
  String get asnAllAssigned => '모두 배정되었습니다';

  @override
  String get dashAssignSubtitle => '숙소·말씀조를 배정합니다';
}
