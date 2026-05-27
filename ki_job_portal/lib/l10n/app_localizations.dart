import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('hi'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @languageSelection.
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get languageSelection;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @find_jobs.
  ///
  /// In en, this message translates to:
  /// **'Find Jobs'**
  String get find_jobs;

  /// No description provided for @find_workers.
  ///
  /// In en, this message translates to:
  /// **'Find Workers'**
  String get find_workers;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @accountPreferences.
  ///
  /// In en, this message translates to:
  /// **'Account & Preferences'**
  String get accountPreferences;

  /// No description provided for @verificationDocuments.
  ///
  /// In en, this message translates to:
  /// **'Verification & Documents'**
  String get verificationDocuments;

  /// No description provided for @verificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Aadhar, ID, and certificates'**
  String get verificationSubtitle;

  /// No description provided for @rolePreferences.
  ///
  /// In en, this message translates to:
  /// **'Role Preferences'**
  String get rolePreferences;

  /// No description provided for @hiringNeeds.
  ///
  /// In en, this message translates to:
  /// **'Hiring needs'**
  String get hiringNeeds;

  /// No description provided for @jobPreferences.
  ///
  /// In en, this message translates to:
  /// **'Job preferences'**
  String get jobPreferences;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get languageSubtitle;

  /// No description provided for @securityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityPrivacy;

  /// No description provided for @privacyControls.
  ///
  /// In en, this message translates to:
  /// **'Privacy Controls'**
  String get privacyControls;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile and contact visibility'**
  String get privacySubtitle;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @blockedUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage blocked accounts'**
  String get blockedUsersSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when something important happens.'**
  String get notificationsHint;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage alerts and messages'**
  String get notificationsSubtitle;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ, contact us'**
  String get helpSupportSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark appearance'**
  String get darkModeSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Terms, Privacy, Version 1.0.0'**
  String get aboutSubtitle;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About KI Job Portal'**
  String get aboutApp;

  /// No description provided for @aboutContent.
  ///
  /// In en, this message translates to:
  /// **'Version: 1.0.0\n\nThe most comprehensive job portal for blue and white collar workers.\n\n© 2026 KI Job Portal. All rights reserved.'**
  String get aboutContent;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get logoutMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @earnSkills.
  ///
  /// In en, this message translates to:
  /// **'Earn Through Your Skills'**
  String get earnSkills;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account — '**
  String get alreadyAccount;

  /// No description provided for @loginUnderlined.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginUnderlined;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'TERMS & CONDITIONS'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY POLICY'**
  String get privacy;

  /// No description provided for @copyrightMarketplace.
  ///
  /// In en, this message translates to:
  /// **'© 2026 KI Marketplace. All rights reserved.'**
  String get copyrightMarketplace;

  /// No description provided for @whatBrings.
  ///
  /// In en, this message translates to:
  /// **'What brings you to KI?'**
  String get whatBrings;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to use the platform. You can change this later.'**
  String get selectRole;

  /// No description provided for @wantWork.
  ///
  /// In en, this message translates to:
  /// **'I want to work'**
  String get wantWork;

  /// No description provided for @findJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find jobs, track applications, and earn.'**
  String get findJobsSubtitle;

  /// No description provided for @wantHire.
  ///
  /// In en, this message translates to:
  /// **'I want to hire'**
  String get wantHire;

  /// No description provided for @postJobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post jobs, find talent, and manage applicants.'**
  String get postJobsSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @userNotExist.
  ///
  /// In en, this message translates to:
  /// **'User doesn\'t exist. Please sign up first.'**
  String get userNotExist;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your account to continue where you left off.'**
  String get loginSubtitle;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'MOBILE NUMBER'**
  String get mobileNumber;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @validNumber.
  ///
  /// In en, this message translates to:
  /// **'Valid number required'**
  String get validNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendCode;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found. Please sign up first.'**
  String get accountNotFound;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalidOtp;

  /// No description provided for @securityCheck.
  ///
  /// In en, this message translates to:
  /// **'Security Check'**
  String get securityCheck;

  /// No description provided for @verifyYour.
  ///
  /// In en, this message translates to:
  /// **'Verify Your'**
  String get verifyYour;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @secureCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a secure code to your device. Enter the digits below to authenticate.'**
  String get secureCodeSent;

  /// No description provided for @authorizing.
  ///
  /// In en, this message translates to:
  /// **'AUTHORIZING...'**
  String get authorizing;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @didntReceive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceive;

  /// No description provided for @secureVerification.
  ///
  /// In en, this message translates to:
  /// **'Secure Verification'**
  String get secureVerification;

  /// No description provided for @secureVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protecting your professional data is our top priority. Two-factor authentication keeps your profile safe.'**
  String get secureVerificationSubtitle;

  /// No description provided for @communityFeed.
  ///
  /// In en, this message translates to:
  /// **'Community Feed'**
  String get communityFeed;

  /// No description provided for @tabLatest.
  ///
  /// In en, this message translates to:
  /// **'LATEST'**
  String get tabLatest;

  /// No description provided for @tabTrending.
  ///
  /// In en, this message translates to:
  /// **'TRENDING'**
  String get tabTrending;

  /// No description provided for @tabNetwork.
  ///
  /// In en, this message translates to:
  /// **'NETWORK'**
  String get tabNetwork;

  /// No description provided for @errorLoadingFeed.
  ///
  /// In en, this message translates to:
  /// **'Error loading feed: '**
  String get errorLoadingFeed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @beFirstToShare.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share an update with the community!'**
  String get beFirstToShare;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a Conversation'**
  String get startConversation;

  /// No description provided for @shareProfessionalUpdates.
  ///
  /// In en, this message translates to:
  /// **'Share your professional updates...'**
  String get shareProfessionalUpdates;

  /// No description provided for @postPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get postPhoto;

  /// No description provided for @postVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get postVideo;

  /// No description provided for @postEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get postEvent;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get available;

  /// No description provided for @asks.
  ///
  /// In en, this message translates to:
  /// **'Asks: '**
  String get asks;

  /// No description provided for @hireMe.
  ///
  /// In en, this message translates to:
  /// **'HIRE ME'**
  String get hireMe;

  /// No description provided for @tapToReadFullDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap to read full description →'**
  String get tapToReadFullDescription;

  /// No description provided for @tapToViewFullProfile.
  ///
  /// In en, this message translates to:
  /// **'Tap to view full profile →'**
  String get tapToViewFullProfile;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @postSavedSnackBar.
  ///
  /// In en, this message translates to:
  /// **'Post saved! Find it in the Saved tab.'**
  String get postSavedSnackBar;

  /// No description provided for @contactBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get contactBtn;

  /// No description provided for @applyForThisJob.
  ///
  /// In en, this message translates to:
  /// **'APPLY FOR THIS JOB'**
  String get applyForThisJob;

  /// No description provided for @alreadyApplied.
  ///
  /// In en, this message translates to:
  /// **'ALREADY APPLIED'**
  String get alreadyApplied;

  /// No description provided for @chooseHowToConnect.
  ///
  /// In en, this message translates to:
  /// **'Choose how to connect'**
  String get chooseHowToConnect;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start a chat on KI Job Portal'**
  String get startChat;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Exp'**
  String get experience;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Yrs'**
  String get years;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @noJobRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No job requests yet'**
  String get noJobRequestsYet;

  /// No description provided for @noApplicationsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t applied to any jobs yet'**
  String get noApplicationsYet;

  /// No description provided for @noSavedPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved posts yet'**
  String get noSavedPostsYet;

  /// No description provided for @couldNotLaunchDoc.
  ///
  /// In en, this message translates to:
  /// **'Could not launch document'**
  String get couldNotLaunchDoc;

  /// No description provided for @referralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied!'**
  String get referralCodeCopied;

  /// No description provided for @tabAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get tabAbout;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'STATS'**
  String get tabStats;

  /// No description provided for @tabPosts.
  ///
  /// In en, this message translates to:
  /// **'POSTS'**
  String get tabPosts;

  /// No description provided for @tabSaved.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get tabSaved;

  /// No description provided for @tabApplied.
  ///
  /// In en, this message translates to:
  /// **'APPLIED'**
  String get tabApplied;

  /// No description provided for @tabMyRequests.
  ///
  /// In en, this message translates to:
  /// **'MY REQUESTS'**
  String get tabMyRequests;

  /// No description provided for @tabVisitors.
  ///
  /// In en, this message translates to:
  /// **'VISITORS'**
  String get tabVisitors;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @portfolioDocuments.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Documents'**
  String get portfolioDocuments;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommendedForYou;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get contactPerson;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @officeLocation.
  ///
  /// In en, this message translates to:
  /// **'Office Location'**
  String get officeLocation;

  /// No description provided for @viewPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'View Public Profile'**
  String get viewPublicProfile;

  /// No description provided for @aboutCompany.
  ///
  /// In en, this message translates to:
  /// **'About Company'**
  String get aboutCompany;

  /// No description provided for @documentsCertifications.
  ///
  /// In en, this message translates to:
  /// **'Documents & Certifications'**
  String get documentsCertifications;

  /// No description provided for @noDocumentsUploaded.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded yet'**
  String get noDocumentsUploaded;

  /// No description provided for @noDescriptionCompany.
  ///
  /// In en, this message translates to:
  /// **'No description provided yet. Add your company profile to attract more professional workers.'**
  String get noDescriptionCompany;

  /// No description provided for @whoViewedMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Who viewed my profile?'**
  String get whoViewedMyProfile;

  /// No description provided for @expertiseAndBio.
  ///
  /// In en, this message translates to:
  /// **'Expertise & Bio'**
  String get expertiseAndBio;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @referralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCodeLabel;

  /// No description provided for @noDocumentsUploadedYet.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded yet'**
  String get noDocumentsUploadedYet;

  /// No description provided for @noNewJobsAtTheMoment.
  ///
  /// In en, this message translates to:
  /// **'No new jobs at the moment.'**
  String get noNewJobsAtTheMoment;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE JOBS'**
  String get activeJobs;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'CREDITS'**
  String get credits;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'STRENGTH'**
  String get strength;

  /// No description provided for @yourNextMasterworkIsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your next masterwork is waiting.'**
  String get yourNextMasterworkIsWaiting;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get namaste;

  /// No description provided for @karigar.
  ///
  /// In en, this message translates to:
  /// **'Karigar'**
  String get karigar;

  /// No description provided for @employer.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get employer;

  /// No description provided for @hirer.
  ///
  /// In en, this message translates to:
  /// **'Hirer'**
  String get hirer;

  /// No description provided for @postJob.
  ///
  /// In en, this message translates to:
  /// **'Post Job'**
  String get postJob;

  /// No description provided for @findPros.
  ///
  /// In en, this message translates to:
  /// **'Find Pros'**
  String get findPros;

  /// No description provided for @myJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get myJobs;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @businessInsights.
  ///
  /// In en, this message translates to:
  /// **'Business Insights'**
  String get businessInsights;

  /// No description provided for @karigarFeed.
  ///
  /// In en, this message translates to:
  /// **'Karigar Feed'**
  String get karigarFeed;

  /// No description provided for @noRecentUpdates.
  ///
  /// In en, this message translates to:
  /// **'No recent updates.'**
  String get noRecentUpdates;

  /// No description provided for @featuredKarigars.
  ///
  /// In en, this message translates to:
  /// **'FEATURED KARIGARS'**
  String get featuredKarigars;

  /// No description provided for @viewTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'View Transaction History'**
  String get viewTransactionHistory;

  /// No description provided for @availableCredits.
  ///
  /// In en, this message translates to:
  /// **'Available Credits'**
  String get availableCredits;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @recruitmentCredits.
  ///
  /// In en, this message translates to:
  /// **'Recruitment Credits'**
  String get recruitmentCredits;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @sub.
  ///
  /// In en, this message translates to:
  /// **'Sub'**
  String get sub;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @whatDoYouWantToTalkAbout.
  ///
  /// In en, this message translates to:
  /// **'What do you want to talk about?'**
  String get whatDoYouWantToTalkAbout;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @jobApplications.
  ///
  /// In en, this message translates to:
  /// **'Job Applications'**
  String get jobApplications;

  /// No description provided for @tabNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get tabNew;

  /// No description provided for @tabInvites.
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get tabInvites;

  /// No description provided for @searchJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Search jobs, companies...'**
  String get searchJobsHint;

  /// No description provided for @unlockMoreOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Unlock More Opportunities'**
  String get unlockMoreOpportunities;

  /// No description provided for @subscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlans;

  /// No description provided for @creditPacks.
  ///
  /// In en, this message translates to:
  /// **'Credit Packs'**
  String get creditPacks;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlan;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message_btn.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message_btn;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @workers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workers;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @myCareer.
  ///
  /// In en, this message translates to:
  /// **'MY CAREER'**
  String get myCareer;

  /// No description provided for @leaveRating.
  ///
  /// In en, this message translates to:
  /// **'LEAVE A RATING'**
  String get leaveRating;

  /// No description provided for @ratingLocked.
  ///
  /// In en, this message translates to:
  /// **'RATING LOCKED'**
  String get ratingLocked;

  /// No description provided for @securePayments.
  ///
  /// In en, this message translates to:
  /// **'SECURE PAYMENTS'**
  String get securePayments;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. No hidden charges.'**
  String get cancelAnytime;

  /// No description provided for @securePaymentsFooter.
  ///
  /// In en, this message translates to:
  /// **'© 2024 KI Marketplace. Secure payments via encrypted gateways.'**
  String get securePaymentsFooter;

  /// No description provided for @notif_chat_title.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get notif_chat_title;

  /// No description provided for @notif_post_like_title.
  ///
  /// In en, this message translates to:
  /// **'New Like'**
  String get notif_post_like_title;

  /// No description provided for @notif_post_comment_title.
  ///
  /// In en, this message translates to:
  /// **'New Comment'**
  String get notif_post_comment_title;

  /// No description provided for @notif_post_approved_title.
  ///
  /// In en, this message translates to:
  /// **'Post Approved'**
  String get notif_post_approved_title;

  /// No description provided for @notif_invite_title.
  ///
  /// In en, this message translates to:
  /// **'Job Invitation'**
  String get notif_invite_title;

  /// No description provided for @notif_default_title.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notif_default_title;

  /// No description provided for @notif_chat_body.
  ///
  /// In en, this message translates to:
  /// **'You have a new message'**
  String get notif_chat_body;

  /// No description provided for @notif_post_like_body.
  ///
  /// In en, this message translates to:
  /// **'Someone liked your post'**
  String get notif_post_like_body;

  /// No description provided for @notif_post_comment_body.
  ///
  /// In en, this message translates to:
  /// **'Someone commented on your post'**
  String get notif_post_comment_body;

  /// No description provided for @notif_post_approved_body.
  ///
  /// In en, this message translates to:
  /// **'Your post has been approved'**
  String get notif_post_approved_body;

  /// No description provided for @notif_invite_body.
  ///
  /// In en, this message translates to:
  /// **'You have a new job invitation'**
  String get notif_invite_body;

  /// No description provided for @notif_post_share_title.
  ///
  /// In en, this message translates to:
  /// **'Post Shared'**
  String get notif_post_share_title;

  /// No description provided for @notif_post_share_body.
  ///
  /// In en, this message translates to:
  /// **'Someone shared your post'**
  String get notif_post_share_body;

  /// No description provided for @listAvailability.
  ///
  /// In en, this message translates to:
  /// **'List Availability'**
  String get listAvailability;

  /// No description provided for @postAJob.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get postAJob;

  /// No description provided for @selectSkillExpertise.
  ///
  /// In en, this message translates to:
  /// **'Select your Skill / Expertise'**
  String get selectSkillExpertise;

  /// No description provided for @expectedPay.
  ///
  /// In en, this message translates to:
  /// **'Expected Pay'**
  String get expectedPay;

  /// No description provided for @salaryRate.
  ///
  /// In en, this message translates to:
  /// **'Salary / Rate'**
  String get salaryRate;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @subLocationArea.
  ///
  /// In en, this message translates to:
  /// **'Sub-Location / Area'**
  String get subLocationArea;

  /// No description provided for @experienceExample.
  ///
  /// In en, this message translates to:
  /// **'Experience (e.g. 5 Years)'**
  String get experienceExample;

  /// No description provided for @specificSkills.
  ///
  /// In en, this message translates to:
  /// **'Specific Skills'**
  String get specificSkills;

  /// No description provided for @saveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get saveDetails;

  /// No description provided for @addEventDetails.
  ///
  /// In en, this message translates to:
  /// **'Add Event Details'**
  String get addEventDetails;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get eventTitle;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @saveEvent.
  ///
  /// In en, this message translates to:
  /// **'Save Event'**
  String get saveEvent;

  /// No description provided for @includedInPlan.
  ///
  /// In en, this message translates to:
  /// **'Included in your plan'**
  String get includedInPlan;

  /// No description provided for @activePlan.
  ///
  /// In en, this message translates to:
  /// **'✅ Active Plan'**
  String get activePlan;

  /// No description provided for @renewPlan.
  ///
  /// In en, this message translates to:
  /// **'Renew Plan'**
  String get renewPlan;

  /// No description provided for @upgradeTo.
  ///
  /// In en, this message translates to:
  /// **'⬆ Upgrade to {planName}'**
  String upgradeTo(String planName);

  /// No description provided for @creditsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Credits'**
  String creditsCount(int count);

  /// No description provided for @buyBtn.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyBtn;

  /// No description provided for @creditActivity.
  ///
  /// In en, this message translates to:
  /// **'Credit Activity'**
  String get creditActivity;

  /// No description provided for @workActivity.
  ///
  /// In en, this message translates to:
  /// **'Work Activity'**
  String get workActivity;

  /// No description provided for @noCreditActivity.
  ///
  /// In en, this message translates to:
  /// **'No credit activity yet'**
  String get noCreditActivity;

  /// No description provided for @noWorkActivity.
  ///
  /// In en, this message translates to:
  /// **'No work activity yet'**
  String get noWorkActivity;

  /// No description provided for @ratingsAndReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get ratingsAndReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;
  String get noBio;
  String get notSet;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
