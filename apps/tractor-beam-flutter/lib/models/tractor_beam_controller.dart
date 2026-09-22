import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../bridge/generated/api.dart' as bridge;
import 'request_cache.dart';

enum ConnectionMode { relay, lan }

/// The single Flutter-side projection of the Rust application state.
///
/// Rust owns all business state. This controller only keeps the latest monotonic
/// snapshot plus UI-only route selection used before a room is created.
class TractorBeamController extends ChangeNotifier {
  TractorBeamController.detached() {
    _lanAdapterCache = RequestCache<List<bridge.LanAdapterDto>>(
      loader: () async => null,
      ttl: lanAdapterCacheTtl,
    );
  }

  TractorBeamController.native() {
    _lanAdapterCache = RequestCache<List<bridge.LanAdapterDto>>(
      loader: _requestLanAdapters,
      ttl: lanAdapterCacheTtl,
    );
    _subscription = bridge.updates().listen(
      _acceptUpdate,
      onError: (Object error, StackTrace stack) {
        _bridgeError = error.toString();
        notifyListeners();
      },
    );
  }

  StreamSubscription<bridge.AppUpdate>? _subscription;
  bridge.AppSnapshot? _snapshot;
  bridge.AppEvent? _latestEvent;
  String? _bridgeError;
  BigInt _revision = BigInt.from(-1);
  int _eventSerial = 0;
  ConnectionMode _connectionMode = ConnectionMode.relay;
  static const Duration lanAdapterCacheTtl = Duration(seconds: 30);
  late final RequestCache<List<bridge.LanAdapterDto>> _lanAdapterCache;
  Completer<List<bridge.LanAdapterDto>?>? _lanAdaptersCompleter;
  BigInt _inputDelayReadGeneration = BigInt.from(-1);
  bool _disposed = false;
  BigInt? _pendingHistoryRoomId;
  String? _pendingJoinCode;
  bool _autoRestoreAttempted = false;
  bool _autoRestoreInFlight = false;
  int _autoRestoreAttempts = 0;
  Timer? _autoRestoreRetryTimer;
  Timer? _autoRestoreWatchdogTimer;
  bool _initialRelayProbeAttempted = false;
  int _initialRelayProbeAttempts = 0;
  Timer? _initialRelayProbeTimer;
  bool _latencyTestPending = false;
  bool _latencyTestStarted = false;
  Set<String> _latencyTestRelayIds = const {};
  Timer? _latencyTestTimeoutTimer;
  String _demoNode = '上海 BGP 极速节点 01';
  String _demoHost = 'relay.sh.net:19842';
  String _demoPort = '19842';
  int _demoLatency = 24;
  bool _demoTcp = true;
  bool _demoUdp = true;
  String _demoDefaultTransport = 'UDP';

  bridge.AppSnapshot? get snapshot => _snapshot;
  bridge.LaunchProgressDto? get launchProgress => _snapshot?.launch;
  bridge.AppEvent? get latestEvent => _latestEvent;
  String? get bridgeError => _bridgeError ?? _snapshot?.bootstrapError;
  BigInt get revision => _revision;
  int get eventSerial => _eventSerial;
  ConnectionMode get connectionMode => _connectionMode;
  bool get isNative => _subscription != null;
  bool get canMutate => _snapshot?.canMutate ?? false;
  bool get isInRoom => _snapshot?.room.active ?? false;
  bool get isSessionRunning =>
      _snapshot?.session.status == bridge.SessionStatusDto.running;
  bridge.SnapshotProfileDto get snapshotProfile =>
      _snapshot?.profile ?? bridge.SnapshotProfileDto.full;
  LightweightViewState get lightweightViewState => LightweightViewState(
    sessionRunning: isSessionRunning,
    hookReady: _snapshot?.launch.status == bridge.LaunchStatusDto.ready,
    route: _snapshot?.room.route,
    transport: _snapshot?.room.transport,
    members: List<bridge.RoomMemberDto>.unmodifiable(
      _snapshot?.room.members ?? const <bridge.RoomMemberDto>[],
    ),
    roomCode: _snapshot?.room.joinCode,
  );
  bool get isHookReady =>
      _snapshot?.launch.status == bridge.LaunchStatusDto.ready;
  bool get isLaunching => switch (_snapshot?.launch.status) {
    bridge.LaunchStatusDto.starting ||
    bridge.LaunchStatusDto.waitingForGame ||
    bridge.LaunchStatusDto.injecting ||
    bridge.LaunchStatusDto.waitingForHook ||
    bridge.LaunchStatusDto.cancelling => true,
    _ => false,
  };
  String get launchButtonLabel =>
      _snapshot?.launch.status == bridge.LaunchStatusDto.cancelling
      ? '取消中…'
      : isLaunching
      ? '启动中…'
      : isSessionRunning
      ? '游戏运行中'
      : isHookReady
      ? (isInRoom ? '开始联机' : '游戏已就绪')
      : '启动游戏';
  bool get canStartGame =>
      _snapshot == null || (isInRoom && canMutate && !isSessionRunning);

