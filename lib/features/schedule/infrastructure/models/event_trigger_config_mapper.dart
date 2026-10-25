import '../../domain/entities/event_trigger_config.dart';

/// Einzige Stelle, die [EventTriggerConfig] in das Dokumentformat der
/// Runtime überführt und zurückliest.
class EventTriggerConfigMapper {
  const EventTriggerConfigMapper._();

  static Map<String, Object?> toDocument(EventTriggerConfig config) {
    return {
      'source': config.source.name,
      'target': _targetToDocument(config.target),
      'fileKinds': [for (final kind in config.fileKinds) kind.name],
      'filter': config.filter.trim(),
      if (config.webhook case final webhook?)
        'webhook': _webhookToDocument(webhook),
      if (config.params.isNotEmpty) 'params': config.params,
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
      webhook: _webhookFromDocument(data['webhook']),
      params: _paramsFrom(data['params']),
    );
  }

  /// Das Token vergibt die Runtime und wird deshalb nie mitgeschickt. Das
  /// Geheimnis geht nur beim Anlegen hinaus und kommt nie zurück.
  static Map<String, Object?> _webhookToDocument(WebhookConfig webhook) {
    return {
      'verification': switch (webhook.verification) {
        NoWebhookVerification() => {'kind': 'none'},
        HmacWebhookVerification(
          :final header,
          :final algorithm,
          :final encoding,
          :final prefix,
        ) =>
          {
            'kind': 'hmac',
            'header': header.trim(),
            'algorithm': algorithm.name,
            'encoding': encoding.name,
            'prefix': prefix,
          },
      },
      'validationParameter': webhook.validationParameter.trim(),
      if (webhook.secret.isNotEmpty) 'secret': webhook.secret,
    };
  }

  static WebhookConfig? _webhookFromDocument(Object? value) {
    if (value is! Map) return null;
    return WebhookConfig(
      token: value['token'] as String? ?? '',
      verification: _verificationFrom(value['verification']),
      validationParameter: value['validationParameter'] as String? ?? '',
    );
  }

  static WebhookVerification _verificationFrom(Object? value) {
    if (value is! Map || value['kind'] != 'hmac') {
      return WebhookVerification.none;
    }
    return HmacWebhookVerification(
      header: value['header'] as String? ?? '',
      algorithm: WebhookSignatureAlgorithm.values.firstWhere(
        (item) => item.name == value['algorithm'],
        orElse: () => WebhookSignatureAlgorithm.sha256,
      ),
      encoding: WebhookSignatureEncoding.values.firstWhere(
        (item) => item.name == value['encoding'],
        orElse: () => WebhookSignatureEncoding.hex,
      ),
      prefix: value['prefix'] as String? ?? '',
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

  static Map<String, Object?> _paramsFrom(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries) entry.key.toString(): entry.value,
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
