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
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'Use device language';

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
    return 'Photos ($count/6)';
  }

  @override
  String get epPhotoUrlTitle => 'Add photo URL';

  @override
  String get epPhotoUrlLabel => 'Image URL';

  @override
  String get epCapacity => 'Capacity';

  @override
  String get epSignupDeadline => 'Signup deadline';

  @override
  String get epBrochureUrl => 'Brochure link';

  @override
  String get epVideoUrl => 'Intro video link';

  @override
  String get tourCapacityLabel => 'Spots remaining';

  @override
  String tourRemaining(int remaining, int capacity) {
    return '$remaining / $capacity';
  }

  @override
  String get tourFull => 'Full';

  @override
  String get tourClosed => 'Closed';

  @override
  String tourDeadline(String date) {
    return 'Deadline: $date';
  }

  @override
  String get linkCopied => 'Link copied';

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
      'Roommate requests can only be sent to the same gender, or to family travelling with you.';

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

  @override
  String get dashDispatchSubtitle => 'Driver roster and auto van dispatch';

  @override
  String get dspTitle => 'Transport';

  @override
  String get dspTabArrival => 'Arrival pickup';

  @override
  String get dspTabDeparture => 'Departure drop-off';

  @override
  String get dspAddVan => 'Add van';

  @override
  String get dspAutoDispatch => 'Auto dispatch';

  @override
  String get dspNoRuns => 'Register a van (driver & capacity) first';

  @override
  String dspAutoDone(int assigned, int unassigned) {
    return '$assigned assigned · $unassigned unassigned';
  }

  @override
  String dspUnassignedCount(int count) {
    return 'Unassigned $count';
  }

  @override
  String get dspAllAssigned => 'Everyone is assigned';

  @override
  String get dspPickVan => 'Choose a van';

  @override
  String get dspDriverUnset => 'No driver';

  @override
  String get dspNewVan => 'New van';

  @override
  String get dspEditVan => 'Edit van';

  @override
  String get dspAirport => 'Airport';

  @override
  String get dspVehicle => 'Vehicle';

  @override
  String get dspDriverName => 'Driver name';

  @override
  String get dspDriverPhone => 'Driver phone';

  @override
  String get dspCapacityLabel => 'Capacity';

  @override
  String get dspMeetPoint => 'Meeting point';

  @override
  String get dspDeleteVan => 'Delete van';

  @override
  String get mtrTitle => 'My transport';

  @override
  String get mtrArrival => 'Arrival pickup';

  @override
  String get mtrDeparture => 'Departure drop-off';

  @override
  String mtrArrivalRoute(String airport) {
    return '$airport → Venue';
  }

  @override
  String mtrDepartureRoute(String airport) {
    return 'Venue → $airport';
  }

  @override
  String get mtrPending => 'Transport will be arranged soon';

  @override
  String get mtrAssigned => 'Assigned';

  @override
  String get mtrPendingBadge => 'Pending';

  @override
  String get mtrVehicle => 'Vehicle';

  @override
  String get mtrDriver => 'Driver';

  @override
  String get mtrCoPassengers => 'With';

  @override
  String get mtrMeetPoint => 'Meeting point';

  @override
  String get mtrSelfDrive => 'I\'ll drive myself';

  @override
  String get mtrSelfDriveDesc => 'Turn off if you don\'t need pickup';

  @override
  String get mtrHostCountryTitle => 'No airport pickup for you';

  @override
  String get mtrHostCountryDesc =>
      'You are attending from the host country, so you are not on the airport pickup list. Flying in? Add your flight to your registration and you will be included.';

  @override
  String get rdyTitle => 'Readiness';

  @override
  String get rdySubtitle => 'What is blocked and who to contact';

  @override
  String get rdySectionItems => 'Readiness items';

  @override
  String get rdySectionCohorts => 'Domestic and overseas attendees';

  @override
  String get rdySectionBlocked => 'People to contact';

  @override
  String get rdyLodging => 'Lodging';

  @override
  String get rdyTransport => 'Pickup vans';

  @override
  String get rdyFlights => 'Missing flights';

  @override
  String get rdyMeals => 'Meals';

  @override
  String get rdyPayment => 'Fees';

  @override
  String get rdyRoles => 'Church roles';

  @override
  String get rdyDomestic => 'Domestic';

  @override
  String get rdyOverseas => 'Overseas';

  @override
  String get rdySkipped => 'Skipped';

  @override
  String get rdyUnspecified => 'Unspecified';

  @override
  String get rdyStuckPersonal => 'Personal info';

  @override
  String get rdyStuckMeals => 'Meals';

  @override
  String get rdyStuckFlight => 'Flight';

  @override
  String get rdyStuckLodging => 'Lodging';

  @override
  String get rdyStuckPayment => 'Fees';

  @override
  String get rdyStatusOk => 'OK';

  @override
  String get rdyStatusWarn => 'Attention';

  @override
  String get rdyStatusStop => 'Short';

  @override
  String get rdyStatusIdle => 'Not set';

  @override
  String get rdyNoBlocked => 'Everyone is on track';

  @override
  String get rdyRolesUnreliable => 'More than half have no role recorded';

  @override
  String get rdyOpenCard => 'View readiness';

  @override
  String get rdyOpenCardSub => 'Blockers and who to contact at a glance';

  @override
  String get privacyTitle => 'How your information is used';

  @override
  String get privacySummary =>
      'What you enter here is used only to run the conference.';

  @override
  String get privacyWhatTitle => 'What we collect';

  @override
  String get privacyWhat =>
      'Name, Bible name, gender, age, country of residence and chapter; flight details; dietary restrictions; medical conditions; roommate preference; payment status. If you use SOS, your location at that moment is sent as well.';

  @override
  String get privacyWhyTitle => 'Why';

  @override
  String get privacyWhy =>
      'To assign rooms and groups, arrange airport pickup, prepare meals, and respond to emergencies. Nothing else.';

  @override
  String get privacyWhoTitle => 'Who can see it';

  @override
  String get privacyWho =>
      'Conference organizers. Other participants see only what you choose to share through QR sharing — your verse, prayer topics and the contacts you switch on. Medical information is never shared with participants; it is not shown in lists, an organizer opens it per person when needed, and that access is logged.';

  @override
  String get privacyWhereTitle => 'Where it is stored';

  @override
  String get privacyWhere =>
      'Data is stored in a cloud database located in the United States. This means it leaves your country of residence.';

  @override
  String get privacyKeepTitle => 'How long';

  @override
  String get privacyKeep =>
      'Kept for up to one year after the conference ends, then deleted.';

  @override
  String get privacyRightsTitle => 'Your choices';

  @override
  String get privacyRights =>
      'You can change what you entered at any time. For QR sharing you can switch each item off, cut off anyone who saved your card, or make a new QR so old codes stop working. To have your data deleted, ask an organizer.';

  @override
  String get privacyAgree => 'I have read this';

  @override
  String get privacyMore => 'Read more';

  @override
  String get privacyLess => 'Show less';

  @override
  String get regStepFee => 'Fee';

  @override
  String get feePrompt => 'Choose a fee tier.';

  @override
  String get feeTierBasic => 'Standard';

  @override
  String get feeTierPremium => 'Premium';

  @override
  String get feeNotSet => 'The fee has not been set yet.';

  @override
  String get discountTitle => 'Discount request';

  @override
  String get discountPrompt => 'If one of these applies to you, choose it.';

  @override
  String get discountNone => 'No discount request';

  @override
  String get discountReasonLabel => 'Additional note (optional)';

  @override
  String get discountReasonHint => 'Anything the organizers should know';

  @override
  String get discountStatusPending => 'Waiting for the organizers to review.';

  @override
  String discountStatusApproved(String amount) {
    return 'Approved — $amount off';
  }

  @override
  String get discountStatusRejected => 'Not approved.';

  @override
  String discountAdminNote(String note) {
    return 'Organizer note: $note';
  }

  @override
  String get cohortSection => 'Bible study teams';

  @override
  String get cohortHint =>
      'Teams are split by language first, then by age. Adulto 20+ · Junior 19 and under.';

  @override
  String get cohortMinSize => 'Minimum team size';

  @override
  String get cohortKeep => 'Leave as is';

  @override
  String get cohortKeepSub =>
      'If no team fits, they stay unassigned for you to place';

  @override
  String get cohortAbsorb => 'Move up to the Adulto team in the same language';

  @override
  String get cohortAbsorbSub => 'Keeps everyone in a language they share';

  @override
  String get cohortMerge => 'Merge with the same age band in another language';

  @override
  String get cohortMergeSub => 'Keeps them with people their own age';

  @override
  String get studyLangTitle => 'Which language will you study in?';

  @override
  String get studyLangBody => 'Bible study teams are formed by this language.';

  @override
  String get studyLangNote =>
      'You can change this later from your registration.';

  @override
  String get regStepStudyLang => 'Bible study';

  @override
  String get discountNoOptions =>
      'This conference does not offer discount requests.';

  @override
  String discountDomesticOnly(String country) {
    return 'Discounts can only be requested by attendees coming from $country.';
  }

  @override
  String get cpFeeSection => 'Fee';

  @override
  String get cpFeeBasic => 'Standard fee';

  @override
  String get cpFeePremium => 'Premium fee';

  @override
  String get cpFeeBasicDesc => 'What the standard fee covers';

  @override
  String get cpFeePremiumDesc => 'What the premium fee covers';

  @override
  String get cpFeeHint => 'Leave empty if you do not offer that tier.';

  @override
  String get cpFeeInvalid => 'Enter a number of 0 or more.';

  @override
  String get cpDiscountSection => 'Discount options';

  @override
  String get cpDiscountHint =>
      'Reasons attendees can pick when asking for a discount — for example \"Attending one day only\".';

  @override
  String get cpDiscountLabel => 'Wording shown to attendees';

  @override
  String get cpDiscountAmount => 'Discount amount (optional)';

  @override
  String get cpDiscountAmountHint => 'Leave empty to decide case by case.';

  @override
  String get cpDiscountAdd => 'Add discount option';

  @override
  String get cpDiscountRemove => 'Remove';

  @override
  String get cpDiscountEmpty => 'No discount options yet.';

  @override
  String get adDiscountTitle => 'Discount requests';

  @override
  String get adDiscountNone => 'No discount requests.';

  @override
  String get adDiscountApprove => 'Approve';

  @override
  String get adDiscountReject => 'Reject';

  @override
  String get adDiscountAmount => 'Discount amount';

  @override
  String get adDiscountNote => 'Note (optional)';

  @override
  String get adDiscountAmountReq => 'An amount is required to approve.';

  @override
  String get adDiscountSaved => 'Saved.';

  @override
  String get adDiscountPending => 'Pending';

  @override
  String get adDiscountApproved => 'Approved';

  @override
  String get adDiscountRejected => 'Rejected';

  @override
  String get myProgramsTitle => 'My programs';

  @override
  String get myProgramsEmpty =>
      'You have not created any conference yet.\nTap the button below to create one.';

  @override
  String get myProgramsEdit => 'Edit';

  @override
  String myProgramsRegistered(int count) {
    return '$count registered';
  }

  @override
  String get cpCurrency => 'Currency';

  @override
  String get cpCurrencyHint =>
      'All attendees of this conference see amounts in this currency. No exchange-rate conversion is applied.';

  @override
  String cpCurrencyFixed(String code) {
    return 'International conferences are priced in $code. Attendees come from many countries, so the currency is the same for everyone.';
  }

  @override
  String get flightNotBookedYet => 'I haven\'t booked my flight yet';

  @override
  String get flightNotBookedYetHint =>
      'Just put the date you expect. You can add the flight later.';

  @override
  String get flightEstimatedNotice =>
      'This is recorded as an estimate, not a confirmed flight. Please come back and add the flight once you book it.';

  @override
  String get expFlightEstimated => '(estimate — not booked)';

  @override
  String get buddyFamilyTitle => 'Are you travelling together?';

  @override
  String get buddyFamilyBody =>
      'This person is a different gender. Rooms are same-gender by default; you can share only if you are family travelling together (spouse, parent and child, and so on). They still have to accept.';

  @override
  String get buddyFamilyConfirm => 'Yes, we are family';

  @override
  String get myProgramsDelete => 'Delete';

  @override
  String get myProgramsDeleteTitle => 'Delete this conference?';

  @override
  String myProgramsDeleteBody(String name) {
    return '\"$name\" will no longer appear to anyone. Registrations and assignments are kept, so ask an administrator if you need it back.';
  }

  @override
  String myProgramsDeleteHasRegistrations(int count) {
    return '$count people have already registered. Type the conference name to confirm.';
  }

  @override
  String get myProgramsDeleteTypeName => 'Conference name';

  @override
  String get myProgramsDeleted => 'Deleted.';

  @override
  String get mealsTitle => 'Dietary restrictions';

  @override
  String get mealsSubtitle => 'Who cannot eat what — for the kitchen';

  @override
  String get mealsEmpty => 'Nobody has reported a dietary restriction.';

  @override
  String get mealsRestriction => 'Cannot eat / notes';

  @override
  String get mealsSkipsBreakfast => 'skips breakfast';

  @override
  String mealsSummary(int restricted, int total) {
    return '$restricted of $total attendees';
  }

  @override
  String mealsPdfSummary(int restricted, int total) {
    return '$restricted of $total registered attendees reported a dietary restriction.';
  }

  @override
  String get mealsPdfNote =>
      'Compiled from what attendees entered themselves. Confirm with the person before assuming an allergy is mild.';

  @override
  String get mealsDownloadPdf => 'Download PDF';

  @override
  String get mealsHint => 'Double-tap to see who cannot eat what';

  @override
  String get mealsNotSubmitted => 'not submitted';

  @override
  String mealsDownloadFailed(String detail) {
    return 'Could not save the PDF: $detail';
  }

  @override
  String get regStepHotel => 'Hotel';

  @override
  String get hotelTitle => 'Staying before or after?';

  @override
  String get hotelBody =>
      'If you arrive early or stay on after the tour, you will need a hotel. Pick the level you want and how many nights.';

  @override
  String get hotelNoOptions =>
      'The organisers have not set hotel levels yet. You can come back to this later.';

  @override
  String get hotelNone => 'I don\'t need a hotel';

  @override
  String hotelPerNight(String amount) {
    return '$amount / night';
  }

  @override
  String get hotelPriceTbd => 'To be announced';

  @override
  String get hotelNightsBefore => 'Nights before the conference';

  @override
  String get hotelNightsAfter => 'Nights after the tour';

  @override
  String hotelNightsCount(int count) {
    return '$count';
  }

  @override
  String get hotelEstimate => 'Estimated hotel cost';

  @override
  String get hotelNotInFee =>
      'Not included in your conference fee. You settle this separately.';

  @override
  String get hotelSectionTitle => 'Hotel levels (before / after)';

  @override
  String get hotelSectionHelp =>
      'Only attendees coming from abroad see these. They pick a level and the number of nights.';

  @override
  String get hotelLevelKo => 'Level (Korean)';

  @override
  String get hotelLevelEn => 'Level (English)';

  @override
  String get hotelLevelEs => 'Level (Spanish)';

  @override
  String get hotelPricePerNightLabel => 'Price per night';

  @override
  String get hotelAddLevel => 'Add level';

  @override
  String get hotelNoLevelsYet => 'No levels added yet';

  @override
  String get summarySectionHotel => 'Hotel before / after';

  @override
  String summaryHotelNights(int before, int after) {
    return '$before night(s) before · $after night(s) after';
  }

  @override
  String hotelComputed(int before, int after) {
    return 'You need $before night(s) before the conference and $after night(s) after.';
  }

  @override
  String hotelComputedBeforeOnly(int before) {
    return 'You need $before night(s) before the conference. We could not work out the nights after — your return flight is not entered yet.';
  }

  @override
  String hotelComputedAfterOnly(int after) {
    return 'You need $after night(s) after. We could not work out the nights before — your arrival flight is not entered yet.';
  }

  @override
  String get hotelComputedNone =>
      'Your flights arrive and leave within the conference, so you do not need a hotel around it.';

  @override
  String get hotelNoFlightYet =>
      'Enter your flights and we will work out how many nights you need. You can also set them yourself below.';

  @override
  String get hotelPickPrompt => 'Please choose the option you want:';

  @override
  String get hotelAdjustHint =>
      'Counted from your flights and the conference dates. Adjust below if it is wrong.';

  @override
  String get hotelRecalc => 'Recalculate from my flights';

  @override
  String get pcInviteLink => 'Invite link';

  @override
  String get pcInviteLinkHelp =>
      'Send this instead of the UUID. Opening it takes the person straight to this conference — no code to type in.';

  @override
  String get pcCopyLink => 'Copy link';

  @override
  String get pcLinkCopied => 'Invite link copied';

  @override
  String get tgSectionTitle => 'Telegram notifications';

  @override
  String get tgSectionHelp =>
      'New sign-ups and edits for this conference are sent to your Telegram. Leave blank to use the default bot.';

  @override
  String get tgBotToken => 'Bot token';

  @override
  String get tgBotTokenHint => '123456789:AA…  (from @BotFather)';

  @override
  String get tgChatId => 'Chat ID';

  @override
  String get tgChatIdHint => 'e.g. -1001234567890 (group) or your user ID';

  @override
  String get tgConfigured => 'A bot is set for this conference';

  @override
  String get tgTokenHidden =>
      'The saved token is never shown again. Leave blank to keep it; type a new one to replace it.';

  @override
  String get tgClearToken => 'Remove the bot';

  @override
  String get tgInvalidToken =>
      'That does not look like a bot token (e.g. 123456789:AA…)';

  @override
  String get tgHowTo =>
      'In Telegram, talk to @BotFather → /newbot → copy the token. Add the bot to your group and use that group\'s chat ID.';

  @override
  String get hotelLevelPt => 'Level (Portuguese)';

  @override
  String get libTitle => 'Library';

  @override
  String get libSubtitle =>
      'Materials shared during the conference — open them any time';

  @override
  String get libEmpty => 'No materials yet.';

  @override
  String get libEmptyAdmin =>
      'No materials yet. Use the button below to add a PDF.';

  @override
  String get libOpen => 'Open';

  @override
  String get libAdd => 'Add material';

  @override
  String get libPickPdf => 'Choose a PDF';

  @override
  String get libPickOnWeb =>
      'PDFs can be added from a computer browser. Open ubf.coolsistema.com and sign in there.';

  @override
  String get libItemTitle => 'Title';

  @override
  String get libItemTitleHint => 'e.g. Lesson 1 — John 10';

  @override
  String get libItemDesc => 'Note (optional)';

  @override
  String get libPublished => 'Visible to participants';

  @override
  String get libHidden => 'Hidden';

  @override
  String get libUploading => 'Uploading…';

  @override
  String libUploadFailed(String detail) {
    return 'Upload failed: $detail';
  }

  @override
  String get libDeleteTitle => 'Delete this material?';

  @override
  String libDeleteBody(String title) {
    return '\"$title\" will be removed for everyone, and the file is deleted.';
  }

  @override
  String libSize(int kb) {
    return '$kb KB';
  }

  @override
  String libOpenFailed(String detail) {
    return 'Could not open the file: $detail';
  }

  @override
  String get libTitleRequired => 'Please enter a title';

  @override
  String get dashLibrarySubtitle => 'Share lesson PDFs with participants';

  @override
  String get homeLibrary => 'Conference library';

  @override
  String get photoPick => 'Choose from device';

  @override
  String get photoUploading => 'Uploading…';

  @override
  String photoUploadFailed(String detail) {
    return 'Could not upload the photo: $detail';
  }

  @override
  String get photoOrUrl => 'or paste an image address';

  @override
  String get cardTitle => 'My card';

  @override
  String get cardShareTitle => 'QR sharing';

  @override
  String get cardShareIntro =>
      'Swap verses, prayer topics and contacts with people you meet.';

  @override
  String get cardPhoto => 'Photo';

  @override
  String get cardChangePhoto => 'Change photo';

  @override
  String get cardVerseRef => 'Life verse';

  @override
  String get cardVerseRefHint => 'e.g. John 10:10';

  @override
  String get cardVerseText => 'Verse text (optional)';

  @override
  String get cardPrayerTopics => 'Prayer topics · up to 3';

  @override
  String get cardPrayerHint => 'One per line';

  @override
  String get cardContacts => 'Contacts — only what you turn on is shown';

  @override
  String get cardChannels => 'Channels';

  @override
  String get cardEmail => 'Email';

  @override
  String get cardWhatsapp => 'WhatsApp';

  @override
  String get cardPhone => 'Phone';

  @override
  String get cardInstagram => 'Instagram';

  @override
  String get cardX => 'X';

  @override
  String get cardYoutube => 'YouTube';

  @override
  String get cardJuniorLocked =>
      'You are 19 or under, so contact details stay off. You can still share your verse, prayer topics and channels.';

  @override
  String get cardShowQr => 'Show my QR';

  @override
  String get cardScan => 'Scan a QR';

  @override
  String get cardQrHint => 'When someone scans this, your card opens.';

  @override
  String get cardQrRotate => 'Make a new QR';

  @override
  String get cardQrRotateWarn =>
      'The old code stops working right away. People you already saved stay in your list.';

  @override
  String get cardQrRotated => 'A new QR was created';

  @override
  String get cardScanUnsupported =>
      'Scanning needs a camera. Use your phone, or open the site in a browser.';

  @override
  String get cardScanPoint => 'Point at the other person\'s QR';

  @override
  String get cardSaveFriend => 'Save as friend';

  @override
  String get cardDontSave => 'Don\'t save';

  @override
  String get cardSaved => 'Saved to your friends';

  @override
  String get cardAlreadySaved => 'Already in your friends';

  @override
  String get cardSelfScan => 'That is your own card';

  @override
  String get cardExpiredCode => 'That code has expired or does not exist';

  @override
  String get friendsTitle => 'Sharing friends';

  @override
  String get friendsEmpty =>
      'Nobody yet. Scan someone\'s QR after you have talked.';

  @override
  String get friendsSearch => 'Search by name or country…';

  @override
  String friendsMetOn(String date) {
    return 'Met on $date';
  }

  @override
  String get friendsNote => 'My note (only you see this)';

  @override
  String get friendsRemove => 'Remove from my list';

  @override
  String get friendsOtherPrograms => 'Other conferences';

  @override
  String get cardPrivacyTitle => 'Sharing settings';

  @override
  String get cardWhoCanSee => 'Who can open my card';

  @override
  String get cardVisToken => 'People who scan my QR';

  @override
  String get cardVisProgram => 'Everyone at the same conference';

  @override
  String get cardVisProgramNote =>
      'With this on, people can open your card from the participant list without a QR. It is off by default.';

  @override
  String cardSavedBy(int count) {
    return 'People who saved my card · $count';
  }

  @override
  String get cardSavedByEmpty => 'Nobody has saved your card yet.';

  @override
  String get cardRevoke => 'Cut off';

  @override
  String get cardRevokeDone => 'They can no longer see your card';

  @override
  String get cardSaveBack => 'Save them too';

  @override
  String get cardOpenWhatsapp => 'WhatsApp';

  @override
  String get cardOpenEmail => 'Email';

  @override
  String get cardNoContacts => 'This person did not share contact details.';

  @override
  String get homeQrShare => 'QR sharing';

  @override
  String get homeQrShareSub => 'Your card, your QR, and the people you met';

  @override
  String get companionSameBranch => 'Same chapter as me';

  @override
  String get companionSameBranchSub =>
      'Turn off if they belong to a different chapter';

  @override
  String get companionMustRegister =>
      'Each companion has to register on their own as well.';

  @override
  String get companionWhy =>
      'You add them here so you are placed in the same room. If it is fine for you to be placed separately, you do not need to add them.';

  @override
  String get homeAlsoAttending => 'I\'m attending too';

  @override
  String get homeAlsoAttendingSub =>
      'Register yourself, or open the registration you already filled in';

  @override
  String get homePickMyProgram => 'Go straight to one of my conferences';

  @override
  String get homeOrEnterUuid =>
      'Or enter a UUID for someone else\'s conference';

  @override
  String chapterNoticeTitle(String leader) {
    return 'Your chapter leader $leader has created a conference';
  }

  @override
  String get chapterNoticeAsk => 'Would you like to attend?';

  @override
  String get chapterNoticeJoin => 'Yes, register';

  @override
  String get chapterNoticeLater => 'Not now';

  @override
  String get cpFeeDescHint => 'e.g. shared room, 3 meals a day';

  @override
  String get cpFeeDescLooksLikeAmount =>
      'This looks like an amount. Put the number in the fee box on the left — this box is for what the fee covers.';

  @override
  String get cpFeeNoneWarning =>
      'No fee is set, so attendees never see the fee step. Leave it empty only if this conference is free.';

  @override
  String get rdyFeeTier => 'Fee tier';

  @override
  String feeBackfillTitle(int count) {
    return '$count people have not picked a fee tier';
  }

  @override
  String get feeBackfillWhy =>
      'They registered before the fee was set, so they never saw the fee step. Their total does not include the conference fee.';

  @override
  String get feeBackfillAction => 'Set them all to…';

  @override
  String feeBackfillConfirm(int count, String tier) {
    return 'Set $count people to $tier and recalculate their totals? People who already picked a tier are not touched.';
  }

  @override
  String feeBackfillDone(int count) {
    return '$count people updated';
  }

  @override
  String get feeBackfillNotSet =>
      'That tier has no amount yet. Set the fee first.';

  @override
  String get studyLangMulti => 'Pick every language you can study in';

  @override
  String get studyLangPrimary => 'Main';

  @override
  String get studyLangPrimaryNote =>
      'The first one you pick is your main language — your Bible study team is formed by it. The others help us place you when a team is too small.';

  @override
  String get regStepPickup => 'Pickup';

  @override
  String get pickupTitle => 'Do you need a ride to the venue?';

  @override
  String get pickupBody =>
      'You are coming from within the host country, so we do not need your flight. We only need to know whether to pick you up, and from where.';

  @override
  String get pickupNeed => 'I need a ride';

  @override
  String get pickupNeedNo => 'I\'ll get there myself';

  @override
  String get pickupFromLabel => 'Where should we pick you up?';

  @override
  String get pickupFromHint =>
      'e.g. Retiro bus terminal, in front of the chapter';

  @override
  String get pickupFromRequired => 'Please write where we should pick you up';

  @override
  String get cpFeeMoveTitle => 'The fee amounts are in the description boxes';

  @override
  String get cpFeeMoveBody =>
      'Because the amount boxes are empty, attendees never see the fee step. Move them?';

  @override
  String get cpFeeMoveAction => 'Move to the fee boxes';

  @override
  String get cpFeeMoveDone => 'Moved. Press Save to keep it.';

  @override
  String get tblTitle => 'Details';

  @override
  String tblCount(int count) {
    return '$count rows';
  }

  @override
  String get tblEmpty => 'Nothing to show.';

  @override
  String get tblExportPdf => 'PDF';

  @override
  String get tblExportExcel => 'Excel';

  @override
  String tblExportFailed(String detail) {
    return 'Could not export: $detail';
  }

  @override
  String get tblHint => 'Double-tap to see the list';

  @override
  String get colGenderAge => 'Sex / Age';

  @override
  String get colStatus => 'Status';

  @override
  String get colFlight => 'Arrival flight';

  @override
  String get colPayment => 'Payment';

  @override
  String get colFee => 'Fee';

  @override
  String get colLanguages => 'Languages';

  @override
  String get tblAllAttendees => 'All attendees';

  @override
  String epPlanDocs(int count) {
    return 'Plan documents ($count)';
  }

  @override
  String get epPlanUpload => 'Upload a PDF';

  @override
  String get epPlanName => 'What is this document?';

  @override
  String get epPlanNameHint => 'e.g. Itinerary, Costs, Application';

  @override
  String get epPlanRemove => 'Remove this document';

  @override
  String epPlanFull(int max) {
    return 'Up to $max documents.';
  }

  @override
  String get tourPlanOpen => 'Open';

  @override
  String get tourOpenFailed =>
      'Could not open it, so the link was copied instead.';

  @override
  String get dashStatTours => 'Tour signups';

  @override
  String get tblTourSignups => 'Tour signups';

  @override
  String get colTour => 'Tour';

  @override
  String get colSignups => 'Signed up';

  @override
  String get colRemaining => 'Left';

  @override
  String get colDeadline => 'Closes';

  @override
  String get tourNoLimit => 'no limit';

  @override
  String get tourNobody => 'Nobody has signed up yet';

  @override
  String tourSignupSummary(int signed) {
    return '$signed signed up';
  }

  @override
  String get tblUnfinishedNote =>
      'A cream row means they have not finished registering.';

  @override
  String get asnTabService => 'Service';

  @override
  String svcNeeded(int filled, int needed) {
    return '$filled of $needed';
  }

  @override
  String svcNoLimit(int filled) {
    return '$filled · no target';
  }

  @override
  String svcShort(int count) {
    return '$count still needed';
  }

  @override
  String get svcNobody => 'Nobody yet';

  @override
  String get svcNominate => 'Ask someone';

  @override
  String get svcPickPerson => 'Who should we ask?';

  @override
  String svcAsked(String name) {
    return 'Asked $name';
  }

  @override
  String get svcSetLead => 'Make lead';

  @override
  String get svcLead => 'Lead';

  @override
  String get svcConfirm => 'Confirm';

  @override
  String get svcReject => 'Turn down';

  @override
  String get svcEditRoles => 'Add roles · set numbers';

  @override
  String get svcAddRole => 'Add a role';

  @override
  String get svcRoleName => 'Role name';

  @override
  String get svcRoleNameHint => 'e.g. Bus guide for Iguazú';

  @override
  String get svcNeedCount => 'How many?';

  @override
  String get svcNeedsApproval => 'Needs approval';

  @override
  String get svcStatusInvited => 'Waiting for a reply';

  @override
  String get svcStatusApplied => 'Volunteered';

  @override
  String get svcStatusApproval => 'Waiting for approval';

  @override
  String get svcStatusConfirmed => 'Confirmed';

  @override
  String get svcStatusRejected => 'Turned down';

  @override
  String get svcStatusDeclined => 'Said no';

  @override
  String get svcRoleSpecialSong => 'Special song';

  @override
  String get svcRoleMc => 'MC';

  @override
  String get svcRolePickup => 'Airport pickup';

  @override
  String get svcRoleCleaning => 'Cleaning';

  @override
  String get svcRoleTourGuide => 'Tour guide';

  @override
  String get svcRoleMealPrep => 'Meal prep';

  @override
  String get svcRoleLodgingBackup => 'Lodging backup';

  @override
  String get svcRoleRegistrationDesk => 'Registration desk';

  @override
  String get svcRoleInterpreter => 'Interpreter';

  @override
  String get svcRolePhotoVideo => 'Photo and video';

  @override
  String get svcRoleMedical => 'Medical';

  @override
  String get svcRoleGroupStudyLeader => 'Bible study group leader';

  @override
  String get svcRoleOther => 'Other';

  @override
  String get svcInviteTitle => 'A request for you';

  @override
  String svcInviteBody(String role) {
    return 'Could you take care of $role?';
  }

  @override
  String get svcAccept => 'Yes, I can';

  @override
  String get svcDecline => 'Sorry, I cannot';

  @override
  String get svcThanks => 'Thank you.';

  @override
  String get admTitle => 'Who can manage this';

  @override
  String get admSubtitle =>
      'They see the dashboard, the roster and the assignment screens.';

  @override
  String get admOwner => 'Created it';

  @override
  String get admAdd => 'Add someone';

  @override
  String get admPickPerson => 'Pick from the roster';

  @override
  String get admByEmail => 'Not on the list? Use their email';

  @override
  String get admEmailLabel => 'The email they sign in with';

  @override
  String get admRemove => 'Remove';

  @override
  String admRemoveAsk(String name) {
    return 'Remove $name from the managers?';
  }

  @override
  String admAdded(String name) {
    return '$name can manage this now';
  }

  @override
  String get admOwnerLocked => 'The person who created it cannot be removed.';

  @override
  String get dashAdmins => 'Managers';

  @override
  String get dashAdminsSub => 'Let someone else see the roster and assignments';

  @override
  String get svcRolesTitle => 'Roles for this conference';

  @override
  String svcRoleCount(int count, int max) {
    return '$count of $max roles';
  }

  @override
  String get svcSectionCustom => 'Roles you made';

  @override
  String get svcSectionBuiltIn => 'Ready-made roles';

  @override
  String svcRoleFull(int max) {
    return 'Up to $max roles.';
  }

  @override
  String get svcDeleteRole => 'Delete this role';

  @override
  String get svcNeedShort => 'need';

  @override
  String dashMoreCount(int count) {
    return 'See the other $count →';
  }

  @override
  String get dashSeeAll => 'Open the table →';

  @override
  String get dashByTour => 'See it tour by tour →';

  @override
  String get dashPreviewEmpty => 'Nothing yet';

  @override
  String get dashTourNobody => 'nobody yet';

  @override
  String get dashTourRoom => 'room left';

  @override
  String get dashTourFull => 'full';

  @override
  String dashUnitPeopleShort(int count) {
    return '$count';
  }

  @override
  String epContacts(int count) {
    return 'On-site contacts ($count)';
  }

  @override
  String get epAddContact => 'Add a contact';

  @override
  String get epContactName => 'Name';

  @override
  String get epContactPhone => 'Phone';

  @override
  String get epRemoveContact => 'Remove this contact';

  @override
  String epContactsFull(int max) {
    return 'Up to $max contacts.';
  }

  @override
  String get epPaymentWhen => 'When is it paid?';

  @override
  String get epFeeWhen => 'Conference fee';

  @override
  String get epTourWhen => 'Tour fee';

  @override
  String get epPrepaid => 'In advance';

  @override
  String get epOnsite => 'On arrival';

  @override
  String get epPaymentNote =>
      'If both are paid on arrival, the payment card is hidden from the dashboard.';

  @override
  String get dashStatPayments => 'Payments';

  @override
  String get dashPayConfirmed => 'paid';

  @override
  String get dashPayPending => 'waiting';

  @override
  String get dashPayNone => 'not yet';

  @override
  String get tblPayments => 'Payments';

  @override
  String get setupExtraBed => 'Spare spot';

  @override
  String get setupExtraBedHint =>
      'One more person can squeeze in. Used only when the normal beds run out.';

  @override
  String asnRoomWithExtra(int used, int cap, int extra) {
    return '$used/$cap (+$extra)';
  }

  @override
  String setupExtraSeats(int count) {
    return 'spare $count';
  }

  @override
  String get dashStatVolunteers => 'Volunteers';

  @override
  String dashRoleFilled(int filled, int needed) {
    return '$filled/$needed';
  }

  @override
  String get dashOpenService => 'Open the service board →';

  @override
  String svcOffered(int count) {
    return 'Offered to help ($count)';
  }

  @override
  String get svcOfferedNote =>
      'What they said they can do. Choosing who does what is still yours.';

  @override
  String get svcCanDo => 'can do';

  @override
  String get svcCallSend => 'Ask everyone for help';

  @override
  String svcCallSent(int short) {
    return 'Asked · $short still open';
  }

  @override
  String get svcCallClose => 'Stop asking';

  @override
  String get svcCallDone => 'Sent to everyone';

  @override
  String get svcCallTooSoon => 'Already asked recently. Give it a few hours.';

  @override
  String get svcCallFilled => 'This one is already covered.';

  @override
  String get svcCallNoTarget => 'Set how many you need first.';

  @override
  String get svcOpenTitle => 'Help is needed';

  @override
  String svcOpenBody(String role, int short) {
    return '$role — $short still open';
  }

  @override
  String get svcIllDoIt => 'I\'ll do it';

  @override
  String get svcAppliedThanks => 'Thank you. The organizer will confirm.';

  @override
  String get annTitle => 'Send a message';

  @override
  String get annSubtitle => 'Reaches phones directly, not just the group chat';

  @override
  String get annBody => 'What do you want to say?';

  @override
  String get annSend => 'Send';

  @override
  String get annTo => 'Who gets it';

  @override
  String get annToAll => 'Everyone';

  @override
  String get annToRoom => 'One room';

  @override
  String get annToGroup => 'One study group';

  @override
  String get annToUnsub => 'Not finished registering';

  @override
  String get annToUnpaid => 'Not paid yet';

  @override
  String get annPickRoom => 'Which room?';

  @override
  String get annPickGroup => 'Which group?';

  @override
  String annSent(int count) {
    return 'Sent to $count devices';
  }

  @override
  String get annPast => 'Sent before';

  @override
  String get annNoneYet => 'Nothing sent yet';

  @override
  String get dashAnnounce => 'Message participants';

  @override
  String get dashAnnounceSub => 'Everyone, or just one room or group';

  @override
  String get dspPlanTitle => 'What is needed';

  @override
  String dspPlanNeed(int need, int add) {
    return '$need needed · $add short';
  }

  @override
  String dspPlanOk(int have) {
    return '$have · covered';
  }

  @override
  String dspPlanPeople(int count) {
    return '$count people';
  }

  @override
  String dspMakeVans(int count) {
    return 'Make $count van(s)';
  }

  @override
  String get dspPlanNone => 'No arrival times yet';

  @override
  String get dspUnassignedFlight => 'no van yet';

  @override
  String get schServiceLabel => 'Service needed for this (optional)';

  @override
  String get schServiceNone => 'None';

  @override
  String get schServiceHint =>
      'The reminder will say how many are still needed, and only when some are.';

  @override
  String svcAssignTo(String name) {
    return 'Ask $name to help with';
  }

  @override
  String get svcSuggested => 'matches what they offered';

  @override
  String get dashNotAssigned => 'not assigned yet';

  @override
  String dashAssignedCount(int count) {
    return 'assigned to $count';
  }

  @override
  String get asnNoRoomLeader => 'no room leader yet';

  @override
  String asnRoomLeaderIs(String name) {
    return 'Room leader: $name';
  }

  @override
  String get asnNoGroupLeader => 'no leader yet';

  @override
  String get svcMineTitle => 'What I am helping with';

  @override
  String get tgOffer => 'Get messages on Telegram too';

  @override
  String get tgOpen => 'Open Telegram';

  @override
  String get tgCheck => 'I did it';

  @override
  String get tgLinked => 'Telegram is connected';

  @override
  String get tgNotYet =>
      'Not connected yet — open the link and press Start, then try again';

  @override
  String get tgUnlink => 'Disconnect';

  @override
  String svcAskThem(int count) {
    return 'Ask ($count)';
  }

  @override
  String get epRoutes => 'Other ways to get here';

  @override
  String get epRoutesDesc =>
      'Not everyone flies into the same airport. Say what the other routes are.';

  @override
  String get epRouteAirport => 'Airport';

  @override
  String get epRouteNote => 'How they get here from there';

  @override
  String get epRouteNoteHint => 'e.g. Buenos Aires, then 4 hours by bus';

  @override
  String get epAddRoute => 'Add a route';

  @override
  String get epRemoveRoute => 'Remove this route';

  @override
  String get flightNoteLabel => 'Anything to add (optional)';

  @override
  String get flightNoteHint => 'e.g. landing at EZE, taking the bus from there';

  @override
  String get immCardOtherRoute => 'OTHER ROUTE / 다른 경로';

  @override
  String get svcWillConfirm => 'they offered this — assigned right away';

  @override
  String get svcWillAsk => 'they did not offer this — we will ask them';

  @override
  String get setupGroupLanguage => 'Language this group studies in';

  @override
  String get setupAnyLanguage => 'Not set';

  @override
  String get setupCoupleRooms => 'Couple · family rooms';

  @override
  String get setupDormRooms => 'Shared rooms';

  @override
  String get setupRoomsMadeName => 'Room name';

  @override
  String get setupGroupCapacityHint =>
      'Leave blank to let the auto-assigner spread people evenly';

  @override
  String get tblAmountDue => 'Amount owed';

  @override
  String get tblSubmittedHint => 'Turn on if you took their form on paper';

  @override
  String get annToService => 'One service team';

  @override
  String get annPickService => 'Which team?';

  @override
  String get payUnpaid => 'Unpaid';

  @override
  String get payPartial => 'Part paid';

  @override
  String get payPaid => 'Paid in full';

  @override
  String get payPending => 'Awaiting check';

  @override
  String get tblAmountPaid => 'Amount received';

  @override
  String get sumWanting => 'Coming';

  @override
  String get sumCollected => 'Collected';

  @override
  String get sumRemaining => 'Still owed';

  @override
  String get ledgerTitle => 'Money';

  @override
  String get ledgerAdd => 'Add an entry';

  @override
  String get ledgerEmpty => 'Nothing written down yet';

  @override
  String get ledgerIncome => 'Came in';

  @override
  String get ledgerExpense => 'Went out';

  @override
  String get ledgerWhat => 'What for';

  @override
  String get ledgerAmount => 'Amount';

  @override
  String get ledgerNote => 'Note (optional)';

  @override
  String get ledgerCollected => 'Fees collected';

  @override
  String get ledgerSupport => 'Support received';

  @override
  String get ledgerSpent => 'Spent';

  @override
  String get ledgerBalance => 'In hand';

  @override
  String get ledgerExpected => 'If everyone pays';

  @override
  String ledgerOwedNote(String amount) {
    return 'Fees still owed: $amount';
  }

  @override
  String get dashLedgerSub => 'Support, spending and what is left';

  @override
  String get ledgerAddExpense => 'Record spending';

  @override
  String get ledgerAddIncome => 'Record support';

  @override
  String ledgerCount(int count) {
    return '$count entries';
  }

  @override
  String ledgerLocalAmount(String code) {
    return 'Amount in $code';
  }

  @override
  String ledgerRate(String code, String base) {
    return '$code per 1 $base';
  }

  @override
  String get ledgerRateBlue =>
      'today\'s blue rate — change it if you got another';

  @override
  String get ledgerRateMarket => 'today\'s rate — change it if you got another';

  @override
  String get ledgerRateUnavailable =>
      'Could not fetch a rate. Type the one you used.';

  @override
  String get rosterNoName => 'Name not filled in';

  @override
  String rosterAccountName(String name) {
    return '$name (from their account)';
  }

  @override
  String get regNameFromAccount =>
      'Filled in from your account — change it if it is not right';

  @override
  String get statByCountry => 'BY COUNTRY';

  @override
  String get statByGender => 'BY GENDER';

  @override
  String get statByAge => 'BY AGE';

  @override
  String get statUnknown => 'Not given';

  @override
  String get statAgeUnder20 => 'Under 20';

  @override
  String get statAge70Plus => '70 and over';

  @override
  String statAgeDecade(int from, int to) {
    return '$from–$to';
  }

  @override
  String get tblFindName => 'Find a name';

  @override
  String get statShowAll => 'Show everyone';

  @override
  String get commonClear => 'Clear';

  @override
  String get scopeTransport => 'Pickup and transport';

  @override
  String get scopeTransportHint =>
      'Vans, airport arrivals and departures, pickup requests';

  @override
  String get scopeRooms => 'Lodging';

  @override
  String get scopeRoomsHint => 'Rooms and capacity, assignment, room leaders';

  @override
  String get scopeGroups => 'Bible study';

  @override
  String get scopeGroupsHint => 'Groups, language and capacity, assignment';

  @override
  String get scopeLedger => 'Money';

  @override
  String get scopeLedgerHint =>
      'Ledger, fees received, approving payments and discounts';

  @override
  String get scopeService => 'Service';

  @override
  String get scopeServiceHint => 'Service teams, asking people, volunteer list';

  @override
  String get scopeRegistration => 'Registration';

  @override
  String get scopeRegistrationHint =>
      'Roster, marking someone registered, filling a form for them';

  @override
  String get scopeComms => 'Notices';

  @override
  String get scopeCommsHint => 'Announcements and the library';

  @override
  String get scopeSchedule => 'Schedule';

  @override
  String get scopeScheduleHint => 'Programme and times';

  @override
  String get scopeMedical => 'Medical and safety';

  @override
  String get scopeMedicalHint =>
      'SOS alerts and health notes. The most private thing here.';

  @override
  String get scopeAll => 'Everything — the same view as mine';

  @override
  String get scopeAllHint =>
      'No need to pick one by one. Editing and deleting the conference stays with whoever created it.';

  @override
  String get scopeTitle => 'What do they look after?';

  @override
  String get scopeSaved => 'Saved. They will be told.';

  @override
  String get scopeNone => 'Pick at least one area';

  @override
  String get scopeEdit => 'Change areas';

  @override
  String get scopeNotYours => 'This area is not yours to look after';

  @override
  String get epTourLodging => 'Lodging is part of the tour price';

  @override
  String get epTourLodgingOn => 'Nights during this tour are already paid for';

  @override
  String get epTourLodgingOff => 'Those nights are charged as hotel';

  @override
  String get colHotel => 'Hotel';

  @override
  String rosterHotelNights(int n) {
    return '$n night(s)';
  }

  @override
  String get epTourNotIncluded => 'Not covered by the tour price';

  @override
  String get epTourNotIncludedHelp =>
      'Tick what participants pay for separately, and roughly how much. Leave the amount blank if you do not know it yet — blank means \"to be confirmed\", not \"nothing\".';

  @override
  String get epTourNoMeals => 'Meals not included';

  @override
  String get epTourNoLodging => 'Hotel nights not included';

  @override
  String get epTourNoAirfare => 'Airfare not included';

  @override
  String get epTourEstimate => 'Estimated';

  @override
  String get epTourEstimateUnknown => 'to be confirmed';

  @override
  String get regExtrasTitle => 'Not covered by the tour price';

  @override
  String get regExtrasMeals => 'Meals';

  @override
  String get regExtrasLodging => 'Hotel nights';

  @override
  String get regExtrasAirfare => 'Airfare';

  @override
  String get regExtrasTbd => 'to be confirmed';

  @override
  String summaryPlusEstimated(String amount) {
    return 'Plus about $amount you pay separately';
  }

  @override
  String summaryPlusEstimatedSome(String amount) {
    return 'Plus about $amount you pay separately, and more still to be confirmed';
  }

  @override
  String get summaryPlusUnknownOnly =>
      'There is more to pay separately — the amount is not confirmed yet';

  @override
  String get summaryExtrasHelp =>
      'Estimates only, and not part of the fee you send us. Bring enough for these.';
}
