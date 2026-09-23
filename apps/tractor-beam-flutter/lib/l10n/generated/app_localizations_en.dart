// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navRoom => 'Room';

  @override
  String get navSettings => 'Settings';

  @override
  String get navStatistics => 'Stats';

  @override
  String get navLogs => 'Logs';

  @override
  String get navAbout => 'About';

  @override
  String get switchToEnglish => 'Switch to Chinese';

  @override
  String get trayShowMonitor => 'Show monitor';

  @override
  String get trayOpenFull => 'Open full interface';

  @override
  String get trayHide => 'Hide window';

  @override
  String get trayExit => 'Exit application';

  @override
  String get genericError => 'Operation failed';

  @override
  String get busy => 'The application is busy. Try again shortly.';

  @override
  String get roomRestoreRelayFailed =>
      'Could not restore the previous Relay room. Check the Relay server and network, then try again.';

  @override
  String get roomRestoreLanFailed =>
      'Could not restore the previous LAN room because its saved endpoint is no longer reachable. Ask the host for a new Join Code.';

  @override
  String get roomRestoreRelayTimeout =>
      'Restoring the previous Relay room timed out. Check your network and retry it from room history.';

  @override
  String get roomRestoreLanManualRequired =>
      'The previous LAN room cannot be restored automatically. Select it from room history and choose an endpoint manually.';

  @override
  String latencyComplete(int latency) {
    return 'Latency test completed: ${latency}ms';
  }

  @override
  String get latencyUnavailable =>
      'Could not connect to the selected Relay server';

  @override
  String get latencyTimeout =>
      'Latency test timed out; the selected Relay server could not be reached';

  @override
  String get startupFailed => 'Application initialization failed';

  @override
  String get retry => 'Retry';

  @override
  String get exit => 'Exit';

  @override
  String get openFullInterface => 'Open full interface';

  @override
  String get hideToTray => 'Hide to tray';

  @override
  String get localPlayer => 'Local';

  @override
  String get connected => 'Connected';

  @override
  String get noData => '—';

  @override
  String get homeNoticeTitle => 'Online Play Guide';

  @override
  String get homeNoticeHelp =>
      'Basic online play instructions and important notes';

  @override
  String get connectionMode => 'Connection Mode';

  @override
  String get connectionModeHelp =>
      'Choose an external Relay for internet play or a direct LAN connection';

  @override
  String get hostInstruction =>
      'If you are the host, choose a connection mode and create a room.';

  @override
  String get memberInstructionBefore =>
      'If you are joining, copy the host\'s Join Code and select ';

  @override
  String get memberInstructionAfter => '.';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get launchInstructionBefore => 'After joining the room, select ';

  @override
  String get launchInstructionAfter => ' in the lower-right corner.';

  @override
  String get launchGame => 'Launch Game';

  @override
  String get startMultiplayer => 'Start Multiplayer';

  @override
  String get gameReady => 'Game Ready';

  @override
  String get gameReadyStandby => 'Game Ready';

  @override
  String get gameReadyJoinRoomPrompt =>
      'Game is ready. Please join or create a room to start multiplayer.';

  @override
  String get dialogLeaveRoomInGameTitle => 'Leave Multiplayer Room';

  @override
  String get dialogLeaveRoomInGameWarning =>
      'Gameplay is currently active! Leaving the room will immediately disconnect you from other players. Are you sure you want to leave?';

  @override
  String get confirmLeave => 'Leave Room';

  @override
  String get launchWarning =>
      'Do not launch the game directly through Steam or another shortcut.';

  @override
  String get externalRelay => 'External Relay';

  @override
  String get lanDirect => 'LAN Direct';

  @override
  String get lanSelectedHint =>
      'LAN Direct is selected. Continue to the Room page to create a room.';

  @override
  String get relayConfiguration => 'Relay Configuration';

  @override
  String get noRelayConfigured => 'No Relay server is configured';

  @override
  String get addRelayHint =>
      'Use the button below to add a custom Relay server.';

  @override
  String get addRelay => 'Add Relay';

  @override
  String get editRelay => 'Edit Relay';

  @override
  String get switchRelay => 'Switch';

  @override
  String get noOtherRelayToSwitch => 'No other Relay server available';

  @override
  String get testLatency => 'Test Latency';

  @override
  String get selectRelayFirst => 'Select a Relay server first';

  @override
  String get latencyTestUnavailable => 'Latency cannot be tested right now';

  @override
  String get relayAddFailed => 'Could not add the Relay server';

  @override
  String get relayUpdateFailed => 'Could not update the Relay server';

  @override
  String get relayDeleteFailed => 'Could not delete the Relay server';

  @override
  String get relayDeleted => 'Relay server deleted';

  @override
  String blockSessionAndRoom(String action) {
    return 'Exit the game and leave the room before you $action';
  }

  @override
  String blockSession(String action) {
    return 'Exit the game before you $action';
  }

  @override
  String blockRoom(String action) {
    return 'Leave the room before you $action';
  }

  @override
  String blockCurrentState(String action) {
    return 'You cannot $action in the current state';
  }

  @override
  String get actionSwitchConnection => 'switch connection modes';

  @override
  String get actionSwitchRelay => 'switch Relay servers';

  @override
  String get actionAddRelay => 'add Relay node';

  @override
  String get actionEditRelay => 'edit Relay node';

  @override
  String get monitorWindow => 'Monitor';

  @override
  String get monitorWindowTooltip => 'Switch to floating window mode';

  @override
  String get running => 'Running';

  @override
  String get idle => 'Idle';

  @override
  String reconnectCount(int count) {
    return 'Reconnects $count';
  }

  @override
  String errorCount(String count) {
    return 'Errors $count';
  }

  @override
  String get hookReady => 'Hook ready';

  @override
  String get hookConnecting => 'Hook connecting';

  @override
  String get noMembers => 'No member information';

  @override
  String get relayRoute => 'Relay';

  @override
  String get relayConnectionRoute => 'Relay';

  @override
  String get lanRoute => 'LAN Direct';

  @override
  String get unknownRoute => 'Unknown route';

  @override
  String get relayDefault => 'Relay default';

  @override
  String get defaultTransport => 'Default protocol';

  @override
  String get fullInterface => 'Full interface';

  @override
  String get launching => 'Launching…';

  @override
  String get cancelling => 'Cancelling…';

  @override
  String get gameRunning => 'Game running';

  @override
  String get hookDisconnected => 'Not connected';

  @override
  String get hookConnected => 'Connected';

  @override
  String get hookReconnecting => 'Reconnecting';

  @override
  String get hookFailed => 'Connection failed';

  @override
  String get hookClosed => 'Disconnected';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get leaveAndJoin => 'Leave & Join';

  @override
  String get confirmSwitch => 'Confirm Switch';

  @override
  String get completeExit => 'Exit App';

  @override
  String get hideToTrayAction => 'Hide to Tray';

  @override
  String get retryAction => 'Retry';

  @override
  String get exitAction => 'Exit';

  @override
  String get errRoomAlreadyActive => 'Please leave the current room first';

  @override
  String get errAccountRequired => 'Please select a Steam account';

  @override
  String get errSessionRunning =>
      'Game is currently running; please exit the game first';

  @override
  String get errLanAdapterRequired =>
      'Please select at least one network adapter';

  @override
  String get errTooManyLanAdapters => 'Select up to 8 network adapters';

  @override
  String get errLaunchNotActive => 'No active launch flow to cancel';

  @override
  String get errLaunchCancelPending => 'Cancelling game launch, please wait';

  @override
  String get errLaunchGeneric => 'Unable to launch game';

  @override
  String get gameLaunching => 'Game is launching';

  @override
  String get errQueueBusy => 'Command queue is busy, please try again shortly';

  @override
  String get errPublisherUnavailable =>
      'Failed to start status publisher thread';

  @override
  String get errAlreadyInitialized => 'TractorBeam is already initialized';

  @override
  String get errNotInitialized => 'Application is not initialized yet';

  @override
  String get errInputDelayUnsupported =>
      'Input delay is not supported in the current mode; please use Fallback or Pure mode';

  @override
  String get errInputDelayHookNotReady =>
      'Hook is not ready yet; please try again later';

  @override
  String get errInputDelayHookBusy =>
      'Hook is busy; please retry input delay operation shortly';

  @override
  String get errInputDelayTimedOut =>
      'Input delay read/write timed out; please try again later';

  @override
  String get errInputDelayGeneric =>
      'Failed to process input delay; please try again later';

  @override
  String get errConfigSaveFailed => 'Failed to save configuration';

  @override
  String get errRelaySaveFailed =>
      'Could not save Relay; check logs for details';

  @override
  String get errLanProbeFailed => 'LAN probe failed';

  @override
  String get errLanUnreachable => 'LAN target is unreachable';

  @override
  String get roomTitle => 'Room';

  @override
  String get roomJoinCodeTitle => 'Room Join Code';

  @override
  String get roomJoinCodeHelp =>
      'Room code is used to invite players to join the match; click to copy';

  @override
  String get roomSteamAccountHelp =>
      'Steam account identity for multiplayer; supports quick switching and manual management';

  @override
  String get roomPartyHelp =>
      'All members in the current room, connection states, and network metrics';

  @override
  String get roomLeaving => 'Leaving room…';

  @override
  String get roomAlreadyInTarget => 'Already in this room';

  @override
  String get roomEmptySubtitle =>
      'Create a room or enter a Join Code to play with friends';

  @override
  String get roomCreating => 'Creating room…';

  @override
  String get roomJoining => 'Joining room…';

  @override
  String get roomFailed => 'Room operation failed; please try again';

  @override
  String get roomNotJoined => 'You have not joined any room yet';

  @override
  String get createStandaloneRoom => 'Create Room';

  @override
  String get createLanRoom => 'Create LAN Room';

  @override
  String get leaveCurrentRoom => 'Leave Room';

  @override
  String get roomProcessingWait => 'Processing room request, please wait…';

  @override
  String get roomHistoryEmpty => 'No room history records';

  @override
  String get roomSwitchFailed => 'Failed to switch room';

  @override
  String get roomJoinFailed => 'Failed to join room';

  @override
  String get roomJoinRoomFull =>
      'Room is full: the room has reached its player limit. Please wait for other players to leave and try again.';

  @override
  String get roomJoinRelayFull =>
      'Relay is temporarily full: the relay server has reached its room capacity. Please try again later or choose another relay node.';

  @override
  String get roomJoinInvalidAdmission =>
      'Could not verify room code: the code may be invalid or expired. Ask the host to send a new room code.';

  @override
  String get roomJoinDnsFailed =>
      'Could not resolve relay server address. Check host configuration, DNS, and network connectivity.';

  @override
  String get roomJoinConnectionRefused =>
      'Relay server refused connection. Check address, port, and server status.';

  @override
  String get roomJoinTimeout =>
      'Connection to relay server timed out. Check network, firewall, or server status.';

  @override
  String get roomJoinNetworkUnreachable =>
      'Relay server is unreachable from current network. Check network connection and routing.';

  @override
  String get roomJoinConnectionReset =>
      'Relay connection was reset. Check network or try again later.';

  @override
  String get roomJoinUdpUnavailable =>
      'UDP communication is restricted. You can retry with TCP.';

  @override
  String get roomJoinRetry => 'Retry Join';

  @override
  String get roomJoinClear => 'Clear';

  @override
  String get roomJoinFailedTitle => 'Failed to Join Room';

  @override
  String get roomJoinJoining => 'Joining room…';

  @override
  String get clipboardEmpty => 'Clipboard is empty';

  @override
  String get dialogPaste => 'Paste';

  @override
  String get roomCreateFailed => 'Failed to create room';

  @override
  String get roomLeaveFailed => 'Failed to leave room';

  @override
  String get roomCreatedSuccess => 'Room created successfully';

  @override
  String get roomLeftSuccess => 'Left current room';

  @override
  String roomJoinedSuccess(String code) {
    return 'Joined room: $code';
  }

  @override
  String roomSwitchedSuccess(String code) {
    return 'Left previous room and joined new room: $code';
  }

  @override
  String roomLanCreatedSuccess(int count) {
    return 'Created LAN room with $count network adapters';
  }

  @override
  String get roomSteamAccountTitle => 'Steam Account';

  @override
  String get roomSteamAccountUnconfigured => 'Unconfigured';

  @override
  String get roomSteamMismatchTitle => 'Steam Account Mismatch';

  @override
  String roomSteamMismatchMessage(String gameSteamId, String roomSteamId) {
    return 'Isaac game uses $gameSteamId, but room is configured with $roomSteamId';
  }

  @override
  String get roomSteamSyncNow => 'Sync to Game Account & Reconnect';

  @override
  String get roomPartyTitle => 'Party Members';

  @override
  String get memberStatusConnected => 'Status: Connected';

  @override
  String get memberStatusPlaying => 'Status: In Game';

  @override
  String get memberStatusReconnecting => 'Status: Reconnecting';

  @override
  String get memberStatusDisconnected => 'Status: Disconnected';

  @override
  String get memberStatusInactive => 'Status: Disconnected';

  @override
  String get memberStatusConnecting => 'Status: Connecting';

  @override
  String get memberTagLocal => 'Local';

  @override
  String get memberTagHost => 'Host';

  @override
  String memberLocalFooter(String route, String transport) {
    return 'Route: $route    Transport: $transport';
  }

  @override
  String memberPeerFooter(String jitter, String loss) {
    return 'Jitter: ${jitter}ms  Loss: $loss%';
  }

  @override
  String get routeRelay => 'Relay';

  @override
  String get routeLan => 'LAN';

  @override
  String get transportUdp => 'UDP';

  @override
  String get transportTcp => 'TCP';

  @override
  String get transportAuto => 'Auto';

  @override
  String get roomCurrentCode => 'Current Code';

  @override
  String get roomCodeCopied => 'Room code copied';

  @override
  String get inputCodeToJoin => 'Enter Code to Join';

  @override
  String get history => 'History';

  @override
  String get switchAction => 'Switch';

  @override
  String get roomAdapterReadFailed => 'Failed to read network adapters';

  @override
  String roomOnlineCount(int count) {
    return 'Online $count';
  }

  @override
  String roomOnlineCountWithPage(int count, int page, int total) {
    return 'Online $count  $page/$total';
  }

  @override
  String get steamManualAccountDeleted => 'Manual Steam account deleted';

  @override
  String steamAccountUpdated(String name) {
    return 'Steam account updated: $name';
  }

  @override
  String get steamSwitched => 'Switched Steam account';

  @override
  String get steamSwitchedAndReconnected =>
      'Switched Steam account and reconnected';

  @override
  String get steamSwitchFailed => 'Failed to switch account';

  @override
  String steamSwitchedTo(String name) {
    return 'Switched Steam account: $name';
  }

  @override
  String get steamRefreshAccounts => 'Refresh Accounts';

  @override
  String get steamRefreshStarted => 'Account refresh started';

  @override
  String get steamManualInput => 'Manual Entry';

  @override
  String steamActiveQuickSwitch(String name) {
    return 'Steam active account: $name (Click to switch)';
  }

  @override
  String get steamAccountActiveTag => 'Active';

  @override
  String get steamAccountManualTag => 'Manual';

  @override
  String get steamAccountCurrentLogin => 'Current Steam Login';

  @override
  String get roomSteamMismatchDesc =>
      'Identity mismatch causes connection failures or routing errors. Syncing with Isaac is recommended.';

  @override
  String get roomSteamSyncSuccess =>
      'Synced with Isaac account and reconnected';

  @override
  String get roomSteamSyncFailed => 'Sync failed';

  @override
  String get settingsLanguageFollowSystem => 'System Default';

  @override
  String get dialogJoinRoomTitle => 'Join Room';

  @override
  String get dialogJoinRoomHint => 'Enter 16 or 32-character Join Code';

  @override
  String get dialogJoinRoomConfirm => 'Join';

  @override
  String get dialogReplaceRoomTitle => 'Switch & Join Room';

  @override
  String get dialogReplaceRoomPrompt =>
      'Leaving the current room will end your active game session. Continue?';

  @override
  String get dialogSwitchHistoryTitle => 'Switch Room';

  @override
  String get dialogSwitchHistoryPrompt =>
      'Switching rooms will leave the current room and end any active game session. Continue?';

  @override
  String get dialogSwitchSteamInRoomTitle => 'Switch Steam Account in Room';

  @override
  String dialogSwitchSteamInRoomPrompt(String extra) {
    return 'Switching Steam account will leave the current room$extra. Continue?';
  }

  @override
  String get dialogSwitchSteamEndSession => ' and end the game session';

  @override
  String get dialogCreateLanTitle => 'Create LAN Game';

  @override
  String get dialogCreateLanSubtitle =>
      'Select network adapters for direct LAN play (up to 8)';

  @override
  String get dialogCreateLanConfirm => 'Create LAN Room';

  @override
  String get dialogAddRelayTitle => 'Add Relay Node';

  @override
  String get dialogEditRelayTitle => 'Edit Relay Node';

  @override
  String get dialogRelayNameLabel => 'Node Name';

  @override
  String get dialogRelayNameHint => 'e.g. East China Fast Node';

  @override
  String get dialogRelayHostLabel => 'Relay Address';

  @override
  String get dialogRelayHostHint => 'e.g. relay.example.com';

  @override
  String get dialogRelayPortLabel => 'Port';

  @override
  String get dialogRelayTransportLabel => 'Supported Transports';

  @override
  String get dialogRelayDefaultTransportLabel => 'Default Transport';

  @override
  String get dialogRelayDeleteConfirmTitle => 'Delete Relay Node';

  @override
  String get dialogRelayDeleteConfirmPrompt =>
      'Are you sure you want to delete this Relay node? This action cannot be undone.';

  @override
  String get dialogManualSteamTitle => 'Manual Steam Account';

  @override
  String get dialogManualSteamSubtitle =>
      'Specify your Steam identity and name manually when Steam client is not running';

  @override
  String get dialogManualSteamNameLabel => 'Username';

  @override
  String get dialogManualSteamIdLabel => 'SteamID64';

  @override
  String get dialogManualSteamDelete => 'Delete Account';

  @override
  String get dialogManualSteamSave => 'Save & Apply';

  @override
  String get dialogCloseAppTitle => 'Close Tractor Beam';

  @override
  String get dialogCloseAppPrompt =>
      'Do you want to exit completely or hide to system tray to stay connected?';

  @override
  String get dialogCloseAppRoomWarning =>
      'You are in an active room! Hide to tray to stay in the room; choosing Exit will leave and disconnect.';

  @override
  String get dialogCloseAppSessionWarning =>
      'Game is currently running! Hide to tray to stay connected; choosing Exit will immediately disconnect gameplay.';

  @override
  String get dialogLaunchProgressTitle => 'Launching Game';

  @override
  String get dialogLaunchProgressCancel => 'Cancel Launch';

  @override
  String get dialogLaunchCancelConfirmTitle => 'Cancel Game Launch';

  @override
  String get dialogLaunchCancelConfirmPrompt =>
      'Game is starting and preparing injection. Are you sure you want to cancel?';

  @override
  String get dialogLaunchFailureTitle => 'Launch Failed';

  @override
  String get dialogClearLogsTitle => 'Clear Diagnostic Logs';

  @override
  String get dialogClearLogsPrompt =>
      'Are you sure you want to clear all recorded console logs? This cannot be undone.';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageHelpTooltip =>
      'Switch Tractor Beam interface display language (supports Simplified Chinese and English).';

  @override
  String get settingsLanguageZh => '简体中文';

  @override
  String get settingsLanguageZhSub => 'Chinese (Default)';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageEnSub => 'English (US)';

  @override
  String get settingsInputDelayTitle => 'Input Delay';

  @override
  String get settingsInputDelayHelp =>
      'Fine-tune frame buffer delay in non-official modes to balance responsiveness';

  @override
  String get settingsInputDelayLabel => 'Input Delay';

  @override
  String settingsInputDelayFrames(int frames, int ms) {
    return '$frames frames (${ms}ms)';
  }

  @override
  String get settingsInputDelayRead => 'Read from Game';

  @override
  String get settingsInputDelayWrite => 'Write to Game';

  @override
  String get settingsInputDelayOfficialNotice =>
      'Official mode netcode does not require input delay';

  @override
  String get settingsInputDelayNotRunningNotice =>
      'Game not running; launch Isaac to adjust delay';

  @override
  String get settingsInputDelayReadSuccess => 'Input delay read successfully';

  @override
  String get settingsInputDelayWriteSuccess =>
      'Input delay written successfully';

  @override
  String get settingsWorkModeTitle => 'Work Mode';

  @override
  String get settingsWorkModeHelp =>
      'Determines how Hook intercepts and routes gameplay traffic';

  @override
  String get settingsModeOfficial => 'Official';

  @override
  String get settingsModeFallback => 'Fallback';

  @override
  String get settingsModePure => 'Pure';

  @override
  String get settingsModeOfficialTitle => 'Official';

  @override
  String get settingsModeFallbackTitle => 'Fallback';

  @override
  String get settingsModePureTitle => 'Pure';

  @override
  String get settingsInputDelayReading => 'Reading input delay from Isaac...';

  @override
  String get settingsInputDelayWriting => 'Writing input delay to Isaac...';

  @override
  String get settingsModeOfficialDesc =>
      'Pure Steam P2P mode, bridge only monitors session';

  @override
  String get settingsModeFallbackDesc =>
      'Relay first, automatic fallback to Steam P2P on errors';

  @override
  String get settingsModePureDesc =>
      'Full traffic takeover for lowest latency and stability (Recommended)';

  @override
  String get settingsWorkModeSavedRestartHint =>
      'Settings saved; restart Isaac to apply new mode';

  @override
  String get settingsTransportProtocolTitle => 'Transport Protocol';

  @override
  String get settingsTransportProtocolHelp =>
      'Default packet transport protocol for Relay sessions';

  @override
  String get settingsProtocolAuto => 'Default (UDP)';

  @override
  String get settingsProtocolUdp => 'UDP Protocol';

  @override
  String get settingsProtocolTcp => 'TCP Protocol';

  @override
  String get settingsRestoreDefaults => 'Restore Defaults';

  @override
  String get settingsRestoreDefaultsSuccess => 'Default settings restored';

  @override
  String get settingsProtocolAutoSub => 'Server Default';

  @override
  String get settingsProtocolUdpSub => 'Low Latency';

  @override
  String get settingsProtocolTcpSub => 'High Compatibility';

  @override
  String get settingsModeOfficialSub => 'Official Route';

  @override
  String get settingsModeFallbackSub => 'Prefer TB';

  @override
  String get settingsModePureSub => 'Pure TB';

  @override
  String settingsInputDelayApplied(int frames) {
    return 'Active: $frames';
  }

  @override
  String get settingsInputDelayAdjustHint =>
      'Increase when network is unstable';

  @override
  String get settingsProtocolHelpTooltip =>
      'Transport Protocol:\nDefault: Automatically determined by relay capabilities\nUDP: Low latency, sensitive to jitter\nTCP: High penetration, stable and easy to connect';

  @override
  String get settingsModeHelpTooltip =>
      'Work Mode:\nOfficial: Pure official routing without TB relay\nFallback: Prefer TB relay, fall back to official P2P if blocked\nPure: Force all traffic through TB relay';

  @override
  String get settingsInputDelayHelpTooltip =>
      'Input Delay (0-5 frames):\nLower delay feels more responsive; increase during jitter/packet loss for smoothness.\nOfficial mode is managed by game\'s own netcode and cannot be tuned.';

  @override
  String get statsTitle => 'Statistics & Diagnostics';

  @override
  String get statsConnectionQuality => 'Connection Quality';

  @override
  String get statsPacketStats => 'Packet Statistics';

  @override
  String get statsHookStatus => 'Hook Status';

  @override
  String get statsRefreshHook => 'Refresh IPC';

  @override
  String get statsTestLatency => 'Test Ping';

  @override
  String get logsTitle => 'Console Logs';

  @override
  String get logsFilterAll => 'All';

  @override
  String get logsFilterInfo => 'Info';

  @override
  String get logsFilterWarn => 'Warn';

  @override
  String get logsFilterError => 'Error';

  @override
  String get logsAutoScroll => 'Auto-scroll';

  @override
  String get logsClear => 'Clear Logs';

  @override
  String get logsExport => 'Export Diagnostics';

  @override
  String get logsSearchHint => 'Search logs / keywords...';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutProjectDesc =>
      'High-performance, low-latency co-op tool for The Binding of Isaac: Repentance+';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutOpenSource => 'Repository';

  @override
  String aboutLicense(String license) {
    return 'Open Source License ($license)';
  }

  @override
  String get aboutDiagnosticTitle => 'Export Diagnostics Bundle';

  @override
  String get aboutDiagnosticDesc =>
      'Export logs and diagnostic info for troubleshooting';

  @override
  String get aboutExportButton => 'Export Diagnostics';

  @override
  String get pleaseJoinRoomFirst => 'Please join a room first';

  @override
  String get errRelayNameRequired => 'Please enter a node name';

  @override
  String get errRelayHostRequired => 'Please enter a relay address';

  @override
  String get errRelayPortRange => 'Port must be an integer between 1 and 65535';

  @override
  String get errRelayProtocolRequired =>
      'Must select at least one transport protocol (TCP/UDP)';

  @override
  String dialogRelayDeletePrompt(String relayName) {
    return 'Are you sure you want to delete node \"$relayName\"?\nThis cannot be undone.';
  }

  @override
  String get dialogConfirmDelete => 'Delete';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogSave => 'Save';

  @override
  String get dialogDelete => 'Delete';

  @override
  String get dialogClose => 'Close';

  @override
  String get dialogClearLogsPromptDetailed =>
      'Are you sure you want to clear current logs?\nHistorical logs in memory will be permanently removed.';

  @override
  String get dialogClearLogsConfirm => 'Clear';

  @override
  String get dialogExitAppTitle => 'Exit Tractor Beam';

  @override
  String get dialogExitSessionRunningWarning =>
      'The game is currently running. Exiting will immediately terminate the session and disconnect. Are you sure?';

  @override
  String get dialogExitRoomWarning =>
      'You are currently in a room. Exiting will leave the room (and close it if you are host). Are you sure?';

  @override
  String get dialogExitPrompt => 'Are you sure you want to exit Tractor Beam?';

  @override
  String get dialogExitButton => 'Exit';

  @override
  String get dialogCloseAppHideToTray => 'Hide to Tray';

  @override
  String get dialogCloseAppFullExit => 'Exit Completely';

  @override
  String get dialogReplaceRoomExitAndJoin => 'Leave & Join';

  @override
  String get dialogSwitchRoomConfirm => 'Confirm Switch';

  @override
  String get dialogSwitchSteamLanPrompt =>
      'Currently in a LAN direct room. Switching Steam accounts requires leaving the current room. Recreate or rejoin with your new identity afterward. Leave and switch?';

  @override
  String get dialogSwitchSteamRelayPrompt =>
      'Currently in a Relay room. Switching Steam accounts will reconnect to this relay room with the new identity. If Isaac is running, you will need to reconnect in-game. Continue?';

  @override
  String get dialogSwitchSteamConfirm => 'Confirm Switch';

  @override
  String get dialogJoinRoomByCodePrompt =>
      'Enter the TB-NET room code provided by the host:';

  @override
  String get dialogJoinRoomCodeLabel => 'Room Code';

  @override
  String get dialogLanEndpointTitle => 'Select LAN Endpoint';

  @override
  String get dialogLanEndpointPrompt =>
      'Multiple reachable addresses detected. Please select an endpoint to connect:';

  @override
  String get dialogLanEndpointConnect => 'Connect';

  @override
  String get dialogLanAdaptersPrompt => 'Available Network Adapters for LAN';

  @override
  String get dialogLanNoAdapters => 'No available network adapters found';

  @override
  String dialogLanSelectedCount(int count) {
    return 'Selected: $count/8';
  }

  @override
  String get dialogCreateButton => 'Create';

  @override
  String get dialogDeleteSteamAccountTitle => 'Delete Steam Account';

  @override
  String dialogDeleteSteamAccountPrompt(String username, String steamId64) {
    return 'Are you sure you want to delete manual account \"$username\" ($steamId64)?\nYou will need to re-enter it manually later.';
  }

  @override
  String get errSteamIdRequired => 'SteamID64 cannot be empty';

  @override
  String get errSteamIdInvalid => 'SteamID64 must be 17 digits and non-zero';

  @override
  String get errSteamUsernameRequired => 'Username cannot be empty';

  @override
  String get dialogManualSteamSavedAccounts => 'Saved Manual Accounts';

  @override
  String get dialogManualSteamIdInputHint => '17-digit SteamID64';

  @override
  String get dialogManualSteamNameInputHint => 'Enter Steam username';

  @override
  String get dialogLaunchCancelFailed =>
      'Unable to cancel launch right now, please try again';

  @override
  String get dialogLaunchFailedGeneric => 'Game failed to launch';

  @override
  String get dialogLaunchGoToLogs => 'Go to Logs';

  @override
  String get dialogLaunchStepStarting => 'Preparing launch arguments';

  @override
  String get dialogLaunchStepWaitingForGame => 'Waiting for game process';

  @override
  String get dialogLaunchStepInjecting => 'Injecting TractorBeam Hook';

  @override
  String get dialogLaunchStepWaitingForHook => 'Connecting to Hook endpoint';

  @override
  String get dialogLaunchStepReady => 'Game and Hook ready';

  @override
  String get dialogLaunchCancelling => 'Cancelling launch...';

  @override
  String get dialogLaunchCancelled => 'Launch cancelled';

  @override
  String get dialogLaunchSuccess => 'Launch successful';

  @override
  String get dialogLaunchPreparing => 'Preparing to launch game...';

  @override
  String get dialogLaunchCancellingButton => 'Cancelling…';

  @override
  String get dialogLaunchCancelButton => 'Cancel Launch';

  @override
  String get dialogLaunchStepCompleted => 'Completed';

  @override
  String get dialogLaunchStepInProgress => 'In progress';

  @override
  String get dialogLaunchStepPending => 'Pending';

  @override
  String get dialogLaunchNotStarted => 'Game not yet launched';

  @override
  String get dialogLaunchConfigured => 'Launch parameters configured';

  @override
  String get dialogLaunchWaitingForGame => 'Waiting for game process...';

  @override
  String get dialogLaunchInjectingHook => 'Game detected, injecting Hook...';

  @override
  String get dialogLaunchConnectingHook =>
      'Injection complete, connecting to Hook...';

  @override
  String get dialogLaunchHookReady => 'Game and Hook ready';

  @override
  String get dialogLaunchStoppingProcess =>
      'Stopping TractorBeam launch process...';

  @override
  String get dialogLaunchErrIsaacAlreadyRunning =>
      'The Binding of Isaac is already running. Please exit Isaac completely before launching.';

  @override
  String get dialogLaunchErrPreviousHookPresent =>
      'Previous Hook instance detected in game. Please exit the game completely and try again.';

  @override
  String get dialogLaunchErrCannotChangeMode =>
      'Cannot change mode while Isaac is running. Please exit the game completely and try again.';

  @override
  String get dialogLaunchErrLaunchInProgress =>
      'Game launch is currently in progress, please wait.';

  @override
  String get dialogLaunchErrInsufficientPermissions =>
      'Insufficient injection permissions. Please close blocking programs or run as administrator.';

  @override
  String get dialogLaunchErrProcessNotFound =>
      'Isaac game process was not found. Please confirm the game launched properly.';

  @override
  String get dialogLaunchErrMissingComponents =>
      'Required injection components are missing. Please verify your program files.';

  @override
  String get dialogLaunchErrCannotPrepareParams =>
      'Unable to prepare Hook parameters. Please check directory write permissions.';

  @override
  String get dialogLaunchErrCannotBindEndpoint =>
      'Unable to bind local Hook endpoint. Please close old game processes and try again.';

  @override
  String get dialogLaunchErrSteamApiTakeoverFailed =>
      'Hook could not take over Steam API. Please exit the game completely and try again.';

  @override
  String get dialogLaunchErrNetworkHookInstallFailed =>
      'Hook could not install networking features. Please exit the game completely and try again.';

  @override
  String get dialogLaunchErrTimeout =>
      'Timed out waiting for game or Hook to be ready. Please make sure the game launched properly.';

  @override
  String get dialogLaunchErrElevationCancelled =>
      'Administrator elevation was cancelled. Hook injection cannot proceed.';

  @override
  String get dialogLaunchErrSteamLaunchFailed =>
      'Unable to launch game via Steam. Please make sure Steam is running.';

  @override
  String get dialogLaunchErrUnsupportedPlatform =>
      'Current operating system does not support native Hook injection.';

  @override
  String get dialogLaunchErrCannotReattach =>
      'Cannot reattach or detach from current game runtime. Please exit the game completely and try again.';

  @override
  String get dialogLaunchErrHookRuntimeTerminated =>
      'Hook runtime has terminated. Please restart the game.';

  @override
  String get dialogLaunchErrFileNotFound =>
      'The system cannot find the file specified. Please check game or component integrity.';

  @override
  String get dialogLaunchErrWaitTimeout120 =>
      'Launch wait exceeded 120 seconds and was stopped. Please check game and Steam status and try again.';

  @override
  String get dialogLaunchErrUnknown =>
      'Game failed to launch normally. No detailed error message was returned.';

  @override
  String get dialogLaunchErrOpenProcessFailed =>
      'Hook injection failed: Unable to open Isaac process (try running as administrator or check antivirus).';

  @override
  String get dialogLaunchErrCreateRemoteThreadFailed =>
      'Hook injection failed: Unable to create remote thread (may be blocked by security software).';

  @override
  String get dialogLaunchErrAllocMemoryFailed =>
      'Hook injection failed: Unable to allocate remote memory in Isaac process.';

  @override
  String get dialogLaunchErrWriteDllPathFailed =>
      'Hook injection failed: Unable to write DLL path to game process.';

  @override
  String get dialogLaunchErrInjectionGenericFailed =>
      'Hook injection failed. Try running as administrator or check antivirus.';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowMaximize => 'Maximize';

  @override
  String get windowRestore => 'Restore';

  @override
  String get windowClose => 'Close';

  @override
  String get latencyGradeExcellent => 'Excellent';

  @override
  String get latencyGradeFair => 'Fair';

  @override
  String get latencyGradePoor => 'Poor';

  @override
  String get latencyGradeSevere => 'Severe';

  @override
  String latencyTestComplete(int latency, String grade) {
    return 'Latency test completed: ${latency}ms ($grade)';
  }

  @override
  String relayAddedAndSwitched(String name) {
    return 'Added and switched to node: $name';
  }

  @override
  String relayUpdatedNotice(String name) {
    return 'Node updated: $name';
  }

  @override
  String get aboutIdentityHelp =>
      'Tractor Beam version, original architecture, and core protocol specifications';

  @override
  String get aboutIdentitySlogan =>
      'Lightweight online play bridge built for The Binding of Isaac: Repentance+';

  @override
  String get aboutAuthor => 'Project Author';

  @override
  String get aboutUiDesigner => 'UI Redesign';

  @override
  String get aboutVersionLabel => 'Version ID';

  @override
  String get aboutVersionHelp =>
      'Click to copy client version and diagnostic info';

  @override
  String get aboutCopiedVersionNotice =>
      'Client version and diagnostic info copied to clipboard';

  @override
  String get aboutCoreProtocol => 'Core Protocol';

  @override
  String get aboutLinksTitle => 'Open Source & Links';

  @override
  String get aboutLinksHelp =>
      'Flutter client repository and official upstream repository';

  @override
  String get aboutSourceRepo => 'Flutter Client Source (GitHub)';

  @override
  String get aboutRefactorRepo => 'Official Upstream (GitHub)';

  @override
  String get aboutRefactorRepoPending =>
      'UI refactoring project coming soon. Repository will be linked once published.';

  @override
  String get aboutRefactorRepoBadge => 'Reserved';

  @override
  String get aboutReleases => 'Releases (GitHub)';

  @override
  String get aboutIssues => 'Issues & Feedback';

  @override
  String aboutLinkCopiedNotice(String title) {
    return 'Copied $title link to clipboard';
  }

  @override
  String aboutLinkCopiedDirect(String title) {
    return 'Copied $title link';
  }

  @override
  String get aboutThanksTitle => 'Acknowledgements';

  @override
  String get aboutThanksHelp =>
      'Thanks to everyone who helped develop, test, and improve Tractor Beam';

  @override
  String get aboutThanksIntro =>
      'Thank you to every friend who helped make Tractor Beam better';

  @override
  String get aboutContributors => '●  Core Contributors';

  @override
  String get aboutEarlyTesters => '●  Early Testers';

  @override
  String get aboutTagTester => 'Tester';

  @override
  String get aboutTagContributor => 'Contributor';

  @override
  String get aboutOtherAnonymous => 'Other Anonymous Players';

  @override
  String get statsSessionQualityTitle => 'Session Quality';

  @override
  String get statsSessionQualityHelp =>
      'Network smoothness assessment and diagnostic status for the current session';

  @override
  String get statsCountersTitle => 'Counters';

  @override
  String get statsCountersHelp =>
      'Packet and byte throughput statistics between Hook injection and Relay server';

  @override
  String get statsConnectionTestTitle => 'Connection Test';

  @override
  String get statsConnectionTestHelp =>
      'Send lightweight probe packets to test latency and reachability to the selected Relay';

  @override
  String get statsHookIpcTitle => 'Hook IPC Status';

  @override
  String get statsHookIpcHelp =>
      'Real-time IPC communication status between in-game Hook module and this app';

  @override
  String get statsStartSpeedtest => 'Start Test';

  @override
  String get statsSpeedtesting => 'Testing...';

  @override
  String get statsRefreshingHook => 'Refreshing...';

  @override
  String get statsQualityGood => 'Session Quality: Good';

  @override
  String get statsQualityWatch => 'Session Quality: Watch';

  @override
  String get statsQualityPoor => 'Session Quality: Poor';

  @override
  String get statsQualityEvaluating => 'Session Quality: Evaluating';

  @override
  String get statsQualityInactive => 'Session Inactive';

  @override
  String get statsModeOfficial => 'Official Matchmaking';

  @override
  String get statsModePure => 'Pure Mode';

  @override
  String get statsModeFallback => 'Fallback Mode';

  @override
  String statsRoomNumber(String code) {
    return 'Room $code';
  }

  @override
  String get statsRoomJoined => 'In Room';

  @override
  String get statsRoomNotJoined => 'Not in Room';

  @override
  String get statsRouteLan => 'LAN Direct';

  @override
  String get statsRouteUnknown => 'Unknown Route';

  @override
  String get statsRouteRelay => 'Relay';

  @override
  String statsRouteRelayNode(String node) {
    return 'Relay ($node)';
  }

  @override
  String get statsTransportAuto => 'Auto';

  @override
  String get statsLabelMode => 'Mode';

  @override
  String get statsLabelRoomStatus => 'Room Status';

  @override
  String get statsLabelRouteNode => 'Route / Node';

  @override
  String get statsLabelTransport => 'Transport';

  @override
  String statsHealthDiagnostic(String health) {
    return 'Health: $health';
  }

  @override
  String statsLastStopReason(String reason) {
    return 'Last Stop: $reason';
  }

  @override
  String get statsCounterHookToRelay => 'Hook -> Relay';

  @override
  String get statsCounterBytesReceived => 'Bytes Received';

  @override
  String get statsCounterRelayToHook => 'Relay -> Hook';

  @override
  String get statsCounterErrors => 'Errors';

  @override
  String get statsCounterBytesSent => 'Bytes Sent';

  @override
  String get statsCounterReconnectDrops => 'Drops on Reconnect';

  @override
  String get statsNoTestRecords => 'No speedtest records yet';

  @override
  String get statsNoTestRecordsPrompt =>
      'Click \'Start Test\' above to probe latency and reachability to the selected Relay';

  @override
  String get statsTableHeaderNode => 'Node';

  @override
  String get statsTableHeaderTransport => 'Transport';

  @override
  String get statsTableHeaderPackets => 'Tx/Rx';

  @override
  String get statsTableHeaderLoss => 'Loss';

  @override
  String get statsTableHeaderLatency => 'Latency';

  @override
  String get statsTestTimeout => 'Timeout';

  @override
  String get statsTableHeaderStatus => 'Status';

  @override
  String get statsTableHeaderVersion => 'Version';

  @override
  String get statsTableHeaderReconnects => 'Reconnects';

  @override
  String get statsTableHeaderDrops => 'Dropped (Hook/App)';

  @override
  String get statsTableHeaderBadFrames => 'Bad Frames';

  @override
  String get statsHookRefreshFailed => 'Failed to refresh Hook status';

  @override
  String get statsHookRefreshSuccess => 'Hook status refreshed';

  @override
  String get statsSelectRelayPrompt =>
      'Please select a Relay node on the Home page first';

  @override
  String get statsSpeedtestRejected => 'Speedtest request was not accepted';

  @override
  String get logsLevelAll => 'ALL';

  @override
  String get logsLevelTrace => 'TRACE';

  @override
  String get logsLevelDebug => 'DEBUG';

  @override
  String get logsLevelInfo => 'INFO';

  @override
  String get logsLevelWarn => 'WARN';

  @override
  String get logsLevelError => 'ERROR';

  @override
  String get logsExportBundle => 'Export Bundle';

  @override
  String get logsExportBundleTooltip => 'Export full diagnostic archive (ZIP)';

  @override
  String get logsExportingNotice => 'Exporting diagnostic bundle...';

  @override
  String get logsOpenFolder => 'Open Folder';

  @override
  String get logsOpenFolderTooltip =>
      'Open local log and diagnostics directory';

  @override
  String get logsOpeningFolderNotice => 'Opening log folder...';

  @override
  String get logsClearTooltip => 'Clear current session logs';

  @override
  String get logsClearedNotice => 'Logs cleared';

  @override
  String logsShowingCount(int visible, int total) {
    return 'Showing $visible / $total entries';
  }

  @override
  String get logsSearchButton => 'Search';

  @override
  String get logsCopyAll => 'Copy All';

  @override
  String get logsAutoScrollOn => 'Auto-scroll: On';

  @override
  String get logsAutoScrollPaused => 'Auto-scroll: Paused';

  @override
  String logsEmptyNoMatch(String query) {
    return 'No logs matching \'$query\'';
  }

  @override
  String get logsEmptyNoRecords => 'No logs recorded yet';

  @override
  String get logsCopyLine => 'Copy line';

  @override
  String get logsNoCopyableLogs => 'No logs to copy';

  @override
  String logsCopiedCount(int count) {
    return 'Copied $count log entries';
  }

  @override
  String get logsCopiedSingle => 'Log entry copied';

  @override
  String get logsCopyFailed => 'Failed to copy to clipboard';

  @override
  String get logsAlreadyEmpty => 'No logs to clear';

  @override
  String get dialogUdpFallbackTitle => 'Could not connect over UDP';

  @override
  String get dialogUdpFallbackBody =>
      'This network may restrict UDP traffic. You can retry this connection over TCP, which is usually more compatible but may add some latency. This retry will not change your default protocol.';

  @override
  String get dialogUdpFallbackRetry => 'Retry with TCP';

  @override
  String get dialogUdpFallbackSettings => 'Open Settings';

  @override
  String get udpTcpRetryStarted => 'Retrying the connection over TCP…';

  @override
  String get udpTcpRetryFailed => 'Could not start the TCP retry';

  @override
  String latencyBatchComplete(int successful, int total) {
    return 'Relay test complete: $successful/$total servers available';
  }

  @override
  String latencyBatchAllFailed(int total) {
    return 'Relay test complete: none of $total servers could be reached';
  }

  @override
  String get lightweightBackToMain => '← Main UI';

  @override
  String get lightweightApplyDelay => 'Apply';

  @override
  String framesCount(int frames) {
    String _temp0 = intl.Intl.pluralLogic(
      frames,
      locale: localeName,
      other: '$frames frames',
      one: '1 frame',
    );
    return '$_temp0';
  }
}
