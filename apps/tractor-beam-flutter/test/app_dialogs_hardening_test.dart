import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/bridge/generated/api.dart' as bridge;
import 'package:tbnet_app/l10n/l10n.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/theme/app_theme.dart';
import 'package:tbnet_app/widgets/app_dialogs.dart';

class _FakeLaunchController extends TractorBeamController {
  _FakeLaunchController([bridge.LaunchProgressDto? initial])
      : _launch = initial ??
            bridge.LaunchProgressDto(
              status: bridge.LaunchStatusDto.cancelling,
              generation: BigInt.zero,
              displayText: '正在取消启动...',
              terminal: false,
              success: false,
            ),
        super.detached();

  bridge.LaunchProgressDto _launch;

  @override
  bridge.LaunchProgressDto? get launchProgress => _launch;

  void updateLaunch(bridge.LaunchProgressDto next) {
    _launch = next;
    notifyListeners();
  }

  @override
  bridge.CommandReceipt cancelLaunch() {
    return const bridge.CommandReceipt(accepted: true);
  }
}

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dialog Hardening Tests', () {
    testWidgets(
      'showLanEndpointSelectionDialog with empty list returns null safely',
      (tester) async {
        String? selected = 'dummy';
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selected = await showLanEndpointSelectionDialog(
                    context,
                    const [],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(selected, isNull);
        expect(find.byType(PaperDialogShell), findsNothing);
      },
    );

    testWidgets(
      'showJoinRoomDialog validates empty input and normalizes lowercase to uppercase',
      (tester) async {
        String? result;
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showJoinRoomDialog(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // 1. Try to submit empty input
        await tester.tap(find.text('加入'));
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(find.byType(PaperDialogShell), findsOneWidget);

        // 2. Try submitting only whitespace
        await tester.enterText(find.byType(TextField), '   ');
        await tester.pumpAndSettle();
        await tester.tap(find.text('加入'));
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(find.byType(PaperDialogShell), findsOneWidget);

        // 3. Enter lowercase room code with spaces
        await tester.enterText(find.byType(TextField), '  tb-room-888  ');
        await tester.pumpAndSettle();
        await tester.tap(find.text('加入'));
        await tester.pumpAndSettle();

        expect(result, 'TB-ROOM-888');
        expect(find.byType(PaperDialogShell), findsNothing);
      },
    );

    testWidgets(
      'showManualSteamAccountDialog autofills from history and restricts steamId64 to digits and 17 length',
      (tester) async {
        SteamAccountData? result;
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showManualSteamAccountDialog(
                    context,
                    initialUsername: '',
                    initialSteamId64: '',
                    manualAccounts: [
                      const SteamAccountData(
                        username: 'PlayerAlpha',
                        steamId64: '76561198000000001',
                      ),
                    ],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // 1. Test non-digits and length limit > 17 on empty textfield
        await tester.enterText(
          find.byType(TextField).first,
          'abc12345678901234567890',
        );
        await tester.pumpAndSettle();
        final updatedIdField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(updatedIdField.controller?.text, '12345678901234567');

        // 2. Tap on historical account item to autofill
        expect(find.text('PlayerAlpha'), findsOneWidget);
        expect(find.text('ID64: 76561198000000001'), findsOneWidget);

        await tester.tap(find.text('PlayerAlpha'));
        await tester.pumpAndSettle();

        // Verify text fields were autofilled
        final idField = tester.widget<TextField>(find.byType(TextField).first);
        expect(idField.controller?.text, '76561198000000001');
        final nameField = tester.widget<TextField>(find.byType(TextField).last);
        expect(nameField.controller?.text, 'PlayerAlpha');

        // Save
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.steamId64, '76561198000000001');
        expect(result!.username, 'PlayerAlpha');
      },
    );

    testWidgets(
      'showAddRelayDialog cleans protocol prefixes and extracts port automatically',
      (tester) async {
        AddRelayData? result;
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAddRelayDialog(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        // Name
        await tester.enterText(fields.at(0), 'Custom Node');
        // Address with https scheme and custom port and trailing slash
        await tester.enterText(fields.at(1), 'https://node.example.org:3128/');
        await tester.pumpAndSettle();

        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.name, 'Custom Node');
        expect(result!.address, 'node.example.org');
        expect(result!.port, '3128');
      },
    );

    testWidgets(
      'showEditRelayDialog cleans tcp/udp protocol prefixes and extracts port',
      (tester) async {
        EditRelayResult? result;
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showEditRelayDialog(
                    context,
                    initialName: 'Existing Node',
                    initialAddress: '192.0.2.4',
                    initialPort: '25910',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(1), 'tcp://relay.mycloud.cn:8088');
        await tester.pumpAndSettle();

        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.action, EditRelayAction.save);
        expect(result!.data!.address, 'relay.mycloud.cn');
        expect(result!.data!.port, '8088');
      },
    );

    testWidgets(
      'showCreateLanRoomDialog prevents selecting more than 8 network adapters',
      (tester) async {
        final adapters = List.generate(
          10,
          (i) => LanAdapterInfo(
            'Network Card $i',
            '192.168.1.${10 + i}',
            null,
            false,
          ),
        );

        List<LanAdapterInfo>? selected;
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selected = await showCreateLanRoomDialog(
                    context,
                    adapters: adapters,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // 1st adapter is selected by fallback because none recommended
        expect(find.text('已选择：1/8'), findsOneWidget);

        // Select up to 8 cards (cards 1..7)
        final scrollable = find.byType(Scrollable).last;
        for (var i = 1; i < 8; i++) {
          final itemFinder = find.text('Network Card $i');
          await tester.scrollUntilVisible(
            itemFinder,
            60,
            scrollable: scrollable,
          );
          await tester.tap(itemFinder);
          await tester.pumpAndSettle();
        }
        expect(find.text('已选择：8/8'), findsOneWidget);

        // Attempting to select 9th adapter (index 8)
        final card8Finder = find.text('Network Card 8');
        await tester.scrollUntilVisible(
          card8Finder,
          60,
          scrollable: scrollable,
        );
        await tester.tap(card8Finder);
        await tester.pumpAndSettle();

        // Count should remain 8
        expect(find.text('已选择：8/8'), findsOneWidget);

        // Click create button
        await tester.tap(find.text('创建'));
        await tester.pumpAndSettle();

        expect(selected, isNotNull);
        expect(selected!.length, 8);
      },
    );

    testWidgets(
      'showCloseApplicationDialog offers Cancel button when hasTray is true',
      (tester) async {
        CloseApplicationChoice? result = CloseApplicationChoice.exit;
        await tester.pumpWidget(
          _wrapWithApp(
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

        expect(find.text('隐藏到托盘'), findsOneWidget);
        expect(find.text('完全退出'), findsOneWidget);
        expect(find.text('取消'), findsOneWidget);

        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();

        expect(result, isNull);
        expect(find.byType(PaperDialogShell), findsNothing);
      },
    );

    testWidgets(
      'showDeleteRelayConfirmDialog supports Enter to confirm and Escape to cancel',
      (tester) async {
        bool? confirmed;
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmed = await showDeleteRelayConfirmDialog(
                    context,
                    relayName: 'Target Relay Node',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        // 1. Escape key cancels
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('删除 Relay 节点'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(confirmed, isFalse);
        expect(find.byType(PaperDialogShell), findsNothing);

        // 2. Enter key confirms
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('删除 Relay 节点'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(confirmed, isTrue);
        expect(find.byType(PaperDialogShell), findsNothing);
      },
    );

    testWidgets(
      'showLaunchGameDialog shows close button and allows pop after cancelling timeout',
      (tester) async {
        final controller = _FakeLaunchController();
        await tester.pumpWidget(
          _wrapWithApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showLaunchGameDialog(context, controller: controller);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Initially in cancelling state, only "正在取消…" is shown
        expect(find.text('正在取消启动'), findsOneWidget);
        expect(find.text('正在取消…'), findsOneWidget);
        expect(find.text('关闭'), findsNothing);

        // Advance timer past the 5-second fallback timeout
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();

        // Now "关闭" (Close) button appears
        expect(find.text('关闭'), findsOneWidget);

        // Tapping Close successfully pops the dialog
        await tester.tap(find.text('关闭'));
        await tester.pumpAndSettle();

        expect(find.byType(PaperDialogShell), findsNothing);
      },
    );

    testWidgets(
      'showLaunchGameDialog renders bottom text and steps in English when in English locale',
      (tester) async {
        final controller = _FakeLaunchController(
          bridge.LaunchProgressDto(
            status: bridge.LaunchStatusDto.waitingForGame,
            generation: BigInt.one,
            displayText: '正在等待游戏进程',
            terminal: false,
            success: false,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showLaunchGameDialog(context, controller: controller);
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Title and steps in English
        expect(find.text('Launching Game'), findsOneWidget);
        expect(find.text('Waiting for game process'), findsOneWidget);
        expect(find.text('Injecting TractorBeam Hook'), findsOneWidget);

        // Bottom text is in English (not Chinese)
        expect(find.text('Waiting for game process...'), findsOneWidget);
        expect(find.text('Cancel Launch'), findsOneWidget);

        // Update to injecting Hook
        controller.updateLaunch(
          bridge.LaunchProgressDto(
            status: bridge.LaunchStatusDto.injecting,
            generation: BigInt.one,
            displayText: '已发现游戏，正在注入 Hook',
            terminal: false,
            success: false,
          ),
        );
        await tester.pump();
        expect(find.text('Game detected, injecting Hook...'), findsOneWidget);

        // Update to ready
        controller.updateLaunch(
          bridge.LaunchProgressDto(
            status: bridge.LaunchStatusDto.ready,
            generation: BigInt.one,
            displayText: '游戏与 Hook 已就绪',
            terminal: true,
            success: true,
          ),
        );
        await tester.pump();
        expect(find.text('Game and Hook ready'), findsWidgets);
      },
    );
  });
}
