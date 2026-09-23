import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/l10n/l10n.dart';
import 'package:tbnet_app/main.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/home_screen.dart';
import 'package:tbnet_app/screens/log_screen.dart';
import 'package:tbnet_app/screens/lightweight_session_view.dart';
import 'package:tbnet_app/screens/about_screen.dart';
import 'package:tbnet_app/screens/room_screen.dart';
import 'package:tbnet_app/screens/settings_screen.dart';
import 'package:tbnet_app/screens/statistics_screen.dart';
import 'package:tbnet_app/theme/app_theme.dart';
import 'package:tbnet_app/widgets/paper_card.dart';
import 'package:tbnet_app/widgets/paper_dropdown.dart';
import 'package:tbnet_app/widgets/app_dialogs.dart';
import 'package:tbnet_app/widgets/app_notification.dart';
import 'package:tbnet_app/widgets/asset_shape_shadow.dart';
import 'package:tbnet_app/widgets/custom_title_bar.dart';
import 'package:tbnet_app/widgets/custom_icons.dart';
import 'package:tbnet_app/widgets/sidebar.dart';
import 'package:tbnet_app/widgets/status_bar.dart';
import 'package:tbnet_app/widgets/torn_paper.dart';

class _LightweightTestController extends TractorBeamController {
  _LightweightTestController() : super.detached();

  @override
  LightweightViewState get lightweightViewState => LightweightViewState(
    sessionRunning: true,
    hookReady: true,
    route: bridge.RoomRouteDto.relay,
    transport: bridge.TransportSelection.udp,
    members: [
      const bridge.RoomMemberDto(
        steamId64: '76561198000000001',
        displayName: '本机玩家',
        connection: '已连接',
        isLocal: true,
      ),
      bridge.RoomMemberDto(
        steamId64: '76561198000000002',
        displayName: '远端玩家',
        connection: '已连接',
        latencyMs: BigInt.from(36),
        isLocal: false,
      ),
    ],
  );
}

class _PresentationTestController extends _LightweightTestController {
  bool _running = false;
  bridge.LaunchProgressDto _launch = bridge.LaunchProgressDto(
    status: bridge.LaunchStatusDto.idle,
    generation: BigInt.zero,
    displayText: '',
    terminal: false,
    success: false,
  );

  @override
  bool get isSessionRunning => _running;

  @override
  bridge.LaunchProgressDto? get launchProgress => _launch;

  void markReady() {
    _running = true;
    _launch = bridge.LaunchProgressDto(
      status: bridge.LaunchStatusDto.ready,
      generation: BigInt.one,
      displayText: 'Hook Ready',
      terminal: true,
      success: true,
    );
    notifyListeners();
  }

  void markStopped() {
    _running = false;
    notifyListeners();
  }
}

Finder _inBoard(String boardKey, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(boardKey)), matching: matching);

Future<void> _focusRoom(WidgetTester tester) async {
  final roomButton = _inBoard('home-page-board', find.text('房间'));
  expect(roomButton, findsOneWidget);
  await tester.tap(roomButton);
  await tester.pumpAndSettle();
}

Future<void> _focusHome(WidgetTester tester) async {
  final homeButton = _inBoard('room-page-board', find.text('首页'));
  expect(homeButton, findsOneWidget);
  await tester.tap(homeButton);
  await tester.pumpAndSettle();
}

Widget _resizeShadowHarness({required bool isResizing}) => MaterialApp(
  home: WindowResizePerformanceScope(
    isResizing: isResizing,
    child: const SizedBox(
      width: 240,
      height: 120,
      child: AssetShapeShadow(
        imageProvider: AssetImage('assets/images/paper/sidebar_card.webp'),
      ),
    ),
  ),
);

class _PaintCounter extends CustomPainter {
  const _PaintCounter(this.onPaint);

  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(_PaintCounter oldDelegate) => false;
}

class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild, this.readResizeGeometry = false});

  final VoidCallback onBuild;
  final bool readResizeGeometry;

  @override
  Widget build(BuildContext context) {
    onBuild();
    if (readResizeGeometry) {
      WindowResizePerformanceScope.isResizingOf(context);
    }
    return const SizedBox(width: 120, height: 60);
  }
}

Widget _resizeSnapshotHarness({
  required bool isResizing,
  required double scale,
  required VoidCallback onPaint,
}) => MaterialApp(
  home: WindowResizePerformanceScope(
    isResizing: isResizing,
    child: Center(
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: 240,
          height: 120,
          child: WindowResizeSnapshot(
            key: const ValueKey('resize-snapshot-under-test'),
            child: CustomPaint(painter: _PaintCounter(onPaint)),
          ),
        ),
      ),
    ),
  ),
);

Widget _resizeSnapshotShadowHarness({required bool isResizing}) => MaterialApp(
  home: WindowResizePerformanceScope(
    isResizing: isResizing,
    child: const SizedBox(
      width: 240,
      height: 120,
      child: WindowResizeSnapshot(
        child: AssetShapeShadow(
          imageProvider: AssetImage('assets/images/paper/sidebar_card.webp'),
        ),
      ),
    ),
  ),
);

Widget _resizeMediaSnapshotHarness({required VoidCallback onBuild}) =>
    MaterialApp(
      home: WindowResizePerformanceScope(
        isResizing: true,
        child: WindowResizeSnapshot(child: _BuildCounter(onBuild: onBuild)),
      ),
    );

Widget _resizeAspectHarness({
  required bool isResizing,
  required bool useLightweightEffects,
  required Widget child,
}) => MaterialApp(
  home: WindowResizePerformanceScope(
    isResizing: isResizing,
    useLightweightEffects: useLightweightEffects,
    child: child,
  ),
);

class _LaunchDialogController extends TractorBeamController {
  _LaunchDialogController() : super.detached();

  bridge.LaunchProgressDto? _launch;
  int cancelCalls = 0;

  @override
  bridge.LaunchProgressDto? get launchProgress => _launch;

  void updateLaunch(bridge.LaunchProgressDto launch) {
    _launch = launch;
    notifyListeners();
  }

  @override
  bridge.CommandReceipt cancelLaunch() {
    cancelCalls += 1;
    final launch = _launch;
    if (launch != null) {
      updateLaunch(
        bridge.LaunchProgressDto(
          status: bridge.LaunchStatusDto.cancelling,
          generation: launch.generation,
          displayText: '正在停止 TractorBeam 启动流程',
          terminal: false,
          success: false,
        ),
      );
    }
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }
}

