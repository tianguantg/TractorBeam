import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/l10n/l10n.dart';
import 'package:tbnet_app/theme/app_theme.dart';
import 'package:tbnet_app/widgets/app_notification.dart';

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
  group('AppNotification Hardening Tests', () {
    tearDown(() {
      AppNotification.dismiss();
    });

    testWidgets('Natural timeout triggers smooth reverse animation and removal',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppNotification.show(
                  context,
                  '超时测试通知',
                  duration: const Duration(milliseconds: 300),
                );
              },
              child: const Text('显示'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('超时测试通知'), findsOneWidget);

      // Advance past duration (300ms total, 80ms more) to start reverse animation
      await tester.pump(const Duration(milliseconds: 100));
      // Reversing has started: IgnorePointer should now be true
      final ignorePointerFinder = find.byWidgetPredicate(
        (w) => w is IgnorePointer && w.ignoring == true,
      );
      expect(ignorePointerFinder, findsOneWidget);

      // Advance through reverse duration (160ms)
      await tester.pumpAndSettle();
      expect(find.text('超时测试通知'), findsNothing);
    });

    testWidgets('Tapping dismiss button activates IgnorePointer and exits cleanly',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppNotification.show(context, '点击关闭测试');
              },
              child: const Text('显示'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示'));
      await tester.pumpAndSettle();
      expect(find.text('点击关闭测试'), findsOneWidget);

      // Tap on the toast to dismiss it
      await tester.tap(find.text('点击关闭测试'));
      await tester.pump(); // Start dismiss

      final ignorePointerFinder = find.byWidgetPredicate(
        (w) => w is IgnorePointer && w.ignoring == true,
      );
      expect(ignorePointerFinder, findsOneWidget);

      // Rapid consecutive tap during dismiss should not throw
      await tester.tap(find.text('点击关闭测试'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('点击关闭测试'), findsNothing);
    });

    testWidgets('Hover pauses timeout timer and exit resumes timer',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppNotification.show(
                  context,
                  '悬停测试通知',
                  duration: const Duration(milliseconds: 400),
                );
              },
              child: const Text('显示'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('悬停测试通知'), findsOneWidget);

      // Simulate mouse enter
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('悬停测试通知')));
      await tester.pump();

      // Advance by 600ms (more than duration) while mouse is hovering
      await tester.pump(const Duration(milliseconds: 600));
      // Toast must still be visible and not dismissing
      expect(find.text('悬停测试通知'), findsOneWidget);
      final activeIgnorePointer = find.byWidgetPredicate(
        (w) => w is IgnorePointer && w.ignoring == true,
      );
      expect(activeIgnorePointer, findsNothing);

      // Move mouse away
      await gesture.moveTo(Offset.zero);
      await tester.pump();

      // Grace period (1200ms) hasn't passed yet at 500ms
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('悬停测试通知'), findsOneWidget);

      // Finish grace period (1200ms) + reverse duration (160ms)
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(find.text('悬停测试通知'), findsNothing);
    });

    testWidgets('Immediate dismiss tears down entry cleanly without throwing',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppNotification.show(context, '即时清理通知');
              },
              child: const Text('显示'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示'));
      await tester.pumpAndSettle();
      expect(find.text('即时清理通知'), findsOneWidget);

      AppNotification.dismiss();
      await tester.pumpAndSettle();
      expect(find.text('即时清理通知'), findsNothing);

      // Redundant dismiss should be a safe no-op
      AppNotification.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('Showing new notification replaces previous one safely',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => AppNotification.show(context, '第一条通知'),
                  child: const Text('第1条'),
                ),
                ElevatedButton(
                  onPressed: () => AppNotification.show(context, '第二条通知'),
                  child: const Text('第2条'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('第1条'));
      await tester.pumpAndSettle();
      expect(find.text('第一条通知'), findsOneWidget);

      await tester.tap(find.text('第2条'));
      await tester.pumpAndSettle();
      expect(find.text('第一条通知'), findsNothing);
      expect(find.text('第二条通知'), findsOneWidget);
    });
  });
}
