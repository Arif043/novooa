import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/push_device.dart';
import '../../domain/repositories/push_device_repository.dart';

class LocalRelayPushDeviceRepository implements PushDeviceRepository {
  const LocalRelayPushDeviceRepository(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<void> save(PushDevice device) {
    return _client.post('/v1/push-devices', {
      'token': device.token,
      'platform': device.platform,
    });
  }

  @override
  Future<void> remove({required String ownerId, required String token}) {
    return _client.post('/v1/push-devices/remove', {'token': token});
  }
}
