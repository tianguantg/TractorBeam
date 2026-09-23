import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/l10n/bridge_message_localizer.dart';
import 'package:tbnet_app/l10n/generated/app_localizations.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/room_screen.dart';

Widget _wrapWithApp(Widget child, {Locale locale = const Locale('zh')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(child: child),
  );
}

bridge.AppEvent _event(String key, {String text = '', String? value}) {
  return bridge.AppEvent(
    code: 'relay_room_joined',
    success: false,
    displayText: text,
    value: value,
    message: bridge.LocalizedMessageDto(
      key: key,
      args: const [],
      fallbackZh: text,
    ),
  );
}

bridge.AppSnapshot _testSnapshot({
  bool active = false,
  bridge.RoomStatusDto status = bridge.RoomStatusDto.idle,
}) {
  return bridge.AppSnapshot(
    profile: bridge.SnapshotProfileDto.full,
    bootstrap: bridge.BootstrapStateDto.ready,
    canMutate: true,
    shutdownState: bridge.ShutdownStateDto.running,
    buildInfo: const bridge.BuildInfoDto(
      version: '0.5.2',
      versionLabel: '0.5.2',
      relayProtocol: 'v5',
      directProtocol: 'v6',
      license: 'AGPL-3.0-or-later',
      sourceUrl: 'https://github.com/tianguantg/TractorBeam',
    ),
    clientConfig: const bridge.ClientConfigDto(
      selectedRelayId: null,
      selectedSteamId64: null,
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
      active: active,
      status: status,
      generation: BigInt.zero,
      route: bridge.RoomRouteDto.relay,
      transport: bridge.TransportSelection.udp,
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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Room Join Error Localization Tests', () {
    testWidgets('localizes structured relay error keys into Chinese and English', (
      tester,
    ) async {
      late BuildContext zhContext;
      late BuildContext enContext;

      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (ctx) {
              zhContext = ctx;
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('zh'),
        ),
      );

      expect(
        localizeBridgeEvent(zhContext, _event('event.relay_room_joined.room_full')),
        contains('房间已满'),
      );
      expect(
        localizeBridgeEvent(zhContext, _event('event.relay_room_joined.relay_full')),
        contains('Relay 暂时已满'),
      );
      expect(
        localizeBridgeEvent(zhContext, _event('event.relay_room_joined.invalid_admission')),
        contains('无法验证联机码'),
      );
      expect(
        localizeBridgeEvent(zhContext, _event('event.relay_room_joined.dns_failed')),
        contains('无法解析 Relay 服务器地址'),
      );
      expect(
        localizeBridgeEvent(zhContext, _event('event.relay_room_joined.connection_refused')),
        contains('Relay 服务器拒绝连接'),
      );
      expect(
        localizeBridgeEvent(zhContext, _event('event.relay_room_joined.timeout')),
        contains('连接 Relay 服务器超时'),
      );
      expect(
        localizeBridgeEvent(zhContext, _event('event.relay_room_joined.network_unreachable')),
        contains('当前网络无法到达 Relay 服务器'),
      );
      expect(
        localizeBridgeEvent(zhContext, _event('event.relay_room_joined.connection_reset')),
        contains('Relay 连接被中断'),
      );
      expect(
        localizeBridgeEvent(
          zhContext,
          _event('event.relay_room_joined.failure', text: '自定义网络报错信息'),
        ),
        '自定义网络报错信息',
      );

      // Verify English localization
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (ctx) {
              enContext = ctx;
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('en'),
        ),
      );

      expect(
        localizeBridgeEvent(enContext, _event('event.relay_room_joined.room_full')),
        contains('Room is full'),
      );
      expect(
        localizeBridgeEvent(enContext, _event('event.relay_room_joined.relay_full')),
        contains('Relay is temporarily full'),
      );
      expect(
        localizeBridgeEvent(enContext, _event('event.relay_room_joined.invalid_admission')),
        contains('Could not verify room code'),
      );
    });
  });

  group('RoomScreen Persistent Error Card and Join Flow Tests', () {
    testWidgets('shows joining indicator when room status is joining', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TractorBeamController.detached();
      addTearDown(controller.dispose);

      controller.debugAcceptUpdate(
        bridge.AppUpdate(
          revision: BigInt.one,
          snapshot: _testSnapshot(status: bridge.RoomStatusDto.joining),
          events: const [],
        ),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          TractorBeamScope(
            notifier: controller,
            child: const RoomScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('正在加入房间…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'displays persistent error card on async join failure and supports retry and clear',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1100, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = TractorBeamController.detached();
        addTearDown(controller.dispose);

        // Initially idle
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.one,
            snapshot: _testSnapshot(status: bridge.RoomStatusDto.idle),
            events: const [],
          ),
        );

        await tester.pumpWidget(
          _wrapWithApp(
            TractorBeamScope(
              notifier: controller,
              child: const RoomScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('新建房间或输入联机码与好友联机'), findsOneWidget);

        // Trigger an async room join failure event with failed join code
        const failedCode = 'TB-NET-TEST123456';
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(2),
            snapshot: _testSnapshot(status: bridge.RoomStatusDto.failed),
            events: [
              _event('event.relay_room_joined.room_full', value: failedCode),
            ],
          ),
        );

        await tester.pump();

        // Error card is now visible
        expect(find.text('加入房间失败'), findsOneWidget);
        expect(find.textContaining('房间已满'), findsOneWidget);
        expect(find.text('重新加入'), findsOneWidget);
        expect(find.text('清除'), findsOneWidget);

        // Click Clear button -> error card is dismissed back to idle subtitle
        await tester.tap(find.text('清除'));
        await tester.pump();

        expect(find.text('加入房间失败'), findsNothing);
        expect(find.text('新建房间或输入联机码与好友联机'), findsOneWidget);
      },
    );
  });
}