  List<bridge.RelayDto> get relays =>
      _snapshot?.clientConfig.relays ?? const [];
  List<bridge.SteamAccountDto> get accounts =>
      _snapshot?.clientConfig.accounts ?? const [];
  List<bridge.RoomHistoryEntryDto> get roomHistory =>
      _snapshot?.roomHistory ?? const [];
  bridge.RelayDto? get selectedRelay {
    final id = _snapshot?.clientConfig.selectedRelayId;
    for (final relay in relays) {
      if (relay.id == id) return relay;
    }
    return null;
  }

  bridge.SteamAccountDto? get selectedAccount {
    final id = _snapshot?.clientConfig.selectedSteamId64;
    for (final account in accounts) {
      if (account.steamId64 == id) return account;
    }
    return null;
  }

  bridge.SteamIdentityMismatchDto? get steamIdentityMismatch =>
      _snapshot?.room.steamIdentityMismatch;

  bridge.SteamAccountDto? get mostRecentAccount {
    for (final account in accounts) {
      if (account.mostRecent) return account;
    }
    return null;
  }

  String get selectedNode =>
      snapshot == null ? _demoNode : selectedRelay?.name ?? '';
  String get selectedNodeHost => snapshot == null
      ? _demoHost
      : selectedRelay == null
      ? '—'
      : '${selectedRelay!.host}:${selectedRelay!.port}';
  String get nodePort =>
      snapshot == null ? _demoPort : selectedRelay?.port.toString() ?? '—';
  bool get nodeTcp =>
      snapshot == null ? _demoTcp : selectedRelay?.supportsTcp ?? false;
  bool get nodeUdp =>
      snapshot == null ? _demoUdp : selectedRelay?.supportsUdp ?? false;
  String get nodeDefaultTransport => snapshot == null
      ? _demoDefaultTransport
      : switch (selectedRelay?.defaultTransport) {
          bridge.TransportSelection.udp => 'UDP',
          bridge.TransportSelection.tcp => 'TCP',
          _ => '默认',
        };
  bool get isTestingLatency => _latencyTestPending;
  int? get serverLatency {
    if (_snapshot == null) return _demoLatency;
    final selectedId = selectedRelay?.id;
    if (selectedId == null) return null;
    for (final test
        in _snapshot?.connectionTests ?? const <bridge.ConnectionTestDto>[]) {
      if (test.relayId == selectedId && test.medianRttMs != null) {
        return test.medianRttMs!.toInt();
      }
    }
    return null;
  }

  int? relayLatency(String relayId) {
    if (_snapshot == null) return null;
    for (final test in _snapshot!.connectionTests) {
      if (test.relayId == relayId && test.medianRttMs != null) {
        return test.medianRttMs!.toInt();
      }
    }
    return null;
  }

  int? get activeServerLatency =>
      _connectionMode == ConnectionMode.relay && serverLatency != null
      ? serverLatency
      : null;

