import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/startup/startup_warmup.dart';
import 'package:tbnet_app/widgets/app_dialogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, fontFamily: 'Xiaolai'),
      home: Scaffold(body: child),
    );
  }

  group('showCloseApplicationDialog', () {
    testWidgets(
      'renders default options when tray is available and not in room',
      (tester) async {
        CloseApplicationChoice? result;
        await tester.pumpWidget(
          wrapWithTheme(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showCloseApplicationDialog(
                    context,
                    isInRoom: false,
                    isSessionRunning: false,
                    hasTray: true,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('关闭 Tractor Beam'), findsOneWidget);
        expect(find.text('是完全退出程序，还是隐藏到系统托盘继续保持联机？'), findsOneWidget);
        expect(find.text('隐藏到托盘'), findsOneWidget);
        expect(find.text('完全退出'), findsOneWidget);

        await tester.tap(find.text('隐藏到托盘'));
        await tester.pumpAndSettle();

        expect(result, CloseApplicationChoice.hideToTray);
      },
    );

    testWidgets('renders room warning when in active room with tray', (
      tester,
    ) async {
      CloseApplicationChoice? result;
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCloseApplicationDialog(
                  context,
                  isInRoom: true,
                  isSessionRunning: false,
                  hasTray: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('关闭 Tractor Beam'), findsOneWidget);
      expect(
        find.text('当前正处于联机房间中！若要保持房间请隐藏到托盘；选择“完全退出”将离开并断开房间连接。'),
        findsOneWidget,
      );

      await tester.tap(find.text('完全退出'));
      await tester.pumpAndSettle();

      expect(result, CloseApplicationChoice.exit);
    });

    testWidgets('renders session warning when game is running with tray', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showCloseApplicationDialog(
                  context,
                  isInRoom: false,
                  isSessionRunning: true,
                  hasTray: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('游戏正在运行中！若要保持联机请隐藏到托盘；选择“完全退出”将立即中断游戏联机会话。'),
        findsOneWidget,
      );
    });

    testWidgets('renders cancel and exit when tray is unavailable', (
      tester,
    ) async {
      CloseApplicationChoice? result;
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showCloseApplicationDialog(
                  context,
                  isInRoom: false,
                  isSessionRunning: false,
                  hasTray: false,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('退出 Tractor Beam'), findsOneWidget);
      expect(find.text('确定要退出 Tractor Beam 吗？'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('退出程序'), findsOneWidget);
      expect(find.text('隐藏到托盘'), findsNothing);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('StartupSplash', () {
    testWidgets('renders normal splash mark when no error', (tester) async {
      await tester.pumpWidget(wrapWithTheme(const StartupSplash()));

      expect(find.byKey(const ValueKey('startup-app-mark')), findsOneWidget);
      expect(find.text('应用初始化失败'), findsNothing);
    });

    testWidgets(
      'renders error details, retry, and exit buttons when error occurs',
      (tester) async {
        var retried = false;
        var exited = false;

        await tester.pumpWidget(
          wrapWithTheme(
            StartupSplash(
              error: 'Simulated bridge initialization error',
              onRetry: () => retried = true,
              onExit: () => exited = true,
            ),
          ),
        );

        expect(find.text('应用初始化失败'), findsOneWidget);
        expect(
          find.text('Simulated bridge initialization error'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('startup-error-close')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('startup-error-exit')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('startup-error-retry')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('startup-error-retry')));
        await tester.pump();
        expect(retried, isTrue);

        await tester.tap(find.byKey(const ValueKey('startup-error-exit')));
        await tester.pump();
        expect(exited, isTrue);
      },
    );
  });

  group('showReplaceRoomByCodeDialog', () {
    testWidgets('renders concise prompt and join code, and handles actions', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showReplaceRoomByCodeDialog(
                  context,
                  'TB-SWITCH-TEST-999',
                );
              },
              child: const Text('Open Replace Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Replace Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('加入新的联机房间'), findsOneWidget);
      expect(find.text('TB-SWITCH-TEST-999'), findsOneWidget);
      expect(find.text('将退出当前房间并结束游戏联机，是否继续？'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('退出并加入'), findsOneWidget);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await tester.tap(find.text('Open Replace Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('退出并加入'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });
}
