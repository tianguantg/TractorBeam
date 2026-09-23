import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/l10n/generated/app_localizations.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/lightweight_session_view.dart';

class _FakeLightweightController extends TractorBeamController {
  _FakeLightweightController({
    this.running = true,
    this.hookReady = true,
    this.activeMode = bridge.SessionModeDto.pure,
    this.delay = 2,
    this.delayError,
  })  : membersList = const [
          bridge.RoomMemberDto(
            steamId64: '76561198000000001',
            displayName: '本地玩家',
            connection: 'connected',
            isLocal: true,
          ),
        ],
        super.detached();

  bool running;
  bool hookReady;
  bridge.SessionModeDto? activeMode;
  int? delay;
  String? delayError;
  bridge.RoomRouteDto route = bridge.RoomRouteDto.relay;
  bridge.TransportSelection transport = bridge.TransportSelection.udp;
  String? joinCode = 'TB-NET-TEST1234';
  List<bridge.RoomMemberDto> membersList;

  int? lastWrittenDelay;
  bool shouldRejectWrite = false;
  bool readCalled = false;
  BigInt _rev = BigInt.one;

  @override
  bool get isNative => false;

  @override
  bool get isSessionRunning => running;

  @override
  BigInt get revision => _rev;

  @override
  LightweightViewState get lightweightViewState => LightweightViewState(
        sessionRunning: running,
        hookReady: hookReady,
        route: route,
        transport: transport,
        members: membersList,
        roomCode: joinCode,
        activeMode: activeMode,
        inputDelay: delay,
        inputDelayError: delayError,
      );