  void _acceptUpdate(bridge.AppUpdate update) {
    if (update.revision <= _revision) return;
    final previousSnapshot = _snapshot;
    final snapshotChanged = !_appSnapshotsSemanticallyEqual(
      previousSnapshot,
      update.snapshot,
    );
    final hasEvents = update.events.isNotEmpty;
    _revision = update.revision;
    _snapshot = update.snapshot;
    _latestEvent = null;
    if (update.events.isNotEmpty) {
      _latestEvent = update.events.last;
      _eventSerial += 1;
      for (final event in update.events) {
        final completer = _lanAdaptersCompleter;
        if (event.code == 'lan_adapters') {
          if (event.success) {
            final adapters = List<bridge.LanAdapterDto>.unmodifiable(
              update.snapshot.lanAdapters,
            );
            _lanAdapterCache.seed(adapters);
            if (completer != null && !completer.isCompleted) {
              completer.complete(adapters);
            }
          } else if (completer != null && !completer.isCompleted) {
            completer.complete(null);
          }
          _lanAdaptersCompleter = null;
        }
        if (event.code == 'room_left') {
          if (!event.success) {
            _pendingHistoryRoomId = null;
            _pendingJoinCode = null;
          } else if (_pendingHistoryRoomId != null) {
            final historyId = _pendingHistoryRoomId!;
            _pendingHistoryRoomId = null;
            scheduleMicrotask(() => joinHistoryRoom(historyId));
          } else if (_pendingJoinCode != null) {
            final code = _pendingJoinCode!;
            _pendingJoinCode = null;
            scheduleMicrotask(() => joinRoom(code));
          }
        }
        if (event.code == 'latency_test') {
          if (event.success) {
            if (!_latencyTestPending) {
              _latencyTestPending = true;
              final selected = update.snapshot.clientConfig.selectedRelayId;
              _latencyTestRelayIds = selected == null ? const {} : {selected};
              _armLatencyTestTimeout();
            }
            _latencyTestStarted = true;
          } else {
            _finishLatencyTest(success: false, displayText: event.displayText);
          }
        }
        if (_autoRestoreInFlight) {
          if (event.code == 'command_rejected') {
            _autoRestoreWatchdogTimer?.cancel();
            _autoRestoreWatchdogTimer = null;
            _autoRestoreInFlight = false;
            if (identical(_latestEvent, event) ||
                _latestEvent?.code == 'command_rejected') {
              _latestEvent = null;
            }
            _scheduleAutoRestoreRetry();
          } else if ((event.code == 'relay_room_joined' ||
                  event.code == 'lan_room_joined' ||
                  event.code == 'lan_room_created') &&
              event.success) {
            _autoRestoreWatchdogTimer?.cancel();
            _autoRestoreWatchdogTimer = null;
            _autoRestoreInFlight = false;
            _autoRestoreAttempted = true;
          } else if (event.code == 'lan_endpoint_selection_required') {
            // Startup recovery has no interactive endpoint picker. Never
            // leave the authoritative room state waiting indefinitely.
            _abortAutoRestore(
              '无法自动恢复上一次的局域网房间，请从历史记录中手动选择并加入。',
              messageKey: 'event.room_restore_lan.manual_required',
            );
          } else if (!event.success &&
              (event.code == 'relay_room_joined' ||
                  event.code == 'lan_room_joined' ||
                  event.code == 'lan_probe_failed' ||
                  event.code == 'lan_unreachable')) {
            _autoRestoreWatchdogTimer?.cancel();
            _autoRestoreWatchdogTimer = null;
            _autoRestoreInFlight = false;
            _autoRestoreAttempted = true;
            _latestEvent = bridge.AppEvent(
              code: 'room_restore_failed',
              success: false,
              displayText: event.code.startsWith('lan_')
                  ? '无法恢复上一次的局域网房间：原联机码中的端点当前不可达，请让房主重新发送联机码。'
                  : '无法恢复上一次的 Relay 房间，请检查节点和网络后重试。',
              message: bridge.LocalizedMessageDto(
                key: event.code.startsWith('lan_')
                    ? 'event.room_restore_lan.failure'
                    : 'event.room_restore_relay.failure',
                args: const [],
                fallbackZh: event.code.startsWith('lan_')
                    ? '无法恢复上一次的局域网房间：原联机码中的端点当前不可达，请让房主重新发送联机码。'
                    : '无法恢复上一次的 Relay 房间，请检查节点和网络后重试。',
              ),
            );
          }
        }
      }
    }
    if (_latencyTestPending && _latencyTestStarted) {
      final completed = <bridge.ConnectionTestDto>[];
      for (final report in update.snapshot.connectionTests) {
        if (report.relayId != null &&
            _latencyTestRelayIds.contains(report.relayId)) {
          completed.add(report);
        }
      }
      if (_latencyTestRelayIds.isNotEmpty &&
          completed.length >= _latencyTestRelayIds.length) {
        final successful = completed
            .where((report) => report.medianRttMs != null)
            .length;
        _finishLatencyTest(
          success: successful > 0,
          displayText: 'Relay 延迟测试完成：$successful/${completed.length}',
          code: 'latency_test_batch_result',
          value: '$successful,${completed.length}',
        );
      }
    }
    if (snapshotChanged || hasEvents) {
      notifyListeners();
    }
    final launch = update.snapshot.launch;
    if (launch.status == bridge.LaunchStatusDto.ready &&
        launch.generation != _inputDelayReadGeneration) {
      final generation = launch.generation;
      _inputDelayReadGeneration = generation;
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (_disposed ||
            _snapshot?.launch.status != bridge.LaunchStatusDto.ready ||
            _snapshot?.launch.generation != generation ||
            _snapshot?.session.status != bridge.SessionStatusDto.running) {
          return;
        }
        readInputDelay();
      });
    }
    _coordinateStartupActions(update.snapshot);
  }

  @visibleForTesting
  void debugAcceptUpdate(bridge.AppUpdate update) => _acceptUpdate(update);

  void _finishLatencyTest({
    required bool success,
    required String displayText,
    String code = 'latency_test_result',
    String? value,
  }) {
    if (!_latencyTestPending) return;
    _latencyTestPending = false;
    _latencyTestStarted = false;
    _latencyTestRelayIds = const {};
    _latencyTestTimeoutTimer?.cancel();
    _latencyTestTimeoutTimer = null;
    _latestEvent = bridge.AppEvent(
      code: code,
      success: success,
      displayText: displayText,
      message: bridge.LocalizedMessageDto(
        key: code == 'latency_test_batch_result'
            ? 'event.latency_test_batch_result.${success ? 'success' : 'failure'}'
            : success
            ? 'event.latency_test_result.success'
            : 'event.latency_test_result.failure',
        args: const [],
        fallbackZh: displayText,
      ),
      value: value,
    );
    _eventSerial += 1;
  }

  void _armLatencyTestTimeout() {
    _latencyTestTimeoutTimer?.cancel();
    _latencyTestTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (_disposed || !_latencyTestPending) return;
      _finishLatencyTest(
        success: false,
        displayText: '延迟测试超时，无法连接到当前 Relay 节点',
      );
      notifyListeners();
    });
  }

  void _coordinateStartupActions(bridge.AppSnapshot snapshot) {
    if (snapshot.bootstrap != bridge.BootstrapStateDto.ready) return;
    final restoreId = snapshot.restoreHistoryId;
    if (!_autoRestoreAttempted && restoreId != null) {
      if (snapshot.clientConfig.selectedSteamId64 == null) {
        // A saved room cannot be restored without a local identity. Skip the
        // restore quietly so startup Relay probing is not blocked forever.
        _autoRestoreAttempted = true;
        _scheduleInitialRelayProbe(snapshot);
        return;
      }
      if (!_autoRestoreInFlight &&
          _autoRestoreRetryTimer == null &&
          !snapshot.room.active &&
          snapshot.room.status == bridge.RoomStatusDto.idle &&
          snapshot.canMutate) {
        _scheduleAutoRestoreRetry(delay: const Duration(milliseconds: 180));
      }
      return;
    }
    if (restoreId == null || snapshot.room.active || _autoRestoreAttempted) {
      _scheduleInitialRelayProbe(snapshot);
    }
  }

  void _scheduleAutoRestoreRetry({
    Duration delay = const Duration(milliseconds: 350),
  }) {
    if (_disposed || _autoRestoreAttempted || _autoRestoreAttempts >= 3) {
      _autoRestoreAttempted = true;
      _scheduleInitialRelayProbe(_snapshot);
      return;
    }
    _autoRestoreRetryTimer?.cancel();
    _autoRestoreRetryTimer = Timer(delay, () {
      _autoRestoreRetryTimer = null;
      final snapshot = _snapshot;
      final restoreId = snapshot?.restoreHistoryId;
      if (_disposed || snapshot == null || restoreId == null) {
        _autoRestoreAttempted = true;
        return;
      }
      if (!snapshot.canMutate ||
          snapshot.room.active ||
          snapshot.room.status != bridge.RoomStatusDto.idle) {
        _scheduleAutoRestoreRetry();
        return;
      }
      _autoRestoreAttempts += 1;
      final receipt = _joinHistoryRoom(restoreId, reportRejection: false);
      if (receipt.accepted) {
        _autoRestoreInFlight = true;
        _armAutoRestoreWatchdog();
      } else if (receipt.rejection?.code == 'queue_busy') {
        _scheduleAutoRestoreRetry();
      } else {
        _autoRestoreAttempted = true;
        _scheduleInitialRelayProbe(snapshot);
      }
    });
  }

  void _armAutoRestoreWatchdog() {
    _autoRestoreWatchdogTimer?.cancel();
    _autoRestoreWatchdogTimer = Timer(const Duration(seconds: 15), () {
      if (_disposed || !_autoRestoreInFlight) return;
      _abortAutoRestore(
        '恢复上一次的 Relay 房间超时，请检查网络后从历史记录重试。',
        messageKey: 'event.room_restore_relay.timeout',
      );
    });
  }

  void _abortAutoRestore(String displayText, {required String messageKey}) {
    _autoRestoreWatchdogTimer?.cancel();
    _autoRestoreWatchdogTimer = null;
    _autoRestoreInFlight = false;
    _autoRestoreAttempted = true;
    final roomStatus = _snapshot?.room.status;
    if (roomStatus == bridge.RoomStatusDto.joining ||
        roomStatus == bridge.RoomStatusDto.creating) {
      // This also clears the automatic restore marker while retaining the
      // room in the five-entry history list for an explicit user retry.
      leaveRoom();
    }
    _latestEvent = bridge.AppEvent(
      code: 'room_restore_failed',
      success: false,
      displayText: displayText,
      message: bridge.LocalizedMessageDto(
        key: messageKey,
        args: const [],
        fallbackZh: displayText,
      ),
    );
    _eventSerial += 1;
    notifyListeners();
    _scheduleInitialRelayProbe(_snapshot);
  }

  void _scheduleInitialRelayProbe(bridge.AppSnapshot? snapshot) {
    if (_disposed ||
        _initialRelayProbeAttempted ||
        _initialRelayProbeTimer != null ||
        snapshot == null) {
      return;
    }
    if (snapshot.clientConfig.selectedRelayId == null) {
      _initialRelayProbeAttempted = true;
      return;
    }
    _initialRelayProbeTimer = Timer(const Duration(milliseconds: 300), () {
      _initialRelayProbeTimer = null;
      if (_disposed || _initialRelayProbeAttempted || _latencyTestPending) {
        return;
      }
      final latest = _snapshot;
      if (latest == null || !latest.canMutate) {
        if (_initialRelayProbeAttempts++ < 3) {
          _scheduleInitialRelayProbe(latest);
        } else {
          _initialRelayProbeAttempted = true;
        }
        return;
      }
      final receipt = testRelayLatency();
      if (receipt.accepted) {
        _initialRelayProbeAttempted = true;
      } else if (receipt.rejection?.code == 'queue_busy' &&
          _initialRelayProbeAttempts++ < 3) {
        _scheduleInitialRelayProbe(latest);
      } else {
        _initialRelayProbeAttempted = true;
      }
    });
  }

  bridge.CommandReceipt _detachedReceipt() =>
      const bridge.CommandReceipt(accepted: true, rejection: null);

  bridge.CommandReceipt _native(
    bridge.CommandReceipt Function() command, {
    bool reportRejection = true,
  }) {
    if (_subscription == null) return _detachedReceipt();
    final result = command();
    if (!result.accepted && reportRejection) {
      _latestEvent = bridge.AppEvent(
        code: result.rejection?.code ?? 'command_rejected',
        success: false,
        displayText: result.rejection?.displayText ?? '操作未被接受',
        message:
            result.rejection?.message ??
            const bridge.LocalizedMessageDto(
              key: 'rejection.command_rejected',
              args: [],
              fallbackZh: '操作未被接受',
            ),
      );
      _eventSerial += 1;
      notifyListeners();
    }
    return result;
  }

  void setConnectionMode(ConnectionMode mode) {
    if (_connectionMode == mode) return;
    _connectionMode = mode;
    notifyListeners();
    if (mode == ConnectionMode.lan) {
      unawaited(prefetchLanAdapters());
    }
  }

  bridge.CommandReceipt selectRelay(String? id) =>
      _native(() => bridge.selectRelay(relayId: id));
  bridge.CommandReceipt selectSteamAccount(String? id) =>
      _native(() => bridge.selectSteamAccount(steamId64: id));
  bridge.CommandReceipt saveManualSteamAccount({
    required String steamId64,
    required String displayName,
  }) => _native(
    () => bridge.saveManualSteamAccount(
      steamId64: steamId64,
      displayName: displayName,
    ),
  );
  bridge.CommandReceipt deleteManualSteamAccount(String steamId64) =>
      _native(() => bridge.deleteManualSteamAccount(steamId64: steamId64));
  bridge.CommandReceipt useGameSteamAccount() =>
      _native(bridge.useGameSteamAccount);
  bridge.CommandReceipt setMode(bridge.SessionModeDto mode) =>
      _native(() => bridge.setSessionMode(mode: mode));
  bridge.CommandReceipt setTransport(bridge.TransportSelection transport) =>
      _native(() => bridge.setTransport(transport: transport));
  bridge.CommandReceipt restoreDefaultPreferences() =>
      _native(bridge.restoreDefaultPreferences);
  bridge.CommandReceipt refreshAccounts() => _native(bridge.refreshAccounts);
  bridge.CommandReceipt addRelay({
    required String name,
    required String host,
    required int port,
    required bool tcp,
    required bool udp,
    required bool defaultUdp,
  }) {
    if (!isNative) {
      _setDemoRelay(name, host, port, tcp, udp, defaultUdp);
      return _detachedReceipt();
    }
    return _native(
      () => bridge.addRelay(
        relay: bridge.RelayDraft(
          name: name,
          host: host,
          port: port,
          supportsUdp: udp,
          supportsTcp: tcp,
          defaultTransport: defaultUdp
              ? bridge.TransportSelection.udp
              : bridge.TransportSelection.tcp,
        ),
      ),
    );
  }

  bridge.CommandReceipt updateRelay({
    required String id,
    required String name,
    required String host,
    required int port,
    required bool tcp,
    required bool udp,
    required bool defaultUdp,
  }) {
    if (!isNative) {
      _setDemoRelay(name, host, port, tcp, udp, defaultUdp);
      return _detachedReceipt();
    }
    return _native(
      () => bridge.updateRelay(
        relayId: id,
        relay: bridge.RelayDraft(
          name: name,
          host: host,
          port: port,
          supportsUdp: udp,
          supportsTcp: tcp,
          defaultTransport: defaultUdp
              ? bridge.TransportSelection.udp
              : bridge.TransportSelection.tcp,
        ),
      ),
    );
  }

  bridge.CommandReceipt deleteRelay(String id) =>
      _native(() => bridge.deleteRelay(relayId: id));
  bridge.CommandReceipt testRelayLatency() {
    if (_latencyTestPending) {
      return const bridge.CommandReceipt(
        accepted: false,
        rejection: bridge.CommandRejection(
          code: 'latency_test_running',
          displayText: '延迟测试正在进行中',
          message: bridge.LocalizedMessageDto(
            key: 'rejection.latency_test_running',
            args: [],
            fallbackZh: '延迟测试正在进行中',
          ),
        ),
      );
    }
    final relayId = selectedRelay?.id;
    final receipt = _native(bridge.testRelayLatency);
    if (receipt.accepted && relayId != null) {
      _latencyTestPending = true;
      _latencyTestStarted = false;
      _latencyTestRelayIds = relays.map((relay) => relay.id).toSet();
      _armLatencyTestTimeout();
      notifyListeners();
    }
    return receipt;
  }

  bridge.CommandReceipt createRoom() => _connectionMode == ConnectionMode.relay
      ? _native(bridge.createRelayRoom)
      : _native(bridge.enumerateLanAdapters);
  Future<List<bridge.LanAdapterDto>?> loadLanAdapters({
    bool forceRefresh = false,
  }) => _lanAdapterCache.load(forceRefresh: forceRefresh);

  Future<void> prefetchLanAdapters() async {
    await loadLanAdapters();
  }

  Future<List<bridge.LanAdapterDto>?> _requestLanAdapters() async {
    if (!isNative) return null;
    final pending = _lanAdaptersCompleter;
    if (pending != null) return pending.future;
    final completer = Completer<List<bridge.LanAdapterDto>?>();
    _lanAdaptersCompleter = completer;
    final receipt = _native(bridge.enumerateLanAdapters);
    if (!receipt.accepted) {
      _lanAdaptersCompleter = null;
      return null;
    }
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (identical(_lanAdaptersCompleter, completer)) {
          _lanAdaptersCompleter = null;
        }
        return null;
      },
    );
  }

  bridge.CommandReceipt createLanRoom(List<String> adapterIds) =>
      _native(() => bridge.createLanRoom(adapterIds: adapterIds));
  bridge.CommandReceipt joinRoom(String code, {String? lanEndpoint}) => _native(
    () => bridge.joinRoom(joinCode: code, selectedLanEndpoint: lanEndpoint),
  );
  bridge.CommandReceipt retryRelayRoomWithTcp(String code) =>
      _native(() => bridge.retryRelayRoomWithTcp(joinCode: code));
  bridge.CommandReceipt _joinHistoryRoom(
    BigInt historyId, {
    bool reportRejection = true,
  }) => _native(
    () => bridge.joinHistoryRoom(historyId: historyId),
    reportRejection: reportRejection,
  );
  bridge.CommandReceipt joinHistoryRoom(BigInt historyId) =>
      _joinHistoryRoom(historyId);
  bridge.CommandReceipt switchToHistoryRoom(BigInt historyId) {
    if (!isInRoom) return joinHistoryRoom(historyId);
    _pendingHistoryRoomId = historyId;
    _pendingJoinCode = null;
    final receipt = leaveRoom(clearPending: false);
    if (!receipt.accepted) _pendingHistoryRoomId = null;
    return receipt;
  }

  bridge.CommandReceipt switchRoom(String joinCode) {
    if (!isInRoom) return joinRoom(joinCode);
    _pendingJoinCode = joinCode;
    _pendingHistoryRoomId = null;
    final receipt = leaveRoom(clearPending: false);
    if (!receipt.accepted) _pendingJoinCode = null;
    return receipt;
  }

  bridge.CommandReceipt continueLanJoin(String endpoint) =>
      _native(() => bridge.continueLanJoin(selectedLanEndpoint: endpoint));
  bridge.CommandReceipt leaveRoom({bool clearPending = true}) {
    if (clearPending) {
      _pendingHistoryRoomId = null;
      _pendingJoinCode = null;
    }
    return _native(bridge.leaveRoom);
  }

  bridge.CommandReceipt startGame() => _native(bridge.startGame);
  bridge.CommandReceipt cancelLaunch() => _native(bridge.cancelLaunch);
  bridge.CommandReceipt readInputDelay() => _native(bridge.readInputDelay);
  bridge.CommandReceipt writeInputDelay(int value) =>
      _native(() => bridge.writeInputDelay(value: value));
  bridge.CommandReceipt refreshHookStatus() =>
      _native(bridge.refreshHookStatus);
  bridge.CommandReceipt openLogDirectory() => _native(bridge.openLogDirectory);
  bridge.CommandReceipt exportDiagnosticsBundle() =>
      _native(bridge.exportDiagnosticsBundle);
  bridge.CommandReceipt clearLogs() => _native(bridge.clearLogs);
  bridge.CommandReceipt setSnapshotProfile(bridge.SnapshotProfileDto profile) =>
      _native(() => bridge.setSnapshotProfile(profile: profile));
  bridge.CommandReceipt shutdown() => _native(bridge.shutdown);

  Future<bool> waitForSnapshotProfile(
    bridge.SnapshotProfileDto profile, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (!isNative || snapshotProfile == profile) return true;
    final completer = Completer<bool>();
    void listener() {
      if (snapshotProfile == profile && !completer.isCompleted) {
        completer.complete(true);
      }
    }

    addListener(listener);
    final receipt = setSnapshotProfile(profile);
    if (!receipt.accepted) {
      removeListener(listener);
      return false;
    }
    final result = await completer.future.timeout(
      timeout,
      onTimeout: () => false,
    );
    removeListener(listener);
    return result;
  }

  Future<bool> shutdownAndWait() async {
    if (_subscription == null) return true;
    if (_snapshot?.shutdownState == bridge.ShutdownStateDto.complete) {
      return true;
    }
    final completer = Completer<bool>();
    void listener() {
      if (_snapshot?.shutdownState == bridge.ShutdownStateDto.complete &&
          !completer.isCompleted) {
        completer.complete(true);
      }
    }

    addListener(listener);
    shutdown();
    final completed = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    removeListener(listener);
    return completed;
  }

  // Compatibility methods retained only for isolated visual widgets. They now
  // dispatch to Rust instead of mutating demo data.
  void setServerLatency(int value) {
    if (isNative) return;
    _demoLatency = value;
    notifyListeners();
  }

  void setIsTestingLatency(bool testing) {
    if (testing) testRelayLatency();
  }

  void switchNode() {
    if (!isNative) {
      final beijing = _demoNode != '北京 BGP 低延迟节点 02';
      _setDemoRelay(
        beijing ? '北京 BGP 低延迟节点 02' : '上海 BGP 极速节点 01',
        beijing ? 'relay.bj.net' : 'relay.sh.net',
        19842,
        true,
        true,
        true,
        latency: beijing ? 31 : 24,
      );
      return;
    }
    if (relays.isEmpty) return;
    final current = relays.indexWhere((relay) => relay.id == selectedRelay?.id);
    selectRelay(relays[(current + 1) % relays.length].id);
  }

  void updateRelayNode({
    required String name,
    required String address,
    required String port,
    required bool tcp,
    required bool udp,
    required String defaultTransport,
    int? latency,
  }) {
    if (!isNative) {
      _setDemoRelay(
        name,
        address,
        int.tryParse(port) ?? 0,
        tcp,
        udp,
        defaultTransport == 'UDP',
        latency: latency,
      );
      return;
    }
    final match = relays.where((relay) => relay.name == name);
    if (match.isNotEmpty) selectRelay(match.first.id);
  }

  void resetToDefaultPublicNode() {
    if (!isNative) {
      _setDemoRelay(
        '上海 BGP 极速节点 01',
        'relay.sh.net',
        19842,
        true,
        true,
        true,
        latency: 24,
      );
      return;
    }
    if (relays.isNotEmpty) selectRelay(relays.first.id);
  }

  void _setDemoRelay(
    String name,
    String host,
    int port,
    bool tcp,
    bool udp,
    bool defaultUdp, {
    int? latency,
  }) {
    _demoNode = name;
    _demoHost = '$host:$port';
    _demoPort = '$port';
    _demoTcp = tcp;
    _demoUdp = udp;
    _demoDefaultTransport = defaultUdp ? 'UDP' : 'TCP';
    if (latency != null) _demoLatency = latency;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingHistoryRoomId = null;
    _pendingJoinCode = null;
    _autoRestoreRetryTimer?.cancel();
    _autoRestoreWatchdogTimer?.cancel();
    _initialRelayProbeTimer?.cancel();
    _latencyTestTimeoutTimer?.cancel();
    final lanCompleter = _lanAdaptersCompleter;
    if (lanCompleter != null && !lanCompleter.isCompleted) {
      lanCompleter.complete(null);
    }
    _lanAdaptersCompleter = null;
    _subscription?.cancel();
    super.dispose();
  }
}

