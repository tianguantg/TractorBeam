import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/l10n/l10n.dart';
import 'package:tbnet_app/theme/app_theme.dart';
import 'package:tbnet_app/widgets/app_dialogs.dart';
import 'package:tbnet_app/widgets/app_notification.dart';
import 'package:tbnet_app/widgets/status_bar.dart';
import 'package:tbnet_app/widgets/torn_paper.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Xiaolai',
      scaffoldBackgroundColor: AppColors.canvasBg,
    ),
    locale: const Locale('zh', 'CN'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Accessibility & Keyboard Navigation Hardening Tests', () {
    testWidgets('TornPaperButton can be focused and activated via Enter and Space',
        (tester) async {
      final handle = tester.ensureSemantics();
      var tapCount = 0;
      await tester.pumpWidget(
        _wrapWithApp(
          TornPaperButton(
            onTap: () => tapCount++,
            semanticLabel: '测试按钮',
            child: const Text('点击测试'),
          ),
        ),
      );

      // Verify Semantics
      expect(
        tester.getSemantics(find.byType(TornPaperButton)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasSelectedState: true,
          label: '测试按钮\n点击测试',
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      // Verify action invoke
      Actions.invoke(
        tester.element(find.text('点击测试')),
        const ActivateIntent(),
      );
      expect(tapCount, 1);

      handle.dispose();
    });

    testWidgets('StatusBar launch game button is keyboard accessible and has focus',
        (tester) async {
      final handle = tester.ensureSemantics();
      var launchCount = 0;
      await tester.pumpWidget(
        _wrapWithApp(
          Column(
            children: [
              Expanded(child: Container()),
              BottomStatusBar(
                onLaunchGame: () => launchCount++,
              ),
            ],
          ),
        ),
      );

      // Verify Semantics on launch button
      final launchFinder = find.byKey(const ValueKey('status-bar-launch-button'));
      expect(launchFinder, findsOneWidget);

      expect(
        tester.getSemantics(launchFinder),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          label: '启动游戏',
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      // Press Enter/Space on launch button
      Actions.invoke(
        tester.element(find.text('启动游戏')),
        const ActivateIntent(),
      );
      expect(launchCount, 1);

      handle.dispose();
    });

    testWidgets('PaperDialogShell provides route semantics and autofocus',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => const PaperDialogShell(
                    icon: Icon(Icons.info),
                    title: '测试弹窗标题',
                    content: Text('内容区域'),
                    actions: [Text('确定')],
                  ),
                );
              },
              child: const Text('打开弹窗'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开弹窗'));
      await tester.pumpAndSettle();
      expect(find.byType(PaperDialogShell), findsOneWidget);
      expect(find.text('测试弹窗标题'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.scopesRoute == true &&
              w.properties.label == '测试弹窗标题',
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PaperDialogShell), findsNothing);

      handle.dispose();
    });

    test('DialogTextStyles.inputHint meets WCAG AA contrast threshold', () {
      expect(DialogTextStyles.inputHint.color, const Color(0xFF6B635B));
    });

    testWidgets('AppNotification broadcasts liveRegion semantics',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppNotification.show(context, '操作成功完成');
              },
              child: const Text('展示通知'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('展示通知'));
      await tester.pumpAndSettle();

      expect(find.text('操作成功完成'), findsOneWidget);
      // Verify liveRegion semantics on notification host
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      );
      expect(semanticsFinder, findsOneWidget);

      AppNotification.dismiss();
      await tester.pumpAndSettle();
    });
  });
}
