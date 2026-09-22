import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/screens/settings_screen.dart';
import 'package:tbnet_app/screens/statistics_screen.dart';
import 'package:tbnet_app/screens/log_screen.dart';
import 'package:tbnet_app/screens/about_screen.dart';
import 'package:tbnet_app/screens/home_screen.dart';
import 'package:tbnet_app/screens/room_screen.dart';
import 'package:tbnet_app/theme/app_theme.dart';
import 'package:tbnet_app/widgets/paper_image.dart';

void main() {
  testWidgets('capture home screen', (tester) async {
    final fontLoader = FontLoader('Xiaolai')
      ..addFont(rootBundle.load('assets/fonts/Xiaolai-Regular.ttf'));
    await fontLoader.load();
    await tester.binding.setSurfaceSize(const Size(840, 776));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Xiaolai'),
        home: const Scaffold(
          backgroundColor: AppColors.canvasBg,
          body: HomeScreen(),
        ),
      ),
    );
    final context = tester.element(find.byType(HomeScreen));
    await tester.runAsync(() async {
      for (final asset in <String>[
        'assets/images/paper/notice_paper.webp',
        'assets/images/paper/connection_paper.webp',
        'assets/images/paper/connection_lan_torn.webp',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen.png'),
    );
    await tester.tap(find.text('局域网直连'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
        TbPaperImageScope.providerFor(
          asset: 'assets/images/paper/connection_lan_torn.webp',
          pixelRatio: 1,
          logicalWidth: 792,
          logicalHeight: 237,
        ),
        context,
      );
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_lan_screen.png'),
    );
  });

  testWidgets('capture room screen', (tester) async {
    final fontLoader = FontLoader('Xiaolai')
      ..addFont(rootBundle.load('assets/fonts/Xiaolai-Regular.ttf'));
    await fontLoader.load();
    await tester.binding.setSurfaceSize(const Size(840, 776));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Xiaolai'),
        home: const Scaffold(
          backgroundColor: AppColors.canvasBg,
          body: RoomScreen(),
        ),
      ),
    );
    final context = tester.element(find.byType(RoomScreen));
    await tester.runAsync(() async {
      for (final asset in <String>[
        'assets/icons/ui/room_title.png',
        'assets/images/paper/room_code_card.webp',
        'assets/images/paper/steam_account_card.webp',
        'assets/images/paper/party_card.webp',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RoomScreen),
      matchesGoldenFile('goldens/room_screen.png'),
    );
  });

  testWidgets('capture settings screen', (tester) async {
    final fontLoader = FontLoader('Xiaolai')
      ..addFont(rootBundle.load('assets/fonts/Xiaolai-Regular.ttf'));
    await fontLoader.load();
    await tester.binding.setSurfaceSize(const Size(840, 776));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Xiaolai',
          scaffoldBackgroundColor: AppColors.canvasBg,
        ),
        home: const Scaffold(
          backgroundColor: AppColors.canvasBg,
          body: SettingsScreen(),
        ),
      ),
    );
    final context = tester.element(find.byType(SettingsScreen));
    await tester.runAsync(() async {
      for (final asset in <String>[
        'assets/icons/ui/settings_title.png',
        'assets/icons/ui/section_triangle.png',
        'assets/icons/ui/room_dashed_line.png',
        'assets/images/paper/settings_protocol_card.webp',
        'assets/images/paper/settings_mode_card.webp',
        'assets/images/paper/settings_latency_card.webp',
        'assets/images/paper/settings_language_card.webp',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
  });

  testWidgets('capture statistics screen', (tester) async {
    final fontLoader = FontLoader('Xiaolai')
      ..addFont(rootBundle.load('assets/fonts/Xiaolai-Regular.ttf'));
    await fontLoader.load();
    await tester.binding.setSurfaceSize(const Size(840, 776));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Xiaolai',
          scaffoldBackgroundColor: AppColors.canvasBg,
        ),
        home: const Scaffold(
          backgroundColor: AppColors.canvasBg,
          body: StatisticsScreen(),
        ),
      ),
    );
    final context = tester.element(find.byType(StatisticsScreen));
    await tester.runAsync(() async {
      for (final asset in <String>[
        'assets/icons/ui/statistics_title.png',
        'assets/icons/ui/section_triangle.png',
        'assets/icons/ui/about.png',
        'assets/icons/ui/room_dashed_line.png',
        'assets/icons/ui/refresh_account.png',
        'assets/images/paper/statistics_session_card.webp',
        'assets/images/paper/statistics_counter_card.webp',
        'assets/images/paper/statistics_test_card.webp',
        'assets/images/paper/statistics_hook_card.webp',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(StatisticsScreen),
      matchesGoldenFile('goldens/statistics_screen.png'),
    );
  });

  testWidgets('capture log screen', (tester) async {
    final fontLoader = FontLoader('Xiaolai')
      ..addFont(rootBundle.load('assets/fonts/Xiaolai-Regular.ttf'));
    await fontLoader.load();
    await tester.binding.setSurfaceSize(const Size(840, 776));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Xiaolai'),
        home: const Scaffold(
          backgroundColor: AppColors.canvasBg,
          body: LogScreen(),
        ),
      ),
    );
    final context = tester.element(find.byType(LogScreen));
    await tester.runAsync(() async {
      for (final asset in <String>[
        'assets/icons/ui/log_title.png',
        'assets/icons/ui/export_diagnostics.png',
        'assets/icons/ui/locate_folder.png',
        'assets/icons/ui/clear_logs.png',
        'assets/images/paper/log_toolbar_card.webp',
        'assets/images/paper/log_console_card_dark.webp',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LogScreen),
      matchesGoldenFile('goldens/log_screen.png'),
    );
  });

  testWidgets('capture about screen', (tester) async {
    final fontLoader = FontLoader('Xiaolai')
      ..addFont(rootBundle.load('assets/fonts/Xiaolai-Regular.ttf'));
    await fontLoader.load();
    await tester.binding.setSurfaceSize(const Size(840, 776));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Xiaolai'),
        home: const Scaffold(
          backgroundColor: AppColors.canvasBg,
          body: AboutScreen(),
        ),
      ),
    );
    final context = tester.element(find.byType(AboutScreen));
    await tester.runAsync(() async {
      for (final asset in <String>[
        'assets/icons/ui/about_title.png',
        'assets/icons/ui/external_link.png',
        'assets/icons/ui/room_dashed_line.png',
        'assets/icons/ui/section_triangle.png',
        'assets/images/paper/about_identity_card.webp',
        'assets/images/paper/about_links_card.webp',
        'assets/images/paper/about_thanks_card.webp',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AboutScreen),
      matchesGoldenFile('goldens/about_screen.png'),
    );
  });
}
