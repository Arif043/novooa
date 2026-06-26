import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/domain/unique_id.dart';

import '../entities/ai_model_settings.dart';
import '../entities/ai_provider.dart';
import '../entities/api_key.dart';
import '../entities/settings_failure.dart';
import '../repositories/settings_repository.dart';

class SaveAiProviderSettingsParams {
  const SaveAiProviderSettingsParams({
    required this.userId,
    required this.provider,
    required this.apiKey,
  });

  final UniqueId userId;
  final AiProvider provider;
  final ApiKey apiKey;
}

class SaveAiProviderSettings {
  const SaveAiProviderSettings(this._repository);

  final SettingsRepository _repository;

  Future<Result<AiModelSettings, SettingsFailure>> call(
    SaveAiProviderSettingsParams params,
  ) {
    return _repository.saveAiProviderSettings(
      userId: params.userId,
      provider: params.provider,
      apiKey: params.apiKey,
    );
  }
}
