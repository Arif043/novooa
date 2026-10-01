/// Worauf sich die Auswahl des Ziels bezieht — bestimmt, welche Optionen die
/// UI anbietet.
enum EventTargetScope { none, files, channel, mailConnector }

enum EventTriggerSource {
  emailReceived('E-Mail empfangen', EventTargetScope.mailConnector),
  smsMessageReceived('SMS empfangen', EventTargetScope.channel),
  whatsappMessageReceived('WhatsApp-Nachricht', EventTargetScope.channel),
  fileCreated('Datei erstellt', EventTargetScope.files),
  fileVersionCreated('Neue Dateiversion', EventTargetScope.files),
  fileDeleted('Datei gelöscht', EventTargetScope.files),
  webhookReceived('Webhook empfangen', EventTargetScope.none);

  const EventTriggerSource(this.label, this.targetScope);

  final String label;
  final EventTargetScope targetScope;
}

/// Dateikategorien, auf die sich ein Datei-Trigger beschränken lässt.
enum EventFileKind {
  text('Text'),
  image('Bilder'),
  video('Video'),
  audio('Audio'),
  pdf('PDF'),
  spreadsheet('Tabellen'),
  other('Sonstige');

  const EventFileKind(this.label);

  final String label;
}

/// Ziel eines Event-Triggers. Der Name ist nur Anzeigetext für die
/// Trigger-Karte; abgeglichen wird ausschließlich über die ID.
sealed class EventTriggerTarget {
  const EventTriggerTarget();

  static const anywhere = AnywhereTarget();
}

class AnywhereTarget extends EventTriggerTarget {
  const AnywhereTarget();
}

class FolderTarget extends EventTriggerTarget {
  const FolderTarget({
    required this.id,
    required this.name,
    this.includeSubfolders = true,
  });

  final String id;
  final String name;
  final bool includeSubfolders;

  FolderTarget copyWith({bool? includeSubfolders}) {
    return FolderTarget(
      id: id,
      name: name,
      includeSubfolders: includeSubfolders ?? this.includeSubfolders,
    );
  }
}

class FileTarget extends EventTriggerTarget {
  const FileTarget({required this.id, required this.name});

  final String id;
  final String name;
}

class ChannelTarget extends EventTriggerTarget {
  const ChannelTarget({required this.id, required this.name});

  final String id;
  final String name;
}

class ConnectorTarget extends EventTriggerTarget {
  const ConnectorTarget({required this.id, required this.name});

  final String id;
  final String name;
}

class EventTriggerConfig {
  const EventTriggerConfig({
    required this.source,
    this.target = EventTriggerTarget.anywhere,
    this.fileKinds = const {},
    this.filter = '',
  });

  final EventTriggerSource source;
  final EventTriggerTarget target;

  /// Leer heißt: alle Kategorien. Nur für Datei-Quellen relevant.
  final Set<EventFileKind> fileKinds;
  final String filter;

  bool get isValid => true;
}