bool _appSnapshotsSemanticallyEqual(
  bridge.AppSnapshot? previous,
  bridge.AppSnapshot next,
) {
  if (previous == null) return false;
  return previous.profile == next.profile &&
      previous.bootstrap == next.bootstrap &&
      previous.operation == next.operation &&
      previous.canMutate == next.canMutate &&
      previous.shutdownState == next.shutdownState &&
      previous.buildInfo == next.buildInfo &&
      _clientConfigsEqual(previous.clientConfig, next.clientConfig) &&
      previous.session == next.session &&
      _roomsEqual(previous.room, next.room) &&
      listEquals(previous.roomHistory, next.roomHistory) &&
      previous.restoreHistoryId == next.restoreHistoryId &&
      previous.launch == next.launch &&
      previous.hook == next.hook &&
      previous.counters == next.counters &&
      listEquals(previous.connectionTests, next.connectionTests) &&
      listEquals(previous.logs, next.logs) &&
      _lanAdaptersEqual(previous.lanAdapters, next.lanAdapters) &&
      listEquals(previous.lanJoinEndpoints, next.lanJoinEndpoints) &&
      previous.bootstrapError == next.bootstrapError;
}

bool _clientConfigsEqual(
  bridge.ClientConfigDto previous,
  bridge.ClientConfigDto next,
) =>
    previous.selectedRelayId == next.selectedRelayId &&
    previous.selectedSteamId64 == next.selectedSteamId64 &&
    previous.mode == next.mode &&
    previous.transport == next.transport &&
    listEquals(previous.relays, next.relays) &&
    listEquals(previous.accounts, next.accounts) &&
    listEquals(previous.warnings, next.warnings);

