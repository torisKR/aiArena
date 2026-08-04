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

  /// Application title shown by the operating system and browser.
  ///
  /// In en, this message translates to:
  /// **'Tokenfront: AI Arena'**
  String get appTitle;

  /// Short product tagline on the lobby header.
  ///
  /// In en, this message translates to:
  /// **'AI ARENA  /  ONE SIGNAL. FOUR FRONTS.'**
  String get lobbyTagline;

  /// Selected faction signal heading.
  ///
  /// In en, this message translates to:
  /// **'{faction} SIGNAL'**
  String factionSignal(String faction);

  /// Short description of the selected army.
  ///
  /// In en, this message translates to:
  /// **'1,000 units · Lv.1–10 balanced · one continuous command'**
  String get factionBrief;

  /// Primary button that starts a battle.
  ///
  /// In en, this message translates to:
  /// **'DEPLOY SIGNAL'**
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
  /// **'Choose {faction} faction'**
  String chooseFaction(String faction);

  /// Visible number of units in an army.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 UNIT} other{{count} UNITS}}'**
  String unitsCount(int count);

  /// Rules-strip label for units.
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
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
  /// **'{count, plural, =1{{faction} 1 alive} other{{faction} {count} alive}}'**
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

  /// Visible lifecycle pause notice.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL HELD  /  BATTLE PAUSED'**
  String get battlePaused;

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

  /// Result standings survivor column.
  ///
  /// In en, this message translates to:
  /// **'ALIVE'**
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
