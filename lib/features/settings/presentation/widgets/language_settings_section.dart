import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import 'settings_section.dart';

/// Wechselt die Sprache der Oberfläche. easy_localization speichert die Wahl.
class LanguageSettingsSection extends StatelessWidget {
  const LanguageSettingsSection({super.key});

  static const _german = Locale('de');
  static const _english = Locale('en');

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.language,
      title: LocaleKeys.settings_language_title.tr(),
      description: LocaleKeys.settings_language_description.tr(),
      child: SegmentedButton<Locale>(
        segments: [
          ButtonSegment(
            value: _german,
            label: Text(LocaleKeys.settings_language_de.tr()),
          ),
          ButtonSegment(
            value: _english,
            label: Text(LocaleKeys.settings_language_en.tr()),
          ),
        ],
        selected: {Locale(context.locale.languageCode)},
        onSelectionChanged: (selection) => context.setLocale(selection.single),
      ),
    );
  }
}
