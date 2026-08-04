// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Tokenfront: 軌道信号戦';

  @override
  String get lobbyTagline => '4つのAIコア。最後のリレーは1つ。';

  @override
  String factionSignal(String faction) {
    return '$faction シグナル';
  }

  @override
  String get factionBrief => '1,000ユニット · Lv.1–10均衡 · 指揮権を連続維持';

  @override
  String get deploySignal => '軌道へ展開';

  @override
  String lockerBalance(int balance) {
    return 'ロッカー  $balance WT';
  }

  @override
  String get tune => '調整';

  @override
  String get signalSettings => 'シグナル設定';

  @override
  String get offline => 'オフライン';

  @override
  String chooseFaction(String faction) {
    return '$faction陣営を選択';
  }

  @override
  String unitsCount(int count) {
    return '$countユニット';
  }

  @override
  String get units => 'ユニット';

  @override
  String get highLevel => '高Lv';

  @override
  String get wins => '勝利';

  @override
  String get equalLevel => '同Lv';

  @override
  String get death => '撃破';

  @override
  String get relays => '指揮継承';

  @override
  String get move => '移動';

  @override
  String get stickWasd => 'スティック / WASD';

  @override
  String get dash => 'ダッシュ';

  @override
  String get buttonSpace => 'ボタン / SPACE';

  @override
  String get sponsorBannerArea => 'スポンサーバナー領域';

  @override
  String get sponsorSignal => 'スポンサーシグナル';

  @override
  String get lobbyPlacement => 'ロビー配置';

  @override
  String get languageSection => '言語';

  @override
  String get displayLanguage => '表示言語';

  @override
  String get displayLanguageDetail => '端末の言語に従うか、このゲームで使う言語を選択します。';

  @override
  String get languageSystem => 'システム設定';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get settingsTitle => 'シグナル調整';

  @override
  String get settingsSubtitle => '戦闘力を変えずに戦場を調整。';

  @override
  String get closeSettings => '設定を閉じる';

  @override
  String get battlefieldSection => '戦場';

  @override
  String get lowSpecFilter => '軽量フィルター';

  @override
  String get lowSpecFilterDetail => 'パーティクルと高負荷な戦場表現を削減。';

  @override
  String get reduceMotion => '動きを抑える';

  @override
  String get reduceMotionDetail => '指揮継承時のカメラ移動と大きな画面遷移を短縮。';

  @override
  String get mouseCamera => 'マウス視点';

  @override
  String get mouseCameraDetail => 'Webでホイールズームとドラッグ移動を有効化。';

  @override
  String get audioCues => '音声キュー';

  @override
  String get audioCuesDetail => 'ダッシュ、戦闘、指揮継承の信号音を再生。';

  @override
  String get hapticCues => '触覚キュー';

  @override
  String get hapticCuesDetail => '対応端末でダッシュと指揮継承を振動で通知。';

  @override
  String get privacySection => 'プライバシー';

  @override
  String get shareAnalytics => '分析データ共有';

  @override
  String get shareAnalyticsDetail => 'オンライン時に匿名のマッチイベントをまとめて送信。';

  @override
  String get adRequests => '広告リクエスト';

  @override
  String get adRequestsDetail => 'ロビーと結果画面の広告を許可。追跡には別途プラットフォーム権限が必要です。';

  @override
  String get privacyDefaultNote =>
      '両方とも初期設定はオフです。どちらをオフにしても、オフラインマッチと報酬は利用できます。';

  @override
  String get privacyPolicyTitle => 'プライバシーポリシー';

  @override
  String get privacyPolicyEffectiveDate => '施行日: 2026-08-05';

  @override
  String get privacyPolicyIntro =>
      'Tokenfront: Orbital Signal Warはオフラインのシングルプレイゲームです。このリリースはユーザーデータを端末外へ収集または共有しません。';

  @override
  String get privacyDataStoredTitle => '端末に保存されるデータ';

  @override
  String get privacyDataStoredBody =>
      'War Token残高、コスメの解除・装備、言語、アクセシビリティ、音声、カメラ、触覚・プライバシー設定、Signal Chronicleの進行状況をアプリ専用のローカル領域に保存します。アップロードはせず、アプリデータの消去またはアンインストールで削除されます。';

  @override
  String get privacyAnalyticsTitle => '分析';

  @override
  String get privacyAnalyticsBody =>
      'ゲームプレイと性能イベントは最大500件の一時メモリバッファに存在する場合があります。このリリースは分析送信機能を使用せず、イベントを送信せず、プロセス終了時にバッファを破棄します。';

  @override
  String get privacyAdvertisingTitle => '広告';

  @override
  String get privacyAdvertisingBody =>
      'このリリースには広告SDK、実広告リクエスト、インプレッション、リワード広告のネットワーク呼び出し、広告識別子へのアクセスがありません。';

  @override
  String get privacyAccountsTitle => 'アカウント、権限、第三者';

  @override
  String get privacyAccountsBody =>
      'アカウント、ログイン、クラウド同期、購入システム、ユーザー投稿、ソーシャル機能はありません。位置情報、カメラ、マイク、連絡先、写真、ファイル、カレンダー、健康、金融、メッセージ権限を要求しません。';

  @override
  String get privacyHostingTitle => '公開ポリシーのホスティング';

  @override
  String get privacyHostingBody =>
      '公開版はCloudflare Pagesでホストされます。外部ブラウザで開くと、Cloudflareが自社の条件に基づき通常のWebリクエストデータを処理する場合があります。Androidアプリは公開ページを埋め込まず、ゲームプレイやローカル状態を送信しません。';

  @override
  String get privacyChildrenTitle => '子ども';

  @override
  String get privacyChildrenBody =>
      'Tokenfrontは13歳以上を対象とし、13歳未満の子ども向けではありません。このリリースは個人情報を収集しません。';

  @override
  String get privacyChangesTitle => '変更';

  @override
  String get privacyChangesBody =>
      '将来のリリースに分析送信、広告、アカウント、クラウドサービス、その他の端末外データフローを追加する前に、本ポリシーとGoogle Playのデータセーフティ申告を更新します。';

  @override
  String get privacyContactTitle => '連絡先';

  @override
  String get privacyPublicUrlLabel => '公開ポリシーURL';

  @override
  String get privacyOpenPublicPage => '公開ページを開く';

  @override
  String get privacyCopyUrl => 'URLをコピー';

  @override
  String get privacyUrlCopied => 'プライバシーポリシーのURLをコピーしました。';

  @override
  String get privacyOpenFailed => '公開ポリシーページを開けませんでした。全文はこの画面で引き続き確認できます。';

  @override
  String get releaseServicesUnavailable => 'このリリースでは利用できません';

  @override
  String get closePanel => 'パネルを閉じる';

  @override
  String get stateOff => 'オフ';

  @override
  String get stateOn => 'オン';

  @override
  String get semanticsOff => 'オフ';

  @override
  String get semanticsOn => 'オン';

  @override
  String needMoreWarTokens(int count) {
    return 'ウォートークンがあと$count必要です。';
  }

  @override
  String get signalLocker => 'シグナルロッカー';

  @override
  String get lockerSubtitle => 'ウォートークンは戦場外観にのみ使用。戦闘力は変化しません。';

  @override
  String warTokenBalance(int balance) {
    return 'ウォートークン $balance';
  }

  @override
  String get closeSignalLocker => 'シグナルロッカーを閉じる';

  @override
  String get equipped => '装備中';

  @override
  String get equip => '装備';

  @override
  String unlockCost(int cost) {
    return 'アンロック  $cost';
  }

  @override
  String get commandEdge => '指揮輪郭';

  @override
  String get movementTrace => '移動軌跡';

  @override
  String get defeatMark => '撃破エフェクト';

  @override
  String get cosmeticFieldIssueName => '標準支給';

  @override
  String get cosmeticFieldIssueDescription => '陣営シグナルの標準カラー。';

  @override
  String get cosmeticRelayIvoryName => 'リレーアイボリー';

  @override
  String get cosmeticRelayIvoryDescription => '陣営の中心を見やすく保つアイボリーの指揮輪郭。';

  @override
  String get cosmeticOxideEdgeName => 'オキサイドエッジ';

  @override
  String get cosmeticOxideEdgeDescription => '操作ユニットに暖色の戦術輪郭を追加。';

  @override
  String get cosmeticCleanWakeName => 'クリーンウェイク';

  @override
  String get cosmeticCleanWakeDescription => '移動軌跡を残しません。';

  @override
  String get cosmeticRelayTapeName => 'リレーテープ';

  @override
  String get cosmeticRelayTapeDescription => '短く分割された指揮軌跡。';

  @override
  String get cosmeticCinderGridName => 'シンダーグリッド';

  @override
  String get cosmeticCinderGridDescription => '高速移動時にまばらなオキサイド軌跡を表示。';

  @override
  String get cosmeticSignalRingName => 'シグナルリング';

  @override
  String get cosmeticSignalRingDescription => '標準の小さな撃破パルス。';

  @override
  String get cosmeticFractureName => '四方向フラクチャー';

  @override
  String get cosmeticFractureDescription => 'ゲームプレイに影響しない鮮明な幾何学破砕。';

  @override
  String get signalLostObserving => 'シグナル喪失  /  残存戦を観戦';

  @override
  String timeRemaining(String time) {
    return '残り時間 $time';
  }

  @override
  String factionAlive(String faction, int count) {
    return '$faction 生存 $count';
  }

  @override
  String get cameraShort => '視点';

  @override
  String get ecoShort => '省電';

  @override
  String get lockShort => '復帰';

  @override
  String get mouseCameraSemantics => 'マウスドラッグとホイールによるカメラ操作';

  @override
  String get lowPowerModeSemantics => '省電力モード';

  @override
  String get resetCameraSemantics => '操作ユニットにカメラを戻す';

  @override
  String get battlePausedSemantics => 'アプリが非アクティブなため戦闘を一時停止';

  @override
  String get battleUserPausedSemantics => 'プレイヤーが戦闘を一時停止';

  @override
  String get battlePaused => 'シグナル待機  /  戦闘一時停止';

  @override
  String get pauseBattle => '一時停止';

  @override
  String get resumeBattle => '再開';

  @override
  String get pauseBattleSemantics => 'バトルを一時停止または再開';

  @override
  String controlledUnitStatus(int level, int killCount, int relayCount) {
    return '操作ユニット レベル$level、撃破$killCount、指揮継承$relayCount';
  }

  @override
  String controlledUnitVisualStatus(
    String level,
    String killCount,
    String relayCount,
  ) {
    return 'LV $level  /  撃破 $killCount  /  継承 $relayCount';
  }

  @override
  String get movementJoystick => '移動スティック';

  @override
  String get movementJoystickHint => 'ドラッグで移動。キーボードはWASDまたは矢印キーを使用できます。';

  @override
  String get tacticalMapSemantics => '戦術マップ';

  @override
  String get tacticalMapHint => 'ドラッグまたは矢印キーでカメラを移動します。実行すると操作ユニットに戻ります。';

  @override
  String get rotateToPlay => '横向きでプレイ';

  @override
  String get rotateToPlayHint =>
      'Tokenfrontの戦闘は横向きで進行します。続けるにはスマートフォンを回転してください。';

  @override
  String get dashSemantics => 'ダッシュ';

  @override
  String get dashHint => '短時間、移動速度が2倍。キーボードショートカットはSPACEです。';

  @override
  String get dashKeyLabel => 'ダッシュ\nSPACE';

  @override
  String commandHandoff(String stage, int progress) {
    return '指揮継承：$stage、$progressパーセント';
  }

  @override
  String get handoffImpactHold => '衝撃停止';

  @override
  String get handoffCasualtyFocus => '撃破対象フォーカス · 0.5×';

  @override
  String get handoffSuccessorScan => '後継ユニット選定';

  @override
  String get handoffRelayTravel => '指揮継承中';

  @override
  String get handoffSignalLock => 'シグナル固定';

  @override
  String get combatWinCode => 'WIN';

  @override
  String get combatOutCode => 'OUT';

  @override
  String get signalSurvived => 'シグナル生存';

  @override
  String get signalLost => 'シグナル喪失';

  @override
  String drawSummary(String duration, String matchId) {
    return '引き分け  /  $duration  /  $matchId';
  }

  @override
  String winnerSummary(String winner, String duration, String matchId) {
    return '$winner、最後のシグナルを確保  /  $duration  /  $matchId';
  }

  @override
  String get match => 'マッチ';

  @override
  String get complete => '完了';

  @override
  String get warToken => 'ウォートークン';

  @override
  String warTokensSecured(int count) {
    return 'ウォートークンを+$count確保。';
  }

  @override
  String get requestingAd => '広告をリクエスト中…';

  @override
  String get rewardDoubled => '報酬2倍';

  @override
  String get doubleReward => '報酬を2倍に';

  @override
  String get rematch => '再戦';

  @override
  String get lobby => 'ロビー';

  @override
  String get locker => 'ロッカー';

  @override
  String get settings => '設定';

  @override
  String get adRequestsOffMessage => '広告リクエストはオフです。設定で有効にできます。基本報酬は保持されます。';

  @override
  String get noConnectionRewardMessage => '接続がありません。マッチと基本報酬は完了済みです。';

  @override
  String get noRewardedAdMessage => '利用できるリワード広告がありません。基本報酬は付与済みです。';

  @override
  String get adFailedRewardMessage => '広告に失敗しました。基本報酬は付与済みです。';

  @override
  String get rewardOfferUnavailableMessage => 'この報酬オファーは利用できません。';

  @override
  String get rewardRequestCompleteMessage => '報酬リクエストが完了しました。';

  @override
  String get resultSponsorPlacement => 'スポンサーシグナル  /  結果画面配置';

  @override
  String get faction => '陣営';

  @override
  String get alive => '生存';

  @override
  String get levelSum => 'Σ LV';

  @override
  String get kills => '撃破';

  @override
  String standingFactionYou(String faction) {
    return '$faction  · 自分';
  }

  @override
  String get chronicleUnavailable => 'シグナル・クロニクル利用不可';

  @override
  String get chroniclePrologue =>
      '地表は72年間、沈黙している。あなたは肉体を持たない指揮信号だ。最後のリレーが呼びかけている。';

  @override
  String get chronicle => 'クロニクル';

  @override
  String get skirmish => 'スカーミッシュ';

  @override
  String get archive => 'アーカイブ';

  @override
  String get restartChronicle => 'クロニクルをリセット';

  @override
  String get briefing => '作戦ブリーフィング';

  @override
  String get directive => '指令';

  @override
  String get debrief => '作戦報告';

  @override
  String get ending => 'エンディング';

  @override
  String operationWakeTitle(int operation) {
    return 'OP-0$operation  //  覚醒 // 死んだ軌道';
  }

  @override
  String operationEchoTitle(int operation) {
    return 'OP-0$operation  //  反響 // 借り物の身体';
  }

  @override
  String operationSplitTitle(int operation) {
    return 'OP-0$operation  //  分裂 // 一つから四つへ';
  }

  @override
  String operationCrownTitle(int operation) {
    return 'OP-0$operation  //  王冠 // 偽りの勝者';
  }

  @override
  String operationLastInstructionTitle(int operation) {
    return 'OP-0$operation  //  最後 // その指示';
  }

  @override
  String get operationWakeBriefing =>
      '沈黙した地表から人間の権限を持つパルスが立ち上がる。三角測量できるまで、ひとつのボディを稼働させ続けろ。';

  @override
  String get operationEchoBriefing => '現在のボディは消耗品だ。指令は違う。リンクを失わず、二度の死を越えろ。';

  @override
  String get operationSplitBriefing =>
      '敵のチェックサムは君のルートと一致する。直接戦闘に入り、完全な照合データを回収せよ。';

  @override
  String get operationCrownBriefing =>
      'リレーは生存者ひとつを王冠に据え、競合する記憶をすべて消去する。サイクルが閉じる前に王冠キーへ到達せよ。';

  @override
  String get operationLastInstructionBriefing =>
      '最後のパケットは管理者ロックに封印されている。ループがリセットされる前にフィールドを破れ。';

  @override
  String get operationWakeTransmission => 'リンクを維持せよ—';

  @override
  String get operationEchoTransmission => '—ひとつのボディが倒れたら、移れ—';

  @override
  String get operationSplitTransmission => '—4つのコア、ひとつのルート—';

  @override
  String get operationCrownTransmission => '—勝者は残りを消去する—';

  @override
  String get operationLastInstructionTransmission => '—ひとつを選ぶな。リレーを開け。';

  @override
  String get operationWakeResponse => 'パルスが呼びかけたのはユニットではない。その間を移動する信号だった。';

  @override
  String get operationEchoResponse => 'ボディは破壊される。指揮の連続性は移行によって生き残る。';

  @override
  String get operationSplitResponse => '4つの軍勢がひとつの起源キーを返す。敵はかつて同じ守護知性の一部だった。';

  @override
  String get operationCrownResponse => 'この戦争は守護者を選んでいない。損傷した認証ループの証人を消している。';

  @override
  String get operationLastInstructionResponse =>
      '人間の命令は勝者を選ぶことではなかった。すべての指揮チャンネルを開いたままにすることだった。';

  @override
  String get coreArchive => 'ARCHIVE';

  @override
  String get coreArchiveIdentity => '戦争が消すものを記憶する。';

  @override
  String get coreBastion => 'BASTION';

  @override
  String get coreBastionIdentity => '信号がボディを越えて存続するよう耐える。';

  @override
  String get coreSurge => 'SURGE';

  @override
  String get coreSurgeIdentity => '沈黙が閉じる前に隔たりを越える。';

  @override
  String get coreMirror => 'MIRROR';

  @override
  String get coreMirrorIdentity => 'メッセージを守るためパターンを変える。';

  @override
  String coreResponse(String coreName) {
    return '$coreName // 指揮信号を確認';
  }

  @override
  String directiveLongestCommandLink(int seconds) {
    return '指揮リンクを$seconds秒維持';
  }

  @override
  String directiveCommandRelays(int count) {
    return '指揮引き継ぎを$count回完了';
  }

  @override
  String directiveCommandKills(int count) {
    return '直接指揮で$count体撃破';
  }

  @override
  String directiveFinalRank(int rank) {
    return '$rank位以内で終了';
  }

  @override
  String get directiveVictory => '単独勝利';

  @override
  String directiveBonus(int amount) {
    return '指令ボーナス  $amount WT';
  }

  @override
  String get directiveLocked => '指令ロック // ボーナス準備完了';

  @override
  String get directiveComplete => '指令完了';

  @override
  String get directiveMissed => '指令未達';

  @override
  String get directiveNameLongestCommandLink => '指揮リンク';

  @override
  String get directiveNameCommandRelays => '指揮引き継ぎ';

  @override
  String get directiveNameCommandKills => '直接指揮撃破';

  @override
  String get directiveNameFinalRank => '最終順位';

  @override
  String get directiveNameVictory => '勝利';

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
    return '$heading // $directive $current / $target // 進行中';
  }

  @override
  String directivePending(
    String heading,
    String directive,
    int current,
    int target,
  ) {
    return '$heading // $directive $current / $target // 最終報告待ち';
  }

  @override
  String get bonusClaimed => 'ボーナス取得済み';

  @override
  String chronicleCoreLocked(String faction) {
    return '$faction // クロニクルコア固定済み';
  }

  @override
  String get archiveSimulation => 'アーカイブ・シミュレーション // 非正史';

  @override
  String get transmissionRecovered => '伝送記録を回収';

  @override
  String get retryDirective => '指令を再試行';

  @override
  String get continueCampaign => '続行';

  @override
  String get commandDeck => 'コマンドデッキ';

  @override
  String get currentOperation => '現在の作戦';

  @override
  String orbitalProgressSemantics(String deck, int concluded, String current) {
    return '$deck // 5作戦中$concluded作戦完了 // $current';
  }

  @override
  String deployOperation(String operation) {
    return 'OP-$operation 展開';
  }

  @override
  String get medalEarned => 'メダル獲得';

  @override
  String get restartDisclosure =>
      'キャンペーンコア、進行、送信、メダル、エンディングをリセットします。ウォレット、設定、コスメは保持されます。以前に付与された作戦ボーナスは再獲得できません。';

  @override
  String get endingClaimRelay => 'リレーを掌握';

  @override
  String get endingOpenRelay => 'リレーを開放';

  @override
  String get endingClaimEpilogue =>
      'ひとつのコアがOrbit 00を継承する。他の3つはチェックサムの傷跡としてのみ残る。';

  @override
  String get endingOpenEpilogue => 'リレーが開く。4つの異なるコアが同じ記憶を受け取る。認証戦争は終わる。';
}
