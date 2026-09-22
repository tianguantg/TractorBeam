import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/locale/ui_locale_store.dart';

void main() {
  test('all Chinese system locales resolve to simplified Chinese', () {
    for (final locale in const [
      Locale('zh', 'CN'),
      Locale('zh', 'TW'),
      Locale('zh', 'HK'),
    ]) {
      expect(UiLocaleStore.systemLocale([locale]), const Locale('zh', 'CN'));
    }
  });

  test('non-Chinese and empty locale lists resolve to English', () {
    expect(
      UiLocaleStore.systemLocale(const [Locale('ja', 'JP')]),
      const Locale('en', 'US'),
    );
    expect(UiLocaleStore.systemLocale(const []), const Locale('en', 'US'));
  });
}
