import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/settings/presentation/widgets/runtime_settings_content.dart';

void main() {
  test(
    'die Runtime-Einstellungen behalten ihre Reiter in fester Reihenfolge',
    () {
      expect(runtimeSettingsTabs.map((tab) => tab.label), [
        'Allgemein',
        'Sprachmodelle',
        'Kommunikation',
        'Verbindungen',
        'Machine Learning',
        'Import/Export',
      ]);
    },
  );
}
