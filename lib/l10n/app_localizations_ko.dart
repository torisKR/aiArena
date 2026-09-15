// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get recoveryTitle => '신호 세 개 회수하기';

  @override
  String get recoveryInstruction =>
      '1, 2, 3을 눌러 목적지를 고르세요. 이동과 전투는 자동입니다. 토큰이 쓰러지면 다른 토큰이 이어갑니다. 회수 진행도는 유지됩니다.';

  @override
  String get recoveryAutomatic => '자동 이동 · 자동 전투 · 자동 이어받기';

  @override
  String get recoveryWon => '신호 회수 완료';

  @override
  String get recoveryLost => '회수 종료';

  @override
  String get recoveryTimeout => '시간 초과';

  @override
  String get recoveryAlliesLost => '아군 전멸';

  @override
  String recoveryProgress(int count) {
    return '신호 $count/3개 회수';
  }

  @override
  String recoveryDestination(int number, int seconds) {
    return '신호 $number: $seconds/10초';
  }

  @override
  String get appTitle => 'Tokenfront: 궤도 신호전';

  @override
  String get lobbyTagline => '네 AI 코어. 4,000개의 활성 토큰. 단 하나의 최후 릴레이.';

  @override
  String factionSignal(String faction) {
    return '$faction 신호';
  }

  @override
  String get factionBrief => '활성 AI 토큰 1,000개 · Lv.1–10 균형 · 지휘권 연속 유지';

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
    return '$faction AI 코어 선택';
  }

  @override
  String unitsCount(int count) {
    return 'AI 토큰 $count개';
  }

  @override
  String get units => 'AI 토큰';

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
  String get privacyPolicyTitle => '개인정보처리방침';

  @override
  String get privacyOptions => '광고 개인정보 설정';

  @override
  String get privacyPolicyEffectiveDate => '시행일: 2026-08-05';

  @override
  String get privacyPolicyIntro =>
      'Tokenfront는 오프라인 싱글 플레이 게임입니다. 게임 플레이와 로컬 진행 정보는 기기에 보관됩니다. 광고 요청을 켜고 동의 절차가 허용하면 Google AdMob 테스트 광고가 광고 요청과 기기/광고 식별자를 처리할 수 있습니다.';

  @override
  String get privacyDataStoredTitle => '기기에 저장되는 데이터';

  @override
  String get privacyDataStoredBody =>
      'Tokenfront는 War Token 잔액, 코스메틱 잠금 해제 및 장착 상태, 언어, 접근성, 오디오, 카메라, 햅틱 및 개인정보 선택, Signal Chronicle 진행 상태를 앱 전용 로컬 저장소에 보관합니다. 외부로 업로드하지 않으며 앱 저장공간을 삭제하거나 앱을 제거하면 지워집니다.';

  @override
  String get privacyAnalyticsTitle => '분석';

  @override
  String get privacyAnalyticsBody =>
      '게임 플레이 및 성능 이벤트는 최대 500개의 임시 메모리 버퍼에 존재할 수 있습니다. 이 출시 버전은 분석 전송 기능을 사용하지 않고 이벤트를 전송하지 않으며 프로세스 종료 시 버퍼를 삭제합니다.';

  @override
  String get privacyAdvertisingTitle => '광고';

  @override
  String get privacyAdvertisingBody =>
      '이 Android 테스트 빌드는 Google 테스트 광고 단위와 Google Mobile Ads를 사용합니다. 선택한 로비·결과 배너, 결과 보상형 광고, 결과 종료 전면 광고는 Google 동의 절차가 허용한 뒤에만 요청됩니다. AdMob은 Google 정책에 따라 광고 요청, 기기 정보, 광고 식별자를 처리할 수 있습니다. 광고 요청을 끄면 앱의 광고 요청이 중단되며 기본 War Token 보상에는 영향이 없습니다.';

  @override
  String get privacyAccountsTitle => '계정·권한·제3자';

  @override
  String get privacyAccountsBody =>
      'Tokenfront에는 계정, 로그인, 클라우드 동기화, 구매 시스템, 사용자 제출 콘텐츠, 소셜 기능이 없습니다. 위치, 카메라, 마이크, 연락처, 사진, 파일, 캘린더, 건강, 금융, 메시지 권한을 요청하지 않습니다.';

  @override
  String get privacyHostingTitle => '공개 정책 페이지 호스팅';

  @override
  String get privacyHostingBody =>
      '공개 정책은 Cloudflare Pages에서 호스팅됩니다. 외부 브라우저로 열면 Cloudflare가 자체 조건에 따라 일반적인 웹 요청 데이터를 처리할 수 있습니다. Android 앱은 공개 페이지를 내장하지 않으며 게임 플레이나 로컬 상태 데이터를 보내지 않습니다.';

  @override
  String get privacyChildrenTitle => '아동';

  @override
  String get privacyChildrenBody =>
      'Tokenfront는 만 13세 이상 이용자를 대상으로 하며 만 13세 미만 아동을 대상으로 하지 않습니다. 이 출시 버전은 개인정보를 수집하지 않습니다.';

  @override
  String get privacyChangesTitle => '변경';

  @override
  String get privacyChangesBody =>
      '향후 버전에 분석 전송, 광고, 계정, 클라우드 서비스 또는 다른 기기 외부 데이터 흐름을 추가하기 전에 이 정책과 Google Play 데이터 보안 선언을 갱신합니다.';

  @override
  String get privacyContactTitle => '문의';

  @override
  String get privacyPublicUrlLabel => '공개 정책 URL';

  @override
  String get privacyOpenPublicPage => '공개 페이지 열기';

  @override
  String get privacyCopyUrl => 'URL 복사';

  @override
  String get privacyUrlCopied => '개인정보처리방침 URL을 복사했습니다.';

  @override
  String get privacyOpenFailed =>
      '공개 정책 페이지를 열 수 없습니다. 전체 정책은 이 화면에서 계속 읽을 수 있습니다.';

  @override
  String get releaseServicesUnavailable => '이 출시 버전에서는 사용할 수 없음';

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
    return '$faction 활성 AI 토큰 $count개';
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
  String get battleUserPausedSemantics => '사용자가 전투를 일시정지함';

  @override
  String get battlePaused => '신호 대기  /  전투 일시정지';

  @override
  String get pauseBattle => '일시정지';

  @override
  String get resumeBattle => '재개';

  @override
  String get pauseBattleSemantics => '전투 일시정지 또는 재개';

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
  String get alive => '활성 토큰';

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
  String get coreArchiveIdentity => '토큰 전쟁이 지운 문맥을 끝까지 보존합니다.';

  @override
  String get coreBastion => 'BASTION';

  @override
  String get coreBastionIdentity => '연산 예산을 천천히 써서 신호를 오래 유지합니다.';

  @override
  String get coreSurge => 'SURGE';

  @override
  String get coreSurgeIdentity => '토큰을 빠르게 소각해 간극을 먼저 돌파합니다.';

  @override
  String get coreMirror => 'MIRROR';

  @override
  String get coreMirrorIdentity => '적의 패턴을 재사용해 토큰 예산을 늘립니다.';

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
  String get directiveComplete => '지령 완료';

  @override
  String get directiveMissed => '지령 실패';

  @override
  String get directiveNameLongestCommandLink => '지휘 연결';

  @override
  String get directiveNameCommandRelays => '지휘권 인계';

  @override
  String get directiveNameCommandKills => '직접 지휘 처치';

  @override
  String get directiveNameFinalRank => '최종 순위';

  @override
  String get directiveNameVictory => '승리';

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
    return '$heading // $directive $current / $target // 진행 중';
  }

  @override
  String directivePending(
    String heading,
    String directive,
    int current,
    int target,
  ) {
    return '$heading // $directive $current / $target // 최종 보고 대기';
  }

  @override
  String get bonusClaimed => '보너스 수령 완료';

  @override
  String chronicleCoreLocked(String faction) {
    return '$faction // 크로니클 코어 잠금';
  }

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
      '캠페인 코어, 진행도, 전송, 메달, 결말이 초기화됩니다. 지갑, 설정, 꾸미기는 유지됩니다. 이전에 지급된 작전 보너스는 다시 받을 수 없습니다.';

  @override
  String get endingClaimRelay => '릴레이 장악';

  @override
  String get endingOpenRelay => '릴레이 개방';

  @override
  String get endingClaimEpilogue =>
      '하나의 코어가 Orbit 00을 계승합니다. 나머지 셋은 체크섬의 상흔으로만 남습니다.';

  @override
  String get endingOpenEpilogue => '릴레이가 열립니다. 네 코어가 같은 기억을 받습니다. 인증 전쟁이 끝납니다.';

  @override
  String get storyRoleTitle => 'AI 토큰 흐름을 지휘하라.';

  @override
  String get storyRoleBody =>
      '궤도 00의 네 가상 AI 코어는 각각 1,000개의 동일한 연산 토큰으로 전쟁을 시작한다. 모든 유닛은 활성 AI 토큰이다. 적의 공급량을 소각하고 현재 토큰이 지워지기 전에 지휘 신호를 넘겨라.';

  @override
  String get signalFork => '신호 분기';

  @override
  String get routePreserve => '보존';

  @override
  String get routeForce => '강행';

  @override
  String get routePreserveEffect =>
      '수동 릴레이가 교전하지 않은 아군 중 가장 안전한 대상에게 연결됩니다. 낮은 레벨의 수신자일 수 있습니다.';

  @override
  String get routeForceEffect =>
      '수동 릴레이가 노출된 아군 중 레벨이 가장 높은 대상에게 연결됩니다. 압박은 빠르지만 손실 위험이 커집니다.';

  @override
  String get relayReady => '릴레이 준비 완료';

  @override
  String relayCharging(num current, num target) {
    return '릴레이 $current / $target';
  }

  @override
  String get relayNoReceiver => '수신자 없음';

  @override
  String get relayLinkResetWarning => '지금 릴레이하면 지휘 연결 진행도가 다시 시작됩니다.';

  @override
  String get changeSimulationRoute => '시뮬레이션 경로 변경';

  @override
  String get fragmentRecovered => '조각 회수';

  @override
  String get simulationComplete => '시뮬레이션 완료';

  @override
  String continueToOperation(String operation) {
    return 'OP-$operation(으)로 계속';
  }

  @override
  String get battleDetails => '전투 상세';

  @override
  String routingPattern(String pattern) {
    return '라우팅 패턴 // $pattern';
  }

  @override
  String get patternContinuity => '연속성';

  @override
  String get patternPressure => '압박';

  @override
  String get patternAdaptive => '적응형';

  @override
  String get signalDoctrineUndecided => '미결정';

  @override
  String get signalDoctrinePreserve => '보존';

  @override
  String get signalDoctrineForce => '강행';

  @override
  String get signalDoctrineBalanced => '균형';

  @override
  String get operationWakeIncident =>
      '인간 권한의 펄스는 어떤 유닛도 지목하지 않는다. 유닛 사이를 이동하는 신호를 지목한다.';

  @override
  String get operationWakePreserve => '근원을 숨겨라';

  @override
  String get operationWakeForce => '펄스를 따라가라';

  @override
  String get operationEchoIncident => '운반체가 삭제 대상으로 표시됐다. 지시는 아직 살아 있다.';

  @override
  String get operationEchoPreserve => '수신자를 지켜라';

  @override
  String get operationEchoForce => '포화를 가로질러라';

  @override
  String get operationSplitIncident => '적의 체크섬이 네 코어의 루트 키에 응답한다.';

  @override
  String get operationSplitPreserve => '온전하게 지켜라';

  @override
  String get operationSplitForce => '루트 키를 차지하라';

  @override
  String get operationCrownIncident => '궤도 00이 선두 코어 뒤의 모든 목격자를 삭제하고 있다.';

  @override
  String get operationCrownPreserve => '목격자를 지켜라';

  @override
  String get operationCrownForce => '왕관에 도달하라';

  @override
  String get operationLastIncident => '마지막 인간의 지시가 한 번의 전송을 위해 열렸다.';

  @override
  String get operationLastPreserve => '모든 채널을 운반하라';

  @override
  String get operationLastForce => '잠금을 부숴라';

  @override
  String get coreAmethystVoice => '이 전쟁이 지워 버린 모든 수신자를 기억한다.';

  @override
  String get coreCobaltVoice => '연결을 맡겨. 내가 지켜 낼게.';

  @override
  String get coreVoltVoice => '틈은 건너기 전까지만 위험하다.';

  @override
  String get corePrismVoice => '경로를 바꾸면 하나의 메시지가 살아남는다.';

  @override
  String get livingRelayThread => '살아 있는 릴레이 스레드';

  @override
  String get relayRouting => '라우팅 중';

  @override
  String get relayAction => '릴레이';

  @override
  String get relayKeyboardHint => 'R / Enter / Space';

  @override
  String manualRelaysSummary(int count) {
    return '수동 릴레이  //  $count';
  }

  @override
  String doctrineSummary(String doctrine) {
    return '신호 교리  //  $doctrine';
  }
}
