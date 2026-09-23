import 'package:flutter/widgets.dart';

import '../bridge/generated/api.dart' as bridge;
import 'l10n.dart';

String localizeBridgeEvent(
  BuildContext context,
  bridge.AppEvent? event, {
  String? fallback,
}) {
  if (event == null) return fallback ?? context.l10n.genericError;
  final l10n = context.l10n;
  return switch (event.message.key) {
    'rejection.queue_busy' || 'event.command_rejected.failure' => l10n.busy,
    'event.room_restore_lan.failure' => l10n.roomRestoreLanFailed,
    'event.room_restore_relay.failure' => l10n.roomRestoreRelayFailed,
    'event.room_restore_lan.manual_required' =>
      l10n.roomRestoreLanManualRequired,
    'event.room_restore_relay.timeout' => l10n.roomRestoreRelayTimeout,
    'event.room_left.success' => l10n.roomLeftSuccess,
    'event.relay_room_joined.success' ||
    'event.lan_room_joined.success' => l10n.connected,
    'event.lan_room_created.success' => l10n.roomCreatedSuccess,
    'event.relay_room_joined.room_full' => l10n.roomJoinRoomFull,
    'event.relay_room_joined.relay_full' => l10n.roomJoinRelayFull,
    'event.relay_room_joined.invalid_admission' =>
      l10n.roomJoinInvalidAdmission,
    'event.relay_room_joined.dns_failed' => l10n.roomJoinDnsFailed,
    'event.relay_room_joined.connection_refused' =>
      l10n.roomJoinConnectionRefused,
    'event.relay_room_joined.timeout' => l10n.roomJoinTimeout,
    'event.relay_room_joined.network_unreachable' =>
      l10n.roomJoinNetworkUnreachable,
    'event.relay_room_joined.connection_reset' =>
      l10n.roomJoinConnectionReset,
    'event.relay_room_joined.udp_unavailable' => l10n.roomJoinUdpUnavailable,
    'event.relay_room_joined.failure' ||
    'event.lan_room_joined.failure' =>
      event.displayText.trim().isNotEmpty
          ? event.displayText
          : l10n.roomJoinFailed,
    'event.lan_room_created.failure' => l10n.roomCreateFailed,
    'event.input_delay_read.success' => l10n.settingsInputDelayReadSuccess,
    'event.input_delay_written.success' => l10n.settingsInputDelayWriteSuccess,
    'event.relay_deleted.success' => l10n.relayDeleted,
    'event.latency_test_result.success' => () {
      final match = RegExp(r'(\d+)').firstMatch(event.displayText);
      final latency = match != null ? int.tryParse(match.group(1)!) : null;
      return latency != null
          ? l10n.latencyComplete(latency)
          : event.displayText;
    }(),
    'event.latency_test_result.failure' =>
      event.displayText.contains('超时') ||
              event.displayText.contains('timed out')
          ? l10n.latencyTimeout
          : l10n.latencyUnavailable,
    'event.latency_test_batch_result.success' ||
    'event.latency_test_batch_result.failure' => () {
      final parts = event.value?.split(',');
      final successful = parts == null ? null : int.tryParse(parts.first);
      final total = parts == null || parts.length < 2
          ? null
          : int.tryParse(parts[1]);
      if (successful == null || total == null) return event.displayText;
      return successful > 0
          ? l10n.latencyBatchComplete(successful, total)
          : l10n.latencyBatchAllFailed(total);
    }(),
    _ => _fallback(context, event.message, event.code, fallback: fallback),
  };
}

