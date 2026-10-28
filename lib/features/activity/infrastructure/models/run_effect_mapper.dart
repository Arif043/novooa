import '../../domain/entities/run_effect.dart';

/// Liest die Folgen einer Aktivität; unbekannte Arten (neuere Runtime) und
/// unvollständige Einträge werden übersprungen.
List<RunEffect> runEffectsFrom(Object? value) {
  if (value is! List) return const [];
  return List.unmodifiable(
    value.whereType<Map>().map(_effectFrom).whereType<RunEffect>(),
  );
}

RunEffect? _effectFrom(Map<dynamic, dynamic> data) {
  final source = data['sourceNodeId'];
  if (source is! String) return null;
  final iteration = data['iteration'] is num
      ? (data['iteration'] as num).toInt()
      : null;
  return switch (data['kind']) {
    'fileWritten' => _file(data, source, iteration),
    'messageSent' => _message(data, source, iteration),
    'notificationSent' => _notification(data, source, iteration),
    'recordsChanged' => _records(data, source, iteration),
    'httpRequested' => _http(data, source, iteration),
    'externalAction' => _external(data, source, iteration),
    _ => null,
  };
}

RunEffect? _file(Map<dynamic, dynamic> data, String source, int? iteration) {
  final [fileId, versionId, name] = [
    data['fileId'],
    data['versionId'],
    data['displayName'],
  ];
  if (fileId is! String || versionId is! String || name is! String) {
    return null;
  }
  return FileWrittenEffect(
    sourceNodeId: source,
    iteration: iteration,
    fileId: fileId,
    versionId: versionId,
    displayName: name,
    isNewFile: data['isNewFile'] == true,
  );
}

RunEffect? _message(Map<dynamic, dynamic> data, String source, int? iteration) {
  final channel = MessageChannel.values
      .where((value) => value.name == data['channel'])
      .firstOrNull;
  final recipient = data['recipient'];
  if (channel == null || recipient is! String) return null;
  final subject = data['subject'];
  return MessageSentEffect(
    sourceNodeId: source,
    iteration: iteration,
    channel: channel,
    recipient: recipient,
    subject: subject is String && subject.isNotEmpty ? subject : null,
  );
}

RunEffect? _notification(
  Map<dynamic, dynamic> data,
  String source,
  int? iteration,
) {
  final title = data['title'];
  if (title is! String) return null;
  return NotificationSentEffect(
    sourceNodeId: source,
    iteration: iteration,
    title: title,
  );
}

RunEffect? _records(Map<dynamic, dynamic> data, String source, int? iteration) {
  final operation = RecordOperation.values
      .where((value) => value.name == data['operation'])
      .firstOrNull;
  final collectionId = data['collectionId'];
  final count = data['count'];
  if (operation == null || collectionId is! String || count is! num) {
    return null;
  }
  final documentId = data['documentId'];
  return RecordsChangedEffect(
    sourceNodeId: source,
    iteration: iteration,
    collectionId: collectionId,
    operation: operation,
    count: count.toInt(),
    documentId: documentId is String ? documentId : null,
  );
}

RunEffect? _http(Map<dynamic, dynamic> data, String source, int? iteration) {
  final method = data['method'];
  final status = data['status'];
  if (method is! String || status is! num) return null;
  final host = data['host'];
  return HttpRequestedEffect(
    sourceNodeId: source,
    iteration: iteration,
    method: method,
    status: status.toInt(),
    host: host is String && host.isNotEmpty ? host : null,
  );
}

RunEffect? _external(
  Map<dynamic, dynamic> data,
  String source,
  int? iteration,
) {
  final [plugin, action, label] = [
    data['plugin'],
    data['action'],
    data['label'],
  ];
  if (plugin is! String || action is! String || label is! String) return null;
  return ExternalActionEffect(
    sourceNodeId: source,
    iteration: iteration,
    plugin: plugin,
    action: action,
    label: label,
  );
}
