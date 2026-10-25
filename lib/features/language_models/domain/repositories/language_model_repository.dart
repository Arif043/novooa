import '../../../files/domain/entities/team_id.dart';
import '../entities/language_model.dart';

abstract interface class LanguageModelRepository {
  Stream<List<LanguageModel>> watchLanguageModels(TeamId teamId);
}
