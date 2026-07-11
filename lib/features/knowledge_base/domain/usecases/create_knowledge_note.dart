import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/knowledge_failure.dart';
import '../entities/knowledge_note.dart';
import '../entities/knowledge_note_draft.dart';
import '../repositories/knowledge_base_repository.dart';

class CreateKnowledgeNote {
  const CreateKnowledgeNote(this._repository);

  final KnowledgeBaseRepository _repository;

  Future<Result<KnowledgeNote, KnowledgeFailure>> call({
    required TeamId teamId,
    required String ownerUid,
    required KnowledgeNoteDraft draft,
  }) {
    return _repository.createNote(
      teamId: teamId,
      ownerUid: ownerUid,
      draft: draft,
    );
  }
}