String localizeBridgeRejection(
  BuildContext context,
  bridge.CommandRejection? rejection, {
  String? fallback,
}) {
  if (rejection == null) return fallback ?? context.l10n.genericError;
  final l10n = context.l10n;
  return switch (rejection.message.key) {
    'rejection.room_already_active' => l10n.errRoomAlreadyActive,
    'rejection.account_required' => l10n.errAccountRequired,
    'rejection.session_running' => l10n.errSessionRunning,
    'rejection.lan_adapter_required' => l10n.errLanAdapterRequired,
    'rejection.too_many_lan_adapters' => l10n.errTooManyLanAdapters,
    'rejection.launch_not_active' => l10n.errLaunchNotActive,
    'rejection.launch_cancel_pending' => l10n.errLaunchCancelPending,
    'rejection.queue_busy' ||
    'rejection.command_rejected' ||
    'rejection.latency_test_running' => l10n.busy,
    'rejection.publisher_unavailable' => l10n.errPublisherUnavailable,
    'rejection.already_initialized' => l10n.errAlreadyInitialized,
    'rejection.not_initialized' => l10n.errNotInitialized,
    'rejection.input_delay_unsupported' => l10n.errInputDelayUnsupported,
    'rejection.hook_not_ready' => l10n.errInputDelayHookNotReady,
    'rejection.hook_busy' => l10n.errInputDelayHookBusy,
    'rejection.input_delay_timeout' => l10n.errInputDelayTimedOut,
    'rejection.input_delay_failed' => l10n.errInputDelayGeneric,
    'rejection.config_save_failed' => l10n.errConfigSaveFailed,
    'rejection.relay_save_failed' => l10n.errRelaySaveFailed,
    'rejection.lan_probe_failed' => l10n.errLanProbeFailed,
    'rejection.lan_unreachable' => l10n.errLanUnreachable,
    _ => _fallback(
      context,
      rejection.message,
      rejection.code,
      fallback: fallback,
    ),
  };
}

