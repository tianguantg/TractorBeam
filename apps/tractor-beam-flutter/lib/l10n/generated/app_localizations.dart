import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
/// import 'generated/app_localizations.dart';
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
    Locale('zh'),
  ];

  /// No description provided for @navHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get navHome;

  /// No description provided for @navRoom.
  ///
  /// In zh, this message translates to:
  /// **'房间'**
  String get navRoom;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @navStatistics.
  ///
  /// In zh, this message translates to:
  /// **'统计'**
  String get navStatistics;

  /// No description provided for @navLogs.
  ///
  /// In zh, this message translates to:
  /// **'日志'**
  String get navLogs;

  /// No description provided for @navAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get navAbout;

  /// No description provided for @switchToEnglish.
  ///
  /// In zh, this message translates to:
  /// **'切换到 English'**
  String get switchToEnglish;

  /// No description provided for @trayShowMonitor.
  ///
  /// In zh, this message translates to:
  /// **'显示悬浮窗'**
  String get trayShowMonitor;

  /// No description provided for @trayOpenFull.
  ///
  /// In zh, this message translates to:
  /// **'打开完整界面'**
  String get trayOpenFull;

  /// No description provided for @trayHide.
  ///
  /// In zh, this message translates to:
  /// **'隐藏窗口'**
  String get trayHide;

  /// No description provided for @trayExit.
  ///
  /// In zh, this message translates to:
  /// **'退出程序'**
  String get trayExit;

  /// No description provided for @genericError.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get genericError;

  /// No description provided for @busy.
  ///
  /// In zh, this message translates to:
  /// **'当前正忙，请稍后重试'**
  String get busy;

  /// No description provided for @roomRestoreRelayFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法恢复上一次的 Relay 房间，请检查节点和网络后重试。'**
  String get roomRestoreRelayFailed;

  /// No description provided for @roomRestoreLanFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法恢复上一次的局域网房间：原联机码中的端点当前不可达，请让房主重新发送联机码。'**
  String get roomRestoreLanFailed;

  /// No description provided for @roomRestoreRelayTimeout.
  ///
  /// In zh, this message translates to:
  /// **'恢复上一次的 Relay 房间超时，请检查网络后从历史记录重试。'**
  String get roomRestoreRelayTimeout;

  /// No description provided for @roomRestoreLanManualRequired.
  ///
  /// In zh, this message translates to:
  /// **'无法自动恢复上一次的局域网房间，请从历史记录中手动选择并加入。'**
  String get roomRestoreLanManualRequired;

  /// No description provided for @latencyComplete.
  ///
  /// In zh, this message translates to:
  /// **'延迟测试完成：{latency}ms'**
  String latencyComplete(int latency);

  /// No description provided for @latencyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法连接到当前 Relay 节点'**
  String get latencyUnavailable;

  /// No description provided for @latencyTimeout.
  ///
  /// In zh, this message translates to:
  /// **'延迟测试超时，无法连接到当前 Relay 节点'**
  String get latencyTimeout;

  /// No description provided for @startupFailed.
  ///
  /// In zh, this message translates to:
  /// **'应用初始化失败'**
  String get startupFailed;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @exit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exit;

  /// No description provided for @openFullInterface.
  ///
  /// In zh, this message translates to:
  /// **'打开完整界面'**
  String get openFullInterface;

  /// No description provided for @hideToTray.
  ///
  /// In zh, this message translates to:
  /// **'隐藏到托盘'**
  String get hideToTray;

  /// No description provided for @localPlayer.
  ///
  /// In zh, this message translates to:
  /// **'本机'**
  String get localPlayer;

  /// No description provided for @connected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get connected;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'—'**
  String get noData;

  /// No description provided for @homeNoticeTitle.
  ///
  /// In zh, this message translates to:
  /// **'联机游玩须知'**
  String get homeNoticeTitle;

  /// No description provided for @homeNoticeHelp.
  ///
  /// In zh, this message translates to:
  /// **'以撒联机基本操作指南与联机注意事项'**
  String get homeNoticeHelp;

  /// No description provided for @connectionMode.
  ///
  /// In zh, this message translates to:
  /// **'联机方式'**
  String get connectionMode;

  /// No description provided for @connectionModeHelp.
  ///
  /// In zh, this message translates to:
  /// **'可选择外部中继服务器（跨公网推荐）或局域网直连模式'**
  String get connectionModeHelp;

  /// No description provided for @hostInstruction.
  ///
  /// In zh, this message translates to:
  /// **'若你当房主，请先配置联机方式，然后创建自己的房间；'**
  String get hostInstruction;

  /// No description provided for @memberInstructionBefore.
  ///
  /// In zh, this message translates to:
  /// **'若你是成员，请复制房主的“联机码”，然后 '**
  String get memberInstructionBefore;

  /// No description provided for @memberInstructionAfter.
  ///
  /// In zh, this message translates to:
  /// **' 。'**
  String get memberInstructionAfter;

  /// No description provided for @joinRoom.
  ///
  /// In zh, this message translates to:
  /// **'加入房间'**
  String get joinRoom;

  /// No description provided for @launchInstructionBefore.
  ///
  /// In zh, this message translates to:
  /// **'进入房间后，点击位于右下角的 '**
  String get launchInstructionBefore;

  /// No description provided for @launchInstructionAfter.
  ///
  /// In zh, this message translates to:
  /// **' 按钮。'**
  String get launchInstructionAfter;

  /// No description provided for @launchGame.
  ///
  /// In zh, this message translates to:
  /// **'启动游戏'**
  String get launchGame;

  /// No description provided for @startMultiplayer.
  ///
  /// In zh, this message translates to:
  /// **'开始联机'**
  String get startMultiplayer;

  /// No description provided for @gameReady.
  ///
  /// In zh, this message translates to:
  /// **'游戏已就绪'**
  String get gameReady;

  /// No description provided for @gameReadyStandby.
  ///
  /// In zh, this message translates to:
  /// **'游戏就绪'**
  String get gameReadyStandby;

  /// No description provided for @gameReadyJoinRoomPrompt.
  ///
  /// In zh, this message translates to:
  /// **'游戏已就绪，请加入或创建房间开始联机'**
  String get gameReadyJoinRoomPrompt;

  /// No description provided for @dialogLeaveRoomInGameTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出联机房间'**
  String get dialogLeaveRoomInGameTitle;

  /// No description provided for @dialogLeaveRoomInGameWarning.
  ///
  /// In zh, this message translates to:
  /// **'当前游戏联机对局正在进行中！退出房间将立即中断对局并切断与其他玩家的连接，是否确认退出？'**
  String get dialogLeaveRoomInGameWarning;

  /// No description provided for @confirmLeave.
  ///
  /// In zh, this message translates to:
  /// **'确认退出'**
  String get confirmLeave;

  /// No description provided for @launchWarning.
  ///
  /// In zh, this message translates to:
  /// **'不要通过 Steam 客户端或其它方式直接启动游戏！'**
  String get launchWarning;

  /// No description provided for @externalRelay.
  ///
  /// In zh, this message translates to:
  /// **'外部 Relay 中继'**
  String get externalRelay;

  /// No description provided for @lanDirect.
  ///
  /// In zh, this message translates to:
  /// **'局域网直连'**
  String get lanDirect;

  /// No description provided for @lanSelectedHint.
  ///
  /// In zh, this message translates to:
  /// **'已选局域网联机，直接前往创建房间即可'**
  String get lanSelectedHint;

  /// No description provided for @relayConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'Relay 中继路由配置'**
  String get relayConfiguration;

  /// No description provided for @noRelayConfigured.
  ///
  /// In zh, this message translates to:
  /// **'当前未配置任何 Relay 节点'**
  String get noRelayConfigured;

  /// No description provided for @addRelayHint.
  ///
  /// In zh, this message translates to:
  /// **'请点击下方按钮添加自定义 Relay 节点。'**
  String get addRelayHint;

  /// No description provided for @addRelay.
  ///
  /// In zh, this message translates to:
  /// **'添加relay'**
  String get addRelay;

  /// No description provided for @editRelay.
  ///
  /// In zh, this message translates to:
  /// **'编辑relay'**
  String get editRelay;

  /// No description provided for @switchRelay.
  ///
  /// In zh, this message translates to:
  /// **'切换'**
  String get switchRelay;

  /// No description provided for @noOtherRelayToSwitch.
  ///
  /// In zh, this message translates to:
  /// **'暂无其他可用 Relay 节点'**
  String get noOtherRelayToSwitch;

  /// No description provided for @testLatency.
  ///
  /// In zh, this message translates to:
  /// **'测试延迟'**
  String get testLatency;

  /// No description provided for @selectRelayFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择 Relay 服务器'**
  String get selectRelayFirst;

  /// No description provided for @latencyTestUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法测试延迟'**
  String get latencyTestUnavailable;

  /// No description provided for @relayAddFailed.
  ///
  /// In zh, this message translates to:
  /// **'Relay 添加失败'**
  String get relayAddFailed;

  /// No description provided for @relayUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'Relay 更新失败'**
  String get relayUpdateFailed;

  /// No description provided for @relayDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'Relay 删除失败'**
  String get relayDeleteFailed;

  /// No description provided for @relayDeleted.
  ///
  /// In zh, this message translates to:
  /// **'节点已删除'**
  String get relayDeleted;

  /// No description provided for @blockSessionAndRoom.
  ///
  /// In zh, this message translates to:
  /// **'请先退出游戏并离开房间再{action}'**
  String blockSessionAndRoom(String action);

  /// No description provided for @blockSession.
  ///
  /// In zh, this message translates to:
  /// **'请先退出游戏再{action}'**
  String blockSession(String action);

  /// No description provided for @blockRoom.
  ///
  /// In zh, this message translates to:
  /// **'请先退出房间再{action}'**
  String blockRoom(String action);

  /// No description provided for @blockCurrentState.
  ///
  /// In zh, this message translates to:
  /// **'当前状态下不可{action}'**
  String blockCurrentState(String action);

  /// No description provided for @actionSwitchConnection.
  ///
  /// In zh, this message translates to:
  /// **'切换联机方式'**
  String get actionSwitchConnection;

  /// No description provided for @actionSwitchRelay.
  ///
  /// In zh, this message translates to:
  /// **'切换 Relay 节点'**
  String get actionSwitchRelay;

  /// No description provided for @actionAddRelay.
  ///
  /// In zh, this message translates to:
  /// **'添加 Relay 节点'**
  String get actionAddRelay;

  /// No description provided for @actionEditRelay.
  ///
  /// In zh, this message translates to:
  /// **'编辑 Relay 节点'**
  String get actionEditRelay;

  /// No description provided for @monitorWindow.
  ///
  /// In zh, this message translates to:
  /// **'悬浮窗'**
  String get monitorWindow;

  /// No description provided for @monitorWindowTooltip.
  ///
  /// In zh, this message translates to:
  /// **'切换到悬浮窗模式'**
  String get monitorWindowTooltip;

  /// No description provided for @running.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get running;

  /// No description provided for @idle.
  ///
  /// In zh, this message translates to:
  /// **'空闲'**
  String get idle;

  /// No description provided for @reconnectCount.
  ///
  /// In zh, this message translates to:
  /// **'重连 {count}'**
  String reconnectCount(int count);

  /// No description provided for @errorCount.
  ///
  /// In zh, this message translates to:
  /// **'错误 {count}'**
  String errorCount(String count);

  /// No description provided for @hookReady.
  ///
  /// In zh, this message translates to:
  /// **'Hook 已就绪'**
  String get hookReady;

  /// No description provided for @hookConnecting.
  ///
  /// In zh, this message translates to:
  /// **'Hook 连接中'**
  String get hookConnecting;

  /// No description provided for @noMembers.
  ///
  /// In zh, this message translates to:
  /// **'暂无队员信息'**
  String get noMembers;

  /// No description provided for @relayRoute.
  ///
  /// In zh, this message translates to:
  /// **'Relay'**
  String get relayRoute;

  /// No description provided for @relayConnectionRoute.
  ///
  /// In zh, this message translates to:
  /// **'Relay 中继'**
  String get relayConnectionRoute;

  /// No description provided for @lanRoute.
  ///
  /// In zh, this message translates to:
  /// **'局域网直连'**
  String get lanRoute;

  /// No description provided for @unknownRoute.
  ///
  /// In zh, this message translates to:
  /// **'联机方式未知'**
  String get unknownRoute;

  /// No description provided for @relayDefault.
  ///
  /// In zh, this message translates to:
  /// **'Relay 默认'**
  String get relayDefault;

  /// No description provided for @defaultTransport.
  ///
  /// In zh, this message translates to:
  /// **'默认协议'**
  String get defaultTransport;

  /// No description provided for @fullInterface.
  ///
  /// In zh, this message translates to:
  /// **'完整界面'**
  String get fullInterface;

  /// No description provided for @launching.
  ///
  /// In zh, this message translates to:
  /// **'启动中…'**
  String get launching;

  /// No description provided for @cancelling.
  ///
  /// In zh, this message translates to:
  /// **'取消中…'**
  String get cancelling;

  /// No description provided for @gameRunning.
  ///
  /// In zh, this message translates to:
  /// **'游戏运行中'**
  String get gameRunning;

  /// No description provided for @hookDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get hookDisconnected;

  /// No description provided for @hookConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get hookConnected;

  /// No description provided for @hookReconnecting.
  ///
  /// In zh, this message translates to:
  /// **'重连中'**
  String get hookReconnecting;

  /// No description provided for @hookFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败'**
  String get hookFailed;

  /// No description provided for @hookClosed.
  ///
  /// In zh, this message translates to:
  /// **'已断开'**
  String get hookClosed;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get copied;

  /// No description provided for @leaveAndJoin.
  ///
  /// In zh, this message translates to:
  /// **'退出并加入'**
  String get leaveAndJoin;

  /// No description provided for @confirmSwitch.
  ///
  /// In zh, this message translates to:
  /// **'确认切换'**
  String get confirmSwitch;

  /// No description provided for @completeExit.
  ///
  /// In zh, this message translates to:
  /// **'完全退出'**
  String get completeExit;

  /// No description provided for @hideToTrayAction.
  ///
  /// In zh, this message translates to:
  /// **'隐藏到托盘'**
  String get hideToTrayAction;

  /// No description provided for @retryAction.
  ///
  /// In zh, this message translates to:
  /// **'重试启动'**
  String get retryAction;

  /// No description provided for @exitAction.
  ///
  /// In zh, this message translates to:
  /// **'退出程序'**
  String get exitAction;

  /// No description provided for @errRoomAlreadyActive.
  ///
  /// In zh, this message translates to:
  /// **'请先退出当前房间'**
  String get errRoomAlreadyActive;

  /// No description provided for @errAccountRequired.
  ///
  /// In zh, this message translates to:
  /// **'请选择 Steam 账号'**
  String get errAccountRequired;

  /// No description provided for @errSessionRunning.
  ///
  /// In zh, this message translates to:
  /// **'游戏正在运行中，请先退出游戏'**
  String get errSessionRunning;

  /// No description provided for @errLanAdapterRequired.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择一个网卡'**
  String get errLanAdapterRequired;

  /// No description provided for @errTooManyLanAdapters.
  ///
  /// In zh, this message translates to:
  /// **'最多选择八个网卡'**
  String get errTooManyLanAdapters;

  /// No description provided for @errLaunchNotActive.
  ///
  /// In zh, this message translates to:
  /// **'当前没有可以取消的启动流程'**
  String get errLaunchNotActive;

  /// No description provided for @errLaunchCancelPending.
  ///
  /// In zh, this message translates to:
  /// **'正在取消游戏启动，请稍候'**
  String get errLaunchCancelPending;

  /// No description provided for @errLaunchGeneric.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法启动游戏'**
  String get errLaunchGeneric;

  /// No description provided for @gameLaunching.
  ///
  /// In zh, this message translates to:
  /// **'游戏正在启动中'**
  String get gameLaunching;

  /// No description provided for @errQueueBusy.
  ///
  /// In zh, this message translates to:
  /// **'命令队列繁忙，请稍后重试'**
  String get errQueueBusy;

  /// No description provided for @errPublisherUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法启动状态推送线程'**
  String get errPublisherUnavailable;

  /// No description provided for @errAlreadyInitialized.
  ///
  /// In zh, this message translates to:
  /// **'TractorBeam 已经初始化'**
  String get errAlreadyInitialized;

  /// No description provided for @errNotInitialized.
  ///
  /// In zh, this message translates to:
  /// **'应用尚未初始化'**
  String get errNotInitialized;

  /// No description provided for @errInputDelayUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前工作模式不支持输入延迟控制，请使用 Fallback 或 Pure 模式'**
  String get errInputDelayUnsupported;

  /// No description provided for @errInputDelayHookNotReady.
  ///
  /// In zh, this message translates to:
  /// **'Hook 尚未就绪，请稍后再试'**
  String get errInputDelayHookNotReady;

  /// No description provided for @errInputDelayHookBusy.
  ///
  /// In zh, this message translates to:
  /// **'Hook 正忙，请稍后重试输入延迟操作'**
  String get errInputDelayHookBusy;

  /// No description provided for @errInputDelayTimedOut.
  ///
  /// In zh, this message translates to:
  /// **'读写输入延迟超时，请稍后重试'**
  String get errInputDelayTimedOut;

  /// No description provided for @errInputDelayGeneric.
  ///
  /// In zh, this message translates to:
  /// **'无法处理输入延迟，请稍后重试'**
  String get errInputDelayGeneric;

  /// No description provided for @errConfigSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'配置保存失败'**
  String get errConfigSaveFailed;

  /// No description provided for @errRelaySaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法保存 Relay，请查看日志了解详情'**
  String get errRelaySaveFailed;

  /// No description provided for @errLanProbeFailed.
  ///
  /// In zh, this message translates to:
  /// **'局域网探测失败'**
  String get errLanProbeFailed;

  /// No description provided for @errLanUnreachable.
  ///
  /// In zh, this message translates to:
  /// **'局域网目标不可达'**
  String get errLanUnreachable;

  /// No description provided for @roomTitle.
  ///
  /// In zh, this message translates to:
  /// **'房间'**
  String get roomTitle;

  /// No description provided for @roomJoinCodeTitle.
  ///
  /// In zh, this message translates to:
  /// **'房间联机码'**
  String get roomJoinCodeTitle;

  /// No description provided for @roomJoinCodeHelp.
  ///
  /// In zh, this message translates to:
  /// **'房间联机码用于邀请其他玩家加入对局，点击可复制'**
  String get roomJoinCodeHelp;

  /// No description provided for @roomSteamAccountHelp.
  ///
  /// In zh, this message translates to:
  /// **'当前用于联机的 Steam 账号身份，支持快速切换与手动管理'**
  String get roomSteamAccountHelp;

  /// No description provided for @roomPartyHelp.
  ///
  /// In zh, this message translates to:
  /// **'当前房间内的全部玩家及对局连接状态与网络质量'**
  String get roomPartyHelp;

  /// No description provided for @roomLeaving.
  ///
  /// In zh, this message translates to:
  /// **'正在退出联机房间…'**
  String get roomLeaving;

  /// No description provided for @roomAlreadyInTarget.
  ///
  /// In zh, this message translates to:
  /// **'当前已在该房间中'**
  String get roomAlreadyInTarget;

  /// No description provided for @roomEmptySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'新建房间或输入联机码与好友联机'**
  String get roomEmptySubtitle;

  /// No description provided for @roomCreating.
  ///
  /// In zh, this message translates to:
  /// **'正在创建联机房间…'**
  String get roomCreating;

  /// No description provided for @roomJoining.
  ///
  /// In zh, this message translates to:
  /// **'正在加入联机房间…'**
  String get roomJoining;

  /// No description provided for @roomFailed.
  ///
  /// In zh, this message translates to:
  /// **'房间操作失败，请重试'**
  String get roomFailed;

  /// No description provided for @roomNotJoined.
  ///
  /// In zh, this message translates to:
  /// **'当前未加入任何联机房间'**
  String get roomNotJoined;

  /// No description provided for @createStandaloneRoom.
  ///
  /// In zh, this message translates to:
  /// **'新建独立房间'**
  String get createStandaloneRoom;

  /// No description provided for @createLanRoom.
  ///
  /// In zh, this message translates to:
  /// **'新建局域网房间'**
  String get createLanRoom;

  /// No description provided for @leaveCurrentRoom.
  ///
  /// In zh, this message translates to:
  /// **'退出当前房间'**
  String get leaveCurrentRoom;

  /// No description provided for @roomProcessingWait.
  ///
  /// In zh, this message translates to:
  /// **'正在处理房间请求，请稍候…'**
  String get roomProcessingWait;

  /// No description provided for @roomHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无历史联机房间记录'**
  String get roomHistoryEmpty;

  /// No description provided for @roomSwitchFailed.
  ///
  /// In zh, this message translates to:
  /// **'切换房间失败'**
  String get roomSwitchFailed;

  /// No description provided for @roomJoinFailed.
  ///
  /// In zh, this message translates to:
  /// **'加入房间失败'**
  String get roomJoinFailed;

  /// No description provided for @roomCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建房间失败'**
  String get roomCreateFailed;

  /// No description provided for @roomLeaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'退出房间失败'**
  String get roomLeaveFailed;

  /// No description provided for @roomCreatedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已创建独立房间'**
  String get roomCreatedSuccess;

  /// No description provided for @roomLeftSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已退出当前房间'**
  String get roomLeftSuccess;

  /// No description provided for @roomJoinedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已成功加入房间：{code}'**
  String roomJoinedSuccess(String code);

  /// No description provided for @roomSwitchedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已退出原房间并加入新房间：{code}'**
  String roomSwitchedSuccess(String code);

  /// No description provided for @roomLanCreatedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已使用 {count} 张网卡创建局域网房间'**
  String roomLanCreatedSuccess(int count);

  /// No description provided for @roomSteamAccountTitle.
  ///
  /// In zh, this message translates to:
  /// **'Steam 账号'**
  String get roomSteamAccountTitle;

  /// No description provided for @roomSteamAccountUnconfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get roomSteamAccountUnconfigured;

  /// No description provided for @roomSteamMismatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'Steam 账号不一致'**
  String get roomSteamMismatchTitle;

  /// No description provided for @roomSteamMismatchMessage.
  ///
  /// In zh, this message translates to:
  /// **'以撒游戏使用 {gameSteamId}，而房间配置为 {roomSteamId}'**
  String roomSteamMismatchMessage(String gameSteamId, String roomSteamId);

  /// No description provided for @roomSteamSyncNow.
  ///
  /// In zh, this message translates to:
  /// **'同步为游戏账号并重连'**
  String get roomSteamSyncNow;

  /// No description provided for @roomPartyTitle.
  ///
  /// In zh, this message translates to:
  /// **'联机队伍成员'**
  String get roomPartyTitle;

  /// No description provided for @memberStatusConnected.
  ///
  /// In zh, this message translates to:
  /// **'状态：已连接'**
  String get memberStatusConnected;

  /// No description provided for @memberStatusPlaying.
  ///
  /// In zh, this message translates to:
  /// **'状态：游戏中'**
  String get memberStatusPlaying;

  /// No description provided for @memberStatusReconnecting.
  ///
  /// In zh, this message translates to:
  /// **'状态：重连中'**
  String get memberStatusReconnecting;

  /// No description provided for @memberStatusDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'状态：已断开'**
  String get memberStatusDisconnected;

  /// No description provided for @memberStatusInactive.
  ///
  /// In zh, this message translates to:
  /// **'状态：未连接'**
  String get memberStatusInactive;

  /// No description provided for @memberStatusConnecting.
  ///
  /// In zh, this message translates to:
  /// **'状态：连接中'**
  String get memberStatusConnecting;

  /// No description provided for @memberTagLocal.
  ///
  /// In zh, this message translates to:
  /// **'本机'**
  String get memberTagLocal;

  /// No description provided for @memberTagHost.
  ///
  /// In zh, this message translates to:
  /// **'房主'**
  String get memberTagHost;

  /// No description provided for @memberLocalFooter.
  ///
  /// In zh, this message translates to:
  /// **'方式：{route}    协议：{transport}'**
  String memberLocalFooter(String route, String transport);

  /// No description provided for @memberPeerFooter.
  ///
  /// In zh, this message translates to:
  /// **'抖动：{jitter}ms  丢包：{loss}%'**
  String memberPeerFooter(String jitter, String loss);

  /// No description provided for @routeRelay.
  ///
  /// In zh, this message translates to:
  /// **'Relay中继'**
  String get routeRelay;

  /// No description provided for @routeLan.
  ///
  /// In zh, this message translates to:
  /// **'局域网'**
  String get routeLan;

  /// No description provided for @transportUdp.
  ///
  /// In zh, this message translates to:
  /// **'UDP'**
  String get transportUdp;

  /// No description provided for @transportTcp.
  ///
  /// In zh, this message translates to:
  /// **'TCP'**
  String get transportTcp;

  /// No description provided for @transportAuto.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get transportAuto;

  /// No description provided for @roomCurrentCode.
  ///
  /// In zh, this message translates to:
  /// **'当前联机码'**
  String get roomCurrentCode;

  /// No description provided for @roomCodeCopied.
  ///
  /// In zh, this message translates to:
  /// **'联机码已复制'**
  String get roomCodeCopied;

  /// No description provided for @inputCodeToJoin.
  ///
  /// In zh, this message translates to:
  /// **'输入联机码加入'**
  String get inputCodeToJoin;

  /// No description provided for @history.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get history;

  /// No description provided for @switchAction.
  ///
  /// In zh, this message translates to:
  /// **'切换'**
  String get switchAction;

  /// No description provided for @roomAdapterReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取网卡'**
  String get roomAdapterReadFailed;

  /// No description provided for @roomOnlineCount.
  ///
  /// In zh, this message translates to:
  /// **'在线 {count}'**
  String roomOnlineCount(int count);

  /// No description provided for @roomOnlineCountWithPage.
  ///
  /// In zh, this message translates to:
  /// **'在线 {count}  {page}/{total}'**
  String roomOnlineCountWithPage(int count, int page, int total);

  /// No description provided for @steamManualAccountDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除手动 Steam 账号'**
  String get steamManualAccountDeleted;

  /// No description provided for @steamAccountUpdated.
  ///
  /// In zh, this message translates to:
  /// **'Steam 账号信息已更新：{name}'**
  String steamAccountUpdated(String name);

  /// No description provided for @steamSwitched.
  ///
  /// In zh, this message translates to:
  /// **'已切换 Steam 账号'**
  String get steamSwitched;

  /// No description provided for @steamSwitchedAndReconnected.
  ///
  /// In zh, this message translates to:
  /// **'已切换 Steam 账号并重新连接'**
  String get steamSwitchedAndReconnected;

  /// No description provided for @steamSwitchFailed.
  ///
  /// In zh, this message translates to:
  /// **'账号切换失败'**
  String get steamSwitchFailed;

  /// No description provided for @steamSwitchedTo.
  ///
  /// In zh, this message translates to:
  /// **'已切换 Steam 账号：{name}'**
  String steamSwitchedTo(String name);

  /// No description provided for @steamRefreshAccounts.
  ///
  /// In zh, this message translates to:
  /// **'刷新账号'**
  String get steamRefreshAccounts;

  /// No description provided for @steamRefreshStarted.
  ///
  /// In zh, this message translates to:
  /// **'账号刷新已开始'**
  String get steamRefreshStarted;

  /// No description provided for @steamManualInput.
  ///
  /// In zh, this message translates to:
  /// **'手动填写'**
  String get steamManualInput;

  /// No description provided for @steamActiveQuickSwitch.
  ///
  /// In zh, this message translates to:
  /// **'Steam 活跃账号: {name} (点击快速切换)'**
  String steamActiveQuickSwitch(String name);

  /// No description provided for @steamAccountActiveTag.
  ///
  /// In zh, this message translates to:
  /// **'活跃'**
  String get steamAccountActiveTag;

  /// No description provided for @steamAccountManualTag.
  ///
  /// In zh, this message translates to:
  /// **'手动'**
  String get steamAccountManualTag;

  /// No description provided for @steamAccountCurrentLogin.
  ///
  /// In zh, this message translates to:
  /// **'Steam当前登录'**
  String get steamAccountCurrentLogin;

  /// No description provided for @roomSteamMismatchDesc.
  ///
  /// In zh, this message translates to:
  /// **'账号不一致会导致联机失败或数据无法路由，建议同步为以撒当前使用的账号。'**
  String get roomSteamMismatchDesc;

  /// No description provided for @roomSteamSyncSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已同步为以撒账号并重新连接'**
  String get roomSteamSyncSuccess;

  /// No description provided for @roomSteamSyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'同步失败'**
  String get roomSteamSyncFailed;

  /// No description provided for @settingsLanguageFollowSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsLanguageFollowSystem;

  /// No description provided for @dialogJoinRoomTitle.
  ///
  /// In zh, this message translates to:
  /// **'加入联机房间'**
  String get dialogJoinRoomTitle;

  /// No description provided for @dialogJoinRoomHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入 16 位或 32 位联机码'**
  String get dialogJoinRoomHint;

  /// No description provided for @dialogJoinRoomConfirm.
  ///
  /// In zh, this message translates to:
  /// **'加入'**
  String get dialogJoinRoomConfirm;

  /// No description provided for @dialogReplaceRoomTitle.
  ///
  /// In zh, this message translates to:
  /// **'加入新的联机房间'**
  String get dialogReplaceRoomTitle;

  /// No description provided for @dialogReplaceRoomPrompt.
  ///
  /// In zh, this message translates to:
  /// **'将退出当前房间并结束游戏联机，是否继续？'**
  String get dialogReplaceRoomPrompt;

  /// No description provided for @dialogSwitchHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'切换联机房间'**
  String get dialogSwitchHistoryTitle;

  /// No description provided for @dialogSwitchHistoryPrompt.
  ///
  /// In zh, this message translates to:
  /// **'切换后将退出当前房间；如果游戏正在运行，也会结束当前联机会话。是否继续？'**
  String get dialogSwitchHistoryPrompt;

  /// No description provided for @dialogSwitchSteamInRoomTitle.
  ///
  /// In zh, this message translates to:
  /// **'在房间中切换 Steam 账号'**
  String get dialogSwitchSteamInRoomTitle;

  /// No description provided for @dialogSwitchSteamInRoomPrompt.
  ///
  /// In zh, this message translates to:
  /// **'切换 Steam 账号将退出当前房间{extra}。是否继续？'**
  String dialogSwitchSteamInRoomPrompt(String extra);

  /// No description provided for @dialogSwitchSteamEndSession.
  ///
  /// In zh, this message translates to:
  /// **'并结束游戏联机'**
  String get dialogSwitchSteamEndSession;

  /// No description provided for @dialogCreateLanTitle.
  ///
  /// In zh, this message translates to:
  /// **'创建局域网联机'**
  String get dialogCreateLanTitle;

  /// No description provided for @dialogCreateLanSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'请选择用于局域网联机的本机网卡（最多可多选 8 张）'**
  String get dialogCreateLanSubtitle;

  /// No description provided for @dialogCreateLanConfirm.
  ///
  /// In zh, this message translates to:
  /// **'创建局域网房间'**
  String get dialogCreateLanConfirm;

  /// No description provided for @dialogAddRelayTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加 Relay 节点'**
  String get dialogAddRelayTitle;

  /// No description provided for @dialogEditRelayTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑 Relay 节点'**
  String get dialogEditRelayTitle;

  /// No description provided for @dialogRelayNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'节点名称'**
  String get dialogRelayNameLabel;

  /// No description provided for @dialogRelayNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例：华东上海极速节点'**
  String get dialogRelayNameHint;

  /// No description provided for @dialogRelayHostLabel.
  ///
  /// In zh, this message translates to:
  /// **'Relay 地址'**
  String get dialogRelayHostLabel;

  /// No description provided for @dialogRelayHostHint.
  ///
  /// In zh, this message translates to:
  /// **'例：relay.example.com'**
  String get dialogRelayHostHint;

  /// No description provided for @dialogRelayPortLabel.
  ///
  /// In zh, this message translates to:
  /// **'端口'**
  String get dialogRelayPortLabel;

  /// No description provided for @dialogRelayTransportLabel.
  ///
  /// In zh, this message translates to:
  /// **'支持的传输'**
  String get dialogRelayTransportLabel;

  /// No description provided for @dialogRelayDefaultTransportLabel.
  ///
  /// In zh, this message translates to:
  /// **'默认传输'**
  String get dialogRelayDefaultTransportLabel;

  /// No description provided for @dialogRelayDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除 Relay 节点'**
  String get dialogRelayDeleteConfirmTitle;

  /// No description provided for @dialogRelayDeleteConfirmPrompt.
  ///
  /// In zh, this message translates to:
  /// **'确认删除该节点配置吗？此操作无法撤销。'**
  String get dialogRelayDeleteConfirmPrompt;

  /// No description provided for @dialogManualSteamTitle.
  ///
  /// In zh, this message translates to:
  /// **'手动填写 Steam 账号'**
  String get dialogManualSteamTitle;

  /// No description provided for @dialogManualSteamSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'方便在未开启或多开 Steam 客户端时指定账号身份与名字'**
  String get dialogManualSteamSubtitle;

  /// No description provided for @dialogManualSteamNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get dialogManualSteamNameLabel;

  /// No description provided for @dialogManualSteamIdLabel.
  ///
  /// In zh, this message translates to:
  /// **'SteamID64'**
  String get dialogManualSteamIdLabel;

  /// No description provided for @dialogManualSteamDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除当前手动账号'**
  String get dialogManualSteamDelete;

  /// No description provided for @dialogManualSteamSave.
  ///
  /// In zh, this message translates to:
  /// **'保存并应用账号'**
  String get dialogManualSteamSave;

  /// No description provided for @dialogCloseAppTitle.
  ///
  /// In zh, this message translates to:
  /// **'关闭 Tractor Beam'**
  String get dialogCloseAppTitle;

  /// No description provided for @dialogCloseAppPrompt.
  ///
  /// In zh, this message translates to:
  /// **'是完全退出程序，还是隐藏到系统托盘继续保持联机？'**
  String get dialogCloseAppPrompt;

  /// No description provided for @dialogCloseAppRoomWarning.
  ///
  /// In zh, this message translates to:
  /// **'当前正处于联机房间中！若要保持房间请隐藏到托盘；选择“完全退出”将离开并断开房间连接。'**
  String get dialogCloseAppRoomWarning;

  /// No description provided for @dialogCloseAppSessionWarning.
  ///
  /// In zh, this message translates to:
  /// **'游戏正在运行中！若要保持联机请隐藏到托盘；选择“完全退出”将立即中断游戏联机会话。'**
  String get dialogCloseAppSessionWarning;

  /// No description provided for @dialogLaunchProgressTitle.
  ///
  /// In zh, this message translates to:
  /// **'正在启动游戏'**
  String get dialogLaunchProgressTitle;

  /// No description provided for @dialogLaunchProgressCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消启动'**
  String get dialogLaunchProgressCancel;

  /// No description provided for @dialogLaunchCancelConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消启动游戏'**
  String get dialogLaunchCancelConfirmTitle;

  /// No description provided for @dialogLaunchCancelConfirmPrompt.
  ///
  /// In zh, this message translates to:
  /// **'游戏正在启动并准备注入，是否确认取消？'**
  String get dialogLaunchCancelConfirmPrompt;

  /// No description provided for @dialogLaunchFailureTitle.
  ///
  /// In zh, this message translates to:
  /// **'启动失败'**
  String get dialogLaunchFailureTitle;

  /// No description provided for @dialogClearLogsTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空诊断日志'**
  String get dialogClearLogsTitle;

  /// No description provided for @dialogClearLogsPrompt.
  ///
  /// In zh, this message translates to:
  /// **'确认清空所有已记录的控制台日志吗？此操作无法撤销。'**
  String get dialogClearLogsPrompt;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In zh, this message translates to:
  /// **'界面语言 (Language)'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageHelpTooltip.
  ///
  /// In zh, this message translates to:
  /// **'切换 Tractor Beam 界面显示语言（支持简体中文与 English）。'**
  String get settingsLanguageHelpTooltip;

  /// No description provided for @settingsLanguageZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get settingsLanguageZh;

  /// No description provided for @settingsLanguageZhSub.
  ///
  /// In zh, this message translates to:
  /// **'中文 / 默认'**
  String get settingsLanguageZhSub;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsLanguageEnSub.
  ///
  /// In zh, this message translates to:
  /// **'英语 (US)'**
  String get settingsLanguageEnSub;

  /// No description provided for @settingsInputDelayTitle.
  ///
  /// In zh, this message translates to:
  /// **'输入延迟'**
  String get settingsInputDelayTitle;

  /// No description provided for @settingsInputDelayHelp.
  ///
  /// In zh, this message translates to:
  /// **'针对非官方工作模式微调对局帧缓冲延迟，平衡流畅度与操作手感'**
  String get settingsInputDelayHelp;

  /// No description provided for @settingsInputDelayLabel.
  ///
  /// In zh, this message translates to:
  /// **'输入延迟微调'**
  String get settingsInputDelayLabel;

  /// No description provided for @settingsInputDelayFrames.
  ///
  /// In zh, this message translates to:
  /// **'{frames} 帧 ({ms}ms)'**
  String settingsInputDelayFrames(int frames, int ms);

  /// No description provided for @settingsInputDelayRead.
  ///
  /// In zh, this message translates to:
  /// **'从游戏读取'**
  String get settingsInputDelayRead;

  /// No description provided for @settingsInputDelayWrite.
  ///
  /// In zh, this message translates to:
  /// **'写入到游戏'**
  String get settingsInputDelayWrite;

  /// No description provided for @settingsInputDelayOfficialNotice.
  ///
  /// In zh, this message translates to:
  /// **'官方模式由以撒内置网络栈管理，不支持输入延迟'**
  String get settingsInputDelayOfficialNotice;

  /// No description provided for @settingsInputDelayNotRunningNotice.
  ///
  /// In zh, this message translates to:
  /// **'以撒游戏未运行，启动游戏后方可调节输入延迟'**
  String get settingsInputDelayNotRunningNotice;

  /// No description provided for @settingsInputDelayReadSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已从游戏读取输入延迟'**
  String get settingsInputDelayReadSuccess;

  /// No description provided for @settingsInputDelayWriteSuccess.
  ///
  /// In zh, this message translates to:
  /// **'输入延迟已写入游戏'**
  String get settingsInputDelayWriteSuccess;

  /// No description provided for @settingsWorkModeTitle.
  ///
  /// In zh, this message translates to:
  /// **'工作模式'**
  String get settingsWorkModeTitle;

  /// No description provided for @settingsWorkModeHelp.
  ///
  /// In zh, this message translates to:
  /// **'决定 Hook 模块拦截与接管游戏网络流量的深度'**
  String get settingsWorkModeHelp;

  /// No description provided for @settingsModeOfficial.
  ///
  /// In zh, this message translates to:
  /// **'官方联机 (Official)'**
  String get settingsModeOfficial;

  /// No description provided for @settingsModeFallback.
  ///
  /// In zh, this message translates to:
  /// **'混合兼容 (Fallback)'**
  String get settingsModeFallback;

  /// No description provided for @settingsModePure.
  ///
  /// In zh, this message translates to:
  /// **'纯净接管 (Pure)'**
  String get settingsModePure;

  /// No description provided for @settingsModeOfficialTitle.
  ///
  /// In zh, this message translates to:
  /// **'Official'**
  String get settingsModeOfficialTitle;

  /// No description provided for @settingsModeFallbackTitle.
  ///
  /// In zh, this message translates to:
  /// **'Fallback'**
  String get settingsModeFallbackTitle;

  /// No description provided for @settingsModePureTitle.
  ///
  /// In zh, this message translates to:
  /// **'Pure'**
  String get settingsModePureTitle;

  /// No description provided for @settingsInputDelayReading.
  ///
  /// In zh, this message translates to:
  /// **'正在从以撒游戏读取延迟...'**
  String get settingsInputDelayReading;

  /// No description provided for @settingsInputDelayWriting.
  ///
  /// In zh, this message translates to:
  /// **'正在向以撒游戏写入延迟...'**
  String get settingsInputDelayWriting;

  /// No description provided for @settingsModeOfficialDesc.
  ///
  /// In zh, this message translates to:
  /// **'完全使用以撒内置 Steam P2P 网络，桥接工具仅监控状态'**
  String get settingsModeOfficialDesc;

  /// No description provided for @settingsModeFallbackDesc.
  ///
  /// In zh, this message translates to:
  /// **'优先通过 Relay 传输，遇阻时自动回退为官方 P2P 通信'**
  String get settingsModeFallbackDesc;

  /// No description provided for @settingsModePureDesc.
  ///
  /// In zh, this message translates to:
  /// **'强力接管所有网络帧，保证跨网延迟与稳定性（推荐）'**
  String get settingsModePureDesc;

  /// No description provided for @settingsWorkModeSavedRestartHint.
  ///
  /// In zh, this message translates to:
  /// **'设置已保存，需重启以撒游戏以生效新工作模式'**
  String get settingsWorkModeSavedRestartHint;

  /// No description provided for @settingsTransportProtocolTitle.
  ///
  /// In zh, this message translates to:
  /// **'底层网络传输协议'**
  String get settingsTransportProtocolTitle;

  /// No description provided for @settingsTransportProtocolHelp.
  ///
  /// In zh, this message translates to:
  /// **'Relay 模式下默认选用的底层数据包传输协议'**
  String get settingsTransportProtocolHelp;

  /// No description provided for @settingsProtocolAuto.
  ///
  /// In zh, this message translates to:
  /// **'默认 (UDP)'**
  String get settingsProtocolAuto;

  /// No description provided for @settingsProtocolUdp.
  ///
  /// In zh, this message translates to:
  /// **'UDP 协议'**
  String get settingsProtocolUdp;

  /// No description provided for @settingsProtocolTcp.
  ///
  /// In zh, this message translates to:
  /// **'TCP 协议'**
  String get settingsProtocolTcp;

  /// No description provided for @settingsRestoreDefaults.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认设置'**
  String get settingsRestoreDefaults;

  /// No description provided for @settingsRestoreDefaultsSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已恢复默认设置'**
  String get settingsRestoreDefaultsSuccess;

  /// No description provided for @settingsProtocolAutoSub.
  ///
  /// In zh, this message translates to:
  /// **'服务器默认'**
  String get settingsProtocolAutoSub;

  /// No description provided for @settingsProtocolUdpSub.
  ///
  /// In zh, this message translates to:
  /// **'低延迟'**
  String get settingsProtocolUdpSub;

  /// No description provided for @settingsProtocolTcpSub.
  ///
  /// In zh, this message translates to:
  /// **'更容易成功'**
  String get settingsProtocolTcpSub;

  /// No description provided for @settingsModeOfficialSub.
  ///
  /// In zh, this message translates to:
  /// **'官方路由'**
  String get settingsModeOfficialSub;

  /// No description provided for @settingsModeFallbackSub.
  ///
  /// In zh, this message translates to:
  /// **'优先使用TB'**
  String get settingsModeFallbackSub;

  /// No description provided for @settingsModePureSub.
  ///
  /// In zh, this message translates to:
  /// **'仅使用TB'**
  String get settingsModePureSub;

  /// No description provided for @settingsInputDelayApplied.
  ///
  /// In zh, this message translates to:
  /// **'生效: {frames}'**
  String settingsInputDelayApplied(int frames);

  /// No description provided for @settingsInputDelayAdjustHint.
  ///
  /// In zh, this message translates to:
  /// **'网络状态不佳时建议调高'**
  String get settingsInputDelayAdjustHint;

  /// No description provided for @settingsProtocolHelpTooltip.
  ///
  /// In zh, this message translates to:
  /// **'底层传输协议：\n默认：由 Relay 服务器能力自动决定\nUDP：低延迟，对网络抖动更敏感\nTCP：高穿透，更稳定且容易连通'**
  String get settingsProtocolHelpTooltip;

  /// No description provided for @settingsModeHelpTooltip.
  ///
  /// In zh, this message translates to:
  /// **'工作模式：\nOfficial：纯官方路由（不使用 TB 专线）\nFallback：优先 TB 专线，失败自动回退官方\nPure：强制仅走 TB 专线'**
  String get settingsModeHelpTooltip;

  /// No description provided for @settingsInputDelayHelpTooltip.
  ///
  /// In zh, this message translates to:
  /// **'输入延迟（0-5 帧）：\n降低延迟操作更跟手；网络抖动或丢包时可适当调高以保持平稳。\n官方模式由游戏自身网络管理，不支持此项调节。'**
  String get settingsInputDelayHelpTooltip;

  /// No description provided for @statsTitle.
  ///
  /// In zh, this message translates to:
  /// **'统计诊断'**
  String get statsTitle;

  /// No description provided for @statsConnectionQuality.
  ///
  /// In zh, this message translates to:
  /// **'连接质量'**
  String get statsConnectionQuality;

  /// No description provided for @statsPacketStats.
  ///
  /// In zh, this message translates to:
  /// **'数据包统计'**
  String get statsPacketStats;

  /// No description provided for @statsHookStatus.
  ///
  /// In zh, this message translates to:
  /// **'Hook 状态'**
  String get statsHookStatus;

  /// No description provided for @statsRefreshHook.
  ///
  /// In zh, this message translates to:
  /// **'刷新通信状态'**
  String get statsRefreshHook;

  /// No description provided for @statsTestLatency.
  ///
  /// In zh, this message translates to:
  /// **'测延迟'**
  String get statsTestLatency;

  /// No description provided for @logsTitle.
  ///
  /// In zh, this message translates to:
  /// **'控制台日志'**
  String get logsTitle;

  /// No description provided for @logsFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get logsFilterAll;

  /// No description provided for @logsFilterInfo.
  ///
  /// In zh, this message translates to:
  /// **'信息'**
  String get logsFilterInfo;

  /// No description provided for @logsFilterWarn.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get logsFilterWarn;

  /// No description provided for @logsFilterError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get logsFilterError;

  /// No description provided for @logsAutoScroll.
  ///
  /// In zh, this message translates to:
  /// **'自动滚动'**
  String get logsAutoScroll;

  /// No description provided for @logsClear.
  ///
  /// In zh, this message translates to:
  /// **'清空日志'**
  String get logsClear;

  /// No description provided for @logsExport.
  ///
  /// In zh, this message translates to:
  /// **'导出诊断包'**
  String get logsExport;

  /// No description provided for @logsSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索日志 / 关键字...'**
  String get logsSearchHint;

  /// No description provided for @aboutTitle.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get aboutTitle;

  /// No description provided for @aboutProjectDesc.
  ///
  /// In zh, this message translates to:
  /// **'专为《以撒的结合：忏悔+》打造的高性能低延迟联机工具'**
  String get aboutProjectDesc;

  /// No description provided for @aboutVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get aboutVersion;

  /// No description provided for @aboutOpenSource.
  ///
  /// In zh, this message translates to:
  /// **'开源仓库'**
  String get aboutOpenSource;

  /// No description provided for @aboutLicense.
  ///
  /// In zh, this message translates to:
  /// **'开源许可 ({license})'**
  String aboutLicense(String license);

  /// No description provided for @aboutDiagnosticTitle.
  ///
  /// In zh, this message translates to:
  /// **'诊断包导出'**
  String get aboutDiagnosticTitle;

  /// No description provided for @aboutDiagnosticDesc.
  ///
  /// In zh, this message translates to:
  /// **'遇到严重联机或注入问题时，可导出完整日志与状态包提交反馈'**
  String get aboutDiagnosticDesc;

  /// No description provided for @aboutExportButton.
  ///
  /// In zh, this message translates to:
  /// **'导出诊断包'**
  String get aboutExportButton;

  /// No description provided for @pleaseJoinRoomFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先加入联机房间'**
  String get pleaseJoinRoomFirst;

  /// No description provided for @errRelayNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入节点名称'**
  String get errRelayNameRequired;

  /// No description provided for @errRelayHostRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入 Relay 地址'**
  String get errRelayHostRequired;

  /// No description provided for @errRelayPortRange.
  ///
  /// In zh, this message translates to:
  /// **'端口号必须为 1–65535 之间的整数'**
  String get errRelayPortRange;

  /// No description provided for @errRelayProtocolRequired.
  ///
  /// In zh, this message translates to:
  /// **'必须至少选择一种传输协议 (TCP/UDP)'**
  String get errRelayProtocolRequired;

  /// No description provided for @dialogRelayDeletePrompt.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除节点“{relayName}”吗？\n删除后该节点的配置将无法恢复。'**
  String dialogRelayDeletePrompt(String relayName);

  /// No description provided for @dialogConfirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get dialogConfirmDelete;

  /// No description provided for @dialogCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get dialogCancel;

  /// No description provided for @dialogSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get dialogSave;

  /// No description provided for @dialogDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get dialogDelete;

  /// No description provided for @dialogClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get dialogClose;

  /// No description provided for @dialogClearLogsPromptDetailed.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空当前的运行与排错日志吗？\n清空后内存中的历史日志将无法恢复。'**
  String get dialogClearLogsPromptDetailed;

  /// No description provided for @dialogClearLogsConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认清空'**
  String get dialogClearLogsConfirm;

  /// No description provided for @dialogExitAppTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出 Tractor Beam'**
  String get dialogExitAppTitle;

  /// No description provided for @dialogExitSessionRunningWarning.
  ///
  /// In zh, this message translates to:
  /// **'当前游戏正在运行中，退出程序将立即终止联机会话并关闭游戏连接。是否确定退出？'**
  String get dialogExitSessionRunningWarning;

  /// No description provided for @dialogExitRoomWarning.
  ///
  /// In zh, this message translates to:
  /// **'当前正处于联机房间中，退出程序将离开房间（若为房主将解散房间）。是否确定退出？'**
  String get dialogExitRoomWarning;

  /// No description provided for @dialogExitPrompt.
  ///
  /// In zh, this message translates to:
  /// **'确定要退出 Tractor Beam 吗？'**
  String get dialogExitPrompt;

  /// No description provided for @dialogExitButton.
  ///
  /// In zh, this message translates to:
  /// **'退出程序'**
  String get dialogExitButton;

  /// No description provided for @dialogCloseAppHideToTray.
  ///
  /// In zh, this message translates to:
  /// **'隐藏到托盘'**
  String get dialogCloseAppHideToTray;

  /// No description provided for @dialogCloseAppFullExit.
  ///
  /// In zh, this message translates to:
  /// **'完全退出'**
  String get dialogCloseAppFullExit;

  /// No description provided for @dialogReplaceRoomExitAndJoin.
  ///
  /// In zh, this message translates to:
  /// **'退出并加入'**
  String get dialogReplaceRoomExitAndJoin;

  /// No description provided for @dialogSwitchRoomConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认切换'**
  String get dialogSwitchRoomConfirm;

  /// No description provided for @dialogSwitchSteamLanPrompt.
  ///
  /// In zh, this message translates to:
  /// **'当前处于局域网直连房间中。切换 Steam 账号需要退出当前房间，之后请使用新身份重新建房或加入。是否退出并切换？'**
  String get dialogSwitchSteamLanPrompt;

  /// No description provided for @dialogSwitchSteamRelayPrompt.
  ///
  /// In zh, this message translates to:
  /// **'当前正在中继房间中。切换 Steam 账号将以新身份重新连接该中继房间；如果以撒游戏正在运行，需要以新身份重新联机。是否继续？'**
  String get dialogSwitchSteamRelayPrompt;

  /// No description provided for @dialogSwitchSteamConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认切换'**
  String get dialogSwitchSteamConfirm;

  /// No description provided for @dialogJoinRoomByCodePrompt.
  ///
  /// In zh, this message translates to:
  /// **'请输入房主提供的 TB-NET 联机码：'**
  String get dialogJoinRoomByCodePrompt;

  /// No description provided for @dialogJoinRoomCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'联机码'**
  String get dialogJoinRoomCodeLabel;

  /// No description provided for @dialogLanEndpointTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择局域网端点'**
  String get dialogLanEndpointTitle;

  /// No description provided for @dialogLanEndpointPrompt.
  ///
  /// In zh, this message translates to:
  /// **'检测到多个可达地址，请选择要连接的端点：'**
  String get dialogLanEndpointPrompt;

  /// No description provided for @dialogLanEndpointConnect.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get dialogLanEndpointConnect;

  /// No description provided for @dialogLanAdaptersPrompt.
  ///
  /// In zh, this message translates to:
  /// **'可用于局域网联机的网卡'**
  String get dialogLanAdaptersPrompt;

  /// No description provided for @dialogLanNoAdapters.
  ///
  /// In zh, this message translates to:
  /// **'未检测到可用网卡'**
  String get dialogLanNoAdapters;

  /// No description provided for @dialogLanSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选择：{count}/8'**
  String dialogLanSelectedCount(int count);

  /// No description provided for @dialogCreateButton.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get dialogCreateButton;

  /// No description provided for @dialogDeleteSteamAccountTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除 Steam 账号'**
  String get dialogDeleteSteamAccountTitle;

  /// No description provided for @dialogDeleteSteamAccountPrompt.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除手动账号“{username}” ({steamId64}) 吗？\n删除后需重新手动填写录入。'**
  String dialogDeleteSteamAccountPrompt(String username, String steamId64);

  /// No description provided for @errSteamIdRequired.
  ///
  /// In zh, this message translates to:
  /// **'SteamID64 不能为空'**
  String get errSteamIdRequired;

  /// No description provided for @errSteamIdInvalid.
  ///
  /// In zh, this message translates to:
  /// **'SteamID64 必须为 17 位纯数字且不能为 0'**
  String get errSteamIdInvalid;

  /// No description provided for @errSteamUsernameRequired.
  ///
  /// In zh, this message translates to:
  /// **'用户名不能为空'**
  String get errSteamUsernameRequired;

  /// No description provided for @dialogManualSteamSavedAccounts.
  ///
  /// In zh, this message translates to:
  /// **'已保存的手动账号'**
  String get dialogManualSteamSavedAccounts;

  /// No description provided for @dialogManualSteamIdInputHint.
  ///
  /// In zh, this message translates to:
  /// **'17 位纯数字 SteamID64'**
  String get dialogManualSteamIdInputHint;

  /// No description provided for @dialogManualSteamNameInputHint.
  ///
  /// In zh, this message translates to:
  /// **'输入 Steam 用户名'**
  String get dialogManualSteamNameInputHint;

  /// No description provided for @dialogLaunchCancelFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法取消启动，请稍后重试'**
  String get dialogLaunchCancelFailed;

  /// No description provided for @dialogLaunchFailedGeneric.
  ///
  /// In zh, this message translates to:
  /// **'游戏未能启动'**
  String get dialogLaunchFailedGeneric;

  /// No description provided for @dialogLaunchGoToLogs.
  ///
  /// In zh, this message translates to:
  /// **'前往日志'**
  String get dialogLaunchGoToLogs;

  /// No description provided for @dialogLaunchStepStarting.
  ///
  /// In zh, this message translates to:
  /// **'准备启动参数'**
  String get dialogLaunchStepStarting;

  /// No description provided for @dialogLaunchStepWaitingForGame.
  ///
  /// In zh, this message translates to:
  /// **'等待游戏进程'**
  String get dialogLaunchStepWaitingForGame;

  /// No description provided for @dialogLaunchStepInjecting.
  ///
  /// In zh, this message translates to:
  /// **'注入 TractorBeam Hook'**
  String get dialogLaunchStepInjecting;

  /// No description provided for @dialogLaunchStepWaitingForHook.
  ///
  /// In zh, this message translates to:
  /// **'连接 Hook 通信端点'**
  String get dialogLaunchStepWaitingForHook;

  /// No description provided for @dialogLaunchStepReady.
  ///
  /// In zh, this message translates to:
  /// **'游戏与 Hook 就绪'**
  String get dialogLaunchStepReady;

  /// No description provided for @dialogLaunchCancelling.
  ///
  /// In zh, this message translates to:
  /// **'正在取消启动'**
  String get dialogLaunchCancelling;

  /// No description provided for @dialogLaunchCancelled.
  ///
  /// In zh, this message translates to:
  /// **'启动已取消'**
  String get dialogLaunchCancelled;

  /// No description provided for @dialogLaunchSuccess.
  ///
  /// In zh, this message translates to:
  /// **'启动成功'**
  String get dialogLaunchSuccess;

  /// No description provided for @dialogLaunchPreparing.
  ///
  /// In zh, this message translates to:
  /// **'正在准备启动游戏'**
  String get dialogLaunchPreparing;

  /// No description provided for @dialogLaunchCancellingButton.
  ///
  /// In zh, this message translates to:
  /// **'正在取消…'**
  String get dialogLaunchCancellingButton;

  /// No description provided for @dialogLaunchCancelButton.
  ///
  /// In zh, this message translates to:
  /// **'取消启动'**
  String get dialogLaunchCancelButton;

  /// No description provided for @dialogLaunchStepCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get dialogLaunchStepCompleted;

  /// No description provided for @dialogLaunchStepInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get dialogLaunchStepInProgress;

  /// No description provided for @dialogLaunchStepPending.
  ///
  /// In zh, this message translates to:
  /// **'等待中'**
  String get dialogLaunchStepPending;

  /// No description provided for @dialogLaunchNotStarted.
  ///
  /// In zh, this message translates to:
  /// **'未开始启动'**
  String get dialogLaunchNotStarted;

  /// No description provided for @dialogLaunchConfigured.
  ///
  /// In zh, this message translates to:
  /// **'启动参数已就绪'**
  String get dialogLaunchConfigured;

  /// No description provided for @dialogLaunchWaitingForGame.
  ///
  /// In zh, this message translates to:
  /// **'正在等待以撒游戏启动…'**
  String get dialogLaunchWaitingForGame;

  /// No description provided for @dialogLaunchInjectingHook.
  ///
  /// In zh, this message translates to:
  /// **'已发现游戏，正在注入 Hook 模块…'**
  String get dialogLaunchInjectingHook;

  /// No description provided for @dialogLaunchConnectingHook.
  ///
  /// In zh, this message translates to:
  /// **'注入已完成，正在建立 Hook 本地通信…'**
  String get dialogLaunchConnectingHook;

  /// No description provided for @dialogLaunchHookReady.
  ///
  /// In zh, this message translates to:
  /// **'游戏与 Hook 已就绪'**
  String get dialogLaunchHookReady;

  /// No description provided for @dialogLaunchStoppingProcess.
  ///
  /// In zh, this message translates to:
  /// **'正在停止 TractorBeam 启动流程…'**
  String get dialogLaunchStoppingProcess;

  /// No description provided for @dialogLaunchErrIsaacAlreadyRunning.
  ///
  /// In zh, this message translates to:
  /// **'以撒游戏已在运行中。请先完全退出以撒，然后重新点击启动游戏。'**
  String get dialogLaunchErrIsaacAlreadyRunning;

  /// No description provided for @dialogLaunchErrPreviousHookPresent.
  ///
  /// In zh, this message translates to:
  /// **'检测到上一次的 Hook 仍留在游戏中。请完全退出游戏后再试。'**
  String get dialogLaunchErrPreviousHookPresent;

  /// No description provided for @dialogLaunchErrCannotChangeMode.
  ///
  /// In zh, this message translates to:
  /// **'以撒运行期间无法更改工作模式，请完全退出游戏后重试。'**
  String get dialogLaunchErrCannotChangeMode;

  /// No description provided for @dialogLaunchErrLaunchInProgress.
  ///
  /// In zh, this message translates to:
  /// **'游戏启动流程正在进行中，请稍候。'**
  String get dialogLaunchErrLaunchInProgress;

  /// No description provided for @dialogLaunchErrInsufficientPermissions.
  ///
  /// In zh, this message translates to:
  /// **'注入权限不足。请关闭可能阻止注入的程序，或尝试以管理员身份运行。'**
  String get dialogLaunchErrInsufficientPermissions;

  /// No description provided for @dialogLaunchErrProcessNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未发现以撒游戏进程，请确认游戏是否已正常启动。'**
  String get dialogLaunchErrProcessNotFound;

  /// No description provided for @dialogLaunchErrMissingComponents.
  ///
  /// In zh, this message translates to:
  /// **'缺少启动所需的注入组件，请检查程序文件是否完整。'**
  String get dialogLaunchErrMissingComponents;

  /// No description provided for @dialogLaunchErrCannotPrepareParams.
  ///
  /// In zh, this message translates to:
  /// **'无法准备 Hook 启动参数，请检查程序目录的写入权限。'**
  String get dialogLaunchErrCannotPrepareParams;

  /// No description provided for @dialogLaunchErrCannotBindEndpoint.
  ///
  /// In zh, this message translates to:
  /// **'无法建立本地 Hook 通信端点，请关闭旧的游戏进程后重试。'**
  String get dialogLaunchErrCannotBindEndpoint;

  /// No description provided for @dialogLaunchErrSteamApiTakeoverFailed.
  ///
  /// In zh, this message translates to:
  /// **'Hook 无法接管 Steam API。请完全退出游戏后重试。'**
  String get dialogLaunchErrSteamApiTakeoverFailed;

  /// No description provided for @dialogLaunchErrNetworkHookInstallFailed.
  ///
  /// In zh, this message translates to:
  /// **'Hook 无法安装网络功能。请完全退出游戏后重试。'**
  String get dialogLaunchErrNetworkHookInstallFailed;

  /// No description provided for @dialogLaunchErrTimeout.
  ///
  /// In zh, this message translates to:
  /// **'等待游戏或 Hook 就绪超时，请确认游戏已正常启动后重试。'**
  String get dialogLaunchErrTimeout;

  /// No description provided for @dialogLaunchErrElevationCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消管理员提权授权，无法完成 Hook 注入。'**
  String get dialogLaunchErrElevationCancelled;

  /// No description provided for @dialogLaunchErrSteamLaunchFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法通过 Steam 启动游戏，请确认 Steam 正在运行。'**
  String get dialogLaunchErrSteamLaunchFailed;

  /// No description provided for @dialogLaunchErrUnsupportedPlatform.
  ///
  /// In zh, this message translates to:
  /// **'当前操作系统平台暂不支持原生 Hook 注入。'**
  String get dialogLaunchErrUnsupportedPlatform;

  /// No description provided for @dialogLaunchErrCannotReattach.
  ///
  /// In zh, this message translates to:
  /// **'当前游戏运行时无法重新附加或分离，请完全退出游戏后重试。'**
  String get dialogLaunchErrCannotReattach;

  /// No description provided for @dialogLaunchErrHookRuntimeTerminated.
  ///
  /// In zh, this message translates to:
  /// **'Hook 运行时已终止，请重新启动游戏。'**
  String get dialogLaunchErrHookRuntimeTerminated;

  /// No description provided for @dialogLaunchErrFileNotFound.
  ///
  /// In zh, this message translates to:
  /// **'系统找不到指定的文件，请检查游戏或注入组件完整性。'**
  String get dialogLaunchErrFileNotFound;

  /// No description provided for @dialogLaunchErrWaitTimeout120.
  ///
  /// In zh, this message translates to:
  /// **'启动等待超过 120 秒，本次启动已停止。请确认游戏和 Steam 状态后重试。'**
  String get dialogLaunchErrWaitTimeout120;

  /// No description provided for @dialogLaunchErrUnknown.
  ///
  /// In zh, this message translates to:
  /// **'游戏未能正常启动，未获取到具体错误信息。'**
  String get dialogLaunchErrUnknown;

  /// No description provided for @dialogLaunchErrOpenProcessFailed.
  ///
  /// In zh, this message translates to:
  /// **'Hook 注入失败：无法打开以撒进程（请尝试以管理员身份运行或检查杀毒软件拦截）。'**
  String get dialogLaunchErrOpenProcessFailed;

  /// No description provided for @dialogLaunchErrCreateRemoteThreadFailed.
  ///
  /// In zh, this message translates to:
  /// **'Hook 注入失败：无法在游戏中创建注入线程（可能被安全软件拦截）。'**
  String get dialogLaunchErrCreateRemoteThreadFailed;

  /// No description provided for @dialogLaunchErrAllocMemoryFailed.
  ///
  /// In zh, this message translates to:
  /// **'Hook 注入失败：无法为以撒进程分配内存。'**
  String get dialogLaunchErrAllocMemoryFailed;

  /// No description provided for @dialogLaunchErrWriteDllPathFailed.
  ///
  /// In zh, this message translates to:
  /// **'Hook 注入失败：无法向游戏写入注入路径。'**
  String get dialogLaunchErrWriteDllPathFailed;

  /// No description provided for @dialogLaunchErrInjectionGenericFailed.
  ///
  /// In zh, this message translates to:
  /// **'Hook 注入以撒进程失败，请尝试以管理员身份运行或检查杀毒软件拦截。'**
  String get dialogLaunchErrInjectionGenericFailed;

  /// No description provided for @windowMinimize.
  ///
  /// In zh, this message translates to:
  /// **'最小化'**
  String get windowMinimize;

  /// No description provided for @windowMaximize.
  ///
  /// In zh, this message translates to:
  /// **'最大化'**
  String get windowMaximize;

  /// No description provided for @windowRestore.
  ///
  /// In zh, this message translates to:
  /// **'还原'**
  String get windowRestore;

  /// No description provided for @windowClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get windowClose;

  /// No description provided for @latencyGradeExcellent.
  ///
  /// In zh, this message translates to:
  /// **'优秀'**
  String get latencyGradeExcellent;

  /// No description provided for @latencyGradeFair.
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get latencyGradeFair;

  /// No description provided for @latencyGradePoor.
  ///
  /// In zh, this message translates to:
  /// **'差'**
  String get latencyGradePoor;

  /// No description provided for @latencyGradeSevere.
  ///
  /// In zh, this message translates to:
  /// **'严重'**
  String get latencyGradeSevere;

  /// No description provided for @latencyTestComplete.
  ///
  /// In zh, this message translates to:
  /// **'延迟测试完成: {latency}ms ({grade})'**
  String latencyTestComplete(int latency, String grade);

  /// No description provided for @relayAddedAndSwitched.
  ///
  /// In zh, this message translates to:
  /// **'已添加并切换至节点：{name}'**
  String relayAddedAndSwitched(String name);

  /// No description provided for @relayUpdatedNotice.
  ///
  /// In zh, this message translates to:
  /// **'节点已更新：{name}'**
  String relayUpdatedNotice(String name);

  /// No description provided for @aboutIdentityHelp.
  ///
  /// In zh, this message translates to:
  /// **'Tractor Beam 版本、原项目架构与核心协议标准'**
  String get aboutIdentityHelp;

  /// No description provided for @aboutIdentitySlogan.
  ///
  /// In zh, this message translates to:
  /// **'为《以撒的结合：忏悔+》打造的轻量联机桥接工具'**
  String get aboutIdentitySlogan;

  /// No description provided for @aboutAuthor.
  ///
  /// In zh, this message translates to:
  /// **'项目作者'**
  String get aboutAuthor;

  /// No description provided for @aboutUiDesigner.
  ///
  /// In zh, this message translates to:
  /// **'UI 重构设计'**
  String get aboutUiDesigner;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In zh, this message translates to:
  /// **'版本标识'**
  String get aboutVersionLabel;

  /// No description provided for @aboutVersionHelp.
  ///
  /// In zh, this message translates to:
  /// **'点击复制客户端版本与诊断标识'**
  String get aboutVersionHelp;

  /// No description provided for @aboutCopiedVersionNotice.
  ///
  /// In zh, this message translates to:
  /// **'已复制客户端版本与构建诊断信息'**
  String get aboutCopiedVersionNotice;

  /// No description provided for @aboutCoreProtocol.
  ///
  /// In zh, this message translates to:
  /// **'核心协议'**
  String get aboutCoreProtocol;

  /// No description provided for @aboutLinksTitle.
  ///
  /// In zh, this message translates to:
  /// **'开源与链接'**
  String get aboutLinksTitle;

  /// No description provided for @aboutLinksHelp.
  ///
  /// In zh, this message translates to:
  /// **'本 Flutter 客户端仓库与官方原版代码仓库'**
  String get aboutLinksHelp;

  /// No description provided for @aboutSourceRepo.
  ///
  /// In zh, this message translates to:
  /// **'Flutter 客户端源码 (GitHub)'**
  String get aboutSourceRepo;

  /// No description provided for @aboutRefactorRepo.
  ///
  /// In zh, this message translates to:
  /// **'官方原版项目 (GitHub)'**
  String get aboutRefactorRepo;

  /// No description provided for @aboutRefactorRepoPending.
  ///
  /// In zh, this message translates to:
  /// **'UI 重构项目即将上线，开源地址将在上传后更新'**
  String get aboutRefactorRepoPending;

  /// No description provided for @aboutRefactorRepoBadge.
  ///
  /// In zh, this message translates to:
  /// **'预留'**
  String get aboutRefactorRepoBadge;

  /// No description provided for @aboutReleases.
  ///
  /// In zh, this message translates to:
  /// **'版本发布 (Releases)'**
  String get aboutReleases;

  /// No description provided for @aboutIssues.
  ///
  /// In zh, this message translates to:
  /// **'问题与建议反馈 (Issues)'**
  String get aboutIssues;

  /// No description provided for @aboutLinkCopiedNotice.
  ///
  /// In zh, this message translates to:
  /// **'已将 {title} 链接复制到剪贴板'**
  String aboutLinkCopiedNotice(String title);

  /// No description provided for @aboutLinkCopiedDirect.
  ///
  /// In zh, this message translates to:
  /// **'已复制 {title} 链接'**
  String aboutLinkCopiedDirect(String title);

  /// No description provided for @aboutThanksTitle.
  ///
  /// In zh, this message translates to:
  /// **'感谢'**
  String get aboutThanksTitle;

  /// No description provided for @aboutThanksHelp.
  ///
  /// In zh, this message translates to:
  /// **'致谢为 Tractor Beam 提供开发、测试与优化支持的伙伴'**
  String get aboutThanksHelp;

  /// No description provided for @aboutThanksIntro.
  ///
  /// In zh, this message translates to:
  /// **'感谢每一位帮助 Tractor Beam 变得更好的朋友'**
  String get aboutThanksIntro;

  /// No description provided for @aboutContributors.
  ///
  /// In zh, this message translates to:
  /// **'●  核心贡献者'**
  String get aboutContributors;

  /// No description provided for @aboutEarlyTesters.
  ///
  /// In zh, this message translates to:
  /// **'●  早期测试者'**
  String get aboutEarlyTesters;

  /// No description provided for @aboutTagTester.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get aboutTagTester;

  /// No description provided for @aboutTagContributor.
  ///
  /// In zh, this message translates to:
  /// **'贡献者'**
  String get aboutTagContributor;

  /// No description provided for @aboutOtherAnonymous.
  ///
  /// In zh, this message translates to:
  /// **'其他匿名玩家'**
  String get aboutOtherAnonymous;

  /// No description provided for @statsSessionQualityTitle.
  ///
  /// In zh, this message translates to:
  /// **'会话质量'**
  String get statsSessionQualityTitle;

  /// No description provided for @statsSessionQualityHelp.
  ///
  /// In zh, this message translates to:
  /// **'当前联机会话的网络平滑度评估与诊断状态'**
  String get statsSessionQualityHelp;

  /// No description provided for @statsCountersTitle.
  ///
  /// In zh, this message translates to:
  /// **'计数器'**
  String get statsCountersTitle;

  /// No description provided for @statsCountersHelp.
  ///
  /// In zh, this message translates to:
  /// **'Hook 注入与 Relay 服务器之间的数据包及字节吞吐统计'**
  String get statsCountersHelp;

  /// No description provided for @statsConnectionTestTitle.
  ///
  /// In zh, this message translates to:
  /// **'连接测试'**
  String get statsConnectionTestTitle;

  /// No description provided for @statsConnectionTestHelp.
  ///
  /// In zh, this message translates to:
  /// **'向当前选中的 Relay 节点发送轻量探测包测试延迟与连通性'**
  String get statsConnectionTestHelp;

  /// No description provided for @statsHookIpcTitle.
  ///
  /// In zh, this message translates to:
  /// **'Hook 通信状态'**
  String get statsHookIpcTitle;

  /// No description provided for @statsHookIpcHelp.
  ///
  /// In zh, this message translates to:
  /// **'以撒游戏进程内 Hook 模块与本程序的 IPC 实时通信状态'**
  String get statsHookIpcHelp;

  /// No description provided for @statsStartSpeedtest.
  ///
  /// In zh, this message translates to:
  /// **'开始测速'**
  String get statsStartSpeedtest;

  /// No description provided for @statsSpeedtesting.
  ///
  /// In zh, this message translates to:
  /// **'测速中'**
  String get statsSpeedtesting;

  /// No description provided for @statsRefreshingHook.
  ///
  /// In zh, this message translates to:
  /// **'刷新中'**
  String get statsRefreshingHook;

  /// No description provided for @statsQualityGood.
  ///
  /// In zh, this message translates to:
  /// **'会话质量：良好'**
  String get statsQualityGood;

  /// No description provided for @statsQualityWatch.
  ///
  /// In zh, this message translates to:
  /// **'会话质量：需关注'**
  String get statsQualityWatch;

  /// No description provided for @statsQualityPoor.
  ///
  /// In zh, this message translates to:
  /// **'会话质量：较差'**
  String get statsQualityPoor;

  /// No description provided for @statsQualityEvaluating.
  ///
  /// In zh, this message translates to:
  /// **'会话质量：评估中'**
  String get statsQualityEvaluating;

  /// No description provided for @statsQualityInactive.
  ///
  /// In zh, this message translates to:
  /// **'未开始会话'**
  String get statsQualityInactive;

  /// No description provided for @statsModeOfficial.
  ///
  /// In zh, this message translates to:
  /// **'官方匹配'**
  String get statsModeOfficial;

  /// No description provided for @statsModePure.
  ///
  /// In zh, this message translates to:
  /// **'纯净联机'**
  String get statsModePure;

  /// No description provided for @statsModeFallback.
  ///
  /// In zh, this message translates to:
  /// **'后备兼容'**
  String get statsModeFallback;

  /// No description provided for @statsRoomNumber.
  ///
  /// In zh, this message translates to:
  /// **'房间 {code}'**
  String statsRoomNumber(String code);

  /// No description provided for @statsRoomJoined.
  ///
  /// In zh, this message translates to:
  /// **'已加入房间'**
  String get statsRoomJoined;

  /// No description provided for @statsRoomNotJoined.
  ///
  /// In zh, this message translates to:
  /// **'未加入房间'**
  String get statsRoomNotJoined;

  /// No description provided for @statsRouteLan.
  ///
  /// In zh, this message translates to:
  /// **'局域网直连'**
  String get statsRouteLan;

  /// No description provided for @statsRouteUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知路由'**
  String get statsRouteUnknown;

  /// No description provided for @statsRouteRelay.
  ///
  /// In zh, this message translates to:
  /// **'中继转发'**
  String get statsRouteRelay;

  /// No description provided for @statsRouteRelayNode.
  ///
  /// In zh, this message translates to:
  /// **'中继 ({node})'**
  String statsRouteRelayNode(String node);

  /// No description provided for @statsTransportAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get statsTransportAuto;

  /// No description provided for @statsLabelMode.
  ///
  /// In zh, this message translates to:
  /// **'联机模式'**
  String get statsLabelMode;

  /// No description provided for @statsLabelRoomStatus.
  ///
  /// In zh, this message translates to:
  /// **'房间状态'**
  String get statsLabelRoomStatus;

  /// No description provided for @statsLabelRouteNode.
  ///
  /// In zh, this message translates to:
  /// **'路由节点'**
  String get statsLabelRouteNode;

  /// No description provided for @statsLabelTransport.
  ///
  /// In zh, this message translates to:
  /// **'传输协议'**
  String get statsLabelTransport;

  /// No description provided for @statsHealthDiagnostic.
  ///
  /// In zh, this message translates to:
  /// **'健康诊断: {health}'**
  String statsHealthDiagnostic(String health);

  /// No description provided for @statsLastStopReason.
  ///
  /// In zh, this message translates to:
  /// **'上次停止: {reason}'**
  String statsLastStopReason(String reason);

  /// No description provided for @statsCounterHookToRelay.
  ///
  /// In zh, this message translates to:
  /// **'Hook 到 Relay'**
  String get statsCounterHookToRelay;

  /// No description provided for @statsCounterBytesReceived.
  ///
  /// In zh, this message translates to:
  /// **'接收流量'**
  String get statsCounterBytesReceived;

  /// No description provided for @statsCounterRelayToHook.
  ///
  /// In zh, this message translates to:
  /// **'Relay 到 Hook'**
  String get statsCounterRelayToHook;

  /// No description provided for @statsCounterErrors.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get statsCounterErrors;

  /// No description provided for @statsCounterBytesSent.
  ///
  /// In zh, this message translates to:
  /// **'发送流量'**
  String get statsCounterBytesSent;

  /// No description provided for @statsCounterReconnectDrops.
  ///
  /// In zh, this message translates to:
  /// **'重连丢弃'**
  String get statsCounterReconnectDrops;

  /// No description provided for @statsNoTestRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无测速记录'**
  String get statsNoTestRecords;

  /// No description provided for @statsNoTestRecordsPrompt.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角“开始测速”探测当前 Relay 节点的延迟与连通性'**
  String get statsNoTestRecordsPrompt;

  /// No description provided for @statsTableHeaderNode.
  ///
  /// In zh, this message translates to:
  /// **'节点'**
  String get statsTableHeaderNode;

  /// No description provided for @statsTableHeaderTransport.
  ///
  /// In zh, this message translates to:
  /// **'传输'**
  String get statsTableHeaderTransport;

  /// No description provided for @statsTableHeaderPackets.
  ///
  /// In zh, this message translates to:
  /// **'收发'**
  String get statsTableHeaderPackets;

  /// No description provided for @statsTableHeaderLoss.
  ///
  /// In zh, this message translates to:
  /// **'丢包率'**
  String get statsTableHeaderLoss;

  /// No description provided for @statsTableHeaderLatency.
  ///
  /// In zh, this message translates to:
  /// **'延迟'**
  String get statsTableHeaderLatency;

  /// No description provided for @statsTestTimeout.
  ///
  /// In zh, this message translates to:
  /// **'超时'**
  String get statsTestTimeout;

  /// No description provided for @statsTableHeaderStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get statsTableHeaderStatus;

  /// No description provided for @statsTableHeaderVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get statsTableHeaderVersion;

  /// No description provided for @statsTableHeaderReconnects.
  ///
  /// In zh, this message translates to:
  /// **'重连'**
  String get statsTableHeaderReconnects;

  /// No description provided for @statsTableHeaderDrops.
  ///
  /// In zh, this message translates to:
  /// **'丢弃(Hook/程序)'**
  String get statsTableHeaderDrops;

  /// No description provided for @statsTableHeaderBadFrames.
  ///
  /// In zh, this message translates to:
  /// **'异常帧'**
  String get statsTableHeaderBadFrames;

  /// No description provided for @statsHookRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'Hook 状态刷新失败'**
  String get statsHookRefreshFailed;

  /// No description provided for @statsHookRefreshSuccess.
  ///
  /// In zh, this message translates to:
  /// **'Hook 状态已刷新'**
  String get statsHookRefreshSuccess;

  /// No description provided for @statsSelectRelayPrompt.
  ///
  /// In zh, this message translates to:
  /// **'请先在首页选择 Relay 节点'**
  String get statsSelectRelayPrompt;

  /// No description provided for @statsSpeedtestRejected.
  ///
  /// In zh, this message translates to:
  /// **'测速请求未被接受'**
  String get statsSpeedtestRejected;

  /// No description provided for @logsLevelAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get logsLevelAll;

  /// No description provided for @logsLevelTrace.
  ///
  /// In zh, this message translates to:
  /// **'跟踪'**
  String get logsLevelTrace;

  /// No description provided for @logsLevelDebug.
  ///
  /// In zh, this message translates to:
  /// **'调试'**
  String get logsLevelDebug;

  /// No description provided for @logsLevelInfo.
  ///
  /// In zh, this message translates to:
  /// **'信息'**
  String get logsLevelInfo;

  /// No description provided for @logsLevelWarn.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get logsLevelWarn;

  /// No description provided for @logsLevelError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get logsLevelError;

  /// No description provided for @logsExportBundle.
  ///
  /// In zh, this message translates to:
  /// **'导出诊断包'**
  String get logsExportBundle;

  /// No description provided for @logsExportBundleTooltip.
  ///
  /// In zh, this message translates to:
  /// **'导出完整诊断数据包（ZIP）'**
  String get logsExportBundleTooltip;

  /// No description provided for @logsExportingNotice.
  ///
  /// In zh, this message translates to:
  /// **'正在导出诊断包'**
  String get logsExportingNotice;

  /// No description provided for @logsOpenFolder.
  ///
  /// In zh, this message translates to:
  /// **'定位文件夹'**
  String get logsOpenFolder;

  /// No description provided for @logsOpenFolderTooltip.
  ///
  /// In zh, this message translates to:
  /// **'打开本地日志与诊断目录'**
  String get logsOpenFolderTooltip;

  /// No description provided for @logsOpeningFolderNotice.
  ///
  /// In zh, this message translates to:
  /// **'正在打开日志文件夹'**
  String get logsOpeningFolderNotice;

  /// No description provided for @logsClearTooltip.
  ///
  /// In zh, this message translates to:
  /// **'清空当前诊断日志'**
  String get logsClearTooltip;

  /// No description provided for @logsClearedNotice.
  ///
  /// In zh, this message translates to:
  /// **'日志已清空'**
  String get logsClearedNotice;

  /// No description provided for @logsShowingCount.
  ///
  /// In zh, this message translates to:
  /// **'显示 {visible} / 共 {total} 条'**
  String logsShowingCount(int visible, int total);

  /// No description provided for @logsSearchButton.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get logsSearchButton;

  /// No description provided for @logsCopyAll.
  ///
  /// In zh, this message translates to:
  /// **'复制全部'**
  String get logsCopyAll;

  /// No description provided for @logsAutoScrollOn.
  ///
  /// In zh, this message translates to:
  /// **'已锁定最新'**
  String get logsAutoScrollOn;

  /// No description provided for @logsAutoScrollPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停滚动'**
  String get logsAutoScrollPaused;

  /// No description provided for @logsEmptyNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'未找到与“{query}”匹配的日志'**
  String logsEmptyNoMatch(String query);

  /// No description provided for @logsEmptyNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无日志记录'**
  String get logsEmptyNoRecords;

  /// No description provided for @logsCopyLine.
  ///
  /// In zh, this message translates to:
  /// **'复制此行'**
  String get logsCopyLine;

  /// No description provided for @logsNoCopyableLogs.
  ///
  /// In zh, this message translates to:
  /// **'当前没有可复制的日志'**
  String get logsNoCopyableLogs;

  /// No description provided for @logsCopiedCount.
  ///
  /// In zh, this message translates to:
  /// **'已复制当前 {count} 条日志'**
  String logsCopiedCount(int count);

  /// No description provided for @logsCopiedSingle.
  ///
  /// In zh, this message translates to:
  /// **'已复制此行日志'**
  String get logsCopiedSingle;

  /// No description provided for @logsCopyFailed.
  ///
  /// In zh, this message translates to:
  /// **'复制到剪贴板失败，请稍后重试'**
  String get logsCopyFailed;

  /// No description provided for @logsAlreadyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前没有可清空的日志'**
  String get logsAlreadyEmpty;

  /// No description provided for @dialogUdpFallbackTitle.
  ///
  /// In zh, this message translates to:
  /// **'无法通过 UDP 连接'**
  String get dialogUdpFallbackTitle;

  /// No description provided for @dialogUdpFallbackBody.
  ///
  /// In zh, this message translates to:
  /// **'当前网络可能限制了 UDP 通信。可以临时改用 TCP 重新连接；TCP 通常兼容性更好，但延迟可能略高。此次重试不会修改默认协议。'**
  String get dialogUdpFallbackBody;

  /// No description provided for @dialogUdpFallbackRetry.
  ///
  /// In zh, this message translates to:
  /// **'改用 TCP 并重试'**
  String get dialogUdpFallbackRetry;

  /// No description provided for @dialogUdpFallbackSettings.
  ///
  /// In zh, this message translates to:
  /// **'打开设置'**
  String get dialogUdpFallbackSettings;

  /// No description provided for @udpTcpRetryStarted.
  ///
  /// In zh, this message translates to:
  /// **'正在改用 TCP 重新连接…'**
  String get udpTcpRetryStarted;

  /// No description provided for @udpTcpRetryFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法开始 TCP 重试'**
  String get udpTcpRetryFailed;

  /// No description provided for @latencyBatchComplete.
  ///
  /// In zh, this message translates to:
  /// **'Relay 测速完成：{successful}/{total} 个节点可用'**
  String latencyBatchComplete(int successful, int total);

  /// No description provided for @latencyBatchAllFailed.
  ///
  /// In zh, this message translates to:
  /// **'Relay 测速完成：{total} 个节点均无法连接'**
  String latencyBatchAllFailed(int total);

  /// No description provided for @aboutReleaseVersion.
  ///
  /// In zh, this message translates to:
  /// **'发布版本'**
  String get aboutReleaseVersion;

  /// No description provided for @aboutUpdateStatusLabel.
  ///
  /// In zh, this message translates to:
  /// **'更新状态'**
  String get aboutUpdateStatusLabel;

  /// No description provided for @aboutUpdateUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'已是最新版本'**
  String get aboutUpdateUpToDate;

  /// No description provided for @aboutUpdateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本：v{version}'**
  String aboutUpdateAvailable(String version);

  /// No description provided for @aboutUpdateChecking.
  ///
  /// In zh, this message translates to:
  /// **'正在检查更新…'**
  String get aboutUpdateChecking;

  /// No description provided for @aboutUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败'**
  String get aboutUpdateFailed;

  /// No description provided for @aboutCheckUpdateBtn.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get aboutCheckUpdateBtn;

  /// No description provided for @aboutViewUpdateBtn.
  ///
  /// In zh, this message translates to:
  /// **'查看更新'**
  String get aboutViewUpdateBtn;

  /// No description provided for @aboutRetryUpdateBtn.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get aboutRetryUpdateBtn;

  /// No description provided for @startupUpdateAvailableNotice.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 v{version}'**
  String startupUpdateAvailableNotice(String version);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
