import '../../domain/entities/installed_plugin.dart';
import '../../domain/entities/plugin_catalog_entry.dart';
import '../../domain/entities/plugin_manifest.dart';
import '../../domain/entities/plugin_settings.dart';

Map<String, Object?> _record(Object? value, String what) {
  if (value is! Map) throw FormatException('$what ist ungültig.');
  return value.cast<String, Object?>();
}

List<Object?> _list(Object? value) => value is List ? value : const [];

String _string(Object? value) => value is String ? value : '';

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

PluginField _fieldFromJson(Object? value) {
  final json = _record(value, 'Feld');
  return PluginField(
    key: _string(json['key']),
    label: _string(json['label']),
    kind: PluginFieldKind.parse(json['kind'] as String?),
    description: _optionalString(json['description']),
    required: json['required'] == true,
    secret: json['secret'] == true,
    options: [
      for (final option in _list(json['options']))
        PluginFieldOption(
          value: _string(_record(option, 'Option')['value']),
          label: _string(_record(option, 'Option')['label']),
        ),
    ],
    defaultValue: switch (json['defaultValue']) {
      final String value => value,
      final num value => value,
      final bool value => value,
      _ => null,
    },
  );
}

List<PluginField> _fields(Object? value) =>
    _list(value).map(_fieldFromJson).toList(growable: false);

PluginManifest manifestFromJson(Object? value) {
  final json = _record(value, 'Plugin');
  return PluginManifest(
    id: _string(json['id']),
    version: _string(json['version']),
    name: _string(json['name']),
    description: _string(json['description']),
    primitives: [
      for (final item in _list(json['primitives']))
        _primitiveFromJson(_record(item, 'Baustein')),
    ],
    triggers: [
      for (final item in _list(json['triggers']))
        _triggerFromJson(_record(item, 'Trigger')),
    ],
    settingsPanels: [
      for (final item in _list(json['settingsPanels']))
        _panelFromJson(_record(item, 'Panel')),
    ],
  );
}

PluginPrimitiveDefinition _primitiveFromJson(Map<String, Object?> json) =>
    PluginPrimitiveDefinition(
      type: _string(json['type']),
      label: _string(json['label']),
      description: _string(json['description']),
      group: _optionalString(json['group']),
      icon: _optionalString(json['icon']),
      settings: _fields(json['settings']),
      outputs: [
        for (final output in _list(json['outputs']))
          PluginOutputDefinition(
            name: _string(_record(output, 'Ausgabe')['name']),
            label: _string(_record(output, 'Ausgabe')['label']),
            type: PluginOutputType.parse(
              _record(output, 'Ausgabe')['type'] as String?,
            ),
          ),
      ],
    );

PluginTriggerDefinition _triggerFromJson(Map<String, Object?> json) =>
    PluginTriggerDefinition(
      type: _string(json['type']),
      label: _string(json['label']),
      description: _string(json['description']),
      settings: _fields(json['settings']),
    );

PluginSettingsPanel _panelFromJson(Map<String, Object?> json) =>
    PluginSettingsPanel(
      id: _string(json['id']),
      title: _string(json['title']),
      description: _optionalString(json['description']),
      icon: _optionalString(json['icon']),
      fields: _fields(json['fields']),
    );

InstalledPlugin pluginFromJson(Object? value) {
  final json = _record(value, 'Plugin');
  return InstalledPlugin(manifest: manifestFromJson(json['manifest']));
}

List<InstalledPlugin> pluginsFromJson(Map<String, Object?> json) {
  final items = json['items'];
  if (items is! List) {
    throw const FormatException('Plugins konnten nicht gelesen werden.');
  }
  return items.map(pluginFromJson).toList(growable: false);
}

List<PluginCatalogEntry> catalogFromJson(Map<String, Object?> json) {
  final items = json['items'];
  if (items is! List) {
    throw const FormatException('Der Katalog konnte nicht gelesen werden.');
  }
  return [
    for (final item in items)
      PluginCatalogEntry(
        id: _string(_record(item, 'Eintrag')['id']),
        name: _string(_record(item, 'Eintrag')['name']),
        description: _string(_record(item, 'Eintrag')['description']),
        version: _string(_record(item, 'Eintrag')['version']),
        sizeBytes: (_record(item, 'Eintrag')['sizeBytes'] as num?)?.toInt() ?? 0,
      ),
  ];
}

PluginInstallPreview previewFromJson(Map<String, Object?> json) {
  final installId = json['installId'];
  if (installId is! String) {
    throw const FormatException('Die Vorschau ist ungültig.');
  }
  return PluginInstallPreview(
    installId: installId,
    manifest: manifestFromJson(json['manifest']),
    installedVersion: _optionalString(json['installedVersion']),
  );
}

PluginSettings settingsFromJson(Map<String, Object?> json) {
  final values = _record(json['values'] ?? const <String, Object?>{}, 'Werte');
  return PluginSettings(
    values: {
      for (final entry in values.entries)
        if (entry.value is String || entry.value is num || entry.value is bool)
          entry.key: entry.value!,
    },
    secretsSet: _list(json['secretsSet']).whereType<String>().toSet(),
  );
}
