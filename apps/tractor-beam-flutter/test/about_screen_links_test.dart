import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/l10n/generated/app_localizations.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/about_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AboutScreen verifies author Sworld, designer tgw, refactor repo slot, and clickable user profiles',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
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
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{
              'text': clipboardLog.isNotEmpty ? clipboardLog.last : '',
            };
          }
          return null;
        },
      );

      final controller = TractorBeamController.detached();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const AboutScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Author and Designer
      expect(find.text('项目作者'), findsOneWidget);
      expect(find.text('Sworld'), findsAtLeast(1));
      expect(find.text('tgw'), findsOneWidget);

      // 2. Open source links: this flutter client and the official upstream.
      expect(find.text('Flutter 客户端源码 (GitHub)'), findsOneWidget);
      expect(find.text('官方原版项目 (GitHub)'), findsOneWidget);
      // Ensure Releases and Issues are removed
      expect(find.text('版本发布 (Releases)'), findsNothing);
      expect(find.text('问题与建议反馈 (Issues)'), findsNothing);

      // 3. Secondary tap on the upstream row copies the upstream URL.
      final refactorFinder = find.ancestor(
        of: find.text('官方原版项目 (GitHub)'),
        matching: find.byType(GestureDetector),
      );
      expect(refactorFinder, findsWidgets);
      await tester.tap(refactorFinder.first, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(clipboardLog, contains('https://github.com/mcthesw/TractorBeam'));

      // 4. Secondary tap on Author copies GitHub url to clipboard
      final authorFinder = find.ancestor(
        of: find.text('Sworld'),
        matching: find.byType(GestureDetector),
      );
      expect(authorFinder, findsWidgets);
      await tester.tap(authorFinder.first, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(clipboardLog, contains('https://github.com/mcthesw'));

      // 5. Check Acknowledgements and Tester links
      expect(
        find.byTooltip('Summerraim: https://github.com/Summerraim'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('舟飏 (LLIittleFish): https://github.com/LLIittleFish'),
        findsOneWidget,
      );

      // Secondary tap on Summerraim tester tile copies URL
      final summerraimFinder = find.ancestor(
        of: find.text('Summerraim'),
        matching: find.byType(GestureDetector),
      );
      expect(summerraimFinder, findsWidgets);
      await tester.tap(summerraimFinder.first, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(clipboardLog, contains('https://github.com/Summerraim'));

      // Secondary tap on 舟飏 tester tile copies LLIittleFish URL
      final fishFinder = find.ancestor(
        of: find.text('舟飏'),
        matching: find.byType(GestureDetector),
      );
      expect(fishFinder, findsWidgets);
      await tester.tap(fishFinder.first, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(clipboardLog, contains('https://github.com/LLIittleFish'));

      // 6. Non-link tester tiles also have tooltips to prevent truncation obscurity
      expect(find.byTooltip('扣1跟科比打复活赛'), findsOneWidget);
      expect(find.byTooltip('勺子c'), findsOneWidget);
      expect(find.byTooltip('老吴'), findsOneWidget);

      // 7. Link rows have descriptive tooltips
      expect(
        find.byTooltip('GitHub: https://github.com/mcthesw/TractorBeam'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('GitHub: https://github.com/tianguantg/TractorBeam'),
        findsOneWidget,
      );

      // 8. Secondary tap on designer tgw copies designer GitHub URL
      final tgwFinder = find.ancestor(
        of: find.text('tgw'),
        matching: find.byType(GestureDetector),
      );
      expect(tgwFinder, findsWidgets);
      await tester.tap(tgwFinder.first, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(clipboardLog, contains('https://github.com/tianguantg'));

      // 9. Clicking version row copies diagnostic text with clean version (no 'vv')
      final versionFinder = find.ancestor(
        of: find.text('版本标识'),
        matching: find.byType(InkWell),
      );
      expect(versionFinder, findsOneWidget);
      await tester.tap(versionFinder);
      await tester.pumpAndSettle();
      final lastLog = clipboardLog.last;
      expect(lastLog.startsWith('Tractor Beam v'), isTrue);
      expect(lastLog.contains('vv'), isFalse);
    },
  );

  testWidgets(
    'AboutScreen _safeCopy handles Clipboard platform exceptions gracefully',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Mock Clipboard to throw PlatformException
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            throw PlatformException(
              code: 'CLIPBOARD_ERROR',
              message: 'Clipboard is busy',
            );
          }
          return null;
        },
      );

      final controller = TractorBeamController.detached();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: TractorBeamScope(
              notifier: controller,
              child: const AboutScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Secondary tap on designer tgw triggers _safeCopy - handles error notice
      final tgwFinder = find.ancestor(
        of: find.text('tgw'),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(tgwFinder.first, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(find.text('复制到剪贴板失败，请稍后重试'), findsOneWidget);
    },
  );
}
