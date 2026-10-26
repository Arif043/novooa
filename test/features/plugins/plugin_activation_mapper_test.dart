import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_activation.dart';
import 'package:syscat2/features/plugins/infrastructure/mappers/plugin_activation_mapper.dart';

void main() {
  test('liest den Zustand je Plugin und übergeht Einträge ohne Kennung', () {
    final plugins = PluginActivationMapper.listFrom({
      'items': [
        {'id': 'shopware', 'enabled': false, 'enabledAt': null},
        {
          'id': 'googleDrive',
          'enabled': true,
          'enabledAt': '2026-10-26T10:00:00.000Z',
        },
        {'enabled': true},
      ],
    });

    expect(plugins, [
      const PluginActivation(id: PluginId('shopware'), isEnabled: false),
      PluginActivation(
        id: const PluginId('googleDrive'),
        isEnabled: true,
        enabledAt: DateTime.utc(2026, 10, 26, 10),
      ),
    ]);
  });

  test('eine Antwort ohne Liste ergibt keine Plugins', () {
    expect(PluginActivationMapper.listFrom({}), isEmpty);
  });
}
