import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/l10n/l10n.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/main_shell.dart';
import 'package:tbnet_app/screens/room_screen.dart';
import 'package:tbnet_app/widgets/status_bar.dart';

class _FakeAppSnapshot implements bridge.AppSnapshot {
  const _FakeAppSnapshot();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _LifecycleTestSnapshot extends _FakeAppSnapshot {
  final bool inRoom;
  final bool sessionRunning;
  final bridge.LaunchStatusDto launchStatus;
  final bridge.SteamIdentityMismatchDto? mismatch;

  const _LifecycleTestSnapshot({
    required this.inRoom,
    required this.sessionRunning,
    required this.launchStatus,
    this.mismatch,
  });

  @override
  bool get canMutate => true;

  @override
  bridge.SessionSnapshot get session => bridge.SessionSnapshot(
        status: sessionRunning
            ? bridge.SessionStatusDto.running
            : bridge.SessionStatusDto.idle,
        smoothness: 'smooth',
        health: null,
        lastStopReason: null,
      );

  @override
  bridge.RoomSnapshot get room => bridge.RoomSnapshot(
        active: inRoom,
        status: inRoom ? bridge.RoomStatusDto.active : bridge.RoomStatusDto.idle,
        generation: BigInt.one,
        route: bridge.RoomRouteDto.relay,
        transport: bridge.TransportSelection.udp,
        joinCode: inRoom ? 'TB-TEST-1234' : null,
        members: const [],
        steamIdentityMismatch: mismatch,
      );

  @override
  bridge.LaunchProgressDto get launch => bridge.LaunchProgressDto(
        status: launchStatus,
        generation: BigInt.one,
        displayText: '',
        terminal: true,
        success: launchStatus == bridge.LaunchStatusDto.ready,
      );

  @override
  bridge.BuildInfoDto get buildInfo => const _FakeBuildInfoDto();

  @override
  bridge.HookSnapshot get hook => const _FakeHookSnapshot();

  @override
  bridge.CountersDto get counters => const _FakeCountersDto();

  @override
  bridge.ClientConfigDto get clientConfig => const _FakeClientConfigDto();

  @override
  List<bridge.RoomHistoryEntryDto> get roomHistory => const [];

  @override
  List<bridge.LogEntryDto> get logs => const [];

  @override
  List<bridge.ConnectionTestDto> get connectionTests => const [];

  @override
  List<bridge.LanAdapterDto> get lanAdapters => const [];

  @override
  List<String> get lanJoinEndpoints => const [];
}

class _FakeBuildInfoDto implements bridge.BuildInfoDto {
  const _FakeBuildInfoDto();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  String get versionLabel => 'v0.5.2-test';
  @override
  String get relayProtocol => 'v5';
  @override
  String get directProtocol => 'v6';
  @override
  String get version => '0.5.2';
  @override
  String get releaseVersion => '0.5.2-tb.1';
  @override
  String get license => 'GPL-3.0';
  @override
  String get sourceUrl => 'https://github.com/mcthesw/TractorBeam';
}

class _FakeHookSnapshot implements bridge.HookSnapshot {
  const _FakeHookSnapshot();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  String get connection => 'connected';
  @override
  String get startupPhase => 'ready';
  @override
  String get installation => 'ok';
  @override
  bool get runtimeActive => true;
  @override
  String get version => '1.0';
  @override
  int get reconnects => 0;
  @override
  BigInt get malformedFrames => BigInt.zero;
}

class _FakeClientConfigDto implements bridge.ClientConfigDto {
  const _FakeClientConfigDto();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  bridge.SessionModeDto get mode => bridge.SessionModeDto.pure;
  @override
  bridge.TransportSelection get transport => bridge.TransportSelection.udp;
  @override
  List<bridge.RelayDto> get relays => const [];
  @override
  List<bridge.SteamAccountDto> get accounts => const [];
  @override
  List<String> get warnings => const [];
}

class _FakeCountersDto implements bridge.CountersDto {
  const _FakeCountersDto();
  @override
  dynamic noSuchMethod(Invocation invocation) => BigInt.zero;
}

class _LifecycleTestController extends TractorBeamController {
  bool inRoomState;
  bool sessionRunningState;
  bridge.LaunchStatusDto launchStatusState;
  bridge.SteamIdentityMismatchDto? mismatchState;

  _LifecycleTestController({
    this.inRoomState = false,
    this.sessionRunningState = false,
    this.launchStatusState = bridge.LaunchStatusDto.idle,
    this.mismatchState,
  }) : super.detached();

  @override
  bool get isNative => true;

  @override
  bool get isInRoom => inRoomState;

  @override
  bool get isSessionRunning => sessionRunningState;

  @override
  bool get isHookReady => launchStatusState == bridge.LaunchStatusDto.ready;

