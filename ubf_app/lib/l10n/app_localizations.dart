import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ko'),
  ];

  /// Application title, shown in the app switcher
  ///
  /// In en, this message translates to:
  /// **'Mana'**
  String get appTitle;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Generic confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// Generic delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Generic edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Generic add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// Wizard next-step button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// Wizard previous-step button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionPrevious;

  /// Retry after an error
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Close a screen or dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Sign the user out
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get actionLogout;

  /// Loading indicator label
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// Marks a required field
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// Marks an optional field
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// Title of the pre-assignment setup screen (F2)
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupTitle;

  /// Setup tab: room configuration
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get setupTabRooms;

  /// Setup tab: Bible study group configuration
  ///
  /// In en, this message translates to:
  /// **'Bible study groups'**
  String get setupTabGroups;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Conference registration system'**
  String get appTagline;

  /// No description provided for @authSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authSignInGoogle;

  /// No description provided for @authSignInKakao.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Kakao'**
  String get authSignInKakao;

  /// No description provided for @authSignInDev.
  ///
  /// In en, this message translates to:
  /// **'Test login (dev@test.com)'**
  String get authSignInDev;

  /// No description provided for @authTermsNotice.
  ///
  /// In en, this message translates to:
  /// **'By signing in, you agree to the Terms of Service.'**
  String get authTermsNotice;

  /// No description provided for @authGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {error}'**
  String authGoogleFailed(String error);

  /// No description provided for @authKakaoFailed.
  ///
  /// In en, this message translates to:
  /// **'Kakao sign-in failed: {error}'**
  String authKakaoFailed(String error);

  /// No description provided for @authDevFailed.
  ///
  /// In en, this message translates to:
  /// **'Test login failed: {error}'**
  String authDevFailed(String error);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile setup'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the basic information used for registration.\nYou only need to do this once.'**
  String get profileSubtitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get profileNameLabel;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your real name'**
  String get profileNameHint;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get profileNameRequired;

  /// No description provided for @profileAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age *'**
  String get profileAgeLabel;

  /// No description provided for @profileAgeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 28'**
  String get profileAgeHint;

  /// No description provided for @profileAgeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age'**
  String get profileAgeInvalid;

  /// No description provided for @profileRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region *'**
  String get profileRegionLabel;

  /// No description provided for @profileRegionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Seoul, New York, Toronto...'**
  String get profileRegionHint;

  /// No description provided for @profileRegionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your region'**
  String get profileRegionRequired;

  /// No description provided for @profileSaveStart.
  ///
  /// In en, this message translates to:
  /// **'Save and start'**
  String get profileSaveStart;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String profileSaveFailed(String error);

  /// No description provided for @homeLogoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out?\nYou can sign in with a different account.'**
  String get homeLogoutConfirmBody;

  /// No description provided for @homeDirectorMode.
  ///
  /// In en, this message translates to:
  /// **'Director mode'**
  String get homeDirectorMode;

  /// No description provided for @homeManageMenu.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get homeManageMenu;

  /// No description provided for @homeCreateProgram.
  ///
  /// In en, this message translates to:
  /// **'Create program'**
  String get homeCreateProgram;

  /// No description provided for @homeCreateProgramSub.
  ///
  /// In en, this message translates to:
  /// **'Generate a UUID and configure a program'**
  String get homeCreateProgramSub;

  /// No description provided for @homeProgramList.
  ///
  /// In en, this message translates to:
  /// **'My programs'**
  String get homeProgramList;

  /// No description provided for @homeProgramListDirectorSub.
  ///
  /// In en, this message translates to:
  /// **'Manage programs you created'**
  String get homeProgramListDirectorSub;

  /// No description provided for @homeProgramListAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your assigned programs'**
  String get homeProgramListAdminSub;

  /// No description provided for @homeAssignAdmins.
  ///
  /// In en, this message translates to:
  /// **'Assign admins'**
  String get homeAssignAdmins;

  /// No description provided for @homeAssignAdminsSub.
  ///
  /// In en, this message translates to:
  /// **'Designate an admin per program'**
  String get homeAssignAdminsSub;

  /// No description provided for @homeDirectorInfo.
  ///
  /// In en, this message translates to:
  /// **'A director manages all programs and can assign admins.'**
  String get homeDirectorInfo;

  /// No description provided for @homeAdminMode.
  ///
  /// In en, this message translates to:
  /// **'Admin mode'**
  String get homeAdminMode;

  /// No description provided for @homeAdminInfo.
  ///
  /// In en, this message translates to:
  /// **'After creating a program, share its UUID with participants.'**
  String get homeAdminInfo;

  /// No description provided for @homeJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a program'**
  String get homeJoinTitle;

  /// No description provided for @homeJoinSub.
  ///
  /// In en, this message translates to:
  /// **'Enter the UUID your leader gave you to join a program.'**
  String get homeJoinSub;

  /// No description provided for @homeUuidLabel.
  ///
  /// In en, this message translates to:
  /// **'Program UUID'**
  String get homeUuidLabel;

  /// No description provided for @homeJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get homeJoinButton;

  /// No description provided for @homeRecentPrograms.
  ///
  /// In en, this message translates to:
  /// **'Recently joined'**
  String get homeRecentPrograms;

  /// No description provided for @homeRemoveFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get homeRemoveFromList;

  /// No description provided for @homeBecomeLeader.
  ///
  /// In en, this message translates to:
  /// **'Are you a leader? Switch to leader mode'**
  String get homeBecomeLeader;

  /// No description provided for @homeLeaderCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter leader check'**
  String get homeLeaderCheckTitle;

  /// No description provided for @homeLeaderCheckBody.
  ///
  /// In en, this message translates to:
  /// **'The email you signed in with ({email}) is registered as the leader of this chapter:'**
  String homeLeaderCheckBody(String email);

  /// No description provided for @homeLeaderContinent.
  ///
  /// In en, this message translates to:
  /// **'Continent: {value}'**
  String homeLeaderContinent(String value);

  /// No description provided for @homeLeaderNation.
  ///
  /// In en, this message translates to:
  /// **'Country: {value}'**
  String homeLeaderNation(String value);

  /// No description provided for @homeLeaderChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter: {value}'**
  String homeLeaderChapter(String value);

  /// No description provided for @homeLeaderCheckPrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you like to register as a chapter leader?'**
  String get homeLeaderCheckPrompt;

  /// No description provided for @homeLeaderDeclineParticipant.
  ///
  /// In en, this message translates to:
  /// **'No, continue as participant'**
  String get homeLeaderDeclineParticipant;

  /// No description provided for @homeLeaderConfirmRegister.
  ///
  /// In en, this message translates to:
  /// **'Yes, register as leader'**
  String get homeLeaderConfirmRegister;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

  /// No description provided for @commonErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonErrorDetail(String error);

  /// No description provided for @sectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'This section is disabled'**
  String get sectionDisabled;

  /// No description provided for @regTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get regTitle;

  /// No description provided for @regInvalidProgram.
  ///
  /// In en, this message translates to:
  /// **'Invalid program UUID'**
  String get regInvalidProgram;

  /// No description provided for @regScheduleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Program schedule'**
  String get regScheduleTooltip;

  /// No description provided for @regSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get regSaveDraft;

  /// No description provided for @regReviewSummary.
  ///
  /// In en, this message translates to:
  /// **'Review summary'**
  String get regReviewSummary;

  /// No description provided for @regStepPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get regStepPersonal;

  /// No description provided for @regStepArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival flight'**
  String get regStepArrival;

  /// No description provided for @regStepDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure flight'**
  String get regStepDeparture;

  /// No description provided for @regStepFood.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get regStepFood;

  /// No description provided for @regStepOptions.
  ///
  /// In en, this message translates to:
  /// **'Tours / options'**
  String get regStepOptions;

  /// No description provided for @regStepRoommate.
  ///
  /// In en, this message translates to:
  /// **'Roommate'**
  String get regStepRoommate;

  /// No description provided for @regStepVolunteer.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get regStepVolunteer;

  /// No description provided for @roommateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is there someone you\'d like to room with?'**
  String get roommateQuestion;

  /// No description provided for @roommateHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the name (Bible name or real name) of the person you\'d like to room with.\nWe\'ll do our best to accommodate it.'**
  String get roommateHelp;

  /// No description provided for @roommateFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Roommate preference (optional)'**
  String get roommateFieldLabel;

  /// No description provided for @roommateFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Peter, John (same room)\nor enter \"None\"'**
  String get roommateFieldHint;

  /// No description provided for @roommateNotice.
  ///
  /// In en, this message translates to:
  /// **'Roommate assignments may be adjusted at the leader\'s discretion.'**
  String get roommateNotice;

  /// No description provided for @optionsNone.
  ///
  /// In en, this message translates to:
  /// **'This program has no special options'**
  String get optionsNone;

  /// No description provided for @optionsSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select the programs you\'ll join (multiple allowed)'**
  String get optionsSelectPrompt;

  /// No description provided for @optionsFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get optionsFree;

  /// No description provided for @optionsSelectedTotal.
  ///
  /// In en, this message translates to:
  /// **'Selected options total'**
  String get optionsSelectedTotal;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @regContinent.
  ///
  /// In en, this message translates to:
  /// **'Continent *'**
  String get regContinent;

  /// No description provided for @regContinentHint.
  ///
  /// In en, this message translates to:
  /// **'Select a continent'**
  String get regContinentHint;

  /// No description provided for @regNation.
  ///
  /// In en, this message translates to:
  /// **'Country *'**
  String get regNation;

  /// No description provided for @regNationHint.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get regNationHint;

  /// No description provided for @regNationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Select a continent first'**
  String get regNationDisabled;

  /// No description provided for @regChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter *'**
  String get regChapter;

  /// No description provided for @regChapterHint.
  ///
  /// In en, this message translates to:
  /// **'Select a chapter'**
  String get regChapterHint;

  /// No description provided for @regChapterNoneHint.
  ///
  /// In en, this message translates to:
  /// **'No chapters are registered for this country. Please enter it manually below.'**
  String get regChapterNoneHint;

  /// No description provided for @regChapterManualHint.
  ///
  /// In en, this message translates to:
  /// **'If not listed, enter it manually below'**
  String get regChapterManualHint;

  /// No description provided for @regBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch name *'**
  String get regBranch;

  /// No description provided for @regBranchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tokyo, Chicago'**
  String get regBranchHint;

  /// No description provided for @regRealName.
  ///
  /// In en, this message translates to:
  /// **'Real name *'**
  String get regRealName;

  /// No description provided for @regBibleName.
  ///
  /// In en, this message translates to:
  /// **'Bible name'**
  String get regBibleName;

  /// No description provided for @regBibleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Peter, Mary'**
  String get regBibleNameHint;

  /// No description provided for @regGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get regGender;

  /// No description provided for @regAge.
  ///
  /// In en, this message translates to:
  /// **'Age *'**
  String get regAge;

  /// No description provided for @foodMedicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical conditions'**
  String get foodMedicalTitle;

  /// No description provided for @foodMedicalHint.
  ///
  /// In en, this message translates to:
  /// **'Enter any conditions such as diabetes, hypertension, allergies (leave blank if none)'**
  String get foodMedicalHint;

  /// No description provided for @foodRestrictionTitle.
  ///
  /// In en, this message translates to:
  /// **'Foods you cannot eat'**
  String get foodRestrictionTitle;

  /// No description provided for @foodRestrictionHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose below or enter your own'**
  String get foodRestrictionHelp;

  /// No description provided for @foodRestrictionInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter foods you cannot eat'**
  String get foodRestrictionInputHint;

  /// No description provided for @foodVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get foodVegetarian;

  /// No description provided for @foodVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get foodVegan;

  /// No description provided for @foodHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get foodHalal;

  /// No description provided for @foodKosher.
  ///
  /// In en, this message translates to:
  /// **'Kosher'**
  String get foodKosher;

  /// No description provided for @foodGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten intolerance'**
  String get foodGluten;

  /// No description provided for @foodPeanut.
  ///
  /// In en, this message translates to:
  /// **'Peanut allergy'**
  String get foodPeanut;

  /// No description provided for @foodDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy allergy'**
  String get foodDairy;

  /// No description provided for @foodSeafood.
  ///
  /// In en, this message translates to:
  /// **'Seafood allergy'**
  String get foodSeafood;

  /// No description provided for @foodNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get foodNone;

  /// No description provided for @foodBreakfastTitle.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get foodBreakfastTitle;

  /// No description provided for @foodSkipBreakfast.
  ///
  /// In en, this message translates to:
  /// **'I usually skip breakfast'**
  String get foodSkipBreakfast;

  /// No description provided for @foodSkipBreakfastSub.
  ///
  /// In en, this message translates to:
  /// **'Used to estimate meal headcount'**
  String get foodSkipBreakfastSub;

  /// No description provided for @flightArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get flightArrival;

  /// No description provided for @flightDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get flightDeparture;

  /// No description provided for @flightInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'{dir} flight info'**
  String flightInfoTitle(String dir);

  /// No description provided for @flightDateLabel.
  ///
  /// In en, this message translates to:
  /// **'{dir} date *'**
  String flightDateLabel(String dir);

  /// No description provided for @flightAirportLabel.
  ///
  /// In en, this message translates to:
  /// **'{dir} airport'**
  String flightAirportLabel(String dir);

  /// No description provided for @flightTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'{dir} scheduled time'**
  String flightTimeLabel(String dir);

  /// No description provided for @flightPickDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get flightPickDate;

  /// No description provided for @flightNumber.
  ///
  /// In en, this message translates to:
  /// **'Flight number'**
  String get flightNumber;

  /// No description provided for @flightNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. KE123, OZ456'**
  String get flightNumberHint;

  /// No description provided for @flightAutoSearch.
  ///
  /// In en, this message translates to:
  /// **'Look up flight automatically'**
  String get flightAutoSearch;

  /// No description provided for @flightNotFound.
  ///
  /// In en, this message translates to:
  /// **'Flight information not found. Please enter it manually.'**
  String get flightNotFound;

  /// No description provided for @flightStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {value}'**
  String flightStatus(String value);

  /// No description provided for @flightAutoFillHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled when you search by flight number'**
  String get flightAutoFillHint;

  /// No description provided for @volQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can you help with the program?'**
  String get volQuestion;

  /// No description provided for @volHelp.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply. (Optional)'**
  String get volHelp;

  /// No description provided for @volOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other ways you can help (optional)'**
  String get volOtherLabel;

  /// No description provided for @volOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Write any talents or resources not listed above'**
  String get volOtherHint;

  /// No description provided for @volPiano.
  ///
  /// In en, this message translates to:
  /// **'Piano'**
  String get volPiano;

  /// No description provided for @volGuitar.
  ///
  /// In en, this message translates to:
  /// **'Guitar'**
  String get volGuitar;

  /// No description provided for @volBass.
  ///
  /// In en, this message translates to:
  /// **'Bass'**
  String get volBass;

  /// No description provided for @volDrums.
  ///
  /// In en, this message translates to:
  /// **'Drums'**
  String get volDrums;

  /// No description provided for @volViolin.
  ///
  /// In en, this message translates to:
  /// **'Violin'**
  String get volViolin;

  /// No description provided for @volWorshipLead.
  ///
  /// In en, this message translates to:
  /// **'Worship leading'**
  String get volWorshipLead;

  /// No description provided for @volVocals.
  ///
  /// In en, this message translates to:
  /// **'Vocals'**
  String get volVocals;

  /// No description provided for @volTranslation.
  ///
  /// In en, this message translates to:
  /// **'Interpretation/Translation'**
  String get volTranslation;

  /// No description provided for @volPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photo/Video'**
  String get volPhotography;

  /// No description provided for @volSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get volSound;

  /// No description provided for @volDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get volDesign;

  /// No description provided for @volIt.
  ///
  /// In en, this message translates to:
  /// **'IT/Tech'**
  String get volIt;

  /// No description provided for @volChildcare.
  ///
  /// In en, this message translates to:
  /// **'Childcare'**
  String get volChildcare;

  /// No description provided for @volCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking/Kitchen'**
  String get volCooking;

  /// No description provided for @volDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get volDriving;

  /// No description provided for @volMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical/First aid'**
  String get volMedical;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration summary'**
  String get summaryTitle;

  /// No description provided for @summarySectionProgram.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get summarySectionProgram;

  /// No description provided for @summaryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get summaryName;

  /// No description provided for @summaryLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get summaryLocation;

  /// No description provided for @summaryPeriod.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get summaryPeriod;

  /// No description provided for @summaryCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get summaryCountry;

  /// No description provided for @summaryBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get summaryBranch;

  /// No description provided for @summaryRealName.
  ///
  /// In en, this message translates to:
  /// **'Real name'**
  String get summaryRealName;

  /// No description provided for @summaryBibleName.
  ///
  /// In en, this message translates to:
  /// **'Bible name'**
  String get summaryBibleName;

  /// No description provided for @summaryAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get summaryAge;

  /// No description provided for @summaryFlightNo.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get summaryFlightNo;

  /// No description provided for @summaryArrAirport.
  ///
  /// In en, this message translates to:
  /// **'Arrival airport'**
  String get summaryArrAirport;

  /// No description provided for @summaryArrTime.
  ///
  /// In en, this message translates to:
  /// **'Arrival time'**
  String get summaryArrTime;

  /// No description provided for @summaryDepAirport.
  ///
  /// In en, this message translates to:
  /// **'Departure airport'**
  String get summaryDepAirport;

  /// No description provided for @summaryDepTime.
  ///
  /// In en, this message translates to:
  /// **'Departure time'**
  String get summaryDepTime;

  /// No description provided for @summarySectionFood.
  ///
  /// In en, this message translates to:
  /// **'Dietary needs'**
  String get summarySectionFood;

  /// No description provided for @summarySectionOptions.
  ///
  /// In en, this message translates to:
  /// **'Selected programs'**
  String get summarySectionOptions;

  /// No description provided for @summarySectionRoommate.
  ///
  /// In en, this message translates to:
  /// **'Roommate preference'**
  String get summarySectionRoommate;

  /// No description provided for @summaryTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total payment'**
  String get summaryTotalCost;

  /// No description provided for @summaryNoPaidOptions.
  ///
  /// In en, this message translates to:
  /// **'No paid options selected'**
  String get summaryNoPaidOptions;

  /// No description provided for @summaryViewImmigration.
  ///
  /// In en, this message translates to:
  /// **'View immigration card'**
  String get summaryViewImmigration;

  /// No description provided for @summarySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get summarySubmit;

  /// No description provided for @summaryEditBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get summaryEditBtn;

  /// No description provided for @summarySubmitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to submit your registration?\nEditing may be restricted after submission.'**
  String get summarySubmitConfirm;

  /// No description provided for @summarySubmitDone.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get summarySubmitDone;

  /// No description provided for @summarySubmitDoneMsg.
  ///
  /// In en, this message translates to:
  /// **'Your registration was submitted successfully.\nAn organizer will contact you after review.'**
  String get summarySubmitDoneMsg;

  /// No description provided for @summarySubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String summarySubmitFailed(String error);

  /// No description provided for @commonNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get commonNoName;

  /// No description provided for @unitPeople.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String unitPeople(int count);

  /// No description provided for @unitCases.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String unitCases(int count);

  /// No description provided for @dashTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashTitle;

  /// No description provided for @dashExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get dashExport;

  /// No description provided for @dashExportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get dashExportExcel;

  /// No description provided for @dashExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get dashExportCsv;

  /// No description provided for @dashEditSettings.
  ///
  /// In en, this message translates to:
  /// **'Edit program settings'**
  String get dashEditSettings;

  /// No description provided for @dashSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Define rooms and Bible study groups (pre-assignment step)'**
  String get dashSetupSubtitle;

  /// No description provided for @dashPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments to confirm'**
  String get dashPendingPayments;

  /// No description provided for @dashViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashViewAll;

  /// No description provided for @dashNoPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments awaiting confirmation'**
  String get dashNoPendingPayments;

  /// No description provided for @dashAttendeeList.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get dashAttendeeList;

  /// No description provided for @dashNoAttendees.
  ///
  /// In en, this message translates to:
  /// **'No participants registered yet'**
  String get dashNoAttendees;

  /// No description provided for @dashSendNotice.
  ///
  /// In en, this message translates to:
  /// **'Send group announcement'**
  String get dashSendNotice;

  /// No description provided for @dashNoStats.
  ///
  /// In en, this message translates to:
  /// **'No statistics'**
  String get dashNoStats;

  /// No description provided for @dashStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total registered'**
  String get dashStatTotal;

  /// No description provided for @dashStatSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashStatSubmitted;

  /// No description provided for @dashStatFoodRestriction.
  ///
  /// In en, this message translates to:
  /// **'Dietary needs'**
  String get dashStatFoodRestriction;

  /// No description provided for @dashStatPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get dashStatPendingPayment;

  /// No description provided for @dashStatArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival flights'**
  String get dashStatArrival;

  /// No description provided for @dashStatConfirmedPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get dashStatConfirmedPayment;

  /// No description provided for @dashPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get dashPaymentPending;

  /// No description provided for @dashStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dashStatusDone;

  /// No description provided for @dashStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get dashStatusInProgress;

  /// No description provided for @pcTitle.
  ///
  /// In en, this message translates to:
  /// **'Program created'**
  String get pcTitle;

  /// No description provided for @pcHeading.
  ///
  /// In en, this message translates to:
  /// **'Your program has been created!'**
  String get pcHeading;

  /// No description provided for @pcShareUuid.
  ///
  /// In en, this message translates to:
  /// **'Share the UUID below with participants'**
  String get pcShareUuid;

  /// No description provided for @pcCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get pcCopy;

  /// No description provided for @pcCopied.
  ///
  /// In en, this message translates to:
  /// **'UUID copied'**
  String get pcCopied;

  /// No description provided for @pcInfo.
  ///
  /// In en, this message translates to:
  /// **'Participants can register by entering this UUID in the app.'**
  String get pcInfo;

  /// No description provided for @pcGoDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to dashboard'**
  String get pcGoDashboard;

  /// No description provided for @pcGoHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get pcGoHome;

  /// No description provided for @cpProgramType.
  ///
  /// In en, this message translates to:
  /// **'Program type'**
  String get cpProgramType;

  /// No description provided for @cpTypeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local retreat'**
  String get cpTypeLocal;

  /// No description provided for @cpTypeInternational.
  ///
  /// In en, this message translates to:
  /// **'International retreat'**
  String get cpTypeInternational;

  /// No description provided for @cpLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Local retreat: flight and tour sections are disabled automatically'**
  String get cpLocalNote;

  /// No description provided for @cpBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get cpBasicInfo;

  /// No description provided for @cpNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Program name *'**
  String get cpNameLabel;

  /// No description provided for @cpNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2025 Summer Retreat'**
  String get cpNameHint;

  /// No description provided for @cpNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a program name'**
  String get cpNameRequired;

  /// No description provided for @cpLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location *'**
  String get cpLocationLabel;

  /// No description provided for @cpLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jeju International Convention Center'**
  String get cpLocationHint;

  /// No description provided for @cpLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location'**
  String get cpLocationRequired;

  /// No description provided for @cpStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get cpStartDate;

  /// No description provided for @cpEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get cpEndDate;

  /// No description provided for @cpImmigrationInfo.
  ///
  /// In en, this message translates to:
  /// **'Immigration guide info'**
  String get cpImmigrationInfo;

  /// No description provided for @cpImmigrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Info participants can show to an immigration officer on arrival (optional)'**
  String get cpImmigrationDesc;

  /// No description provided for @cpNearestAirport.
  ///
  /// In en, this message translates to:
  /// **'Nearest airport'**
  String get cpNearestAirport;

  /// No description provided for @cpAirportHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Incheon Intl (ICN)'**
  String get cpAirportHint;

  /// No description provided for @cpContacts.
  ///
  /// In en, this message translates to:
  /// **'On-site contacts (2)'**
  String get cpContacts;

  /// No description provided for @cpName1.
  ///
  /// In en, this message translates to:
  /// **'Name 1'**
  String get cpName1;

  /// No description provided for @cpName1Hint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get cpName1Hint;

  /// No description provided for @cpPhone1.
  ///
  /// In en, this message translates to:
  /// **'Phone 1'**
  String get cpPhone1;

  /// No description provided for @cpName2.
  ///
  /// In en, this message translates to:
  /// **'Name 2'**
  String get cpName2;

  /// No description provided for @cpName2Hint.
  ///
  /// In en, this message translates to:
  /// **'Jane Doe'**
  String get cpName2Hint;

  /// No description provided for @cpPhone2.
  ///
  /// In en, this message translates to:
  /// **'Phone 2'**
  String get cpPhone2;

  /// No description provided for @cpSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable registration sections'**
  String get cpSectionsTitle;

  /// No description provided for @cpSectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which items participants will see'**
  String get cpSectionsDesc;

  /// No description provided for @cpSecVolunteer.
  ///
  /// In en, this message translates to:
  /// **'Program help resources (instruments, translation, etc.)'**
  String get cpSecVolunteer;

  /// No description provided for @cpSpecialOptions.
  ///
  /// In en, this message translates to:
  /// **'Special programs / tour options'**
  String get cpSpecialOptions;

  /// No description provided for @cpOptionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a cost per option so participants can choose'**
  String get cpOptionsDesc;

  /// No description provided for @cpOptionCost.
  ///
  /// In en, this message translates to:
  /// **'Cost: {value}'**
  String cpOptionCost(String value);

  /// No description provided for @cpOptionName.
  ///
  /// In en, this message translates to:
  /// **'Option name'**
  String get cpOptionName;

  /// No description provided for @cpOptionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Jeju Tour Course A'**
  String get cpOptionNameHint;

  /// No description provided for @cpOptionCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cpOptionCostLabel;

  /// No description provided for @cpCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create program (issue UUID)'**
  String get cpCreateButton;

  /// No description provided for @cpDupTitle.
  ///
  /// In en, this message translates to:
  /// **'Program already exists'**
  String get cpDupTitle;

  /// No description provided for @cpDupBody.
  ///
  /// In en, this message translates to:
  /// **'A program with the same name and start date already exists.\nGo to the existing program\'s UUID screen?'**
  String get cpDupBody;

  /// No description provided for @cpDupGoExisting.
  ///
  /// In en, this message translates to:
  /// **'Go to existing program'**
  String get cpDupGoExisting;

  /// No description provided for @cpCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create program: {error}'**
  String cpCreateFailed(String error);

  /// No description provided for @epSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get epSaved;

  /// No description provided for @epNotFound.
  ///
  /// In en, this message translates to:
  /// **'Program not found'**
  String get epNotFound;

  /// No description provided for @epTourLocked.
  ///
  /// In en, this message translates to:
  /// **'The retreat has already started, so tour options cannot be edited'**
  String get epTourLocked;

  /// No description provided for @epOptionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact: {value}'**
  String epOptionContact(String value);

  /// No description provided for @epAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get epAddOption;

  /// No description provided for @epEditOption.
  ///
  /// In en, this message translates to:
  /// **'Edit option'**
  String get epEditOption;

  /// No description provided for @epSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get epSaveChanges;

  /// No description provided for @epOptionNameReq.
  ///
  /// In en, this message translates to:
  /// **'Option name *'**
  String get epOptionNameReq;

  /// No description provided for @epOptionCostNum.
  ///
  /// In en, this message translates to:
  /// **'Cost (number)'**
  String get epOptionCostNum;

  /// No description provided for @epOptionContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get epOptionContactName;

  /// No description provided for @epOptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get epOptionDesc;

  /// No description provided for @epPickDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get epPickDate;

  /// No description provided for @epPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count}/5)'**
  String epPhotos(int count);

  /// No description provided for @blTitle.
  ///
  /// In en, this message translates to:
  /// **'Register as leader'**
  String get blTitle;

  /// No description provided for @blInfo.
  ///
  /// In en, this message translates to:
  /// **'Registering as a leader lets you create retreat programs and manage participants.'**
  String get blInfo;

  /// No description provided for @blLoginAccount.
  ///
  /// In en, this message translates to:
  /// **'Signed-in account'**
  String get blLoginAccount;

  /// No description provided for @blLeaderName.
  ///
  /// In en, this message translates to:
  /// **'Leader name *'**
  String get blLeaderName;

  /// No description provided for @blLeaderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name shown to participants'**
  String get blLeaderNameHint;

  /// No description provided for @blRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register and create an event'**
  String get blRegisterButton;

  /// No description provided for @blLeaderRegFailed.
  ///
  /// In en, this message translates to:
  /// **'Leader registration failed: {error}'**
  String blLeaderRegFailed(String error);

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get sosTitle;

  /// No description provided for @sosHealth.
  ///
  /// In en, this message translates to:
  /// **'🚑 Health/Medical emergency'**
  String get sosHealth;

  /// No description provided for @sosSafety.
  ///
  /// In en, this message translates to:
  /// **'🆘 Personal safety threat'**
  String get sosSafety;

  /// No description provided for @sosLost.
  ///
  /// In en, this message translates to:
  /// **'🗺️ I\'m lost'**
  String get sosLost;

  /// No description provided for @sosGpsOff.
  ///
  /// In en, this message translates to:
  /// **'GPS is off. Please enable it in settings.'**
  String get sosGpsOff;

  /// No description provided for @sosPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Sending SOS without location.'**
  String get sosPermDenied;

  /// No description provided for @sosLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get location: {error}'**
  String sosLocationError(String error);

  /// No description provided for @sosSentTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS sent'**
  String get sosSentTitle;

  /// No description provided for @sosSentMsg.
  ///
  /// In en, this message translates to:
  /// **'An emergency alert has been sent to the organizers.\nPlease wait a moment.'**
  String get sosSentMsg;

  /// No description provided for @sosSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String sosSendFailed(String error);

  /// No description provided for @sosBanner.
  ///
  /// In en, this message translates to:
  /// **'An alert is sent to organizers immediately.\nUse only in an emergency.'**
  String get sosBanner;

  /// No description provided for @sosSelectType.
  ///
  /// In en, this message translates to:
  /// **'Select the type of situation'**
  String get sosSelectType;

  /// No description provided for @sosMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional message (optional)'**
  String get sosMessageLabel;

  /// No description provided for @sosMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe your current situation'**
  String get sosMessageHint;

  /// No description provided for @sosGpsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'GPS location confirmed {value}'**
  String sosGpsConfirmed(String value);

  /// No description provided for @sosGpsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking GPS location...'**
  String get sosGpsChecking;

  /// No description provided for @sosSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sosSending;

  /// No description provided for @sosSend.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get sosSend;

  /// No description provided for @sosFabConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send an emergency alert to the organizers?'**
  String get sosFabConfirm;

  /// No description provided for @schLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load schedule: {error}'**
  String schLoadFailed(String error);

  /// No description provided for @schAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get schAddTitle;

  /// No description provided for @schTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get schTitleLabel;

  /// No description provided for @schTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Opening worship'**
  String get schTitleHint;

  /// No description provided for @schDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get schDescLabel;

  /// No description provided for @schPickTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get schPickTime;

  /// No description provided for @schTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get schTimezone;

  /// No description provided for @schTzAuto.
  ///
  /// In en, this message translates to:
  /// **'Set automatically to your device time zone'**
  String get schTzAuto;

  /// No description provided for @schTzReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to device time zone'**
  String get schTzReset;

  /// No description provided for @schAllRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter title, date, and time'**
  String get schAllRequired;

  /// No description provided for @schAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add: {error}'**
  String schAddFailed(String error);

  /// No description provided for @schTzChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change time zone'**
  String get schTzChangeTitle;

  /// No description provided for @schTzUseDevice.
  ///
  /// In en, this message translates to:
  /// **'Use my device time zone'**
  String get schTzUseDevice;

  /// No description provided for @schTzExamples.
  ///
  /// In en, this message translates to:
  /// **'e.g. Asia/Seoul, America/New_York, Europe/London'**
  String get schTzExamples;

  /// No description provided for @schTzChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change time zone: {error}'**
  String schTzChangeFailed(String error);

  /// No description provided for @schDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get schDeleteTitle;

  /// No description provided for @schDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this event?'**
  String get schDeleteConfirm;

  /// No description provided for @schDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String schDeleteFailed(String error);

  /// No description provided for @schEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events scheduled'**
  String get schEmpty;

  /// No description provided for @immTitle.
  ///
  /// In en, this message translates to:
  /// **'Immigration guide card'**
  String get immTitle;

  /// No description provided for @immFullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen (show to officer)'**
  String get immFullscreenTooltip;

  /// No description provided for @immNotFound.
  ///
  /// In en, this message translates to:
  /// **'Program information not found.'**
  String get immNotFound;

  /// No description provided for @immBanner.
  ///
  /// In en, this message translates to:
  /// **'Tap the fullscreen button at the top right to show it to the officer.'**
  String get immBanner;

  /// No description provided for @immCardPurpose.
  ///
  /// In en, this message translates to:
  /// **'PURPOSE OF VISIT'**
  String get immCardPurpose;

  /// No description provided for @immCardConference.
  ///
  /// In en, this message translates to:
  /// **'Religious Conference'**
  String get immCardConference;

  /// No description provided for @immCardVenue.
  ///
  /// In en, this message translates to:
  /// **'VENUE'**
  String get immCardVenue;

  /// No description provided for @immCardDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get immCardDate;

  /// No description provided for @immCardAirport.
  ///
  /// In en, this message translates to:
  /// **'NEAREST AIRPORT'**
  String get immCardAirport;

  /// No description provided for @immCardContact.
  ///
  /// In en, this message translates to:
  /// **'ON-SITE CONTACT'**
  String get immCardContact;

  /// No description provided for @immCardFooter.
  ///
  /// In en, this message translates to:
  /// **'I am attending the above religious conference as a participant.'**
  String get immCardFooter;

  /// No description provided for @immExitHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to exit fullscreen'**
  String get immExitHint;

  /// No description provided for @setupRoomsMade.
  ///
  /// In en, this message translates to:
  /// **'Rooms created · {count}'**
  String setupRoomsMade(int count);

  /// No description provided for @setupRoomsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rooms yet.\nUse the button at the bottom right to bulk-add rooms.'**
  String get setupRoomsEmpty;

  /// No description provided for @setupBulkAddRooms.
  ///
  /// In en, this message translates to:
  /// **'Bulk-add rooms'**
  String get setupBulkAddRooms;

  /// No description provided for @setupRoomsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} rooms'**
  String setupRoomsAdded(int count);

  /// No description provided for @setupReconcileTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered vs capacity'**
  String get setupReconcileTitle;

  /// No description provided for @setupMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get setupMale;

  /// No description provided for @setupFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get setupFemale;

  /// No description provided for @setupMixedSeats.
  ///
  /// In en, this message translates to:
  /// **'Couple/family rooms: {count} beds (assigned by family)'**
  String setupMixedSeats(int count);

  /// No description provided for @setupRegVsSeats.
  ///
  /// In en, this message translates to:
  /// **'Registered {regs} · Capacity {seats}'**
  String setupRegVsSeats(int regs, int seats);

  /// No description provided for @setupSeatShortage.
  ///
  /// In en, this message translates to:
  /// **'{count} beds short'**
  String setupSeatShortage(int count);

  /// No description provided for @setupRoomCapacity.
  ///
  /// In en, this message translates to:
  /// **'{count}-person'**
  String setupRoomCapacity(int count);

  /// No description provided for @setupCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple room'**
  String get setupCouple;

  /// No description provided for @setupCoupleSub.
  ///
  /// In en, this message translates to:
  /// **'2 ppl · mixed'**
  String get setupCoupleSub;

  /// No description provided for @setupFamily.
  ///
  /// In en, this message translates to:
  /// **'Family room'**
  String get setupFamily;

  /// No description provided for @setupFamilySub.
  ///
  /// In en, this message translates to:
  /// **'3–4 ppl · mixed'**
  String get setupFamilySub;

  /// No description provided for @setupDorm.
  ///
  /// In en, this message translates to:
  /// **'Dormitory'**
  String get setupDorm;

  /// No description provided for @setupDormSub.
  ///
  /// In en, this message translates to:
  /// **'5+ · single gender'**
  String get setupDormSub;

  /// No description provided for @setupMixed.
  ///
  /// In en, this message translates to:
  /// **'Family (mixed)'**
  String get setupMixed;

  /// No description provided for @setupRoomType.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get setupRoomType;

  /// No description provided for @setupNameRule.
  ///
  /// In en, this message translates to:
  /// **'Name pattern'**
  String get setupNameRule;

  /// No description provided for @setupNameRuleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3F 3##'**
  String get setupNameRuleHint;

  /// No description provided for @setupStartNum.
  ///
  /// In en, this message translates to:
  /// **'Start#'**
  String get setupStartNum;

  /// No description provided for @setupCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get setupCount;

  /// No description provided for @setupCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get setupCapacity;

  /// No description provided for @setupFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor (optional)'**
  String get setupFloor;

  /// No description provided for @setupMixedNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Mixed not allowed'**
  String get setupMixedNotAllowed;

  /// No description provided for @setupFamilyAuto.
  ///
  /// In en, this message translates to:
  /// **'Family unit (mixed) — automatic'**
  String get setupFamilyAuto;

  /// No description provided for @setupBulkValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the name pattern, count, and capacity'**
  String get setupBulkValidation;

  /// No description provided for @setupGroupsMade.
  ///
  /// In en, this message translates to:
  /// **'Groups created · {count}'**
  String setupGroupsMade(int count);

  /// No description provided for @setupGroupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No groups yet.\nUse the button at the bottom right to create groups.'**
  String get setupGroupsEmpty;

  /// No description provided for @setupMakeGroups.
  ///
  /// In en, this message translates to:
  /// **'Create groups'**
  String get setupMakeGroups;

  /// No description provided for @setupMakeGroupsPrompt.
  ///
  /// In en, this message translates to:
  /// **'How many groups? (Group 1, Group 2 … auto-generated)'**
  String get setupMakeGroupsPrompt;

  /// No description provided for @setupGroupCount.
  ///
  /// In en, this message translates to:
  /// **'Number of groups'**
  String get setupGroupCount;

  /// No description provided for @setupGroupCountSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get setupGroupCountSuffix;

  /// No description provided for @setupMake.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get setupMake;

  /// No description provided for @setupGroupsCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {count} groups'**
  String setupGroupsCreated(int count);

  /// No description provided for @setupMakeGroupsFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create groups first'**
  String get setupMakeGroupsFirst;

  /// No description provided for @setupEvenPerGroup.
  ///
  /// In en, this message translates to:
  /// **'About {count} per group, evenly'**
  String setupEvenPerGroup(int count);

  /// No description provided for @setupUnevenPerGroup.
  ///
  /// In en, this message translates to:
  /// **'{remCount} groups have {bigger}, the rest have {base}'**
  String setupUnevenPerGroup(int remCount, int bigger, int base);

  /// No description provided for @setupGroupSummary.
  ///
  /// In en, this message translates to:
  /// **'Group summary'**
  String get setupGroupSummary;

  /// No description provided for @setupRegAndGroups.
  ///
  /// In en, this message translates to:
  /// **'{total} registered · {groups} groups'**
  String setupRegAndGroups(int total, int groups);

  /// No description provided for @setupBalancePreview.
  ///
  /// In en, this message translates to:
  /// **'With age/gender balance — {preview}'**
  String setupBalancePreview(String preview);

  /// No description provided for @setupLeaderless.
  ///
  /// In en, this message translates to:
  /// **'{count} without a leader'**
  String setupLeaderless(int count);

  /// No description provided for @setupNoPassageLocation.
  ///
  /// In en, this message translates to:
  /// **'No passage/location set'**
  String get setupNoPassageLocation;

  /// No description provided for @setupNoLeader.
  ///
  /// In en, this message translates to:
  /// **'No leader assigned'**
  String get setupNoLeader;

  /// No description provided for @setupEditGroupMenu.
  ///
  /// In en, this message translates to:
  /// **'Edit leader/passage/location'**
  String get setupEditGroupMenu;

  /// No description provided for @setupEditGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String setupEditGroupTitle(String name);

  /// No description provided for @setupGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get setupGroupName;

  /// No description provided for @setupLeaderName.
  ///
  /// In en, this message translates to:
  /// **'Leader (shepherd) name'**
  String get setupLeaderName;

  /// No description provided for @setupLeaderPhone.
  ///
  /// In en, this message translates to:
  /// **'Leader phone'**
  String get setupLeaderPhone;

  /// No description provided for @setupPassage.
  ///
  /// In en, this message translates to:
  /// **'Passage (e.g. John 10)'**
  String get setupPassage;

  /// No description provided for @setupLocation.
  ///
  /// In en, this message translates to:
  /// **'Meeting place'**
  String get setupLocation;

  /// No description provided for @expColNo.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get expColNo;

  /// No description provided for @expArrFlight.
  ///
  /// In en, this message translates to:
  /// **'Arrival flight'**
  String get expArrFlight;

  /// No description provided for @expArrTime.
  ///
  /// In en, this message translates to:
  /// **'Arrival time'**
  String get expArrTime;

  /// No description provided for @expDepFlight.
  ///
  /// In en, this message translates to:
  /// **'Departure flight'**
  String get expDepFlight;

  /// No description provided for @expDepTime.
  ///
  /// In en, this message translates to:
  /// **'Departure time'**
  String get expDepTime;

  /// No description provided for @expOptions.
  ///
  /// In en, this message translates to:
  /// **'Selected options'**
  String get expOptions;

  /// No description provided for @expTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get expTotalCost;

  /// No description provided for @expPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get expPaymentStatus;

  /// No description provided for @expSubmittedCol.
  ///
  /// In en, this message translates to:
  /// **'Registration complete'**
  String get expSubmittedCol;

  /// No description provided for @expUnregistered.
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get expUnregistered;

  /// No description provided for @expIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get expIncomplete;

  /// No description provided for @expRoster.
  ///
  /// In en, this message translates to:
  /// **'Participant roster'**
  String get expRoster;

  /// No description provided for @regStepCompanion.
  ///
  /// In en, this message translates to:
  /// **'Companions'**
  String get regStepCompanion;

  /// No description provided for @regStepBuddy.
  ///
  /// In en, this message translates to:
  /// **'Buddy requests'**
  String get regStepBuddy;

  /// No description provided for @buddyTitle.
  ///
  /// In en, this message translates to:
  /// **'People you\'d like to be with'**
  String get buddyTitle;

  /// No description provided for @buddyDesc.
  ///
  /// In en, this message translates to:
  /// **'When you pick someone, a request is sent. It\'s confirmed only when they accept.'**
  String get buddyDesc;

  /// No description provided for @buddyRoommateSection.
  ///
  /// In en, this message translates to:
  /// **'Roommate requests'**
  String get buddyRoommateSection;

  /// No description provided for @buddyGroupSection.
  ///
  /// In en, this message translates to:
  /// **'Bible study group requests'**
  String get buddyGroupSection;

  /// No description provided for @buddySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or Bible name…'**
  String get buddySearchHint;

  /// No description provided for @buddySendRoommate.
  ///
  /// In en, this message translates to:
  /// **'Request as roommate'**
  String get buddySendRoommate;

  /// No description provided for @buddySendGroup.
  ///
  /// In en, this message translates to:
  /// **'Request same group'**
  String get buddySendGroup;

  /// No description provided for @buddySentSection.
  ///
  /// In en, this message translates to:
  /// **'Requests you sent'**
  String get buddySentSection;

  /// No description provided for @buddyReceivedSection.
  ///
  /// In en, this message translates to:
  /// **'Requests you received'**
  String get buddyReceivedSection;

  /// No description provided for @buddyStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get buddyStatusPending;

  /// No description provided for @buddyStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get buddyStatusAccepted;

  /// No description provided for @buddyStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get buddyStatusDeclined;

  /// No description provided for @buddyAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get buddyAccept;

  /// No description provided for @buddyDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get buddyDecline;

  /// No description provided for @buddyKindRoommate.
  ///
  /// In en, this message translates to:
  /// **'Roommate'**
  String get buddyKindRoommate;

  /// No description provided for @buddyKindGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get buddyKindGroup;

  /// No description provided for @buddyReqSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get buddyReqSent;

  /// No description provided for @buddyRoommateSameGenderNote.
  ///
  /// In en, this message translates to:
  /// **'Roommate requests can only be sent to the same gender.'**
  String get buddyRoommateSameGenderNote;

  /// No description provided for @buddyReceivedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests received'**
  String get buddyReceivedEmpty;

  /// No description provided for @buddyNoCandidates.
  ///
  /// In en, this message translates to:
  /// **'No other participants to pick yet'**
  String get buddyNoCandidates;

  /// No description provided for @buddyRequestLine.
  ///
  /// In en, this message translates to:
  /// **'{kind} request'**
  String buddyRequestLine(String kind);

  /// No description provided for @companionTitle.
  ///
  /// In en, this message translates to:
  /// **'Companions (couple/family)'**
  String get companionTitle;

  /// No description provided for @companionDesc.
  ///
  /// In en, this message translates to:
  /// **'If you\'re coming with a spouse or family, add them here. Each counts toward headcount and pickup.'**
  String get companionDesc;

  /// No description provided for @companionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add companion'**
  String get companionAdd;

  /// No description provided for @companionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if you\'re attending alone.'**
  String get companionEmpty;

  /// No description provided for @companionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get companionLanguage;

  /// No description provided for @companionSameFlight.
  ///
  /// In en, this message translates to:
  /// **'Same flight as me'**
  String get companionSameFlight;

  /// No description provided for @companionArrivalFlightNo.
  ///
  /// In en, this message translates to:
  /// **'Companion\'s arrival flight'**
  String get companionArrivalFlightNo;

  /// No description provided for @companionDepartureFlightNo.
  ///
  /// In en, this message translates to:
  /// **'Companion\'s departure flight'**
  String get companionDepartureFlightNo;

  /// No description provided for @companionNeedsPickup.
  ///
  /// In en, this message translates to:
  /// **'Needs pickup'**
  String get companionNeedsPickup;

  /// No description provided for @companionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} companion(s)'**
  String companionCount(int count);

  /// No description provided for @companionAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add companion'**
  String get companionAddTitle;

  /// No description provided for @companionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit companion'**
  String get companionEditTitle;

  /// No description provided for @asnTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get asnTitle;

  /// No description provided for @asnAutoAssign.
  ///
  /// In en, this message translates to:
  /// **'Auto-assign'**
  String get asnAutoAssign;

  /// No description provided for @asnAutoRoomsDone.
  ///
  /// In en, this message translates to:
  /// **'Rooms auto-assigned — {count} placed'**
  String asnAutoRoomsDone(int count);

  /// No description provided for @asnAutoGroupsDone.
  ///
  /// In en, this message translates to:
  /// **'Groups auto-assigned — {count} placed'**
  String asnAutoGroupsDone(int count);

  /// No description provided for @asnUnplaced.
  ///
  /// In en, this message translates to:
  /// **'{count} could not be placed'**
  String asnUnplaced(int count);

  /// No description provided for @asnUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get asnUnassigned;

  /// No description provided for @asnUnassignedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unassigned'**
  String asnUnassignedCount(int count);

  /// No description provided for @asnPickRoom.
  ///
  /// In en, this message translates to:
  /// **'Choose a room'**
  String get asnPickRoom;

  /// No description provided for @asnPickGroup.
  ///
  /// In en, this message translates to:
  /// **'Choose a group'**
  String get asnPickGroup;

  /// No description provided for @asnNoRooms.
  ///
  /// In en, this message translates to:
  /// **'Create rooms in Setup first'**
  String get asnNoRooms;

  /// No description provided for @asnNoGroups.
  ///
  /// In en, this message translates to:
  /// **'Create groups in Setup first'**
  String get asnNoGroups;

  /// No description provided for @asnAllAssigned.
  ///
  /// In en, this message translates to:
  /// **'Everyone is assigned'**
  String get asnAllAssigned;

  /// No description provided for @dashAssignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign rooms and Bible study groups'**
  String get dashAssignSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
