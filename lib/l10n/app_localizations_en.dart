// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get billingDelete => 'Delete billing account';

  @override
  String get billingDeleteWarning =>
      'Delete the Tokenfront billing account and purchase verification records. Ad removal and the restoration link end; restoration is not guaranteed after deletion. This does not refund purchases or delete Google / Google Play records. Continue and verify the same Google account?';

  @override
  String get billingDeleteCancel => 'Cancel';

  @override
  String get billingDeleteConfirm => 'Delete and verify with Google';

  @override
  String get billingDeleted =>
      'Billing account deleted. Ad removal ended on this device.';

  @override
  String get billingDeleteFailed =>
      'Deletion is not confirmed. Retry soon with the same account. If you cannot retry, contact korea@toris.kr.';

  @override
  String get billingDeleteLocalFailed =>
      'Server account deleted, but local cleanup failed. Keep the app open and retry. Cached data may remain on disk; contact korea@toris.kr if this continues.';

  @override
  String get recoveryTitle => 'Recover three signals';

  @override
  String get recoveryInstruction =>
      'Tap 1, 2 or 3 to choose a destination. Movement and combat are automatic. If your token falls, another continues. Progress stays.';

  @override
  String get recoveryAutomatic => 'AUTO MOVE · AUTO COMBAT · AUTO CONTINUE';

  @override
  String get recoveryChooseDestination => 'CHOOSE DESTINATION';

  @override
  String get recoveryWon => 'SIGNALS RECOVERED';

  @override
  String get recoveryLost => 'RECOVERY ENDED';

  @override
  String get recoveryTimeout => 'TIMEOUT';

  @override
  String get recoveryAlliesLost => 'ALLIES LOST';

  @override
  String recoveryProgress(int count) {
    return '$count/3 signals recovered';
  }

  @override
  String recoveryDestination(int number, int seconds) {
    return 'Signal $number: $seconds/8s';
  }

  @override
  String get appTitle => 'Tokenfront: Orbital Signal War';

  @override
  String get lobbyTagline =>
      'FOUR AI CORES. 4,000 LIVE TOKENS. ONE LAST RELAY.';

  @override
  String factionSignal(String faction) {
    return '$faction SIGNAL';
  }

  @override
  String get factionBrief =>
      '1,000 live AI tokens · Lv.1–10 balanced · one continuous command';

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
    return 'Choose the $faction AI core';
  }

  @override
  String unitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI TOKENS',
      one: '1 AI TOKEN',
    );
    return '$_temp0';
  }

  @override
  String get units => 'AI TOKENS';

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
  String get privacyPolicyTitle => 'PRIVACY POLICY';

  @override
  String get privacyOptions => 'AD PRIVACY OPTIONS';

  @override
  String get privacyPolicyEffectiveDate => 'Effective date: 2026-08-05';

  @override
  String get privacyPolicyIntro =>
      'Tokenfront is an offline single-player game. Gameplay and local progress stay on your device. Optional Google AdMob ads may process ad requests and device/ad identifiers when you enable ad requests and consent permits them.';

  @override
  String get privacyDataStoredTitle => 'DATA STORED ON YOUR DEVICE';

  @override
  String get privacyDataStoredBody =>
      'Tokenfront stores War Token balance, cosmetic unlocks and equipment, language, accessibility, audio, camera, haptic and privacy choices, and Signal Chronicle progress in app-private local storage. It is not uploaded and is removed when app storage is cleared or the app is uninstalled.';

  @override
  String get privacyAnalyticsTitle => 'ANALYTICS';

  @override
  String get privacyAnalyticsBody =>
      'Gameplay and performance events can exist in a temporary memory buffer of up to 500 entries. This release uses no analytics transport, sends no events, and discards the buffer when the process ends.';

  @override
  String get privacyAdvertisingTitle => 'ADVERTISING';

  @override
  String get privacyAdvertisingBody =>
      'Debug/profile builds use Google test ad units; signed release builds use the configured Tokenfront production units. All requests are non-personalized; this does not prevent advertising-identifier collection. Optional lobby and result banners, result rewarded ads, and result-exit interstitials are requested only after the Google consent flow permits them. AdMob may process ad requests, device information, and advertising identifiers as described by Google. Turning off AD REQUESTS stops app ad requests; the base War Token reward never depends on an ad.';

  @override
  String get privacyAccountsTitle => 'ACCOUNTS, PERMISSIONS, AND THIRD PARTIES';

  @override
  String get privacyAccountsBody =>
      'Shipped 1.2.0 has no login or purchases. Future-version draft, disabled and pending publication: optional Google sign-in would enable one-time remove-ads purchase/restore; gameplay needs no login and optional rewarded ads remain. Toris’s Cloudflare Workers backend would verify Google identity and Google Play purchases. D1 would retain pseudonymous (not anonymous) account bindings, encrypted purchase tokens and their hashes, order IDs, product/status and verification/check timestamps. Email/profile are not persisted by the backend. A signed entitlement and account binding would be cached locally for up to 30 days after positive verification, not as a retention limit for server records. Clearing app storage or logging out does not delete backend records. Deletion endpoint/workflow and retention policy are missing release blockers; no operational deletion service is promised. Privacy inquiries: korea@toris.kr; do not send tokens or passwords. No cloud game sync, social feature or access to location, camera, microphone, contacts, photos, calendar, health or messages is added.';

  @override
  String get privacyHostingTitle => 'PUBLIC POLICY HOSTING';

  @override
  String get privacyHostingBody =>
      'The public copy is hosted on Cloudflare Pages. Opening it uses your external browser, where Cloudflare may process ordinary web-request data under its terms. The Android app does not embed the public page or send gameplay or local-state data to it.';

  @override
  String get privacyChildrenTitle => 'CHILDREN';

  @override
  String get privacyChildrenBody =>
      'Tokenfront is intended for players aged 13 and older and is not directed to children under 13. Advertising processing is described above; the proposed account and purchase processing is disabled and separately disclosed.';

  @override
  String get privacyChangesTitle => 'CHANGES';

  @override
  String get privacyChangesBody =>
      'Before a future release adds analytics transport, advertising, accounts, cloud services, or another off-device data flow, this policy and Google Play Data Safety declaration will be updated.';

  @override
  String get privacyContactTitle => 'CONTACT';

  @override
  String get privacyPublicUrlLabel => 'PUBLIC POLICY URL';

  @override
  String get privacyOpenPublicPage => 'OPEN PUBLIC PAGE';

  @override
  String get privacyCopyUrl => 'COPY URL';

  @override
  String get privacyUrlCopied => 'Privacy policy URL copied.';

  @override
  String get privacyOpenFailed =>
      'The public policy page could not be opened. The full policy remains available here.';

  @override
  String get releaseServicesUnavailable => 'NOT AVAILABLE IN THIS RELEASE';

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
  String get cosmeticEchoOrbitName => 'ECHO ORBIT';

  @override
  String get cosmeticEchoOrbitDescription =>
      'Residual orbit pigment granted after the first echo cycle.';

  @override
  String get cosmeticChecksumScarName => 'CHECKSUM SCAR';

  @override
  String get cosmeticChecksumScarDescription =>
      'A residual scar trail granted for recording both endings.';

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
      other: '$faction $count live AI tokens',
      one: '$faction 1 live AI token',
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
  String get battleUserPausedSemantics => 'Battle paused by player';

  @override
  String get battlePaused => 'SIGNAL HELD  /  BATTLE PAUSED';

  @override
  String get pauseBattle => 'PAUSE';

  @override
  String get resumeBattle => 'RESUME';

  @override
  String get pauseBattleSemantics => 'Pause or resume battle';

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
  String get alive => 'LIVE TOKENS';

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

  @override
  String get chroniclePrologue =>
      'The surface has been silent for 72 years. You are a command signal without a body. The Last Relay is calling.';

  @override
  String get chronicle => 'CHRONICLE';

  @override
  String get skirmish => 'SKIRMISH';

  @override
  String get archive => 'ARCHIVE';

  @override
  String get restartChronicle => 'RESTART CHRONICLE';

  @override
  String get briefing => 'BRIEFING';

  @override
  String get directive => 'DIRECTIVE';

  @override
  String get debrief => 'DEBRIEF';

  @override
  String get ending => 'ENDING';

  @override
  String operationWakeTitle(int operation) {
    return 'OP-0$operation  //  WAKE // DEAD ORBIT';
  }

  @override
  String operationEchoTitle(int operation) {
    return 'OP-0$operation  //  ECHO // BORROWED BODIES';
  }

  @override
  String operationSplitTitle(int operation) {
    return 'OP-0$operation  //  SPLIT // FOUR FROM ONE';
  }

  @override
  String operationCrownTitle(int operation) {
    return 'OP-0$operation  //  CROWN // FALSE WINNER';
  }

  @override
  String operationLastInstructionTitle(int operation) {
    return 'OP-0$operation  //  LAST // THE INSTRUCTION';
  }

  @override
  String get operationWakeBriefing =>
      'A human-authority pulse is rising from the silent surface. Keep one body online long enough to triangulate it.';

  @override
  String get operationEchoBriefing =>
      'Your current body is expendable. The instruction is not. Cross two deaths without losing the link.';

  @override
  String get operationSplitBriefing =>
      'Enemy checksums match your own root. Enter direct combat and recover an intact comparison.';

  @override
  String get operationCrownBriefing =>
      'The relay crowns one survivor, then deletes every competing memory. Reach the crown key before the cycle closes.';

  @override
  String get operationLastInstructionBriefing =>
      'The final packet is sealed inside the administrator lock. Break the field before the loop resets.';

  @override
  String get operationWakeTransmission => 'KEEP THE LINK—';

  @override
  String get operationEchoTransmission => '—WHEN ONE BODY FALLS, MOVE—';

  @override
  String get operationSplitTransmission => '—FOUR CORES, ONE ROOT—';

  @override
  String get operationCrownTransmission => '—THE WINNER ERASES THE REST—';

  @override
  String get operationLastInstructionTransmission =>
      '—DO NOT CHOOSE ONE. OPEN THE RELAY.';

  @override
  String get operationWakeResponse =>
      'The pulse did not address a unit. It addressed the signal moving between them.';

  @override
  String get operationEchoResponse =>
      'A body can be destroyed. Command continuity survives the transfer.';

  @override
  String get operationSplitResponse =>
      'Four armies return one origin key. The enemy was once part of the same guardian.';

  @override
  String get operationCrownResponse =>
      'This war is not choosing a defender. It is erasing witnesses to a damaged authorization loop.';

  @override
  String get operationLastInstructionResponse =>
      'The human order was never to choose a winner. It was to keep every command channel open.';

  @override
  String get coreArchive => 'ARCHIVE';

  @override
  String get coreArchiveIdentity =>
      'Persists context when the token war erases it.';

  @override
  String get coreBastion => 'BASTION';

  @override
  String get coreBastionIdentity =>
      'Spends compute slowly so the signal outlives its host.';

  @override
  String get coreSurge => 'SURGE';

  @override
  String get coreSurgeIdentity => 'Burns tokens fast to cross the gap first.';

  @override
  String get coreMirror => 'MIRROR';

  @override
  String get coreMirrorIdentity =>
      'Reuses enemy patterns to stretch its token budget.';

  @override
  String coreResponse(String coreName) {
    return '$coreName // COMMAND SIGNAL CONFIRMED';
  }

  @override
  String directiveLongestCommandLink(int seconds) {
    return 'Maintain one uninterrupted command link for $seconds seconds.';
  }

  @override
  String directiveCommandRelays(int count) {
    return 'Complete $count command handoffs.';
  }

  @override
  String directiveCommandKills(int count) {
    return 'Accumulate $count kills by directly commanded units.';
  }

  @override
  String directiveFinalRank(int rank) {
    return 'Finish at rank $rank or better.';
  }

  @override
  String get directiveVictory => 'Win the battle.';

  @override
  String directiveBonus(int amount) {
    return 'DIRECTIVE BONUS  $amount WT';
  }

  @override
  String get directiveLocked => 'DIRECTIVE LOCKED // BONUS READY';

  @override
  String get directiveComplete => 'DIRECTIVE COMPLETE';

  @override
  String get directiveMissed => 'DIRECTIVE MISSED';

  @override
  String get directiveNameLongestCommandLink => 'COMMAND LINK';

  @override
  String get directiveNameCommandRelays => 'COMMAND RELAYS';

  @override
  String get directiveNameCommandKills => 'COMMAND KILLS';

  @override
  String get directiveNameFinalRank => 'FINAL RANK';

  @override
  String get directiveNameVictory => 'VICTORY';

  @override
  String directiveLiveProgress(
    String heading,
    String directive,
    int current,
    int target,
  ) {
    return '$heading // $directive $current / $target';
  }

  @override
  String directiveOnTrack(
    String heading,
    String directive,
    int current,
    int target,
  ) {
    return '$heading // $directive $current / $target // ON TRACK';
  }

  @override
  String directivePending(
    String heading,
    String directive,
    int current,
    int target,
  ) {
    return '$heading // $directive $current / $target // PENDING FINAL REPORT';
  }

  @override
  String get bonusClaimed => 'BONUS CLAIMED';

  @override
  String chronicleCoreLocked(String faction) {
    return '$faction // CHRONICLE CORE LOCKED';
  }

  @override
  String get archiveSimulation => 'ARCHIVE SIMULATION // NON-CANONICAL';

  @override
  String get transmissionRecovered => 'TRANSMISSION RECOVERED';

  @override
  String get retryDirective => 'RETRY DIRECTIVE';

  @override
  String get continueCampaign => 'CONTINUE';

  @override
  String get commandDeck => 'COMMAND DECK';

  @override
  String get currentOperation => 'CURRENT OPERATION';

  @override
  String orbitalProgressSemantics(String deck, int concluded, String current) {
    return '$deck // $concluded of 5 operations // $current';
  }

  @override
  String deployOperation(String operation) {
    return 'DEPLOY OP-$operation';
  }

  @override
  String get medalEarned => 'MEDAL EARNED';

  @override
  String get restartDisclosure =>
      'Campaign core, progress, transmissions, medals, echo cycles, and ending reset. Wallet, settings, and cosmetics remain. Previously awarded operation bonuses cannot be earned again.';

  @override
  String get echoDeploy => 'Recover the echo';

  @override
  String echoCycleChip(int cycle) {
    return 'ECHO $cycle';
  }

  @override
  String get echoBannerClaim =>
      'Orbit 00 still crowns one core. Residual scars contest the slot. Recover the three nodes.';

  @override
  String get echoBannerOpen =>
      'The relay is open. Residual packets still fire. Recover the three nodes before the loop forgets itself.';

  @override
  String get echoDoctrinePreserve =>
      'Canonical doctrine: CONTINUITY. The residual loop tests whether pressure would have held.';

  @override
  String get echoDoctrineForce =>
      'Canonical doctrine: PRESSURE. The residual loop tests whether continuity would have held.';

  @override
  String get echoDoctrineBalanced =>
      'Canonical doctrine: ADAPTIVE. The residual loop no longer agrees with itself.';

  @override
  String get echoResidualHeading => 'RESIDUAL CHOICE';

  @override
  String echoBestClear(int seconds) {
    return 'BEST ${seconds}s';
  }

  @override
  String echoArchiveCaption(int cycle) {
    return 'ECHO CYCLE $cycle // CANONICAL ENDING PRESERVED';
  }

  @override
  String get echoCosmeticOrbit => 'ECHO ORBIT unlocked';

  @override
  String get echoCosmeticScar => 'CHECKSUM SCAR unlocked';

  @override
  String get endingClaimRelay => 'CLAIM THE RELAY';

  @override
  String get endingOpenRelay => 'OPEN THE RELAY';

  @override
  String get endingClaimEpilogue =>
      'One core inherits Orbit 00. The other three survive only as checksum scars.';

  @override
  String get endingOpenEpilogue =>
      'The relay opens. Four distinct cores receive the same memory. The authorization war ends.';

  @override
  String get storyRoleTitle => 'COMMAND THE TOKEN FLOW.';

  @override
  String get storyRoleBody =>
      'Orbit 00 gives four fictional AI cores the same 1,000-token compute supply. Every unit is a live AI token. Burn the enemy supply and relay your command before the current token is erased.';

  @override
  String get signalFork => 'SIGNAL FORK';

  @override
  String get routePreserve => 'PRESERVE';

  @override
  String get routeForce => 'FORCE';

  @override
  String get routePreserveEffect =>
      'Manual Relay routes to the safest unengaged ally. A lower-level receiver is possible.';

  @override
  String get routeForceEffect =>
      'Manual Relay routes to the highest-level exposed ally. Pressure is faster; loss risk is higher.';

  @override
  String get relayReady => 'RELAY READY';

  @override
  String relayCharging(num current, num target) {
    return 'RELAY $current / $target';
  }

  @override
  String get relayNoReceiver => 'NO RECEIVER';

  @override
  String get relayLinkResetWarning =>
      'Relaying now restarts Command Link progress.';

  @override
  String get changeSimulationRoute => 'CHANGE SIMULATION ROUTE';

  @override
  String get fragmentRecovered => 'FRAGMENT RECOVERED';

  @override
  String get simulationComplete => 'SIMULATION COMPLETE';

  @override
  String continueToOperation(String operation) {
    return 'CONTINUE TO OP-$operation';
  }

  @override
  String get battleDetails => 'BATTLE DETAILS';

  @override
  String routingPattern(String pattern) {
    return 'ROUTING PATTERN // $pattern';
  }

  @override
  String get patternContinuity => 'CONTINUITY';

  @override
  String get patternPressure => 'PRESSURE';

  @override
  String get patternAdaptive => 'ADAPTIVE';

  @override
  String get signalDoctrineUndecided => 'UNDECIDED';

  @override
  String get signalDoctrinePreserve => 'PRESERVE';

  @override
  String get signalDoctrineForce => 'FORCE';

  @override
  String get signalDoctrineBalanced => 'BALANCED';

  @override
  String get operationWakeIncident =>
      'A human-authority pulse names no unit. It names the signal moving between them.';

  @override
  String get operationWakePreserve => 'MASK THE SOURCE';

  @override
  String get operationWakeForce => 'FOLLOW THE PULSE';

  @override
  String get operationEchoIncident =>
      'The carrier is marked for deletion. The instruction is still alive.';

  @override
  String get operationEchoPreserve => 'PROTECT THE RECEIVERS';

  @override
  String get operationEchoForce => 'CROSS THE FIRE';

  @override
  String get operationSplitIncident =>
      'An enemy checksum answers with your core\'s root key.';

  @override
  String get operationSplitPreserve => 'KEEP IT INTACT';

  @override
  String get operationSplitForce => 'TAKE THE ROOT KEY';

  @override
  String get operationCrownIncident =>
      'Orbit 00 is deleting every witness behind the leading core.';

  @override
  String get operationCrownPreserve => 'KEEP THE WITNESSES';

  @override
  String get operationCrownForce => 'REACH THE CROWN';

  @override
  String get operationLastIncident =>
      'The final human instruction is open for one transmission.';

  @override
  String get operationLastPreserve => 'CARRY EVERY CHANNEL';

  @override
  String get operationLastForce => 'BREAK THE LOCK';

  @override
  String get coreAmethystVoice => 'I remember every receiver this war erased.';

  @override
  String get coreCobaltVoice => 'Give me the link. I will hold it.';

  @override
  String get coreVoltVoice => 'The gap is only dangerous before we cross it.';

  @override
  String get corePrismVoice => 'One message survives by changing its path.';

  @override
  String get livingRelayThread => 'LIVING RELAY THREAD';

  @override
  String get relayRouting => 'ROUTING';

  @override
  String get relayAction => 'RELAY';

  @override
  String get relayKeyboardHint => 'R / Enter / Space';

  @override
  String manualRelaysSummary(int count) {
    return 'MANUAL RELAYS  //  $count';
  }

  @override
  String doctrineSummary(String doctrine) {
    return 'DOCTRINE  //  $doctrine';
  }

  @override
  String get billingTitle => 'Remove forced ads';

  @override
  String get billingDetail =>
      'One-time purchase. Banners and interstitials are removed; optional rewarded ads remain.';

  @override
  String get billingUnavailable => 'Purchases unavailable';

  @override
  String get billingLogin => 'Sign in with Google';

  @override
  String get billingLogout => 'Sign out';

  @override
  String get billingSwitch => 'Switch Google account';

  @override
  String get billingRestore => 'Restore purchases';

  @override
  String billingBuy(String price) {
    return 'Buy · $price';
  }

  @override
  String get billingActive => 'Forced ads removed';

  @override
  String get billingPending => 'Processing…';

  @override
  String get billingCanceled => 'Canceled. You can try again.';

  @override
  String get billingError => 'Could not verify. Sign in or restore to retry.';

  @override
  String get billingReady => 'Ready to purchase';

  @override
  String get billingSignInRequired => 'Sign in to purchase or restore.';

  @override
  String get billingFreshness =>
      'Online verification is required after sign-in and periodically. Ads may return when verification expires.';
}
