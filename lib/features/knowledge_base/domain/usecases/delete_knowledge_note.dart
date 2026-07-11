import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/knowledge_failure.dart';
import '../repositories/knowledge_base_repository.dart';

class DeleteKnowledgeNote {
  const DeleteKnowledgeNote(this._repository);

  final KnowledgeBaseRepository _repository;

  Future<Result<Unit, KnowledgeFailure>> call({
    required TeamId teamId,
    required String noteId,
  }) {
    return _repository.deleteNote(teamId: teamId, noteId: noteId);
  }
}
