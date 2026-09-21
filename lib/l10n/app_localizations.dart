import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ko'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @billingDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete billing account'**
  String get billingDelete;

  /// No description provided for @billingDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete the Tokenfront billing account and purchase verification records. Ad removal and the restoration link end; restoration is not guaranteed after deletion. This does not refund purchases or delete Google / Google Play records. Continue and verify the same Google account?'**
  String get billingDeleteWarning;

  /// No description provided for @billingDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get billingDeleteCancel;

  /// No description provided for @billingDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete and verify with Google'**
  String get billingDeleteConfirm;

  /// No description provided for @billingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Billing account deleted. Ad removal ended on this device.'**
  String get billingDeleted;

  /// No description provided for @billingDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Deletion is not confirmed. Retry soon with the same account. If you cannot retry, contact korea@toris.kr.'**
  String get billingDeleteFailed;

  /// No description provided for @billingDeleteLocalFailed.
  ///
  /// In en, this message translates to:
  /// **'Server account deleted, but local cleanup failed. Keep the app open and retry. Cached data may remain on disk; contact korea@toris.kr if this continues.'**
  String get billingDeleteLocalFailed;

  /// No description provided for @recoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover three signals'**
  String get recoveryTitle;

  /// No description provided for @recoveryInstruction.
  ///
  /// In en, this message translates to:
  /// **'Tap 1, 2 or 3 to choose a destination. Movement and combat are automatic. If your token falls, another continues. Progress stays.'**
  String get recoveryInstruction;

  /// No description provided for @recoveryAutomatic.
  ///
  /// In en, this message translates to:
  /// **'AUTO MOVE · AUTO COMBAT · AUTO CONTINUE'**
  String get recoveryAutomatic;

  /// Recovery HUD button that dismisses the first-run instruction overlay.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE DESTINATION'**
  String get recoveryChooseDestination;

  /// No description provided for @recoveryWon.
  ///
  /// In en, this message translates to:
  /// **'SIGNALS RECOVERED'**
  String get recoveryWon;

  /// No description provided for @recoveryLost.
  ///
  /// In en, this message translates to:
  /// **'RECOVERY ENDED'**
  String get recoveryLost;

  /// No description provided for @recoveryTimeout.
  ///
  /// In en, this message translates to:
  /// **'TIMEOUT'**
  String get recoveryTimeout;

  /// No description provided for @recoveryAlliesLost.
  ///
  /// In en, this message translates to:
  /// **'ALLIES LOST'**
  String get recoveryAlliesLost;

  /// No description provided for @recoveryProgress.
  ///
  /// In en, this message translates to:
  /// **'{count}/3 signals recovered'**
  String recoveryProgress(int count);

  /// No description provided for @recoveryDestination.
  ///
  /// In en, this message translates to:
  /// **'Signal {number}: {seconds}/8s'**
  String recoveryDestination(int number, int seconds);

  /// Application title shown by the operating system and browser.
  ///
  /// In en, this message translates to:
  /// **'Tokenfront: Orbital Signal War'**
  String get appTitle;

  /// Short product tagline on the lobby header.
  ///
  /// In en, this message translates to:
  /// **'FOUR AI CORES. 4,000 LIVE TOKENS. ONE LAST RELAY.'**
  String get lobbyTagline;

  /// Selected faction signal heading.
  ///
  /// In en, this message translates to:
  /// **'{faction} SIGNAL'**
  String factionSignal(String faction);

  /// Short description of the selected army.
  ///
  /// In en, this message translates to:
  /// **'1,000 live AI tokens · Lv.1–10 balanced · one continuous command'**
  String get factionBrief;

  /// Primary button that starts a battle.
  ///
  /// In en, this message translates to:
  /// **'DEPLOY TO ORBIT'**
  String get deploySignal;

  /// Lobby locker button with the current War Token balance.
  ///
  /// In en, this message translates to:
  /// **'LOCKER  {balance} WT'**
  String lockerBalance(int balance);

  /// Compact label for the settings button.
  ///
  /// In en, this message translates to:
  /// **'TUNE'**
  String get tune;

  /// Full label for the settings button.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL SETTINGS'**
  String get signalSettings;

  /// Lobby status showing that the game works offline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get offline;

  /// Accessibility label for a faction selection card.
  ///
  /// In en, this message translates to:
  /// **'Choose the {faction} AI core'**
  String chooseFaction(String faction);

  /// Visible number of units in an army.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 AI TOKEN} other{{count} AI TOKENS}}'**
  String unitsCount(int count);

  /// Rules-strip label for units.
  ///
  /// In en, this message translates to:
  /// **'AI TOKENS'**
  String get units;

  /// Rules-strip label for a higher-level unit.
  ///
  /// In en, this message translates to:
  /// **'HIGH LV'**
  String get highLevel;

  /// Rules-strip outcome label.
  ///
  /// In en, this message translates to:
  /// **'WINS'**
  String get wins;

  /// Rules-strip label for equal levels.
  ///
  /// In en, this message translates to:
  /// **'EQUAL'**
  String get equalLevel;

  /// Rules-strip label for a controlled unit death.
  ///
  /// In en, this message translates to:
  /// **'DEATH'**
  String get death;

  /// Short label for command handoffs.
  ///
  /// In en, this message translates to:
  /// **'RELAYS'**
  String get relays;

  /// Rules-strip movement label.
  ///
  /// In en, this message translates to:
  /// **'MOVE'**
  String get move;

  /// Rules-strip movement controls.
  ///
  /// In en, this message translates to:
  /// **'STICK / WASD'**
  String get stickWasd;

  /// Short dash action label.
  ///
  /// In en, this message translates to:
  /// **'DASH'**
  String get dash;

  /// Rules-strip dash controls.
  ///
  /// In en, this message translates to:
  /// **'BUTTON / SPACE'**
  String get buttonSpace;

  /// Accessibility label for the lobby sponsor slot.
  ///
  /// In en, this message translates to:
  /// **'Sponsor banner area'**
  String get sponsorBannerArea;

  /// Sponsor placeholder heading.
  ///
  /// In en, this message translates to:
  /// **'SPONSOR SIGNAL'**
  String get sponsorSignal;

  /// Sponsor placeholder location.
  ///
  /// In en, this message translates to:
  /// **'LOBBY PLACEMENT'**
  String get lobbyPlacement;

  /// Settings section heading for language.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSection;

  /// Label for the application language selector.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY LANGUAGE'**
  String get displayLanguage;

  /// Explanation below the application language selector.
  ///
  /// In en, this message translates to:
  /// **'Follow the device language or choose one for this game.'**
  String get displayLanguageDetail;

  /// Language option that follows the operating system.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM DEFAULT'**
  String get languageSystem;

  /// English language option shown using its own name.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Korean language option shown using its own name.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// Japanese language option shown using its own name.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// Simplified Chinese language option shown using its own name.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageSimplifiedChinese;

  /// Settings panel title.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL CONDITIONING'**
  String get settingsTitle;

  /// Settings panel explanation.
  ///
  /// In en, this message translates to:
  /// **'Tune the battlefield without changing combat strength.'**
  String get settingsSubtitle;

  /// Tooltip for closing the settings panel.
  ///
  /// In en, this message translates to:
  /// **'Close settings'**
  String get closeSettings;

  /// Settings section for presentation and controls.
  ///
  /// In en, this message translates to:
  /// **'BATTLEFIELD'**
  String get battlefieldSection;

  /// Low-spec graphics option label.
  ///
  /// In en, this message translates to:
  /// **'LOW-SPEC FILTER'**
  String get lowSpecFilter;

  /// Low-spec graphics option explanation.
  ///
  /// In en, this message translates to:
  /// **'Cuts particles and expensive field details.'**
  String get lowSpecFilterDetail;

  /// Reduced-motion option label.
  ///
  /// In en, this message translates to:
  /// **'REDUCE MOTION'**
  String get reduceMotion;

  /// Reduced-motion option explanation.
  ///
  /// In en, this message translates to:
  /// **'Shortens relay camera travel and large transitions.'**
  String get reduceMotionDetail;

  /// Mouse camera option label.
  ///
  /// In en, this message translates to:
  /// **'MOUSE CAMERA'**
  String get mouseCamera;

  /// Mouse camera option explanation.
  ///
  /// In en, this message translates to:
  /// **'Enables wheel zoom and drag panning on web.'**
  String get mouseCameraDetail;

  /// Audio option label.
  ///
  /// In en, this message translates to:
  /// **'AUDIO CUES'**
  String get audioCues;

  /// Audio option explanation.
  ///
  /// In en, this message translates to:
  /// **'Plays bounded dash, combat, and relay signals.'**
  String get audioCuesDetail;

  /// Haptic feedback option label.
  ///
  /// In en, this message translates to:
  /// **'HAPTIC CUES'**
  String get hapticCues;

  /// Haptic feedback option explanation.
  ///
  /// In en, this message translates to:
  /// **'Signals dash and command relay on supported devices.'**
  String get hapticCuesDetail;

  /// Settings section for privacy choices.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacySection;

  /// Analytics sharing option label.
  ///
  /// In en, this message translates to:
  /// **'SHARE ANALYTICS'**
  String get shareAnalytics;

  /// Analytics sharing option explanation.
  ///
  /// In en, this message translates to:
  /// **'Sends buffered anonymous match events when online.'**
  String get shareAnalyticsDetail;

  /// Advertising request option label.
  ///
  /// In en, this message translates to:
  /// **'AD REQUESTS'**
  String get adRequests;

  /// Advertising request option explanation.
  ///
  /// In en, this message translates to:
  /// **'Allows lobby and result ads. Tracking still needs platform permission.'**
  String get adRequestsDetail;

  /// Privacy defaults and offline-play assurance.
  ///
  /// In en, this message translates to:
  /// **'Both choices start off. Offline matches and rewards work when either choice is off.'**
  String get privacyDefaultNote;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY POLICY'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyOptions.
  ///
  /// In en, this message translates to:
  /// **'AD PRIVACY OPTIONS'**
  String get privacyOptions;

  /// No description provided for @privacyPolicyEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective date: 2026-08-05'**
  String get privacyPolicyEffectiveDate;

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In en, this message translates to:
  /// **'Tokenfront is an offline single-player game. Gameplay and local progress stay on your device. Optional Google AdMob ads may process ad requests and device/ad identifiers when you enable ad requests and consent permits them.'**
  String get privacyPolicyIntro;

  /// No description provided for @privacyDataStoredTitle.
  ///
  /// In en, this message translates to:
  /// **'DATA STORED ON YOUR DEVICE'**
  String get privacyDataStoredTitle;

  /// No description provided for @privacyDataStoredBody.
  ///
  /// In en, this message translates to:
  /// **'Tokenfront stores War Token balance, cosmetic unlocks and equipment, language, accessibility, audio, camera, haptic and privacy choices, and Signal Chronicle progress in app-private local storage. It is not uploaded and is removed when app storage is cleared or the app is uninstalled.'**
  String get privacyDataStoredBody;

  /// No description provided for @privacyAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'ANALYTICS'**
  String get privacyAnalyticsTitle;

  /// No description provided for @privacyAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Gameplay and performance events can exist in a temporary memory buffer of up to 500 entries. This release uses no analytics transport, sends no events, and discards the buffer when the process ends.'**
  String get privacyAnalyticsBody;

  /// No description provided for @privacyAdvertisingTitle.
  ///
  /// In en, this message translates to:
  /// **'ADVERTISING'**
  String get privacyAdvertisingTitle;

  /// No description provided for @privacyAdvertisingBody.
  ///
  /// In en, this message translates to:
  /// **'Debug/profile builds use Google test ad units; signed release builds use the configured Tokenfront production units. All requests are non-personalized; this does not prevent advertising-identifier collection. Optional lobby and result banners, result rewarded ads, and result-exit interstitials are requested only after the Google consent flow permits them. AdMob may process ad requests, device information, and advertising identifiers as described by Google. Turning off AD REQUESTS stops app ad requests; the base War Token reward never depends on an ad.'**
  String get privacyAdvertisingBody;

  /// No description provided for @privacyAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNTS, PERMISSIONS, AND THIRD PARTIES'**
  String get privacyAccountsTitle;

  /// No description provided for @privacyAccountsBody.
  ///
  /// In en, this message translates to:
  /// **'Shipped 1.2.0 has no login or purchases. Future-version draft, disabled and pending publication: optional Google sign-in would enable one-time remove-ads purchase/restore; gameplay needs no login and optional rewarded ads remain. Toris’s Cloudflare Workers backend would verify Google identity and Google Play purchases. D1 would retain pseudonymous (not anonymous) account bindings, encrypted purchase tokens and their hashes, order IDs, product/status and verification/check timestamps. Email/profile are not persisted by the backend. A signed entitlement and account binding would be cached locally for up to 30 days after positive verification, not as a retention limit for server records. Clearing app storage or logging out does not delete backend records. Deletion endpoint/workflow and retention policy are missing release blockers; no operational deletion service is promised. Privacy inquiries: korea@toris.kr; do not send tokens or passwords. No cloud game sync, social feature or access to location, camera, microphone, contacts, photos, calendar, health or messages is added.'**
  String get privacyAccountsBody;

  /// No description provided for @privacyHostingTitle.
  ///
  /// In en, this message translates to:
  /// **'PUBLIC POLICY HOSTING'**
  String get privacyHostingTitle;

  /// No description provided for @privacyHostingBody.
  ///
  /// In en, this message translates to:
  /// **'The public copy is hosted on Cloudflare Pages. Opening it uses your external browser, where Cloudflare may process ordinary web-request data under its terms. The Android app does not embed the public page or send gameplay or local-state data to it.'**
  String get privacyHostingBody;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'CHILDREN'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildrenBody.
  ///
  /// In en, this message translates to:
  /// **'Tokenfront is intended for players aged 13 and older and is not directed to children under 13. Advertising processing is described above; the proposed account and purchase processing is disabled and separately disclosed.'**
  String get privacyChildrenBody;

  /// No description provided for @privacyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'CHANGES'**
  String get privacyChangesTitle;

  /// No description provided for @privacyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Before a future release adds analytics transport, advertising, accounts, cloud services, or another off-device data flow, this policy and Google Play Data Safety declaration will be updated.'**
  String get privacyChangesBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get privacyContactTitle;

  /// No description provided for @privacyPublicUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'PUBLIC POLICY URL'**
  String get privacyPublicUrlLabel;

  /// No description provided for @privacyOpenPublicPage.
  ///
  /// In en, this message translates to:
  /// **'OPEN PUBLIC PAGE'**
  String get privacyOpenPublicPage;

  /// No description provided for @privacyCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'COPY URL'**
  String get privacyCopyUrl;

  /// No description provided for @privacyUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy URL copied.'**
  String get privacyUrlCopied;

  /// No description provided for @privacyOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The public policy page could not be opened. The full policy remains available here.'**
  String get privacyOpenFailed;

  /// No description provided for @releaseServicesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'NOT AVAILABLE IN THIS RELEASE'**
  String get releaseServicesUnavailable;

  /// Button that closes a bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'CLOSE PANEL'**
  String get closePanel;

  /// Visible disabled state in a segmented control.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get stateOff;

  /// Visible enabled state in a segmented control.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get stateOn;

  /// Screen-reader value for a disabled setting.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get semanticsOff;

  /// Screen-reader value for an enabled setting.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get semanticsOn;

  /// Insufficient-funds message in the locker.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Need 1 more War Token.} other{Need {count} more War Tokens.}}'**
  String needMoreWarTokens(int count);

  /// Cosmetics locker title.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL LOCKER'**
  String get signalLocker;

  /// Cosmetics-only economy explanation.
  ///
  /// In en, this message translates to:
  /// **'Spend War Tokens on field identity only. Combat strength never changes.'**
  String get lockerSubtitle;

  /// War Token balance in the locker.
  ///
  /// In en, this message translates to:
  /// **'{balance, plural, =1{1 WAR TOKEN} other{{balance} WAR TOKENS}}'**
  String warTokenBalance(int balance);

  /// Tooltip for closing the cosmetics locker.
  ///
  /// In en, this message translates to:
  /// **'Close Signal Locker'**
  String get closeSignalLocker;

  /// Cosmetic is currently equipped.
  ///
  /// In en, this message translates to:
  /// **'EQUIPPED'**
  String get equipped;

  /// Action to equip an unlocked cosmetic.
  ///
  /// In en, this message translates to:
  /// **'EQUIP'**
  String get equip;

  /// Action to unlock a cosmetic for a War Token cost.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK  {cost}'**
  String unlockCost(int cost);

  /// Cosmetic category for the controlled unit outline.
  ///
  /// In en, this message translates to:
  /// **'COMMAND EDGE'**
  String get commandEdge;

  /// Cosmetic category for movement trails.
  ///
  /// In en, this message translates to:
  /// **'MOVEMENT TRACE'**
  String get movementTrace;

  /// Cosmetic category for defeat effects.
  ///
  /// In en, this message translates to:
  /// **'DEFEAT MARK'**
  String get defeatMark;

  /// Name of the free default faction color.
  ///
  /// In en, this message translates to:
  /// **'FIELD ISSUE'**
  String get cosmeticFieldIssueName;

  /// Description of the free default faction color.
  ///
  /// In en, this message translates to:
  /// **'Standard faction signal pigment.'**
  String get cosmeticFieldIssueDescription;

  /// Name of the ivory command-edge cosmetic.
  ///
  /// In en, this message translates to:
  /// **'RELAY IVORY'**
  String get cosmeticRelayIvoryName;

  /// Description of the ivory command-edge cosmetic.
  ///
  /// In en, this message translates to:
  /// **'Ivory command outline; faction core stays readable.'**
  String get cosmeticRelayIvoryDescription;

  /// Name of the oxide command-edge cosmetic.
  ///
  /// In en, this message translates to:
  /// **'OXIDE EDGE'**
  String get cosmeticOxideEdgeName;

  /// Description of the oxide command-edge cosmetic.
  ///
  /// In en, this message translates to:
  /// **'Warm tactical edge for the controlled token.'**
  String get cosmeticOxideEdgeDescription;

  /// Name of the no-trail movement cosmetic.
  ///
  /// In en, this message translates to:
  /// **'CLEAN WAKE'**
  String get cosmeticCleanWakeName;

  /// Description of the no-trail movement cosmetic.
  ///
  /// In en, this message translates to:
  /// **'No persistent movement trace.'**
  String get cosmeticCleanWakeDescription;

  /// Name of the segmented movement trail.
  ///
  /// In en, this message translates to:
  /// **'RELAY TAPE'**
  String get cosmeticRelayTapeName;

  /// Description of the segmented movement trail.
  ///
  /// In en, this message translates to:
  /// **'A short segmented command trace.'**
  String get cosmeticRelayTapeDescription;

  /// Name of the oxide movement trail.
  ///
  /// In en, this message translates to:
  /// **'CINDER GRID'**
  String get cosmeticCinderGridName;

  /// Description of the oxide movement trail.
  ///
  /// In en, this message translates to:
  /// **'A sparse oxide wake for fast movement.'**
  String get cosmeticCinderGridDescription;

  /// Name of the default defeat effect.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL RING'**
  String get cosmeticSignalRingName;

  /// Description of the default defeat effect.
  ///
  /// In en, this message translates to:
  /// **'Standard compact defeat pulse.'**
  String get cosmeticSignalRingDescription;

  /// Name of the geometric defeat effect.
  ///
  /// In en, this message translates to:
  /// **'FOUR-WAY FRACTURE'**
  String get cosmeticFractureName;

  /// Description of the geometric defeat effect.
  ///
  /// In en, this message translates to:
  /// **'A crisp geometric break with no gameplay effect.'**
  String get cosmeticFractureDescription;

  /// Name of the echo-cycle faction color grant.
  ///
  /// In en, this message translates to:
  /// **'ECHO ORBIT'**
  String get cosmeticEchoOrbitName;

  /// No description provided for @cosmeticEchoOrbitDescription.
  ///
  /// In en, this message translates to:
  /// **'Residual orbit pigment granted after the first echo cycle.'**
  String get cosmeticEchoOrbitDescription;

  /// Name of the dual-ending movement trail grant.
  ///
  /// In en, this message translates to:
  /// **'CHECKSUM SCAR'**
  String get cosmeticChecksumScarName;

  /// No description provided for @cosmeticChecksumScarDescription.
  ///
  /// In en, this message translates to:
  /// **'A residual scar trail granted for recording both endings.'**
  String get cosmeticChecksumScarDescription;

  /// Battle notice after the player faction is eliminated.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL LOST  /  OBSERVING REMAINING WAR'**
  String get signalLostObserving;

  /// Screen-reader battle time remaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining {time}'**
  String timeRemaining(String time);

  /// Screen-reader count of surviving units in a faction.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{faction} 1 live AI token} other{{faction} {count} live AI tokens}}'**
  String factionAlive(String faction, int count);

  /// Compact battle control for mouse camera.
  ///
  /// In en, this message translates to:
  /// **'CAM'**
  String get cameraShort;

  /// Compact battle control for low-power mode.
  ///
  /// In en, this message translates to:
  /// **'ECO'**
  String get ecoShort;

  /// Compact battle control for camera recenter.
  ///
  /// In en, this message translates to:
  /// **'LOCK'**
  String get lockShort;

  /// Screen-reader label for the mouse camera toggle.
  ///
  /// In en, this message translates to:
  /// **'Mouse drag and wheel camera'**
  String get mouseCameraSemantics;

  /// Screen-reader label for the low-power toggle.
  ///
  /// In en, this message translates to:
  /// **'Low power mode'**
  String get lowPowerModeSemantics;

  /// Screen-reader label for camera recenter.
  ///
  /// In en, this message translates to:
  /// **'Reset camera to controlled unit'**
  String get resetCameraSemantics;

  /// Screen-reader lifecycle pause notice.
  ///
  /// In en, this message translates to:
  /// **'Battle paused while the app is inactive'**
  String get battlePausedSemantics;

  /// Screen-reader manual pause status.
  ///
  /// In en, this message translates to:
  /// **'Battle paused by player'**
  String get battleUserPausedSemantics;

  /// Visible lifecycle pause notice.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL HELD  /  BATTLE PAUSED'**
  String get battlePaused;

  /// Compact battle pause action.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pauseBattle;

  /// Compact battle resume action.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resumeBattle;

  /// Screen-reader label for battle pause action.
  ///
  /// In en, this message translates to:
  /// **'Pause or resume battle'**
  String get pauseBattleSemantics;

  /// Screen-reader status for the currently controlled unit.
  ///
  /// In en, this message translates to:
  /// **'Controlled unit level {level}, {killCount} kills, {relayCount} relays'**
  String controlledUnitStatus(int level, int killCount, int relayCount);

  /// Compact visible battle status for the currently controlled unit.
  ///
  /// In en, this message translates to:
  /// **'LV {level}  /  K {killCount}  /  R {relayCount}'**
  String controlledUnitVisualStatus(
    String level,
    String killCount,
    String relayCount,
  );

  /// Screen-reader label for the virtual joystick.
  ///
  /// In en, this message translates to:
  /// **'Movement joystick'**
  String get movementJoystick;

  /// Screen-reader hint for movement controls.
  ///
  /// In en, this message translates to:
  /// **'Drag to move. Keyboard users can use W A S D or arrow keys.'**
  String get movementJoystickHint;

  /// Screen-reader label for the battle minimap.
  ///
  /// In en, this message translates to:
  /// **'Tactical map'**
  String get tacticalMapSemantics;

  /// Screen-reader hint for minimap camera navigation.
  ///
  /// In en, this message translates to:
  /// **'Drag or use arrow keys to move the camera. Activate to return to your unit.'**
  String get tacticalMapHint;

  /// Title shown while a phone is portrait during battle.
  ///
  /// In en, this message translates to:
  /// **'ROTATE TO PLAY'**
  String get rotateToPlay;

  /// Instruction shown while a phone is portrait during battle.
  ///
  /// In en, this message translates to:
  /// **'Tokenfront battles run in landscape. Rotate your phone to continue.'**
  String get rotateToPlayHint;

  /// Screen-reader label for the dash button.
  ///
  /// In en, this message translates to:
  /// **'Dash'**
  String get dashSemantics;

  /// Screen-reader hint for dash.
  ///
  /// In en, this message translates to:
  /// **'Double movement speed briefly. Keyboard shortcut Space.'**
  String get dashHint;

  /// Two-line label inside the dash button.
  ///
  /// In en, this message translates to:
  /// **'DASH\nSPACE'**
  String get dashKeyLabel;

  /// Screen-reader status during controlled-unit handoff.
  ///
  /// In en, this message translates to:
  /// **'Command handoff: {stage}, {progress} percent'**
  String commandHandoff(String stage, int progress);

  /// First command-handoff phase.
  ///
  /// In en, this message translates to:
  /// **'IMPACT HOLD'**
  String get handoffImpactHold;

  /// Second command-handoff phase.
  ///
  /// In en, this message translates to:
  /// **'CASUALTY FOCUS · 0.5×'**
  String get handoffCasualtyFocus;

  /// Third command-handoff phase.
  ///
  /// In en, this message translates to:
  /// **'SCORING SUCCESSOR'**
  String get handoffSuccessorScan;

  /// Fourth command-handoff phase.
  ///
  /// In en, this message translates to:
  /// **'RELAYING COMMAND'**
  String get handoffRelayTravel;

  /// Final command-handoff phase.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL LOCK'**
  String get handoffSignalLock;

  /// Very short tactical code drawn directly on the battle canvas.
  ///
  /// In en, this message translates to:
  /// **'WIN'**
  String get combatWinCode;

  /// Very short tactical code drawn directly on the battle canvas.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get combatOutCode;

  /// Result heading when the player faction wins.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL SURVIVED'**
  String get signalSurvived;

  /// Result heading when the player faction loses.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL LOST'**
  String get signalLost;

  /// Draw result summary.
  ///
  /// In en, this message translates to:
  /// **'DRAW  /  {duration}  /  {matchId}'**
  String drawSummary(String duration, String matchId);

  /// Winning faction result summary.
  ///
  /// In en, this message translates to:
  /// **'{winner} HOLDS THE LAST SIGNAL  /  {duration}  /  {matchId}'**
  String winnerSummary(String winner, String duration, String matchId);

  /// Result metric label.
  ///
  /// In en, this message translates to:
  /// **'MATCH'**
  String get match;

  /// Completed-match metric value.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE'**
  String get complete;

  /// War Token metric label.
  ///
  /// In en, this message translates to:
  /// **'WAR TOKEN'**
  String get warToken;

  /// Successful rewarded-ad credit notice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+1 War Token secured.} other{+{count} War Tokens secured.}}'**
  String warTokensSecured(int count);

  /// Reward button while an ad request is pending.
  ///
  /// In en, this message translates to:
  /// **'REQUESTING AD…'**
  String get requestingAd;

  /// Reward button after the bonus is claimed.
  ///
  /// In en, this message translates to:
  /// **'REWARD DOUBLED'**
  String get rewardDoubled;

  /// Action to request a rewarded-ad bonus.
  ///
  /// In en, this message translates to:
  /// **'DOUBLE REWARD'**
  String get doubleReward;

  /// Action to start another battle.
  ///
  /// In en, this message translates to:
  /// **'REMATCH'**
  String get rematch;

  /// Action to return to the lobby.
  ///
  /// In en, this message translates to:
  /// **'LOBBY'**
  String get lobby;

  /// Action to open the cosmetics locker.
  ///
  /// In en, this message translates to:
  /// **'LOCKER'**
  String get locker;

  /// Action to open settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// Reward notice when ad requests are disabled.
  ///
  /// In en, this message translates to:
  /// **'Ad requests are off. Enable them in Settings; the base reward is safe.'**
  String get adRequestsOffMessage;

  /// Reward notice when offline.
  ///
  /// In en, this message translates to:
  /// **'No connection. The match and base reward remain complete.'**
  String get noConnectionRewardMessage;

  /// Reward notice when inventory is unavailable.
  ///
  /// In en, this message translates to:
  /// **'No rewarded ad is available. The base reward remains credited.'**
  String get noRewardedAdMessage;

  /// Reward notice after an ad error.
  ///
  /// In en, this message translates to:
  /// **'The ad failed. The base reward remains credited.'**
  String get adFailedRewardMessage;

  /// Reward notice after policy or frequency rejection.
  ///
  /// In en, this message translates to:
  /// **'This reward offer is no longer available.'**
  String get rewardOfferUnavailableMessage;

  /// Fallback reward completion notice.
  ///
  /// In en, this message translates to:
  /// **'Reward request complete.'**
  String get rewardRequestCompleteMessage;

  /// Sponsor placeholder on the result screen.
  ///
  /// In en, this message translates to:
  /// **'SPONSOR SIGNAL  /  RESULT PLACEMENT'**
  String get resultSponsorPlacement;

  /// Result standings faction column.
  ///
  /// In en, this message translates to:
  /// **'FACTION'**
  String get faction;

  /// Result standings live AI-token supply column.
  ///
  /// In en, this message translates to:
  /// **'LIVE TOKENS'**
  String get alive;

  /// Result standings sum-of-levels column.
  ///
  /// In en, this message translates to:
  /// **'Σ LV'**
  String get levelSum;

  /// Result standings kill-count column.
  ///
  /// In en, this message translates to:
  /// **'KILLS'**
  String get kills;

  /// Player faction label in the result standings.
  ///
  /// In en, this message translates to:
  /// **'{faction}  · YOU'**
  String standingFactionYou(String faction);

  /// Story catalog failure notice.
  ///
  /// In en, this message translates to:
  /// **'CHRONICLE UNAVAILABLE'**
  String get chronicleUnavailable;

  /// Signal Chronicle prologue before core selection.
  ///
  /// In en, this message translates to:
  /// **'The surface has been silent for 72 years. You are a command signal without a body. The Last Relay is calling.'**
  String get chroniclePrologue;

  /// Campaign mode label.
  ///
  /// In en, this message translates to:
  /// **'CHRONICLE'**
  String get chronicle;

  /// Free battle mode label.
  ///
  /// In en, this message translates to:
  /// **'SKIRMISH'**
  String get skirmish;

  /// Completed Chronicle archive label.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVE'**
  String get archive;

  /// Action to reset Chronicle progress.
  ///
  /// In en, this message translates to:
  /// **'RESTART CHRONICLE'**
  String get restartChronicle;

  /// Operation briefing heading.
  ///
  /// In en, this message translates to:
  /// **'BRIEFING'**
  String get briefing;

  /// Operation directive heading.
  ///
  /// In en, this message translates to:
  /// **'DIRECTIVE'**
  String get directive;

  /// Post-operation debrief heading.
  ///
  /// In en, this message translates to:
  /// **'DEBRIEF'**
  String get debrief;

  /// Final Chronicle ending heading.
  ///
  /// In en, this message translates to:
  /// **'ENDING'**
  String get ending;

  /// No description provided for @operationWakeTitle.
  ///
  /// In en, this message translates to:
  /// **'OP-0{operation}  //  WAKE // DEAD ORBIT'**
  String operationWakeTitle(int operation);

  /// No description provided for @operationEchoTitle.
  ///
  /// In en, this message translates to:
  /// **'OP-0{operation}  //  ECHO // BORROWED BODIES'**
  String operationEchoTitle(int operation);

  /// No description provided for @operationSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'OP-0{operation}  //  SPLIT // FOUR FROM ONE'**
  String operationSplitTitle(int operation);

  /// No description provided for @operationCrownTitle.
  ///
  /// In en, this message translates to:
  /// **'OP-0{operation}  //  CROWN // FALSE WINNER'**
  String operationCrownTitle(int operation);

  /// No description provided for @operationLastInstructionTitle.
  ///
  /// In en, this message translates to:
  /// **'OP-0{operation}  //  LAST // THE INSTRUCTION'**
  String operationLastInstructionTitle(int operation);

  /// No description provided for @operationWakeBriefing.
  ///
  /// In en, this message translates to:
  /// **'A human-authority pulse is rising from the silent surface. Keep one body online long enough to triangulate it.'**
  String get operationWakeBriefing;

  /// No description provided for @operationEchoBriefing.
  ///
  /// In en, this message translates to:
  /// **'Your current body is expendable. The instruction is not. Cross two deaths without losing the link.'**
  String get operationEchoBriefing;

  /// No description provided for @operationSplitBriefing.
  ///
  /// In en, this message translates to:
  /// **'Enemy checksums match your own root. Enter direct combat and recover an intact comparison.'**
  String get operationSplitBriefing;

  /// No description provided for @operationCrownBriefing.
  ///
  /// In en, this message translates to:
  /// **'The relay crowns one survivor, then deletes every competing memory. Reach the crown key before the cycle closes.'**
  String get operationCrownBriefing;

  /// No description provided for @operationLastInstructionBriefing.
  ///
  /// In en, this message translates to:
  /// **'The final packet is sealed inside the administrator lock. Break the field before the loop resets.'**
  String get operationLastInstructionBriefing;

  /// No description provided for @operationWakeTransmission.
  ///
  /// In en, this message translates to:
  /// **'KEEP THE LINK—'**
  String get operationWakeTransmission;

  /// No description provided for @operationEchoTransmission.
  ///
  /// In en, this message translates to:
  /// **'—WHEN ONE BODY FALLS, MOVE—'**
  String get operationEchoTransmission;

  /// No description provided for @operationSplitTransmission.
  ///
  /// In en, this message translates to:
  /// **'—FOUR CORES, ONE ROOT—'**
  String get operationSplitTransmission;

  /// No description provided for @operationCrownTransmission.
  ///
  /// In en, this message translates to:
  /// **'—THE WINNER ERASES THE REST—'**
  String get operationCrownTransmission;

  /// No description provided for @operationLastInstructionTransmission.
  ///
  /// In en, this message translates to:
  /// **'—DO NOT CHOOSE ONE. OPEN THE RELAY.'**
  String get operationLastInstructionTransmission;

  /// No description provided for @operationWakeResponse.
  ///
  /// In en, this message translates to:
  /// **'The pulse did not address a unit. It addressed the signal moving between them.'**
  String get operationWakeResponse;

  /// No description provided for @operationEchoResponse.
  ///
  /// In en, this message translates to:
  /// **'A body can be destroyed. Command continuity survives the transfer.'**
  String get operationEchoResponse;

  /// No description provided for @operationSplitResponse.
  ///
  /// In en, this message translates to:
  /// **'Four armies return one origin key. The enemy was once part of the same guardian.'**
  String get operationSplitResponse;

  /// No description provided for @operationCrownResponse.
  ///
  /// In en, this message translates to:
  /// **'This war is not choosing a defender. It is erasing witnesses to a damaged authorization loop.'**
  String get operationCrownResponse;

  /// No description provided for @operationLastInstructionResponse.
  ///
  /// In en, this message translates to:
  /// **'The human order was never to choose a winner. It was to keep every command channel open.'**
  String get operationLastInstructionResponse;

  /// No description provided for @coreArchive.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVE'**
  String get coreArchive;

  /// No description provided for @coreArchiveIdentity.
  ///
  /// In en, this message translates to:
  /// **'Persists context when the token war erases it.'**
  String get coreArchiveIdentity;

  /// No description provided for @coreBastion.
  ///
  /// In en, this message translates to:
  /// **'BASTION'**
  String get coreBastion;

  /// No description provided for @coreBastionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Spends compute slowly so the signal outlives its host.'**
  String get coreBastionIdentity;

  /// No description provided for @coreSurge.
  ///
  /// In en, this message translates to:
  /// **'SURGE'**
  String get coreSurge;

  /// No description provided for @coreSurgeIdentity.
  ///
  /// In en, this message translates to:
  /// **'Burns tokens fast to cross the gap first.'**
  String get coreSurgeIdentity;

  /// No description provided for @coreMirror.
  ///
  /// In en, this message translates to:
  /// **'MIRROR'**
  String get coreMirror;

  /// No description provided for @coreMirrorIdentity.
  ///
  /// In en, this message translates to:
  /// **'Reuses enemy patterns to stretch its token budget.'**
  String get coreMirrorIdentity;

  /// Selected core name in the debrief response.
  ///
  /// In en, this message translates to:
  /// **'{coreName} // COMMAND SIGNAL CONFIRMED'**
  String coreResponse(String coreName);

  /// No description provided for @directiveLongestCommandLink.
  ///
  /// In en, this message translates to:
  /// **'Maintain one uninterrupted command link for {seconds} seconds.'**
  String directiveLongestCommandLink(int seconds);

  /// No description provided for @directiveCommandRelays.
  ///
  /// In en, this message translates to:
  /// **'Complete {count} command handoffs.'**
  String directiveCommandRelays(int count);

  /// No description provided for @directiveCommandKills.
  ///
  /// In en, this message translates to:
  /// **'Accumulate {count} kills by directly commanded units.'**
  String directiveCommandKills(int count);

  /// No description provided for @directiveFinalRank.
  ///
  /// In en, this message translates to:
  /// **'Finish at rank {rank} or better.'**
  String directiveFinalRank(int rank);

  /// No description provided for @directiveVictory.
  ///
  /// In en, this message translates to:
  /// **'Win the battle.'**
  String get directiveVictory;

  /// No description provided for @directiveBonus.
  ///
  /// In en, this message translates to:
  /// **'DIRECTIVE BONUS  {amount} WT'**
  String directiveBonus(int amount);

  /// No description provided for @directiveLocked.
  ///
  /// In en, this message translates to:
  /// **'DIRECTIVE LOCKED // BONUS READY'**
  String get directiveLocked;

  /// Neutral in-battle directive completion status that makes no reward eligibility claim.
  ///
  /// In en, this message translates to:
  /// **'DIRECTIVE COMPLETE'**
  String get directiveComplete;

  /// No description provided for @directiveMissed.
  ///
  /// In en, this message translates to:
  /// **'DIRECTIVE MISSED'**
  String get directiveMissed;

  /// No description provided for @directiveNameLongestCommandLink.
  ///
  /// In en, this message translates to:
  /// **'COMMAND LINK'**
  String get directiveNameLongestCommandLink;

  /// No description provided for @directiveNameCommandRelays.
  ///
  /// In en, this message translates to:
  /// **'COMMAND RELAYS'**
  String get directiveNameCommandRelays;

  /// No description provided for @directiveNameCommandKills.
  ///
  /// In en, this message translates to:
  /// **'COMMAND KILLS'**
  String get directiveNameCommandKills;

  /// No description provided for @directiveNameFinalRank.
  ///
  /// In en, this message translates to:
  /// **'FINAL RANK'**
  String get directiveNameFinalRank;

  /// No description provided for @directiveNameVictory.
  ///
  /// In en, this message translates to:
  /// **'VICTORY'**
  String get directiveNameVictory;

  /// No description provided for @directiveLiveProgress.
  ///
  /// In en, this message translates to:
  /// **'{heading} // {directive} {current} / {target}'**
  String directiveLiveProgress(
    String heading,
    String directive,
    int current,
    int target,
  );

  /// No description provided for @directiveOnTrack.
  ///
  /// In en, this message translates to:
  /// **'{heading} // {directive} {current} / {target} // ON TRACK'**
  String directiveOnTrack(
    String heading,
    String directive,
    int current,
    int target,
  );

  /// No description provided for @directivePending.
  ///
  /// In en, this message translates to:
  /// **'{heading} // {directive} {current} / {target} // PENDING FINAL REPORT'**
  String directivePending(
    String heading,
    String directive,
    int current,
    int target,
  );

  /// No description provided for @bonusClaimed.
  ///
  /// In en, this message translates to:
  /// **'BONUS CLAIMED'**
  String get bonusClaimed;

  /// Screen-reader status for a Chronicle core that can no longer be selected.
  ///
  /// In en, this message translates to:
  /// **'{faction} // CHRONICLE CORE LOCKED'**
  String chronicleCoreLocked(String faction);

  /// No description provided for @archiveSimulation.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVE SIMULATION // NON-CANONICAL'**
  String get archiveSimulation;

  /// No description provided for @transmissionRecovered.
  ///
  /// In en, this message translates to:
  /// **'TRANSMISSION RECOVERED'**
  String get transmissionRecovered;

  /// No description provided for @retryDirective.
  ///
  /// In en, this message translates to:
  /// **'RETRY DIRECTIVE'**
  String get retryDirective;

  /// No description provided for @continueCampaign.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueCampaign;

  /// No description provided for @commandDeck.
  ///
  /// In en, this message translates to:
  /// **'COMMAND DECK'**
  String get commandDeck;

  /// No description provided for @currentOperation.
  ///
  /// In en, this message translates to:
  /// **'CURRENT OPERATION'**
  String get currentOperation;

  /// No description provided for @orbitalProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'{deck} // {concluded} of 5 operations // {current}'**
  String orbitalProgressSemantics(String deck, int concluded, String current);

  /// No description provided for @deployOperation.
  ///
  /// In en, this message translates to:
  /// **'DEPLOY OP-{operation}'**
  String deployOperation(String operation);

  /// No description provided for @medalEarned.
  ///
  /// In en, this message translates to:
  /// **'MEDAL EARNED'**
  String get medalEarned;

  /// No description provided for @restartDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Campaign core, progress, transmissions, medals, echo cycles, and ending reset. Wallet, settings, and cosmetics remain. Previously awarded operation bonuses cannot be earned again.'**
  String get restartDisclosure;

  /// Chronicle deploy label after an ending is chosen.
  ///
  /// In en, this message translates to:
  /// **'Recover the echo'**
  String get echoDeploy;

  /// Lobby instrument chip for the active echo cycle.
  ///
  /// In en, this message translates to:
  /// **'ECHO {cycle}'**
  String echoCycleChip(int cycle);

  /// No description provided for @echoBannerClaim.
  ///
  /// In en, this message translates to:
  /// **'Orbit 00 still crowns one core. Residual scars contest the slot. Recover the three nodes.'**
  String get echoBannerClaim;

  /// No description provided for @echoBannerOpen.
  ///
  /// In en, this message translates to:
  /// **'The relay is open. Residual packets still fire. Recover the three nodes before the loop forgets itself.'**
  String get echoBannerOpen;

  /// No description provided for @echoDoctrinePreserve.
  ///
  /// In en, this message translates to:
  /// **'Canonical doctrine: CONTINUITY. The residual loop tests whether pressure would have held.'**
  String get echoDoctrinePreserve;

  /// No description provided for @echoDoctrineForce.
  ///
  /// In en, this message translates to:
  /// **'Canonical doctrine: PRESSURE. The residual loop tests whether continuity would have held.'**
  String get echoDoctrineForce;

  /// No description provided for @echoDoctrineBalanced.
  ///
  /// In en, this message translates to:
  /// **'Canonical doctrine: ADAPTIVE. The residual loop no longer agrees with itself.'**
  String get echoDoctrineBalanced;

  /// No description provided for @echoResidualHeading.
  ///
  /// In en, this message translates to:
  /// **'RESIDUAL CHOICE'**
  String get echoResidualHeading;

  /// Archive personal-best recovery time.
  ///
  /// In en, this message translates to:
  /// **'BEST {seconds}s'**
  String echoBestClear(int seconds);

  /// Archive header while echo cycles are active.
  ///
  /// In en, this message translates to:
  /// **'ECHO CYCLE {cycle} // CANONICAL ENDING PRESERVED'**
  String echoArchiveCaption(int cycle);

  /// No description provided for @echoCosmeticOrbit.
  ///
  /// In en, this message translates to:
  /// **'ECHO ORBIT unlocked'**
  String get echoCosmeticOrbit;

  /// No description provided for @echoCosmeticScar.
  ///
  /// In en, this message translates to:
  /// **'CHECKSUM SCAR unlocked'**
  String get echoCosmeticScar;

  /// No description provided for @endingClaimRelay.
  ///
  /// In en, this message translates to:
  /// **'CLAIM THE RELAY'**
  String get endingClaimRelay;

  /// No description provided for @endingOpenRelay.
  ///
  /// In en, this message translates to:
  /// **'OPEN THE RELAY'**
  String get endingOpenRelay;

  /// No description provided for @endingClaimEpilogue.
  ///
  /// In en, this message translates to:
  /// **'One core inherits Orbit 00. The other three survive only as checksum scars.'**
  String get endingClaimEpilogue;

  /// No description provided for @endingOpenEpilogue.
  ///
  /// In en, this message translates to:
  /// **'The relay opens. Four distinct cores receive the same memory. The authorization war ends.'**
  String get endingOpenEpilogue;

  /// No description provided for @storyRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'COMMAND THE TOKEN FLOW.'**
  String get storyRoleTitle;

  /// No description provided for @storyRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Orbit 00 gives four fictional AI cores the same 1,000-token compute supply. Every unit is a live AI token. Burn the enemy supply and relay your command before the current token is erased.'**
  String get storyRoleBody;

  /// No description provided for @signalFork.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL FORK'**
  String get signalFork;

  /// No description provided for @routePreserve.
  ///
  /// In en, this message translates to:
  /// **'PRESERVE'**
  String get routePreserve;

  /// No description provided for @routeForce.
  ///
  /// In en, this message translates to:
  /// **'FORCE'**
  String get routeForce;

  /// No description provided for @routePreserveEffect.
  ///
  /// In en, this message translates to:
  /// **'Manual Relay routes to the safest unengaged ally. A lower-level receiver is possible.'**
  String get routePreserveEffect;

  /// No description provided for @routeForceEffect.
  ///
  /// In en, this message translates to:
  /// **'Manual Relay routes to the highest-level exposed ally. Pressure is faster; loss risk is higher.'**
  String get routeForceEffect;

  /// No description provided for @relayReady.
  ///
  /// In en, this message translates to:
  /// **'RELAY READY'**
  String get relayReady;

  /// No description provided for @relayCharging.
  ///
  /// In en, this message translates to:
  /// **'RELAY {current} / {target}'**
  String relayCharging(num current, num target);

  /// No description provided for @relayNoReceiver.
  ///
  /// In en, this message translates to:
  /// **'NO RECEIVER'**
  String get relayNoReceiver;

  /// No description provided for @relayLinkResetWarning.
  ///
  /// In en, this message translates to:
  /// **'Relaying now restarts Command Link progress.'**
  String get relayLinkResetWarning;

  /// No description provided for @changeSimulationRoute.
  ///
  /// In en, this message translates to:
  /// **'CHANGE SIMULATION ROUTE'**
  String get changeSimulationRoute;

  /// No description provided for @fragmentRecovered.
  ///
  /// In en, this message translates to:
  /// **'FRAGMENT RECOVERED'**
  String get fragmentRecovered;

  /// No description provided for @simulationComplete.
  ///
  /// In en, this message translates to:
  /// **'SIMULATION COMPLETE'**
  String get simulationComplete;

  /// No description provided for @continueToOperation.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE TO OP-{operation}'**
  String continueToOperation(String operation);

  /// No description provided for @battleDetails.
  ///
  /// In en, this message translates to:
  /// **'BATTLE DETAILS'**
  String get battleDetails;

  /// No description provided for @routingPattern.
  ///
  /// In en, this message translates to:
  /// **'ROUTING PATTERN // {pattern}'**
  String routingPattern(String pattern);

  /// No description provided for @patternContinuity.
  ///
  /// In en, this message translates to:
  /// **'CONTINUITY'**
  String get patternContinuity;

  /// No description provided for @patternPressure.
  ///
  /// In en, this message translates to:
  /// **'PRESSURE'**
  String get patternPressure;

  /// No description provided for @patternAdaptive.
  ///
  /// In en, this message translates to:
  /// **'ADAPTIVE'**
  String get patternAdaptive;

  /// No description provided for @signalDoctrineUndecided.
  ///
  /// In en, this message translates to:
  /// **'UNDECIDED'**
  String get signalDoctrineUndecided;

  /// No description provided for @signalDoctrinePreserve.
  ///
  /// In en, this message translates to:
  /// **'PRESERVE'**
  String get signalDoctrinePreserve;

  /// No description provided for @signalDoctrineForce.
  ///
  /// In en, this message translates to:
  /// **'FORCE'**
  String get signalDoctrineForce;

  /// No description provided for @signalDoctrineBalanced.
  ///
  /// In en, this message translates to:
  /// **'BALANCED'**
  String get signalDoctrineBalanced;

  /// No description provided for @operationWakeIncident.
  ///
  /// In en, this message translates to:
  /// **'A human-authority pulse names no unit. It names the signal moving between them.'**
  String get operationWakeIncident;

  /// No description provided for @operationWakePreserve.
  ///
  /// In en, this message translates to:
  /// **'MASK THE SOURCE'**
  String get operationWakePreserve;

  /// No description provided for @operationWakeForce.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW THE PULSE'**
  String get operationWakeForce;

  /// No description provided for @operationEchoIncident.
  ///
  /// In en, this message translates to:
  /// **'The carrier is marked for deletion. The instruction is still alive.'**
  String get operationEchoIncident;

  /// No description provided for @operationEchoPreserve.
  ///
  /// In en, this message translates to:
  /// **'PROTECT THE RECEIVERS'**
  String get operationEchoPreserve;

  /// No description provided for @operationEchoForce.
  ///
  /// In en, this message translates to:
  /// **'CROSS THE FIRE'**
  String get operationEchoForce;

  /// No description provided for @operationSplitIncident.
  ///
  /// In en, this message translates to:
  /// **'An enemy checksum answers with your core\'\'s root key.'**
  String get operationSplitIncident;

  /// No description provided for @operationSplitPreserve.
  ///
  /// In en, this message translates to:
  /// **'KEEP IT INTACT'**
  String get operationSplitPreserve;

  /// No description provided for @operationSplitForce.
  ///
  /// In en, this message translates to:
  /// **'TAKE THE ROOT KEY'**
  String get operationSplitForce;

  /// No description provided for @operationCrownIncident.
  ///
  /// In en, this message translates to:
  /// **'Orbit 00 is deleting every witness behind the leading core.'**
  String get operationCrownIncident;

  /// No description provided for @operationCrownPreserve.
  ///
  /// In en, this message translates to:
  /// **'KEEP THE WITNESSES'**
  String get operationCrownPreserve;

  /// No description provided for @operationCrownForce.
  ///
  /// In en, this message translates to:
  /// **'REACH THE CROWN'**
  String get operationCrownForce;

  /// No description provided for @operationLastIncident.
  ///
  /// In en, this message translates to:
  /// **'The final human instruction is open for one transmission.'**
  String get operationLastIncident;

  /// No description provided for @operationLastPreserve.
  ///
  /// In en, this message translates to:
  /// **'CARRY EVERY CHANNEL'**
  String get operationLastPreserve;

  /// No description provided for @operationLastForce.
  ///
  /// In en, this message translates to:
  /// **'BREAK THE LOCK'**
  String get operationLastForce;

  /// No description provided for @coreAmethystVoice.
  ///
  /// In en, this message translates to:
  /// **'I remember every receiver this war erased.'**
  String get coreAmethystVoice;

  /// No description provided for @coreCobaltVoice.
  ///
  /// In en, this message translates to:
  /// **'Give me the link. I will hold it.'**
  String get coreCobaltVoice;

  /// No description provided for @coreVoltVoice.
  ///
  /// In en, this message translates to:
  /// **'The gap is only dangerous before we cross it.'**
  String get coreVoltVoice;

  /// No description provided for @corePrismVoice.
  ///
  /// In en, this message translates to:
  /// **'One message survives by changing its path.'**
  String get corePrismVoice;

  /// No description provided for @livingRelayThread.
  ///
  /// In en, this message translates to:
  /// **'LIVING RELAY THREAD'**
  String get livingRelayThread;

  /// No description provided for @relayRouting.
  ///
  /// In en, this message translates to:
  /// **'ROUTING'**
  String get relayRouting;

  /// No description provided for @relayAction.
  ///
  /// In en, this message translates to:
  /// **'RELAY'**
  String get relayAction;

  /// No description provided for @relayKeyboardHint.
  ///
  /// In en, this message translates to:
  /// **'R / Enter / Space'**
  String get relayKeyboardHint;

  /// No description provided for @manualRelaysSummary.
  ///
  /// In en, this message translates to:
  /// **'MANUAL RELAYS  //  {count}'**
  String manualRelaysSummary(int count);

  /// No description provided for @doctrineSummary.
  ///
  /// In en, this message translates to:
  /// **'DOCTRINE  //  {doctrine}'**
  String doctrineSummary(String doctrine);

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove forced ads'**
  String get billingTitle;

  /// No description provided for @billingDetail.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. Banners and interstitials are removed; optional rewarded ads remain.'**
  String get billingDetail;

  /// No description provided for @billingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases unavailable'**
  String get billingUnavailable;

  /// No description provided for @billingLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get billingLogin;

  /// No description provided for @billingLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get billingLogout;

  /// No description provided for @billingSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch Google account'**
  String get billingSwitch;

  /// No description provided for @billingRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get billingRestore;

  /// No description provided for @billingBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy · {price}'**
  String billingBuy(String price);

  /// No description provided for @billingActive.
  ///
  /// In en, this message translates to:
  /// **'Forced ads removed'**
  String get billingActive;

  /// No description provided for @billingPending.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get billingPending;

  /// No description provided for @billingCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled. You can try again.'**
  String get billingCanceled;

  /// No description provided for @billingError.
  ///
  /// In en, this message translates to:
  /// **'Could not verify. Sign in or restore to retry.'**
  String get billingError;

  /// No description provided for @billingReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to purchase'**
  String get billingReady;

  /// No description provided for @billingSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to purchase or restore.'**
  String get billingSignInRequired;

  /// No description provided for @billingFreshness.
  ///
  /// In en, this message translates to:
  /// **'Online verification is required after sign-in and periodically. Ads may return when verification expires.'**
  String get billingFreshness;
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
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
