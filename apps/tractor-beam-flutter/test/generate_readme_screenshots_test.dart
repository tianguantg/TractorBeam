import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/l10n/l10n.dart';
import 'package:tbnet_app/screens/about_screen.dart';
import 'package:tbnet_app/screens/home_screen.dart';
import 'package:tbnet_app/screens/room_screen.dart';
import 'package:tbnet_app/screens/settings_screen.dart';
import 'package:tbnet_app/screens/statistics_screen.dart';
import 'package:tbnet_app/theme/app_theme.dart';

Widget _buildScreen(Widget screen, Locale locale) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Xiaolai',
      scaffoldBackgroundColor: AppColors.canvasBg,
    ),
    home: Scaffold(
      backgroundColor: AppColors.canvasBg,
      body: screen,
    ),
  );
}

Future<void> _precache(WidgetTester tester, Type type, List<String> assets) async {
  final context = tester.element(find.byType(type));
  await tester.runAsync(() async {
    for (final asset in assets) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final fontLoader = FontLoader('Xiaolai')
      ..addFont(rootBundle.load('assets/fonts/Xiaolai-Regular.ttf'));
    await fontLoader.load();
  });

  for (final lang in ['zh', 'en']) {
    final locale = Locale(lang);
    final suffix = lang;

    testWidgets('Capture Home Screen ($lang)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(840, 776));
      await tester.pumpWidget(_buildScreen(const HomeScreen(), locale));
      await _precache(tester, HomeScreen, [
        'assets/icons/ui/home_title.png',
        'assets/images/paper/notice_paper.webp',
        'assets/images/paper/connection_paper.webp',
        'assets/images/paper/connection_lan_torn.webp',
      ]);
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_$suffix.png'),
      );
    });

    testWidgets('Capture Room Screen Joined ($lang)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(840, 776));
      await tester.pumpWidget(_buildScreen(const RoomScreen(previewPartySize: 4), locale));
      await _precache(tester, RoomScreen, [
        'assets/icons/ui/room_title.png',
        'assets/images/paper/room_code_card.webp',
        'assets/images/paper/steam_account_card.webp',
        'assets/images/paper/party_card.webp',
      ]);

      final createButton = find.text(lang == 'zh' ? '新建独立房间' : 'Create Room');
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      final partyTitle = lang == 'zh' ? '联机队伍成员' : 'Party Members';
      final bgFinder = find.byKey(ValueKey('room-panel-background-$partyTitle'));
      if (bgFinder.evaluate().isNotEmpty) {
        final container = tester.widget<Container>(bgFinder);
        final provider = (container.decoration as BoxDecoration).image!.image;
        final context = tester.element(find.byType(RoomScreen));
        await tester.runAsync(() async {
          await precacheImage(provider, context);
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
      }

      await expectLater(
        find.byType(RoomScreen),
        matchesGoldenFile('goldens/room_$suffix.png'),
      );
    });

    testWidgets('Capture Settings Screen ($lang)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(840, 776));
      await tester.pumpWidget(_buildScreen(const SettingsScreen(), locale));
      await _precache(tester, SettingsScreen, [
        'assets/icons/ui/settings_title.png',
        'assets/icons/ui/section_triangle.png',
        'assets/icons/ui/room_dashed_line.png',
        'assets/images/paper/settings_protocol_card.webp',
        'assets/images/paper/settings_mode_card.webp',
        'assets/images/paper/settings_latency_card.webp',
        'assets/images/paper/settings_language_card.webp',
      ]);
      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('goldens/settings_$suffix.png'),
      );
    });

    testWidgets('Capture Statistics Screen ($lang)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(840, 776));
      await tester.pumpWidget(_buildScreen(const StatisticsScreen(), locale));
      await _precache(tester, StatisticsScreen, [
        'assets/icons/ui/statistics_title.png',
        'assets/icons/ui/section_triangle.png',
        'assets/icons/ui/about.png',
        'assets/icons/ui/room_dashed_line.png',
        'assets/icons/ui/refresh_account.png',
        'assets/images/paper/statistics_session_card.webp',
        'assets/images/paper/statistics_counter_card.webp',
        'assets/images/paper/statistics_test_card.webp',
        'assets/images/paper/statistics_hook_card.webp',
      ]);
      await expectLater(
        find.byType(StatisticsScreen),
        matchesGoldenFile('goldens/statistics_$suffix.png'),
      );
    });

    testWidgets('Capture About Screen ($lang)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(840, 776));
      await tester.pumpWidget(_buildScreen(const AboutScreen(), locale));
      await _precache(tester, AboutScreen, [
        'assets/icons/ui/about_title.png',
        'assets/icons/ui/external_link.png',
        'assets/icons/ui/room_dashed_line.png',
        'assets/icons/ui/section_triangle.png',
        'assets/images/paper/about_identity_card.webp',
        'assets/images/paper/about_links_card.webp',
        'assets/images/paper/about_thanks_card.webp',
      ]);
      await expectLater(
        find.byType(AboutScreen),
        matchesGoldenFile('goldens/about_$suffix.png'),
      );
    });
  }
}
