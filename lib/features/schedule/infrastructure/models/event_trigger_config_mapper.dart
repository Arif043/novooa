import '../../domain/entities/event_trigger_config.dart';

/// Einzige Stelle, die [EventTriggerConfig] in das Dokumentformat von
/// Runtime und Firestore überführt und zurückliest.
class EventTriggerConfigMapper {
  const EventTriggerConfigMapper._();

  static Map<String, Object?> toDocument(EventTriggerConfig config) {
    return {
      'source': config.source.name,
      'target': _targetToDocument(config.target),
      'fileKinds': [for (final kind in config.fileKinds) kind.name],
      'filter': config.filter.trim(),
      if (config.plugin case final plugin?)
        'plugin': {
          'pluginId': plugin.pluginId,
          'type': plugin.type,
          'label': plugin.label,
          'settings': plugin.settings,
        },
    };
  }

  static EventTriggerConfig? fromDocument(Object? value) {
    if (value is! Map || value.isEmpty) return null;
    final data = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    return EventTriggerConfig(
      source: _sourceFrom(data['source']),
      target: _targetFromDocument(data['target']),
      fileKinds: _fileKindsFrom(data['fileKinds']),
      filter: data['filter'] as String? ?? '',
      plugin: _pluginFrom(data['plugin']),
    );
  }

  static PluginTriggerSelection? _pluginFrom(Object? value) {
    if (value is! Map) return null;
    final pluginId = value['pluginId'];
    final type = value['type'];
    if (pluginId is! String || type is! String) return null;
    final settings = value['settings'];
    return PluginTriggerSelection(
      pluginId: pluginId,
      type: type,
      label: value['label'] as String? ?? '$pluginId · $type',
      settings: {
        if (settings is Map)
          for (final entry in settings.entries)
            if (entry.key is String &&
                (entry.value is String ||
                    entry.value is num ||
                    entry.value is bool))
              entry.key as String: entry.value as Object,
      },
    );
  }

  static Map<String, Object?> _targetToDocument(EventTriggerTarget target) {
    return switch (target) {
      AnywhereTarget() => {'kind': 'any'},
      FolderTarget() => {
        'kind': 'folder',
        'id': target.id,
        'label': target.name,
        'includeSubfolders': target.includeSubfolders,
      },
      FileTarget() => {'kind': 'file', 'id': target.id, 'label': target.name},
      ChannelTarget() => {
        'kind': 'channel',
        'id': target.id,
        'label': target.name,
      },
      ConnectorTarget() => {
        'kind': 'connector',
        'id': target.id,
        'label': target.name,
      },
    };
  }

  static EventTriggerTarget _targetFromDocument(Object? value) {
    if (value is! Map) return EventTriggerTarget.anywhere;
    final id = value['id'];
    if (id is! String || id.isEmpty) return EventTriggerTarget.anywhere;
    final name = value['label'] as String? ?? '';
    return switch (value['kind']) {
      'folder' => FolderTarget(
        id: id,
        name: name,
        includeSubfolders: value['includeSubfolders'] as bool? ?? true,
      ),
      'file' => FileTarget(id: id, name: name),
      'channel' => ChannelTarget(id: id, name: name),
      'connector' => ConnectorTarget(id: id, name: name),
      _ => EventTriggerTarget.anywhere,
    };
  }

  static EventTriggerSource _sourceFrom(Object? value) {
    return EventTriggerSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => EventTriggerSource.webhookReceived,
    );
  }

  static Set<EventFileKind> _fileKindsFrom(Object? value) {
    if (value is! List) return const {};
    return {
      for (final kind in EventFileKind.values)
        if (value.contains(kind.name)) kind,
    };
  }
}
