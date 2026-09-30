import '../../../files/domain/entities/team_id.dart';
import '../entities/language_model_connection.dart';
import '../entities/language_model_connection_draft.dart';

abstract interface class LanguageModelConnectionRepository {
  Future<void> connectLanguageModels(LanguageModelConnectionDraft draft);

  Stream<List<LanguageModelConnection>> watchConnections(TeamId teamId);

  Future<void> removeConnection(TeamId teamId, String connectionId);
}
