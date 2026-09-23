// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navHome => '首页';

  @override
  String get navRoom => '房间';

  @override
  String get navSettings => '设置';

  @override
  String get navStatistics => '统计';

  @override
  String get navLogs => '日志';

  @override
  String get navAbout => '关于';

  @override
  String get switchToEnglish => '切换到 English';

  @override
  String get trayShowMonitor => '显示悬浮窗';

  @override
  String get trayOpenFull => '打开完整界面';

  @override
  String get trayHide => '隐藏窗口';

  @override
  String get trayExit => '退出程序';

  @override
  String get genericError => '操作失败';

  @override
  String get busy => '当前正忙，请稍后重试';

  @override
  String get roomRestoreRelayFailed => '无法恢复上一次的 Relay 房间，请检查节点和网络后重试。';

  @override
  String get roomRestoreLanFailed => '无法恢复上一次的局域网房间：原联机码中的端点当前不可达，请让房主重新发送联机码。';

  @override
  String get roomRestoreRelayTimeout => '恢复上一次的 Relay 房间超时，请检查网络后从历史记录重试。';

  @override
  String get roomRestoreLanManualRequired => '无法自动恢复上一次的局域网房间，请从历史记录中手动选择并加入。';

  @override
  String latencyComplete(int latency) {
    return '延迟测试完成：${latency}ms';
  }

  @override
  String get latencyUnavailable => '无法连接到当前 Relay 节点';

  @override
  String get latencyTimeout => '延迟测试超时，无法连接到当前 Relay 节点';

  @override
  String get startupFailed => '应用初始化失败';

  @override
  String get retry => '重试';

  @override
  String get exit => '退出';

  @override
  String get openFullInterface => '打开完整界面';

  @override
  String get hideToTray => '隐藏到托盘';

  @override
  String get localPlayer => '本机';

  @override
  String get connected => '已连接';

  @override
  String get noData => '—';

  @override
  String get homeNoticeTitle => '联机游玩须知';

  @override
  String get homeNoticeHelp => '以撒联机基本操作指南与联机注意事项';

  @override
  String get connectionMode => '联机方式';

  @override
  String get connectionModeHelp => '可选择外部中继服务器（跨公网推荐）或局域网直连模式';

  @override
  String get hostInstruction => '若你当房主，请先配置联机方式，然后创建自己的房间；';

  @override
  String get memberInstructionBefore => '若你是成员，请复制房主的“联机码”，然后 ';

  @override
  String get memberInstructionAfter => ' 。';

  @override
  String get joinRoom => '加入房间';

  @override
  String get launchInstructionBefore => '进入房间后，点击位于右下角的 ';

  @override
  String get launchInstructionAfter => ' 按钮。';

  @override
  String get launchGame => '启动游戏';

  @override
  String get startMultiplayer => '开始联机';

  @override
  String get syncSteamAccount => '同步 Steam 账号';

  @override
  String get gameReady => '游戏已就绪';

  @override
  String get gameReadyStandby => '游戏就绪';

  @override
  String get gameReadyJoinRoomPrompt => '游戏已就绪，请加入或创建房间开始联机';

  @override
  String get dialogLeaveRoomInGameTitle => '退出联机房间';

  @override
  String get dialogLeaveRoomInGameWarning =>
      '当前游戏联机对局正在进行中！退出房间将立即中断对局并切断与其他玩家的连接，是否确认退出？';

  @override
  String get confirmLeave => '确认退出';

  @override
  String get launchWarning => '不要通过 Steam 客户端或其它方式直接启动游戏！';

  @override
  String get externalRelay => '外部 Relay 中继';

  @override
  String get lanDirect => '局域网直连';

  @override
  String get lanSelectedHint => '已选局域网联机，直接前往创建房间即可';

  @override
  String get relayConfiguration => 'Relay 中继路由配置';

  @override
  String get noRelayConfigured => '当前未配置任何 Relay 节点';

  @override
  String get addRelayHint => '请点击下方按钮添加自定义 Relay 节点。';

  @override
  String get addRelay => '添加relay';

  @override
  String get editRelay => '编辑relay';

  @override
  String get switchRelay => '切换';

  @override
  String get noOtherRelayToSwitch => '暂无其他可用 Relay 节点';

  @override
  String get testLatency => '测试延迟';

  @override
  String get selectRelayFirst => '请先选择 Relay 服务器';

  @override
  String get latencyTestUnavailable => '暂时无法测试延迟';

  @override
  String get relayAddFailed => 'Relay 添加失败';

  @override
  String get relayUpdateFailed => 'Relay 更新失败';

  @override
  String get relayDeleteFailed => 'Relay 删除失败';

  @override
  String get relayDeleted => '节点已删除';

  @override
  String blockSessionAndRoom(String action) {
    return '请先退出游戏并离开房间再$action';
  }

  @override
  String blockSession(String action) {
    return '请先退出游戏再$action';
  }

  @override
  String blockRoom(String action) {
    return '请先退出房间再$action';
  }

  @override
  String blockCurrentState(String action) {
    return '当前状态下不可$action';
  }

  @override
  String get actionSwitchConnection => '切换联机方式';

  @override
  String get actionSwitchRelay => '切换 Relay 节点';

  @override
  String get actionAddRelay => '添加 Relay 节点';

  @override
  String get actionEditRelay => '编辑 Relay 节点';

  @override
  String get monitorWindow => '悬浮窗';

  @override
  String get monitorWindowTooltip => '切换到悬浮窗模式';

  @override
  String get running => '运行中';

  @override
  String get idle => '空闲';

  @override
  String reconnectCount(int count) {
    return '重连 $count';
  }

  @override
  String errorCount(String count) {
    return '错误 $count';
  }

  @override
  String get hookReady => 'Hook 已就绪';

  @override
  String get hookConnecting => 'Hook 连接中';

  @override
  String get noMembers => '暂无队员信息';

  @override
  String get relayRoute => 'Relay';

  @override
  String get relayConnectionRoute => 'Relay 中继';

  @override
  String get lanRoute => '局域网直连';

  @override
  String get unknownRoute => '联机方式未知';

  @override
  String get relayDefault => 'Relay 默认';

  @override
  String get defaultTransport => '默认协议';

  @override
  String get fullInterface => '完整界面';

  @override
  String get launching => '启动中…';

  @override
  String get cancelling => '取消中…';

  @override
  String get gameRunning => '游戏运行中';

  @override
  String get hookDisconnected => '未连接';

  @override
  String get hookConnected => '已连接';

  @override
  String get hookReconnecting => '重连中';

  @override
  String get hookFailed => '连接失败';

  @override
  String get hookClosed => '已断开';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get close => '关闭';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制到剪贴板';

  @override
  String get leaveAndJoin => '退出并加入';

  @override
  String get confirmSwitch => '确认切换';

  @override
  String get completeExit => '完全退出';

  @override
  String get hideToTrayAction => '隐藏到托盘';

  @override
  String get retryAction => '重试启动';

  @override
  String get exitAction => '退出程序';

  @override
  String get errRoomAlreadyActive => '请先退出当前房间';

  @override
  String get errAccountRequired => '请选择 Steam 账号';

  @override
  String get errSessionRunning => '游戏正在运行中，请先退出游戏';

  @override
  String get errLanAdapterRequired => '请至少选择一个网卡';

  @override
  String get errTooManyLanAdapters => '最多选择八个网卡';

  @override
  String get errLaunchNotActive => '当前没有可以取消的启动流程';

  @override
  String get errLaunchCancelPending => '正在取消游戏启动，请稍候';

  @override
  String get errLaunchGeneric => '暂时无法启动游戏';

  @override
  String get gameLaunching => '游戏正在启动中';

  @override
  String get errQueueBusy => '命令队列繁忙，请稍后重试';

  @override
  String get errPublisherUnavailable => '无法启动状态推送线程';

  @override
  String get errAlreadyInitialized => 'TractorBeam 已经初始化';

  @override
  String get errNotInitialized => '应用尚未初始化';

  @override
  String get errInputDelayUnsupported =>
      '当前工作模式不支持输入延迟控制，请使用 Fallback 或 Pure 模式';

  @override
  String get errInputDelayHookNotReady => 'Hook 尚未就绪，请稍后再试';

  @override
  String get errInputDelayHookBusy => 'Hook 正忙，请稍后重试输入延迟操作';

  @override
  String get errInputDelayTimedOut => '读写输入延迟超时，请稍后重试';

  @override
  String get errInputDelayGeneric => '无法处理输入延迟，请稍后重试';

  @override
  String get errConfigSaveFailed => '配置保存失败';

  @override
  String get errRelaySaveFailed => '无法保存 Relay，请查看日志了解详情';

  @override
  String get errLanProbeFailed => '局域网探测失败';

  @override
  String get errLanUnreachable => '局域网目标不可达';

  @override
  String get roomTitle => '房间';

  @override
  String get roomJoinCodeTitle => '房间联机码';

  @override
  String get roomJoinCodeHelp => '房间联机码用于邀请其他玩家加入对局，点击可复制';

  @override
  String get roomSteamAccountHelp => '当前用于联机的 Steam 账号身份，支持快速切换与手动管理';

  @override
  String get roomPartyHelp => '当前房间内的全部玩家及对局连接状态与网络质量';

  @override
  String get roomLeaving => '正在退出联机房间…';

  @override
  String get roomAlreadyInTarget => '当前已在该房间中';

  @override
  String get roomEmptySubtitle => '新建房间或输入联机码与好友联机';

  @override
  String get roomCreating => '正在创建联机房间…';

  @override
  String get roomJoining => '正在加入联机房间…';

  @override
  String get roomFailed => '房间操作失败，请重试';

  @override
  String get roomNotJoined => '当前未加入任何联机房间';

  @override
  String get createStandaloneRoom => '新建独立房间';

  @override
  String get createLanRoom => '新建局域网房间';

  @override
  String get leaveCurrentRoom => '退出当前房间';

  @override
  String get roomProcessingWait => '正在处理房间请求，请稍候…';

  @override
  String get roomHistoryEmpty => '暂无历史联机房间记录';

  @override
  String get roomSwitchFailed => '切换房间失败';

  @override
  String get roomJoinFailed => '加入房间失败';

  @override
  String get roomJoinRoomFull => '房间已满：当前房间已达到人数上限，请等待其他玩家退出后重试。';

  @override
  String get roomJoinRelayFull =>
      'Relay 暂时已满：当前 Relay 服务器已达到房间容量上限。请稍后重试，或更换其他 Relay 节点。';

  @override
  String get roomJoinInvalidAdmission =>
      '无法验证联机码：联机码可能无效或已经失效，请让房主重新复制并发送最新的联机码。';

  @override
  String get roomJoinDnsFailed => '无法解析 Relay 服务器地址，请检查主机名是否正确以及 DNS 和网络是否可用。';

  @override
  String get roomJoinConnectionRefused => 'Relay 服务器拒绝连接，请检查地址、端口和服务器运行状态。';

  @override
  String get roomJoinTimeout => '连接 Relay 服务器超时，请检查网络、防火墙或服务器状态。';

  @override
  String get roomJoinNetworkUnreachable => '当前网络无法到达 Relay 服务器，请检查网络连接和路由设置。';

  @override
  String get roomJoinConnectionReset => 'Relay 连接被中断，请检查网络或稍后重试。';

  @override
  String get roomJoinUdpUnavailable => 'UDP 通信受限，可尝试改用 TCP 重新连接。';

  @override
  String get roomJoinRetry => '重新加入';

  @override
  String get roomJoinClear => '清除';

  @override
  String get roomJoinFailedTitle => '加入房间失败';

  @override
  String get roomJoinJoining => '正在加入房间…';

  @override
  String get clipboardEmpty => '剪贴板为空';

  @override
  String get dialogPaste => '粘贴';

  @override
  String get roomCreateFailed => '创建房间失败';

  @override
  String get roomLeaveFailed => '退出房间失败';

  @override
  String get roomCreatedSuccess => '已创建独立房间';

  @override
  String get roomLeftSuccess => '已退出当前房间';

  @override
  String roomJoinedSuccess(String code) {
    return '已成功加入房间：$code';
  }

  @override
  String roomSwitchedSuccess(String code) {
    return '已退出原房间并加入新房间：$code';
  }

  @override
  String roomLanCreatedSuccess(int count) {
    return '已使用 $count 张网卡创建局域网房间';
  }

  @override
  String get roomSteamAccountTitle => 'Steam 账号';

  @override
  String get roomSteamAccountUnconfigured => '未配置';

  @override
  String get roomSteamMismatchTitle => 'Steam 账号不一致';

  @override
  String roomSteamMismatchMessage(String gameSteamId, String roomSteamId) {
    return '以撒游戏使用 $gameSteamId，而房间配置为 $roomSteamId';
  }

  @override
  String get roomSteamSyncNow => '同步为游戏账号并重连';

  @override
  String get roomPartyTitle => '联机队伍成员';

  @override
  String get memberStatusConnected => '状态：已连接';

  @override
  String get memberStatusPlaying => '状态：游戏中';

  @override
  String get memberStatusReconnecting => '状态：重连中';

  @override
  String get memberStatusDisconnected => '状态：已断开';

  @override
  String get memberStatusInactive => '状态：未连接';

  @override
  String get memberStatusConnecting => '状态：连接中';

  @override
  String get memberTagLocal => '本机';

  @override
  String get memberTagHost => '房主';

  @override
  String memberLocalFooter(String route, String transport) {
    return '方式：$route    协议：$transport';
  }

  @override
  String memberPeerFooter(String jitter, String loss) {
    return '抖动：${jitter}ms  丢包：$loss%';
  }

  @override
  String get routeRelay => 'Relay中继';

  @override
  String get routeLan => '局域网';

  @override
  String get transportUdp => 'UDP';

  @override
  String get transportTcp => 'TCP';

  @override
  String get transportAuto => '默认';

  @override
  String get roomCurrentCode => '当前联机码';

  @override
  String get roomCodeCopied => '联机码已复制';

  @override
  String get inputCodeToJoin => '输入联机码加入';

  @override
  String get history => '历史';

  @override
  String get switchAction => '切换';

  @override
  String get roomAdapterReadFailed => '无法读取网卡';

  @override
  String roomOnlineCount(int count) {
    return '在线 $count';
  }

  @override
  String roomOnlineCountWithPage(int count, int page, int total) {
    return '在线 $count  $page/$total';
  }

  @override
  String get steamManualAccountDeleted => '已删除手动 Steam 账号';

  @override
  String steamAccountUpdated(String name) {
    return 'Steam 账号信息已更新：$name';
  }

  @override
  String get steamSwitched => '已切换 Steam 账号';

  @override
  String get steamSwitchedAndReconnected => '已切换 Steam 账号并重新连接';

  @override
  String get steamSwitchFailed => '账号切换失败';

  @override
  String steamSwitchedTo(String name) {
    return '已切换 Steam 账号：$name';
  }

  @override
  String get steamRefreshAccounts => '刷新账号';

  @override
  String get steamRefreshStarted => '账号刷新已开始';

  @override
  String get steamManualInput => '手动填写';

  @override
  String steamActiveQuickSwitch(String name) {
    return 'Steam 活跃账号: $name (点击快速切换)';
  }

  @override
  String get steamAccountActiveTag => '活跃';

  @override
  String get steamAccountManualTag => '手动';

  @override
  String get steamAccountCurrentLogin => 'Steam当前登录';

  @override
  String get roomSteamMismatchDesc => '账号不一致会导致联机失败或数据无法路由，建议同步为以撒当前使用的账号。';

  @override
  String get roomSteamSyncSuccess => '已同步为以撒账号并重新连接';

  @override
  String get roomSteamSyncFailed => '同步失败';

  @override
  String get settingsLanguageFollowSystem => '跟随系统';

  @override
  String get dialogJoinRoomTitle => '加入联机房间';

  @override
  String get dialogJoinRoomHint => '请输入 16 位或 32 位联机码';

  @override
  String get dialogJoinRoomConfirm => '加入';

  @override
  String get dialogReplaceRoomTitle => '加入新的联机房间';

  @override
  String get dialogReplaceRoomPrompt => '将退出当前房间并结束游戏联机，是否继续？';

  @override
  String get dialogSwitchHistoryTitle => '切换联机房间';

  @override
  String get dialogSwitchHistoryPrompt =>
      '切换后将退出当前房间；如果游戏正在运行，也会结束当前联机会话。是否继续？';

  @override
  String get dialogSwitchSteamInRoomTitle => '在房间中切换 Steam 账号';

  @override
  String dialogSwitchSteamInRoomPrompt(String extra) {
    return '切换 Steam 账号将退出当前房间$extra。是否继续？';
  }

  @override
  String get dialogSwitchSteamEndSession => '并结束游戏联机';

  @override
  String get dialogCreateLanTitle => '创建局域网联机';

  @override
  String get dialogCreateLanSubtitle => '请选择用于局域网联机的本机网卡（最多可多选 8 张）';

  @override
  String get dialogCreateLanConfirm => '创建局域网房间';

  @override
  String get dialogAddRelayTitle => '添加 Relay 节点';

  @override
  String get dialogEditRelayTitle => '编辑 Relay 节点';

  @override
  String get dialogRelayNameLabel => '节点名称';

  @override
  String get dialogRelayNameHint => '例：华东上海极速节点';

  @override
  String get dialogRelayHostLabel => 'Relay 地址';

  @override
  String get dialogRelayHostHint => '例：relay.example.com';

  @override
  String get dialogRelayPortLabel => '端口';

  @override
  String get dialogRelayTransportLabel => '支持的传输';

  @override
  String get dialogRelayDefaultTransportLabel => '默认传输';

  @override
  String get dialogRelayDeleteConfirmTitle => '删除 Relay 节点';

  @override
  String get dialogRelayDeleteConfirmPrompt => '确认删除该节点配置吗？此操作无法撤销。';

  @override
  String get dialogManualSteamTitle => '手动填写 Steam 账号';

  @override
  String get dialogManualSteamSubtitle => '方便在未开启或多开 Steam 客户端时指定账号身份与名字';

  @override
  String get dialogManualSteamNameLabel => '用户名';

  @override
  String get dialogManualSteamIdLabel => 'SteamID64';

  @override
  String get dialogManualSteamDelete => '删除当前手动账号';

  @override
  String get dialogManualSteamSave => '保存并应用账号';

  @override
  String get dialogCloseAppTitle => '关闭 Tractor Beam';

  @override
  String get dialogCloseAppPrompt => '是完全退出程序，还是隐藏到系统托盘继续保持联机？';

  @override
  String get dialogCloseAppRoomWarning =>
      '当前正处于联机房间中！若要保持房间请隐藏到托盘；选择“完全退出”将离开并断开房间连接。';

  @override
  String get dialogCloseAppSessionWarning =>
      '游戏正在运行中！若要保持联机请隐藏到托盘；选择“完全退出”将立即中断游戏联机会话。';

  @override
  String get dialogLaunchProgressTitle => '正在启动游戏';

  @override
  String get dialogLaunchProgressCancel => '取消启动';

  @override
  String get dialogLaunchCancelConfirmTitle => '取消启动游戏';

  @override
  String get dialogLaunchCancelConfirmPrompt => '游戏正在启动并准备注入，是否确认取消？';

  @override
  String get dialogLaunchFailureTitle => '启动失败';

  @override
  String get dialogClearLogsTitle => '清空诊断日志';

  @override
  String get dialogClearLogsPrompt => '确认清空所有已记录的控制台日志吗？此操作无法撤销。';

  @override
  String get settingsLanguageLabel => '界面语言 (Language)';

  @override
  String get settingsLanguageTitle => '界面语言';

  @override
  String get settingsLanguageHelpTooltip =>
      '切换 Tractor Beam 界面显示语言（支持简体中文与 English）。';

  @override
  String get settingsLanguageZh => '简体中文';

  @override
  String get settingsLanguageZhSub => '中文 / 默认';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageEnSub => '英语 (US)';

  @override
  String get settingsInputDelayTitle => '输入延迟';

  @override
  String get settingsInputDelayHelp => '针对非官方工作模式微调对局帧缓冲延迟，平衡流畅度与操作手感';

  @override
  String get settingsInputDelayLabel => '输入延迟微调';

  @override
  String settingsInputDelayFrames(int frames, int ms) {
    return '$frames 帧 (${ms}ms)';
  }

  @override
  String get settingsInputDelayRead => '从游戏读取';

  @override
  String get settingsInputDelayWrite => '写入到游戏';

  @override
  String get settingsInputDelayOfficialNotice => '官方模式由以撒内置网络栈管理，不支持输入延迟';

  @override
  String get settingsInputDelayNotRunningNotice => '以撒游戏未运行，启动游戏后方可调节输入延迟';

  @override
  String get settingsInputDelayReadSuccess => '已从游戏读取输入延迟';

  @override
  String get settingsInputDelayWriteSuccess => '输入延迟已写入游戏';

  @override
  String get settingsWorkModeTitle => '工作模式';

  @override
  String get settingsWorkModeHelp => '决定 Hook 模块拦截与接管游戏网络流量的深度';

  @override
  String get settingsModeOfficial => '官方联机 (Official)';

  @override
  String get settingsModeFallback => '混合兼容 (Fallback)';

  @override
  String get settingsModePure => '纯净接管 (Pure)';

  @override
  String get settingsModeOfficialTitle => 'Official';

  @override
  String get settingsModeFallbackTitle => 'Fallback';

  @override
  String get settingsModePureTitle => 'Pure';

  @override
  String get settingsInputDelayReading => '正在从以撒游戏读取延迟...';

  @override
  String get settingsInputDelayWriting => '正在向以撒游戏写入延迟...';

  @override
  String get settingsModeOfficialDesc => '完全使用以撒内置 Steam P2P 网络，桥接工具仅监控状态';

  @override
  String get settingsModeFallbackDesc => '优先通过 Relay 传输，遇阻时自动回退为官方 P2P 通信';

  @override
  String get settingsModePureDesc => '强力接管所有网络帧，保证跨网延迟与稳定性（推荐）';

  @override
  String get settingsWorkModeSavedRestartHint => '设置已保存，需重启以撒游戏以生效新工作模式';

  @override
  String get settingsTransportProtocolTitle => '底层网络传输协议';

  @override
  String get settingsTransportProtocolHelp => 'Relay 模式下默认选用的底层数据包传输协议';

  @override
  String get settingsProtocolAuto => '默认 (UDP)';

  @override
  String get settingsProtocolUdp => 'UDP 协议';

  @override
  String get settingsProtocolTcp => 'TCP 协议';

  @override
  String get settingsRestoreDefaults => '恢复默认设置';

  @override
  String get settingsRestoreDefaultsSuccess => '已恢复默认设置';

  @override
  String get settingsProtocolAutoSub => '服务器默认';

  @override
  String get settingsProtocolUdpSub => '低延迟';

  @override
  String get settingsProtocolTcpSub => '更容易成功';

  @override
  String get settingsModeOfficialSub => '官方路由';

  @override
  String get settingsModeFallbackSub => '优先使用TB';

  @override
  String get settingsModePureSub => '仅使用TB';

  @override
  String settingsInputDelayApplied(int frames) {
    return '生效: $frames';
  }

  @override
  String get settingsInputDelayAdjustHint => '网络状态不佳时建议调高';

  @override
  String get settingsProtocolHelpTooltip =>
      '底层传输协议：\n默认：由 Relay 服务器能力自动决定\nUDP：低延迟，对网络抖动更敏感\nTCP：高穿透，更稳定且容易连通';

  @override
  String get settingsModeHelpTooltip =>
      '工作模式：\nOfficial：纯官方路由（不使用 TB 专线）\nFallback：优先 TB 专线，失败自动回退官方\nPure：强制仅走 TB 专线';

  @override
  String get settingsInputDelayHelpTooltip =>
      '输入延迟（0-5 帧）：\n降低延迟操作更跟手；网络抖动或丢包时可适当调高以保持平稳。\n官方模式由游戏自身网络管理，不支持此项调节。';

  @override
  String get statsTitle => '统计诊断';

  @override
  String get statsConnectionQuality => '连接质量';

  @override
  String get statsPacketStats => '数据包统计';

  @override
  String get statsHookStatus => 'Hook 状态';

  @override
  String get statsRefreshHook => '刷新通信状态';

  @override
  String get statsTestLatency => '测延迟';

  @override
  String get logsTitle => '控制台日志';

  @override
  String get logsFilterAll => '全部';

  @override
  String get logsFilterInfo => '信息';

  @override
  String get logsFilterWarn => '警告';

  @override
  String get logsFilterError => '错误';

  @override
  String get logsAutoScroll => '自动滚动';

  @override
  String get logsClear => '清空日志';

  @override
  String get logsExport => '导出诊断包';

  @override
  String get logsSearchHint => '搜索日志 / 关键字...';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutProjectDesc => '专为《以撒的结合：忏悔+》打造的高性能低延迟联机工具';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutOpenSource => '开源仓库';

  @override
  String aboutLicense(String license) {
    return '开源许可 ($license)';
  }

  @override
  String get aboutDiagnosticTitle => '诊断包导出';

  @override
  String get aboutDiagnosticDesc => '遇到严重联机或注入问题时，可导出完整日志与状态包提交反馈';

  @override
  String get aboutExportButton => '导出诊断包';

  @override
  String get pleaseJoinRoomFirst => '请先加入联机房间';

  @override
  String get errRelayNameRequired => '请输入节点名称';

  @override
  String get errRelayHostRequired => '请输入 Relay 地址';

  @override
  String get errRelayPortRange => '端口号必须为 1–65535 之间的整数';

  @override
  String get errRelayProtocolRequired => '必须至少选择一种传输协议 (TCP/UDP)';

  @override
  String dialogRelayDeletePrompt(String relayName) {
    return '确定要删除节点“$relayName”吗？\n删除后该节点的配置将无法恢复。';
  }

  @override
  String get dialogConfirmDelete => '确认删除';

  @override
  String get dialogCancel => '取消';

  @override
  String get dialogSave => '保存';

  @override
  String get dialogDelete => '删除';

  @override
  String get dialogClose => '关闭';

  @override
  String get dialogClearLogsPromptDetailed =>
      '确定要清空当前的运行与排错日志吗？\n清空后内存中的历史日志将无法恢复。';

  @override
  String get dialogClearLogsConfirm => '确认清空';

  @override
  String get dialogExitAppTitle => '退出 Tractor Beam';

  @override
  String get dialogExitSessionRunningWarning =>
      '当前游戏正在运行中，退出程序将立即终止联机会话并关闭游戏连接。是否确定退出？';

  @override
  String get dialogExitRoomWarning => '当前正处于联机房间中，退出程序将离开房间（若为房主将解散房间）。是否确定退出？';

  @override
  String get dialogExitPrompt => '确定要退出 Tractor Beam 吗？';

  @override
  String get dialogExitButton => '退出程序';

  @override
  String get dialogCloseAppHideToTray => '隐藏到托盘';

  @override
  String get dialogCloseAppFullExit => '完全退出';

  @override
  String get dialogReplaceRoomExitAndJoin => '退出并加入';

  @override
  String get dialogSwitchRoomConfirm => '确认切换';

  @override
  String get dialogSwitchSteamLanPrompt =>
      '当前处于局域网直连房间中。切换 Steam 账号需要退出当前房间，之后请使用新身份重新建房或加入。是否退出并切换？';

  @override
  String get dialogSwitchSteamRelayPrompt =>
      '当前正在中继房间中。切换 Steam 账号将以新身份重新连接该中继房间；如果以撒游戏正在运行，需要以新身份重新联机。是否继续？';

  @override
  String get dialogSwitchSteamConfirm => '确认切换';

  @override
  String get dialogJoinRoomByCodePrompt => '请输入房主提供的 TB-NET 联机码：';

  @override
  String get dialogJoinRoomCodeLabel => '联机码';

  @override
  String get dialogLanEndpointTitle => '选择局域网端点';

  @override
  String get dialogLanEndpointPrompt => '检测到多个可达地址，请选择要连接的端点：';

  @override
  String get dialogLanEndpointConnect => '连接';

  @override
  String get dialogLanAdaptersPrompt => '可用于局域网联机的网卡';

  @override
  String get dialogLanNoAdapters => '未检测到可用网卡';

  @override
  String dialogLanSelectedCount(int count) {
    return '已选择：$count/8';
  }

  @override
  String get dialogCreateButton => '创建';

  @override
  String get dialogDeleteSteamAccountTitle => '删除 Steam 账号';

  @override
  String dialogDeleteSteamAccountPrompt(String username, String steamId64) {
    return '确定要删除手动账号“$username” ($steamId64) 吗？\n删除后需重新手动填写录入。';
  }

  @override
  String get errSteamIdRequired => 'SteamID64 不能为空';

  @override
  String get errSteamIdInvalid => 'SteamID64 必须为 17 位纯数字且不能为 0';

  @override
  String get errSteamUsernameRequired => '用户名不能为空';

  @override
  String get dialogManualSteamSavedAccounts => '已保存的手动账号';

  @override
  String get dialogManualSteamIdInputHint => '17 位纯数字 SteamID64';

  @override
  String get dialogManualSteamNameInputHint => '输入 Steam 用户名';

  @override
  String get dialogLaunchCancelFailed => '暂时无法取消启动，请稍后重试';

  @override
  String get dialogLaunchFailedGeneric => '游戏未能启动';

  @override
  String get dialogLaunchGoToLogs => '前往日志';

  @override
  String get dialogLaunchStepStarting => '准备启动参数';

  @override
  String get dialogLaunchStepWaitingForGame => '等待游戏进程';

  @override
  String get dialogLaunchStepInjecting => '注入 TractorBeam Hook';

  @override
  String get dialogLaunchStepWaitingForHook => '连接 Hook 通信端点';

  @override
  String get dialogLaunchStepReady => '游戏与 Hook 就绪';

  @override
  String get dialogLaunchCancelling => '正在取消启动';

  @override
  String get dialogLaunchCancelled => '启动已取消';

  @override
  String get dialogLaunchSuccess => '启动成功';

  @override
  String get dialogLaunchPreparing => '正在准备启动游戏';

  @override
  String get dialogLaunchCancellingButton => '正在取消…';

  @override
  String get dialogLaunchCancelButton => '取消启动';

  @override
  String get dialogLaunchStepCompleted => '已完成';

  @override
  String get dialogLaunchStepInProgress => '进行中';

  @override
  String get dialogLaunchStepPending => '等待中';

  @override
  String get dialogLaunchNotStarted => '未开始启动';

  @override
  String get dialogLaunchConfigured => '启动参数已就绪';

  @override
  String get dialogLaunchWaitingForGame => '正在等待以撒游戏启动…';

  @override
  String get dialogLaunchInjectingHook => '已发现游戏，正在注入 Hook 模块…';

  @override
  String get dialogLaunchConnectingHook => '注入已完成，正在建立 Hook 本地通信…';

  @override
  String get dialogLaunchHookReady => '游戏与 Hook 已就绪';

  @override
  String get dialogLaunchStoppingProcess => '正在停止 TractorBeam 启动流程…';

  @override
  String get dialogLaunchErrIsaacAlreadyRunning =>
      '以撒游戏已在运行中。请先完全退出以撒，然后重新点击启动游戏。';

  @override
  String get dialogLaunchErrPreviousHookPresent =>
      '检测到上一次的 Hook 仍留在游戏中。请完全退出游戏后再试。';

  @override
  String get dialogLaunchErrCannotChangeMode => '以撒运行期间无法更改工作模式，请完全退出游戏后重试。';

  @override
  String get dialogLaunchErrLaunchInProgress => '游戏启动流程正在进行中，请稍候。';

  @override
  String get dialogLaunchErrInsufficientPermissions =>
      '注入权限不足。请关闭可能阻止注入的程序，或尝试以管理员身份运行。';

  @override
  String get dialogLaunchErrProcessNotFound => '未发现以撒游戏进程，请确认游戏是否已正常启动。';

  @override
  String get dialogLaunchErrMissingComponents => '缺少启动所需的注入组件，请检查程序文件是否完整。';

  @override
  String get dialogLaunchErrCannotPrepareParams =>
      '无法准备 Hook 启动参数，请检查程序目录的写入权限。';

  @override
  String get dialogLaunchErrCannotBindEndpoint =>
      '无法建立本地 Hook 通信端点，请关闭旧的游戏进程后重试。';

  @override
  String get dialogLaunchErrSteamApiTakeoverFailed =>
      'Hook 无法接管 Steam API。请完全退出游戏后重试。';

  @override
  String get dialogLaunchErrNetworkHookInstallFailed =>
      'Hook 无法安装网络功能。请完全退出游戏后重试。';

  @override
  String get dialogLaunchErrTimeout => '等待游戏或 Hook 就绪超时，请确认游戏已正常启动后重试。';

  @override
  String get dialogLaunchErrElevationCancelled => '已取消管理员提权授权，无法完成 Hook 注入。';

  @override
  String get dialogLaunchErrSteamLaunchFailed =>
      '无法通过 Steam 启动游戏，请确认 Steam 正在运行。';

  @override
  String get dialogLaunchErrUnsupportedPlatform => '当前操作系统平台暂不支持原生 Hook 注入。';

  @override
  String get dialogLaunchErrCannotReattach => '当前游戏运行时无法重新附加或分离，请完全退出游戏后重试。';

  @override
  String get dialogLaunchErrHookRuntimeTerminated => 'Hook 运行时已终止，请重新启动游戏。';

  @override
  String get dialogLaunchErrFileNotFound => '系统找不到指定的文件，请检查游戏或注入组件完整性。';

  @override
  String get dialogLaunchErrWaitTimeout120 =>
      '启动等待超过 120 秒，本次启动已停止。请确认游戏和 Steam 状态后重试。';

  @override
  String get dialogLaunchErrUnknown => '游戏未能正常启动，未获取到具体错误信息。';

  @override
  String get dialogLaunchErrOpenProcessFailed =>
      'Hook 注入失败：无法打开以撒进程（请尝试以管理员身份运行或检查杀毒软件拦截）。';

  @override
  String get dialogLaunchErrCreateRemoteThreadFailed =>
      'Hook 注入失败：无法在游戏中创建注入线程（可能被安全软件拦截）。';

  @override
  String get dialogLaunchErrAllocMemoryFailed => 'Hook 注入失败：无法为以撒进程分配内存。';

  @override
  String get dialogLaunchErrWriteDllPathFailed => 'Hook 注入失败：无法向游戏写入注入路径。';

  @override
  String get dialogLaunchErrInjectionGenericFailed =>
      'Hook 注入以撒进程失败，请尝试以管理员身份运行或检查杀毒软件拦截。';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowMaximize => '最大化';

  @override
  String get windowRestore => '还原';

  @override
  String get windowClose => '关闭';

  @override
  String get latencyGradeExcellent => '优秀';

  @override
  String get latencyGradeFair => '一般';

  @override
  String get latencyGradePoor => '差';

  @override
  String get latencyGradeSevere => '严重';

  @override
  String latencyTestComplete(int latency, String grade) {
    return '延迟测试完成: ${latency}ms ($grade)';
  }

  @override
  String relayAddedAndSwitched(String name) {
    return '已添加并切换至节点：$name';
  }

  @override
  String relayUpdatedNotice(String name) {
    return '节点已更新：$name';
  }

  @override
  String get aboutIdentityHelp => 'Tractor Beam 版本、原项目架构与核心协议标准';

  @override
  String get aboutIdentitySlogan => '为《以撒的结合：忏悔+》打造的轻量联机桥接工具';

  @override
  String get aboutAuthor => '项目作者';

  @override
  String get aboutUiDesigner => 'UI 重构设计';

  @override
  String get aboutVersionLabel => '版本标识';

  @override
  String get aboutVersionHelp => '点击复制客户端版本与诊断标识';

  @override
  String get aboutCopiedVersionNotice => '已复制客户端版本与构建诊断信息';

  @override
  String get aboutCoreProtocol => '核心协议';

  @override
  String get aboutLinksTitle => '开源与链接';

  @override
  String get aboutLinksHelp => '本 Flutter 客户端仓库与官方原版代码仓库';

  @override
  String get aboutSourceRepo => 'Flutter 客户端源码 (GitHub)';

  @override
  String get aboutRefactorRepo => '官方原版项目 (GitHub)';

  @override
  String get aboutRefactorRepoPending => 'UI 重构项目即将上线，开源地址将在上传后更新';

  @override
  String get aboutRefactorRepoBadge => '预留';

  @override
  String get aboutReleases => '版本发布 (Releases)';

  @override
  String get aboutIssues => '问题与建议反馈 (Issues)';

  @override
  String aboutLinkCopiedNotice(String title) {
    return '已将 $title 链接复制到剪贴板';
  }

  @override
  String aboutLinkCopiedDirect(String title) {
    return '已复制 $title 链接';
  }

  @override
  String get aboutThanksTitle => '感谢';

  @override
  String get aboutThanksHelp => '致谢为 Tractor Beam 提供开发、测试与优化支持的伙伴';

  @override
  String get aboutThanksIntro => '感谢每一位帮助 Tractor Beam 变得更好的朋友';

  @override
  String get aboutContributors => '●  核心贡献者';

  @override
  String get aboutEarlyTesters => '●  早期测试者';

  @override
  String get aboutTagTester => '测试';

  @override
  String get aboutTagContributor => '贡献者';

  @override
  String get aboutOtherAnonymous => '其他匿名玩家';

  @override
  String get statsSessionQualityTitle => '会话质量';

  @override
  String get statsSessionQualityHelp => '当前联机会话的网络平滑度评估与诊断状态';

  @override
  String get statsCountersTitle => '计数器';

  @override
  String get statsCountersHelp => 'Hook 注入与 Relay 服务器之间的数据包及字节吞吐统计';

  @override
  String get statsConnectionTestTitle => '连接测试';

  @override
  String get statsConnectionTestHelp => '向当前选中的 Relay 节点发送轻量探测包测试延迟与连通性';

  @override
  String get statsHookIpcTitle => 'Hook 通信状态';

  @override
  String get statsHookIpcHelp => '以撒游戏进程内 Hook 模块与本程序的 IPC 实时通信状态';

  @override
  String get statsStartSpeedtest => '开始测速';

  @override
  String get statsSpeedtesting => '测速中';

  @override
  String get statsRefreshingHook => '刷新中';

  @override
  String get statsQualityGood => '会话质量：良好';

  @override
  String get statsQualityWatch => '会话质量：需关注';

  @override
  String get statsQualityPoor => '会话质量：较差';

  @override
  String get statsQualityEvaluating => '会话质量：评估中';

  @override
  String get statsQualityInactive => '未开始会话';

  @override
  String get statsModeOfficial => '官方匹配';

  @override
  String get statsModePure => '纯净联机';

  @override
  String get statsModeFallback => '后备兼容';

  @override
  String statsRoomNumber(String code) {
    return '房间 $code';
  }

  @override
  String get statsRoomJoined => '已加入房间';

  @override
  String get statsRoomNotJoined => '未加入房间';

  @override
  String get statsRouteLan => '局域网直连';

  @override
  String get statsRouteUnknown => '未知路由';

  @override
  String get statsRouteRelay => '中继转发';

  @override
  String statsRouteRelayNode(String node) {
    return '中继 ($node)';
  }

  @override
  String get statsTransportAuto => '自动';

  @override
  String get statsLabelMode => '联机模式';

  @override
  String get statsLabelRoomStatus => '房间状态';

  @override
  String get statsLabelRouteNode => '路由节点';

  @override
  String get statsLabelTransport => '传输协议';

  @override
  String statsHealthDiagnostic(String health) {
    return '健康诊断: $health';
  }

  @override
  String statsLastStopReason(String reason) {
    return '上次停止: $reason';
  }

  @override
  String get statsCounterHookToRelay => 'Hook 到 Relay';

  @override
  String get statsCounterBytesReceived => '接收流量';

  @override
  String get statsCounterRelayToHook => 'Relay 到 Hook';

  @override
  String get statsCounterErrors => '错误';

  @override
  String get statsCounterBytesSent => '发送流量';

  @override
  String get statsCounterReconnectDrops => '重连丢弃';

  @override
  String get statsNoTestRecords => '暂无测速记录';

  @override
  String get statsNoTestRecordsPrompt => '点击右上角“开始测速”探测当前 Relay 节点的延迟与连通性';

  @override
  String get statsTableHeaderNode => '节点';

  @override
  String get statsTableHeaderTransport => '传输';

  @override
  String get statsTableHeaderPackets => '收发';

  @override
  String get statsTableHeaderLoss => '丢包率';

  @override
  String get statsTableHeaderLatency => '延迟';

  @override
  String get statsTestTimeout => '超时';

  @override
  String get statsTableHeaderStatus => '状态';

  @override
  String get statsTableHeaderVersion => '版本';

  @override
  String get statsTableHeaderReconnects => '重连';

  @override
  String get statsTableHeaderDrops => '丢弃(Hook/程序)';

  @override
  String get statsTableHeaderBadFrames => '异常帧';

  @override
  String get statsHookRefreshFailed => 'Hook 状态刷新失败';

  @override
  String get statsHookRefreshSuccess => 'Hook 状态已刷新';

  @override
  String get statsSelectRelayPrompt => '请先在首页选择 Relay 节点';

  @override
  String get statsSpeedtestRejected => '测速请求未被接受';

  @override
  String get logsLevelAll => '全部';

  @override
  String get logsLevelTrace => '跟踪';

  @override
  String get logsLevelDebug => '调试';

  @override
  String get logsLevelInfo => '信息';

  @override
  String get logsLevelWarn => '警告';

  @override
  String get logsLevelError => '错误';

  @override
  String get logsExportBundle => '导出诊断包';

  @override
  String get logsExportBundleTooltip => '导出完整诊断数据包（ZIP）';

  @override
  String get logsExportingNotice => '正在导出诊断包';

  @override
  String get logsOpenFolder => '定位文件夹';

  @override
  String get logsOpenFolderTooltip => '打开本地日志与诊断目录';

  @override
  String get logsOpeningFolderNotice => '正在打开日志文件夹';

  @override
  String get logsClearTooltip => '清空当前诊断日志';

  @override
  String get logsClearedNotice => '日志已清空';

  @override
  String logsShowingCount(int visible, int total) {
    return '显示 $visible / 共 $total 条';
  }

  @override
  String get logsSearchButton => '搜索';

  @override
  String get logsCopyAll => '复制全部';

  @override
  String get logsAutoScrollOn => '已锁定最新';

  @override
  String get logsAutoScrollPaused => '已暂停滚动';

  @override
  String logsEmptyNoMatch(String query) {
    return '未找到与“$query”匹配的日志';
  }

  @override
  String get logsEmptyNoRecords => '暂无日志记录';

  @override
  String get logsCopyLine => '复制此行';

  @override
  String get logsNoCopyableLogs => '当前没有可复制的日志';

  @override
  String logsCopiedCount(int count) {
    return '已复制当前 $count 条日志';
  }

  @override
  String get logsCopiedSingle => '已复制此行日志';

  @override
  String get logsCopyFailed => '复制到剪贴板失败，请稍后重试';

  @override
  String get logsAlreadyEmpty => '当前没有可清空的日志';

  @override
  String get dialogUdpFallbackTitle => '无法通过 UDP 连接';

  @override
  String get dialogUdpFallbackBody =>
      '当前网络可能限制了 UDP 通信。可以临时改用 TCP 重新连接；TCP 通常兼容性更好，但延迟可能略高。此次重试不会修改默认协议。';

  @override
  String get dialogUdpFallbackRetry => '改用 TCP 并重试';

  @override
  String get dialogUdpFallbackSettings => '打开设置';

  @override
  String get udpTcpRetryStarted => '正在改用 TCP 重新连接…';

  @override
  String get udpTcpRetryFailed => '无法开始 TCP 重试';

  @override
  String latencyBatchComplete(int successful, int total) {
    return 'Relay 测速完成：$successful/$total 个节点可用';
  }

  @override
  String latencyBatchAllFailed(int total) {
    return 'Relay 测速完成：$total 个节点均无法连接';
  }

  @override
  String get lightweightBackToMain => '← 主界面';

  @override
  String get lightweightApplyDelay => '应用';

  @override
  String framesCount(int frames) {
    return '$frames 帧';
  }

  @override
  String get aboutReleaseVersion => '发布版本';

  @override
  String get aboutUpdateStatusLabel => '更新状态';

  @override
  String get aboutUpdateUpToDate => '已是最新版本';

  @override
  String aboutUpdateAvailable(String version) {
    return '发现新版本：v$version';
  }

  @override
  String get aboutUpdateChecking => '正在检查更新…';

  @override
  String get aboutUpdateFailed => '检查更新失败';

  @override
  String get aboutCheckUpdateBtn => '检查更新';

  @override
  String get aboutViewUpdateBtn => '查看更新';

  @override
  String get aboutRetryUpdateBtn => '重试';

  @override
  String startupUpdateAvailableNotice(String version) {
    return '发现新版本 v$version';
  }

  @override
  String activeRelayLatencyTooltip(int latency, String grade) {
    return '当前 Relay 往返延迟：${latency}ms ($grade)';
  }

  @override
  String selectedRelayLatencyTooltip(int latency, String grade) {
    return '节点测速延迟：${latency}ms ($grade)';
  }

  @override
  String get relayReconnecting => '重连中…';

  @override
  String get relayReconnectingTooltip => 'Relay 连接已断开，正在尝试重连…';
}
