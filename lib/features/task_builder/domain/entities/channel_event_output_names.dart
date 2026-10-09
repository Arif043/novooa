part of 'node_config.dart';

/// Die fachlichen Werte, die „Nachricht lesen“ bereitstellt.
enum ChannelEventOutputField { sender, subject, message, receivedAt }

/// Graph-weit eindeutige, flache Namen der Werte von „Nachricht lesen“ —
/// wie die Felder einer strukturierten Prompt-Ausgabe, erreichbar direkt per
/// `{{name}}` statt über einen Knotennamen.
class ChannelEventOutputNames extends Equatable {
  const ChannelEventOutputNames({
    this.sender = 'sender',
    this.subject = 'subject',
    this.message = 'message',
    this.receivedAt = 'receivedAt',
  });

  final String sender;
  final String subject;
  final String message;
  final String receivedAt;

  String nameOf(ChannelEventOutputField field) {
    return switch (field) {
      ChannelEventOutputField.sender => sender,
      ChannelEventOutputField.subject => subject,
      ChannelEventOutputField.message => message,
      ChannelEventOutputField.receivedAt => receivedAt,
    };
  }

  ChannelEventOutputNames rename(ChannelEventOutputField field, String name) {
    return ChannelEventOutputNames(
      sender: field == ChannelEventOutputField.sender ? name : sender,
      subject: field == ChannelEventOutputField.subject ? name : subject,
      message: field == ChannelEventOutputField.message ? name : message,
      receivedAt: field == ChannelEventOutputField.receivedAt
          ? name
          : receivedAt,
    );
  }

  @override
  List<Object?> get props => [sender, subject, message, receivedAt];
}
