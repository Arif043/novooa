import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/domain/unique_id.dart';

import '../entities/ai_model_settings.dart';
import '../entities/settings_failure.dart';
import '../repositories/settings_repository.dart';

class GetAiModelSettings {
  const GetAiModelSettings(this._repository);

  final SettingsRepository _repository;

  Future<Result<AiModelSettings, SettingsFailure>> call(UniqueId userId) {
    return _repository.getAiModelSettings(userId);
  }
}