  @override
  bridge.SteamIdentityMismatchDto? get steamIdentityMismatch => mismatchState;

  @override
  bridge.LaunchProgressDto? get launchProgress => bridge.LaunchProgressDto(
        status: launchStatusState,
        generation: BigInt.one,
        displayText: '',
        terminal: true,
        success: launchStatusState == bridge.LaunchStatusDto.ready,
      );

  @override
  bridge.AppSnapshot? get snapshot => _LifecycleTestSnapshot(
        inRoom: inRoomState,
        sessionRunning: sessionRunningState,
        launchStatus: launchStatusState,
        mismatch: mismatchState,
      );

  void updateState({
    bool? inRoom,
    bool? sessionRunning,
    bridge.LaunchStatusDto? launchStatus,
    bridge.SteamIdentityMismatchDto? mismatch,
  }) {
    if (inRoom != null) inRoomState = inRoom;
    if (sessionRunning != null) sessionRunningState = sessionRunning;
    if (launchStatus != null) launchStatusState = launchStatus;
    mismatchState = mismatch;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrimarySessionAction priority derivation', () {
    test('resolveSteamMismatch takes highest precedence', () {
      final controller = _LifecycleTestController(
        inRoomState: true,
        sessionRunningState: true,
        launchStatusState: bridge.LaunchStatusDto.ready,
        mismatchState: const bridge.SteamIdentityMismatchDto(
          gameSteamId64: '76561198000000001',
          roomSteamId64: '76561198000000002',
        ),
      );

      expect(
        controller.primarySessionAction,
        PrimarySessionAction.resolveSteamMismatch,
      );
      expect(controller.launchButtonLabel, '同步 Steam 账号');
    });

    test('running takes precedence when no mismatch', () {
      final controller = _LifecycleTestController(
        inRoomState: true,
        sessionRunningState: true,
        launchStatusState: bridge.LaunchStatusDto.ready,
      );

      expect(controller.primarySessionAction, PrimarySessionAction.running);
      expect(controller.launchButtonLabel, '游戏运行中');
    });

    test('launching takes precedence over ready when starting', () {
      final controller = _LifecycleTestController(
        inRoomState: true,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.waitingForGame,
      );

      expect(controller.primarySessionAction, PrimarySessionAction.launching);
      expect(controller.launchButtonLabel, '启动中…');
    });

    test('resumeGameplay when hook is ready and in room', () {
      final controller = _LifecycleTestController(
        inRoomState: true,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.ready,
      );

      expect(
        controller.primarySessionAction,
        PrimarySessionAction.resumeGameplay,
      );
      expect(controller.launchButtonLabel, '开始联机');
    });

    test('unavailable when hook is ready but not in room', () {
      final controller = _LifecycleTestController(
        inRoomState: false,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.ready,
      );

      expect(controller.primarySessionAction, PrimarySessionAction.unavailable);
      expect(controller.launchButtonLabel, '游戏已就绪');
    });

    test('launchGame is the default initial state', () {
      final controller = _LifecycleTestController(
        inRoomState: false,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.idle,
      );

      expect(controller.primarySessionAction, PrimarySessionAction.launchGame);
      expect(controller.launchButtonLabel, '启动游戏');
    });
  });

  group('BottomStatusBar under steam mismatch', () {
    testWidgets('renders sync steam account label and triggers onNavigateToRoom',
        (tester) async {
      final controller = _LifecycleTestController(
        inRoomState: true,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.ready,
        mismatchState: const bridge.SteamIdentityMismatchDto(
          gameSteamId64: '76561198000000001',
          roomSteamId64: '76561198000000002',
        ),
      );

      var navigatedToRoom = false;
      var launchedGame = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh', 'CN'),
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: BottomStatusBar(
                onNavigateToRoom: () => navigatedToRoom = true,
                onLaunchGame: () => launchedGame = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('同步 Steam 账号'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('status-bar-launch-button')));
      await tester.pumpAndSettle();

      expect(navigatedToRoom, isTrue);
      expect(launchedGame, isFalse);
    });
  });

  group('MainShell mismatch navigation', () {
    testWidgets('automatically switches to room page when mismatch appears',
        (tester) async {
      final controller = _LifecycleTestController(
        inRoomState: true,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.ready,
      );

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh', 'CN'),
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: MainShell(controller: controller),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger mismatch
      controller.updateState(
        mismatch: const bridge.SteamIdentityMismatchDto(
          gameSteamId64: '76561198000000001',
          roomSteamId64: '76561198000000002',
        ),
      );

      await tester.pumpAndSettle();

      // Verify mismatch banner in RoomScreen is visible
      expect(find.byType(RoomScreen), findsOneWidget);
      expect(find.text('Steam 账号不一致：以撒游戏使用 76561198000000001，而房间配置为 76561198000000002'), findsOneWidget);
    });
  });
}
