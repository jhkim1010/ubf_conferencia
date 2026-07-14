// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mana';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionNext => 'Next';

  @override
  String get actionPrevious => 'Back';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionClose => 'Close';

  @override
  String get actionLogout => 'Log out';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonOptional => 'Optional';

  @override
  String get setupTitle => 'Setup';

  @override
  String get setupTabRooms => 'Rooms';

  @override
  String get setupTabGroups => 'Bible study groups';

  @override
  String get appTagline => 'Conference registration system';

  @override
  String get authSignInGoogle => 'Sign in with Google';

  @override
  String get authSignInKakao => 'Sign in with Kakao';

  @override
  String get authSignInDev => 'Test login (dev@test.com)';

  @override
  String get authTermsNotice =>
      'By signing in, you agree to the Terms of Service.';

  @override
  String authGoogleFailed(String error) {
    return 'Google sign-in failed: $error';
  }

  @override
  String authKakaoFailed(String error) {
    return 'Kakao sign-in failed: $error';
  }

  @override
  String authDevFailed(String error) {
    return 'Test login failed: $error';
  }

  @override
  String get profileTitle => 'Profile setup';

  @override
  String get profileSubtitle =>
      'Enter the basic information used for registration.\nYou only need to do this once.';

  @override
  String get profileNameLabel => 'Name *';

  @override
  String get profileNameHint => 'Enter your real name';

  @override
  String get profileNameRequired => 'Please enter your name';

  @override
  String get profileAgeLabel => 'Age *';

  @override
  String get profileAgeHint => 'e.g. 28';

  @override
  String get profileAgeInvalid => 'Please enter a valid age';

  @override
  String get profileRegionLabel => 'Country of residence *';

  @override
  String get profileRegionHint => 'Search and select a country';

  @override
  String get profileRegionRequired => 'Please select your country';

  @override
  String get profileSaveStart => 'Save and start';

  @override
  String profileSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get homeLogoutConfirmBody =>
      'Do you want to log out?\nYou can sign in with a different account.';

  @override
  String get homeDirectorMode => 'Director mode';

  @override
  String get homeManageMenu => 'Management';

  @override
  String get homeCreateProgram => 'Create program';

  @override
  String get homeCreateProgramSub => 'Generate a UUID and configure a program';

  @override
  String get homeProgramList => 'My programs';

  @override
  String get homeProgramListDirectorSub => 'Manage programs you created';

  @override
  String get homeProgramListAdminSub => 'Manage your assigned programs';

  @override
  String get homeAssignAdmins => 'Assign admins';

  @override
  String get homeAssignAdminsSub => 'Designate an admin per program';

  @override
  String get homeDirectorInfo =>
      'A director manages all programs and can assign admins.';

  @override
  String get homeAdminMode => 'Admin mode';

  @override
  String get homeAdminInfo =>
      'After creating a program, share its UUID with participants.';

  @override
  String get homeJoinTitle => 'Join a program';

  @override
  String get homeJoinSub =>
      'Enter the UUID your leader gave you to join a program.';

  @override
  String get homeUuidLabel => 'Program UUID';

  @override
  String get homeJoinButton => 'Join';

  @override
  String get homeRecentPrograms => 'Recently joined';

  @override
  String get homeRemoveFromList => 'Remove from list';

  @override
  String get homeBecomeLeader => 'Are you a leader? Switch to leader mode';

  @override
  String get homeLeaderCheckTitle => 'Chapter leader check';

  @override
  String homeLeaderCheckBody(String email) {
    return 'The email you signed in with ($email) is registered as the leader of this chapter:';
  }

  @override
  String homeLeaderContinent(String value) {
    return 'Continent: $value';
  }

  @override
  String homeLeaderNation(String value) {
    return 'Country: $value';
  }

  @override
  String homeLeaderChapter(String value) {
    return 'Chapter: $value';
  }

  @override
  String get homeLeaderCheckPrompt =>
      'Would you like to register as a chapter leader?';

  @override
  String get homeLeaderDeclineParticipant => 'No, continue as participant';

  @override
  String get homeLeaderConfirmRegister => 'Yes, register as leader';

  @override
  String get commonSaved => 'Saved';

  @override
  String commonErrorDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get sectionDisabled => 'This section is disabled';

  @override
  String get flightSkipTitle => 'Flight input skipped';

  @override
  String flightSkipBody(String dir) {
    return 'You live in the host country, so $dir flight input is skipped. If you are flying, add it below.';
  }

  @override
  String get flightSkipAdd => 'Add flight info';

  @override
  String get flightSkipCollapse => 'Skip flight';

  @override
  String get regTitle => 'Registration';

  @override
  String get regInvalidProgram => 'Invalid program UUID';

  @override
  String get regScheduleTooltip => 'Program schedule';

  @override
  String get regSaveDraft => 'Save draft';

  @override
  String get regReviewSummary => 'Review summary';

  @override
  String get regStepPersonal => 'Personal info';

  @override
  String get regStepArrival => 'Arrival flight';

  @override
  String get regStepDeparture => 'Departure flight';

  @override
  String get regStepFood => 'Meals';

  @override
  String get regStepOptions => 'Tours / options';

  @override
  String get regStepRoommate => 'Roommate';

  @override
  String get regStepVolunteer => 'Volunteering';

  @override
  String get roommateQuestion => 'Is there someone you\'d like to room with?';

  @override
  String get roommateHelp =>
      'Enter the name (Bible name or real name) of the person you\'d like to room with.\nWe\'ll do our best to accommodate it.';

  @override
  String get roommateFieldLabel => 'Roommate preference (optional)';

  @override
  String get roommateFieldHint =>
      'e.g. Peter, John (same room)\nor enter \"None\"';

  @override
  String get roommateNotice =>
      'Roommate assignments may be adjusted at the leader\'s discretion.';

  @override
  String get optionsNone => 'This program has no special options';

  @override
  String get optionsSelectPrompt =>
      'Select the programs you\'ll join (multiple allowed)';

  @override
  String get optionsFree => 'Free';

  @override
  String get optionsSelectedTotal => 'Selected options total';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get regContinent => 'Continent *';

  @override
  String get regContinentHint => 'Select a continent';

  @override
  String get regNation => 'Country *';

  @override
  String get regNationHint => 'Select a country';

  @override
  String get regNationDisabled => 'Select a continent first';

  @override
  String get regChapter => 'Chapter *';

  @override
  String get regChapterHint => 'Select a chapter';

  @override
  String get regChapterNoneHint =>
      'No chapters are registered for this country. Please enter it manually below.';

  @override
  String get regChapterManualHint => 'If not listed, enter it manually below';

  @override
  String get regBranch => 'Branch name *';

  @override
  String get regBranchHint => 'e.g. Tokyo, Chicago';

  @override
  String get regRealName => 'Real name *';

  @override
  String get regBibleName => 'Bible name';

  @override
  String get regBibleNameHint => 'e.g. Peter, Mary';

  @override
  String get regGender => 'Gender';

  @override
  String get regAge => 'Age *';

  @override
  String get foodMedicalTitle => 'Medical conditions';

  @override
  String get foodMedicalHint =>
      'Enter any conditions such as diabetes, hypertension, allergies (leave blank if none)';

  @override
  String get foodRestrictionTitle => 'Foods you cannot eat';

  @override
  String get foodRestrictionHelp => 'Choose below or enter your own';

  @override
  String get foodRestrictionInputHint => 'Enter foods you cannot eat';

  @override
  String get foodVegetarian => 'Vegetarian';

  @override
  String get foodVegan => 'Vegan';

  @override
  String get foodHalal => 'Halal';

  @override
  String get foodKosher => 'Kosher';

  @override
  String get foodGluten => 'Gluten intolerance';

  @override
  String get foodPeanut => 'Peanut allergy';

  @override
  String get foodDairy => 'Dairy allergy';

  @override
  String get foodSeafood => 'Seafood allergy';

  @override
  String get foodNone => 'None';

  @override
  String get foodBreakfastTitle => 'Breakfast';

  @override
  String get foodSkipBreakfast => 'I usually skip breakfast';

  @override
  String get foodSkipBreakfastSub => 'Used to estimate meal headcount';

  @override
  String get flightArrival => 'Arrival';

  @override
  String get flightDeparture => 'Departure';

  @override
  String flightInfoTitle(String dir) {
    return '$dir flight info';
  }

  @override
  String flightDateLabel(String dir) {
    return '$dir date *';
  }

  @override
  String flightAirportLabel(String dir) {
    return '$dir airport';
  }

  @override
  String flightTimeLabel(String dir) {
    return '$dir scheduled time';
  }

  @override
  String get flightPickDate => 'Select a date';

  @override
  String get flightNumber => 'Flight number';

  @override
  String get flightNumberHint => 'e.g. KE123, OZ456';

  @override
  String get flightAutoSearch => 'Look up flight automatically';

  @override
  String get flightNotFound =>
      'Flight information not found. Please enter it manually.';

  @override
  String flightStatus(String value) {
    return 'Status: $value';
  }

  @override
  String get flightAutoFillHint =>
      'Auto-filled when you search by flight number';

  @override
  String get volQuestion => 'Can you help with the program?';

  @override
  String get volHelp => 'Select all that apply. (Optional)';

  @override
  String get volOtherLabel => 'Other ways you can help (optional)';

  @override
  String get volOtherHint => 'Write any talents or resources not listed above';

  @override
  String get volPiano => 'Piano';

  @override
  String get volGuitar => 'Guitar';

  @override
  String get volBass => 'Bass';

  @override
  String get volDrums => 'Drums';

  @override
  String get volViolin => 'Violin';

  @override
  String get volWorshipLead => 'Worship leading';

  @override
  String get volVocals => 'Vocals';

  @override
  String get volTranslation => 'Interpretation/Translation';

  @override
  String get volPhotography => 'Photo/Video';

  @override
  String get volSound => 'Sound';

  @override
  String get volDesign => 'Design';

  @override
  String get volIt => 'IT/Tech';

  @override
  String get volChildcare => 'Childcare';

  @override
  String get volCooking => 'Cooking/Kitchen';

  @override
  String get volDriving => 'Driving';

  @override
  String get volMedical => 'Medical/First aid';

  @override
  String get summaryTitle => 'Registration summary';

  @override
  String get summarySectionProgram => 'Program';

  @override
  String get summaryName => 'Name';

  @override
  String get summaryLocation => 'Location';

  @override
  String get summaryPeriod => 'Dates';

  @override
  String get summaryCountry => 'Country';

  @override
  String get summaryBranch => 'Branch';

  @override
  String get summaryRealName => 'Real name';

  @override
  String get summaryBibleName => 'Bible name';

  @override
  String get summaryAge => 'Age';

  @override
  String get summaryFlightNo => 'Flight';

  @override
  String get summaryArrAirport => 'Arrival airport';

  @override
  String get summaryArrTime => 'Arrival time';

  @override
  String get summaryDepAirport => 'Departure airport';

  @override
  String get summaryDepTime => 'Departure time';

  @override
  String get summarySectionFood => 'Dietary needs';

  @override
  String get summarySectionOptions => 'Selected programs';

  @override
  String get summarySectionRoommate => 'Roommate preference';

  @override
  String get summaryTotalCost => 'Total payment';

  @override
  String get summaryNoPaidOptions => 'No paid options selected';

  @override
  String get summaryViewImmigration => 'View immigration card';

  @override
  String get summarySubmit => 'Submit';

  @override
  String get summaryEditBtn => 'Edit';

  @override
  String get summarySubmitConfirm =>
      'Do you want to submit your registration?\nEditing may be restricted after submission.';

  @override
  String get summarySubmitDone => 'Submitted';

  @override
  String get summarySubmitDoneMsg =>
      'Your registration was submitted successfully.\nAn organizer will contact you after review.';

  @override
  String summarySubmitFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String get commonNoName => 'No name';

  @override
  String unitPeople(int count) {
    return '$count people';
  }

  @override
  String unitCases(int count) {
    return '$count';
  }

  @override
  String get dashTitle => 'Dashboard';

  @override
  String get dashExport => 'Export';

  @override
  String get dashExportExcel => 'Export to Excel';

  @override
  String get dashExportCsv => 'Export to CSV';

  @override
  String get dashEditSettings => 'Edit program settings';

  @override
  String get dashSetupSubtitle =>
      'Define rooms and Bible study groups (pre-assignment step)';

  @override
  String get dashPendingPayments => 'Payments to confirm';

  @override
  String get dashViewAll => 'View all';

  @override
  String get dashNoPendingPayments => 'No payments awaiting confirmation';

  @override
  String get dashAttendeeList => 'Participants';

  @override
  String get dashNoAttendees => 'No participants registered yet';

  @override
  String get dashSendNotice => 'Send group announcement';

  @override
  String get dashNoStats => 'No statistics';

  @override
  String get dashStatTotal => 'Total registered';

  @override
  String get dashStatSubmitted => 'Completed';

  @override
  String get dashStatFoodRestriction => 'Dietary needs';

  @override
  String get dashStatPendingPayment => 'Payment pending';

  @override
  String get dashStatArrival => 'Arrival flights';

  @override
  String get dashStatConfirmedPayment => 'Payment confirmed';

  @override
  String get dashPaymentPending => 'Awaiting confirmation';

  @override
  String get dashStatusDone => 'Done';

  @override
  String get dashStatusInProgress => 'In progress';

  @override
  String get pcTitle => 'Program created';

  @override
  String get pcHeading => 'Your program has been created!';

  @override
  String get pcShareUuid => 'Share the UUID below with participants';

  @override
  String get pcCopy => 'Copy';

  @override
  String get pcCopied => 'UUID copied';

  @override
  String get pcInfo =>
      'Participants can register by entering this UUID in the app.';

  @override
  String get pcGoDashboard => 'Go to dashboard';

  @override
  String get pcGoHome => 'Home';

  @override
  String get cpProgramType => 'Program type';

  @override
  String get cpTypeLocal => 'Local retreat';

  @override
  String get cpTypeInternational => 'International retreat';

  @override
  String get cpLocalNote =>
      'Local retreat: flight and tour sections are disabled automatically';

  @override
  String get cpBasicInfo => 'Basic info';

  @override
  String get cpNameLabel => 'Program name *';

  @override
  String get cpNameHint => 'e.g. 2025 Summer Retreat';

  @override
  String get cpNameRequired => 'Please enter a program name';

  @override
  String get cpLocationLabel => 'Location *';

  @override
  String get cpLocationHint => 'e.g. Jeju International Convention Center';

  @override
  String get cpLocationRequired => 'Please enter a location';

  @override
  String get cpStartDate => 'Select start date';

  @override
  String get cpEndDate => 'Select end date';

  @override
  String get cpPeriod => 'Select period (start ~ end)';

  @override
  String get cpHostCountry => 'Host country';

  @override
  String get cpHostCountryHint => 'Search and select a country';

  @override
  String get cpHostCountryHelp =>
      'Participants living in the host country skip flight input';

  @override
  String get cpImmigrationInfo => 'Immigration guide info';

  @override
  String get cpImmigrationDesc =>
      'Info participants can show to an immigration officer on arrival (optional)';

  @override
  String get cpNearestAirport => 'Nearest airport';

  @override
  String get cpAirportHint => 'e.g. Incheon Intl (ICN)';

  @override
  String get cpContacts => 'On-site contacts (2)';

  @override
  String get cpName1 => 'Name 1';

  @override
  String get cpName1Hint => 'John Doe';

  @override
  String get cpPhone1 => 'Phone 1';

  @override
  String get cpName2 => 'Name 2';

  @override
  String get cpName2Hint => 'Jane Doe';

  @override
  String get cpPhone2 => 'Phone 2';

  @override
  String get cpSectionsTitle => 'Enable registration sections';

  @override
  String get cpSectionsDesc => 'Choose which items participants will see';

  @override
  String get cpSecVolunteer =>
      'Program help resources (instruments, translation, etc.)';

  @override
  String get cpSpecialOptions => 'Special programs / tour options';

  @override
  String get cpOptionsDesc =>
      'Set a cost per option so participants can choose';

  @override
  String cpOptionCost(String value) {
    return 'Cost: $value';
  }

  @override
  String get cpOptionName => 'Option name';

  @override
  String get cpOptionNameHint => 'Jeju Tour Course A';

  @override
  String get cpOptionCostLabel => 'Cost';

  @override
  String get cpCreateButton => 'Create program (issue UUID)';

  @override
  String get cpDupTitle => 'Program already exists';

  @override
  String get cpDupBody =>
      'A program with the same name and start date already exists.\nGo to the existing program\'s UUID screen?';

  @override
  String get cpDupGoExisting => 'Go to existing program';

  @override
  String cpCreateFailed(String error) {
    return 'Failed to create program: $error';
  }

  @override
  String get epSaved => 'Settings saved';

  @override
  String get epNotFound => 'Program not found';

  @override
  String get epTourLocked =>
      'The retreat has already started, so tour options cannot be edited';

  @override
  String epOptionContact(String value) {
    return 'Contact: $value';
  }

  @override
  String get epAddOption => 'Add option';

  @override
  String get epEditOption => 'Edit option';

  @override
  String get epSaveChanges => 'Save changes';

  @override
  String get epOptionNameReq => 'Option name *';

  @override
  String get epOptionCostNum => 'Cost (number)';

  @override
  String get epOptionContactName => 'Contact name';

  @override
  String get epOptionDesc => 'Description (optional)';

  @override
  String get epPickDate => 'Select date';

  @override
  String epPhotos(int count) {
    return 'Photos ($count/5)';
  }

  @override
  String get blTitle => 'Register as leader';

  @override
  String get blInfo =>
      'Registering as a leader lets you create retreat programs and manage participants.';

  @override
  String get blLoginAccount => 'Signed-in account';

  @override
  String get blLeaderName => 'Leader name *';

  @override
  String get blLeaderNameHint => 'Name shown to participants';

  @override
  String get blRegisterButton => 'Register and create an event';

  @override
  String blLeaderRegFailed(String error) {
    return 'Leader registration failed: $error';
  }

  @override
  String get sosTitle => 'Emergency SOS';

  @override
  String get sosHealth => '🚑 Health/Medical emergency';

  @override
  String get sosSafety => '🆘 Personal safety threat';

  @override
  String get sosLost => '🗺️ I\'m lost';

  @override
  String get sosGpsOff => 'GPS is off. Please enable it in settings.';

  @override
  String get sosPermDenied =>
      'Location permission denied. Sending SOS without location.';

  @override
  String sosLocationError(String error) {
    return 'Could not get location: $error';
  }

  @override
  String get sosSentTitle => 'SOS sent';

  @override
  String get sosSentMsg =>
      'An emergency alert has been sent to the organizers.\nPlease wait a moment.';

  @override
  String sosSendFailed(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get sosBanner =>
      'An alert is sent to organizers immediately.\nUse only in an emergency.';

  @override
  String get sosSelectType => 'Select the type of situation';

  @override
  String get sosMessageLabel => 'Additional message (optional)';

  @override
  String get sosMessageHint => 'Briefly describe your current situation';

  @override
  String sosGpsConfirmed(String value) {
    return 'GPS location confirmed $value';
  }

  @override
  String get sosGpsChecking => 'Checking GPS location...';

  @override
  String get sosSending => 'Sending...';

  @override
  String get sosSend => 'Send SOS';

  @override
  String get sosFabConfirm => 'Send an emergency alert to the organizers?';

  @override
  String schLoadFailed(String error) {
    return 'Failed to load schedule: $error';
  }

  @override
  String get schAddTitle => 'Add event';

  @override
  String get schTitleLabel => 'Title *';

  @override
  String get schTitleHint => 'Opening worship';

  @override
  String get schDescLabel => 'Description (optional)';

  @override
  String get schPickTime => 'Select time';

  @override
  String get schTimezone => 'Time zone';

  @override
  String get schTzAuto => 'Set automatically to your device time zone';

  @override
  String get schTzReset => 'Reset to device time zone';

  @override
  String get schAllRequired => 'Please enter title, date, and time';

  @override
  String schAddFailed(String error) {
    return 'Failed to add: $error';
  }

  @override
  String get schTzChangeTitle => 'Change time zone';

  @override
  String get schTzUseDevice => 'Use my device time zone';

  @override
  String get schTzExamples =>
      'e.g. Asia/Seoul, America/New_York, Europe/London';

  @override
  String schTzChangeFailed(String error) {
    return 'Failed to change time zone: $error';
  }

  @override
  String get schDeleteTitle => 'Delete event';

  @override
  String get schDeleteConfirm => 'Delete this event?';

  @override
  String schDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get schEmpty => 'No events scheduled';

  @override
  String get immTitle => 'Immigration guide card';

  @override
  String get immFullscreenTooltip => 'Fullscreen (show to officer)';

  @override
  String get immNotFound => 'Program information not found.';

  @override
  String get immBanner =>
      'Tap the fullscreen button at the top right to show it to the officer.';

  @override
  String get immCardPurpose => 'PURPOSE OF VISIT';

  @override
  String get immCardConference => 'Religious Conference';

  @override
  String get immCardVenue => 'VENUE';

  @override
  String get immCardDate => 'DATE';

  @override
  String get immCardAirport => 'NEAREST AIRPORT';

  @override
  String get immCardContact => 'ON-SITE CONTACT';

  @override
  String get immCardFooter =>
      'I am attending the above religious conference as a participant.';

  @override
  String get immExitHint => 'Tap anywhere to exit fullscreen';

  @override
  String setupRoomsMade(int count) {
    return 'Rooms created · $count';
  }

  @override
  String get setupRoomsEmpty =>
      'No rooms yet.\nUse the button at the bottom right to bulk-add rooms.';

  @override
  String get setupBulkAddRooms => 'Bulk-add rooms';

  @override
  String setupRoomsAdded(int count) {
    return 'Added $count rooms';
  }

  @override
  String get setupReconcileTitle => 'Registered vs capacity';

  @override
  String get setupMale => 'Male';

  @override
  String get setupFemale => 'Female';

  @override
  String setupMixedSeats(int count) {
    return 'Couple/family rooms: $count beds (assigned by family)';
  }

  @override
  String setupRegVsSeats(int regs, int seats) {
    return 'Registered $regs · Capacity $seats';
  }

  @override
  String setupSeatShortage(int count) {
    return '$count beds short';
  }

  @override
  String setupRoomCapacity(int count) {
    return '$count-person';
  }

  @override
  String get setupCouple => 'Couple room';

  @override
  String get setupCoupleSub => '2 ppl · mixed';

  @override
  String get setupFamily => 'Family room';

  @override
  String get setupFamilySub => '3–4 ppl · mixed';

  @override
  String get setupDorm => 'Dormitory';

  @override
  String get setupDormSub => '5+ · single gender';

  @override
  String get setupMixed => 'Family (mixed)';

  @override
  String get setupRoomType => 'Room type';

  @override
  String get setupNameRule => 'Name pattern';

  @override
  String get setupNameRuleHint => 'e.g. 3F 3##';

  @override
  String get setupStartNum => 'Start#';

  @override
  String get setupCount => 'Count';

  @override
  String get setupCapacity => 'Capacity';

  @override
  String get setupFloor => 'Floor (optional)';

  @override
  String get setupMixedNotAllowed => 'Mixed not allowed';

  @override
  String get setupFamilyAuto => 'Family unit (mixed) — automatic';

  @override
  String get setupBulkValidation =>
      'Please check the name pattern, count, and capacity';

  @override
  String setupGroupsMade(int count) {
    return 'Groups created · $count';
  }

  @override
  String get setupGroupsEmpty =>
      'No groups yet.\nUse the button at the bottom right to create groups.';

  @override
  String get setupMakeGroups => 'Create groups';

  @override
  String get setupMakeGroupsPrompt =>
      'How many groups? (Group 1, Group 2 … auto-generated)';

  @override
  String get setupGroupCount => 'Number of groups';

  @override
  String get setupGroupCountSuffix => '';

  @override
  String get setupMake => 'Create';

  @override
  String setupGroupsCreated(int count) {
    return 'Created $count groups';
  }

  @override
  String get setupMakeGroupsFirst => 'Please create groups first';

  @override
  String setupEvenPerGroup(int count) {
    return 'About $count per group, evenly';
  }

  @override
  String setupUnevenPerGroup(int remCount, int bigger, int base) {
    return '$remCount groups have $bigger, the rest have $base';
  }

  @override
  String get setupGroupSummary => 'Group summary';

  @override
  String setupRegAndGroups(int total, int groups) {
    return '$total registered · $groups groups';
  }

  @override
  String setupBalancePreview(String preview) {
    return 'With age/gender balance — $preview';
  }

  @override
  String setupLeaderless(int count) {
    return '$count without a leader';
  }

  @override
  String get setupNoPassageLocation => 'No passage/location set';

  @override
  String get setupNoLeader => 'No leader assigned';

  @override
  String get setupEditGroupMenu => 'Edit leader/passage/location';

  @override
  String setupEditGroupTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get setupGroupName => 'Group name';

  @override
  String get setupLeaderName => 'Leader (shepherd) name';

  @override
  String get setupLeaderPhone => 'Leader phone';

  @override
  String get setupPassage => 'Passage (e.g. John 10)';

  @override
  String get setupLocation => 'Meeting place';

  @override
  String get expColNo => 'No.';

  @override
  String get expArrFlight => 'Arrival flight';

  @override
  String get expArrTime => 'Arrival time';

  @override
  String get expDepFlight => 'Departure flight';

  @override
  String get expDepTime => 'Departure time';

  @override
  String get expOptions => 'Selected options';

  @override
  String get expTotalCost => 'Total cost';

  @override
  String get expPaymentStatus => 'Payment status';

  @override
  String get expSubmittedCol => 'Registration complete';

  @override
  String get expUnregistered => 'Not registered';

  @override
  String get expIncomplete => 'Incomplete';

  @override
  String get expRoster => 'Participant roster';

  @override
  String get regStepCompanion => 'Companions';

  @override
  String get regStepBuddy => 'Buddy requests';

  @override
  String get buddyTitle => 'People you\'d like to be with';

  @override
  String get buddyDesc =>
      'When you pick someone, a request is sent. It\'s confirmed only when they accept.';

  @override
  String get buddyRoommateSection => 'Roommate requests';

  @override
  String get buddyGroupSection => 'Bible study group requests';

  @override
  String get buddySearchHint => 'Search by name or Bible name…';

  @override
  String get buddySendRoommate => 'Request as roommate';

  @override
  String get buddySendGroup => 'Request same group';

  @override
  String get buddySentSection => 'Requests you sent';

  @override
  String get buddyReceivedSection => 'Requests you received';

  @override
  String get buddyStatusPending => 'Pending';

  @override
  String get buddyStatusAccepted => 'Accepted';

  @override
  String get buddyStatusDeclined => 'Declined';

  @override
  String get buddyAccept => 'Accept';

  @override
  String get buddyDecline => 'Decline';

  @override
  String get buddyKindRoommate => 'Roommate';

  @override
  String get buddyKindGroup => 'Group';

  @override
  String get buddyReqSent => 'Request sent';

  @override
  String get buddyRoommateSameGenderNote =>
      'Roommate requests can only be sent to the same gender.';

  @override
  String get buddyReceivedEmpty => 'No requests received';

  @override
  String get buddyNoCandidates => 'No other participants to pick yet';

  @override
  String buddyRequestLine(String kind) {
    return '$kind request';
  }

  @override
  String get companionTitle => 'Companions (couple/family)';

  @override
  String get companionDesc =>
      'If you\'re coming with a spouse or family, add them here. Each counts toward headcount and pickup.';

  @override
  String get companionAdd => 'Add companion';

  @override
  String get companionEmpty => 'Leave empty if you\'re attending alone.';

  @override
  String get companionLanguage => 'Language';

  @override
  String get companionSameFlight => 'Same flight as me';

  @override
  String get companionArrivalFlightNo => 'Companion\'s arrival flight';

  @override
  String get companionDepartureFlightNo => 'Companion\'s departure flight';

  @override
  String get companionNeedsPickup => 'Needs pickup';

  @override
  String companionCount(int count) {
    return '$count companion(s)';
  }

  @override
  String get companionAddTitle => 'Add companion';

  @override
  String get companionEditTitle => 'Edit companion';

  @override
  String get asnTitle => 'Assignment';

  @override
  String get asnAutoAssign => 'Auto-assign';

  @override
  String asnAutoRoomsDone(int count) {
    return 'Rooms auto-assigned — $count placed';
  }

  @override
  String asnAutoGroupsDone(int count) {
    return 'Groups auto-assigned — $count placed';
  }

  @override
  String asnUnplaced(int count) {
    return '$count could not be placed';
  }

  @override
  String get asnUnassigned => 'Unassigned';

  @override
  String asnUnassignedCount(int count) {
    return '$count unassigned';
  }

  @override
  String get asnPickRoom => 'Choose a room';

  @override
  String get asnPickGroup => 'Choose a group';

  @override
  String get asnNoRooms => 'Create rooms in Setup first';

  @override
  String get asnNoGroups => 'Create groups in Setup first';

  @override
  String get asnAllAssigned => 'Everyone is assigned';

  @override
  String get dashAssignSubtitle => 'Assign rooms and Bible study groups';
}
