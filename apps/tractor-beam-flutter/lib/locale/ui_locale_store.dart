import 'dart:convert';
import 'dart:io';
import 'dart:ui';

class UiLocaleStore {
  static File? get _file {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.trim().isEmpty) return null;
    return File('$localAppData\\TractorBeamFlutter\\ui_preferences.json');
  }

  static Locale systemLocale(Iterable<Locale> locales) {
    final locale = locales.isEmpty ? const Locale('en', 'US') : locales.first;
    return locale.languageCode.toLowerCase() == 'zh'
        ? const Locale('zh', 'CN')
        : const Locale('en', 'US');
  }

  static Future<Locale> loadAndRemember(Iterable<Locale> systemLocales) async {
    final fallback = systemLocale(systemLocales);
    final file = _file;
    if (file != null && await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          final language = decoded['language'];
          if (language == 'zh') return const Locale('zh', 'CN');
          if (language == 'en') return const Locale('en', 'US');
        }
      } catch (_) {
        // Invalid optional UI state falls back to the system language.
      }
    }
    await save(fallback);
    return fallback;
  }

  static Future<void> save(Locale locale) async {
    final file = _file;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode({'language': locale.languageCode == 'zh' ? 'zh' : 'en'}),
        flush: true,
      );
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
    } catch (_) {
      // Locale persistence must never prevent startup or a live switch.
    }
  }
}
