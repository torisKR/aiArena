// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Tokenfront: 궤도 신호전';

  @override
  String get lobbyTagline => '네 AI 코어. 단 하나의 최후 릴레이.';

  @override
  String factionSignal(String faction) {
    return '$faction 신호';
  }

  @override
  String get factionBrief => '1,000 유닛 · Lv.1–10 균형 · 지휘권 연속 유지';

  @override
  String get deploySignal => '궤도 투입';

  @override
  String lockerBalance(int balance) {
    return '보관소  $balance WT';
  }

  @override
  String get tune => '조정';

  @override
  String get signalSettings => '신호 설정';

  @override
  String get offline => '오프라인';

  @override
  String chooseFaction(String faction) {
    return '$faction 진영 선택';
  }

  @override
  String unitsCount(int count) {
    return '$count 유닛';
  }

  @override
  String get units => '유닛';

  @override
  String get highLevel => '고레벨';

  @override
  String get wins => '승리';

  @override
  String get equalLevel => '동급';

  @override
  String get death => '사망';

  @override
  String get relays => '지휘 인계';

  @override
  String get move => '이동';

  @override
  String get stickWasd => '스틱 / WASD';

  @override
  String get dash => '돌진';

  @override
  String get buttonSpace => '버튼 / SPACE';

  @override
  String get sponsorBannerArea => '스폰서 배너 영역';

  @override
  String get sponsorSignal => '스폰서 신호';

  @override
  String get lobbyPlacement => '로비 배치';

  @override
  String get languageSection => '언어';

  @override
  String get displayLanguage => '표시 언어';

  @override
  String get displayLanguageDetail => '기기 언어를 따르거나 이 게임에서 사용할 언어를 선택합니다.';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get settingsTitle => '신호 조정';

  @override
  String get settingsSubtitle => '전투력 변화 없이 전장을 조정합니다.';

  @override
  String get closeSettings => '설정 닫기';

  @override
  String get battlefieldSection => '전장';

  @override
  String get lowSpecFilter => '저사양 필터';

  @override
  String get lowSpecFilterDetail => '파티클과 고비용 전장 효과를 줄입니다.';

  @override
  String get reduceMotion => '모션 줄이기';

  @override
  String get reduceMotionDetail => '지휘 인계 카메라 이동과 큰 전환을 줄입니다.';

  @override
  String get mouseCamera => '마우스 카메라';

  @override
  String get mouseCameraDetail => '웹에서 휠 확대와 드래그 이동을 사용합니다.';

  @override
  String get audioCues => '효과음 신호';

  @override
  String get audioCuesDetail => '돌진, 전투, 지휘 인계 신호음을 재생합니다.';

  @override
  String get hapticCues => '진동 신호';

  @override
  String get hapticCuesDetail => '지원 기기에서 돌진과 지휘 인계를 진동으로 알립니다.';

  @override
  String get privacySection => '개인정보';

  @override
  String get shareAnalytics => '분석 공유';

  @override
  String get shareAnalyticsDetail => '온라인일 때 익명 매치 이벤트를 모아 전송합니다.';

  @override
  String get adRequests => '광고 요청';

  @override
  String get adRequestsDetail => '로비와 결과 광고를 허용합니다. 추적에는 플랫폼 권한이 별도로 필요합니다.';

  @override
  String get privacyDefaultNote =>
      '두 옵션은 기본 꺼짐입니다. 어느 옵션을 꺼도 오프라인 매치와 보상은 정상 작동합니다.';

  @override
  String get closePanel => '패널 닫기';

  @override
  String get stateOff => '끔';

  @override
  String get stateOn => '켬';

  @override
  String get semanticsOff => '꺼짐';

  @override
  String get semanticsOn => '켜짐';

  @override
  String needMoreWarTokens(int count) {
    return '워 토큰 $count개가 더 필요합니다.';
  }

  @override
  String get signalLocker => '신호 보관소';

  @override
  String get lockerSubtitle => '워 토큰은 전장 외형에만 사용됩니다. 전투력은 변하지 않습니다.';

  @override
  String warTokenBalance(int balance) {
    return '워 토큰 $balance개';
  }

  @override
  String get closeSignalLocker => '신호 보관소 닫기';

  @override
  String get equipped => '장착됨';

  @override
  String get equip => '장착';

  @override
  String unlockCost(int cost) {
    return '해금  $cost';
  }

  @override
  String get commandEdge => '지휘 테두리';

  @override
  String get movementTrace => '이동 흔적';

  @override
  String get defeatMark => '전사 표식';

  @override
  String get cosmeticFieldIssueName => '기본 지급';

  @override
  String get cosmeticFieldIssueDescription => '진영 신호의 기본 색상입니다.';

  @override
  String get cosmeticRelayIvoryName => '릴레이 아이보리';

  @override
  String get cosmeticRelayIvoryDescription => '진영 중심부를 가리지 않는 아이보리 지휘 테두리입니다.';

  @override
  String get cosmeticOxideEdgeName => '옥사이드 엣지';

  @override
  String get cosmeticOxideEdgeDescription => '조종 유닛에 따뜻한 전술 테두리를 더합니다.';

  @override
  String get cosmeticCleanWakeName => '클린 웨이크';

  @override
  String get cosmeticCleanWakeDescription => '이동 흔적을 남기지 않습니다.';

  @override
  String get cosmeticRelayTapeName => '릴레이 테이프';

  @override
  String get cosmeticRelayTapeDescription => '짧게 분절된 지휘 흔적입니다.';

  @override
  String get cosmeticCinderGridName => '신더 그리드';

  @override
  String get cosmeticCinderGridDescription => '빠른 이동에 성긴 옥사이드 흔적을 남깁니다.';

  @override
  String get cosmeticSignalRingName => '신호 링';

  @override
  String get cosmeticSignalRingDescription => '작고 선명한 기본 전사 파동입니다.';

  @override
  String get cosmeticFractureName => '4방향 파열';

  @override
  String get cosmeticFractureDescription => '게임플레이에 영향을 주지 않는 선명한 기하학 파열입니다.';

  @override
  String get signalLostObserving => '신호 소실  /  잔여 전투 관전';

  @override
  String timeRemaining(String time) {
    return '남은 시간 $time';
  }

  @override
  String factionAlive(String faction, int count) {
    return '$faction 생존 $count';
  }

  @override
  String get cameraShort => '시점';

  @override
  String get ecoShort => '절전';

  @override
  String get lockShort => '복귀';

  @override
  String get mouseCameraSemantics => '마우스 드래그와 휠 카메라';

  @override
  String get lowPowerModeSemantics => '저전력 모드';

  @override
  String get resetCameraSemantics => '조종 유닛으로 카메라 복귀';

  @override
  String get battlePausedSemantics => '앱이 비활성 상태라 전투가 일시정지됨';

  @override
  String get battlePaused => '신호 대기  /  전투 일시정지';

  @override
  String controlledUnitStatus(int level, int killCount, int relayCount) {
    return '조종 유닛 레벨 $level, 처치 $killCount, 지휘 인계 $relayCount';
  }

  @override
  String controlledUnitVisualStatus(
    String level,
    String killCount,
    String relayCount,
  ) {
    return 'LV $level  /  처치 $killCount  /  인계 $relayCount';
  }

  @override
  String get movementJoystick => '이동 스틱';

  @override
  String get movementJoystickHint =>
      '드래그하여 이동합니다. 키보드는 WASD 또는 방향키를 사용할 수 있습니다.';

  @override
  String get tacticalMapSemantics => '전술 지도';

  @override
  String get tacticalMapHint => '드래그하거나 방향키로 카메라를 이동합니다. 실행하면 조종 유닛으로 돌아갑니다.';

  @override
  String get rotateToPlay => '가로로 돌려 플레이';

  @override
  String get rotateToPlayHint =>
      'Tokenfront 전투는 가로 화면에서 진행됩니다. 계속하려면 휴대폰을 돌려 주세요.';

  @override
  String get dashSemantics => '돌진';

  @override
  String get dashHint => '잠시 이동 속도가 2배가 됩니다. 키보드 단축키는 SPACE입니다.';

  @override
  String get dashKeyLabel => '돌진\nSPACE';

  @override
  String commandHandoff(String stage, int progress) {
    return '지휘 인계: $stage, $progress퍼센트';
  }

  @override
  String get handoffImpactHold => '충격 정지';

  @override
  String get handoffCasualtyFocus => '전사자 포커스 · 0.5×';

  @override
  String get handoffSuccessorScan => '후계 유닛 산정';

  @override
  String get handoffRelayTravel => '지휘 인계 중';

  @override
  String get handoffSignalLock => '신호 고정';

  @override
  String get combatWinCode => 'WIN';

  @override
  String get combatOutCode => 'OUT';

  @override
  String get signalSurvived => '신호 생존';

  @override
  String get signalLost => '신호 소실';

  @override
  String drawSummary(String duration, String matchId) {
    return '무승부  /  $duration  /  $matchId';
  }

  @override
  String winnerSummary(String winner, String duration, String matchId) {
    return '$winner, 최후 신호 확보  /  $duration  /  $matchId';
  }

  @override
  String get match => '매치';

  @override
  String get complete => '완료';

  @override
  String get warToken => '워 토큰';

  @override
  String warTokensSecured(int count) {
    return '+$count 워 토큰 확보.';
  }

  @override
  String get requestingAd => '광고 요청 중…';

  @override
  String get rewardDoubled => '보상 2배 완료';

  @override
  String get doubleReward => '보상 2배';

  @override
  String get rematch => '재대결';

  @override
  String get lobby => '로비';

  @override
  String get locker => '보관소';

  @override
  String get settings => '설정';

  @override
  String get adRequestsOffMessage =>
      '광고 요청이 꺼져 있습니다. 설정에서 켤 수 있으며 기본 보상은 유지됩니다.';

  @override
  String get noConnectionRewardMessage => '연결되지 않았습니다. 매치와 기본 보상은 완료 처리됐습니다.';

  @override
  String get noRewardedAdMessage => '사용 가능한 보상형 광고가 없습니다. 기본 보상은 지급됐습니다.';

  @override
  String get adFailedRewardMessage => '광고에 실패했습니다. 기본 보상은 지급됐습니다.';

  @override
  String get rewardOfferUnavailableMessage => '이 보상 제안은 더 이상 사용할 수 없습니다.';

  @override
  String get rewardRequestCompleteMessage => '보상 요청이 완료됐습니다.';

  @override
  String get resultSponsorPlacement => '스폰서 신호  /  결과 배치';

  @override
  String get faction => '진영';

  @override
  String get alive => '생존';

  @override
  String get levelSum => 'Σ LV';

  @override
  String get kills => '처치';

  @override
  String standingFactionYou(String faction) {
    return '$faction  · 나';
  }

  @override
  String get chronicleUnavailable => '시그널 크로니클 이용 불가';
}