String? localizeBridgeMessage(BuildContext context, String? text) {
  if (text == null) return null;
  final l10n = context.l10n;
  final trimmed = text.trim();
  return switch (trimmed) {
    '准备启动参数' ||
    '启动参数已配置' ||
    'Preparing launch arguments' ||
    'Launch arguments configured' ||
    'Launch parameters configured' =>
      l10n.dialogLaunchConfigured,

    '等待游戏进程' ||
    '正在等待游戏进程' ||
    'Waiting for game process' ||
    'Waiting for game process...' =>
      l10n.dialogLaunchWaitingForGame,

    '注入 TractorBeam Hook' ||
    '已发现游戏，正在注入 Hook' ||
    'Injecting TractorBeam Hook' ||
    'Game detected, injecting Hook...' =>
      l10n.dialogLaunchInjectingHook,

    '连接 Hook 通信端点' ||
    '注入完成，正在连接 Hook' ||
    'Connecting to Hook endpoint' ||
    'Injection complete, connecting to Hook...' ||
    'Injection completed, connecting to Hook...' =>
      l10n.dialogLaunchConnectingHook,

    '游戏与 Hook 就绪' ||
    '游戏与 Hook 已就绪' ||
    'Game and Hook ready' =>
      l10n.dialogLaunchHookReady,

    '正在启动以撒游戏…' ||
    'Launching The Binding of Isaac…' =>
      l10n.dialogLaunchProgressTitle,

    '正在准备启动游戏' ||
    'Preparing to launch game...' =>
      l10n.dialogLaunchPreparing,

    '尚未启动游戏' ||
    'Game not yet launched' =>
      l10n.dialogLaunchNotStarted,

    '正在停止 TractorBeam 启动流程' ||
    'Stopping TractorBeam launch process...' =>
      l10n.dialogLaunchStoppingProcess,

    '游戏启动已取消' ||
    '启动已取消' ||
    '正在取消启动' ||
    '正在取消启动...' ||
    'Cancelling launch...' ||
    'Launch cancelled' ||
    'Game launch cancelled' =>
      l10n.dialogLaunchCancelled,

    '启动游戏失败' ||
    '启动失败' ||
    'Game Launch Failed' ||
    'Launch Failed' =>
      l10n.dialogLaunchFailureTitle,

    '游戏未能启动' ||
    '游戏启动失败' ||
    'Game failed to launch' =>
      (Localizations.localeOf(context).languageCode == 'en')
          ? l10n.dialogLaunchFailedGeneric
          : '游戏启动失败',

    '暂时无法取消启动，请稍后重试' ||
    'Unable to cancel launch right now, please try again' =>
      l10n.dialogLaunchCancelFailed,

    // Launch error details emitted by Rust
    '以撒游戏已在运行中。请先完全退出以撒，然后重新点击启动游戏。' =>
      l10n.dialogLaunchErrIsaacAlreadyRunning,
    '检测到上一次的 Hook 仍留在游戏中。请完全退出游戏后再试。' =>
      l10n.dialogLaunchErrPreviousHookPresent,
    '以撒运行期间无法更改工作模式，请完全退出游戏后重试。' =>
      l10n.dialogLaunchErrCannotChangeMode,
    '游戏启动流程正在进行中，请稍候。' =>
      l10n.dialogLaunchErrLaunchInProgress,
    '注入权限不足。请关闭可能阻止注入的程序，或尝试以管理员身份运行。' =>
      l10n.dialogLaunchErrInsufficientPermissions,
    '未发现以撒游戏进程，请确认游戏是否已正常启动。' =>
      l10n.dialogLaunchErrProcessNotFound,
    '缺少启动所需的注入组件，请检查程序文件是否完整。' =>
      l10n.dialogLaunchErrMissingComponents,
    '无法准备 Hook 启动参数，请检查程序目录的写入权限。' =>
      l10n.dialogLaunchErrCannotPrepareParams,
    '无法建立本地 Hook 通信端点，请关闭旧的游戏进程后重试。' =>
      l10n.dialogLaunchErrCannotBindEndpoint,
    'Hook 无法接管 Steam API。请完全退出游戏后重试。' =>
      l10n.dialogLaunchErrSteamApiTakeoverFailed,
    'Hook 无法安装网络功能。请完全退出游戏后重试。' =>
      l10n.dialogLaunchErrNetworkHookInstallFailed,
    '等待游戏或 Hook 就绪超时，请确认游戏已正常启动后重试。' =>
      l10n.dialogLaunchErrTimeout,
    '已取消管理员提权授权，无法完成 Hook 注入。' =>
      l10n.dialogLaunchErrElevationCancelled,
    '无法通过 Steam 启动游戏，请确认 Steam 正在运行。' =>
      l10n.dialogLaunchErrSteamLaunchFailed,
    '当前操作系统平台暂不支持原生 Hook 注入。' =>
      l10n.dialogLaunchErrUnsupportedPlatform,
    '当前游戏运行时无法重新附加或分离，请完全退出游戏后重试。' =>
      l10n.dialogLaunchErrCannotReattach,
    'Hook 运行时已终止，请重新启动游戏。' =>
      l10n.dialogLaunchErrHookRuntimeTerminated,
    '系统找不到指定的文件，请检查游戏或注入组件完整性。' =>
      l10n.dialogLaunchErrFileNotFound,
    '启动等待超过 120 秒，本次启动已停止。请确认游戏和 Steam 状态后重试。' =>
      l10n.dialogLaunchErrWaitTimeout120,
    '游戏未能正常启动，未获取到具体错误信息。' =>
      l10n.dialogLaunchErrUnknown,
    'Hook 注入失败：无法打开以撒进程（请尝试以管理员身份运行或检查杀毒软件拦截）。' =>
      l10n.dialogLaunchErrOpenProcessFailed,
    'Hook 注入失败：无法在游戏中创建注入线程（可能被安全软件拦截）。' =>
      l10n.dialogLaunchErrCreateRemoteThreadFailed,
    'Hook 注入失败：无法为以撒进程分配内存。' =>
      l10n.dialogLaunchErrAllocMemoryFailed,
    'Hook 注入失败：无法向游戏写入注入路径。' =>
      l10n.dialogLaunchErrWriteDllPathFailed,
    'Hook 注入以撒进程失败，请尝试以管理员身份运行或检查杀毒软件拦截。' =>
      l10n.dialogLaunchErrInjectionGenericFailed,

    _ => text,
  };
}

String _fallback(
  BuildContext context,
  bridge.LocalizedMessageDto message,
  String code, {
  String? fallback,
}) {
  if (Localizations.localeOf(context).languageCode == 'zh' &&
      message.fallbackZh.trim().isNotEmpty) {
    return message.fallbackZh;
  }
  if (fallback != null) {
    return fallback;
  }
  // If an English message has a readable fallback or code, format it nicely
  final cleanCode = code
      .replaceAll('rejection.', '')
      .replaceAll('event.', '')
      .replaceAll('_', ' ');
  return '${context.l10n.genericError} ($cleanCode)';
}
