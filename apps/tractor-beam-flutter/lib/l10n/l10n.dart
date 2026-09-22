import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension TractorBeamLocalizations on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('zh', 'CN'));
}