  @override
  bridge.CommandReceipt writeInputDelay(int value) {
    if (shouldRejectWrite) {
      return const bridge.CommandReceipt(
        accepted: false,
        rejection: bridge.CommandRejection(
          code: 'rejected',
          displayText: 'Write rejected',
          message: bridge.LocalizedMessageDto(
            key: 'error.hook_not_ready',
            args: [],
            fallbackZh: 'Hook 尚未就绪，请稍后再试。',
          ),
        ),
      );
    }
    lastWrittenDelay = value;
    delay = value;
    _rev = _rev + BigInt.one;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt readInputDelay() {
    readCalled = true;
    _rev = _rev + BigInt.one;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  void updateDelay(int? newDelay, {String? newError}) {
    delay = newDelay;
    delayError = newError;
    _rev = _rev + BigInt.one;
    notifyListeners();
  }

  void updateActiveMode(bridge.SessionModeDto newMode) {
    activeMode = newMode;
    _rev = _rev + BigInt.one;
    notifyListeners();
  }
}

Widget _wrap(Widget child, {Locale locale = const Locale('zh', 'CN')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: SizedBox(
        width: 380,
        height: 360,
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LightweightViewState Unit Tests', () {
    test('equality and hashCode include activeMode, inputDelay, and inputDelayError', () {
      const state1 = LightweightViewState(
        sessionRunning: true,
        hookReady: true,
        route: bridge.RoomRouteDto.relay,
        transport: bridge.TransportSelection.udp,
        members: [],
        roomCode: 'ABC',
        activeMode: bridge.SessionModeDto.pure,
        inputDelay: 2,
        inputDelayError: null,
      );

      const state2 = LightweightViewState(
        sessionRunning: true,
        hookReady: true,
        route: bridge.RoomRouteDto.relay,
        transport: bridge.TransportSelection.udp,
        members: [],
        roomCode: 'ABC',
        activeMode: bridge.SessionModeDto.pure,
        inputDelay: 2,
        inputDelayError: null,
      );

      const stateDifferentDelay = LightweightViewState(
        sessionRunning: true,
        hookReady: true,
        route: bridge.RoomRouteDto.relay,
        transport: bridge.TransportSelection.udp,
        members: [],
        roomCode: 'ABC',
        activeMode: bridge.SessionModeDto.pure,
        inputDelay: 3,
        inputDelayError: null,
      );

      const stateOfficial = LightweightViewState(
        sessionRunning: true,
        hookReady: true,
        route: bridge.RoomRouteDto.relay,
        transport: bridge.TransportSelection.udp,
        members: [],
        roomCode: 'ABC',
        activeMode: bridge.SessionModeDto.official,
        inputDelay: 2,
        inputDelayError: null,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(stateDifferentDelay)));
      expect(state1, isNot(equals(stateOfficial)));

      expect(state1.isOfficial, isFalse);
      expect(state1.canEditInputDelay, isTrue);

      expect(stateOfficial.isOfficial, isTrue);
      expect(stateOfficial.canEditInputDelay, isFalse);
    });

    test('canEditInputDelay requires sessionRunning to be true', () {
      final controllerIdle = _FakeLightweightController(running: false);
      expect(controllerIdle.canEditInputDelay(), isFalse);
      expect(controllerIdle.lightweightViewState.canEditInputDelay, isFalse);
      controllerIdle.dispose();

      final controllerRunning = _FakeLightweightController(running: true);
      expect(controllerRunning.canEditInputDelay(), isTrue);
      expect(controllerRunning.lightweightViewState.canEditInputDelay, isTrue);
      controllerRunning.dispose();
    });

    test('hookReady reflects controller state in lightweightViewState', () {
      final controllerNotReady = _FakeLightweightController(hookReady: false);
      expect(controllerNotReady.lightweightViewState.hookReady, isFalse);
      controllerNotReady.dispose();

      final controllerReady = _FakeLightweightController(hookReady: true);
      expect(controllerReady.lightweightViewState.hookReady, isTrue);
      controllerReady.dispose();
    });
  });

  group('LightweightSessionView Controls Tests', () {
    testWidgets('Header displays "← 主界面" and tapping triggers onOpenFull', (tester) async {
      final controller = _FakeLightweightController();
      var openedFull = false;

      await tester.pumpWidget(
        _wrap(
          LightweightSessionView(
            controller: controller,
            onOpenFull: () => openedFull = true,
            onHideToTray: () {},
          ),
        ),
      );
      await tester.pump();

      // Find the explicit "← 主界面" text and button key
      expect(find.text('← 主界面'), findsOneWidget);
      final openFullFinder = find.byKey(const ValueKey('lightweight-open-full'));
      expect(openFullFinder, findsOneWidget);

      await tester.tap(openFullFinder);
      await tester.pump();

      expect(openedFull, isTrue);
      controller.dispose();
    });

    testWidgets('Header displays "← Main UI" in English locale', (tester) async {
      final controller = _FakeLightweightController();
      var openedFull = false;

      await tester.pumpWidget(
        _wrap(
          LightweightSessionView(
            controller: controller,
            onOpenFull: () => openedFull = true,
            onHideToTray: () {},
          ),
          locale: const Locale('en', 'US'),
        ),
      );
      await tester.pump();

      expect(find.text('← Main UI'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('lightweight-open-full')));
      await tester.pump();

      expect(openedFull, isTrue);
      controller.dispose();
    });

    testWidgets('In-game input delay stepper can increment, decrement, and apply', (tester) async {
      final controller = _FakeLightweightController(delay: 2);

      await tester.pumpWidget(
        _wrap(
          LightweightSessionView(
            controller: controller,
            onOpenFull: () {},
            onHideToTray: () {},
          ),
        ),
      );
      await tester.pump();

      // Verify delay title, initial value 2 帧, and buttons
      expect(find.text('输入延迟'), findsOneWidget);
      expect(find.text('2 帧'), findsOneWidget);
      expect(find.text('应用'), findsOneWidget);

      final minusBtn = find.byKey(const ValueKey('lightweight-delay-minus'));
      final plusBtn = find.byKey(const ValueKey('lightweight-delay-plus'));
      final readBtn = find.byKey(const ValueKey('lightweight-delay-read'));
      final applyBtn = find.byKey(const ValueKey('lightweight-delay-apply'));

      expect(minusBtn, findsOneWidget);
      expect(plusBtn, findsOneWidget);
      expect(readBtn, findsOneWidget);
      expect(applyBtn, findsOneWidget);

      // Decrement: 2 -> 1
      await tester.tap(minusBtn);
      await tester.pump();
      expect(find.text('1 帧'), findsOneWidget);

      // Decrement: 1 -> 0
      await tester.tap(minusBtn);
      await tester.pump();
      expect(find.text('0 帧'), findsOneWidget);

      // Decrement at 0 should stay at 0
      await tester.tap(minusBtn);
      await tester.pump();
      expect(find.text('0 帧'), findsOneWidget);

      // Increment: 0 -> 1 -> 2 -> 3
      await tester.tap(plusBtn);
      await tester.pump();
      await tester.tap(plusBtn);
      await tester.pump();
      await tester.tap(plusBtn);
      await tester.pump();
      expect(find.text('3 帧'), findsOneWidget);

      // Tap apply button -> controller receives writeInputDelay(3)
      await tester.tap(applyBtn);
      await tester.pump();

      expect(controller.lastWrittenDelay, equals(3));

      controller.dispose();
    });

    testWidgets('Official mode disables stepper and shows notice', (tester) async {
      final controller = _FakeLightweightController(
        activeMode: bridge.SessionModeDto.official,
        delay: 2,
      );

      await tester.pumpWidget(
        _wrap(
          LightweightSessionView(
            controller: controller,
            onOpenFull: () {},
            onHideToTray: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('输入延迟'), findsOneWidget);
      // Official notice is shown
      expect(find.text('官方模式由以撒内置网络栈管理，不支持输入延迟'), findsOneWidget);

      // Stepper buttons and read button should not be rendered or active
      expect(find.byKey(const ValueKey('lightweight-delay-minus')), findsNothing);
      expect(find.byKey(const ValueKey('lightweight-delay-plus')), findsNothing);
      expect(find.byKey(const ValueKey('lightweight-delay-read')), findsNothing);
      expect(find.byKey(const ValueKey('lightweight-delay-apply')), findsNothing);

      controller.dispose();
    });

    testWidgets('In-game input delay read button triggers readInputDelay and resets draft', (tester) async {
      final controller = _FakeLightweightController(delay: 2);

      await tester.pumpWidget(
        _wrap(
          LightweightSessionView(
            controller: controller,
            onOpenFull: () {},
            onHideToTray: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('2 帧'), findsOneWidget);

      // User edits draft: 2 -> 3
      await tester.tap(find.byKey(const ValueKey('lightweight-delay-plus')));
      await tester.pump();
      expect(find.text('3 帧'), findsOneWidget);

      // Tap read button
      final readBtn = find.byKey(const ValueKey('lightweight-delay-read'));
      expect(readBtn, findsOneWidget);
      await tester.tap(readBtn);
      await tester.pump();

      // Controller readInputDelay was called
      expect(controller.readCalled, isTrue);

      // Draft resets back to 2 帧
      expect(find.text('2 帧'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Displays inputDelayError icon when error is present', (tester) async {
      const errorMsg = '内存偏移解析失败 (TargetNotFound)';
      final controller = _FakeLightweightController(
        delay: 2,
        delayError: errorMsg,
      );

      await tester.pumpWidget(
        _wrap(
          LightweightSessionView(
            controller: controller,
            onOpenFull: () {},
            onHideToTray: () {},
          ),
        ),
      );
      await tester.pump();

      // Tooltip matching the error message
      expect(find.byTooltip(errorMsg), findsOneWidget);

      controller.dispose();
    });
  });
}
