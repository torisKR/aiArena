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
  /// **'Tokenfront: Orbital Signal War'**
  String get appTitle;

  /// Short product tagline on the lobby header.
  ///
  /// In en, this message translates to:
  /// **'FOUR AI CORES. ONE LAST RELAY.'**
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
  /// **'Remembers what the war deletes.'**
  String get coreArchiveIdentity;

  /// No description provided for @coreBastion.
  ///
  /// In en, this message translates to:
  /// **'BASTION'**
  String get coreBastion;

  /// No description provided for @coreBastionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Endures so the signal outlives its body.'**
  String get coreBastionIdentity;

  /// No description provided for @coreSurge.
  ///
  /// In en, this message translates to:
  /// **'SURGE'**
  String get coreSurge;

  /// No description provided for @coreSurgeIdentity.
  ///
  /// In en, this message translates to:
  /// **'Crosses a gap before silence can close it.'**
  String get coreSurgeIdentity;

  /// No description provided for @coreMirror.
  ///
  /// In en, this message translates to:
  /// **'MIRROR'**
  String get coreMirror;

  /// No description provided for @coreMirrorIdentity.
  ///
  /// In en, this message translates to:
  /// **'Changes its pattern to preserve the message.'**
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

  /// No description provided for @directiveMissed.
  ///
  /// In en, this message translates to:
  /// **'DIRECTIVE MISSED'**
  String get directiveMissed;

  /// No description provided for @bonusClaimed.
  ///
  /// In en, this message translates to:
  /// **'BONUS CLAIMED'**
  String get bonusClaimed;

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
  /// **'Campaign core, progress, transmissions, medals, and ending reset. Wallet, settings, and cosmetics remain. Paid operation bonuses cannot be earned again.'**
  String get restartDisclosure;

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
