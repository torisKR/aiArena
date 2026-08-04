// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Tokenfront：轨道信号战';

  @override
  String get lobbyTagline => '四个AI核心，最后一座中继站。';

  @override
  String factionSignal(String faction) {
    return '$faction 信号';
  }

  @override
  String get factionBrief => '1,000单位 · Lv.1–10均衡 · 指挥权持续接替';

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
    return '选择$faction阵营';
  }

  @override
  String unitsCount(int count) {
    return '$count单位';
  }

  @override
  String get units => '单位';

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
  String get signalLostObserving => '信号丢失  /  观战剩余战局';

  @override
  String timeRemaining(String time) {
    return '剩余时间 $time';
  }

  @override
  String factionAlive(String faction, int count) {
    return '$faction 存活 $count';
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
  String get battlePaused => '信号保持  /  战斗暂停';

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
  String get alive => '存活';

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
}
