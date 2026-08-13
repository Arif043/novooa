import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/knowledge_failure.dart';
import '../entities/knowledge_note.dart';
import '../repositories/knowledge_base_repository.dart';

class RestoreKnowledgeNote {
  const RestoreKnowledgeNote(this._repository);

  final KnowledgeBaseRepository _repository;

  Future<Result<KnowledgeNote, KnowledgeFailure>> call({
    required TeamId teamId,
    required KnowledgeNote note,
  }) {
    return _repository.restoreNote(teamId: teamId, note: note);
  }
}