void main() {
  testWidgets('Smoke test TB-NET app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TbNetApp());
    expect(find.text('首页'), findsWidgets);
    expect(find.byKey(const ValueKey('home-title-image')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sidebar-card-image'), skipOffstage: false),
      findsNWidgets(6),
    );
    expect(
      find.byKey(const ValueKey('sidebar-pin-image'), skipOffstage: false),
      findsNWidgets(6),
    );
    expect(
      find.byKey(const ValueKey('sidebar-language-icon'), skipOffstage: false),
      findsNWidgets(6),
    );
    expect(find.text('联机游玩须知'), findsOneWidget);
    expect(find.text('联机方式'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.theme!.pageTransitionsTheme.builders[TargetPlatform.windows],
      isA<FadeUpwardsPageTransitionsBuilder>(),
    );
  });

  testWidgets('Language button switches the mounted canvas without reset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp(initialLocale: Locale('en', 'US')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Online Play Guide'), findsOneWidget);
    expect(find.text('首页'), findsNothing);

    await tester.tap(
      find
          .byKey(const ValueKey('sidebar-language-icon'), skipOffstage: false)
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsWidgets);
    expect(find.text('联机游玩须知'), findsOneWidget);
  });

  testWidgets('Lightweight session view shows only compact live information', (
    WidgetTester tester,
  ) async {
    final controller = _LightweightTestController();
    var openedFull = false;
    var hidden = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 380,
          height: 360,
          child: LightweightSessionView(
            controller: controller,
            onOpenFull: () => openedFull = true,
            onHideToTray: () => hidden = true,
          ),
        ),
      ),
    );

    expect(find.text('Tractor Beam'), findsOneWidget);
    expect(find.text('Relay 中继  ·  UDP'), findsOneWidget);
    expect(find.text('Hook 已就绪'), findsOneWidget);
    expect(find.text('本机玩家'), findsOneWidget);
    expect(find.text('本机'), findsOneWidget);
    expect(find.text('远端玩家'), findsOneWidget);
    expect(find.text('36ms'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.byKey(const ValueKey('lightweight-open-full')));
    await tester.tap(find.byKey(const ValueKey('lightweight-hide')));
    expect(openedFull, isTrue);
    expect(hidden, isTrue);
    controller.dispose();
  });

  testWidgets('Hook Ready replaces and later rebuilds the full page canvas', (
    WidgetTester tester,
  ) async {
    final controller = _PresentationTestController();
    await tester.pumpWidget(TbNetApp(controller: controller));
    expect(find.byKey(const ValueKey('home-page-board')), findsOneWidget);

    controller.markReady();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('enter-lightweight-splash')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 180));
    expect(
      find.byKey(const ValueKey('enter-lightweight-splash')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('lightweight-session-view')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-page-board')), findsNothing);

    controller.markStopped();
    await tester.pump();
    expect(find.byKey(const ValueKey('restore-full-splash')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-page-board')), findsNothing);
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.byKey(const ValueKey('restore-full-splash')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-page-board')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lightweight-session-view')),
      findsNothing,
    );
  });

  for (final size in <Size>[
    const Size(960, 680),
    const Size(1200, 500),
    const Size(640, 760),
  ]) {
    testWidgets('Design canvas adapts without layout exceptions at $size', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('adaptive-design-canvas')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('World canvas keeps both page boards mounted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('home-page-board'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('room-page-board'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-page-board'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('statistics-page-board'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('log-page-board'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('about-page-board'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(RoomScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(SettingsScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(StatisticsScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(LogScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(AboutScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('Log and About boards occupy the requested lower row', (
    tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    final home = tester.getRect(find.byKey(const ValueKey('home-page-board')));
    final room = tester.getRect(find.byKey(const ValueKey('room-page-board')));
    final log = tester.getRect(
      find.byKey(const ValueKey('log-page-board'), skipOffstage: false),
    );
    final about = tester.getRect(
      find.byKey(const ValueKey('about-page-board'), skipOffstage: false),
    );

    expect(log.center.dx, closeTo(home.center.dx, 0.1));
    expect(log.top, greaterThan(home.bottom));
    expect(about.center.dx, closeTo(room.center.dx, 0.1));
    expect(about.top, greaterThan(room.bottom));

    await tester.tap(_inBoard('home-page-board', find.text('日志')));
    await tester.pumpAndSettle();
    expect(_inBoard('log-page-board', find.text('导出诊断包')), findsOneWidget);

    await tester.tap(_inBoard('log-page-board', find.text('关于')));
    await tester.pumpAndSettle();
    expect(_inBoard('about-page-board', find.text('开源与链接')), findsOneWidget);
    expect(_inBoard('about-page-board', find.text('感谢')), findsOneWidget);
  });

  testWidgets('Statistics board is below settings and can receive focus', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    final settings = tester.getRect(
      find.byKey(const ValueKey('settings-page-board'), skipOffstage: false),
    );
    final statistics = tester.getRect(
      find.byKey(const ValueKey('statistics-page-board'), skipOffstage: false),
    );
    expect(statistics.top, greaterThan(settings.bottom));

    await tester.tap(_inBoard('home-page-board', find.text('统计')));
    await tester.pumpAndSettle();

    final statsPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey('page-pointer-3')),
    );
    expect(statsPointer.ignoring, isFalse);
    expect(
      _inBoard('statistics-page-board', find.text('会话质量')),
      findsOneWidget,
    );
    expect(
      _inBoard('statistics-page-board', find.text('连接测试')),
      findsOneWidget,
    );
    expect(
      _inBoard('statistics-page-board', find.text('Hook 通信状态')),
      findsOneWidget,
    );
    expect(_inBoard('statistics-page-board', find.text('计数器')), findsOneWidget);
    expect(
      _inBoard('statistics-page-board', find.text('暂无测速记录')),
      findsOneWidget,
    );
    expect(
      _inBoard('statistics-page-board', find.text('开始测速')),
      findsOneWidget,
    );

    final refresh = _inBoard('statistics-page-board', find.text('刷新通信状态'));
    await tester.tap(refresh);
    await tester.pump();
    expect(_inBoard('statistics-page-board', find.text('刷新中')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Page camera disables interaction while moving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    IgnorePointer homePointer = tester.widget(
      find.byKey(const ValueKey('page-pointer-0')),
    );
    IgnorePointer roomPointer = tester.widget(
      find.byKey(const ValueKey('page-pointer-1')),
    );
    expect(homePointer.ignoring, isFalse);
    expect(roomPointer.ignoring, isTrue);

    await tester.tap(_inBoard('home-page-board', find.text('房间')));
    await tester.pump(const Duration(milliseconds: 100));

    homePointer = tester.widget(find.byKey(const ValueKey('page-pointer-0')));
    roomPointer = tester.widget(find.byKey(const ValueKey('page-pointer-1')));
    expect(homePointer.ignoring, isTrue);
    expect(roomPointer.ignoring, isTrue);

    await tester.pumpAndSettle();
    roomPointer = tester.widget(find.byKey(const ValueKey('page-pointer-1')));
    expect(roomPointer.ignoring, isFalse);
  });

  testWidgets('First page visit prepaints destination before camera movement', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    final homeBoard = find.byKey(const ValueKey('home-page-board'));
    final roomBoard = find.byKey(const ValueKey('room-page-board'));
    final roomBefore = tester.getTopLeft(roomBoard);

    await tester.tap(_inBoard('home-page-board', find.text('房间')));
    await tester.pump();

    // The real destination board is painted behind the opaque current board
    // for one frame, without enabling its interaction or ticker tree.
    expect(tester.getTopLeft(roomBoard), tester.getTopLeft(homeBoard));
    expect(tester.getTopLeft(roomBoard), isNot(roomBefore));
    expect(
      tester
          .widget<IgnorePointer>(find.byKey(const ValueKey('page-pointer-1')))
          .ignoring,
      isTrue,
    );

    await tester.pump(const Duration(milliseconds: 12));
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.getTopLeft(roomBoard), isNot(tester.getTopLeft(homeBoard)));
    await tester.pumpAndSettle();
  });

  testWidgets('Page camera keeps sidebar builds out of animation ticks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    var sidebarBuilds = 0;
    final previousRebuildCallback = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      previousRebuildCallback?.call(element, builtOnce);
      if (builtOnce && element.widget is PaperSidebar) sidebarBuilds++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previousRebuildCallback);

    await tester.tap(_inBoard('home-page-board', find.text('房间')));
    for (var elapsed = 0; elapsed < 560; elapsed += 40) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();

    // Interaction and semantics wrappers update at the transition boundaries,
    // but the cached page boards and their sidebars remain the same instances.
    expect(sidebarBuilds, 0);
  });

  testWidgets('Live window resize bypasses expensive shaped-shadow blur', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_resizeShadowHarness(isResizing: false));
    expect(find.byType(ImageFiltered), findsOneWidget);

    await tester.pumpWidget(_resizeShadowHarness(isResizing: true));
    expect(find.byType(ImageFiltered), findsNothing);

    await tester.pumpWidget(_resizeShadowHarness(isResizing: false));
    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('Live window resize reuses one fixed-board snapshot', (
    WidgetTester tester,
  ) async {
    var childPaints = 0;
    void countPaint() => childPaints++;

    await tester.pumpWidget(
      _resizeSnapshotHarness(isResizing: false, scale: 1, onPaint: countPaint),
    );
    expect(childPaints, greaterThan(0));

    await tester.pumpWidget(
      _resizeSnapshotHarness(isResizing: true, scale: .96, onPaint: countPaint),
    );
    final paintsAfterCapture = childPaints;

    for (final scale in <double>[.91, .83, .76, .69]) {
      await tester.pumpWidget(
        _resizeSnapshotHarness(
          isResizing: true,
          scale: scale,
          onPaint: countPaint,
        ),
      );
    }
    expect(childPaints, paintsAfterCapture);

    await tester.pumpWidget(
      _resizeSnapshotHarness(
        isResizing: false,
        scale: .69,
        onPaint: countPaint,
      ),
    );
    expect(childPaints, greaterThan(paintsAfterCapture));
  });

  testWidgets('Resize snapshot preserves the cached full-quality shadow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_resizeSnapshotShadowHarness(isResizing: false));
    expect(find.byType(ImageFiltered), findsOneWidget);

    await tester.pumpWidget(_resizeSnapshotShadowHarness(isResizing: true));
    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('Resize snapshot ignores MediaQuery size-only updates', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.view.resetPhysicalSize());
    tester.view.physicalSize = const Size(960, 680);
    var childBuilds = 0;
    await tester.pumpWidget(
      _resizeMediaSnapshotHarness(onBuild: () => childBuilds++),
    );
    final buildsAfterCapture = childBuilds;

    for (final size in const <Size>[
      Size(1000, 700),
      Size(1120, 760),
      Size(880, 640),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
    }
    expect(childBuilds, buildsAfterCapture);
  });

  testWidgets('Effect restoration does not rebuild geometry consumers', (
    WidgetTester tester,
  ) async {
    var geometryBuilds = 0;
    final geometryConsumer = _BuildCounter(
      onBuild: () => geometryBuilds++,
      readResizeGeometry: true,
    );
    await tester.pumpWidget(
      _resizeAspectHarness(
        isResizing: false,
        useLightweightEffects: true,
        child: geometryConsumer,
      ),
    );
    final initialBuilds = geometryBuilds;

    await tester.pumpWidget(
      _resizeAspectHarness(
        isResizing: false,
        useLightweightEffects: false,
        child: geometryConsumer,
      ),
    );
    expect(geometryBuilds, initialBuilds);

    await tester.pumpWidget(
      _resizeAspectHarness(
        isResizing: true,
        useLightweightEffects: false,
        child: geometryConsumer,
      ),
    );
    expect(geometryBuilds, initialBuilds + 1);
  });

  testWidgets(
    'Viewport resizing uses live lightweight layout without snapshots',
    (WidgetTester tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      tester.view.physicalSize = const Size(960, 680);
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      var snapshotRebuilds = 0;
      final previousRebuildCallback = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        previousRebuildCallback?.call(element, builtOnce);
        if (builtOnce && element.widget is WindowResizeSnapshot) {
          snapshotRebuilds++;
        }
      };
      addTearDown(() => debugOnRebuildDirtyWidget = previousRebuildCallback);

      for (final size in const <Size>[
        Size(1000, 700),
        Size(1120, 760),
        Size(880, 640),
        Size(960, 680),
      ]) {
        tester.view.physicalSize = size;
        await tester.pump();
      }

      expect(snapshotRebuilds, 0);
      expect(find.byType(WindowResizeSnapshot), findsNothing);
    },
  );

  testWidgets('Settings board is left of home and its primary controls work', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    await tester.tap(_inBoard('home-page-board', find.text('设置')));
    await tester.pumpAndSettle();

    final settingsPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey('page-pointer-2')),
    );
    expect(settingsPointer.ignoring, isFalse);
    expect(find.text('底层网络传输协议'), findsOneWidget);
    expect(find.text('工作模式'), findsOneWidget);
    expect(find.text('输入延迟'), findsOneWidget);

    await tester.tap(_inBoard('settings-page-board', find.text('TCP 协议')));
    await tester.tap(find.byKey(const ValueKey('restore-default-settings')));
    await tester.pumpAndSettle();
    expect(find.text('已恢复默认设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings screen adheres to Four-Tier Visual System colors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    await tester.tap(_inBoard('home-page-board', find.text('设置')));
    await tester.pumpAndSettle();

    // Verify content containers use natural paper background (Tier 3)
    final containers = tester.widgetList<TornPaperContainer>(
      _inBoard('settings-page-board', find.byType(TornPaperContainer)),
    );
    expect(containers, isNotEmpty);
    for (final container in containers) {
      expect(container.fillColor, AppColors.paperBg);
    }

    // Verify restore defaults button uses peach paper with paperBorder (Tier 1)
    final restoreBtn = tester.widget<TornPaperButton>(
      find.descendant(
        of: find.byKey(const ValueKey('restore-default-settings')),
        matching: find.byType(TornPaperButton),
      ),
    );
    expect(restoreBtn.fillColor, AppColors.peachPaper);
    expect(restoreBtn.borderColor, AppColors.paperBorder);

    // Verify "从游戏读取" and "写入到游戏" both use peach paper (Tier 1)
    final gameReadBtn = tester.widget<TornPaperButton>(
      find.ancestor(
        of: _inBoard('settings-page-board', find.text('从游戏读取')),
        matching: find.byType(TornPaperButton),
      ),
    );
    final gameWriteBtn = tester.widget<TornPaperButton>(
      find.ancestor(
        of: _inBoard('settings-page-board', find.text('写入到游戏')),
        matching: find.byType(TornPaperButton),
      ),
    );
    expect(gameReadBtn.fillColor, AppColors.peachPaper);
    expect(gameWriteBtn.fillColor, AppColors.peachPaper);
  });

  testWidgets('Wide windows can reveal the neighboring page board', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    final viewport = tester.getRect(
      find.byKey(const ValueKey('adaptive-design-canvas')),
    );
    final home = tester.getRect(find.byKey(const ValueKey('home-page-board')));
    final room = tester.getRect(find.byKey(const ValueKey('room-page-board')));

    expect(home.center.dx, closeTo(viewport.center.dx, 1));
    expect(room.left, lessThan(viewport.right));
    expect(room.left, greaterThan(home.right));
  });

  testWidgets('Resizing with the LAN dialog open preserves page state', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('局域网直连'));
    await tester.pumpAndSettle();
    await _focusRoom(tester);
    final roomState = tester.state(find.byType(RoomScreen));
    await tester.tap(find.text('新建独立房间'));
    await tester.pumpAndSettle();
    expect(find.text('创建局域网联机'), findsOneWidget);
    final dialogRoute = ModalRoute.of(tester.element(find.text('创建局域网联机')));
    expect(dialogRoute, isA<TransitionRoute<dynamic>>());
    expect(
      (dialogRoute! as TransitionRoute<dynamic>).allowSnapshotting,
      isFalse,
    );

    for (final size in <Size>[
      const Size(900, 700),
      const Size(1200, 760),
      const Size(720, 560),
      const Size(1400, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();

    expect(identical(roomState, tester.state(find.byType(RoomScreen))), isTrue);
    expect(
      tester
          .widget<IgnorePointer>(find.byKey(const ValueKey('page-pointer-1')))
          .ignoring,
      isFalse,
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('page-semantics-1')))
          .properties
          .hidden,
      isFalse,
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('page-semantics-0')))
          .properties
          .hidden,
      isTrue,
    );
    expect(find.text('创建局域网联机'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('创建局域网联机'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Room state survives camera navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();
    final stateBefore = tester.state(find.byType(RoomScreen));

    await _focusRoom(tester);
    await _focusHome(tester);
    await _focusRoom(tester);

    expect(
      identical(stateBefore, tester.state(find.byType(RoomScreen))),
      isTrue,
    );
  });

  testWidgets('Sidebar remains usable in a tall window', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(640, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TbNetApp());
    await _focusRoom(tester);

    expect(find.byType(RoomScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('room-code-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('steam-account-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('party-panel')), findsNothing);
    expect(find.byKey(const ValueKey('empty-room-panel')), findsOneWidget);
    expect(find.text('新建房间或输入联机码与好友联机'), findsOneWidget);
    expect(find.text('当前未加入任何联机房间'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sidebar frames the home cards without excessive height', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    final sidebarRect = tester.getRect(
      _inBoard('home-page-board', find.byType(PaperSidebar)),
    );
    final cards = _inBoard('home-page-board', find.byType(PaperCard));
    final firstCardRect = tester.getRect(cards.first);
    final lastCardRect = tester.getRect(cards.last);

    expect(sidebarRect.top, lessThan(firstCardRect.top));
    expect(sidebarRect.bottom, greaterThan(lastCardRect.bottom));
    expect(firstCardRect.top - sidebarRect.top, lessThan(80));
    expect(sidebarRect.bottom - lastCardRect.bottom, lessThan(80));
  });

  testWidgets('Bottom status bar is outside the scaled canvas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());

    expect(find.byType(BottomStatusBar), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(BottomStatusBar),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('Custom title bar stays outside the scaled canvas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());

    expect(find.byType(CustomTitleBar), findsOneWidget);
    expect(find.byKey(const ValueKey('titlebar-drag-area')), findsOneWidget);
    expect(find.byKey(const ValueKey('titlebar-minimize')), findsOneWidget);
    expect(find.byKey(const ValueKey('titlebar-maximize')), findsOneWidget);
    expect(find.byKey(const ValueKey('titlebar-close')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CustomTitleBar),
        matching: find.byType(Image),
      ),
      findsNWidgets(4),
    );
    expect(
      find.ancestor(
        of: find.byType(CustomTitleBar),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('Home page has no trailing scroll when fully visible', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    final homeScrollable = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Scrollable),
    );
    final scrollableState = tester.state<ScrollableState>(homeScrollable);

    expect(scrollableState.position.maxScrollExtent, 0);
  });

  testWidgets('All supplied UI icons load as image assets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            TbIcons.homeNetwork(),
            TbIcons.roomBars(),
            TbIcons.settingsSliders(),
            TbIcons.settingsReadGame(),
            TbIcons.settingsWriteGame(),
            TbIcons.language(),
            TbIcons.settingsTitle(),
            TbIcons.settingsLatencyLevel(level: 2),
            TbIcons.statsChart(),
            TbIcons.statisticsTitle(),
            TbIcons.logsTerminal(),
            TbIcons.logTitle(),
            TbIcons.infoCircle(),
            TbIcons.aboutTitle(),
            TbIcons.externalLink(),
            TbIcons.thanksHeart(),
            TbIcons.exportDiagnostics(),
            TbIcons.locateFolder(),
            TbIcons.clearLogs(),
            TbIcons.openSourceLinks(),
            TbIcons.gamepad(),
            TbIcons.relayNodes(),
            TbIcons.lanRadar(),
            TbIcons.switchDirection(),
            TbIcons.add(),
            TbIcons.edit(),
            TbIcons.speedGauge(),
            TbIcons.latencyGreen(),
            TbIcons.latencyYellow(),
            TbIcons.latencyRed(),
            TbIcons.dashedLine(),
            TbIcons.noticeAlert(),
            TbIcons.sectionTriangle(),
            TbIcons.copyRoomCode(),
            TbIcons.roomHistory(),
            TbIcons.joinRoom(),
            TbIcons.leaveRoom(),
            TbIcons.partyPagePrevious(),
            TbIcons.partyPageNext(),
            TbIcons.refreshAccount(),
            TbIcons.roomTitle(),
            TbIcons.roomDashedLine(),
            TbIcons.relayRadio(selected: true),
            TbIcons.relayRadio(selected: false),
            TbIcons.relayCheckbox(selected: true),
            TbIcons.relayCheckbox(selected: false),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(47));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PNG icons decode into stable DPR-aware cache buckets', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.view.resetDevicePixelRatio());

    for (final pixelRatio in const <double>[1, 1.25, 1.5, 2]) {
      tester.view.devicePixelRatio = pixelRatio;
      await tester.pumpWidget(
        MaterialApp(home: Center(child: TbIcons.add(size: 20))),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as ResizeImage;
      expect(provider.width, TbPngAsset.bucketForLogicalExtent(20, pixelRatio));
      expect(provider.height, isNull);
    }

    expect(TbPngAsset.bucketForLogicalExtent(32, 2), 96);
  });

  testWidgets('Stretched PNG lines decode to their bounded render size', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 600,
            height: 6,
            child: TbIcons.roomDashedLine(height: 6),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(provider.width, 1536);
    expect(provider.height, 16);
    expect(image.fit, BoxFit.fill);
  });

  testWidgets('Party members paginate after six players', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 824));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RoomScreen(previewPartySize: 8))),
    );

    await tester.tap(find.text('新建独立房间'));
    await tester.pumpAndSettle();
    expect(find.text('在线 8  1/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('party-next-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('party-previous-page')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('party-next-page')));
    await tester.pumpAndSettle();
    expect(find.text('在线 8  2/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('party-next-page')), findsNothing);
    expect(find.byKey(const ValueKey('party-previous-page')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Launch game requires a room from the bottom action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    final launchBtn = find.descendant(
      of: find.byType(BottomStatusBar),
      matching: find.text('启动游戏'),
    );
    expect(launchBtn, findsOneWidget);
    await tester.tap(launchBtn);
    await tester.pumpAndSettle();

    expect(find.text('请先加入联机房间'), findsOneWidget);
    expect(find.text('正在启动游戏'), findsNothing);
  });

  testWidgets('Home shortcuts reuse room join and launch flows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    await tester.tap(_inBoard('home-page-board', find.text('加入房间')));
    await tester.pumpAndSettle();
    expect(find.text('请输入房主提供的 TB-NET 联机码：'), findsOneWidget);
    final roomPointer = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey('page-pointer-1')),
    );
    expect(roomPointer.ignoring, isFalse);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await _focusHome(tester);
    await tester.tap(_inBoard('home-page-board', find.text('启动游戏')));
    await tester.pumpAndSettle();
    expect(find.text('请先加入联机房间'), findsOneWidget);
  });

  testWidgets('Joining by code while already in a room requires confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    await _focusRoom(tester);
    await tester.tap(find.text('新建独立房间'));
    await tester.pumpAndSettle();
    expect(find.text('退出当前房间'), findsOneWidget);

    await _focusHome(tester);
    await tester.tap(_inBoard('home-page-board', find.text('加入房间')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'TB-NEW-ROOM-001');
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('加入')),
    );
    await tester.pumpAndSettle();

    expect(find.text('加入新的联机房间'), findsOneWidget);
    expect(find.text('TB-NEW-ROOM-001'), findsOneWidget);
    expect(find.text('退出并加入'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('退出当前房间'), findsOneWidget);
    expect(find.text('TB-NEW-ROOM-001'), findsNothing);

    await _focusHome(tester);
    await tester.tap(_inBoard('home-page-board', find.text('加入房间')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'TB-NEW-ROOM-002');
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('加入')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出并加入'));
    await tester.pumpAndSettle();

    expect(find.text('TB-NEW-ROOM-002'), findsOneWidget);
    expect(find.text('退出当前房间'), findsOneWidget);
  });

  testWidgets('Launch progress dialog shows injection stages and is modal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLaunchGameDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('正在启动游戏'), findsOneWidget);
    expect(find.text('等待游戏进程'), findsOneWidget);
    expect(find.text('注入 TractorBeam Hook'), findsOneWidget);
    expect(find.text('关闭'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('正在启动游戏'), findsOneWidget);
  });

  testWidgets('Launch failure replaces progress with a closable error dialog', (
    WidgetTester tester,
  ) async {
    final controller = _LaunchDialogController();
    addTearDown(controller.dispose);
    var openedLogs = false;
    controller.updateLaunch(
      bridge.LaunchProgressDto(
        status: bridge.LaunchStatusDto.starting,
        generation: BigInt.one,
        displayText: '正在准备启动游戏',
        terminal: false,
        success: false,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLaunchGameDialog(
                context,
                controller: controller,
                onOpenLogs: () => openedLogs = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('正在启动游戏'), findsOneWidget);

    controller.updateLaunch(
      bridge.LaunchProgressDto(
        status: bridge.LaunchStatusDto.failed,
        generation: BigInt.one,
        displayText: '游戏启动失败',
        errorText: '缺少启动所需的注入组件，请检查程序文件是否完整。',
        terminal: true,
        success: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('启动失败'), findsOneWidget);
    expect(find.text('正在启动游戏'), findsNothing);
    expect(find.text('缺少启动所需的注入组件，请检查程序文件是否完整。'), findsOneWidget);
    expect(find.text('前往日志'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);

    await tester.tap(find.text('前往日志'));
    await tester.pumpAndSettle();
    expect(openedLogs, isTrue);
    expect(find.text('启动失败'), findsNothing);
  });

  testWidgets(
    'Launch progress can be cancelled and closes after confirmation',
    (WidgetTester tester) async {
      final controller = _LaunchDialogController();
      addTearDown(controller.dispose);
      controller.updateLaunch(
        bridge.LaunchProgressDto(
          status: bridge.LaunchStatusDto.waitingForGame,
          generation: BigInt.from(7),
          displayText: '正在等待游戏进程',
          terminal: false,
          success: false,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showLaunchGameDialog(context, controller: controller),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('取消启动'), findsOneWidget);

      await tester.tap(find.text('取消启动'));
      await tester.pump();
      expect(controller.cancelCalls, 1);
      expect(find.text('正在取消启动'), findsOneWidget);
      expect(find.text('正在取消…'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.text('正在取消启动'), findsOneWidget);

      controller.updateLaunch(
        bridge.LaunchProgressDto(
          status: bridge.LaunchStatusDto.cancelled,
          generation: BigInt.from(7),
          displayText: '游戏启动已取消',
          terminal: true,
          success: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('启动已取消'), findsNothing);
    },
  );

  testWidgets('Empty paper dropdown does not open a collapsed menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaperDropdown<String>(
            selectedValue: null,
            items: const [],
            onSelected: (_) {},
            triggerBuilder: (openMenu) =>
                TextButton(onPressed: openMenu, child: const Text('切换')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('切换'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add Relay and Edit Relay dialogs open and interact correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    // 1. Open Add Relay Dialog
    final addRelayBtn = find.text('添加relay');
    expect(addRelayBtn, findsOneWidget);
    await tester.tap(addRelayBtn);
    await tester.pumpAndSettle();

    expect(find.text('添加 Relay 节点'), findsOneWidget);
    expect(find.text('节点名称'), findsOneWidget);
    expect(find.text('Relay 地址'), findsOneWidget);
    expect(find.text('端口'), findsOneWidget);
    expect(find.text('支持的传输'), findsOneWidget);
    expect(find.text('默认传输'), findsOneWidget);
    final dialogPaper = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TornPaperContainer),
    );
    expect(dialogPaper, findsOneWidget);
    expect(
      tester.widget<TornPaperContainer>(dialogPaper).borderWidth,
      AppStrokes.paperOutline,
    );

    // Enter name & address
    await tester.enterText(find.byType(TextField).at(0), '东京高速节点 02');
    await tester.enterText(
      find.byType(TextField).at(1),
      'tokyo.relay.tbnet.org',
    );
    await tester.enterText(find.byType(TextField).at(2), '8443');

    // Tap Save
    final saveBtn = find.text('保存');
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(find.text('添加 Relay 节点'), findsNothing);
    expect(find.text('东京高速节点 02'), findsOneWidget);
    expect(find.text('tokyo.relay.tbnet.org:8443'), findsOneWidget);

    // 2. Open Edit Relay Dialog
    final editRelayBtn = find.text('编辑relay');
    expect(editRelayBtn, findsOneWidget);
    await tester.tap(editRelayBtn);
    await tester.pumpAndSettle();

    expect(find.text('编辑 Relay 节点'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('编辑 Relay 节点'), findsNothing);
  });

  testWidgets(
    'Join Room and Manual Steam Account dialogs open and interact correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      // Navigate to RoomScreen
      await _focusRoom(tester);

      // 1. Join Room Dialog
      final joinBtn = find.text('输入联机码加入');
      expect(joinBtn, findsOneWidget);
      await tester.tap(joinBtn);
      await tester.pumpAndSettle();

      expect(find.text('输入联机码加入'), findsWidgets);
      expect(find.text('联机码'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'TB-9999-8888-ZZ');
      final confirmJoinBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('加入'),
      );
      expect(confirmJoinBtn, findsOneWidget);
      await tester.tap(confirmJoinBtn);
      await tester.pumpAndSettle();

      expect(find.text('TB-9999-8888-ZZ'), findsOneWidget);
      expect(find.byKey(const ValueKey('party-panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('empty-room-panel')), findsNothing);
      expect(find.text('新建独立房间'), findsNothing);
      expect(find.text('输入联机码加入'), findsNothing);
      expect(find.text('退出当前房间'), findsOneWidget);
      expect(find.text('方式：Relay中继    协议：UDP'), findsOneWidget);

      // A fresh detached preview has no successful room history yet. The
      // themed history control remains visible but must not open an empty
      // collapsed menu.
      expect(find.text('历史'), findsOneWidget);
      await tester.tap(find.text('历史'));
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsNothing);

      // Steam account switch is an anchored themed dropdown.
      await tester.tap(_inBoard('room-page-board', find.text('切换')));
      await tester.pumpAndSettle();
      final alexAccount = find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.text('Alex Wolf'),
      );
      expect(alexAccount, findsOneWidget);
      await tester.tap(alexAccount);
      await tester.pumpAndSettle();
      expect(find.text('ID64：76561198123456789'), findsOneWidget);

      // 2. Manual Steam Account Dialog
      final manualFillBtn = find.text('手动填写');
      expect(manualFillBtn, findsOneWidget);
      await tester.tap(manualFillBtn);
      await tester.pumpAndSettle();

      expect(find.text('手动填写 Steam 账号'), findsOneWidget);
      expect(find.text('SteamID64'), findsOneWidget);
      expect(find.text('用户名'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '76561198999999999');
      await tester.enterText(find.byType(TextField).at(1), 'CyberKnight');

      final saveSteamBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('保存'),
      );
      await tester.tap(saveSteamBtn);
      await tester.pumpAndSettle();

      expect(find.text('手动填写 Steam 账号'), findsNothing);
      expect(find.text('CyberKnight'), findsOneWidget);
      expect(find.text('ID64：76561198999999999'), findsOneWidget);

      await tester.tap(find.text('退出当前房间'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('party-panel')), findsNothing);
      expect(find.byKey(const ValueKey('empty-room-panel')), findsOneWidget);
      expect(find.text('退出当前房间'), findsNothing);
      expect(find.text('新建独立房间'), findsOneWidget);
      expect(find.text('输入联机码加入'), findsOneWidget);
    },
  );

  testWidgets(
    'Dialog handles small window heights without RenderFlex overflow',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      final editRelayBtn = find.text('编辑relay');
      await tester.tap(editRelayBtn);
      await tester.pumpAndSettle();

      expect(find.text('编辑 Relay 节点'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final cancelBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('取消'),
      );
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('LAN room creation selects adapters before expanding party', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('局域网直连'));
    await tester.pumpAndSettle();
    await _focusRoom(tester);
    await tester.tap(find.text('新建独立房间'));
    await tester.pumpAndSettle();

    expect(find.text('创建局域网联机'), findsOneWidget);
    expect(find.text('可用于局域网联机的网卡'), findsOneWidget);
    expect(find.text('已选择：7/8'), findsOneWidget);
    expect(find.byKey(const ValueKey('lan-adapter-list')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_LanAdapterTile',
      ),
      findsWidgets,
    );

    await tester.scrollUntilVisible(
      find.text('WLAN'),
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('lan-adapter-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('WLAN'));
    await tester.pumpAndSettle();
    expect(find.text('已选择：8/8'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('VMware Network Adapter VMnet1'),
      80,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('lan-adapter-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('VMware Network Adapter VMnet1'));
    await tester.pump();
    expect(find.text('已选择：8/8'), findsOneWidget);

    final createButton = find.descendant(
      of: find.byType(Dialog),
      matching: find.text('创建'),
    );
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('party-panel')), findsOneWidget);
  });

  testWidgets('LAN room dialog disables creation without an adapter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showCreateLanRoomDialog(context, adapters: const []),
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('未检测到可用网卡'), findsOneWidget);
    expect(find.text('已选择：0/8'), findsOneWidget);
    final createButton = tester.widget<TornPaperButton>(
      find.ancestor(
        of: find.text('创建'),
        matching: find.byType(TornPaperButton),
      ),
    );
    expect(createButton.onTap, isNull);
  });

  testWidgets('LAN endpoint chooser returns the selected reachable address', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selected = await showLanEndpointSelectionDialog(context, const [
                '192.168.0.10:25910',
                '[fe80::42]:25910',
              ]);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('选择局域网端点'), findsOneWidget);
    await tester.tap(find.text('[fe80::42]:25910'));
    await tester.tap(find.text('连接'));
    await tester.pumpAndSettle();
    expect(selected, '[fe80::42]:25910');
  });

  test('Server latency rating thresholds evaluate accurately', () {
    // 0-30 为优秀
    expect(LatencyTheme.evaluateServer(0), LatencyGrade.excellent);
    expect(LatencyTheme.evaluateServer(24), LatencyGrade.excellent);
    expect(LatencyTheme.evaluateServer(30), LatencyGrade.excellent);

    // 30-60 为一般
    expect(LatencyTheme.evaluateServer(31), LatencyGrade.fair);
    expect(LatencyTheme.evaluateServer(45), LatencyGrade.fair);
    expect(LatencyTheme.evaluateServer(60), LatencyGrade.fair);

    // 60-100 为差
    expect(LatencyTheme.evaluateServer(61), LatencyGrade.poor);
    expect(LatencyTheme.evaluateServer(80), LatencyGrade.poor);
    expect(LatencyTheme.evaluateServer(100), LatencyGrade.poor);

    // 100 以上为严重
    expect(LatencyTheme.evaluateServer(101), LatencyGrade.severe);
    expect(LatencyTheme.evaluateServer(250), LatencyGrade.severe);
  });

  test('P2P end-to-end latency rating thresholds evaluate accurately', () {
    // 0-60 为优秀
    expect(LatencyTheme.evaluateP2p(0), LatencyGrade.excellent);
    expect(LatencyTheme.evaluateP2p(32), LatencyGrade.excellent);
    expect(LatencyTheme.evaluateP2p(60), LatencyGrade.excellent);

    // 60-100 为一般
    expect(LatencyTheme.evaluateP2p(61), LatencyGrade.fair);
    expect(LatencyTheme.evaluateP2p(78), LatencyGrade.fair);
    expect(LatencyTheme.evaluateP2p(100), LatencyGrade.fair);

    // 100-150 为差
    expect(LatencyTheme.evaluateP2p(101), LatencyGrade.poor);
    expect(LatencyTheme.evaluateP2p(120), LatencyGrade.poor);
    expect(LatencyTheme.evaluateP2p(150), LatencyGrade.poor);

    // 150 以上为严重
    expect(LatencyTheme.evaluateP2p(151), LatencyGrade.severe);
    expect(LatencyTheme.evaluateP2p(300), LatencyGrade.severe);
  });

  testWidgets(
    'Bottom status bar and relay card share synchronized server latency',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      // Initial server latency is 24ms: displayed in both bottom bar and relay card
      expect(find.text('24ms'), findsNWidgets(2));

      // Switch node (Shanghai 24ms -> Beijing 31ms)
      final switchBtn = _inBoard('home-page-board', find.text('切换'));
      expect(switchBtn, findsOneWidget);
      await tester.tap(switchBtn);
      await tester.pumpAndSettle();
      expect(find.text('北京 BGP 低延迟节点 02'), findsOneWidget);
      await tester.tap(find.text('北京 BGP 低延迟节点 02'));
      await tester.pumpAndSettle();

      // Both bottom bar and relay card update to 31ms simultaneously
      expect(find.text('31ms'), findsNWidgets(2));
      expect(find.text('24ms'), findsNothing);
    },
  );

  testWidgets(
    'Selecting LAN mode removes server latency from bottom bar and home card',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      // Initial in Relay mode: latency displayed
      expect(find.text('24ms'), findsNWidgets(2));

      // Switch to LAN mode ("局域网直连")
      final lanTab = find.text('局域网直连');
      expect(lanTab, findsOneWidget);
      await tester.tap(lanTab);
      await tester.pumpAndSettle();

      // In LAN mode: "当选择局域网联机不会有这个值"
      // Latency is completely hidden from both bottom status bar and connection card
      expect(find.text('24ms'), findsNothing);
      expect(find.text('31ms'), findsNothing);
      expect(find.text('本地局域网组网'), findsNothing);
      expect(find.text('局域网直连配置'), findsNothing);
      expect(find.text('扫描局域网'), findsNothing);
      expect(find.text('重置组网'), findsNothing);
      expect(find.text('局域网直连'), findsOneWidget);
      expect(find.text('已选局域网联机，直接前往创建房间即可'), findsOneWidget);

      // Switch back to Relay mode ("外部 Relay 中继")
      final relayTab = find.text('外部 Relay 中继');
      expect(relayTab, findsOneWidget);
      await tester.tap(relayTab);
      await tester.pumpAndSettle();

      // Latency reappears on both bottom bar and relay card
      expect(find.text('24ms'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Dropdown menus in home and room screens render with torn paper container',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      // 1. Home screen relay dropdown menu
      final homeSwitchBtn = _inBoard('home-page-board', find.text('切换'));
      expect(homeSwitchBtn, findsOneWidget);
      await tester.tap(homeSwitchBtn);
      await tester.pumpAndSettle();

      // Verify the dropdown menu is wrapped in a TornPaperContainer
      expect(find.byType(TornPaperContainer), findsWidgets);
      expect(find.text('北京 BGP 低延迟节点 02'), findsOneWidget);
      // Latency badges are visibly rendered for each relay option in the dropdown
      expect(find.text('31ms'), findsOneWidget);
      expect(find.text('24ms'), findsNWidgets(3));
      await tester.tap(find.text('北京 BGP 低延迟节点 02'));
      await tester.pumpAndSettle();

      // 2. Navigate to Room screen
      await _focusRoom(tester);

      // Room screen Steam account switch dropdown
      final roomSwitchBtn = _inBoard('room-page-board', find.text('切换'));
      expect(roomSwitchBtn, findsOneWidget);
      await tester.tap(roomSwitchBtn);
      await tester.pumpAndSettle();

      // Verify account items in torn paper dropdown
      expect(find.text('Alex Wolf'), findsOneWidget);
      await tester.tap(find.text('Alex Wolf'));
      await tester.pumpAndSettle();

      // Steam account switched
      expect(find.text('Alex Wolf'), findsWidgets);
    },
  );

  testWidgets(
    'Room party panel supports pagination when members exceed 6 and transitions smoothly',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      await _focusRoom(tester);

      // Enter room by clicking "新建独立房间"
      final createRoomBtn = _inBoard('room-page-board', find.text('新建独立房间'));
      expect(createRoomBtn, findsOneWidget);
      await tester.tap(createRoomBtn);
      await tester.pumpAndSettle();

      // Verify in room and party panel is visible
      expect(find.byKey(const ValueKey('party-panel')), findsOneWidget);

      // With default 7 members (exceeding 6): displays 1/2 page badge
      expect(find.textContaining('1/2'), findsOneWidget);

      // Click next page button
      final nextBtn = find.byKey(const ValueKey('party-next-page'));
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Page 2 displayed: badge shows 2/2, previous button is present
      expect(find.textContaining('2/2'), findsOneWidget);
      final prevBtn = find.byKey(const ValueKey('party-previous-page'));
      expect(prevBtn, findsOneWidget);

      // Click previous page button
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      // Back to Page 1
      expect(find.textContaining('1/2'), findsOneWidget);
    },
  );

  testWidgets(
    'Top toast notification renders at window top and dismisses on tap',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      // Trigger bottom action without room
      final launchBtn = find.descendant(
        of: find.byType(BottomStatusBar),
        matching: find.text('启动游戏'),
      );
      expect(launchBtn, findsOneWidget);
      await tester.tap(launchBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Toast appears with message
      expect(find.text('请先加入联机房间'), findsOneWidget);

      // Verify the toast is positioned at the top of the window
      final toastFinder = find.ancestor(
        of: find.text('请先加入联机房间'),
        matching: find.byType(TornPaperContainer),
      );
      expect(toastFinder, findsOneWidget);
      expect(
        tester.widget<TornPaperContainer>(toastFinder).borderWidth,
        AppStrokes.paperOutline,
      );
      final toastTop = tester.getTopLeft(toastFinder).dy;
      // Should be just below the 44px CustomTitleBar (around 52px)
      expect(toastTop, greaterThanOrEqualTo(44.0));
      expect(toastTop, lessThan(80.0));

      // Tap to dismiss
      await tester.tap(toastFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Message is dismissed
      expect(find.text('请先加入联机房间'), findsNothing);
    },
  );

  testWidgets('Consecutive notifications replace active toast smoothly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => AppNotification.info(context, '第一条消息'),
                  child: const Text('Msg 1'),
                ),
                ElevatedButton(
                  onPressed: () => AppNotification.error(context, '第二条消息'),
                  child: const Text('Msg 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger first notification
    await tester.tap(find.text('Msg 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('第一条消息'), findsOneWidget);
    expect(find.text('第二条消息'), findsNothing);

    // Trigger second notification: replaces the first cleanly
    await tester.tap(find.text('Msg 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('第一条消息'), findsNothing);
    expect(find.text('第二条消息'), findsOneWidget);
  });

  testWidgets(
    'Input text fields show localized Chinese context menu on right click',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      // Open Join Room dialog (which contains a TextField)
      await tester.tap(_inBoard('home-page-board', find.text('加入房间')));
      await tester.pumpAndSettle();

      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'TB-12345');
      await tester.pumpAndSettle();

      // Right-click inside the TextField using mouse secondary button
      final gesture = await tester.startGesture(
        tester.getCenter(inputFinder),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify context menu is displayed in Chinese
      expect(find.text('全选'), findsOneWidget);
      expect(find.text('Select all'), findsNothing);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
    },
  );

  testWidgets(
    'Steam identity mismatch banner displays when mismatch exists and triggers sync',
    (WidgetTester tester) async {
      final controller = _SteamMismatchTestController();

      await tester.pumpWidget(TbNetApp(controller: controller));
      await tester.pumpAndSettle();

      await _focusRoom(tester);

      expect(find.textContaining('Steam 账号不一致'), findsOneWidget);
      expect(find.textContaining('76561198000000002'), findsOneWidget);
      expect(find.text('同步为游戏账号并重连'), findsOneWidget);

      await tester.tap(find.text('同步为游戏账号并重连'));
      await tester.pumpAndSettle();

      expect(controller.useGameSteamAccountCalled, isTrue);
    },
  );

  testWidgets(
    'Manual Steam Account dialog enforces 17-digit non-zero ID and supports deletion',
    (WidgetTester tester) async {
      String? deletedId;
      SteamAccountData? savedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  savedData = await showManualSteamAccountDialog(
                    context,
                    initialUsername: '',
                    initialSteamId64: '',
                    manualAccounts: const [
                      SteamAccountData(
                        username: 'OldAccount',
                        steamId64: '76561198000000099',
                      ),
                    ],
                    onDeleteManualAccount: (id) => deletedId = id,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify existing manual account is listed
      expect(find.text('已保存的手动账号'), findsOneWidget);
      expect(find.text('OldAccount'), findsOneWidget);
      expect(find.text('ID64: 76561198000000099'), findsOneWidget);

      // Tap delete icon for OldAccount
      await tester.tap(
        find.byKey(const ValueKey('delete-manual-account-76561198000000099')),
      );
      await tester.pumpAndSettle();
      expect(find.text('删除 Steam 账号'), findsOneWidget);
      expect(find.textContaining('确定要删除手动账号“OldAccount”'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();
      expect(deletedId, '76561198000000099');
      expect(find.text('OldAccount'), findsNothing);

      final saveBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('保存'),
      );

      // 1. Try empty submission
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('SteamID64 不能为空'), findsOneWidget);
      expect(find.text('手动填写 Steam 账号'), findsOneWidget);

      // 2. Try non-17 digit ID
      await tester.enterText(find.byType(TextField).at(0), '12345');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('SteamID64 必须为 17 位纯数字且不能为 0'), findsOneWidget);

      // 3. Try 17-digit all zeros
      await tester.enterText(find.byType(TextField).at(0), '00000000000000000');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('SteamID64 必须为 17 位纯数字且不能为 0'), findsOneWidget);

      // 4. Try valid ID but empty username
      await tester.enterText(find.byType(TextField).at(0), '76561198123456780');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('用户名不能为空'), findsOneWidget);

      // 5. Fill username and save
      await tester.enterText(find.byType(TextField).at(1), 'NewGamer');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Dialog dismissed and data returned
      expect(find.text('手动填写 Steam 账号'), findsNothing);
      expect(savedData?.username, 'NewGamer');
      expect(savedData?.steamId64, '76561198123456780');
    },
  );

  testWidgets(
    'Switching Steam account in active room prompts confirmation dialog',
    (WidgetTester tester) async {
      bool? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      confirmedResult =
                          await showSwitchSteamAccountInRoomDialog(
                            context,
                            isLan: false,
                          );
                    },
                    child: const Text('Switch Relay'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      confirmedResult =
                          await showSwitchSteamAccountInRoomDialog(
                            context,
                            isLan: true,
                          );
                    },
                    child: const Text('Switch LAN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test Relay prompt
      await tester.tap(find.text('Switch Relay'));
      await tester.pumpAndSettle();
      expect(find.text('在房间中切换 Steam 账号'), findsOneWidget);
      expect(find.textContaining('中继房间'), findsOneWidget);
      await tester.tap(find.text('确认切换'));
      await tester.pumpAndSettle();
      expect(confirmedResult, isTrue);

      // Test LAN prompt
      await tester.tap(find.text('Switch LAN'));
      await tester.pumpAndSettle();
      expect(find.text('在房间中切换 Steam 账号'), findsOneWidget);
      expect(find.textContaining('局域网直连房间'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(confirmedResult, isFalse);
    },
  );

  testWidgets(
    'Manual Steam Account in active room prompts confirmation dialog',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _RoomScreenTestController(
        inRoom: true,
        currentRoomCode: 'TB-TEST-1234-AA',
        currentSteamId64: '76561198000000001',
        currentSteamUsername: 'OriginalPlayer',
      );

      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(home: Scaffold(body: RoomScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // Tap manual fill button in room screen
      final manualFillBtn = find.text('手动填写');
      expect(manualFillBtn, findsOneWidget);
      await tester.tap(manualFillBtn);
      await tester.pumpAndSettle();

      expect(find.text('手动填写 Steam 账号'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '76561198999999999');
      await tester.enterText(find.byType(TextField).at(1), 'NewManualUser');

      final saveSteamBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('保存'),
      );
      await tester.tap(saveSteamBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog should be shown because inRoom is true and ID changed!
      expect(find.text('在房间中切换 Steam 账号'), findsOneWidget);
      expect(find.textContaining('中继房间'), findsOneWidget);

      // Confirm the switch
      await tester.tap(find.text('确认切换'));
      await tester.pumpAndSettle();

      expect(controller.currentSteamId64, '76561198999999999');
      expect(controller.currentSteamUsername, 'NewManualUser');
    },
  );

  testWidgets(
    'Settings screen disables input latency in Official mode and preserves user slider edits',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _NativeMockController(sessionRunning: true);
      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial pure mode with running session allows adjusting delay
      expect(find.text('网络状态不佳时建议调高'), findsOneWidget);
      final sliderFinder = find.byKey(const ValueKey('input-latency-slider'));
      expect(sliderFinder, findsOneWidget);

      // Tap tick '4' inside latency-panel
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('latency-panel')),
          matching: find.text('4'),
        ),
      );
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.value, 4.0);

      // 2. Select Official mode -> input latency should be disabled and show notice
      await tester.tap(find.text('Official'));
      await tester.pumpAndSettle();

      expect(find.text('官方模式由以撒内置网络栈管理，不支持输入延迟'), findsOneWidget);
      final officialSlider = tester.widget<Slider>(sliderFinder);
      expect(officialSlider.onChanged, isNull);

      // 3. Switch back to Pure mode -> latency slider re-enabled and holds draft value 4
      await tester.tap(find.text('Pure'));
      await tester.pumpAndSettle();

      expect(find.text('网络状态不佳时建议调高'), findsOneWidget);
      final restoredSlider = tester.widget<Slider>(sliderFinder);
      expect(restoredSlider.value, 4.0);
      expect(restoredSlider.onChanged, isNotNull);
    },
  );

  testWidgets(
    'Settings screen disables input delay editing when Isaac session is not running',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _NativeMockController(sessionRunning: false);
      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // When game is not running:
      expect(find.text('以撒游戏未运行，启动游戏后方可调节输入延迟'), findsOneWidget);
      final disabledSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('input-latency-slider')),
      );
      expect(disabledSlider.onChanged, isNull);

      // When game starts running:
      controller.setSessionRunning(true);
      await tester.pumpAndSettle();

      expect(find.text('网络状态不佳时建议调高'), findsOneWidget);
      final enabledSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('input-latency-slider')),
      );
      expect(enabledSlider.onChanged, isNotNull);
    },
  );

  testWidgets(
    'Settings screen handles asynchronous input_delay_read success and failure events properly',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _SettingsScreenTestController(
        sessionRunning: true,
        hookDelay: 2,
      );

      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(
            locale: Locale('zh', 'CN'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger successful read event
      controller.triggerEvent(
        const bridge.AppEvent(
          code: 'input_delay_read',
          success: true,
          displayText: '已从游戏读取输入延迟',
          value: '4',
          message: bridge.LocalizedMessageDto(
            key: 'event.input_delay_read',
            args: [],
            fallbackZh: '已从游戏读取输入延迟',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slider value should update to 4
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('input-latency-slider')),
      );
      expect(slider.value, 4.0);

      // Trigger error event
      controller.triggerEvent(
        const bridge.AppEvent(
          code: 'input_delay_read',
          success: false,
          displayText: 'Hook 尚未就绪，请稍后再试。',
          value: null,
          message: bridge.LocalizedMessageDto(
            key: 'error.hook_not_ready',
            args: [],
            fallbackZh: 'Hook 尚未就绪，请稍后再试。',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hook 尚未就绪，请稍后再试。'), findsOneWidget);
    },
  );

  testWidgets('Settings screen displays hook inputDelayError when present', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 680));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = _SettingsScreenTestController(
      sessionRunning: true,
      hookDelay: 2,
      hookDelayError: '内存偏移解析失败 (TargetNotFound)',
    );

    await tester.pumpWidget(
      TractorBeamScope(
        notifier: controller,
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('内存偏移解析失败 (TargetNotFound)'), findsOneWidget);
  });

  testWidgets(
    'Settings screen prioritizes active session mode over drafted mode during live gameplay',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Active session is official, but user config is pure
      final controller = _SettingsScreenTestController(
        sessionRunning: true,
        activeSessionMode: bridge.SessionModeDto.official,
        configMode: bridge.SessionModeDto.pure,
      );

      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(
            locale: Locale('zh', 'CN'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Delay editing should be disabled because the active game is official!
      expect(find.text('官方模式由以撒内置网络栈管理，不支持输入延迟'), findsOneWidget);
      final disabledSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('input-latency-slider')),
      );
      expect(disabledSlider.onChanged, isNull);
    },
  );

  testWidgets(
    'Settings screen rolls back protocol and mode selection when command is rejected',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _SettingsScreenTestController(
        transportSelection: bridge.TransportSelection.relayDefault,
        configMode: bridge.SessionModeDto.pure,
      );
      controller.shouldRejectTransport = true;
      controller.shouldRejectMode = true;

      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(
            locale: Locale('zh', 'CN'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap UDP -> rejected, should roll back to default
      await tester.tap(find.text('UDP 协议'));
      await tester.pumpAndSettle();
      expect(find.text('传输协议已被锁定'), findsOneWidget);

      // Tap Fallback -> rejected, should roll back to Pure
      await tester.tap(find.text('Fallback'));
      await tester.pumpAndSettle();
      expect(find.text('工作模式已被锁定'), findsOneWidget);
    },
  );

  testWidgets('Settings screen ignores redundant language selection', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 680));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int localeChangeCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('zh', 'CN'),
        home: Scaffold(
          body: SettingsScreen(onLocaleChanged: (_) => localeChangeCount++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Chinese while already in Chinese
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    expect(localeChangeCount, 0);

    // Tap English -> should trigger
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(localeChangeCount, 1);
  });

  testWidgets('Settings screen resets draft flag when session terminates', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 680));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = _SettingsScreenTestController(
      sessionRunning: true,
      hookDelay: 2,
    );

    await tester.pumpWidget(
      TractorBeamScope(
        notifier: controller,
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Drag slider to 4
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('latency-panel')),
        matching: find.text('4'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('input-latency-slider')))
          .value,
      4.0,
    );

    // Session ends
    controller.setSessionRunning(false);
    await tester.pumpAndSettle();

    // New session starts with delay 1
    controller.setSessionRunning(true);
    controller.setHookDelay(1);
    await tester.pumpAndSettle();

    // Slider should now follow the new session truth (1.0) because draft was reset on session end!
    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('input-latency-slider')))
          .value,
      1.0,
    );
  });

  testWidgets(
    'Add Relay dialog validates empty fields, port range, and protocol selection',
    (WidgetTester tester) async {
      AddRelayData? savedData;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  savedData = await showAddRelayDialog(context);
                },
                child: const Text('Open Add Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Add Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('添加 Relay 节点'), findsOneWidget);

      // 1. Empty fields validation
      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请输入节点名称'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '自定义节点');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请输入 Relay 地址'), findsOneWidget);

      // 2. Invalid port validation
      await tester.enterText(find.byType(TextField).at(1), 'relay.test.org');
      await tester.enterText(find.byType(TextField).at(2), '999999');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('端口号必须为 1–65535 之间的整数'), findsOneWidget);

      // 3. Smart host:port parsing
      await tester.enterText(
        find.byType(TextField).at(1),
        'fast.relay.net:19842',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('添加 Relay 节点'), findsNothing);
      expect(savedData, isNotNull);
      expect(savedData!.name, '自定义节点');
      expect(savedData!.address, 'fast.relay.net');
      expect(savedData!.port, '19842');
    },
  );

  testWidgets(
    'Edit Relay dialog requires secondary confirmation to delete node',
    (WidgetTester tester) async {
      EditRelayResult? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showEditRelayDialog(
                    context,
                    initialName: '测试待删节点',
                    initialAddress: 'test.relay.org',
                    initialPort: '25910',
                  );
                },
                child: const Text('Open Edit Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Edit Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('编辑 Relay 节点'), findsOneWidget);

      // Click delete button
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // Secondary confirmation dialog should appear
      expect(find.text('删除 Relay 节点'), findsOneWidget);
      expect(find.textContaining('确定要删除节点“测试待删节点”吗？'), findsOneWidget);

      // Tap cancel in confirmation dialog
      await tester.tap(find.text('取消').last);
      await tester.pumpAndSettle();

      // Confirmation dialog is closed, but Edit Relay dialog remains open
      expect(find.textContaining('确定要删除节点“测试待删节点”吗？'), findsNothing);
      expect(find.text('编辑 Relay 节点'), findsOneWidget);

      // Click delete again, and confirm
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();

      // Both dialogs closed, action is delete
      expect(find.text('编辑 Relay 节点'), findsNothing);
      expect(result, isNotNull);
      expect(result!.action, EditRelayAction.delete);
    },
  );

  testWidgets(
    'Relay modifications are disabled and show notice when room or session is active',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _HomeRelayTestController(
        inRoom: true,
        customRelays: const [
          bridge.RelayDto(
            id: 'r1',
            name: '上海极速节点',
            host: '192.0.2.1',
            port: 25910,
            supportsTcp: true,
            supportsUdp: true,
            defaultTransport: bridge.TransportSelection.udp,
          ),
        ],
      );
      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // When room is active, tapping switch should show notice
      final switchBtn = find.text('切换');
      expect(switchBtn, findsOneWidget);
      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      expect(find.text('请先退出房间再切换 Relay 节点'), findsOneWidget);

      // Tapping "添加relay" when disabled should not open dialog, but give clear notice
      await tester.tap(find.text('添加relay'));
      await tester.pumpAndSettle();
      expect(find.text('请先退出房间再添加 Relay 节点'), findsOneWidget);
      expect(find.text('添加 Relay 节点'), findsNothing);

      // When game session is running, relay modifications should also be disabled
      final sessionController = _HomeRelayTestController(
        sessionRunning: true,
        customRelays: const [
          bridge.RelayDto(
            id: 'r1',
            name: '上海极速节点',
            host: '192.0.2.1',
            port: 25910,
            supportsTcp: true,
            supportsUdp: true,
            defaultTransport: bridge.TransportSelection.udp,
          ),
        ],
      );
      await tester.pumpWidget(
        TractorBeamScope(
          notifier: sessionController,
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('切换'));
      await tester.pumpAndSettle();
      expect(find.text('请先退出游戏再切换 Relay 节点'), findsOneWidget);
    },
  );

  testWidgets(
    'Empty relay list displays guidance card and add relay button without default node',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _HomeRelayTestController(
        hasSnapshot: true,
        customRelays: [],
      );
      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('当前未配置任何 Relay 节点'), findsOneWidget);
      expect(find.text('请点击下方按钮添加自定义 Relay 节点。'), findsOneWidget);
      expect(find.text('添加relay'), findsOneWidget);
      expect(find.text('恢复默认节点'), findsNothing);
    },
  );

  testWidgets('Home screen cards have descriptive tooltips on info icons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TbNetApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('以撒联机基本操作指南与联机注意事项'), findsOneWidget);
    expect(find.byTooltip('可选择外部中继服务器（跨公网推荐）或局域网直连模式'), findsOneWidget);
  });

  testWidgets(
    'Statistics screen cards have descriptive tooltips on info icons',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TbNetApp());
      await tester.pumpAndSettle();

      await tester.tap(_inBoard('home-page-board', find.text('统计')));
      await tester.pumpAndSettle();

      expect(find.byTooltip('当前联机会话的网络平滑度评估与诊断状态'), findsOneWidget);
      expect(find.byTooltip('Hook 注入与 Relay 服务器之间的数据包及字节吞吐统计'), findsOneWidget);
      expect(find.byTooltip('向当前选中的 Relay 节点发送轻量探测包测试延迟与连通性'), findsOneWidget);
      expect(find.byTooltip('以撒游戏进程内 Hook 模块与本程序的 IPC 实时通信状态'), findsOneWidget);
    },
  );

  testWidgets(
    'Statistics screen renders live data, localized status, counters and connection reports',
    (WidgetTester tester) async {
      final fake = _StatsFakeSnapshot(
        session: const bridge.SessionSnapshot(
          status: bridge.SessionStatusDto.running,
          activeMode: bridge.SessionModeDto.pure,
          smoothness: 'good',
          health: '链路稳定',
          lastStopReason: null,
        ),
        room: bridge.RoomSnapshot(
          active: true,
          status: bridge.RoomStatusDto.active,
          generation: BigInt.zero,
          route: bridge.RoomRouteDto.relay,
          transport: bridge.TransportSelection.udp,
          joinCode: 'TB-9988',
          members: const [],
          steamIdentityMismatch: null,
        ),
        counters: bridge.CountersDto(
          hookToRelay: BigInt.from(1234),
          relayToHook: BigInt.from(5678),
          sentBytes: BigInt.from(1024 * 1024 * 5),
          receivedBytes: BigInt.from(1024 * 1024 * 12),
          errors: BigInt.from(3),
          reconnectDroppedPackets: BigInt.zero,
          detachedHookDroppedPackets: BigInt.from(1),
          detachedRelayDroppedPackets: BigInt.from(2),
        ),
        tests: [
          bridge.ConnectionTestDto(
            relayId: 'r1',
            relayName: '测试中继',
            endpoint: '127.0.0.1:8080',
            transport: bridge.TransportSelection.udp,
            sent: 50,
            received: 50,
            medianRttMs: BigInt.from(32),
            failureReason: null,
          ),
          bridge.ConnectionTestDto(
            relayId: 'r2',
            relayName: '拥堵节点',
            endpoint: '127.0.0.1:8081',
            transport: bridge.TransportSelection.tcp,
            sent: 50,
            received: 45,
            medianRttMs: BigInt.from(88),
            failureReason: null,
          ),
        ],
        hook: bridge.HookSnapshot(
          startupPhase: 'ready',
          connection: 'connected',
          installation: 'installed',
          runtimeActive: true,
          version: '1.2.0',
          reconnects: 2,
          malformedFrames: BigInt.zero,
          lastError: null,
          inputDelay: 2,
          inputDelayError: null,
        ),
        clientConfig: const bridge.ClientConfigDto(
          selectedRelayId: 'r1',
          selectedSteamId64: null,
          mode: bridge.SessionModeDto.pure,
          transport: bridge.TransportSelection.udp,
          relays: [],
          accounts: [],
          warnings: [],
        ),
      );

      final controller = _StatsTestController(fake);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const StatisticsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('会话质量：良好'), findsOneWidget);
      expect(find.text('纯净联机'), findsOneWidget);
      expect(find.text('房间 TB-9988'), findsOneWidget);
      expect(find.text('UDP'), findsWidgets);
      expect(find.text('TCP'), findsOneWidget);
      expect(find.text('健康诊断: 链路稳定'), findsOneWidget);

      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('12.0 MB'), findsOneWidget);
      expect(find.text('5.0 MB'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      expect(find.text('测试中继'), findsOneWidget);
      expect(find.text('50/50'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('32 ms'), findsOneWidget);
      expect(find.text('拥堵节点'), findsOneWidget);
      expect(find.text('45/50'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('88 ms'), findsOneWidget);

      expect(find.text('已连接'), findsOneWidget);
      expect(find.text('1.2.0'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      final testBtn = find.byKey(const ValueKey('test-relay-latency-button'));
      expect(testBtn, findsOneWidget);
      await tester.tap(testBtn);
      await tester.pump();
      expect(controller.latencyTested, isTrue);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Statistics screen correctly renders Fallback mode and localized Relay route',
    (WidgetTester tester) async {
      final fake = _StatsFakeSnapshot(
        session: const bridge.SessionSnapshot(
          status: bridge.SessionStatusDto.running,
          activeMode: bridge.SessionModeDto.fallback,
          smoothness: 'watch',
          health: '后备链路已激活',
          lastStopReason: null,
        ),
        room: bridge.RoomSnapshot(
          active: true,
          status: bridge.RoomStatusDto.active,
          generation: BigInt.zero,
          route: bridge.RoomRouteDto.relay,
          transport: bridge.TransportSelection.tcp,
          joinCode: 'TB-1122',
          members: const [],
          steamIdentityMismatch: null,
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
        tests: const [],
        hook: bridge.HookSnapshot(
          startupPhase: 'ready',
          connection: 'connected',
          installation: 'installed',
          runtimeActive: true,
          version: '1.2.0',
          reconnects: 0,
          malformedFrames: BigInt.zero,
          lastError: null,
          inputDelay: null,
          inputDelayError: null,
        ),
        clientConfig: const bridge.ClientConfigDto(
          selectedRelayId: 'r-hk',
          selectedSteamId64: null,
          mode: bridge.SessionModeDto.fallback,
          transport: bridge.TransportSelection.tcp,
          relays: [
            bridge.RelayDto(
              id: 'r-hk',
              name: '香港高速中继',
              host: 'hk.relay.net',
              port: 8080,
              supportsTcp: true,
              supportsUdp: true,
              defaultTransport: bridge.TransportSelection.tcp,
            ),
          ],
          accounts: [],
          warnings: [],
        ),
      );

      final controller = _StatsTestController(fake);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const StatisticsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('后备兼容'), findsOneWidget);
      expect(find.text('中继 (香港高速中继)'), findsOneWidget);
      expect(find.text('会话质量：需关注'), findsOneWidget);
    },
  );

  testWidgets(
    'Statistics screen formats Terabytes (TB) and thousands separator for drops',
    (WidgetTester tester) async {
      final tbBytes =
          BigInt.from(1024) *
          BigInt.from(1024) *
          BigInt.from(1024) *
          BigInt.from(1024) *
          BigInt.from(3); // 3 TB

      final fake = _StatsFakeSnapshot(
        session: const bridge.SessionSnapshot(
          status: bridge.SessionStatusDto.running,
          activeMode: bridge.SessionModeDto.pure,
          smoothness: 'good',
          health: '正常',
          lastStopReason: null,
        ),
        room: bridge.RoomSnapshot(
          active: false,
          status: bridge.RoomStatusDto.idle,
          generation: BigInt.zero,
          route: null,
          transport: bridge.TransportSelection.udp,
          joinCode: null,
          members: const [],
          steamIdentityMismatch: null,
        ),
        counters: bridge.CountersDto(
          hookToRelay: BigInt.from(1000000),
          relayToHook: BigInt.from(2000000),
          sentBytes: tbBytes,
          receivedBytes: BigInt.from(1024 * 1024 * 500),
          errors: BigInt.from(42),
          reconnectDroppedPackets: BigInt.from(999),
          detachedHookDroppedPackets: BigInt.from(12345),
          detachedRelayDroppedPackets: BigInt.from(67890),
        ),
        tests: const [],
        hook: bridge.HookSnapshot(
          startupPhase: 'ready',
          connection: 'connected',
          installation: 'installed',
          runtimeActive: true,
          version: '1.2.0',
          reconnects: 15,
          malformedFrames: BigInt.from(9876),
          lastError: null,
          inputDelay: null,
          inputDelayError: null,
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
      );

      final controller = _StatsTestController(fake);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const StatisticsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3.00 TB'), findsOneWidget);
      expect(find.text('1,000,000'), findsOneWidget);
      expect(find.text('12,345 / 67,890'), findsOneWidget);
      expect(find.text('9,876'), findsOneWidget);
    },
  );

  testWidgets(
    'Statistics screen disables speedtest button when latency test is active in backend',
    (WidgetTester tester) async {
      final fake = _StatsFakeSnapshot(
        session: const bridge.SessionSnapshot(
          status: bridge.SessionStatusDto.idle,
          activeMode: bridge.SessionModeDto.pure,
          smoothness: 'inactive',
          health: null,
          lastStopReason: null,
        ),
        room: bridge.RoomSnapshot(
          active: false,
          status: bridge.RoomStatusDto.idle,
          generation: BigInt.zero,
          route: null,
          transport: bridge.TransportSelection.udp,
          joinCode: null,
          members: const [],
          steamIdentityMismatch: null,
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
        tests: const [],
        hook: bridge.HookSnapshot(
          startupPhase: 'ready',
          connection: 'inactive',
          installation: 'ready',
          runtimeActive: false,
          version: '-',
          reconnects: 0,
          malformedFrames: BigInt.zero,
          lastError: null,
          inputDelay: null,
          inputDelayError: null,
        ),
        clientConfig: const bridge.ClientConfigDto(
          selectedRelayId: 'relay-1',
          selectedSteamId64: null,
          mode: bridge.SessionModeDto.pure,
          transport: bridge.TransportSelection.udp,
          relays: [],
          accounts: [],
          warnings: [],
        ),
      );

      final controller = _StatsTestController(fake);
      controller.testingLatency = true;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const StatisticsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('测速中'), findsOneWidget);
      final testBtn = find.byKey(const ValueKey('test-relay-latency-button'));
      expect(testBtn, findsOneWidget);

      await tester.tap(testBtn);
      await tester.pump();

      // Controller should not have been called because button was disabled!
      expect(controller.latencyTested, isFalse);
    },
  );

  testWidgets(
    'Statistics screen shows info Toast on successful Hook refresh and error Toast on rejection',
    (WidgetTester tester) async {
      final fake = _StatsFakeSnapshot(
        session: const bridge.SessionSnapshot(
          status: bridge.SessionStatusDto.idle,
          activeMode: bridge.SessionModeDto.pure,
          smoothness: 'inactive',
          health: null,
          lastStopReason: null,
        ),
        room: bridge.RoomSnapshot(
          active: false,
          status: bridge.RoomStatusDto.idle,
          generation: BigInt.zero,
          route: null,
          transport: bridge.TransportSelection.udp,
          joinCode: null,
          members: const [],
          steamIdentityMismatch: null,
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
        tests: const [],
        hook: bridge.HookSnapshot(
          startupPhase: 'ready',
          connection: 'inactive',
          installation: 'ready',
          runtimeActive: false,
          version: '-',
          reconnects: 0,
          malformedFrames: BigInt.zero,
          lastError: null,
          inputDelay: null,
          inputDelayError: null,
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
      );

      final controller = _StatsTestController(fake);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const StatisticsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Successful Hook refresh
      final refreshBtn = find.byKey(const ValueKey('refresh-hook-status'));
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pump();
      expect(controller.hookRefreshed, isTrue);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hook 状态已刷新'), findsOneWidget);

      await tester.pumpAndSettle();

      // 2. Rejected Hook refresh
      controller.shouldRejectHookRefresh = true;
      await tester.tap(refreshBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hook 正在忙碌'), findsOneWidget);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Statistics screen wraps long failure reasons, lastError, health and stopReason in Tooltips',
    (WidgetTester tester) async {
      final fake = _StatsFakeSnapshot(
        session: const bridge.SessionSnapshot(
          status: bridge.SessionStatusDto.idle,
          activeMode: bridge.SessionModeDto.pure,
          smoothness: 'inactive',
          health: null,
          lastStopReason: '由于游戏异常退出导致的会话中断 (Code 0xC0000005)',
        ),
        room: bridge.RoomSnapshot(
          active: false,
          status: bridge.RoomStatusDto.idle,
          generation: BigInt.zero,
          route: null,
          transport: bridge.TransportSelection.udp,
          joinCode: null,
          members: const [],
          steamIdentityMismatch: null,
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
        tests: [
          bridge.ConnectionTestDto(
            relayId: 'r-fail',
            relayName: '故障节点',
            endpoint: '192.0.2.4:9000',
            transport: bridge.TransportSelection.udp,
            sent: 50,
            received: 0,
            medianRttMs: null,
            failureReason:
                'Socket error 10061: Connection refused by target node',
          ),
        ],
        hook: bridge.HookSnapshot(
          startupPhase: 'failed',
          connection: 'failed',
          installation: 'failed',
          runtimeActive: false,
          version: '1.2.0',
          reconnects: 3,
          malformedFrames: BigInt.zero,
          lastError: 'DLL 注入失败: 权限不足或被第三方杀毒软件拦截',
          inputDelay: null,
          inputDelayError: null,
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
      );

      final controller = _StatsTestController(fake);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const StatisticsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Tooltip on failureReason
      expect(
        find.byTooltip('Socket error 10061: Connection refused by target node'),
        findsOneWidget,
      );

      // Verify Tooltip on lastError
      expect(find.byTooltip('DLL 注入失败: 权限不足或被第三方杀毒软件拦截'), findsOneWidget);

      // Verify Tooltip on lastStopReason
      expect(
        find.byTooltip('由于游戏异常退出导致的会话中断 (Code 0xC0000005)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Log screen renders filters, keyword search, autoscroll toggle and clear dialog',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 750));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeLogs = [
        bridge.LogEntryDto(
          timestampMs: BigInt.from(1773550000000),
          level: bridge.LogLevelDto.info,
          message: '[Hook] 目标进程已定位（PID: 14208），执行 DLL 挂载',
        ),
        bridge.LogEntryDto(
          timestampMs: BigInt.from(1773550001000),
          level: bridge.LogLevelDto.warn,
          message: '[P2P] 远端玩家 Alex 发生网络抖动',
        ),
        bridge.LogEntryDto(
          timestampMs: BigInt.from(1773550002000),
          level: bridge.LogLevelDto.error,
          message: '[Relay] 节点心跳超时，尝试重新连接',
        ),
      ];

      final controller = _LogTestController(fakeLogs);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const LogScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Check title, counts, and items
      expect(find.text('显示 3 / 共 3 条'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('警告'), findsOneWidget);
      expect(find.text('错误'), findsOneWidget);
      expect(find.text('Hook'), findsOneWidget);
      expect(find.text('P2P'), findsOneWidget);
      expect(find.text('Relay'), findsOneWidget);

      // 2. Filter by warning
      await tester.tap(find.text('警告'));
      await tester.pumpAndSettle();
      expect(find.text('显示 1 / 共 3 条'), findsOneWidget);
      expect(find.textContaining('远端玩家 Alex 发生网络抖动'), findsOneWidget);
      expect(find.textContaining('目标进程已定位'), findsNothing);

      // Reset filter to all
      await tester.tap(find.text('全部'));
      await tester.pumpAndSettle();
      expect(find.text('显示 3 / 共 3 条'), findsOneWidget);

      // 3. Test keyword search
      expect(find.text('搜索'), findsOneWidget);
      await tester.tap(find.text('搜索'));
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const ValueKey('log-search-field'));
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'Alex');
      await tester.pumpAndSettle();
      expect(find.text('显示 1 / 共 3 条'), findsOneWidget);
      expect(find.textContaining('远端玩家 Alex 发生网络抖动'), findsOneWidget);
      expect(find.textContaining('节点心跳超时'), findsNothing);

      // Clear search via suffix icon
      final clearSearchIcon = find.byIcon(Icons.close);
      expect(clearSearchIcon, findsOneWidget);
      await tester.tap(clearSearchIcon);
      await tester.pumpAndSettle();
      expect(find.text('显示 3 / 共 3 条'), findsOneWidget);
      expect(find.text('搜索'), findsOneWidget);

      // 4. Test autoscroll toggle
      expect(find.text('已锁定最新'), findsOneWidget);
      await tester.tap(find.text('已锁定最新'));
      await tester.pumpAndSettle();
      expect(find.text('已暂停滚动'), findsOneWidget);

      // 5. Test clear logs button & confirmation dialog
      final clearBtn = find.text('清空日志');
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog pops up
      expect(find.text('清空诊断日志'), findsOneWidget);
      expect(find.text('确定要清空当前的运行与排错日志吗？\n清空后内存中的历史日志将无法恢复。'), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(controller.clearLogsCalled, isFalse);
      expect(find.text('显示 3 / 共 3 条'), findsOneWidget);

      // Open again and confirm
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认清空'));
      await tester.pumpAndSettle();
      expect(controller.clearLogsCalled, isTrue);
      expect(find.text('暂无日志记录'), findsOneWidget);
    },
  );

  testWidgets(
    'Log screen supports searching by level names in Chinese and English and dismissing with Escape',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 750));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeLogs = [
        bridge.LogEntryDto(
          timestampMs: BigInt.from(1773550000000),
          level: bridge.LogLevelDto.info,
          message: '[Hook] 目标进程已定位（PID: 14208），执行 DLL 挂载',
        ),
        bridge.LogEntryDto(
          timestampMs: BigInt.from(1773550001000),
          level: bridge.LogLevelDto.warn,
          message: '[P2P] 远端玩家 Alex 发生网络抖动',
        ),
        bridge.LogEntryDto(
          timestampMs: BigInt.from(1773550002000),
          level: bridge.LogLevelDto.error,
          message: '[Relay] 节点心跳超时，尝试重新连接',
        ),
      ];

      final controller = _LogTestController(fakeLogs);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const LogScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap search button
      await tester.tap(find.text('搜索'));
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const ValueKey('log-search-field'));
      expect(searchInput, findsOneWidget);

      // Search by Chinese level name "错误"
      await tester.enterText(searchInput, '错误');
      await tester.pumpAndSettle();
      expect(find.text('显示 1 / 共 3 条'), findsOneWidget);
      expect(find.textContaining('节点心跳超时'), findsOneWidget);

      // Search by English level name "warn"
      await tester.enterText(searchInput, 'warn');
      await tester.pumpAndSettle();
      expect(find.text('显示 1 / 共 3 条'), findsOneWidget);
      expect(find.textContaining('远端玩家 Alex 发生网络抖动'), findsOneWidget);

      // Dismiss search with Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('显示 3 / 共 3 条'), findsOneWidget);
      expect(find.text('搜索'), findsOneWidget);
      expect(find.byKey(const ValueKey('log-search-field')), findsNothing);
    },
  );

  testWidgets(
    'Log screen guards clear action when logs are empty and shows notification',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 750));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _LogTestController([]);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const LogScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无日志记录'), findsOneWidget);

      // Tapping clear logs when empty does not show confirmation dialog
      final clearBtn = find.text('清空日志');
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pump();

      expect(find.text('清空诊断日志'), findsNothing);
      expect(find.text('当前没有可清空的日志'), findsOneWidget);
    },
  );

  testWidgets(
    'Log screen displays error toast when command receipt is rejected',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 750));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeLogs = [
        bridge.LogEntryDto(
          timestampMs: BigInt.from(1773550000000),
          level: bridge.LogLevelDto.info,
          message: '初始化完成',
        ),
      ];
      final controller = _LogTestController(fakeLogs)..rejectNextCommand = true;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const LogScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap export bundle
      await tester.tap(find.text('导出诊断包'));
      await tester.pump();

      // Verify rejected toast is displayed
      expect(find.text('诊断打包服务正忙，请稍候重试'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Log screen renders desktop Scrollbar and formats extreme timestamps without throwing',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 750));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeLogs = [
        bridge.LogEntryDto(
          timestampMs: BigInt.from(9999999999999999),
          level: bridge.LogLevelDto.info,
          message: '超大时间戳测试日志',
        ),
        bridge.LogEntryDto(
          timestampMs: BigInt.from(-1000),
          level: bridge.LogLevelDto.error,
          message: '负数时间戳测试日志',
        ),
      ];

      final controller = _LogTestController(fakeLogs);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const LogScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollbar), findsAtLeast(1));
      expect(find.textContaining('超大时间戳测试日志'), findsOneWidget);
      expect(find.textContaining('负数时间戳测试日志'), findsOneWidget);
    },
  );

  testWidgets(
    'About screen renders cards, tooltips, links, author info and diagnostic copy',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 750));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AboutScreen())),
      );
      await tester.pumpAndSettle();

      // 1. Verify card titles and subtitles
      expect(find.text('Tractor Beam'), findsOneWidget);
      expect(find.text('开源与链接'), findsOneWidget);
      expect(find.text('感谢'), findsOneWidget);
      expect(find.text('Sworld'), findsAtLeast(1));
      expect(find.text('tgw'), findsOneWidget);

      // 2. Verify info icons and descriptive tooltips
      expect(find.byTooltip('Tractor Beam 版本、原项目架构与核心协议标准'), findsOneWidget);
      expect(find.byTooltip('本 Flutter 客户端仓库与官方原版代码仓库'), findsOneWidget);
      expect(
        find.byTooltip('致谢为 Tractor Beam 提供开发、测试与优化支持的伙伴'),
        findsOneWidget,
      );

      // 3. Verify link rows
      expect(find.text('Flutter 客户端源码 (GitHub)'), findsOneWidget);
      expect(find.text('官方原版项目 (GitHub)'), findsOneWidget);

      // 4. Verify contributors and testers
      expect(find.text('Sworld'), findsAtLeast(1));
      expect(find.text('北国无人'), findsOneWidget);
      expect(find.text('Summerraim'), findsOneWidget);
      expect(find.text('老吴'), findsOneWidget);
      expect(find.text('舟飏'), findsOneWidget);

      // 5. Verify clicking version copies diagnostics info
      final versionTile = find.textContaining('0.5.2');
      expect(versionTile, findsOneWidget);
      await tester.tap(versionTile);
      await tester.pumpAndSettle();
      // 6. Verify UI refactor project link tooltip and interaction
      expect(
        find.byTooltip('GitHub: https://github.com/mcthesw/TractorBeam'),
        findsOneWidget,
      );
      await tester.tap(find.text('官方原版项目 (GitHub)'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Hook status and room member connection status are localized to Chinese in status bar and room screen',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 824));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeSnapshot = _LocalizationFakeSnapshot(
        hook: bridge.HookSnapshot(
          startupPhase: 'ready',
          connection: 'inactive',
          installation: 'installed',
          runtimeActive: false,
          reconnects: 0,
          malformedFrames: BigInt.zero,
        ),
        room: bridge.RoomSnapshot(
          active: true,
          status: bridge.RoomStatusDto.active,
          generation: BigInt.one,
          route: bridge.RoomRouteDto.relay,
          transport: bridge.TransportSelection.udp,
          members: [
            bridge.RoomMemberDto(
              steamId64: '76561198000000001',
              displayName: '本机玩家',
              connection: '已连接',
              isLocal: true,
            ),
            bridge.RoomMemberDto(
              steamId64: '76561198000000002',
              displayName: '远端伙伴',
              connection: 'connected',
              isLocal: false,
            ),
            bridge.RoomMemberDto(
              steamId64: '76561198000000003',
              displayName: '掉线伙伴',
              connection: 'reconnecting',
              isLocal: false,
            ),
          ],
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
        clientConfig: const bridge.ClientConfigDto(
          selectedRelayId: null,
          selectedSteamId64: null,
          mode: bridge.SessionModeDto.pure,
          transport: bridge.TransportSelection.udp,
          relays: [],
          accounts: [],
          warnings: [],
        ),
        roomHistory: const [],
      );

      final controller = _HookRoomLocalizationTestController(fakeSnapshot);

      // 1. Verify BottomStatusBar renders localized Hook status
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: TractorBeamScope(
              notifier: controller,
              child: const BottomStatusBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hook inactive is localized to 'Hook 未连接' in bottom status bar
      expect(find.text('Hook 未连接'), findsOneWidget);
      expect(find.text('Hook inactive'), findsNothing);

      // 2. Verify RoomScreen renders localized member connection statuses
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const RoomScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Member 'connected' and 'reconnecting' are localized in player cards
      expect(find.text('状态：已连接'), findsNWidgets(2));
      expect(find.text('状态：connected'), findsNothing);
      expect(find.text('状态：重连中'), findsOneWidget);
      expect(find.text('状态：reconnecting'), findsNothing);
    },
  );

  testWidgets(
    'IPv6 relay host editing and smart parsing preserves address and port',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final ipv6Relay = const bridge.RelayDto(
        id: 'ipv6-1',
        name: 'IPv6 节点 01',
        host: '2001:db8::1',
        port: 19842,
        supportsTcp: true,
        supportsUdp: true,
        defaultTransport: bridge.TransportSelection.udp,
      );

      final controller = _HomeRelayTestController(
        hasSnapshot: true,
        customRelays: [ipv6Relay],
      );

      await tester.pumpWidget(
        TractorBeamScope(
          notifier: controller,
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial rendering
      expect(find.text('IPv6 节点 01'), findsOneWidget);
      expect(find.text('2001:db8::1:19842'), findsOneWidget);

      // Open Edit Relay dialog and verify address is not split into fragments
      await tester.tap(find.text('编辑relay'));
      await tester.pumpAndSettle();

      expect(find.text('编辑 Relay 节点'), findsOneWidget);
      final addressField = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      final portField = tester.widget<TextField>(find.byType(TextField).at(2));

      // Must be full IPv6 address, NOT truncated to "2001" or "["
      expect(addressField.controller?.text, '2001:db8::1');
      expect(portField.controller?.text, '19842');

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Now test Add Relay smart parsing with bracketed IPv6 and raw IPv6
      await tester.tap(find.text('添加relay'));
      await tester.pumpAndSettle();

      // Paste bracketed IPv6 with port
      await tester.enterText(find.byType(TextField).at(0), '新 IPv6 节点');
      await tester.enterText(
        find.byType(TextField).at(1),
        '[fe80::2001:1]:25910',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Dialog should have closed without errors
      expect(find.text('添加 Relay 节点'), findsNothing);
    },
  );

  testWidgets('Long relay name and host do not cause RenderFlex overflow', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(440, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final longRelay = const bridge.RelayDto(
      id: 'long-1',
      name: '这是一个超长超长超长超长的中继节点名称测试用例香港CN2线路备用01',
      host:
          'extremely-long-subdomain-hostname.relay-cluster-production.game-infrastructure.net',
      port: 65535,
      supportsTcp: true,
      supportsUdp: true,
      defaultTransport: bridge.TransportSelection.udp,
    );

    final controller = _HomeRelayTestController(
      hasSnapshot: true,
      customRelays: [longRelay],
    );

    await tester.pumpWidget(
      TractorBeamScope(
        notifier: controller,
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Latency testing button is disabled while test is in progress', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = _HomeRelayTestController(
      hasSnapshot: true,
      customRelays: const [
        bridge.RelayDto(
          id: 'r1',
          name: '测试节点',
          host: '192.0.2.4',
          port: 19842,
          supportsTcp: true,
          supportsUdp: true,
          defaultTransport: bridge.TransportSelection.udp,
        ),
      ],
    );

    await tester.pumpWidget(
      TractorBeamScope(
        notifier: controller,
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger latency test
    await tester.tap(find.text('测试延迟'));
    await tester.pump();

    // Verify progress indicator is showing while pending
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Tapping during active test does not crash or queue duplicate tests
    await tester.tap(find.text('测试延迟'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete testing
    controller.finishTestingLatency();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Fallback relay deletion displays guidance card without 0ms zombie badge',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Mount isolated HomeScreen without TractorBeamScope (fallback mode)
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('上海 BGP 极速节点 01'), findsOneWidget);

      // Open Edit dialog and delete the node
      await tester.tap(find.text('编辑relay'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // Confirm secondary deletion
      expect(find.text('删除 Relay 节点'), findsOneWidget);
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();

      // Should show guidance card, NOT a 0ms green badge
      expect(find.text('当前未配置任何 Relay 节点'), findsOneWidget);
      expect(find.text('0ms'), findsNothing);
    },
  );

  testWidgets(
    'English localization uses standard English period in notice card',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const TbNetApp(initialLocale: Locale('en', 'US')),
      );
      await tester.pumpAndSettle();

      // In English, instruction should not contain Chinese full-width period ' 。'
      expect(find.text(' 。'), findsNothing);
      expect(find.text('.'), findsOneWidget);
    },
  );

  testWidgets('Room screen cards have descriptive tooltips on info icons', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = _RoomScreenTestController(inRoom: true);
    await tester.pumpWidget(_testRoomApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byTooltip('房间联机码用于邀请其他玩家加入对局，点击可复制'), findsOneWidget);
    expect(find.byTooltip('当前用于联机的 Steam 账号身份，支持快速切换与手动管理'), findsOneWidget);
    expect(find.byTooltip('当前房间内的全部玩家及对局连接状态与网络质量'), findsOneWidget);
  });

  testWidgets(
    'Room screen handles Emoji and surrogate pair usernames safely without splitting UTF-16',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _RoomScreenTestController(
        inRoom: true,
        currentSteamId64: '76561198000000001',
        currentSteamUsername: '🎮 Master',
        customAccounts: const [
          bridge.SteamAccountDto(
            steamId64: '76561198000000001',
            displayName: '🎮 Master',
            mostRecent: true,
            isManual: false,
          ),
        ],
        customMembers: const [
          bridge.RoomMemberDto(
            steamId64: '76561198000000001',
            displayName: '🎮 Master',
            connection: '已连接',
            isLocal: true,
          ),
          bridge.RoomMemberDto(
            steamId64: '76561198000000002',
            displayName: '🔥Fire',
            connection: 'playing',
            isLocal: false,
          ),
        ],
      );

      await tester.pumpWidget(_testRoomApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('🎮M'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('party-member-76561198000000001')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('party-member-76561198000000002')),
        findsOneWidget,
      );
      expect(find.text('🔥F'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Room screen disables copy button when room code is empty and copies when present',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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

      final controller = _RoomScreenTestController(
        inRoom: true,
        currentRoomCode: '',
      );

      await tester.pumpWidget(_testRoomApp(controller: controller));
      await tester.pumpAndSettle();

      final disabledOpacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.widgetWithText(TornPaperButton, '复制'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(disabledOpacity.opacity, 0.48);

      await tester.tap(find.widgetWithText(TornPaperButton, '复制'));
      await tester.pumpAndSettle();
      expect(clipboardLog, isEmpty);

      controller.currentRoomCode = 'TB-ABCD-8888';
      controller.notifyListeners();
      await tester.pumpAndSettle();

      final enabledOpacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.widgetWithText(TornPaperButton, '复制'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(enabledOpacity.opacity, 1.0);

      await tester.tap(find.widgetWithText(TornPaperButton, '复制'));
      await tester.pumpAndSettle();
      expect(clipboardLog, contains('TB-ABCD-8888'));
    },
  );

  testWidgets(
    'Room screen quick switch banner adapts padding and avoids RenderFlex overflow',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 680));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _RoomScreenTestController(
        currentSteamId64: '76561198000000001',
        currentSteamUsername: 'OldUser',
        customAccounts: const [
          bridge.SteamAccountDto(
            steamId64: '76561198000000001',
            displayName: 'OldUser',
            mostRecent: false,
            isManual: false,
          ),
          bridge.SteamAccountDto(
            steamId64: '76561198000000002',
            displayName: 'RecentGamer',
            mostRecent: true,
            isManual: false,
          ),
        ],
        customMostRecent: const bridge.SteamAccountDto(
          steamId64: '76561198000000002',
          displayName: 'RecentGamer',
          mostRecent: true,
          isManual: false,
        ),
      );

      await tester.pumpWidget(_testRoomApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('点击快速切换'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Room screen LAN mode account switch leaves room and displays proper message',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _RoomScreenTestController(
        inRoom: true,
        roomRoute: bridge.RoomRouteDto.lan,
        currentSteamId64: '76561198000000001',
        currentSteamUsername: 'UserOne',
        customAccounts: const [
          bridge.SteamAccountDto(
            steamId64: '76561198000000001',
            displayName: 'UserOne',
            mostRecent: true,
            isManual: false,
          ),
          bridge.SteamAccountDto(
            steamId64: '76561198000000002',
            displayName: 'UserTwo',
            mostRecent: false,
            isManual: false,
          ),
        ],
      );

      await tester.pumpWidget(_testRoomApp(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('切换'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('UserTwo'));
      await tester.pumpAndSettle();

      expect(find.text('在房间中切换 Steam 账号'), findsOneWidget);
      expect(
        find.textContaining('当前处于局域网直连房间中。切换 Steam 账号需要退出当前房间'),
        findsOneWidget,
      );
      await tester.tap(find.text('确认切换'));
      await tester.pumpAndSettle();

      expect(controller.leaveRoomCalled, isTrue);
      expect(controller.currentSteamId64, '76561198000000002');
      expect(controller.currentSteamUsername, 'UserTwo');
    },
  );

  testWidgets(
    'Room screen cancels LAN endpoint selection and releases pending room',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _RoomScreenTestController(
        inRoom: false,
        roomRoute: bridge.RoomRouteDto.lan,
      );

      await tester.pumpWidget(_testRoomApp(controller: controller));
      await tester.pumpAndSettle();

      // Trigger LAN selection event
      controller.triggerLanSelection(['192.168.1.100:19842', '10.0.0.5:19842']);
      await tester.pumpAndSettle();

      expect(find.text('选择局域网端点'), findsOneWidget);

      // Tap cancel in dialog
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Ensure leaveRoom was called on cancel
      expect(controller.leaveRoomCalled, isTrue);
    },
  );

  testWidgets(
    'Room screen PlayerCard applies explicit custom text colors and does not rely on initials',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _RoomScreenTestController(
        inRoom: true,
        customMembers: const [
          bridge.RoomMemberDto(
            steamId64: '76561198000000088',
            displayName: 'AWGamer',
            connection: 'playing',
            isLocal: false,
          ),
        ],
      );

      await tester.pumpWidget(_testRoomApp(controller: controller));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('party-member-76561198000000088')),
        findsOneWidget,
      );

      final initialsText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('party-member-76561198000000088')),
          matching: find.text('AW'),
        ),
      );

      expect(initialsText.style?.color, AppColors.accentRed);
    },
  );
}

class _StatsFakeSnapshot extends _FakeAppSnapshot {
  final bridge.SessionSnapshot _session;
  final bridge.RoomSnapshot _room;
  final bridge.CountersDto _counters;
  final List<bridge.ConnectionTestDto> _tests;
  final bridge.HookSnapshot _hook;
  final bridge.ClientConfigDto _clientConfig;

  _StatsFakeSnapshot({
    required bridge.SessionSnapshot session,
    required bridge.RoomSnapshot room,
    required bridge.CountersDto counters,
    required List<bridge.ConnectionTestDto> tests,
    required bridge.HookSnapshot hook,
    required bridge.ClientConfigDto clientConfig,
  }) : _session = session,
       _room = room,
       _counters = counters,
       _tests = tests,
       _hook = hook,
       _clientConfig = clientConfig;

  @override
  bridge.SessionSnapshot get session => _session;

  @override
  bridge.RoomSnapshot get room => _room;

  @override
  bridge.CountersDto get counters => _counters;

  @override
  List<bridge.ConnectionTestDto> get connectionTests => _tests;

  @override
  bridge.HookSnapshot get hook => _hook;

  @override
  bridge.ClientConfigDto get clientConfig => _clientConfig;
}

class _StatsTestController extends TractorBeamController {
  final bridge.AppSnapshot customSnapshot;
  bool latencyTested = false;
  bool hookRefreshed = false;
  bool testingLatency = false;
  bool shouldRejectHookRefresh = false;

  _StatsTestController(this.customSnapshot) : super.detached();

  @override
  bridge.AppSnapshot? get snapshot => customSnapshot;

  @override
  bool get isTestingLatency => testingLatency;

  @override
  bridge.RelayDto? get selectedRelay => const bridge.RelayDto(
    id: 'relay-1',
    name: '上海节点',
    host: '192.0.2.1',
    port: 8080,
    supportsUdp: true,
    supportsTcp: true,
    defaultTransport: bridge.TransportSelection.udp,
  );

  @override
  bridge.CommandReceipt testRelayLatency() {
    latencyTested = true;
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt refreshHookStatus() {
    hookRefreshed = true;
    if (shouldRejectHookRefresh) {
      return const bridge.CommandReceipt(
        accepted: false,
        rejection: bridge.CommandRejection(
          code: 'busy',
          displayText: 'Hook busy',
          message: bridge.LocalizedMessageDto(
            key: 'rejection.hook_refresh_rejected',
            args: [],
            fallbackZh: 'Hook 正在忙碌',
          ),
        ),
      );
    }
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }
}

class _FakeAppSnapshot implements bridge.AppSnapshot {
  const _FakeAppSnapshot();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _HomeRelayTestController extends TractorBeamController {
  bool inRoom;
  bool sessionRunning;
  List<bridge.RelayDto> customRelays;
  bool hasSnapshot;
  bool _testingLatency = false;
  bool latencyTested = false;

  _HomeRelayTestController({
    this.inRoom = false,
    this.sessionRunning = false,
    this.customRelays = const [],
    this.hasSnapshot = true,
  }) : super.detached();

  @override
  bool get isNative => true;

  @override
  bool get canMutate => true;

  @override
  bool get isInRoom => inRoom;

  @override
  bool get isSessionRunning => sessionRunning;

  @override
  List<bridge.RelayDto> get relays => customRelays;

  @override
  bridge.RelayDto? get selectedRelay =>
      customRelays.isNotEmpty ? customRelays.first : null;

  @override
  bridge.AppSnapshot? get snapshot =>
      hasSnapshot ? const _FakeAppSnapshot() : null;

  @override
  bool get isTestingLatency => _testingLatency;

  @override
  bridge.CommandReceipt testRelayLatency() {
    latencyTested = true;
    _testingLatency = true;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  void finishTestingLatency() {
    _testingLatency = false;
    notifyListeners();
  }

  @override
  bridge.CommandReceipt addRelay({
    required String name,
    required String host,
    required int port,
    required bool tcp,
    required bool udp,
    required bool defaultUdp,
  }) {
    customRelays.add(
      bridge.RelayDto(
        id: 'relay-${customRelays.length + 1}',
        name: name,
        host: host,
        port: port,
        supportsTcp: tcp,
        supportsUdp: udp,
        defaultTransport: defaultUdp
            ? bridge.TransportSelection.udp
            : bridge.TransportSelection.tcp,
      ),
    );
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt updateRelay({
    required String id,
    required String name,
    required String host,
    required int port,
    required bool tcp,
    required bool udp,
    required bool defaultUdp,
  }) {
    final idx = customRelays.indexWhere((r) => r.id == id);
    final updated = bridge.RelayDto(
      id: id,
      name: name,
      host: host,
      port: port,
      supportsTcp: tcp,
      supportsUdp: udp,
      defaultTransport: defaultUdp
          ? bridge.TransportSelection.udp
          : bridge.TransportSelection.tcp,
    );
    if (idx != -1) {
      customRelays[idx] = updated;
    } else {
      customRelays.add(updated);
    }
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt deleteRelay(String id) {
    customRelays.removeWhere((r) => r.id == id);
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }
}

class _NativeMockController extends TractorBeamController {
  bool sessionRunning;
  _NativeMockController({required this.sessionRunning}) : super.detached();

  @override
  bool get isNative => true;

  @override
  bool get isSessionRunning => sessionRunning;

  void setSessionRunning(bool value) {
    sessionRunning = value;
    notifyListeners();
  }
}

class _SteamMismatchTestController extends TractorBeamController {
  _SteamMismatchTestController() : super.detached();

  bool useGameSteamAccountCalled = false;

  @override
  bridge.SteamIdentityMismatchDto? get steamIdentityMismatch =>
      const bridge.SteamIdentityMismatchDto(
        roomSteamId64: '76561198000000001',
        gameSteamId64: '76561198000000002',
      );

  @override
  bool get isInRoom => true;

  @override
  bridge.CommandReceipt useGameSteamAccount() {
    useGameSteamAccountCalled = true;
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }
}

class _LogTestController extends TractorBeamController {
  final List<bridge.LogEntryDto> logs;
  bool clearLogsCalled = false;
  bool rejectNextCommand = false;

  _LogTestController(this.logs) : super.detached();

  @override
  bridge.AppSnapshot? get snapshot => _LogFakeSnapshot(logs);

  @override
  bridge.CommandReceipt clearLogs() {
    clearLogsCalled = true;
    if (rejectNextCommand) {
      return const bridge.CommandReceipt(
        accepted: false,
        rejection: bridge.CommandRejection(
          code: 'clear_logs_busy',
          displayText: '日志记录器正忙，暂时无法清空',
          message: bridge.LocalizedMessageDto(
            key: 'rejection.clear_logs_busy',
            args: [],
            fallbackZh: '日志记录器正忙，暂时无法清空',
          ),
        ),
      );
    }
    logs.clear();
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt exportDiagnosticsBundle() {
    if (rejectNextCommand) {
      return const bridge.CommandReceipt(
        accepted: false,
        rejection: bridge.CommandRejection(
          code: 'export_busy',
          displayText: '诊断打包服务正忙，请稍候重试',
          message: bridge.LocalizedMessageDto(
            key: 'rejection.export_busy',
            args: [],
            fallbackZh: '诊断打包服务正忙，请稍候重试',
          ),
        ),
      );
    }
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }
}

class _LogFakeSnapshot extends _FakeAppSnapshot {
  final List<bridge.LogEntryDto> customLogs;
  _LogFakeSnapshot(this.customLogs);

  @override
  List<bridge.LogEntryDto> get logs => customLogs;
}

class _LocalizationFakeSnapshot extends _FakeAppSnapshot {
  final bridge.HookSnapshot _hook;
  final bridge.RoomSnapshot _room;
  final bridge.CountersDto _counters;
  final bridge.ClientConfigDto _clientConfig;
  final List<bridge.RoomHistoryEntryDto> _roomHistory;

  _LocalizationFakeSnapshot({
    required bridge.HookSnapshot hook,
    required bridge.RoomSnapshot room,
    required bridge.CountersDto counters,
    required bridge.ClientConfigDto clientConfig,
    required List<bridge.RoomHistoryEntryDto> roomHistory,
  }) : _hook = hook,
       _room = room,
       _counters = counters,
       _clientConfig = clientConfig,
       _roomHistory = roomHistory;

  @override
  bridge.HookSnapshot get hook => _hook;

  @override
  bridge.RoomSnapshot get room => _room;

  @override
  bridge.CountersDto get counters => _counters;

  @override
  bridge.ClientConfigDto get clientConfig => _clientConfig;

  @override
  List<bridge.RoomHistoryEntryDto> get roomHistory => _roomHistory;
}

class _HookRoomLocalizationTestController extends TractorBeamController {
  final bridge.AppSnapshot _fakeSnapshot;
  _HookRoomLocalizationTestController(this._fakeSnapshot) : super.detached();

  @override
  bridge.AppSnapshot? get snapshot => _fakeSnapshot;

  @override
  bool get isInRoom => true;

  @override
  bool get isSessionRunning => false;
}

class _RoomScreenTestController extends TractorBeamController {
  bool inRoom;
  String currentRoomCode;
  String currentSteamId64;
  String currentSteamUsername;
  List<bridge.SteamAccountDto> customAccounts;
  bridge.SteamAccountDto? customMostRecent;
  bridge.RoomRouteDto roomRoute;
  List<bridge.RoomMemberDto> customMembers;
  bool leaveRoomCalled = false;
  List<String> lanEndpoints = const [];
  bridge.AppEvent? _event;
  BigInt _rev = BigInt.one;

  _RoomScreenTestController({
    this.inRoom = false,
    this.currentRoomCode = 'TB-TEST-1234',
    this.currentSteamId64 = '76561198000000001',
    this.currentSteamUsername = 'TestPlayer',
    this.customAccounts = const [],
    this.customMostRecent,
    this.roomRoute = bridge.RoomRouteDto.relay,
    this.customMembers = const [],
  }) : super.detached();

  @override
  BigInt get revision => _rev;

  @override
  bridge.AppEvent? get latestEvent => _event;

  void triggerLanSelection(List<String> endpoints) {
    lanEndpoints = endpoints;
    _rev = _rev + BigInt.one;
    _event = const bridge.AppEvent(
      code: 'lan_endpoint_selection_required',
      success: true,
      displayText: 'LAN endpoint selection required',
      message: bridge.LocalizedMessageDto(
        key: 'event.lan_endpoint_selection_required',
        args: [],
        fallbackZh: 'LAN endpoint selection required',
      ),
    );
    notifyListeners();
  }

  @override
  bool get isInRoom => inRoom;

  @override
  bool get isNative => true;

  @override
  bridge.AppSnapshot? get snapshot => _RoomFakeSnapshot(
    inRoom: inRoom,
    roomCode: currentRoomCode,
    route: roomRoute,
    members: customMembers,
    activeSteamId64: currentSteamId64,
    accounts: customAccounts,
    lanEndpoints: lanEndpoints,
  );

  @override
  List<bridge.SteamAccountDto> get accounts => customAccounts;

  @override
  bridge.SteamAccountDto? get selectedAccount {
    for (final account in customAccounts) {
      if (account.steamId64 == currentSteamId64) return account;
    }
    return null;
  }

  @override
  bridge.SteamAccountDto? get mostRecentAccount => customMostRecent;

  @override
  bridge.CommandReceipt leaveRoom({
    bool clearPending = false,
    bool reportRejection = true,
  }) {
    leaveRoomCalled = true;
    inRoom = false;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt selectSteamAccount(String? steamId64) {
    if (steamId64 != null) {
      currentSteamId64 = steamId64;
      final acc = customAccounts
          .where((a) => a.steamId64 == steamId64)
          .firstOrNull;
      if (acc != null) currentSteamUsername = acc.displayName;
      notifyListeners();
    }
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt saveManualSteamAccount({
    required String steamId64,
    required String displayName,
  }) {
    currentSteamId64 = steamId64;
    currentSteamUsername = displayName;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }
}

class _RoomFakeSnapshot extends _FakeAppSnapshot {
  final bool inRoom;
  final String roomCode;
  final bridge.RoomRouteDto route;
  final List<bridge.RoomMemberDto> members;
  final String activeSteamId64;
  final List<bridge.SteamAccountDto> accounts;
  final List<String> lanEndpoints;

  _RoomFakeSnapshot({
    required this.inRoom,
    required this.roomCode,
    required this.route,
    required this.members,
    required this.activeSteamId64,
    required this.accounts,
    this.lanEndpoints = const [],
  });

  @override
  List<String> get lanJoinEndpoints => lanEndpoints;

  @override
  bridge.RoomSnapshot get room => bridge.RoomSnapshot(
    active: inRoom,
    status: inRoom ? bridge.RoomStatusDto.active : bridge.RoomStatusDto.idle,
    generation: BigInt.one,
    joinCode: roomCode,
    route: route,
    transport: bridge.TransportSelection.udp,
    members: members,
  );

  @override
  bridge.ClientConfigDto get clientConfig => bridge.ClientConfigDto(
    selectedRelayId: null,
    selectedSteamId64: activeSteamId64,
    mode: bridge.SessionModeDto.official,
    transport: bridge.TransportSelection.udp,
    relays: const [],
    accounts: accounts,
    warnings: const [],
  );
}

Widget _testRoomApp({
  TractorBeamController? controller,
  Locale locale = const Locale('zh', 'CN'),
}) {
  final content = MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const Scaffold(body: RoomScreen()),
  );
  if (controller != null) {
    return TractorBeamScope(notifier: controller, child: content);
  }
  return content;
}

class _SettingsFakeSnapshot extends _FakeAppSnapshot {
  final bool sessionRunning;
  final bridge.SessionModeDto? activeSessionMode;
  final bridge.SessionModeDto configMode;
  final bridge.TransportSelection transportSelection;
  final int? hookDelay;
  final String? hookDelayError;

  _SettingsFakeSnapshot({
    required this.sessionRunning,
    required this.activeSessionMode,
    required this.configMode,
    required this.transportSelection,
    required this.hookDelay,
    required this.hookDelayError,
  });

  @override
  bridge.SessionSnapshot get session => bridge.SessionSnapshot(
    status: sessionRunning
        ? bridge.SessionStatusDto.running
        : bridge.SessionStatusDto.idle,
    activeMode: activeSessionMode,
    smoothness: 'smooth',
  );

  @override
  bridge.ClientConfigDto get clientConfig => bridge.ClientConfigDto(
    mode: configMode,
    transport: transportSelection,
    relays: const [],
    accounts: const [],
    warnings: const [],
  );

  @override
  bridge.HookSnapshot get hook => bridge.HookSnapshot(
    startupPhase: 'idle',
    connection: 'connected',
    installation: 'ready',
    runtimeActive: true,
    reconnects: 0,
    malformedFrames: BigInt.zero,
    inputDelay: hookDelay,
    inputDelayError: hookDelayError,
  );
}

class _SettingsScreenTestController extends TractorBeamController {
  bool sessionRunning;
  bridge.SessionModeDto? activeSessionMode;
  bridge.SessionModeDto configMode;
  bridge.TransportSelection transportSelection;
  int? hookDelay;
  String? hookDelayError;
  bridge.AppEvent? _event;
  BigInt _rev = BigInt.one;
  bool shouldRejectTransport = false;
  bool shouldRejectMode = false;

  _SettingsScreenTestController({
    this.sessionRunning = true,
    this.activeSessionMode = bridge.SessionModeDto.pure,
    this.configMode = bridge.SessionModeDto.pure,
    this.transportSelection = bridge.TransportSelection.relayDefault,
    this.hookDelay = 2,
    this.hookDelayError,
  }) : super.detached();

  @override
  bool get isNative => true;

  @override
  bool get isSessionRunning => sessionRunning;

  @override
  BigInt get revision => _rev;

  @override
  bridge.AppEvent? get latestEvent => _event;

  void triggerEvent(bridge.AppEvent event) {
    _rev = _rev + BigInt.one;
    _event = event;
    notifyListeners();
  }

  void setSessionRunning(bool value) {
    sessionRunning = value;
    _rev = _rev + BigInt.one;
    notifyListeners();
  }

  void setHookDelay(int? delay, {String? error}) {
    hookDelay = delay;
    hookDelayError = error;
    _rev = _rev + BigInt.one;
    notifyListeners();
  }

  @override
  bridge.CommandReceipt setTransport(bridge.TransportSelection transport) {
    if (shouldRejectTransport) {
      return const bridge.CommandReceipt(
        accepted: false,
        rejection: bridge.CommandRejection(
          code: 'locked',
          displayText: 'Transport change rejected',
          message: bridge.LocalizedMessageDto(
            key: 'error.locked',
            args: [],
            fallbackZh: '传输协议已被锁定',
          ),
        ),
      );
    }
    transportSelection = transport;
    _rev = _rev + BigInt.one;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.CommandReceipt setMode(bridge.SessionModeDto mode) {
    if (shouldRejectMode) {
      return const bridge.CommandReceipt(
        accepted: false,
        rejection: bridge.CommandRejection(
          code: 'locked',
          displayText: 'Mode change rejected',
          message: bridge.LocalizedMessageDto(
            key: 'error.locked',
            args: [],
            fallbackZh: '工作模式已被锁定',
          ),
        ),
      );
    }
    configMode = mode;
    _rev = _rev + BigInt.one;
    notifyListeners();
    return const bridge.CommandReceipt(accepted: true, rejection: null);
  }

  @override
  bridge.AppSnapshot? get snapshot => _SettingsFakeSnapshot(
    sessionRunning: sessionRunning,
    activeSessionMode: activeSessionMode,
    configMode: configMode,
    transportSelection: transportSelection,
    hookDelay: hookDelay,
    hookDelayError: hookDelayError,
  );
}