bool _roomsEqual(bridge.RoomSnapshot previous, bridge.RoomSnapshot next) =>
    previous.active == next.active &&
    previous.status == next.status &&
    previous.generation == next.generation &&
    previous.route == next.route &&
    previous.transport == next.transport &&
    previous.joinCode == next.joinCode &&
    listEquals(previous.members, next.members) &&
    previous.steamIdentityMismatch == next.steamIdentityMismatch;

bool _lanAdaptersEqual(
  List<bridge.LanAdapterDto> previous,
  List<bridge.LanAdapterDto> next,
) {
  if (identical(previous, next)) return true;
  if (previous.length != next.length) return false;
  for (var index = 0; index < previous.length; index++) {
    final left = previous[index];
    final right = next[index];
    if (left.id != right.id ||
        left.name != right.name ||
        left.interfaceIndex != right.interfaceIndex ||
        left.recommended != right.recommended ||
        !listEquals(left.addresses, right.addresses)) {
      return false;
    }
  }
  return true;
}

@immutable
class LightweightViewState {
  const LightweightViewState({
    required this.sessionRunning,
    required this.hookReady,
    required this.route,
    required this.transport,
    required this.members,
    this.roomCode,
  });

  final bool sessionRunning;
  final bool hookReady;
  final bridge.RoomRouteDto? route;
  final bridge.TransportSelection? transport;
  final List<bridge.RoomMemberDto> members;
  final String? roomCode;

  @override
  int get hashCode => Object.hash(
    sessionRunning,
    hookReady,
    route,
    transport,
    roomCode,
    Object.hashAll(members),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LightweightViewState &&
          sessionRunning == other.sessionRunning &&
          hookReady == other.hookReady &&
          route == other.route &&
          transport == other.transport &&
          roomCode == other.roomCode &&
          listEquals(members, other.members);
}

class TractorBeamScope extends InheritedNotifier<TractorBeamController> {
  const TractorBeamScope({
    super.key,
    required TractorBeamController notifier,
    required super.child,
  }) : super(notifier: notifier);

  static TractorBeamController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TractorBeamScope>();
    assert(scope != null, 'No TractorBeamScope found in context');
    return scope!.notifier!;
  }

  static TractorBeamController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TractorBeamScope>()?.notifier;
}
