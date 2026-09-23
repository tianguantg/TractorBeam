import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/l10n/generated/app_localizations.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/about_screen.dart';
import 'package:tbnet_app/widgets/app_notification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bridge.AppSnapshot makeSnapshot({
    bridge.UpdateStatusDto updateStatus = bridge.UpdateStatusDto.idle,
    bridge.AvailableUpdateDto? availableUpdate,
    String? updateError,
    String releaseVersion = '0.5.2-tb.1',
  }) {
    return bridge.AppSnapshot(
      profile: bridge.SnapshotProfileDto.full,
      bootstrap: bridge.BootstrapStateDto.ready,
      canMutate: true,
      shutdownState: bridge.ShutdownStateDto.running,
      buildInfo: bridge.BuildInfoDto(
        version: '0.5.2',
        versionLabel: '0.5.2',
        releaseVersion: releaseVersion,
        relayProtocol: 'v5',
        directProtocol: 'v6',
        license: 'AGPL-3.0-or-later',
        sourceUrl: 'https://github.com/tianguantg/TractorBeam',
      ),
      clientConfig: const bridge.ClientConfigDto(
        selectedRelayId: 'relay-1',
        selectedSteamId64: '76561198000000000',
        mode: bridge.SessionModeDto.pure,
        transport: bridge.TransportSelection.udp,
        relays: [],
        accounts: [],
        warnings: [],
      ),
      session: const bridge.SessionSnapshot(
        status: bridge.SessionStatusDto.idle,
        smoothness: 'idle',
      ),
      room: bridge.RoomSnapshot(
        active: false,
        status: bridge.RoomStatusDto.idle,
        generation: BigInt.zero,
        members: const [],
      ),
      roomHistory: const [],
      launch: bridge.LaunchProgressDto(
        status: bridge.LaunchStatusDto.idle,
        generation: BigInt.zero,
        displayText: '',
        terminal: false,
        success: false,
      ),
      hook: bridge.HookSnapshot(
        startupPhase: 'idle',
        connection: 'inactive',
        installation: 'unknown',
        runtimeActive: false,
        reconnects: 0,
        malformedFrames: BigInt.zero,
      ),
      counters: bridge.CountersDto(
        hookToRelay: BigInt.zero,
        relayToHook: BigInt.zero,
        sentBytes: BigInt.zero,
        receivedBytes: BigInt.zero,
        errors: BigInt.zero,
        reconnectDroppedPackets: BigInt.zero,
        detachedHookDroppedPackets: BigInt.zero,
        detachedRelayDroppedPackets: BigInt.zero,
      ),
      connectionTests: const [],
      logs: const [],
      lanAdapters: const [],
      lanJoinEndpoints: const [],
      update: bridge.UpdateSnapshotDto(
        status: updateStatus,
        availableUpdate: availableUpdate,
        error: updateError,
        channelUrl: 'https://github.com/tianguantg/TractorBeam/releases',
      ),
    );
  }

  bridge.AppUpdate makeUpdate(
    int revision, {
    bridge.UpdateStatusDto updateStatus = bridge.UpdateStatusDto.idle,
    bridge.AvailableUpdateDto? availableUpdate,
    String? updateError,
    String releaseVersion = '0.5.2-tb.1',
  }) {
    return bridge.AppUpdate(
      revision: BigInt.from(revision),
      snapshot: makeSnapshot(
        updateStatus: updateStatus,
        availableUpdate: availableUpdate,
        updateError: updateError,
        releaseVersion: releaseVersion,
      ),
      events: const [],
    );
  }

  group('TractorBeamController update state management', () {
    test('controller exposes update properties from snapshot', () {
      final controller = TractorBeamController.detached();
      addTearDown(controller.dispose);

      controller.debugAcceptUpdate(
        makeUpdate(
          1,
          updateStatus: bridge.UpdateStatusDto.available,
          availableUpdate: const bridge.AvailableUpdateDto(
            version: '0.5.2-tb.2',
            url: 'https://github.com/tianguantg/TractorBeam/releases/tag/v0.5.2-tb.2',
          ),
          releaseVersion: '0.5.2-tb.1',
        ),
      );

      expect(controller.updateStatus, bridge.UpdateStatusDto.available);
      expect(controller.availableUpdate?.version, '0.5.2-tb.2');
      expect(controller.releaseVersion, '0.5.2-tb.1');
      expect(
        controller.updateChannelUrl,
        'https://github.com/tianguantg/TractorBeam/releases',
      );
    });

    test('controller notifies listeners when updateStatus changes', () {
      final controller = TractorBeamController.detached();
      addTearDown(controller.dispose);

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.debugAcceptUpdate(
        makeUpdate(1, updateStatus: bridge.UpdateStatusDto.idle),
      );
      expect(notifyCount, 1);

      controller.debugAcceptUpdate(
        makeUpdate(2, updateStatus: bridge.UpdateStatusDto.checking),
      );
      expect(notifyCount, 2);

      controller.debugAcceptUpdate(
        makeUpdate(
          3,
          updateStatus: bridge.UpdateStatusDto.available,
          availableUpdate: const bridge.AvailableUpdateDto(
            version: '0.5.2-tb.2',
            url: 'https://github.com/tianguantg/TractorBeam/releases/tag/v0.5.2-tb.2',
          ),
        ),
      );
      expect(notifyCount, 3);
    });
  });

  group('AboutScreen update status presentation', () {
    Widget buildAboutScreen(TractorBeamController controller) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: TractorBeamScope(
            notifier: controller,
            child: const AboutScreen(),
          ),
        ),
      );
    }

    testWidgets('shows idle state with check update button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TractorBeamController.detached();
      controller.debugAcceptUpdate(
        makeUpdate(1, updateStatus: bridge.UpdateStatusDto.idle),
      );

      await tester.pumpWidget(buildAboutScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('版本标识'), findsOneWidget);
      expect(find.text('0.5.2-tb.1'), findsOneWidget);
      expect(find.text('更新状态'), findsOneWidget);
      expect(find.text('检查更新'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows checking state with spinner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TractorBeamController.detached();
      controller.debugAcceptUpdate(
        makeUpdate(1, updateStatus: bridge.UpdateStatusDto.checking),
      );

      await tester.pumpWidget(buildAboutScreen(controller));
      await tester.pump();

      expect(find.text('正在检查更新…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows upToDate state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TractorBeamController.detached();
      controller.debugAcceptUpdate(
        makeUpdate(1, updateStatus: bridge.UpdateStatusDto.upToDate),
      );

      await tester.pumpWidget(buildAboutScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('已是最新版本'), findsOneWidget);
      expect(find.text('检查更新'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows available state with view update button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TractorBeamController.detached();
      controller.debugAcceptUpdate(
        makeUpdate(
          1,
          updateStatus: bridge.UpdateStatusDto.available,
          availableUpdate: const bridge.AvailableUpdateDto(
            version: '0.5.2-tb.2',
            url: 'https://github.com/tianguantg/TractorBeam/releases/tag/v0.5.2-tb.2',
          ),
        ),
      );

      await tester.pumpWidget(buildAboutScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('发现新版本：v0.5.2-tb.2'), findsOneWidget);
      expect(find.text('查看更新'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('shows failed state with retry button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TractorBeamController.detached();
      controller.debugAcceptUpdate(
        makeUpdate(
          1,
          updateStatus: bridge.UpdateStatusDto.failed,
          updateError: 'Connection timed out',
        ),
      );

      await tester.pumpWidget(buildAboutScreen(controller));
      await tester.pumpAndSettle();

      expect(find.text('检查更新失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      controller.dispose();
    });
  });

  group('AppNotification action button', () {
    testWidgets('renders action button and triggers callback when tapped', (
      tester,
    ) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppNotification.info(
                    context,
                    '发现新版本 v0.5.2-tb.2',
                    actionLabel: '查看更新',
                    onAction: () {
                      actionTriggered = true;
                    },
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('发现新版本 v0.5.2-tb.2'), findsOneWidget);
      expect(find.text('查看更新'), findsOneWidget);

      await tester.tap(find.text('查看更新'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
      // After tapping the action button, the notification is dismissed
      expect(find.text('发现新版本 v0.5.2-tb.2'), findsNothing);
    });
  });
}
