import '../../../../core/network/workspace_api_client.dart';
import '../../../../core/network/workspace_realtime_channel.dart';
import '../../domain/entities/communication_channel.dart';
import '../../domain/entities/create_communication_channel_input.dart';
import '../../domain/entities/send_channel_message_input.dart';
import '../../domain/repositories/communication_channel_repository.dart';
import '../models/mail_connector_model.dart';

/// Kommunikationskanäle der lokalen Runtime. Hier gibt es ausschließlich
/// E-Mail-Postfächer (Microsoft Outlook): Die Runtime kennt sie über das Cloud
/// Relay und liefert sie unter `GET /v1/mail-connectors`. WhatsApp und SMS
/// laufen über Team-Konten in der Cloud und sind in dieser Variante nicht
/// verfügbar.
class LocalCommunicationChannelRepository
    implements CommunicationChannelRepository {
  const LocalCommunicationChannelRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  /// Die Postfächer liegen in der Cloud, die Runtime hält sie nur zwischen.
  /// Ändert die Cloud etwas, leert die Runtime ihren Cache und meldet das auf
  /// diesem Kanal; erst dann wird neu geladen — es gibt kein Nachfragen im
  /// Takt.
  @override
  Stream<List<CommunicationChannel>> watchChannels() =>
      watchWorkspaceChannel('mail-connectors', _load, _channel);

  @override
  Future<String> beginMicrosoftConnection() async {
    final response = await _client.post(
      '/v1/mail-connectors/microsoft/authorization',
      const {},
    );
    final url = response['authorizationUrl'];
    if (url is! String || url.isEmpty) {
      throw StateError('Microsoft-Anmeldung fehlt.');
    }
    return url;
  }

  Future<List<CommunicationChannel>> _load() async {
    final response = await _client.get('/v1/mail-connectors');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die Postfachliste ist ungültig.');
    }
    return [
      for (final item in items.whereType<Map>())
        MailConnectorModel.fromData(item['id'] as String? ?? '', {
          for (final entry in item.entries) entry.key.toString(): entry.value,
        }).toChannel(),
    ];
  }

  @override
  Future<void> createChannel(CreateCommunicationChannelInput input) =>
      _unsupported();

  @override
  Future<void> deleteChannel(String channelId) => _unsupported();

  @override
  Future<void> dispatchFakeMessage(String channelId) => _unsupported();

  @override
  Future<void> sendMessage(SendChannelMessageInput input) => _unsupported();

  Future<Never> _unsupported() => Future.error(
    UnsupportedError(
      'Dieser Kanaltyp ist in der lokalen Runtime nicht verfügbar.',
    ),
  );
}
