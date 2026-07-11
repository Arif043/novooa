import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/knowledge_note.dart';
import '../repositories/knowledge_base_repository.dart';

class WatchKnowledgeNotes {
  const WatchKnowledgeNotes(this._repository);

  final KnowledgeBaseRepository _repository;

  Stream<List<KnowledgeNote>> call(TeamId teamId) {
    return _repository.watchNotes(teamId);
  }
}
