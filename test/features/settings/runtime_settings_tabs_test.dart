import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/settings/presentation/widgets/runtime_settings_content.dart';

void main() {
  test('Admins sehen alle Reiter in fester Reihenfolge', () {
    expect(runtimeSettingsTabs(isAdmin: true).map((tab) => tab.labelKey), [
      LocaleKeys.settings_tabs_general,
      LocaleKeys.settings_tabs_users,
      LocaleKeys.settings_tabs_language_models,
      LocaleKeys.settings_tabs_communication,
      LocaleKeys.settings_tabs_connections,
      LocaleKeys.settings_tabs_machine_learning,
      LocaleKeys.settings_tabs_import_export,
    ]);
  });

  test('Mitglieder sehen nur, was ihr eigenes Konto betrifft', () {
    expect(runtimeSettingsTabs(isAdmin: false).map((tab) => tab.labelKey), [
      LocaleKeys.settings_tabs_general,
      LocaleKeys.settings_tabs_machine_learning,
    ]);
  });
}
