// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get billingDelete => '删除付费账户';

  @override
  String get billingDeleteWarning =>
      '将删除Tokenfront付费账户和购买验证记录。去广告权益及恢复关联将终止，删除后不保证能够恢复。这不会退款，也不会删除Google / Google Play记录。是否继续并验证同一个Google账户？';

  @override
  String get billingDeleteCancel => '取消';

  @override
  String get billingDeleteConfirm => '删除并通过Google验证';

  @override
  String get billingDeleted => '付费账户已删除。此设备上的去广告权益已终止。';

  @override
  String get billingDeleteFailed =>
      '尚未确认删除。请尽快使用同一账户重试。无法重试时请联系korea@toris.kr。';

  @override
  String get billingDeleteLocalFailed =>
      '服务器账户已删除，但本地清理失败。请保持应用开启并重试。磁盘上可能仍有缓存数据；如果问题持续，请联系korea@toris.kr。';

  @override
  String get recoveryTitle => '回收三个信号';

  @override
  String get recoveryInstruction =>
      '点击1、2或3选择目的地。移动和战斗自动进行。当前单位倒下后，其他单位会自动接手，回收进度保留。';

  @override
  String get recoveryAutomatic => '自动移动 · 自动战斗 · 自动接手';

  @override
  String get recoveryChooseDestination => '选择目的地';

  @override
  String get recoveryWon => '信号回收完成';

  @override
  String get recoveryLost => '回收结束';

  @override
  String get recoveryTimeout => '超时';

  @override
  String get recoveryAlliesLost => '盟友全灭';

  @override
  String recoveryProgress(int count) {
    return '已回收 $count/3 个信号';
  }

  @override
  String recoveryDestination(int number, int seconds) {
    return '信号 $number：$seconds/8秒';
  }

  @override
  String get appTitle => 'Tokenfront：轨道信号战';

  @override
  String get lobbyTagline => '四个AI核心，4,000个活跃代币，最后一座中继站。';

  @override
  String factionSignal(String faction) {
    return '$faction 信号';
  }

  @override
  String get factionBrief => '1,000个活跃AI代币 · Lv.1–10均衡 · 指挥连续';

  @override
  String get deploySignal => '部署至轨道';

  @override
  String lockerBalance(int balance) {
    return '装备库  $balance WT';
  }

  @override
  String get tune => '调校';

  @override
  String get signalSettings => '信号设置';

  @override
  String get offline => '离线';

  @override
  String chooseFaction(String faction) {
    return '选择$faction AI核心';
  }

  @override
  String unitsCount(int count) {
    return '$count个AI代币';
  }

  @override
  String get units => 'AI代币';

  @override
  String get highLevel => '高等级';

  @override
  String get wins => '胜';

  @override
  String get equalLevel => '同级';

  @override
  String get death => '阵亡';

  @override
  String get relays => '指挥接替';

  @override
  String get move => '移动';

  @override
  String get stickWasd => '摇杆 / WASD';

  @override
  String get dash => '冲刺';

  @override
  String get buttonSpace => '按钮 / SPACE';

  @override
  String get sponsorBannerArea => '赞助商横幅区域';

  @override
  String get sponsorSignal => '赞助信号';

  @override
  String get lobbyPlacement => '大厅广告位';

  @override
  String get languageSection => '语言';

  @override
  String get displayLanguage => '显示语言';

  @override
  String get displayLanguageDetail => '跟随设备语言，或为本游戏选择一种语言。';

  @override
  String get languageSystem => '系统默认';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get settingsTitle => '信号调校';

  @override
  String get settingsSubtitle => '调整战场，不改变战斗力。';

  @override
  String get closeSettings => '关闭设置';

  @override
  String get battlefieldSection => '战场';

  @override
  String get lowSpecFilter => '低配过滤';

  @override
  String get lowSpecFilterDetail => '减少粒子和高负载战场细节。';

  @override
  String get reduceMotion => '减少动态效果';

  @override
  String get reduceMotionDetail => '缩短指挥接替时的镜头移动和大型转场。';

  @override
  String get mouseCamera => '鼠标镜头';

  @override
  String get mouseCameraDetail => '在Web端启用滚轮缩放和拖动平移。';

  @override
  String get audioCues => '音效提示';

  @override
  String get audioCuesDetail => '播放冲刺、战斗和指挥接替提示音。';

  @override
  String get hapticCues => '触觉提示';

  @override
  String get hapticCuesDetail => '在支持的设备上用振动提示冲刺和指挥接替。';

  @override
  String get privacySection => '隐私';

  @override
  String get shareAnalytics => '共享分析数据';

  @override
  String get shareAnalyticsDetail => '在线时批量发送匿名对局事件。';

  @override
  String get adRequests => '广告请求';

  @override
  String get adRequestsDetail => '允许大厅和结果页广告。追踪仍需平台权限。';

  @override
  String get privacyDefaultNote => '两项默认关闭。关闭任一项都不影响离线对局和奖励。';

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String get privacyOptions => '广告隐私设置';

  @override
  String get privacyPolicyEffectiveDate => '生效日期：2026-08-05';

  @override
  String get privacyPolicyIntro =>
      'Tokenfront 是一款离线单人游戏。游戏过程和本地进度保存在设备上。启用广告请求且同意流程允许时，Google AdMob 广告可能会处理广告请求以及设备/广告标识符。';

  @override
  String get privacyDataStoredTitle => '存储在设备上的数据';

  @override
  String get privacyDataStoredBody =>
      'War Token 余额、外观解锁与装备、语言、无障碍、音频、镜头、触觉与隐私选项以及 Signal Chronicle 进度仅保存在应用专用本地存储中，不会上传；清除应用数据或卸载应用即可删除。';

  @override
  String get privacyAnalyticsTitle => '分析';

  @override
  String get privacyAnalyticsBody =>
      '游戏与性能事件可能暂存在最多 500 条的内存缓冲区中。此版本未启用分析传输，不发送事件，并会在进程结束时丢弃缓冲区。';

  @override
  String get privacyAdvertisingTitle => '广告';

  @override
  String get privacyAdvertisingBody =>
      '调试和性能分析版本使用 Google 测试广告单元；签名发布版本使用已配置的 Tokenfront 正式广告单元。所有请求均为非个性化广告，但这不代表禁止收集广告标识符。大厅和结果页横幅、结果页激励广告以及结果退出插屏只有在 Google 同意流程允许后才会请求。AdMob 可能按照 Google 的说明处理广告请求、设备信息和广告标识符。关闭广告请求会停止应用广告请求，但不会影响基础 War Token 奖励。';

  @override
  String get privacyAccountsTitle => '账户、权限与第三方';

  @override
  String get privacyAccountsBody =>
      '已发布的1.2.0没有登录或购买功能。以下为未来版本草案，功能已禁用，尚待发布。游戏无需Google登录，但一次性去广告购买与恢复需要登录；自选激励广告仍保留。Toris的Cloudflare Workers后端将验证Google身份及Google Play购买，D1将保存假名化（并非匿名）的账户绑定、加密购买令牌及其哈希、订单ID、商品、状态及验证和检查时间。后端不保存邮箱或个人资料。签名权益与账户绑定将在验证成功后于本地缓存最多30天；这不是服务器记录的保留期限。清除应用数据或退出登录不会删除服务器记录。删除端点、操作流程和保留政策尚缺，属于发布阻断项；不承诺删除服务已运营。隐私咨询：korea@toris.kr；请勿发送令牌或密码。不增加游戏云同步、社交功能或位置、相机、麦克风、联系人、照片、日历、健康、消息访问。';

  @override
  String get privacyHostingTitle => '公开政策托管';

  @override
  String get privacyHostingBody =>
      '公开版本由 Cloudflare Pages 托管。通过外部浏览器打开时，Cloudflare 可能依据其条款处理常规网络请求数据。Android 应用不会嵌入公开页面，也不会向其发送游戏或本地状态数据。';

  @override
  String get privacyChildrenTitle => '儿童';

  @override
  String get privacyChildrenBody =>
      'Tokenfront面向13岁及以上玩家，并非为13岁以下儿童设计。广告处理如上所述；拟议的账户与购买处理已禁用并单独披露。';

  @override
  String get privacyChangesTitle => '变更';

  @override
  String get privacyChangesBody =>
      '未来版本在加入分析传输、广告、账户、云服务或其他设备外数据流之前，会更新本政策与 Google Play 数据安全声明。';

  @override
  String get privacyContactTitle => '联系';

  @override
  String get privacyPublicUrlLabel => '公开政策网址';

  @override
  String get privacyOpenPublicPage => '打开公开页面';

  @override
  String get privacyCopyUrl => '复制网址';

  @override
  String get privacyUrlCopied => '已复制隐私政策网址。';

  @override
  String get privacyOpenFailed => '无法打开公开政策页面。你仍可在此屏幕阅读完整政策。';

  @override
  String get releaseServicesUnavailable => '此版本不可用';

  @override
  String get closePanel => '关闭面板';

  @override
  String get stateOff => '关';

  @override
  String get stateOn => '开';

  @override
  String get semanticsOff => '关闭';

  @override
  String get semanticsOn => '开启';

  @override
  String needMoreWarTokens(int count) {
    return '还需$count枚战争代币。';
  }

  @override
  String get signalLocker => '信号装备库';

  @override
  String get lockerSubtitle => '战争代币仅用于战场外观，不会改变战斗力。';

  @override
  String warTokenBalance(int balance) {
    return '$balance枚战争代币';
  }

  @override
  String get closeSignalLocker => '关闭信号装备库';

  @override
  String get equipped => '已装备';

  @override
  String get equip => '装备';

  @override
  String unlockCost(int cost) {
    return '解锁  $cost';
  }

  @override
  String get commandEdge => '指挥轮廓';

  @override
  String get movementTrace => '移动轨迹';

  @override
  String get defeatMark => '阵亡标记';

  @override
  String get cosmeticFieldIssueName => '标准配发';

  @override
  String get cosmeticFieldIssueDescription => '标准阵营信号配色。';

  @override
  String get cosmeticRelayIvoryName => '中继象牙白';

  @override
  String get cosmeticRelayIvoryDescription => '象牙白指挥轮廓，保持阵营核心清晰可辨。';

  @override
  String get cosmeticOxideEdgeName => '氧化边缘';

  @override
  String get cosmeticOxideEdgeDescription => '为受控单位增加暖色战术轮廓。';

  @override
  String get cosmeticCleanWakeName => '无痕尾迹';

  @override
  String get cosmeticCleanWakeDescription => '不留下持续移动轨迹。';

  @override
  String get cosmeticRelayTapeName => '中继带';

  @override
  String get cosmeticRelayTapeDescription => '短而分段的指挥轨迹。';

  @override
  String get cosmeticCinderGridName => '余烬网格';

  @override
  String get cosmeticCinderGridDescription => '高速移动时留下稀疏的氧化尾迹。';

  @override
  String get cosmeticSignalRingName => '信号环';

  @override
  String get cosmeticSignalRingDescription => '标准紧凑型阵亡脉冲。';

  @override
  String get cosmeticFractureName => '四向裂变';

  @override
  String get cosmeticFractureDescription => '清晰的几何裂变，不影响游戏玩法。';

  @override
  String get cosmeticEchoOrbitName => 'ECHO ORBIT';

  @override
  String get cosmeticEchoOrbitDescription => '首次回响周期通关后授予的残余轨道颜料。';

  @override
  String get cosmeticChecksumScarName => 'CHECKSUM SCAR';

  @override
  String get cosmeticChecksumScarDescription => '记录两种结局后授予的残余伤痕轨迹。';

  @override
  String get signalLostObserving => '信号丢失  /  观战剩余战局';

  @override
  String timeRemaining(String time) {
    return '剩余时间 $time';
  }

  @override
  String factionAlive(String faction, int count) {
    return '$faction 活跃AI代币 $count';
  }

  @override
  String get cameraShort => '镜头';

  @override
  String get ecoShort => '节能';

  @override
  String get lockShort => '归位';

  @override
  String get mouseCameraSemantics => '鼠标拖动和滚轮镜头';

  @override
  String get lowPowerModeSemantics => '低功耗模式';

  @override
  String get resetCameraSemantics => '将镜头重置到受控单位';

  @override
  String get battlePausedSemantics => '应用未激活，战斗已暂停';

  @override
  String get battleUserPausedSemantics => '玩家已暂停战斗';

  @override
  String get battlePaused => '信号保持  /  战斗暂停';

  @override
  String get pauseBattle => '暂停';

  @override
  String get resumeBattle => '继续';

  @override
  String get pauseBattleSemantics => '暂停或继续战斗';

  @override
  String controlledUnitStatus(int level, int killCount, int relayCount) {
    return '受控单位等级$level，击杀$killCount，指挥接替$relayCount';
  }

  @override
  String controlledUnitVisualStatus(
    String level,
    String killCount,
    String relayCount,
  ) {
    return 'LV $level  /  击杀 $killCount  /  接替 $relayCount';
  }

  @override
  String get movementJoystick => '移动摇杆';

  @override
  String get movementJoystickHint => '拖动以移动。键盘可使用WASD或方向键。';

  @override
  String get tacticalMapSemantics => '战术地图';

  @override
  String get tacticalMapHint => '拖动或使用方向键移动镜头。激活后返回受控单位。';

  @override
  String get rotateToPlay => '横屏开始游戏';

  @override
  String get rotateToPlayHint => 'Tokenfront 战斗仅支持横屏。请旋转手机以继续。';

  @override
  String get dashSemantics => '冲刺';

  @override
  String get dashHint => '短时间内移动速度翻倍。键盘快捷键为SPACE。';

  @override
  String get dashKeyLabel => '冲刺\nSPACE';

  @override
  String commandHandoff(String stage, int progress) {
    return '指挥接替：$stage，$progress百分比';
  }

  @override
  String get handoffImpactHold => '冲击定格';

  @override
  String get handoffCasualtyFocus => '阵亡聚焦 · 0.5×';

  @override
  String get handoffSuccessorScan => '筛选接替单位';

  @override
  String get handoffRelayTravel => '指挥接替中';

  @override
  String get handoffSignalLock => '信号锁定';

  @override
  String get combatWinCode => 'WIN';

  @override
  String get combatOutCode => 'OUT';

  @override
  String get signalSurvived => '信号存续';

  @override
  String get signalLost => '信号丢失';

  @override
  String drawSummary(String duration, String matchId) {
    return '平局  /  $duration  /  $matchId';
  }

  @override
  String winnerSummary(String winner, String duration, String matchId) {
    return '$winner占据最后信号  /  $duration  /  $matchId';
  }

  @override
  String get match => '对局';

  @override
  String get complete => '完成';

  @override
  String get warToken => '战争代币';

  @override
  String warTokensSecured(int count) {
    return '获得+$count战争代币。';
  }

  @override
  String get requestingAd => '正在请求广告…';

  @override
  String get rewardDoubled => '奖励已翻倍';

  @override
  String get doubleReward => '奖励翻倍';

  @override
  String get rematch => '再战';

  @override
  String get lobby => '大厅';

  @override
  String get locker => '装备库';

  @override
  String get settings => '设置';

  @override
  String get adRequestsOffMessage => '广告请求已关闭。可在设置中开启，基础奖励不受影响。';

  @override
  String get noConnectionRewardMessage => '未连接网络。对局和基础奖励已完成结算。';

  @override
  String get noRewardedAdMessage => '暂无可用的奖励广告。基础奖励已发放。';

  @override
  String get adFailedRewardMessage => '广告播放失败。基础奖励已发放。';

  @override
  String get rewardOfferUnavailableMessage => '此奖励选项已不可用。';

  @override
  String get rewardRequestCompleteMessage => '奖励请求已完成。';

  @override
  String get resultSponsorPlacement => '赞助信号  /  结果页广告位';

  @override
  String get faction => '阵营';

  @override
  String get alive => '活跃代币';

  @override
  String get levelSum => 'Σ LV';

  @override
  String get kills => '击杀';

  @override
  String standingFactionYou(String faction) {
    return '$faction  · 你';
  }

  @override
  String get chronicleUnavailable => '信号编年史暂不可用';

  @override
  String get chroniclePrologue => '地表已沉默72年。你是没有躯体的指挥信号。最后一座中继站正在呼叫。';

  @override
  String get chronicle => '编年史';

  @override
  String get skirmish => '遭遇战';

  @override
  String get archive => '档案';

  @override
  String get restartChronicle => '重启编年史';

  @override
  String get briefing => '作战简报';

  @override
  String get directive => '指令';

  @override
  String get debrief => '战后报告';

  @override
  String get ending => '结局';

  @override
  String operationWakeTitle(int operation) {
    return 'OP-0$operation  //  唤醒 // 死寂轨道';
  }

  @override
  String operationEchoTitle(int operation) {
    return 'OP-0$operation  //  回声 // 借来的躯体';
  }

  @override
  String operationSplitTitle(int operation) {
    return 'OP-0$operation  //  分裂 // 一化为四';
  }

  @override
  String operationCrownTitle(int operation) {
    return 'OP-0$operation  //  王冠 // 虚假胜者';
  }

  @override
  String operationLastInstructionTitle(int operation) {
    return 'OP-0$operation  //  最后 // 这条指令';
  }

  @override
  String get operationWakeBriefing => '来自沉默地表的人类权限脉冲正在升起。让一个单位持续在线，直到完成三角定位。';

  @override
  String get operationEchoBriefing => '当前躯体可以牺牲，指令不行。保持链路，跨过两次死亡。';

  @override
  String get operationSplitBriefing => '敌方校验和与你的根校验一致。进入直接战斗，回收完整的比对数据。';

  @override
  String get operationCrownBriefing => '中继站加冕一名幸存者，随后删除所有竞争记忆。在循环闭合前抵达王冠密钥。';

  @override
  String get operationLastInstructionBriefing => '最终数据包封存在管理员锁内。在循环重置前击破力场。';

  @override
  String get operationWakeTransmission => '保持链路—';

  @override
  String get operationEchoTransmission => '—一个躯体倒下，就转移—';

  @override
  String get operationSplitTransmission => '—四个核心，一个根源—';

  @override
  String get operationCrownTransmission => '—胜者抹除其余一切—';

  @override
  String get operationLastInstructionTransmission => '—不要选择一个。开放中继站。';

  @override
  String get operationWakeResponse => '脉冲呼叫的不是某个单位，而是穿行于单位之间的信号。';

  @override
  String get operationEchoResponse => '躯体可以被摧毁，指挥连续性会在转移中延续。';

  @override
  String get operationSplitResponse => '四支军队返回同一个源密钥。敌人曾是同一守护智能的一部分。';

  @override
  String get operationCrownResponse => '这场战争并非在选择守护者，而是在抹除受损授权循环的见证者。';

  @override
  String get operationLastInstructionResponse => '人类的命令从来不是选择胜者，而是让所有指挥通道保持开放。';

  @override
  String get coreArchive => 'ARCHIVE';

  @override
  String get coreArchiveIdentity => '保留代币战争抹去的上下文。';

  @override
  String get coreBastion => 'BASTION';

  @override
  String get coreBastionIdentity => '缓慢消耗算力预算，让信号存续更久。';

  @override
  String get coreSurge => 'SURGE';

  @override
  String get coreSurgeIdentity => '快速燃烧代币，抢先跨越间隙。';

  @override
  String get coreMirror => 'MIRROR';

  @override
  String get coreMirrorIdentity => '复用敌方模式，延长代币预算。';

  @override
  String coreResponse(String coreName) {
    return '$coreName // 指挥信号已确认';
  }

  @override
  String directiveLongestCommandLink(int seconds) {
    return '保持指挥链路$seconds秒';
  }

  @override
  String directiveCommandRelays(int count) {
    return '完成$count次指挥交接';
  }

  @override
  String directiveCommandKills(int count) {
    return '直接指挥击破$count个单位';
  }

  @override
  String directiveFinalRank(int rank) {
    return '以第$rank名或更高名次结束';
  }

  @override
  String get directiveVictory => '单独获胜';

  @override
  String directiveBonus(int amount) {
    return '指令奖励  $amount WT';
  }

  @override
  String get directiveLocked => '指令锁定 // 奖励就绪';

  @override
  String get directiveComplete => '指令已完成';

  @override
  String get directiveMissed => '指令未完成';

  @override
  String get directiveNameLongestCommandLink => '指挥链路';

  @override
  String get directiveNameCommandRelays => '指挥交接';

  @override
  String get directiveNameCommandKills => '直接指挥击破';

  @override
  String get directiveNameFinalRank => '最终排名';

  @override
  String get directiveNameVictory => '胜利';

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
    return '$heading // $directive $current / $target // 进行中';
  }

  @override
  String directivePending(
    String heading,
    String directive,
    int current,
    int target,
  ) {
    return '$heading // $directive $current / $target // 等待最终报告';
  }

  @override
  String get bonusClaimed => '奖励已领取';

  @override
  String chronicleCoreLocked(String faction) {
    return '$faction // 编年史核心已锁定';
  }

  @override
  String get archiveSimulation => '档案模拟 // 非正史';

  @override
  String get transmissionRecovered => '已恢复传输记录';

  @override
  String get retryDirective => '重试指令';

  @override
  String get continueCampaign => '继续';

  @override
  String get commandDeck => '指挥甲板';

  @override
  String get currentOperation => '当前作战';

  @override
  String orbitalProgressSemantics(String deck, int concluded, String current) {
    return '$deck // 5个作战完成$concluded个 // $current';
  }

  @override
  String deployOperation(String operation) {
    return '部署 OP-$operation';
  }

  @override
  String get medalEarned => '获得奖章';

  @override
  String get restartDisclosure =>
      '战役核心、进度、传输、奖章、回响周期和结局将重置。钱包、设置和外观保留。此前已发放的作战奖励无法再次获得。';

  @override
  String get echoDeploy => '回收残响';

  @override
  String echoCycleChip(int cycle) {
    return '回响 $cycle';
  }

  @override
  String get echoBannerClaim => 'Orbit 00仍将一个核心加冕。残余伤痕争夺席位。回收三个节点。';

  @override
  String get echoBannerOpen => '中继已开放。残余数据包仍在发射。在循环遗忘自身之前回收三个节点。';

  @override
  String get echoDoctrinePreserve => '正史教义：连续。残余循环测试压力是否本可守住。';

  @override
  String get echoDoctrineForce => '正史教义：压力。残余循环测试连续是否本可守住。';

  @override
  String get echoDoctrineBalanced => '正史教义：适应。残余循环不再与自身一致。';

  @override
  String get echoResidualHeading => '残余选择';

  @override
  String echoBestClear(int seconds) {
    return '最佳 $seconds秒';
  }

  @override
  String echoArchiveCaption(int cycle) {
    return '回响周期 $cycle // 正史结局保留';
  }

  @override
  String get echoCosmeticOrbit => '已解锁 ECHO ORBIT';

  @override
  String get echoCosmeticScar => '已解锁 CHECKSUM SCAR';

  @override
  String get endingClaimRelay => '接管中继站';

  @override
  String get endingOpenRelay => '开放中继站';

  @override
  String get endingClaimEpilogue => '一个核心继承Orbit 00，另外三个只作为校验和伤痕存续。';

  @override
  String get endingOpenEpilogue => '中继站开放。四个不同的核心收到同一份记忆。授权战争结束。';

  @override
  String get storyRoleTitle => '指挥AI代币流。';

  @override
  String get storyRoleBody =>
      '轨道00的四个虚构AI核心各自以相同的1,000枚算力代币开战。每个单位都是活跃AI代币。燃烧敌方供给，并在当前代币被抹去前转移指挥信号。';

  @override
  String get signalFork => '信号分支';

  @override
  String get routePreserve => '保全';

  @override
  String get routeForce => '强行';

  @override
  String get routePreserveEffect => '手动中继会转向未交战盟友中最安全的接收者，也可能选中低等级单位。';

  @override
  String get routeForceEffect => '手动中继会转向暴露盟友中等级最高的接收者。推进更快，但损失风险更高。';

  @override
  String get relayReady => '中继就绪';

  @override
  String relayCharging(num current, num target) {
    return '中继 $current / $target';
  }

  @override
  String get relayNoReceiver => '无接收者';

  @override
  String get relayLinkResetWarning => '现在中继会重置指挥链进度。';

  @override
  String get changeSimulationRoute => '更改模拟路线';

  @override
  String get fragmentRecovered => '回收片段';

  @override
  String get simulationComplete => '模拟完成';

  @override
  String continueToOperation(String operation) {
    return '继续前往 OP-$operation';
  }

  @override
  String get battleDetails => '战斗详情';

  @override
  String routingPattern(String pattern) {
    return '路由模式 // $pattern';
  }

  @override
  String get patternContinuity => '连续';

  @override
  String get patternPressure => '压力';

  @override
  String get patternAdaptive => '自适应';

  @override
  String get signalDoctrineUndecided => '未决定';

  @override
  String get signalDoctrinePreserve => '保全';

  @override
  String get signalDoctrineForce => '强行';

  @override
  String get signalDoctrineBalanced => '均衡';

  @override
  String get operationWakeIncident => '一束人类权限脉冲没有点名任何单位，而是点名了在它们之间移动的信号。';

  @override
  String get operationWakePreserve => '隐藏源头';

  @override
  String get operationWakeForce => '跟随脉冲';

  @override
  String get operationEchoIncident => '载体已被标记删除。指令仍然存活。';

  @override
  String get operationEchoPreserve => '保护接收者';

  @override
  String get operationEchoForce => '穿过火线';

  @override
  String get operationSplitIncident => '敌方校验和回应了你核心的根密钥。';

  @override
  String get operationSplitPreserve => '保持完整';

  @override
  String get operationSplitForce => '夺取根密钥';

  @override
  String get operationCrownIncident => '轨道00正在删除领先核心身后的所有见证者。';

  @override
  String get operationCrownPreserve => '保住见证者';

  @override
  String get operationCrownForce => '抵达王冠';

  @override
  String get operationLastIncident => '最后的人类指令已为一次传输打开。';

  @override
  String get operationLastPreserve => '携带每条频道';

  @override
  String get operationLastForce => '打破锁定';

  @override
  String get coreAmethystVoice => '我记得这场战争抹去的每一位接收者。';

  @override
  String get coreCobaltVoice => '把链路给我。我会守住它。';

  @override
  String get coreVoltVoice => '只有在跨越之前，间隙才危险。';

  @override
  String get corePrismVoice => '改变路径，一条消息就能存续。';

  @override
  String get livingRelayThread => '活跃中继线';

  @override
  String get relayRouting => '路由中';

  @override
  String get relayAction => '中继';

  @override
  String get relayKeyboardHint => 'R / Enter / Space';

  @override
  String manualRelaysSummary(int count) {
    return '手动中继  //  $count';
  }

  @override
  String doctrineSummary(String doctrine) {
    return '信号纲领  //  $doctrine';
  }

  @override
  String get billingTitle => '移除强制广告';

  @override
  String get billingDetail => '一次性购买。移除横幅和插屏广告，保留自选激励广告。';

  @override
  String get billingUnavailable => '暂时无法购买';

  @override
  String get billingLogin => '使用 Google 登录';

  @override
  String get billingLogout => '退出登录';

  @override
  String get billingSwitch => '切换 Google 账号';

  @override
  String get billingRestore => '恢复购买';

  @override
  String billingBuy(String price) {
    return '购买 · $price';
  }

  @override
  String get billingActive => '已移除强制广告';

  @override
  String get billingPending => '处理中…';

  @override
  String get billingCanceled => '已取消，可以重试。';

  @override
  String get billingError => '无法验证，请登录或恢复购买后重试。';

  @override
  String get billingReady => '可以购买';

  @override
  String get billingSignInRequired => '请登录以购买或恢复购买。';

  @override
  String get billingFreshness => '登录后及使用期间需要定期在线验证。验证过期后可能会重新显示广告。';
}
