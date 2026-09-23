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

class _MockStateSnapshot extends _FakeAppSnapshot {
  final bool inRoom;
  final bool sessionRunning;
  final bridge.LaunchStatusDto launchStatus;

  const _MockStateSnapshot({
    required this.inRoom,
    required this.sessionRunning,
    required this.launchStatus,
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
    members: inRoom
        ? const [
            bridge.RoomMemberDto(
              steamId64: '76561198000000001',
              displayName: 'Player1',
              connection: 'connected',
              isLocal: true,
            ),
          ]
        : const [],
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

  @override
  bridge.HookSnapshot get hook => const _FakeHookSnapshot();

  @override
  bridge.CountersDto get counters => const _FakeCountersDto();
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

class _FakeClientConfigDto implements bridge.ClientConfigDto {
  const _FakeClientConfigDto();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  bridge.SessionModeDto get mode => bridge.SessionModeDto.official;
  @override
  bridge.TransportSelection get transport => bridge.TransportSelection.udp;
  @override
  List<bridge.RelayDto> get relays => const [];
  @override
  List<bridge.SteamAccountDto> get accounts => const [];
  @override
  List<String> get warnings => const [];
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

class _FakeCountersDto implements bridge.CountersDto {
  const _FakeCountersDto();
  @override
  dynamic noSuchMethod(Invocation invocation) => BigInt.zero;
  @override
  BigInt get errors => BigInt.zero;
  @override
  BigInt get hookToRelay => BigInt.zero;
  @override
  BigInt get relayToHook => BigInt.zero;
  @override
  BigInt get sentBytes => BigInt.zero;
  @override
  BigInt get receivedBytes => BigInt.zero;
  @override
  BigInt get reconnectDroppedPackets => BigInt.zero;
  @override
  BigInt get detachedHookDroppedPackets => BigInt.zero;
  @override
  BigInt get detachedRelayDroppedPackets => BigInt.zero;
}

class _MockStateController extends TractorBeamController {
  bool inRoomState;
  bool sessionRunningState;
  bridge.LaunchStatusDto launchStatusState;
  bool leaveRoomCalled = false;
  bool startGameCalled = false;

  _MockStateController({
    this.inRoomState = false,
    this.sessionRunningState = false,
    this.launchStatusState = bridge.LaunchStatusDto.idle,
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
  bridge.LaunchProgressDto? get launchProgress => bridge.LaunchProgressDto(
    status: launchStatusState,
    generation: BigInt.one,
    displayText: '',
    terminal: true,
    success: launchStatusState == bridge.LaunchStatusDto.ready,
  );

  @override
  bridge.AppSnapshot? get snapshot => _MockStateSnapshot(
    inRoom: inRoomState,
    sessionRunning: sessionRunningState,
    launchStatus: launchStatusState,
  );

  @override
  bridge.CommandReceipt leaveRoom({bool clearPending = false}) {
    leaveRoomCalled = true;
    inRoomState = false;
    sessionRunningState = false;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt startGame() {
    startGameCalled = true;
    sessionRunningState = true;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }
}

Widget _wrapWithScope(TractorBeamController controller, Widget child) {
  return TractorBeamScope(
    notifier: controller,
    child: MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Game Ready & Button Labels Unit Tests', () {
    test('launchButtonLabel returns expected copy across states', () {
      final ctrlIdle = _MockStateController(
        inRoomState: false,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.idle,
      );
      expect(ctrlIdle.launchButtonLabel, '启动游戏');

      final ctrlReadyInRoom = _MockStateController(
        inRoomState: true,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.ready,
      );
      expect(ctrlReadyInRoom.launchButtonLabel, '开始联机');

      final ctrlReadyNotInRoom = _MockStateController(
        inRoomState: false,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.ready,
      );
      expect(ctrlReadyNotInRoom.launchButtonLabel, '游戏已就绪');

      final ctrlRunning = _MockStateController(
        inRoomState: true,
        sessionRunningState: true,
        launchStatusState: bridge.LaunchStatusDto.ready,
      );
      expect(ctrlRunning.launchButtonLabel, '游戏运行中');
    });
  });

  group('BottomStatusBar State Display Widget Tests', () {
    testWidgets(
      'StatusBar displays "开始联机" and "游戏就绪" when hook is ready in room',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(960, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = _MockStateController(
          inRoomState: true,
          sessionRunningState: false,
          launchStatusState: bridge.LaunchStatusDto.ready,
        );

        await tester.pumpWidget(
          _wrapWithScope(controller, const BottomStatusBar()),
        );
        await tester.pumpAndSettle();

        expect(find.text('开始联机'), findsOneWidget);
        expect(find.text('游戏就绪'), findsOneWidget);
        expect(find.text('待机'), findsNothing);
      },
    );

    testWidgets(
      'StatusBar displays "游戏已就绪" when hook is ready but not in room',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(960, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = _MockStateController(
          inRoomState: false,
          sessionRunningState: false,
          launchStatusState: bridge.LaunchStatusDto.ready,
        );

        await tester.pumpWidget(
          _wrapWithScope(controller, const BottomStatusBar()),
        );
        await tester.pumpAndSettle();

        expect(find.text('游戏已就绪'), findsOneWidget);
        expect(find.text('游戏就绪'), findsOneWidget);
      },
    );

    testWidgets('StatusBar displays "空闲" and "启动游戏" when hook is not ready', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(960, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _MockStateController(
        inRoomState: false,
        sessionRunningState: false,
        launchStatusState: bridge.LaunchStatusDto.idle,
      );

      await tester.pumpWidget(
        _wrapWithScope(controller, const BottomStatusBar()),
      );
      await tester.pumpAndSettle();

      expect(find.text('启动游戏'), findsOneWidget);
      expect(find.text('空闲'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('enter-lightweight-mode')),
        findsNothing,
      );
    });

    testWidgets(
      'StatusBar displays prominent lightweight button when session is running and onEnterLightweight is provided',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(960, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var enterLightweightCalled = false;
        final controller = _MockStateController(
          inRoomState: true,
          sessionRunningState: true,
          launchStatusState: bridge.LaunchStatusDto.ready,
        );

        await tester.pumpWidget(
          _wrapWithScope(
            controller,
            BottomStatusBar(
              onEnterLightweight: () => enterLightweightCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final lightweightFinder = find.byKey(
          const ValueKey('enter-lightweight-mode'),
        );
        expect(lightweightFinder, findsOneWidget);
        expect(find.text('悬浮窗'), findsOneWidget);

        await tester.tap(lightweightFinder);
        await tester.pumpAndSettle();

        expect(enterLightweightCalled, isTrue);
      },
    );
  });

  group('Room Screen In-Game Leave Confirmation Tests', () {
    testWidgets(
      'Leaving room during game displays confirmation dialog and can be cancelled',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(960, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = _MockStateController(
          inRoomState: true,
          sessionRunningState: true,
          launchStatusState: bridge.LaunchStatusDto.ready,
        );

        await tester.pumpWidget(_wrapWithScope(controller, const RoomScreen()));
        await tester.pumpAndSettle();

        // Tap "退出当前房间"
        final leaveBtn = find.text('退出当前房间');
        expect(leaveBtn, findsOneWidget);
        await tester.tap(leaveBtn);
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.text('退出联机房间'), findsOneWidget);
        expect(find.textContaining('当前游戏联机对局正在进行中'), findsOneWidget);
        expect(controller.leaveRoomCalled, isFalse);

        // Tap "取消"
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();

        // Dialog dismissed, still in room
        expect(find.text('退出联机房间'), findsNothing);
        expect(controller.leaveRoomCalled, isFalse);
        expect(controller.inRoomState, isTrue);
      },
    );

    testWidgets('Confirming exit in dialog executes leaveRoom', (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _MockStateController(
        inRoomState: true,
        sessionRunningState: true,
        launchStatusState: bridge.LaunchStatusDto.ready,
      );

      await tester.pumpWidget(_wrapWithScope(controller, const RoomScreen()));
      await tester.pumpAndSettle();

      // Tap "退出当前房间"
      await tester.tap(find.text('退出当前房间'));
      await tester.pumpAndSettle();

      // Verify dialog is shown and tap "确认退出"
      expect(find.text('退出联机房间'), findsOneWidget);
      await tester.tap(find.text('确认退出'));
      await tester.pumpAndSettle();

      // leaveRoom was executed
      expect(controller.leaveRoomCalled, isTrue);
      expect(controller.inRoomState, isFalse);
    });

    testWidgets(
      'Leaving room when game is NOT running does not show confirmation dialog',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(960, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = _MockStateController(
          inRoomState: true,
          sessionRunningState: false,
          launchStatusState: bridge.LaunchStatusDto.ready,
        );

        await tester.pumpWidget(_wrapWithScope(controller, const RoomScreen()));
        await tester.pumpAndSettle();

        // Tap "退出当前房间"
        await tester.tap(find.text('退出当前房间'));
        await tester.pumpAndSettle();

        // No confirmation dialog, leaveRoom called directly
        expect(find.text('退出联机房间'), findsNothing);
        expect(controller.leaveRoomCalled, isTrue);
      },
    );
  });

  group('MainShell Smart Navigation Tests', () {
    testWidgets(
      'Clicking Game Ready button when not in room guides to room page',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(960, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = _MockStateController(
          inRoomState: false,
          sessionRunningState: false,
          launchStatusState: bridge.LaunchStatusDto.ready,
        );

        await tester.pumpWidget(
          _wrapWithScope(controller, MainShell(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Tap the status-bar-launch-button (which displays "游戏已就绪")
        final launchButton = find.byKey(
          const ValueKey('status-bar-launch-button'),
        );
        expect(launchButton, findsOneWidget);
        expect(find.text('游戏已就绪'), findsOneWidget);

        await tester.tap(launchButton);
        await tester.pumpAndSettle();

        // Verifies notification prompt
        expect(find.text('游戏已就绪，请加入或创建房间开始联机'), findsOneWidget);
      },
    );
  });
}
