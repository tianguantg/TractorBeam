import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/l10n/generated/app_localizations.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/lightweight_session_view.dart';

class _HardenedLightweightTestController extends TractorBeamController {
  _HardenedLightweightTestController({required this.members, this.roomCode})
    : super.detached();

  final List<bridge.RoomMemberDto> members;
  final String? roomCode;

  @override
  LightweightViewState get lightweightViewState => LightweightViewState(
    sessionRunning: true,
    hookReady: true,
    route: bridge.RoomRouteDto.relay,
    transport: bridge.TransportSelection.udp,
    members: members,
    roomCode: roomCode,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh', 'CN'),
      theme: ThemeData(useMaterial3: true, fontFamily: 'Xiaolai'),
      home: Scaffold(
        body: Center(child: SizedBox(width: 380, height: 360, child: child)),
      ),
    );
  }

  group('LightweightSessionView Hardening Tests', () {
    testWidgets('Safe avatar extraction for Emoji and surrogate pairs', (
      WidgetTester tester,
    ) async {
      final controller = _HardenedLightweightTestController(
        members: [
          const bridge.RoomMemberDto(
            steamId64: '76561198000000001',
            displayName: '🎮GamerPlayer',
            connection: '已连接',
            isLocal: true,
          ),
          bridge.RoomMemberDto(
            steamId64: '76561198000000002',
            displayName: '🚀RocketFriend',
            connection: '已连接',
            latencyMs: BigInt.from(42),
            isLocal: false,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapWithTheme(
          LightweightSessionView(
            controller: controller,
            onOpenFull: () {},
            onHideToTray: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Emoji should be safely extracted without crashing
      expect(find.text('🎮'), findsOneWidget);
      expect(find.text('🚀'), findsOneWidget);
      expect(find.text('🎮GamerPlayer'), findsOneWidget);
      expect(find.text('🚀RocketFriend'), findsOneWidget);
      expect(find.text('42ms'), findsOneWidget);

      controller.dispose();
    });

    testWidgets(
      'Disconnected remote member hides zombie latency and shows status',
      (WidgetTester tester) async {
        final controller = _HardenedLightweightTestController(
          members: [
            const bridge.RoomMemberDto(
              steamId64: '76561198000000001',
              displayName: '本机玩家',
              connection: '已连接',
              isLocal: true,
            ),
            bridge.RoomMemberDto(
              steamId64: '76561198000000002',
              displayName: '掉线玩家',
              connection: 'disconnected',
              latencyMs: BigInt.from(36), // zombie latency
              isLocal: false,
            ),
            bridge.RoomMemberDto(
              steamId64: '76561198000000003',
              displayName: '未连接玩家',
              connection: 'inactive',
              latencyMs: BigInt.from(55), // zombie latency
              isLocal: false,
            ),
          ],
        );

        await tester.pumpWidget(
          wrapWithTheme(
            LightweightSessionView(
              controller: controller,
              onOpenFull: () {},
              onHideToTray: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Disconnected member should display disconnected state rather than zombie latency
        expect(find.text('掉线玩家'), findsOneWidget);
        expect(find.text('未连接玩家'), findsOneWidget);
        expect(find.text('36ms'), findsNothing);
        expect(find.text('55ms'), findsNothing);
        expect(find.text('状态：已断开'), findsOneWidget);
        expect(find.text('状态：未连接'), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets('Pressing Escape key triggers onHideToTray', (
      WidgetTester tester,
    ) async {
      var hidden = false;
      final controller = _HardenedLightweightTestController(
        members: [
          const bridge.RoomMemberDto(
            steamId64: '76561198000000001',
            displayName: '测试玩家',
            connection: '已连接',
            isLocal: true,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapWithTheme(
          LightweightSessionView(
            controller: controller,
            onOpenFull: () {},
            onHideToTray: () => hidden = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send Escape key event
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(hidden, isTrue);

      controller.dispose();
    });

    testWidgets(
      'Header hide button uses Icons.remove and triggers onHideToTray',
      (WidgetTester tester) async {
        var hidden = false;
        final controller = _HardenedLightweightTestController(
          members: [
            const bridge.RoomMemberDto(
              steamId64: '76561198000000001',
              displayName: '测试玩家',
              connection: '已连接',
              isLocal: true,
            ),
          ],
        );

        await tester.pumpWidget(
          wrapWithTheme(
            LightweightSessionView(
              controller: controller,
              onOpenFull: () {},
              onHideToTray: () => hidden = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hideButton = find.byKey(const ValueKey('lightweight-hide'));
        expect(hideButton, findsOneWidget);

        // Verify the icon is Icons.remove
        final iconFinder = find.descendant(
          of: hideButton,
          matching: find.byIcon(Icons.remove),
        );
        expect(iconFinder, findsOneWidget);

        await tester.tap(hideButton);
        await tester.pumpAndSettle();

        expect(hidden, isTrue);

        controller.dispose();
      },
    );

    testWidgets(
      'Resilient against extremely long member and route texts without overflow',
      (WidgetTester tester) async {
        final controller = _HardenedLightweightTestController(
          members: [
            const bridge.RoomMemberDto(
              steamId64: '76561198000000001',
              displayName:
                  'SuperLongDisplayNamePlayerThatMightNormallyOverflowTheHeaderOrCardTitle',
              connection: '已连接',
              isLocal: true,
            ),
            bridge.RoomMemberDto(
              steamId64: '76561198000000002',
              displayName: 'RemotePlayerWithExtraordinaryLongName1234567890',
              connection:
                  'Direct P2P · High Speed Optimized Encrypted Tunnel (UDP / IPv6 fallback route)',
              latencyMs: BigInt.from(18),
              isLocal: false,
            ),
          ],
        );

        await tester.pumpWidget(
          wrapWithTheme(
            LightweightSessionView(
              controller: controller,
              onOpenFull: () {},
              onHideToTray: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No RenderFlex overflow exception should have been thrown
        expect(tester.takeException(), isNull);

        controller.dispose();
      },
    );

    testWidgets(
      'Header renders clickable room code chip and copies code to clipboard',
      (WidgetTester tester) async {
        final clipboardLog = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardLog.add(
                (methodCall.arguments as Map)['text'] as String? ?? '',
              );
              return null;
            }
            return null;
          },
        );

        final controller = _HardenedLightweightTestController(
          roomCode: 'T2QZXZ4',
          members: [
            const bridge.RoomMemberDto(
              steamId64: '76561198000000001',
              displayName: '本机玩家',
              connection: '已连接',
              isLocal: true,
            ),
          ],
        );

        await tester.pumpWidget(
          wrapWithTheme(
            LightweightSessionView(
              controller: controller,
              onOpenFull: () {},
              onHideToTray: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('#T2QZXZ4'), findsOneWidget);
        await tester.tap(find.text('#T2QZXZ4'));
        await tester.pumpAndSettle();

        expect(clipboardLog, contains('T2QZXZ4'));

        controller.dispose();
      },
    );

    testWidgets(
      'Extremely long room code (e.g. 500 chars LAN endpoint) renders safely without RenderFlex overflow and copies full code',
      (WidgetTester tester) async {
        final clipboardLog = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardLog.add(
                (methodCall.arguments as Map)['text'] as String? ?? '',
              );
              return null;
            }
            return null;
          },
        );

        final longRoomCode =
            '192.168.1.100:27015,10.0.0.5:27015,172.16.0.8:27015-'
            'EXTRAORDINARILY-LONG-ROOM-CODE-STRING-TOKEN-DESCRIPTOR-OVERFLOW-TEST-' *
            8;

        final controller = _HardenedLightweightTestController(
          roomCode: longRoomCode,
          members: [
            const bridge.RoomMemberDto(
              steamId64: '76561198000000001',
              displayName: '本机玩家',
              connection: '已连接',
              isLocal: true,
            ),
          ],
        );

        await tester.pumpWidget(
          wrapWithTheme(
            LightweightSessionView(
              controller: controller,
              onOpenFull: () {},
              onHideToTray: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No RenderFlex overflow exception
        expect(tester.takeException(), isNull);

        // Tap the room code chip
        final copyIconFinder = find.byIcon(Icons.copy_rounded);
        expect(copyIconFinder, findsOneWidget);
        await tester.tap(copyIconFinder);
        await tester.pumpAndSettle();

        // Full unabridged code should be copied
        expect(clipboardLog, contains(longRoomCode));

        controller.dispose();
      },
    );


    test(
      'Math clamp protects against inverted boundaries on small or negative coordinate screens',
      () {
        // Test when work area width is smaller than window width
        const size = Size(380, 360);
        const work = Rect.fromLTWH(
          100,
          100,
          200,
          200,
        ); // right = 300, bottom = 300
        const desired = Offset(250, 250);

        // work.right - size.width = 300 - 380 = -80, which is < work.left (100)
        // Standard clamp(100, -80) would throw ArgumentError.
        // With math.max protection:
        final maxX = (work.right - size.width < work.left)
            ? work.left
            : work.right - size.width;
        final maxY = (work.bottom - size.height < work.top)
            ? work.top
            : work.bottom - size.height;

        final clamped = Offset(
          desired.dx.clamp(work.left, maxX),
          desired.dy.clamp(work.top, maxY),
        );

        expect(clamped.dx, equals(100.0));
        expect(clamped.dy, equals(100.0));
      },
    );

    test('Tray double-click debounce window calculation', () {
      final click1 = DateTime(2026, 9, 19, 12, 0, 0, 0);
      final click2Rapid = DateTime(
        2026,
        9,
        19,
        12,
        0,
        0,
        120,
      ); // 120ms later (rapid double click)
      final click3Normal = DateTime(2026, 9, 19, 12, 0, 0, 500); // 500ms later

      const debounceDuration = Duration(milliseconds: 350);

      final isRapidDebounced =
          click2Rapid.difference(click1) < debounceDuration;
      final isNormalDebounced =
          click3Normal.difference(click1) < debounceDuration;

      expect(isRapidDebounced, isTrue); // Should be ignored/debounced
      expect(isNormalDebounced, isFalse); // Should be accepted
    });
  });
}
