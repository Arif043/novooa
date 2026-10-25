import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/google_account.dart';
import '../../domain/repositories/google_account_repository.dart';
import '../models/google_account_model.dart';

/// Google-Konten über die Runtime (`/v1/google-accounts`). Die Runtime hält
/// die Liste aus dem Relay zwischen und meldet Änderungen auf dem
/// Realtime-Kanal `google-accounts`; erst dann wird neu geladen.
class LocalGoogleAccountRepository implements GoogleAccountRepository {
  const LocalGoogleAccountRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<GoogleAccount>> watchAccounts() =>
      watchWorkspaceChannel('google-accounts', _load, _channel);

  @override
  Future<String> beginAuthorization({String? loginHint}) async {
    final response = await _client.post('/v1/google-accounts/authorization', {
      'loginHint': ?loginHint,
    });
    final url = response['authorizationUrl'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('Die Google-Anmeldung fehlt.');
    }
    return url;
  }

  Future<List<GoogleAccount>> _load() async {
    final response = await _client.get('/v1/google-accounts');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die Google-Konten sind ungültig.');
    }
    return [
      for (final item in items.whereType<Map>())
        GoogleAccountModel.fromJson(item),
    ];
  }
}
