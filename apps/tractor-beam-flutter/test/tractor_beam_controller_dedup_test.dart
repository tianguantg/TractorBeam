import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/models/tractor_beam_controller.dart';

void main() {
  test('revision-only and equal fresh lists do not notify listeners', () {
    final controller = TractorBeamController.detached();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.debugAcceptUpdate(_update(1));
    expect(notifications, 1);

    controller.debugAcceptUpdate(_update(2));
    expect(controller.revision, BigInt.from(2));
    expect(notifications, 1);
  });

  test('a visible member change notifies exactly once', () {
    final controller = TractorBeamController.detached();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.debugAcceptUpdate(_update(1));
    controller.debugAcceptUpdate(_update(2, latencyMs: 31));

    expect(notifications, 2);
  });

  test('one-shot event notifies even when snapshot is unchanged', () {
    final controller = TractorBeamController.detached();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.debugAcceptUpdate(_update(1));
    controller.debugAcceptUpdate(
      _update(
        2,
        events: const [
          bridge.AppEvent(
            code: 'test_event',
            success: true,
            displayText: 'done',
            message: bridge.LocalizedMessageDto(
              key: 'event.test',
              args: [],
              fallbackZh: '完成',
            ),
          ),
        ],
      ),
    );

    expect(notifications, 2);
    expect(controller.latestEvent?.code, 'test_event');
  });
}

bridge.AppUpdate _update(
  int revision, {
  int? latencyMs,
  List<bridge.AppEvent> events = const [],
}) => bridge.AppUpdate(
  revision: BigInt.from(revision),
  snapshot: _snapshot(latencyMs: latencyMs),
  events: List<bridge.AppEvent>.of(events),
);

bridge.AppSnapshot _snapshot({int? latencyMs}) => bridge.AppSnapshot(
  profile: bridge.SnapshotProfileDto.full,
  bootstrap: bridge.BootstrapStateDto.ready,
  canMutate: true,
  shutdownState: bridge.ShutdownStateDto.running,
  buildInfo: const bridge.BuildInfoDto(
    version: '0.5.2',
    versionLabel: '0.5.2',
    releaseVersion: '0.5.2-tb.1',
    relayProtocol: 'v5',
    directProtocol: 'v6',
    license: 'AGPL-3.0-or-later',
    sourceUrl: 'https://github.com/tianguantg/TractorBeam',
  ),
  clientConfig: bridge.ClientConfigDto(
    selectedRelayId: 'relay-1',
    selectedSteamId64: '76561198000000000',
    mode: bridge.SessionModeDto.pure,
    transport: bridge.TransportSelection.udp,
    relays: const [
      bridge.RelayDto(
        id: 'relay-1',
        name: 'Relay',
        host: 'relay.example.test',
        port: 25910,
        supportsUdp: true,
        supportsTcp: true,
        defaultTransport: bridge.TransportSelection.udp,
      ),
    ],
    accounts: const [
      bridge.SteamAccountDto(
        steamId64: '76561198000000000',
        displayName: 'Player',
        mostRecent: true,
        isManual: false,
      ),
    ],
    warnings: List<String>.of(const ['warning']),
  ),
  session: const bridge.SessionSnapshot(
    status: bridge.SessionStatusDto.idle,
    smoothness: 'idle',
  ),
  room: bridge.RoomSnapshot(
    active: true,
    status: bridge.RoomStatusDto.active,
    generation: BigInt.one,
    route: bridge.RoomRouteDto.relay,
    transport: bridge.TransportSelection.udp,
    joinCode: 'opaque-code',
    members: [
      bridge.RoomMemberDto(
        steamId64: '76561198000000000',
        displayName: 'Player',
        connection: 'connected',
        latencyMs: latencyMs == null ? null : BigInt.from(latencyMs),
        isLocal: false,
      ),
    ],
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
  connectionTests: List<bridge.ConnectionTestDto>.of(const []),
  logs: List<bridge.LogEntryDto>.of(const []),
  lanAdapters: [
    bridge.LanAdapterDto(
      id: 'adapter-1',
      name: 'Ethernet',
      interfaceIndex: 1,
      addresses: List<String>.of(const ['192.0.2.1']),
      recommended: true,
    ),
  ],
  lanJoinEndpoints: List<String>.of(const ['192.0.2.1:25910']),
  update: const bridge.UpdateSnapshotDto(
    status: bridge.UpdateStatusDto.idle,
    channelUrl: 'https://github.com/tianguantg/TractorBeam/releases',
  ),
);
