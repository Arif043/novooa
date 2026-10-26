import 'package:multiple_result/multiple_result.dart';

import '../entities/plugin_activation.dart';
import '../entities/plugin_failure.dart';
import '../repositories/plugin_repository.dart';

/// Nur Admins dürfen schalten; die Runtime prüft das.
class SetPluginEnabled {
  const SetPluginEnabled(this._repository);

  final PluginRepository _repository;

  Future<Result<PluginActivation, PluginFailure>> call(
    PluginId id, {
    required bool enabled,
  }) => _repository.setEnabled(id, enabled: enabled);
}
