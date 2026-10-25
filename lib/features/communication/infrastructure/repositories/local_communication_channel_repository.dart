import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/communication_channel.dart';
import '../../domain/repositories/communication_channel_repository.dart';
import '../models/mail_connector_model.dart';

/// Kommunikationskanäle der Runtime: ausschließlich E-Mail-Postfächer
/// (Microsoft Outlook). Die Runtime kennt sie über das Mail-Relay und
/// liefert sie unter `GET /v1/mail-connectors`.
class LocalCommunicationChannelRepository
    implements CommunicationChannelRepository {
  const LocalCommunicationChannelRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  /// Die Postfächer liegen beim Mail-Relay, die Runtime hält sie nur
  /// zwischen. Ändert das Relay etwas, leert die Runtime ihren Cache und meldet das auf
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
}
