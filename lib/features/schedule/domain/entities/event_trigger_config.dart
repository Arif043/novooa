import '../../../integrations/shopware/domain/shopware_trigger_params.dart';

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
  webhookReceived('Webhook empfangen', EventTargetScope.none),
  shopware('Shopware-Ereignis', EventTargetScope.none);

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

enum WebhookSignatureAlgorithm {
  sha256('SHA-256'),
  sha512('SHA-512');

  const WebhookSignatureAlgorithm(this.label);

  final String label;
}

enum WebhookSignatureEncoding {
  hex('Hex'),
  base64('Base64');

  const WebhookSignatureEncoding(this.label);

  final String label;
}

/// Wie die Runtime prüft, dass ein Aufruf vom erwarteten Absender stammt.
sealed class WebhookVerification {
  const WebhookVerification();

  static const none = NoWebhookVerification();
}

class NoWebhookVerification extends WebhookVerification {
  const NoWebhookVerification();
}

/// Signatur (HMAC) über den Body in einer Kopfzeile, z. B.
/// `X-Signature: sha256=` plus Hex-Wert.
class HmacWebhookVerification extends WebhookVerification {
  const HmacWebhookVerification({
    required this.header,
    this.algorithm = WebhookSignatureAlgorithm.sha256,
    this.encoding = WebhookSignatureEncoding.hex,
    this.prefix = '',
  });

  final String header;
  final WebhookSignatureAlgorithm algorithm;
  final WebhookSignatureEncoding encoding;
  final String prefix;
}

/// Einstellungen eines Webhook-Auslösers. Das Token vergibt die Runtime;
/// [secret] ist nur beim Anlegen gesetzt und wird nie zurückgeliefert.
class WebhookConfig {
  const WebhookConfig({
    this.token = '',
    this.verification = WebhookVerification.none,
    this.validationParameter = '',
    this.secret = '',
  });

  final String token;
  final WebhookVerification verification;

  /// Query-Parameter, den der Absender beim Einrichten zurückerwartet
  /// (Microsoft Graph: `validationToken`). Leer: keine Einrichtungsprüfung.
  final String validationParameter;
  final String secret;

  /// Eine Signaturprüfung braucht Kopfzeile und Geheimnis.
  bool get isComplete => switch (verification) {
    NoWebhookVerification() => true,
    HmacWebhookVerification(:final header) =>
      header.trim().isNotEmpty && secret.isNotEmpty,
  };
}

class EventTriggerConfig {
  const EventTriggerConfig({
    required this.source,
    this.target = EventTriggerTarget.anywhere,
    this.fileKinds = const {},
    this.filter = '',
    this.webhook,
    this.params = const {},
  });

  final EventTriggerSource source;
  final EventTriggerTarget target;

  /// Leer heißt: alle Kategorien. Nur für Datei-Quellen relevant.
  final Set<EventFileKind> fileKinds;
  final String filter;

  /// Nur bei [EventTriggerSource.webhookReceived].
  final WebhookConfig? webhook;

  /// Einstellungen einer Quelle, die ein Plugin mitbringt; bei
  /// [EventTriggerSource.shopware] die [ShopwareTriggerParams].
  final Map<String, Object?> params;

  ShopwareTriggerParams get shopware => ShopwareTriggerParams.fromMap(params);

  bool get isValid =>
      (webhook?.isComplete ?? true) &&
      (source != EventTriggerSource.shopware || shopware.isComplete);
}
