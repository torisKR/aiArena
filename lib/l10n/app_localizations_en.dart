// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tokenfront: Orbital Signal War';

  @override
  String get lobbyTagline => 'FOUR AI CORES. ONE LAST RELAY.';

  @override
  String factionSignal(String faction) {
    return '$faction SIGNAL';
  }

  @override
  String get factionBrief =>
      '1,000 units · Lv.1–10 balanced · one continuous command';

  @override
  String get deploySignal => 'DEPLOY TO ORBIT';

  @override
  String lockerBalance(int balance) {
    return 'LOCKER  $balance WT';
  }

  @override
  String get tune => 'TUNE';

  @override
  String get signalSettings => 'SIGNAL SETTINGS';

  @override
  String get offline => 'OFFLINE';

  @override
  String chooseFaction(String faction) {
    return 'Choose $faction faction';
  }

  @override
  String unitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count UNITS',
      one: '1 UNIT',
    );
    return '$_temp0';
  }

  @override
  String get units => 'UNITS';

  @override
  String get highLevel => 'HIGH LV';

  @override
  String get wins => 'WINS';

  @override
  String get equalLevel => 'EQUAL';

  @override
  String get death => 'DEATH';

  @override
  String get relays => 'RELAYS';

  @override
  String get move => 'MOVE';

  @override
  String get stickWasd => 'STICK / WASD';

  @override
  String get dash => 'DASH';

  @override
  String get buttonSpace => 'BUTTON / SPACE';

  @override
  String get sponsorBannerArea => 'Sponsor banner area';

  @override
  String get sponsorSignal => 'SPONSOR SIGNAL';

  @override
  String get lobbyPlacement => 'LOBBY PLACEMENT';

  @override
  String get languageSection => 'LANGUAGE';

  @override
  String get displayLanguage => 'DISPLAY LANGUAGE';

  @override
  String get displayLanguageDetail =>
      'Follow the device language or choose one for this game.';

  @override
  String get languageSystem => 'SYSTEM DEFAULT';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get settingsTitle => 'SIGNAL CONDITIONING';

  @override
  String get settingsSubtitle =>
      'Tune the battlefield without changing combat strength.';

  @override
  String get closeSettings => 'Close settings';

  @override
  String get battlefieldSection => 'BATTLEFIELD';

  @override
  String get lowSpecFilter => 'LOW-SPEC FILTER';

  @override
  String get lowSpecFilterDetail =>
      'Cuts particles and expensive field details.';

  @override
  String get reduceMotion => 'REDUCE MOTION';

  @override
  String get reduceMotionDetail =>
      'Shortens relay camera travel and large transitions.';

  @override
  String get mouseCamera => 'MOUSE CAMERA';

  @override
  String get mouseCameraDetail => 'Enables wheel zoom and drag panning on web.';

  @override
  String get audioCues => 'AUDIO CUES';

  @override
  String get audioCuesDetail =>
      'Plays bounded dash, combat, and relay signals.';

  @override
  String get hapticCues => 'HAPTIC CUES';

  @override
  String get hapticCuesDetail =>
      'Signals dash and command relay on supported devices.';

  @override
  String get privacySection => 'PRIVACY';

  @override
  String get shareAnalytics => 'SHARE ANALYTICS';

  @override
  String get shareAnalyticsDetail =>
      'Sends buffered anonymous match events when online.';

  @override
  String get adRequests => 'AD REQUESTS';

  @override
  String get adRequestsDetail =>
      'Allows lobby and result ads. Tracking still needs platform permission.';

  @override
  String get privacyDefaultNote =>
      'Both choices start off. Offline matches and rewards work when either choice is off.';

  @override
  String get closePanel => 'CLOSE PANEL';

  @override
  String get stateOff => 'OFF';

  @override
  String get stateOn => 'ON';

  @override
  String get semanticsOff => 'Off';

  @override
  String get semanticsOn => 'On';

  @override
  String needMoreWarTokens(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Need $count more War Tokens.',
      one: 'Need 1 more War Token.',
    );
    return '$_temp0';
  }

  @override
  String get signalLocker => 'SIGNAL LOCKER';

  @override
  String get lockerSubtitle =>
      'Spend War Tokens on field identity only. Combat strength never changes.';

  @override
  String warTokenBalance(int balance) {
    String _temp0 = intl.Intl.pluralLogic(
      balance,
      locale: localeName,
      other: '$balance WAR TOKENS',
      one: '1 WAR TOKEN',
    );
    return '$_temp0';
  }

  @override
  String get closeSignalLocker => 'Close Signal Locker';

  @override
  String get equipped => 'EQUIPPED';

  @override
  String get equip => 'EQUIP';

  @override
  String unlockCost(int cost) {
    return 'UNLOCK  $cost';
  }

  @override
  String get commandEdge => 'COMMAND EDGE';

  @override
  String get movementTrace => 'MOVEMENT TRACE';

  @override
  String get defeatMark => 'DEFEAT MARK';

  @override
  String get cosmeticFieldIssueName => 'FIELD ISSUE';

  @override
  String get cosmeticFieldIssueDescription =>
      'Standard faction signal pigment.';

  @override
  String get cosmeticRelayIvoryName => 'RELAY IVORY';

  @override
  String get cosmeticRelayIvoryDescription =>
      'Ivory command outline; faction core stays readable.';

  @override
  String get cosmeticOxideEdgeName => 'OXIDE EDGE';

  @override
  String get cosmeticOxideEdgeDescription =>
      'Warm tactical edge for the controlled token.';

  @override
  String get cosmeticCleanWakeName => 'CLEAN WAKE';

  @override
  String get cosmeticCleanWakeDescription => 'No persistent movement trace.';

  @override
  String get cosmeticRelayTapeName => 'RELAY TAPE';

  @override
  String get cosmeticRelayTapeDescription => 'A short segmented command trace.';

  @override
  String get cosmeticCinderGridName => 'CINDER GRID';

  @override
  String get cosmeticCinderGridDescription =>
      'A sparse oxide wake for fast movement.';

  @override
  String get cosmeticSignalRingName => 'SIGNAL RING';

  @override
  String get cosmeticSignalRingDescription => 'Standard compact defeat pulse.';

  @override
  String get cosmeticFractureName => 'FOUR-WAY FRACTURE';

  @override
  String get cosmeticFractureDescription =>
      'A crisp geometric break with no gameplay effect.';

  @override
  String get signalLostObserving => 'SIGNAL LOST  /  OBSERVING REMAINING WAR';

  @override
  String timeRemaining(String time) {
    return 'Time remaining $time';
  }

  @override
  String factionAlive(String faction, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$faction $count alive',
      one: '$faction 1 alive',
    );
    return '$_temp0';
  }

  @override
  String get cameraShort => 'CAM';

  @override
  String get ecoShort => 'ECO';

  @override
  String get lockShort => 'LOCK';

  @override
  String get mouseCameraSemantics => 'Mouse drag and wheel camera';

  @override
  String get lowPowerModeSemantics => 'Low power mode';

  @override
  String get resetCameraSemantics => 'Reset camera to controlled unit';

  @override
  String get battlePausedSemantics => 'Battle paused while the app is inactive';

  @override
  String get battlePaused => 'SIGNAL HELD  /  BATTLE PAUSED';

  @override
  String controlledUnitStatus(int level, int killCount, int relayCount) {
    return 'Controlled unit level $level, $killCount kills, $relayCount relays';
  }

  @override
  String controlledUnitVisualStatus(
    String level,
    String killCount,
    String relayCount,
  ) {
    return 'LV $level  /  K $killCount  /  R $relayCount';
  }

  @override
  String get movementJoystick => 'Movement joystick';

  @override
  String get movementJoystickHint =>
      'Drag to move. Keyboard users can use W A S D or arrow keys.';

  @override
  String get tacticalMapSemantics => 'Tactical map';

  @override
  String get tacticalMapHint =>
      'Drag or use arrow keys to move the camera. Activate to return to your unit.';

  @override
  String get rotateToPlay => 'ROTATE TO PLAY';

  @override
  String get rotateToPlayHint =>
      'Tokenfront battles run in landscape. Rotate your phone to continue.';

  @override
  String get dashSemantics => 'Dash';

  @override
  String get dashHint =>
      'Double movement speed briefly. Keyboard shortcut Space.';

  @override
  String get dashKeyLabel => 'DASH\nSPACE';

  @override
  String commandHandoff(String stage, int progress) {
    return 'Command handoff: $stage, $progress percent';
  }

  @override
  String get handoffImpactHold => 'IMPACT HOLD';

  @override
  String get handoffCasualtyFocus => 'CASUALTY FOCUS · 0.5×';

  @override
  String get handoffSuccessorScan => 'SCORING SUCCESSOR';

  @override
  String get handoffRelayTravel => 'RELAYING COMMAND';

  @override
  String get handoffSignalLock => 'SIGNAL LOCK';

  @override
  String get combatWinCode => 'WIN';

  @override
  String get combatOutCode => 'OUT';

  @override
  String get signalSurvived => 'SIGNAL SURVIVED';

  @override
  String get signalLost => 'SIGNAL LOST';

  @override
  String drawSummary(String duration, String matchId) {
    return 'DRAW  /  $duration  /  $matchId';
  }

  @override
  String winnerSummary(String winner, String duration, String matchId) {
    return '$winner HOLDS THE LAST SIGNAL  /  $duration  /  $matchId';
  }

  @override
  String get match => 'MATCH';

  @override
  String get complete => 'COMPLETE';

  @override
  String get warToken => 'WAR TOKEN';

  @override
  String warTokensSecured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count War Tokens secured.',
      one: '+1 War Token secured.',
    );
    return '$_temp0';
  }

  @override
  String get requestingAd => 'REQUESTING AD…';

  @override
  String get rewardDoubled => 'REWARD DOUBLED';

  @override
  String get doubleReward => 'DOUBLE REWARD';

  @override
  String get rematch => 'REMATCH';

  @override
  String get lobby => 'LOBBY';

  @override
  String get locker => 'LOCKER';

  @override
  String get settings => 'SETTINGS';

  @override
  String get adRequestsOffMessage =>
      'Ad requests are off. Enable them in Settings; the base reward is safe.';

  @override
  String get noConnectionRewardMessage =>
      'No connection. The match and base reward remain complete.';

  @override
  String get noRewardedAdMessage =>
      'No rewarded ad is available. The base reward remains credited.';

  @override
  String get adFailedRewardMessage =>
      'The ad failed. The base reward remains credited.';

  @override
  String get rewardOfferUnavailableMessage =>
      'This reward offer is no longer available.';

  @override
  String get rewardRequestCompleteMessage => 'Reward request complete.';

  @override
  String get resultSponsorPlacement => 'SPONSOR SIGNAL  /  RESULT PLACEMENT';

  @override
  String get faction => 'FACTION';

  @override
  String get alive => 'ALIVE';

  @override
  String get levelSum => 'Σ LV';

  @override
  String get kills => 'KILLS';

  @override
  String standingFactionYou(String faction) {
    return '$faction  · YOU';
  }

  @override
  String get chronicleUnavailable => 'CHRONICLE UNAVAILABLE';
}
