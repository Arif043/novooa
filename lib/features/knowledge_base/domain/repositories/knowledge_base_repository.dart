import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:multiple_result/multiple_result.dart';

import '../entities/knowledge_failure.dart';
import '../entities/knowledge_note.dart';
import '../entities/knowledge_note_draft.dart';

abstract class KnowledgeBaseRepository {
  Stream<List<KnowledgeNote>> watchNotes(TeamId teamId);

  Future<Result<KnowledgeNote, KnowledgeFailure>> createNote({
    required TeamId teamId,
    required String ownerUid,
    required KnowledgeNoteDraft draft,
  });

  Future<Result<KnowledgeNote, KnowledgeFailure>> updateNote({
    required TeamId teamId,
    required String noteId,
    required KnowledgeNoteDraft draft,
  });

  Future<Result<Unit, KnowledgeFailure>> deleteNote({
    required TeamId teamId,
    required String noteId,
  });
}
