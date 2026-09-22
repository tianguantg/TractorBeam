import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/l10n/generated/app_localizations.dart';
import 'package:tbnet_app/main.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/screens/about_screen.dart';
import 'package:tbnet_app/screens/log_screen.dart';
import 'package:tbnet_app/screens/statistics_screen.dart';
import 'package:tbnet_app/theme/app_theme.dart';
import 'package:tbnet_app/widgets/app_dialogs.dart';
import 'package:tbnet_app/widgets/sidebar.dart';

Finder _inBoard(String boardKey, Finder matching) =>
    find.descendant(of: find.byKey(ValueKey(boardKey)), matching: matching);

Widget _wrapEnglish(Widget child, [TractorBeamController? controller]) {
  final content = controller != null
      ? TractorBeamScope(notifier: controller, child: child)
      : child;
  return MaterialApp(
    locale: const Locale('en', 'US'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Xiaolai',
      scaffoldBackgroundColor: AppColors.canvasBg,
    ),
    home: Scaffold(body: content),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('English localization smoke tests', () {
    testWidgets(
      'TbNetApp boots with en_US and renders English labels without overflow',
      (tester) async {
        await tester.pumpWidget(
          const TbNetApp(initialLocale: Locale('en', 'US')),
        );
        await tester.pumpAndSettle();

        // Check sidebar navigation labels
        expect(find.text('Home'), findsWidgets);
        expect(find.text('Room'), findsWidgets);
        expect(find.text('Settings'), findsWidgets);
        expect(find.text('Stats'), findsWidgets);
        expect(find.text('Logs'), findsWidgets);
        expect(find.text('About'), findsWidgets);

        // Verify sidebar navigation labels in PaperSidebar do not wrap into multiple lines
        for (final label in ['Home', 'Room', 'Settings', 'Stats', 'Logs', 'About']) {
          final textWidget = tester.widget<Text>(
            find.descendant(
              of: find.byType(PaperSidebar).first,
              matching: find.text(label),
            ),
          );
          expect(textWidget.maxLines, 1);
          expect(textWidget.softWrap, isFalse);
        }

        // Check home screen content
        expect(find.text('Online Play Guide'), findsOneWidget);
        expect(find.text('Connection Mode'), findsOneWidget);

        // Check status bar
        expect(find.text('Hook Not connected'), findsOneWidget);
        expect(find.text('Idle'), findsOneWidget);
      },
    );

    testWidgets(
      'Language option in Settings switches between English and Chinese smoothly',
      (tester) async {
        await tester.pumpWidget(
          const TbNetApp(initialLocale: Locale('en', 'US')),
        );
        await tester.pumpAndSettle();

        // Navigate to settings using the sidebar in home-page-board
        final settingsBtn = _inBoard('home-page-board', find.text('Settings'));
        expect(settingsBtn, findsOneWidget);
        await tester.tap(settingsBtn);
        await tester.pumpAndSettle();

        // Verify English settings panels
        expect(find.text('Transport Protocol'), findsOneWidget);
        expect(find.text('Work Mode'), findsOneWidget);
        expect(find.text('Input Delay'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Restore Defaults'), findsOneWidget);

        // Switch to Chinese via settings language option
        final zhOption = find.text('简体中文');
        expect(zhOption, findsOneWidget);
        await tester.tap(zhOption);
        await tester.pumpAndSettle();

        // Verify Chinese labels are active
        expect(find.text('传输协议'), findsOneWidget);
        expect(find.text('工作模式'), findsOneWidget);
        expect(find.text('输入延迟'), findsOneWidget);
        expect(find.text('界面语言'), findsOneWidget);
        expect(find.text('恢复默认设置'), findsOneWidget);

        // Switch back to English
        final enOption = find.text('English');
        expect(enOption, findsOneWidget);
        await tester.tap(enOption);
        await tester.pumpAndSettle();

        expect(find.text('Transport Protocol'), findsOneWidget);
        expect(find.text('Work Mode'), findsOneWidget);
        expect(find.text('Language'), findsOneWidget);
      },
    );

    testWidgets('Add Relay Dialog renders English and validates', (tester) async {
      await tester.pumpWidget(
        _wrapEnglish(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddRelayDialog(context),
              child: const Text('Open Add Relay'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Add Relay'));
      await tester.pumpAndSettle();

      expect(find.text('Add Relay Node'), findsOneWidget);
      expect(find.text('Node Name'), findsOneWidget);
      expect(find.text('Relay Address'), findsOneWidget);
      expect(find.text('Port'), findsOneWidget);
      expect(find.text('Supported Transports'), findsOneWidget);
      expect(find.text('Default Transport'), findsOneWidget);

      // Trigger empty validation
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a node name'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Test US Node');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a relay address'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Add Relay Node'), findsNothing);
    });

    testWidgets('Manual Steam Account Dialog renders English and validates', (tester) async {
      await tester.pumpWidget(
        _wrapEnglish(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showManualSteamAccountDialog(
                context,
                initialUsername: '',
                initialSteamId64: '',
              ),
              child: const Text('Open Steam Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Steam Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Manual Steam Account'), findsOneWidget);
      expect(find.text('SteamID64'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('SteamID64 cannot be empty'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '12345');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('SteamID64 must be 17 digits and non-zero'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Manual Steam Account'), findsNothing);
    });

    testWidgets('Close Application Dialog renders English without overflow', (tester) async {
      CloseApplicationChoice? closeChoice;
      await tester.pumpWidget(
        _wrapEnglish(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                closeChoice = await showCloseApplicationDialog(
                  context,
                  isInRoom: false,
                  isSessionRunning: false,
                  hasTray: true,
                );
              },
              child: const Text('Open Close Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Close Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Close Tractor Beam'), findsOneWidget);
      expect(find.text('Hide to Tray'), findsOneWidget);
      expect(find.text('Exit Completely'), findsOneWidget);

      await tester.tap(find.text('Hide to Tray'));
      await tester.pumpAndSettle();
      expect(closeChoice, CloseApplicationChoice.hideToTray);
    });

    testWidgets(
      'Application operates without RenderFlex overflow at minimum window size (640x420)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(640, 420));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const TbNetApp(initialLocale: Locale('en', 'US')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsWidgets);
        expect(tester.takeException(), isNull);

        // Switch to Room tab
        final roomBtn = _inBoard('home-page-board', find.text('Room'));
        expect(roomBtn, findsOneWidget);
        await tester.tap(roomBtn);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Switch to Settings tab
        final settingsBtn = _inBoard('room-page-board', find.text('Settings'));
        expect(settingsBtn, findsOneWidget);
        await tester.tap(settingsBtn);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('About screen renders English content without overflow', (tester) async {
      final controller = TractorBeamController.detached();
      await tester.pumpWidget(_wrapEnglish(const AboutScreen(), controller));
      await tester.pumpAndSettle();

      expect(
        find.text('Lightweight online play bridge built for The Binding of Isaac: Repentance+'),
        findsOneWidget,
      );
      expect(find.text('Project Author'), findsOneWidget);
      expect(find.text('Open Source & Links'), findsOneWidget);
      expect(find.text('Acknowledgements'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Statistics screen renders English panels without overflow', (tester) async {
      final controller = TractorBeamController.detached();
      await tester.pumpWidget(_wrapEnglish(const StatisticsScreen(), controller));
      await tester.pumpAndSettle();

      expect(find.text('Session Quality'), findsOneWidget);
      expect(find.text('Counters'), findsOneWidget);
      expect(find.text('Connection Test'), findsOneWidget);
      expect(find.text('Hook IPC Status'), findsOneWidget);
      expect(find.text('Start Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Log screen renders English filter levels and actions without overflow', (tester) async {
      final controller = TractorBeamController.detached();
      await tester.pumpWidget(_wrapEnglish(const LogScreen(), controller));
      await tester.pumpAndSettle();

      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('TRACE'), findsOneWidget);
      expect(find.text('DEBUG'), findsOneWidget);
      expect(find.text('INFO'), findsOneWidget);
      expect(find.text('WARN'), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('Export Bundle'), findsOneWidget);
      expect(find.text('Open Folder'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
