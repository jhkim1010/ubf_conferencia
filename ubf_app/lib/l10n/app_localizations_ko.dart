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
  String get languageTitle => '언어';

  @override
  String get languageSystem => '기기 언어 따르기';

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
  String get profileRegionLabel => '거주 국가 *';

  @override
  String get profileRegionHint => '국가를 검색·선택하세요';

  @override
  String get profileRegionRequired => '거주 국가를 선택하세요';

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
  String get flightSkipTitle => '항공편 입력 생략';

  @override
  String flightSkipBody(String dir) {
    return '개최 국가와 동일한 국가에 거주하셔서 $dir 항공편 입력이 생략됩니다. 비행기로 오시면 아래에서 추가하세요.';
  }

  @override
  String get flightSkipAdd => '항공편 정보 추가';

  @override
  String get flightSkipCollapse => '항공편 생략';

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
  String get cpPeriod => '기간 선택 (시작 ~ 종료)';

  @override
  String get cpHostCountry => '개최 국가';

  @override
  String get cpHostCountryHint => '국가를 검색·선택하세요';

  @override
  String get cpHostCountryHelp => '거주 국가가 개최 국가와 같은 참가자는 항공편 입력이 생략됩니다';

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
    return '사진 ($count/6)';
  }

  @override
  String get epPhotoUrlTitle => '사진 URL 추가';

  @override
  String get epPhotoUrlLabel => '이미지 주소';

  @override
  String get epCapacity => '정원';

  @override
  String get epSignupDeadline => '신청 마감';

  @override
  String get epBrochureUrl => '브로슈어 링크';

  @override
  String get epVideoUrl => '소개 영상 링크';

  @override
  String get tourCapacityLabel => '잔여 정원';

  @override
  String tourRemaining(int remaining, int capacity) {
    return '$remaining / $capacity명';
  }

  @override
  String get tourFull => '정원 마감';

  @override
  String get tourClosed => '신청 마감';

  @override
  String tourDeadline(String date) {
    return '마감 $date';
  }

  @override
  String get linkCopied => '링크가 복사되었습니다';

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
  String get buddyRoommateSameGenderNote =>
      '룸메이트는 같은 성별 혹은 동반 가족에게만 요청할 수 있어요.';

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

  @override
  String get dashDispatchSubtitle => '기사 명부와 자동 배차';

  @override
  String get dspTitle => '운행 배차';

  @override
  String get dspTabArrival => '도착 픽업';

  @override
  String get dspTabDeparture => '출발 드롭';

  @override
  String get dspAddVan => '밴 추가';

  @override
  String get dspAutoDispatch => '자동 배차';

  @override
  String get dspNoRuns => '먼저 밴(기사·정원)을 등록하세요';

  @override
  String dspAutoDone(int assigned, int unassigned) {
    return '$assigned명 배차 · $unassigned명 미배차';
  }

  @override
  String dspUnassignedCount(int count) {
    return '미배차 $count명';
  }

  @override
  String get dspAllAssigned => '모두 배차되었습니다';

  @override
  String get dspPickVan => '밴 선택';

  @override
  String get dspDriverUnset => '기사 미정';

  @override
  String get dspNewVan => '새 밴 등록';

  @override
  String get dspEditVan => '밴 수정';

  @override
  String get dspAirport => '공항';

  @override
  String get dspVehicle => '차량';

  @override
  String get dspDriverName => '기사 이름';

  @override
  String get dspDriverPhone => '기사 전화';

  @override
  String get dspCapacityLabel => '정원';

  @override
  String get dspMeetPoint => '집결지';

  @override
  String get dspDeleteVan => '밴 삭제';

  @override
  String get mtrTitle => '내 이동 정보';

  @override
  String get mtrArrival => '도착 픽업';

  @override
  String get mtrDeparture => '출발 드롭';

  @override
  String mtrArrivalRoute(String airport) {
    return '$airport → 수양회장';
  }

  @override
  String mtrDepartureRoute(String airport) {
    return '수양회장 → $airport';
  }

  @override
  String get mtrPending => '곧 배차될 예정입니다';

  @override
  String get mtrAssigned => '배차 완료';

  @override
  String get mtrPendingBadge => '배차 예정';

  @override
  String get mtrVehicle => '차편';

  @override
  String get mtrDriver => '기사';

  @override
  String get mtrCoPassengers => '동승';

  @override
  String get mtrMeetPoint => '집결지';

  @override
  String get mtrSelfDrive => '자차로 이동해요';

  @override
  String get mtrSelfDriveDesc => '픽업이 필요 없으면 꺼주세요';

  @override
  String get mtrHostCountryTitle => '공항 픽업 대상이 아닙니다';

  @override
  String get mtrHostCountryDesc =>
      '개최국에서 참석하시므로 공항 픽업 명단에 들어가지 않습니다. 비행기로 오신다면 등록 화면에서 항공편을 입력해 주십시오. 그러면 명단에 들어갑니다.';

  @override
  String get rdyTitle => '준비 현황';

  @override
  String get rdySubtitle => '무엇이 막혀 있고 누구에게 연락해야 하는지';

  @override
  String get rdySectionItems => '준비 항목';

  @override
  String get rdySectionCohorts => '국내 · 해외 참석자';

  @override
  String get rdySectionBlocked => '연락이 필요한 사람';

  @override
  String get rdyLodging => '숙소';

  @override
  String get rdyTransport => '픽업 배차';

  @override
  String get rdyFlights => '항공편 미입력';

  @override
  String get rdyMeals => '식사';

  @override
  String get rdyPayment => '참가비';

  @override
  String get rdyRoles => '직분 분포';

  @override
  String get rdyDomestic => '국내';

  @override
  String get rdyOverseas => '해외';

  @override
  String get rdySkipped => '생략';

  @override
  String get rdyUnspecified => '미입력';

  @override
  String get rdyStuckPersonal => '인적사항';

  @override
  String get rdyStuckMeals => '식사';

  @override
  String get rdyStuckFlight => '항공편';

  @override
  String get rdyStuckLodging => '숙소';

  @override
  String get rdyStuckPayment => '참가비';

  @override
  String get rdyStatusOk => '양호';

  @override
  String get rdyStatusWarn => '주의';

  @override
  String get rdyStatusStop => '부족';

  @override
  String get rdyStatusIdle => '설정 안 됨';

  @override
  String get rdyNoBlocked => '모두 순조롭게 진행 중입니다';

  @override
  String get rdyRolesUnreliable => '직분 미입력이 절반을 넘습니다';

  @override
  String get rdyOpenCard => '준비 현황 보기';

  @override
  String get rdyOpenCardSub => '막힌 지점과 연락 대상을 한눈에';

  @override
  String get privacyTitle => '개인정보 수집·이용 안내';

  @override
  String get privacySummary => '등록에 입력하신 정보는 수양회 운영에만 사용됩니다.';

  @override
  String get privacyWhatTitle => '수집하는 정보';

  @override
  String get privacyWhat =>
      '이름·성경이름·성별·나이·거주 국가·지부, 항공편 정보, 식사 제한, 질병 유무, 룸메이트 희망, 참가비 납부 상태. SOS 기능을 사용하시면 그 시점의 위치가 함께 전송됩니다.';

  @override
  String get privacyWhyTitle => '이용 목적';

  @override
  String get privacyWhy =>
      '숙소·조 편성, 공항 픽업 배차, 식사 준비, 안전 대응에 사용합니다. 다른 목적으로 쓰지 않습니다.';

  @override
  String get privacyWhoTitle => '열람 범위';

  @override
  String get privacyWho =>
      '수양회 담당자입니다. 다른 참가자에게는 QR 나눔으로 직접 나눈 것만 보입니다 — 요절, 기도제목, 그리고 켜 둔 연락처입니다. 건강 정보는 참가자에게 절대 나가지 않습니다. 목록에도 나오지 않고, 담당자가 필요할 때 한 사람씩 열어 보며 그 기록이 남습니다.';

  @override
  String get privacyWhereTitle => '보관 위치';

  @override
  String get privacyWhere =>
      '데이터는 외부 클라우드 데이터베이스(미국)에 저장됩니다. 거주 국가 밖으로 이전됨을 알려드립니다.';

  @override
  String get privacyKeepTitle => '보관 기간';

  @override
  String get privacyKeep => '수양회 종료 후 1년까지 보관하며 이후 삭제합니다.';

  @override
  String get privacyRightsTitle => '권리';

  @override
  String get privacyRights =>
      '적으신 내용은 언제든 고치실 수 있습니다. QR 나눔은 항목마다 끌 수 있고, 내 명함을 저장한 사람을 하나씩 끊을 수 있으며, QR 을 새로 만들면 예전 코드는 모두 막힙니다. 삭제를 원하시면 담당자에게 말씀해 주십시오.';

  @override
  String get privacyAgree => '위 내용을 확인했습니다';

  @override
  String get privacyMore => '자세히 보기';

  @override
  String get privacyLess => '접기';

  @override
  String get regStepFee => '참가비';

  @override
  String get feePrompt => '참가비 등급을 선택하세요.';

  @override
  String get feeTierBasic => '기본';

  @override
  String get feeTierPremium => '프리미엄';

  @override
  String get feeNotSet => '참가비가 아직 정해지지 않았습니다.';

  @override
  String get discountTitle => '할인 신청';

  @override
  String get discountPrompt => '해당되는 경우 선택하세요.';

  @override
  String get discountNone => '할인 신청 안 함';

  @override
  String get discountReasonLabel => '보충 설명 (선택)';

  @override
  String get discountReasonHint => '담당자가 알아야 할 내용';

  @override
  String get discountStatusPending => '담당자 확인을 기다리는 중입니다.';

  @override
  String discountStatusApproved(String amount) {
    return '승인됨 — $amount 할인';
  }

  @override
  String get discountStatusRejected => '승인되지 않았습니다.';

  @override
  String discountAdminNote(String note) {
    return '담당자 메모: $note';
  }

  @override
  String get cohortSection => '성경공부 팀';

  @override
  String get cohortHint =>
      '팀은 사용 언어로 갈리고, 그 안에서 나이로 나뉩니다. Adulto 20세 이상 · Junior 19세 이하.';

  @override
  String get cohortMinSize => '한 팀 최소 인원';

  @override
  String get cohortKeep => '그대로 둔다';

  @override
  String get cohortKeepSub => '받을 팀이 없으면 미배정으로 남겨 직접 정합니다';

  @override
  String get cohortAbsorb => '같은 언어의 Adulto 팀으로 올린다';

  @override
  String get cohortAbsorbSub => '말이 통하는 쪽을 우선합니다';

  @override
  String get cohortMerge => '같은 나이대의 다른 언어 팀과 합친다';

  @override
  String get cohortMergeSub => '또래를 우선합니다';

  @override
  String get studyLangTitle => '말씀 공부를 어떤 언어로 하시겠습니까?';

  @override
  String get studyLangBody => '성경공부 팀이 이 언어로 나뉩니다.';

  @override
  String get studyLangNote => '나중에 등록 화면에서 바꾸실 수 있습니다.';

  @override
  String get regStepStudyLang => '말씀 공부';

  @override
  String get discountNoOptions => '이 수양회는 할인 신청을 받지 않습니다.';

  @override
  String discountDomesticOnly(String country) {
    return '할인은 $country 에서 참석하는 분만 신청할 수 있습니다.';
  }

  @override
  String get cpFeeSection => '참가비';

  @override
  String get cpFeeBasic => '기본 참가비';

  @override
  String get cpFeePremium => '프리미엄 참가비';

  @override
  String get cpFeeBasicDesc => '기본 등급에 포함되는 것';

  @override
  String get cpFeePremiumDesc => '프리미엄 등급에 포함되는 것';

  @override
  String get cpFeeHint => '비워 두면 그 등급을 제공하지 않습니다.';

  @override
  String get cpFeeInvalid => '0 이상의 숫자를 입력하세요.';

  @override
  String get cpDiscountSection => '할인 항목';

  @override
  String get cpDiscountHint => '등록자가 할인을 신청할 때 고를 수 있는 사유입니다. 예: \"1일만 참석\"';

  @override
  String get cpDiscountLabel => '등록자에게 보일 문구';

  @override
  String get cpDiscountAmount => '할인 금액 (선택)';

  @override
  String get cpDiscountAmountHint => '비워 두면 건마다 담당자가 정합니다.';

  @override
  String get cpDiscountAdd => '할인 항목 추가';

  @override
  String get cpDiscountRemove => '삭제';

  @override
  String get cpDiscountEmpty => '할인 항목이 없습니다.';

  @override
  String get adDiscountTitle => '할인 신청';

  @override
  String get adDiscountNone => '할인 신청이 없습니다.';

  @override
  String get adDiscountApprove => '승인';

  @override
  String get adDiscountReject => '반려';

  @override
  String get adDiscountAmount => '할인 금액';

  @override
  String get adDiscountNote => '메모 (선택)';

  @override
  String get adDiscountAmountReq => '승인하려면 금액이 필요합니다.';

  @override
  String get adDiscountSaved => '저장되었습니다.';

  @override
  String get adDiscountPending => '대기';

  @override
  String get adDiscountApproved => '승인';

  @override
  String get adDiscountRejected => '반려';

  @override
  String get myProgramsTitle => '내 프로그램 관리';

  @override
  String get myProgramsEmpty => '아직 만든 수양회가 없습니다.\n아래 버튼으로 새로 만드십시오.';

  @override
  String get myProgramsEdit => '수정';

  @override
  String myProgramsRegistered(int count) {
    return '등록 $count명';
  }

  @override
  String get cpCurrency => '통화';

  @override
  String get cpCurrencyHint => '이 수양회 등록자 전원이 이 통화로 금액을 봅니다. 환율 변환은 하지 않습니다.';

  @override
  String cpCurrencyFixed(String code) {
    return '국제 수양회의 금액은 $code 로 적습니다. 여러 나라에서 오므로 통화를 통일합니다.';
  }

  @override
  String get flightNotBookedYet => '아직 항공권을 예매하지 않았습니다';

  @override
  String get flightNotBookedYetHint => '예상 날짜만 적어 주십시오. 항공편은 나중에 추가할 수 있습니다.';

  @override
  String get flightEstimatedNotice =>
      '확정이 아니라 예상으로 기록됩니다. 예매한 뒤에 다시 들어와 항공편을 넣어 주십시오.';

  @override
  String get expFlightEstimated => '(예상 — 미예매)';

  @override
  String get buddyFamilyTitle => '함께 오시는 분입니까?';

  @override
  String get buddyFamilyBody =>
      '상대가 다른 성별입니다. 방은 기본적으로 같은 성별끼리 씁니다. 부부·부모자녀처럼 함께 오신 가족인 경우에만 같은 방을 쓸 수 있습니다. 상대의 수락도 필요합니다.';

  @override
  String get buddyFamilyConfirm => '예, 가족입니다';

  @override
  String get myProgramsDelete => '삭제';

  @override
  String get myProgramsDeleteTitle => '이 수양회를 삭제할까요?';

  @override
  String myProgramsDeleteBody(String name) {
    return '\"$name\" 이(가) 더 이상 아무에게도 보이지 않습니다. 등록·배정 기록은 남으므로 되살리려면 관리자에게 문의하십시오.';
  }

  @override
  String myProgramsDeleteHasRegistrations(int count) {
    return '이미 $count명이 등록했습니다. 확인을 위해 수양회 이름을 입력하십시오.';
  }

  @override
  String get myProgramsDeleteTypeName => '수양회 이름';

  @override
  String get myProgramsDeleted => '삭제되었습니다.';

  @override
  String get mealsTitle => '식사 제한';

  @override
  String get mealsSubtitle => '누가 무엇을 못 먹는지 — 주방 전달용';

  @override
  String get mealsEmpty => '식사 제한을 적어 낸 사람이 없습니다.';

  @override
  String get mealsRestriction => '못 먹는 것 · 비고';

  @override
  String get mealsSkipsBreakfast => '아침 거름';

  @override
  String mealsSummary(int restricted, int total) {
    return '참가자 $total명 중 $restricted명';
  }

  @override
  String mealsPdfSummary(int restricted, int total) {
    return '등록 참가자 $total명 중 $restricted명이 식사 제한을 적어 냈습니다.';
  }

  @override
  String get mealsPdfNote =>
      '참가자가 직접 적은 내용을 모은 것입니다. 알레르기가 가볍다고 단정하기 전에 본인에게 확인하십시오.';

  @override
  String get mealsDownloadPdf => 'PDF 내려받기';

  @override
  String get mealsHint => '두 번 누르면 누가 무엇을 못 먹는지 보입니다';

  @override
  String get mealsNotSubmitted => '미제출';

  @override
  String mealsDownloadFailed(String detail) {
    return 'PDF 를 저장하지 못했습니다: $detail';
  }

  @override
  String get regStepHotel => '숙박';

  @override
  String get hotelTitle => '수양회 전후에 머무십니까?';

  @override
  String get hotelBody =>
      '일찍 도착하시거나 투어가 끝난 뒤 더 머무시면 호텔이 필요합니다. 원하시는 수준과 박수를 골라 주십시오.';

  @override
  String get hotelNoOptions => '주최 측이 아직 숙소 수준을 정하지 않았습니다. 나중에 다시 오셔도 됩니다.';

  @override
  String get hotelNone => '호텔이 필요 없습니다';

  @override
  String hotelPerNight(String amount) {
    return '1박 $amount';
  }

  @override
  String get hotelPriceTbd => '금액 미정';

  @override
  String get hotelNightsBefore => '수양회 전 박수';

  @override
  String get hotelNightsAfter => '투어 후 박수';

  @override
  String hotelNightsCount(int count) {
    return '$count박';
  }

  @override
  String get hotelEstimate => '예상 숙박비';

  @override
  String get hotelNotInFee => '참가비에는 포함되지 않습니다. 숙박비는 따로 정산합니다.';

  @override
  String get hotelSectionTitle => '숙박 수준 (수양회 전후)';

  @override
  String get hotelSectionHelp => '외국에서 오는 참가자에게만 보입니다. 수준과 박수를 직접 고릅니다.';

  @override
  String get hotelLevelKo => '수준 (한국어)';

  @override
  String get hotelLevelEn => '수준 (영어)';

  @override
  String get hotelLevelEs => '수준 (스페인어)';

  @override
  String get hotelPricePerNightLabel => '1박 단가';

  @override
  String get hotelAddLevel => '수준 추가';

  @override
  String get hotelNoLevelsYet => '아직 추가한 수준이 없습니다';

  @override
  String get summarySectionHotel => '수양회 전후 숙박';

  @override
  String summaryHotelNights(int before, int after) {
    return '전 $before박 · 후 $after박';
  }

  @override
  String hotelComputed(int before, int after) {
    return '수양회 전 $before박, 수양회 이후 $after박이 더 필요합니다.';
  }

  @override
  String hotelComputedBeforeOnly(int before) {
    return '수양회 전 $before박이 더 필요합니다. 이후 박수는 돌아가는 항공편이 없어 계산하지 못했습니다.';
  }

  @override
  String hotelComputedAfterOnly(int after) {
    return '수양회 이후 $after박이 더 필요합니다. 전 박수는 오시는 항공편이 없어 계산하지 못했습니다.';
  }

  @override
  String get hotelComputedNone => '항공편이 수양회 기간 안에 오가므로 전후로 호텔이 필요하지 않습니다.';

  @override
  String get hotelNoFlightYet =>
      '항공편을 적어 주시면 몇 박이 필요한지 계산해 드립니다. 아래에서 직접 정하셔도 됩니다.';

  @override
  String get hotelPickPrompt => '다음 가격 옵션 중 원하시는 것을 선택해 주십시오.';

  @override
  String get hotelAdjustHint => '항공편과 수양회 일정으로 계산한 값입니다. 다르면 아래에서 고쳐 주십시오.';

  @override
  String get hotelRecalc => '항공편 기준으로 다시 계산';

  @override
  String get pcInviteLink => '초대 링크';

  @override
  String get pcInviteLinkHelp =>
      'UUID 대신 이것을 보내십시오. 링크를 누르면 이 수양회로 바로 들어갑니다 — 참가자가 코드를 옮겨 적을 필요가 없습니다.';

  @override
  String get pcCopyLink => '링크 복사';

  @override
  String get pcLinkCopied => '초대 링크를 복사했습니다';

  @override
  String get tgSectionTitle => '텔레그램 알림';

  @override
  String get tgSectionHelp =>
      '이 수양회의 새 등록과 정보 수정이 텔레그램으로 전송됩니다. 비워 두면 기본 봇을 씁니다.';

  @override
  String get tgBotToken => '봇 토큰';

  @override
  String get tgBotTokenHint => '123456789:AA…  (@BotFather 에서 발급)';

  @override
  String get tgChatId => '채팅 ID';

  @override
  String get tgChatIdHint => '예: -1001234567890 (그룹) 또는 본인 사용자 ID';

  @override
  String get tgConfigured => '이 수양회에 봇이 설정되어 있습니다';

  @override
  String get tgTokenHidden =>
      '저장된 토큰은 다시 보여주지 않습니다. 비워 두면 그대로 유지되고, 새로 입력하면 교체됩니다.';

  @override
  String get tgClearToken => '봇 설정 해제';

  @override
  String get tgInvalidToken => '봇 토큰 형식이 아닙니다 (예: 123456789:AA…)';

  @override
  String get tgHowTo =>
      '텔레그램에서 @BotFather 에게 /newbot → 받은 토큰을 복사합니다. 봇을 단톡방에 초대한 뒤 그 방의 채팅 ID 를 적으십시오.';

  @override
  String get hotelLevelPt => '수준 (포르투갈어)';

  @override
  String get libTitle => '자료실';

  @override
  String get libSubtitle => '수양회에서 나눈 자료 — 언제든 다시 보실 수 있습니다';

  @override
  String get libEmpty => '아직 올라온 자료가 없습니다.';

  @override
  String get libEmptyAdmin => '아직 자료가 없습니다. 아래 버튼으로 PDF 를 올리십시오.';

  @override
  String get libOpen => '열기';

  @override
  String get libAdd => '자료 올리기';

  @override
  String get libPickPdf => 'PDF 고르기';

  @override
  String get libPickOnWeb =>
      'PDF 는 컴퓨터 브라우저에서 올릴 수 있습니다. ubf.coolsistema.com 에 접속해 로그인하십시오.';

  @override
  String get libItemTitle => '제목';

  @override
  String get libItemTitleHint => '예: 1과 — 요한복음 10장';

  @override
  String get libItemDesc => '설명 (선택)';

  @override
  String get libPublished => '참가자에게 보임';

  @override
  String get libHidden => '숨김';

  @override
  String get libUploading => '올리는 중…';

  @override
  String libUploadFailed(String detail) {
    return '올리지 못했습니다: $detail';
  }

  @override
  String get libDeleteTitle => '이 자료를 지울까요?';

  @override
  String libDeleteBody(String title) {
    return '\"$title\" 이(가) 모두에게서 사라지고 파일도 지워집니다.';
  }

  @override
  String libSize(int kb) {
    return '$kb KB';
  }

  @override
  String libOpenFailed(String detail) {
    return '파일을 열지 못했습니다: $detail';
  }

  @override
  String get libTitleRequired => '제목을 입력하십시오';

  @override
  String get dashLibrarySubtitle => '교재 PDF 를 참가자에게 나눠 줍니다';

  @override
  String get homeLibrary => '수양회 자료실';

  @override
  String get photoPick => '기기에서 고르기';

  @override
  String get photoUploading => '올리는 중…';

  @override
  String photoUploadFailed(String detail) {
    return '사진을 올리지 못했습니다: $detail';
  }

  @override
  String get photoOrUrl => '또는 이미지 주소 붙여넣기';

  @override
  String get cardTitle => '내 명함';

  @override
  String get cardShareTitle => 'QR 나눔';

  @override
  String get cardShareIntro => '수양회에서 만난 분과 요절·기도제목·연락처를 나눕니다.';

  @override
  String get cardPhoto => '대표사진';

  @override
  String get cardChangePhoto => '사진 바꾸기';

  @override
  String get cardVerseRef => '요절';

  @override
  String get cardVerseRefHint => '예: 요한복음 10:10';

  @override
  String get cardVerseText => '요절 내용 (선택)';

  @override
  String get cardPrayerTopics => '기도제목 · 최대 3개';

  @override
  String get cardPrayerHint => '한 줄에 하나씩';

  @override
  String get cardContacts => '연락 — 켠 것만 보입니다';

  @override
  String get cardChannels => '채널';

  @override
  String get cardEmail => '이메일';

  @override
  String get cardWhatsapp => 'WhatsApp';

  @override
  String get cardPhone => '전화번호';

  @override
  String get cardInstagram => 'Instagram';

  @override
  String get cardX => 'X';

  @override
  String get cardYoutube => 'YouTube';

  @override
  String get cardJuniorLocked =>
      '19세 이하는 연락처를 나누지 않습니다. 요절·기도제목·채널은 나눌 수 있습니다.';

  @override
  String get cardShowQr => '내 QR 보여주기';

  @override
  String get cardScan => 'QR 읽기';

  @override
  String get cardQrHint => '상대가 이 코드를 읽으면 내 명함이 뜹니다.';

  @override
  String get cardQrRotate => 'QR 새로 만들기';

  @override
  String get cardQrRotateWarn => '예전 코드는 그 자리에서 막힙니다. 이미 저장한 친구는 그대로 남습니다.';

  @override
  String get cardQrRotated => 'QR 을 새로 만들었습니다';

  @override
  String get cardScanUnsupported => '읽기에는 카메라가 필요합니다. 폰을 쓰시거나 브라우저에서 열어 주십시오.';

  @override
  String get cardScanPoint => '상대의 QR 을 비추세요';

  @override
  String get cardSaveFriend => '친구로 저장';

  @override
  String get cardDontSave => '저장 안 함';

  @override
  String get cardSaved => '친구 목록에 저장했습니다';

  @override
  String get cardAlreadySaved => '이미 친구 목록에 있습니다';

  @override
  String get cardSelfScan => '내 명함입니다';

  @override
  String get cardExpiredCode => '만료되었거나 없는 코드입니다';

  @override
  String get friendsTitle => '나눔 친구';

  @override
  String get friendsEmpty => '아직 없습니다. 이야기를 나눈 뒤 상대의 QR 을 읽어 보십시오.';

  @override
  String get friendsSearch => '이름·나라로 찾기…';

  @override
  String friendsMetOn(String date) {
    return '$date 만남';
  }

  @override
  String get friendsNote => '내 메모 (나만 봅니다)';

  @override
  String get friendsRemove => '내 목록에서 지우기';

  @override
  String get friendsOtherPrograms => '다른 수양회';

  @override
  String get cardPrivacyTitle => '나눔 설정';

  @override
  String get cardWhoCanSee => '내 명함을 볼 수 있는 사람';

  @override
  String get cardVisToken => 'QR 을 읽은 사람';

  @override
  String get cardVisProgram => '같은 수양회 참가자 전체';

  @override
  String get cardVisProgramNote =>
      '이것을 켜면 QR 없이도 참가자 명단에서 내 명함을 열 수 있습니다. 기본은 꺼져 있습니다.';

  @override
  String cardSavedBy(int count) {
    return '나를 저장한 사람 · $count명';
  }

  @override
  String get cardSavedByEmpty => '아직 아무도 저장하지 않았습니다.';

  @override
  String get cardRevoke => '끊기';

  @override
  String get cardRevokeDone => '이제 그 사람은 내 명함을 볼 수 없습니다';

  @override
  String get cardSaveBack => '나도 저장';

  @override
  String get cardOpenWhatsapp => 'WhatsApp';

  @override
  String get cardOpenEmail => '메일';

  @override
  String get cardNoContacts => '이 분은 연락처를 나누지 않았습니다.';

  @override
  String get homeQrShare => 'QR 나눔';

  @override
  String get homeQrShareSub => '내 명함·QR·만난 사람들';

  @override
  String get companionSameBranch => '저와 같은 지부입니다';

  @override
  String get companionSameBranchSub => '다른 지부에서 오시면 꺼 주세요';

  @override
  String get companionMustRegister => '동반자도 각자 따로 등록해야 합니다.';

  @override
  String get companionWhy =>
      '여기에 적는 것은 같은 방에 배정받기 위해서입니다. 방이 따로 배정되어도 괜찮으시면 적지 않으셔도 됩니다.';

  @override
  String get homeAlsoAttending => '저도 참석합니다';

  @override
  String get homeAlsoAttendingSub => '직접 등록하거나, 이미 적어 둔 내용을 열어 봅니다';

  @override
  String get homePickMyProgram => '내가 만든 수양회로 바로 들어가기';

  @override
  String get homeOrEnterUuid => '다른 분이 만든 수양회는 UUID 를 적어 주십시오';

  @override
  String chapterNoticeTitle(String leader) {
    return '지부장 $leader 님이 만든 수양회가 있습니다';
  }

  @override
  String get chapterNoticeAsk => '참석하시겠습니까?';

  @override
  String get chapterNoticeJoin => '예, 등록하겠습니다';

  @override
  String get chapterNoticeLater => '나중에';

  @override
  String get cpFeeDescHint => '예: 단체실, 하루 세 끼';

  @override
  String get cpFeeDescLooksLikeAmount =>
      '금액처럼 보입니다. 숫자는 왼쪽 참가비 칸에 적어 주십시오 — 이 칸은 무엇이 포함되는지 적는 곳입니다.';

  @override
  String get cpFeeNoneWarning =>
      '참가비가 비어 있어 참가자에게 참가비 화면이 나오지 않습니다. 무료 수양회일 때만 비워 두십시오.';

  @override
  String get rdyFeeTier => '참가비 등급';

  @override
  String feeBackfillTitle(int count) {
    return '참가비를 안 고른 사람이 $count명 있습니다';
  }

  @override
  String get feeBackfillWhy =>
      '참가비를 정하기 전에 등록해서 참가비 화면을 보지 못했습니다. 그분들 총액에는 참가비가 빠져 있습니다.';

  @override
  String get feeBackfillAction => '모두 이 등급으로 맞추기';

  @override
  String feeBackfillConfirm(int count, String tier) {
    return '$count명을 $tier 등급으로 맞추고 총액을 다시 계산할까요? 이미 고른 분은 건드리지 않습니다.';
  }

  @override
  String feeBackfillDone(int count) {
    return '$count명을 맞췄습니다';
  }

  @override
  String get feeBackfillNotSet => '그 등급의 참가비가 아직 없습니다. 참가비를 먼저 정해 주십시오.';

  @override
  String get studyLangMulti => '공부할 수 있는 언어를 모두 고르십시오';

  @override
  String get studyLangPrimary => '주 언어';

  @override
  String get studyLangPrimaryNote =>
      '가장 먼저 고른 것이 주 언어이고, 성경공부 팀은 그것으로 정해집니다. 나머지는 팀 인원이 적을 때 자리를 찾는 데 씁니다.';

  @override
  String get regStepPickup => '픽업';

  @override
  String get pickupTitle => '수양회장까지 태워 드릴까요?';

  @override
  String get pickupBody =>
      '개최국에서 오시므로 항공편은 필요하지 않습니다. 태워 드릴지, 태운다면 어디서인지만 알려 주십시오.';

  @override
  String get pickupNeed => '태워 주셨으면 합니다';

  @override
  String get pickupNeedNo => '제가 알아서 가겠습니다';

  @override
  String get pickupFromLabel => '어디서 태울까요?';

  @override
  String get pickupFromHint => '예: 레티로 버스터미널, 지부 앞';

  @override
  String get pickupFromRequired => '태울 곳을 적어 주십시오';

  @override
  String get cpFeeMoveTitle => '참가비 금액이 설명 칸에 들어가 있습니다';

  @override
  String get cpFeeMoveBody => '금액 칸이 비어 있어 참가자에게 참가비 화면이 나오지 않습니다. 옮길까요?';

  @override
  String get cpFeeMoveAction => '금액 칸으로 옮기기';

  @override
  String get cpFeeMoveDone => '옮겼습니다. 저장을 눌러 주십시오.';

  @override
  String get tblTitle => '세부 내용';

  @override
  String tblCount(int count) {
    return '$count건';
  }

  @override
  String get tblEmpty => '보여 드릴 것이 없습니다.';

  @override
  String get tblExportPdf => 'PDF';

  @override
  String get tblExportExcel => '엑셀';

  @override
  String tblExportFailed(String detail) {
    return '내보내지 못했습니다: $detail';
  }

  @override
  String get tblHint => '두 번 누르면 명단이 보입니다';

  @override
  String get colGenderAge => '성별 / 나이';

  @override
  String get colStatus => '상태';

  @override
  String get colFlight => '도착 항공편';

  @override
  String get colPayment => '입금';

  @override
  String get colFee => '참가비';

  @override
  String get colLanguages => '사용 언어';

  @override
  String get tblAllAttendees => '전체 참가자';

  @override
  String epPlanDocs(int count) {
    return '계획서 · 안내 자료 ($count)';
  }

  @override
  String get epPlanUpload => 'PDF 올리기';

  @override
  String get epPlanName => '이 자료의 이름';

  @override
  String get epPlanNameHint => '예: 일정표, 비용 안내, 신청서';

  @override
  String get epPlanRemove => '이 자료 빼기';

  @override
  String epPlanFull(int max) {
    return '자료는 $max개까지 올릴 수 있습니다.';
  }

  @override
  String get tourPlanOpen => '열기';

  @override
  String get tourOpenFailed => '열지 못해 링크를 대신 복사했습니다.';

  @override
  String get dashStatTours => '투어 신청 상황';

  @override
  String get tblTourSignups => '투어 신청 상황';

  @override
  String get colTour => '투어';

  @override
  String get colSignups => '신청';

  @override
  String get colRemaining => '잔여';

  @override
  String get colDeadline => '마감';

  @override
  String get tourNoLimit => '제한 없음';

  @override
  String get tourNobody => '아직 신청자가 없습니다';

  @override
  String tourSignupSummary(int signed) {
    return '신청 $signed명';
  }

  @override
  String get tblUnfinishedNote => '크림색 줄은 아직 등록을 완료하지 않은 사람입니다.';

  @override
  String get asnTabService => '봉사';

  @override
  String svcNeeded(int filled, int needed) {
    return '$needed명 중 $filled명';
  }

  @override
  String svcNoLimit(int filled) {
    return '$filled명 · 인원 미정';
  }

  @override
  String svcShort(int count) {
    return '$count명 부족';
  }

  @override
  String get svcNobody => '아직 아무도 없습니다';

  @override
  String get svcNominate => '참가자에게 부탁하기';

  @override
  String get svcPickPerson => '누구에게 부탁할까요?';

  @override
  String svcAsked(String name) {
    return '$name 님께 부탁했습니다';
  }

  @override
  String get svcSetLead => '책임자로';

  @override
  String get svcLead => '책임자';

  @override
  String get svcConfirm => '확정';

  @override
  String get svcReject => '반려';

  @override
  String get svcEditRoles => '역할 추가 · 인원 설정';

  @override
  String get svcAddRole => '역할 추가';

  @override
  String get svcRoleName => '역할 이름';

  @override
  String get svcRoleNameHint => '예: 이과수 버스 인솔';

  @override
  String get svcNeedCount => '필요 인원';

  @override
  String get svcNeedsApproval => '승인 필요';

  @override
  String get svcStatusInvited => '수락 대기';

  @override
  String get svcStatusApplied => '신청함';

  @override
  String get svcStatusApproval => '승인 대기';

  @override
  String get svcStatusConfirmed => '확정';

  @override
  String get svcStatusRejected => '반려';

  @override
  String get svcStatusDeclined => '어렵다고 답함';

  @override
  String get svcRoleSpecialSong => '특송';

  @override
  String get svcRoleMc => '사회';

  @override
  String get svcRolePickup => '픽업';

  @override
  String get svcRoleCleaning => '청소';

  @override
  String get svcRoleTourGuide => '투어 인솔';

  @override
  String get svcRoleMealPrep => '식사 준비';

  @override
  String get svcRoleLodgingBackup => '숙소 백업';

  @override
  String get svcRoleRegistrationDesk => '등록 접수';

  @override
  String get svcRoleInterpreter => '통역';

  @override
  String get svcRolePhotoVideo => '사진·영상';

  @override
  String get svcRoleMedical => '의무';

  @override
  String get svcRoleGroupStudyLeader => '말씀조 리더';

  @override
  String get svcRoleOther => '기타';

  @override
  String get svcInviteTitle => '봉사 부탁이 왔습니다';

  @override
  String svcInviteBody(String role) {
    return '$role 을(를) 맡아 주시겠습니까?';
  }

  @override
  String get svcAccept => '수락';

  @override
  String get svcDecline => '어렵습니다';

  @override
  String get svcThanks => '감사합니다.';

  @override
  String get admTitle => '이 수양회를 관리할 사람';

  @override
  String get admSubtitle => '대시보드·참가자 명단·배정 화면을 함께 봅니다.';

  @override
  String get admOwner => '만든 사람';

  @override
  String get admAdd => '관리자 추가';

  @override
  String get admPickPerson => '참가자 명단에서 고르기';

  @override
  String get admByEmail => '목록에 없으면 이메일로';

  @override
  String get admEmailLabel => '구글 로그인에 쓰는 이메일';

  @override
  String get admRemove => '빼기';

  @override
  String admRemoveAsk(String name) {
    return '$name 님을 관리자에서 뺄까요?';
  }

  @override
  String admAdded(String name) {
    return '$name 님이 함께 관리합니다';
  }

  @override
  String get admOwnerLocked => '만든 사람은 뺄 수 없습니다.';

  @override
  String get dashAdmins => '관리자';

  @override
  String get dashAdminsSub => '명단·배정을 함께 볼 사람을 세웁니다';

  @override
  String get svcRolesTitle => '이 수양회의 봉사 역할';

  @override
  String svcRoleCount(int count, int max) {
    return '역할 $count/$max';
  }

  @override
  String get svcSectionCustom => '직접 만든 역할';

  @override
  String get svcSectionBuiltIn => '기본 역할';

  @override
  String svcRoleFull(int max) {
    return '역할은 $max개까지 만들 수 있습니다.';
  }

  @override
  String get svcDeleteRole => '이 역할 지우기';

  @override
  String get svcNeedShort => '필요';

  @override
  String dashMoreCount(int count) {
    return '나머지 $count명 보기 →';
  }

  @override
  String get dashSeeAll => '표로 보기 →';

  @override
  String get dashByTour => '투어별로 보기 →';

  @override
  String get dashPreviewEmpty => '아직 없습니다';

  @override
  String get dashTourNobody => '신청 없음';

  @override
  String get dashTourRoom => '정원 여유';

  @override
  String get dashTourFull => '정원 참';

  @override
  String dashUnitPeopleShort(int count) {
    return '$count명';
  }

  @override
  String epContacts(int count) {
    return '현장 대표 연락처 ($count명)';
  }

  @override
  String get epAddContact => '연락처 추가';

  @override
  String get epContactName => '이름';

  @override
  String get epContactPhone => '전화번호';

  @override
  String get epRemoveContact => '이 연락처 빼기';

  @override
  String epContactsFull(int max) {
    return '연락처는 $max명까지 넣을 수 있습니다.';
  }

  @override
  String get epPaymentWhen => '언제 받습니까?';

  @override
  String get epFeeWhen => '수양회 참가비';

  @override
  String get epTourWhen => '투어 비용';

  @override
  String get epPrepaid => '선불';

  @override
  String get epOnsite => '현장';

  @override
  String get epPaymentNote => '둘 다 현장에서 받으면 대시보드에서 입금 현황 카드를 감춥니다.';

  @override
  String get dashStatPayments => '입금 현황';

  @override
  String get dashPayConfirmed => '확인';

  @override
  String get dashPayPending => '대기';

  @override
  String get dashPayNone => '미납';

  @override
  String get tblPayments => '입금 현황';

  @override
  String get setupExtraBed => '여유 자리';

  @override
  String get setupExtraBedHint => '한 명 더 들어갈 수 있습니다. 정원이 다 찼을 때에만 씁니다.';

  @override
  String asnRoomWithExtra(int used, int cap, int extra) {
    return '$used/$cap (+$extra)';
  }

  @override
  String setupExtraSeats(int count) {
    return '여유 $count석';
  }

  @override
  String get dashStatVolunteers => '봉사 자원자';

  @override
  String dashRoleFilled(int filled, int needed) {
    return '$filled/$needed';
  }

  @override
  String get dashOpenService => '봉사 배정 열기 →';

  @override
  String svcOffered(int count) {
    return '등록할 때 자원한 사람 ($count명)';
  }

  @override
  String get svcOfferedNote => '할 수 있다고 적어 낸 것입니다. 누구에게 맡길지는 담당자가 정합니다.';

  @override
  String get svcCanDo => '가능';

  @override
  String get svcCallSend => '전체에 도움 청하기';

  @override
  String svcCallSent(int short) {
    return '요청함 · $short자리 남음';
  }

  @override
  String get svcCallClose => '요청 닫기';

  @override
  String get svcCallDone => '전체에 보냈습니다';

  @override
  String get svcCallTooSoon => '조금 전에 보냈습니다. 몇 시간 뒤에 다시 보내십시오.';

  @override
  String get svcCallFilled => '이 역할은 이미 다 찼습니다.';

  @override
  String get svcCallNoTarget => '필요 인원을 먼저 정해 주십시오.';

  @override
  String get svcOpenTitle => '봉사자를 찾고 있습니다';

  @override
  String svcOpenBody(String role, int short) {
    return '$role — $short자리 남았습니다';
  }

  @override
  String get svcIllDoIt => '제가 하겠습니다';

  @override
  String get svcAppliedThanks => '감사합니다. 담당자가 확정해 드립니다.';

  @override
  String get annTitle => '공지 보내기';

  @override
  String get annSubtitle => '단톡방이 아니라 앱으로 바로 갑니다';

  @override
  String get annBody => '무엇을 알릴까요?';

  @override
  String get annSend => '보내기';

  @override
  String get annTo => '받는 사람';

  @override
  String get annToAll => '전체';

  @override
  String get annToRoom => '한 숙소';

  @override
  String get annToGroup => '한 말씀조';

  @override
  String get annToUnsub => '등록을 안 끝낸 사람';

  @override
  String get annToUnpaid => '입금 전인 사람';

  @override
  String get annPickRoom => '어느 숙소입니까?';

  @override
  String get annPickGroup => '어느 조입니까?';

  @override
  String annSent(int count) {
    return '$count대에 보냈습니다';
  }

  @override
  String get annPast => '지난 공지';

  @override
  String get annNoneYet => '아직 보낸 공지가 없습니다';

  @override
  String get dashAnnounce => '공지 보내기';

  @override
  String get dashAnnounceSub => '전체에게, 또는 한 숙소·말씀조에만';

  @override
  String get dspPlanTitle => '필요한 차량';

  @override
  String dspPlanNeed(int need, int add) {
    return '$need대 필요 · $add대 부족';
  }

  @override
  String dspPlanOk(int have) {
    return '$have대 · 채워짐';
  }

  @override
  String dspPlanPeople(int count) {
    return '$count명';
  }

  @override
  String dspMakeVans(int count) {
    return '밴 $count대 만들기';
  }

  @override
  String get dspPlanNone => '아직 도착 시각이 없습니다';

  @override
  String get dspUnassignedFlight => '배차 없음';

  @override
  String get schServiceLabel => '이 순서에 필요한 봉사 (선택)';

  @override
  String get schServiceNone => '없음';

  @override
  String get schServiceHint =>
      '시작 5분 전 알림에 \"아직 n명 부족\" 이 함께 갑니다. 다 찼으면 붙지 않습니다.';

  @override
  String svcAssignTo(String name) {
    return '$name 님에게 부탁할 일';
  }

  @override
  String get svcSuggested => '적어 낸 것과 맞음';

  @override
  String get dashNotAssigned => '아직 맡은 일 없음';

  @override
  String dashAssignedCount(int count) {
    return '$count곳 맡음';
  }

  @override
  String get asnNoRoomLeader => '방장 없음';

  @override
  String asnRoomLeaderIs(String name) {
    return '방장 $name';
  }

  @override
  String get asnNoGroupLeader => '조장 없음';

  @override
  String get svcMineTitle => '내가 맡은 봉사';

  @override
  String get tgOffer => '텔레그램으로도 연락받기';

  @override
  String get tgOpen => '텔레그램 열기';

  @override
  String get tgCheck => '눌렀습니다';

  @override
  String get tgLinked => '텔레그램이 연결되었습니다';

  @override
  String get tgNotYet => '아직입니다 — 링크를 열어 시작을 누른 뒤 다시 해 주십시오';

  @override
  String get tgUnlink => '연결 끊기';
}
