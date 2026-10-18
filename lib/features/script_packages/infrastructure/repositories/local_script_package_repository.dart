import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';

import '../../domain/entities/python_package.dart';
import '../../domain/entities/script_package_environment.dart';
import '../../domain/repositories/script_package_repository.dart';

/// Paketumgebungen über die API der lokalen Runtime; Änderungen kommen über
/// das Realtime-Thema `script-packages`.
class LocalScriptPackageRepository implements ScriptPackageRepository {
  const LocalScriptPackageRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<ScriptPackageEnvironment>> watchEnvironments() {
    return watchWorkspaceChannel('script-packages', _load, _channel);
  }

  @override
  Future<void> install(List<PythonPackage> packages) async {
    await _client.post('/v1/script-packages', {
      'packages': [for (final package in packages) package.spec],
    });
  }

  Future<List<ScriptPackageEnvironment>> _load() async {
    final items = (await _client.get('/v1/script-packages'))['items'];
    if (items is! List) {
      throw const FormatException('Die Paketumgebungen sind ungültig.');
    }
    return items.map(_environmentFrom).toList(growable: false);
  }

  ScriptPackageEnvironment _environmentFrom(Object? value) {
    if (value is! Map || value['packages'] is! List) {
      throw const FormatException('Die Paketumgebung ist ungültig.');
    }
    return ScriptPackageEnvironment(
      packages: [for (final package in value['packages'] as List) '$package'],
      state: ScriptPackageEnvironmentState.values.firstWhere(
        (state) => state.name == value['state'],
        orElse: () => ScriptPackageEnvironmentState.failed,
      ),
      problem: _problemOf(value['reason']),
      detail: value['detail'] as String?,
      sizeBytes: (value['sizeBytes'] as num?)?.toInt(),
    );
  }

  ScriptPackageInstallProblem? _problemOf(Object? reason) {
    if (reason == null) return null;
    return ScriptPackageInstallProblem.values.firstWhere(
      (problem) => problem.name == reason,
      orElse: () => ScriptPackageInstallProblem.failed,
    );
  }
}
