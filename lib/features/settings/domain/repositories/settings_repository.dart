import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/domain/unique_id.dart';

import '../entities/ai_model_settings.dart';
import '../entities/ai_provider.dart';
import '../entities/api_key.dart';
import '../entities/settings_failure.dart';

abstract interface class SettingsRepository {
  Future<Result<AiModelSettings, SettingsFailure>> getAiModelSettings(
    UniqueId userId,
  );

  Future<Result<AiModelSettings, SettingsFailure>> saveAiProviderSettings({
    required UniqueId userId,
    required AiProvider provider,
    required ApiKey apiKey,
  });
}
