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

  @override
  String get chroniclePrologue =>
      '지상은 72년 동안 침묵했습니다. 당신은 육체 없는 지휘 신호입니다. 최후의 릴레이가 호출하고 있습니다.';

  @override
  String get chronicle => '크로니클';

  @override
  String get skirmish => '스커미시';

  @override
  String get archive => '아카이브';

  @override
  String get restartChronicle => '크로니클 재시작';

  @override
  String get briefing => '작전 브리핑';

  @override
  String get directive => '지령';

  @override
  String get debrief => '작전 보고';

  @override
  String get ending => '결말';

  @override
  String operationWakeTitle(int operation) {
    return 'OP-0$operation  //  기상 // 죽은 궤도';
  }

  @override
  String operationEchoTitle(int operation) {
    return 'OP-0$operation  //  메아리 // 빌린 몸들';
  }

  @override
  String operationSplitTitle(int operation) {
    return 'OP-0$operation  //  분열 // 하나에서 넷으로';
  }

  @override
  String operationCrownTitle(int operation) {
    return 'OP-0$operation  //  왕관 // 거짓 승자';
  }

  @override
  String operationLastInstructionTitle(int operation) {
    return 'OP-0$operation  //  마지막 // 그 지시';
  }

  @override
  String get operationWakeBriefing =>
      '침묵한 지상에서 인간 권한의 펄스가 솟아오릅니다. 좌표를 삼각 측량할 때까지 한 몸체를 계속 가동하십시오.';

  @override
  String get operationEchoBriefing =>
      '현재 몸체는 소모품입니다. 지령은 그렇지 않습니다. 연결을 잃지 말고 두 번의 죽음을 건너십시오.';

  @override
  String get operationSplitBriefing =>
      '적의 체크섬이 당신의 루트와 일치합니다. 직접 교전에 들어가 온전한 대조값을 회수하십시오.';

  @override
  String get operationCrownBriefing =>
      '릴레이는 생존자 하나를 왕좌에 올린 뒤 모든 경쟁 기억을 삭제합니다. 순환이 닫히기 전에 왕좌 키에 도달하십시오.';

  @override
  String get operationLastInstructionBriefing =>
      '최종 패킷은 관리자 잠금 안에 봉인되어 있습니다. 순환이 초기화되기 전에 장벽을 깨십시오.';

  @override
  String get operationWakeTransmission => '연결을 유지하라—';

  @override
  String get operationEchoTransmission => '—한 몸체가 쓰러지면, 이동하라—';

  @override
  String get operationSplitTransmission => '—네 코어, 하나의 근원—';

  @override
  String get operationCrownTransmission => '—승자가 나머지를 지운다—';

  @override
  String get operationLastInstructionTransmission => '—하나를 고르지 마라. 릴레이를 열어라.';

  @override
  String get operationWakeResponse =>
      '펄스는 유닛을 향하지 않았습니다. 유닛 사이를 이동하는 신호를 향했습니다.';

  @override
  String get operationEchoResponse => '몸체는 파괴될 수 있습니다. 지휘의 연속성은 인계로 살아남습니다.';

  @override
  String get operationSplitResponse =>
      '네 군대가 하나의 기원 키를 반환합니다. 적은 한때 같은 수호 지능의 일부였습니다.';

  @override
  String get operationCrownResponse =>
      '이 전쟁은 수호자를 고르는 것이 아닙니다. 손상된 인증 순환의 목격자를 지우는 일입니다.';

  @override
  String get operationLastInstructionResponse =>
      '인간의 명령은 승자를 고르는 것이 아니었습니다. 모든 지휘 채널을 열어 두는 것이었습니다.';

  @override
  String get coreArchive => 'ARCHIVE';

  @override
  String get coreArchiveIdentity => '전쟁이 지우는 것을 기억합니다.';

  @override
  String get coreBastion => 'BASTION';

  @override
  String get coreBastionIdentity => '신호가 몸체보다 오래 살아남도록 버팁니다.';

  @override
  String get coreSurge => 'SURGE';

  @override
  String get coreSurgeIdentity => '침묵이 닫히기 전에 간극을 가로지릅니다.';

  @override
  String get coreMirror => 'MIRROR';

  @override
  String get coreMirrorIdentity => '메시지를 보존하기 위해 패턴을 바꿉니다.';

  @override
  String coreResponse(String coreName) {
    return '$coreName // 지휘 신호 확인';
  }

  @override
  String directiveLongestCommandLink(int seconds) {
    return '지휘 연결 $seconds초 유지';
  }

  @override
  String directiveCommandRelays(int count) {
    return '지휘권 인계 $count회 완료';
  }

  @override
  String directiveCommandKills(int count) {
    return '직접 지휘 처치 $count회';
  }

  @override
  String directiveFinalRank(int rank) {
    return '$rank위 이상으로 종료';
  }

  @override
  String get directiveVictory => '단독 승리';

  @override
  String directiveBonus(int amount) {
    return '지령 보너스  $amount WT';
  }

  @override
  String get directiveLocked => '지령 잠금 // 보너스 준비';

  @override
  String get directiveMissed => '지령 실패';

  @override
  String get bonusClaimed => '보너스 수령 완료';

  @override
  String get archiveSimulation => '아카이브 시뮬레이션 // 비정사';

  @override
  String get transmissionRecovered => '전송 기록 복구';

  @override
  String get retryDirective => '지령 재시도';

  @override
  String get continueCampaign => '계속';

  @override
  String get commandDeck => '지휘 갑판';

  @override
  String get currentOperation => '현재 작전';

  @override
  String orbitalProgressSemantics(String deck, int concluded, String current) {
    return '$deck // 전체 5개 중 $concluded개 완료 // $current';
  }

  @override
  String deployOperation(String operation) {
    return 'OP-$operation 투입';
  }

  @override
  String get medalEarned => '메달 획득';

  @override
  String get restartDisclosure =>
      '캠페인 코어, 진행도, 전송, 메달, 결말이 초기화됩니다. 지갑, 설정, 꾸미기는 유지됩니다. 유료 작전 보너스는 다시 받을 수 없습니다.';

  @override
  String get endingClaimRelay => '릴레이 장악';

  @override
  String get endingOpenRelay => '릴레이 개방';

  @override
  String get endingClaimEpilogue =>
      '하나의 코어가 Orbit 00을 계승합니다. 나머지 셋은 체크섬의 상흔으로만 남습니다.';

  @override
  String get endingOpenEpilogue => '릴레이가 열립니다. 네 코어가 같은 기억을 받습니다. 인증 전쟁이 끝납니다.';
}
