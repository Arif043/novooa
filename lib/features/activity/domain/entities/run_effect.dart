/// Was ein Baustein über seine Werte hinaus bewirkt hat. [sourceNodeId] ist
/// der verursachende Baustein, auch innerhalb von Zweigen und Schleifen;
/// [iteration] die Runde der umschließenden Schleife (ab 0).
sealed class RunEffect {
  const RunEffect({required this.sourceNodeId, this.iteration});

  final String sourceNodeId;
  final int? iteration;
}

final class FileWrittenEffect extends RunEffect {
  const FileWrittenEffect({
    required super.sourceNodeId,
    super.iteration,
    required this.fileId,
    required this.versionId,
    required this.displayName,
    required this.isNewFile,
  });

  final String fileId;
  final String versionId;
  final String displayName;
  final bool isNewFile;
}

enum MessageChannel { email, whatsapp, sms }

final class MessageSentEffect extends RunEffect {
  const MessageSentEffect({
    required super.sourceNodeId,
    super.iteration,
    required this.channel,
    required this.recipient,
    this.subject,
  });

  final MessageChannel channel;
  final String recipient;
  final String? subject;
}

final class NotificationSentEffect extends RunEffect {
  const NotificationSentEffect({
    required super.sourceNodeId,
    super.iteration,
    required this.title,
  });

  final String title;
}

enum RecordOperation { created, updated, deleted }

final class RecordsChangedEffect extends RunEffect {
  const RecordsChangedEffect({
    required super.sourceNodeId,
    super.iteration,
    required this.collectionId,
    required this.operation,
    required this.count,
    this.documentId,
  });

  final String collectionId;
  final RecordOperation operation;
  final int count;
  final String? documentId;
}

final class HttpRequestedEffect extends RunEffect {
  const HttpRequestedEffect({
    required super.sourceNodeId,
    super.iteration,
    required this.method,
    required this.status,
    this.host,
  });

  final String method;
  final int status;

  /// Fehlt bei Anfragen über eine gespeicherte Verbindung ohne volle Adresse.
  final String? host;
}

final class ExternalActionEffect extends RunEffect {
  const ExternalActionEffect({
    required super.sourceNodeId,
    super.iteration,
    required this.plugin,
    required this.action,
    required this.label,
  });

  final String plugin;
  final String action;
  final String label;
}
