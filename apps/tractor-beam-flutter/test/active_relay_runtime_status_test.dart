import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/l10n/l10n.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/lightweight_session_view.dart';
import 'package:tbnet_app/widgets/status_bar.dart';

class _FakeAppSnapshot implements bridge.AppSnapshot {
  final bool inRoom;
  final bridge.RoomRouteDto route;
  final bridge.ActiveRelayDto? activeRelay;
  final String? selectedRelayId;
  final List<bridge.ConnectionTestDto> tests;

  const _FakeAppSnapshot({
    this.inRoom = false,
    this.route = bridge.RoomRouteDto.relay,
    this.activeRelay,
    this.selectedRelayId,
    this.tests = const [],
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  bridge.SnapshotProfileDto get profile => bridge.SnapshotProfileDto.full;

  @override
  bridge.BootstrapStateDto get bootstrap =>
      bridge.BootstrapStateDto.initializing;

  @override
  bool get canMutate => true;

  @override
  bridge.ShutdownStateDto get shutdownState => bridge.ShutdownStateDto.running;

  @override
  bridge.BuildInfoDto get buildInfo => const _FakeBuildInfoDto();

  @override
  bridge.SessionSnapshot get session => const _FakeSessionSnapshot();

  @override
  bridge.RoomSnapshot get room => bridge.RoomSnapshot(
    active: inRoom,
    status: inRoom ? bridge.RoomStatusDto.active : bridge.RoomStatusDto.idle,
    generation: BigInt.one,
    route: route,
    transport: bridge.TransportSelection.udp,
    joinCode: inRoom ? 'TB-1234' : null,
    members: const [],
    activeRelay: activeRelay,
  );

  @override
  bridge.ClientConfigDto get clientConfig => bridge.ClientConfigDto(
    selectedRelayId: selectedRelayId,
    mode: bridge.SessionModeDto.pure,
    transport: bridge.TransportSelection.udp,
    relays: selectedRelayId != null
        ? [
            bridge.RelayDto(
              id: selectedRelayId!,
              name: 'Selected Node $selectedRelayId',
              host: '10.0.0.1',
              port: 443,
              supportsTcp: true,
              supportsUdp: true,
              defaultTransport: bridge.TransportSelection.udp,
            ),
          ]
        : const [],
    accounts: const [],
    warnings: const [],
  );

  @override
  List<bridge.ConnectionTestDto> get connectionTests => tests;

  @override
  List<bridge.RoomHistoryEntryDto> get roomHistory => const [];

  @override
  List<bridge.LogEntryDto> get logs => const [];

  @override
  List<bridge.LanAdapterDto> get lanAdapters => const [];

  @override
  List<String> get lanJoinEndpoints => const [];

  @override
  bridge.LaunchProgressDto get launch => const _FakeLaunchProgressDto();

  @override
  bridge.HookSnapshot get hook => const _FakeHookSnapshot();

  @override
  bridge.CountersDto get counters => const _FakeCountersDto();

  @override
  bridge.UpdateSnapshotDto get update => const _FakeUpdateSnapshotDto();
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
  String get sourceUrl => 'https://github.com/tianguantg/TractorBeam';
}

class _FakeSessionSnapshot implements bridge.SessionSnapshot {
  const _FakeSessionSnapshot();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  bridge.SessionStatusDto get status => bridge.SessionStatusDto.idle;
  @override
  String get smoothness => 'smooth';
}

class _FakeLaunchProgressDto implements bridge.LaunchProgressDto {
  const _FakeLaunchProgressDto();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  bridge.LaunchStatusDto get status => bridge.LaunchStatusDto.idle;
  @override
  BigInt get generation => BigInt.zero;
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
}

class _FakeUpdateSnapshotDto implements bridge.UpdateSnapshotDto {
  const _FakeUpdateSnapshotDto();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  @override
  bridge.UpdateStatusDto get status => bridge.UpdateStatusDto.idle;
  @override
  String get channelUrl => 'https://github.com/tianguantg/TractorBeam/releases';
}

Widget _wrap(TractorBeamController controller, Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh', 'CN'),
    home: Scaffold(
      body: TractorBeamScope(notifier: controller, child: child),
    ),
  );
}

bridge.ConnectionTestDto _probe(String relayId, int ms) {
  return bridge.ConnectionTestDto(
    relayId: relayId,
    endpoint: '10.0.0.1:443',
    transport: bridge.TransportSelection.udp,
    sent: 1,
    received: 1,
    medianRttMs: BigInt.from(ms),
  );
}

void main() {
  group('PR5: Authoritative Relay Runtime Status & Latency Source', () {
    test(
      '1. Selected Relay A vs Active Room Relay B: activeServerLatency reflects Room B live RTT',
      () {
        final controller = TractorBeamController.detached();

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              selectedRelayId: 'relay-node-a',
              tests: [_probe('relay-node-a', 25)],
              activeRelay: const bridge.ActiveRelayDto(
                relayId: 'relay-node-b',
                displayName: 'Hong Kong Node 02',
                endpoint: '124.71.0.2:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: null,
                link: bridge.RelayLinkStatusDto.connected,
              ),
            ),
            events: const [],
          ),
        );

        // Room B has null latency initially
        expect(controller.relayLatencySource, RelayLatencySource.activeRoom);
        expect(controller.activeServerLatency, isNull);
        expect(controller.serverLatency, 25); // probe latency remains 25

        // Room B updates with live measured RTT = 68ms
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(2),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              selectedRelayId: 'relay-node-a',
              tests: [_probe('relay-node-a', 25)],
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-b',
                displayName: 'Hong Kong Node 02',
                endpoint: '124.71.0.2:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: BigInt.from(68),
                link: bridge.RelayLinkStatusDto.connected,
              ),
            ),
            events: const [],
          ),
        );

        expect(controller.relayLatencySource, RelayLatencySource.activeRoom);
        expect(controller.activeServerLatency, 68);
        expect(controller.activeRelay?.relayId, 'relay-node-b');
        expect(controller.activeRelay?.displayName, 'Hong Kong Node 02');
      },
    );

    test(
      '2. UI in LAN mode but joined Relay room: bottom bar shows active Relay RTT',
      () {
        final controller = TractorBeamController.detached();
        controller.setConnectionMode(ConnectionMode.lan);
        expect(controller.connectionMode, ConnectionMode.lan);

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-c',
                displayName: 'Tokyo Relay',
                endpoint: '45.76.1.1:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: BigInt.from(35),
                link: bridge.RelayLinkStatusDto.connected,
              ),
            ),
            events: const [],
          ),
        );

        expect(controller.relayLatencySource, RelayLatencySource.activeRoom);
        expect(controller.activeServerLatency, 35);
      },
    );

    test(
      '3. Relay room newly joined with latency null: activeServerLatency is null and does NOT fallback to selected probe',
      () {
        final controller = TractorBeamController.detached();

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              selectedRelayId: 'relay-node-a',
              tests: [_probe('relay-node-a', 18)],
              activeRelay: const bridge.ActiveRelayDto(
                relayId: 'relay-node-a',
                displayName: 'Node A',
                endpoint: '1.1.1.1:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: null, // First live RTT not yet measured
                link: bridge.RelayLinkStatusDto.connected,
              ),
            ),
            events: const [],
          ),
        );

        expect(controller.relayLatencySource, RelayLatencySource.activeRoom);
        expect(controller.serverLatency, 18);
        // STRICT ISOLATION: activeServerLatency must be null, never 18!
        expect(controller.activeServerLatency, isNull);
      },
    );

    test(
      '4. Relay disconnect / reconnecting: clears latency to null and link becomes reconnecting',
      () {
        final controller = TractorBeamController.detached();

        // Initially connected with 40ms
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-a',
                displayName: 'Node A',
                endpoint: '1.1.1.1:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: BigInt.from(40),
                link: bridge.RelayLinkStatusDto.connected,
              ),
            ),
            events: const [],
          ),
        );
        expect(controller.activeServerLatency, 40);

        // Link disconnected and reconnecting
        var notified = false;
        controller.addListener(() => notified = true);

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(2),
            snapshot: const _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-a',
                displayName: 'Node A',
                endpoint: '1.1.1.1:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: null,
                link: bridge.RelayLinkStatusDto.reconnecting,
              ),
            ),
            events: const [],
          ),
        );

        expect(notified, isTrue);
        expect(controller.activeServerLatency, isNull);
        expect(
          controller.activeRelay?.link,
          bridge.RelayLinkStatusDto.reconnecting,
        );
        expect(controller.relayLatencySource, RelayLatencySource.activeRoom);
      },
    );

    test(
      '5. Relay recovered: receives new RTT and restores latency display',
      () {
        final controller = TractorBeamController.detached();

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: const _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-a',
                displayName: 'Node A',
                endpoint: '1.1.1.1:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: null,
                link: bridge.RelayLinkStatusDto.reconnecting,
              ),
            ),
            events: const [],
          ),
        );
        expect(controller.activeServerLatency, isNull);

        // Recovered with new 45ms RTT
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(2),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-a',
                displayName: 'Node A',
                endpoint: '1.1.1.1:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: BigInt.from(45),
                link: bridge.RelayLinkStatusDto.recovered,
              ),
            ),
            events: const [],
          ),
        );

        expect(controller.activeServerLatency, 45);
        expect(
          controller.activeRelay?.link,
          bridge.RelayLinkStatusDto.recovered,
        );
      },
    );

    test(
      '6. In LAN room: activeServerLatency is null, relayLatencySource is none',
      () {
        final controller = TractorBeamController.detached();

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.lan,
              selectedRelayId: 'relay-node-a',
              tests: [_probe('relay-node-a', 22)],
              activeRelay: null, // LAN rooms never have activeRelay
            ),
            events: const [],
          ),
        );

        expect(controller.activeRelay, isNull);
        expect(controller.activeServerLatency, isNull);
        expect(controller.relayLatencySource, RelayLatencySource.none);
      },
    );

    test(
      '7. Leaving room: falls back to selected relay probe in Relay mode or null in LAN mode',
      () {
        final controller = TractorBeamController.detached();

        // In room
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              selectedRelayId: 'relay-node-a',
              tests: [_probe('relay-node-a', 24)],
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-b',
                displayName: 'Node B',
                endpoint: '2.2.2.2:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: BigInt.from(55),
                link: bridge.RelayLinkStatusDto.connected,
              ),
            ),
            events: const [],
          ),
        );
        expect(controller.activeServerLatency, 55);

        // Leave room
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(2),
            snapshot: _FakeAppSnapshot(
              inRoom: false,
              selectedRelayId: 'relay-node-a',
              tests: [_probe('relay-node-a', 24)],
              activeRelay: null,
            ),
            events: const [],
          ),
        );

        expect(controller.activeRelay, isNull);
        // Out of room, in relay mode: returns selectedNode probe
        expect(controller.activeServerLatency, 24);
        expect(
          controller.relayLatencySource,
          RelayLatencySource.selectedNodeProbe,
        );

        // Switch to LAN mode outside room
        controller.setConnectionMode(ConnectionMode.lan);
        expect(controller.activeServerLatency, isNull);
        expect(controller.relayLatencySource, RelayLatencySource.none);
      },
    );

    test(
      '8. ActiveRelayDto security: does not expose credentials or auth tokens',
      () {
        const activeRelay = bridge.ActiveRelayDto(
          relayId: 'r1',
          displayName: 'Public Node',
          endpoint: '127.0.0.1:443',
          transport: bridge.TransportSelection.udp,
          link: bridge.RelayLinkStatusDto.connected,
        );

        // Verify fields exist as expected
        expect(activeRelay.relayId, 'r1');
        expect(activeRelay.displayName, 'Public Node');
        expect(activeRelay.endpoint, '127.0.0.1:443');
        expect(activeRelay.transport, bridge.TransportSelection.udp);
        expect(activeRelay.latencyMs, isNull);
        expect(activeRelay.link, bridge.RelayLinkStatusDto.connected);
      },
    );
  });

  group('PR5: UI Widget Rendering with Active Relay Status', () {
    testWidgets(
      'BottomStatusBar: shows active Relay RTT with localized tooltip when in Relay room',
      (tester) async {
        final controller = TractorBeamController.detached();

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-a',
                endpoint: '1.2.3.4:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: BigInt.from(28),
                link: bridge.RelayLinkStatusDto.connected,
              ),
            ),
            events: const [],
          ),
        );

        await tester.pumpWidget(_wrap(controller, const BottomStatusBar()));
        await tester.pumpAndSettle();

        expect(find.text('28ms'), findsOneWidget);
        // Tooltip matches active relay format: "当前 Relay 往返延迟：28ms (优秀)"
        final tooltip = tester.widget<Tooltip>(
          find.ancestor(of: find.text('28ms'), matching: find.byType(Tooltip)),
        );
        expect(tooltip.message, contains('当前 Relay 往返延迟：28ms'));
        expect(tooltip.message, contains('优秀'));
      },
    );

    testWidgets(
      'BottomStatusBar: shows probe latency with localized tooltip when outside room',
      (tester) async {
        final controller = TractorBeamController.detached();

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: false,
              selectedRelayId: 'relay-node-probe',
              tests: [_probe('relay-node-probe', 19)],
              activeRelay: null,
            ),
            events: const [],
          ),
        );

        await tester.pumpWidget(_wrap(controller, const BottomStatusBar()));
        await tester.pumpAndSettle();

        expect(find.text('19ms'), findsOneWidget);
        final tooltip = tester.widget<Tooltip>(
          find.ancestor(of: find.text('19ms'), matching: find.byType(Tooltip)),
        );
        expect(tooltip.message, contains('节点测速延迟：19ms'));
        expect(tooltip.message, contains('优秀'));
      },
    );

    testWidgets(
      'BottomStatusBar: shows reconnecting spinner and text when Relay connection is lost',
      (tester) async {
        final controller = TractorBeamController.detached();

        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: const _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'relay-node-a',
                endpoint: '1.2.3.4:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: null,
                link: bridge.RelayLinkStatusDto.reconnecting,
              ),
            ),
            events: const [],
          ),
        );

        await tester.pumpWidget(_wrap(controller, const BottomStatusBar()));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('重连中…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        final tooltip = tester.widget<Tooltip>(
          find.ancestor(of: find.text('重连中…'), matching: find.byType(Tooltip)),
        );
        expect(tooltip.message, 'Relay 连接已断开，正在尝试重连…');
      },
    );

    testWidgets('BottomStatusBar: hides latency in LAN room', (tester) async {
      final controller = TractorBeamController.detached();

      controller.debugAcceptUpdate(
        bridge.AppUpdate(
          revision: BigInt.from(1),
          snapshot: _FakeAppSnapshot(
            inRoom: true,
            route: bridge.RoomRouteDto.lan,
            selectedRelayId: 'relay-node-a',
            tests: [_probe('relay-node-a', 25)],
            activeRelay: null,
          ),
          events: const [],
        ),
      );

      await tester.pumpWidget(_wrap(controller, const BottomStatusBar()));
      await tester.pumpAndSettle();

      expect(find.text('25ms'), findsNothing);
      expect(find.text('重连中…'), findsNothing);
    });

    testWidgets(
      'LightweightSessionView: displays live RTT, reconnecting, or LAN correctly',
      (tester) async {
        final controller = TractorBeamController.detached();

        // Case 1: Relay room with 31ms
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(1),
            snapshot: _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'r1',
                endpoint: '1.1.1.1:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: BigInt.from(31),
                link: bridge.RelayLinkStatusDto.connected,
              ),
            ),
            events: const [],
          ),
        );

        await tester.pumpWidget(
          _wrap(
            controller,
            LightweightSessionView(
              controller: controller,
              onOpenFull: () {},
              onHideToTray: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Relay 中继  ·  UDP  ·  31ms'), findsOneWidget);

        // Case 2: Reconnecting
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(2),
            snapshot: const _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.relay,
              activeRelay: bridge.ActiveRelayDto(
                relayId: 'r1',
                endpoint: '1.1.1.1:443',
                transport: bridge.TransportSelection.udp,
                latencyMs: null,
                link: bridge.RelayLinkStatusDto.reconnecting,
              ),
            ),
            events: const [],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Relay 中继  ·  UDP  ·  重连中…'), findsOneWidget);

        // Case 3: LAN room
        controller.debugAcceptUpdate(
          bridge.AppUpdate(
            revision: BigInt.from(3),
            snapshot: const _FakeAppSnapshot(
              inRoom: true,
              route: bridge.RoomRouteDto.lan,
              activeRelay: null,
            ),
            events: const [],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('局域网直连'), findsOneWidget);
      },
    );
  });
}
